const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const io_buffers = @import("io_buffers.zig");
const headers_sock = @import("headers_sock.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");
const http1_options = @import("http1_options.zig");
const altsvc_hsts_peer = @import("altsvc_hsts_peer.zig");

const in_libcurl = (builtin.output_mode == .Lib) or builtin.is_test;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_HTTP2: CURLcode = 16;
pub const CURLE_PARTIAL_FILE: CURLcode = 18;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_HTTP2_STREAM: CURLcode = 92;

pub const CURLMcode = c_int;
pub const CURLM_OK: CURLMcode = 0;

pub const CURLUcode = c_uint;
pub const CURLUE_OK: CURLUcode = 0;

pub const curl_off_t = i64;
pub const timediff_t = i64;
pub const curl_socket_t = vdns_cfilters.curl_socket_t;
pub const CURL_SOCKET_BAD = vdns_cfilters.CURL_SOCKET_BAD;

pub const Curl_easy = vdns_cfilters.Curl_easy;
pub const connectdata = vdns_cfilters.connectdata;
pub const easy_pollset = vdns_cfilters.easy_pollset;
pub const Curl_cfilter = vdns_cfilters.Curl_cfilter;
pub const Curl_cftype = vdns_cfilters.Curl_cftype;
pub const Curl_peer = altsvc_hsts_peer.CurlPeer;
pub const CURLU = opaque {};

pub const bufq = io_buffers.bufq;
pub const bufc_pool = io_buffers.bufc_pool;
pub const dynbuf = containers.dynbuf;
pub const dynhds = io_buffers.dynhds;
pub const dynhds_entry = io_buffers.dynhds_entry;
pub const httpreq = http1_options.httpreq;
pub const h1_req_parser = http1_options.h1_req_parser;
pub const u32_ptrset = collections.u32_ptrset;

pub const CURLEASY_MAGIC_NUMBER: c_uint = 0xc0dedbad;

pub const FIRSTSOCKET: i8 = 0;

pub const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
pub const CF_TYPE_SSL: c_int = 1 << 1;
pub const CF_TYPE_MULTIPLEX: c_int = 1 << 2;
pub const CF_TYPE_PROXY: c_int = 1 << 3;
pub const CF_TYPE_HTTP: c_int = 1 << 4;
pub const CF_TYPE_SETUP: c_int = 1 << 5;
pub const CF_TYPE_DNS: c_int = 1 << 6;

pub const CURL_LOG_LVL_NONE: c_int = 0;
pub const CURL_LOG_LVL_INFO: c_int = 1;

pub const CF_CTRL_DATA_SETUP: c_int = 4;
pub const CF_CTRL_DATA_PAUSE: c_int = 6;
pub const CF_CTRL_DATA_DONE: c_int = 7;
pub const CF_CTRL_DATA_DONE_SEND: c_int = 8;
pub const CF_CTRL_CONN_INFO_UPDATE: c_int = 256 + 0;
pub const CF_CTRL_FORGET_SOCKET: c_int = 256 + 1;
pub const CF_CTRL_FLUSH: c_int = 256 + 2;
pub const CF_CTRL_REPORT_STATS: c_int = 256 + 3;

pub const CF_QUERY_MAX_CONCURRENT: c_int = 1;
pub const CF_QUERY_CONNECT_REPLY_MS: c_int = 2;
pub const CF_QUERY_SOCKET: c_int = 3;
pub const CF_QUERY_STREAM_ERROR: c_int = 6;
pub const CF_QUERY_NEED_FLUSH: c_int = 7;
pub const CF_QUERY_IP_INFO: c_int = 8;
pub const CF_QUERY_HTTP_VERSION: c_int = 9;
pub const CF_QUERY_REMOTE_ADDR: c_int = 10;
pub const CF_QUERY_HOST_PORT: c_int = 11;
pub const CF_QUERY_SSL_INFO: c_int = 12;
pub const CF_QUERY_SSL_CTX_INFO: c_int = 13;
pub const CF_QUERY_TRANSPORT: c_int = 14;
pub const CF_QUERY_ALPN_NEGOTIATED: c_int = 15;
pub const CF_QUERY_REALLY_CONNECTED: c_int = 16;

pub const CURL_MAX_HTTP_HEADER: usize = 100 * 1024;
pub const DYN_HTTP_REQUEST: usize = 1024 * 1024;
pub const DYN_TRAILERS: usize = 64 * 1024;
pub const MAX_HTTP_RESP_HEADER_COUNT: usize = 5000;
pub const H1_PARSE_DEFAULT_MAX_LINE_LEN: usize = CURL_MAX_HTTP_HEADER;
pub const DEFAULT_MAX_CONCURRENT_STREAMS: u32 = 100;

pub const CLIENTWRITE_BODY: c_int = 1 << 0;
pub const CLIENTWRITE_HEADER: c_int = 1 << 2;
pub const CLIENTWRITE_TRAILER: c_int = 1 << 6;
pub const CURLINFO_HEADER_IN: c_uint = 1;
pub const CURLH_PSEUDO: c_uint = 1 << 3;

pub const HTTPREQ_GET: u8 = 0;
pub const HTTPREQ_POST: u8 = 1;
pub const HTTPREQ_POST_FORM: u8 = 2;
pub const HTTPREQ_POST_MIME: u8 = 3;
pub const HTTPREQ_PUT: u8 = 4;
pub const HTTPREQ_HEAD: u8 = 5;

pub const CURL_PUSH_OK: c_int = 0;
pub const CURL_PUSH_DENY: c_int = 1;
pub const CURL_PUSH_ERROROUT: c_int = 2;

pub const CURLUPART_URL: c_uint = 0;
pub const CURLUPART_SCHEME: c_uint = 1;
pub const CURLUPART_PATH: c_uint = 7;

pub const HTTP_PSEUDO_METHOD = ":method";
pub const HTTP_PSEUDO_SCHEME = ":scheme";
pub const HTTP_PSEUDO_AUTHORITY = ":authority";
pub const HTTP_PSEUDO_PATH = ":path";
pub const HTTP_PSEUDO_STATUS = ":status";

pub const PROXY_HTTP_V2: c_uint = 1;

pub const proxy_inspect_result = enum(c_uint) {
    PROXY_INSPECT_OK = 0,
    PROXY_INSPECT_FAILED = 1,
    PROXY_INSPECT_AUTH_RETRY = 2,
};

pub const http_resp = extern struct {
    status: c_int,
    description: ?[*:0]u8,
    headers: dynhds,
    trailers: dynhds,
    prev: ?*http_resp,
};

pub const cf_call_data = extern struct {
    data: ?*Curl_easy = null,
    depth: u32 = 0,
};

// ============================================================================
// nghttp2 C ABI Types & Constants
// ============================================================================

pub const nghttp2_session = opaque {};
pub const nghttp2_session_callbacks = opaque {};
pub const nghttp2_option = opaque {};

pub const nghttp2_nv = io_buffers.nghttp2_nv;

pub const nghttp2_info = extern struct {
    age: c_int,
    version_num: c_int,
    version_str: [*:0]const u8,
    proto_str: [*:0]const u8,
};

pub const nghttp2_settings_entry = extern struct {
    settings_id: i32,
    value: u32,
};

pub const nghttp2_priority_spec = extern struct {
    stream_id: i32,
    weight: i32,
    exclusive: u8,
};

pub const nghttp2_data_source = extern union {
    fd: c_int,
    ptr: ?*anyopaque,
};

pub const nghttp2_data_source_read_callback = *const fn (
    session: ?*nghttp2_session,
    stream_id: i32,
    buf: [*]u8,
    length: usize,
    data_flags: *u32,
    source: *nghttp2_data_source,
    user_data: ?*anyopaque,
) callconv(.c) isize;

pub const nghttp2_data_provider = extern struct {
    source: nghttp2_data_source,
    read_callback: ?nghttp2_data_source_read_callback,
};

pub const nghttp2_malloc_cb = *const fn (size: usize, mem_user_data: ?*anyopaque) callconv(.c) ?*anyopaque;
pub const nghttp2_free_cb = *const fn (ptr: ?*anyopaque, mem_user_data: ?*anyopaque) callconv(.c) void;
pub const nghttp2_calloc_cb = *const fn (nmemb: usize, size: usize, mem_user_data: ?*anyopaque) callconv(.c) ?*anyopaque;
pub const nghttp2_realloc_cb = *const fn (ptr: ?*anyopaque, size: usize, mem_user_data: ?*anyopaque) callconv(.c) ?*anyopaque;

pub const nghttp2_mem = extern struct {
    mem_user_data: ?*anyopaque,
    malloc: nghttp2_malloc_cb,
    free: nghttp2_free_cb,
    calloc: nghttp2_calloc_cb,
    realloc: nghttp2_realloc_cb,
};

pub const nghttp2_frame_hd = extern struct {
    length: usize,
    stream_id: i32,
    type: u8,
    flags: u8,
    reserved: u8,
};

pub const nghttp2_data = extern struct {
    hd: nghttp2_frame_hd,
    padlen: usize,
};

pub const nghttp2_headers = extern struct {
    hd: nghttp2_frame_hd,
    padlen: usize,
    pri_spec: nghttp2_priority_spec,
    nva: ?[*]nghttp2_nv,
    nvlen: usize,
    cat: c_uint,
};

pub const nghttp2_priority = extern struct {
    hd: nghttp2_frame_hd,
    pri_spec: nghttp2_priority_spec,
};

pub const nghttp2_rst_stream = extern struct {
    hd: nghttp2_frame_hd,
    error_code: u32,
};

pub const nghttp2_settings = extern struct {
    hd: nghttp2_frame_hd,
    niv: usize,
    iv: ?[*]nghttp2_settings_entry,
};

pub const nghttp2_push_promise = extern struct {
    hd: nghttp2_frame_hd,
    padlen: usize,
    nva: ?[*]nghttp2_nv,
    nvlen: usize,
    promised_stream_id: i32,
    reserved: u8,
};

pub const nghttp2_ping = extern struct {
    hd: nghttp2_frame_hd,
    opaque_data: [8]u8,
};

pub const nghttp2_goaway = extern struct {
    hd: nghttp2_frame_hd,
    last_stream_id: i32,
    error_code: u32,
    opaque_data: ?[*]u8,
    opaque_data_len: usize,
    reserved: u8,
};

pub const nghttp2_window_update = extern struct {
    hd: nghttp2_frame_hd,
    window_size_increment: i32,
    reserved: u8,
};

pub const nghttp2_extension = extern struct {
    hd: nghttp2_frame_hd,
    payload: ?*anyopaque,
};

pub const nghttp2_frame = extern union {
    hd: nghttp2_frame_hd,
    data: nghttp2_data,
    headers: nghttp2_headers,
    priority: nghttp2_priority,
    rst_stream: nghttp2_rst_stream,
    settings: nghttp2_settings,
    push_promise: nghttp2_push_promise,
    ping: nghttp2_ping,
    goaway: nghttp2_goaway,
    window_update: nghttp2_window_update,
    ext: nghttp2_extension,
};

pub const NGHTTP2_CLEARTEXT_PROTO_VERSION_ID: [*:0]const u8 = "h2c";
pub const NGHTTP2_DEFAULT_WEIGHT: c_int = 16;

pub const NGHTTP2_DATA: u8 = 0x00;
pub const NGHTTP2_HEADERS: u8 = 0x01;
pub const NGHTTP2_PRIORITY: u8 = 0x02;
pub const NGHTTP2_RST_STREAM: u8 = 0x03;
pub const NGHTTP2_SETTINGS: u8 = 0x04;
pub const NGHTTP2_PUSH_PROMISE: u8 = 0x05;
pub const NGHTTP2_PING: u8 = 0x06;
pub const NGHTTP2_GOAWAY: u8 = 0x07;
pub const NGHTTP2_WINDOW_UPDATE: u8 = 0x08;
pub const NGHTTP2_CONTINUATION: u8 = 0x09;

pub const NGHTTP2_FLAG_NONE: u8 = 0x00;
pub const NGHTTP2_FLAG_END_STREAM: u8 = 0x01;
pub const NGHTTP2_FLAG_ACK: u8 = 0x01;
pub const NGHTTP2_FLAG_END_HEADERS: u8 = 0x04;
pub const NGHTTP2_FLAG_PADDED: u8 = 0x08;
pub const NGHTTP2_FLAG_PRIORITY: u8 = 0x20;

pub const NGHTTP2_DATA_FLAG_NONE: u32 = 0x00;
pub const NGHTTP2_DATA_FLAG_EOF: u32 = 0x01;

pub const NGHTTP2_SETTINGS_HEADER_TABLE_SIZE: i32 = 0x01;
pub const NGHTTP2_SETTINGS_ENABLE_PUSH: i32 = 0x02;
pub const NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS: i32 = 0x03;
pub const NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE: i32 = 0x04;
pub const NGHTTP2_SETTINGS_MAX_FRAME_SIZE: i32 = 0x05;
pub const NGHTTP2_SETTINGS_MAX_HEADER_LIST_SIZE: i32 = 0x06;

pub const NGHTTP2_NO_ERROR: u32 = 0x00;
pub const NGHTTP2_PROTOCOL_ERROR: u32 = 0x01;
pub const NGHTTP2_INTERNAL_ERROR: u32 = 0x02;
pub const NGHTTP2_FLOW_CONTROL_ERROR: u32 = 0x03;
pub const NGHTTP2_SETTINGS_TIMEOUT: u32 = 0x04;
pub const NGHTTP2_STREAM_CLOSED: u32 = 0x05;
pub const NGHTTP2_FRAME_SIZE_ERROR: u32 = 0x06;
pub const NGHTTP2_REFUSED_STREAM: u32 = 0x07;
pub const NGHTTP2_CANCEL: u32 = 0x08;
pub const NGHTTP2_COMPRESSION_ERROR: u32 = 0x09;
pub const NGHTTP2_CONNECT_ERROR: u32 = 0x0a;
pub const NGHTTP2_ENHANCE_YOUR_CALM: u32 = 0x0b;
pub const NGHTTP2_INADEQUATE_SECURITY: u32 = 0x0c;
pub const NGHTTP2_HTTP_1_1_REQUIRED: u32 = 0x0d;

pub const NGHTTP2_ERR_INVALID_ARGUMENT: c_int = -501;
pub const NGHTTP2_ERR_WOULDBLOCK: c_int = -504;
pub const NGHTTP2_ERR_DEFERRED: c_int = -508;
pub const NGHTTP2_ERR_FATAL: c_int = -900;
pub const NGHTTP2_ERR_NOMEM: c_int = -901;
pub const NGHTTP2_ERR_CALLBACK_FAILURE: c_int = -902;

pub const nghttp2_send_callback = *const fn (
    session: ?*nghttp2_session,
    data: [*]const u8,
    length: usize,
    flags: c_int,
    user_data: ?*anyopaque,
) callconv(.c) isize;

pub const nghttp2_on_frame_recv_callback = *const fn (
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    user_data: ?*anyopaque,
) callconv(.c) c_int;

pub const nghttp2_on_invalid_frame_recv_callback = *const fn (
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    lib_error_code: c_int,
    user_data: ?*anyopaque,
) callconv(.c) c_int;

pub const nghttp2_on_frame_send_callback = *const fn (
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    user_data: ?*anyopaque,
) callconv(.c) c_int;

pub const nghttp2_on_data_chunk_recv_callback = *const fn (
    session: ?*nghttp2_session,
    flags: u8,
    stream_id: i32,
    data: [*]const u8,
    len: usize,
    user_data: ?*anyopaque,
) callconv(.c) c_int;

pub const nghttp2_on_stream_close_callback = *const fn (
    session: ?*nghttp2_session,
    stream_id: i32,
    error_code: u32,
    user_data: ?*anyopaque,
) callconv(.c) c_int;

pub const nghttp2_on_header_callback = *const fn (
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    name: [*]const u8,
    namelen: usize,
    value: [*]const u8,
    valuelen: usize,
    flags: u8,
    user_data: ?*anyopaque,
) callconv(.c) c_int;

pub const nghttp2_error_callback2 = *const fn (
    session: ?*nghttp2_session,
    lib_error_code: c_int,
    msg: [*]const u8,
    len: usize,
    user_data: ?*anyopaque,
) callconv(.c) c_int;

extern fn nghttp2_version(least_version: c_int) callconv(.c) *nghttp2_info;
extern fn nghttp2_strerror(lib_error_code: c_int) callconv(.c) [*:0]const u8;
extern fn nghttp2_http2_strerror(error_code: u32) callconv(.c) [*:0]const u8;
extern fn nghttp2_is_fatal(lib_error_code: c_int) callconv(.c) c_int;
extern fn nghttp2_priority_spec_init(
    pri_spec: *nghttp2_priority_spec,
    stream_id: i32,
    weight: i32,
    exclusive: c_int,
) callconv(.c) void;
extern fn nghttp2_option_new(option_ptr: *?*nghttp2_option) callconv(.c) c_int;
extern fn nghttp2_option_del(option: ?*nghttp2_option) callconv(.c) void;
extern fn nghttp2_option_set_no_auto_window_update(option: ?*nghttp2_option, val: c_int) callconv(.c) void;
extern fn nghttp2_option_set_no_rfc9113_leading_and_trailing_ws_validation(option: ?*nghttp2_option, val: c_int) callconv(.c) void;
extern fn nghttp2_session_callbacks_new(callbacks_ptr: *?*nghttp2_session_callbacks) callconv(.c) c_int;
extern fn nghttp2_session_callbacks_del(callbacks: ?*nghttp2_session_callbacks) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_send_callback(
    cbs: ?*nghttp2_session_callbacks,
    send_callback_fn: nghttp2_send_callback,
) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_on_frame_recv_callback(
    cbs: ?*nghttp2_session_callbacks,
    on_frame_recv_callback_fn: nghttp2_on_frame_recv_callback,
) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_on_invalid_frame_recv_callback(
    cbs: ?*nghttp2_session_callbacks,
    on_invalid_frame_recv_callback_fn: nghttp2_on_invalid_frame_recv_callback,
) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_on_frame_send_callback(
    cbs: ?*nghttp2_session_callbacks,
    on_frame_send_callback_fn: nghttp2_on_frame_send_callback,
) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_on_data_chunk_recv_callback(
    cbs: ?*nghttp2_session_callbacks,
    on_data_chunk_recv_callback_fn: nghttp2_on_data_chunk_recv_callback,
) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_on_stream_close_callback(
    cbs: ?*nghttp2_session_callbacks,
    on_stream_close_callback_fn: nghttp2_on_stream_close_callback,
) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_on_header_callback(
    cbs: ?*nghttp2_session_callbacks,
    on_header_callback_fn: nghttp2_on_header_callback,
) callconv(.c) void;
extern fn nghttp2_session_callbacks_set_error_callback2(
    cbs: ?*nghttp2_session_callbacks,
    error_callback: nghttp2_error_callback2,
) callconv(.c) void;
extern fn nghttp2_session_client_new3(
    session_ptr: *?*nghttp2_session,
    callbacks: ?*const nghttp2_session_callbacks,
    user_data: ?*anyopaque,
    option: ?*const nghttp2_option,
    mem_ptr: ?*nghttp2_mem,
) callconv(.c) c_int;
extern fn nghttp2_session_del(session: ?*nghttp2_session) callconv(.c) void;
extern fn nghttp2_session_send(session: ?*nghttp2_session) callconv(.c) c_int;
extern fn nghttp2_session_mem_recv(session: ?*nghttp2_session, in: [*]const u8, inlen: usize) callconv(.c) isize;
extern fn nghttp2_session_want_read(session: ?*nghttp2_session) callconv(.c) c_int;
extern fn nghttp2_session_want_write(session: ?*nghttp2_session) callconv(.c) c_int;
extern fn nghttp2_session_get_stream_user_data(session: ?*nghttp2_session, stream_id: i32) callconv(.c) ?*anyopaque;
extern fn nghttp2_session_set_stream_user_data(
    session: ?*nghttp2_session,
    stream_id: i32,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int;
extern fn nghttp2_session_get_remote_settings(session: ?*nghttp2_session, id: i32) callconv(.c) u32;
extern fn nghttp2_session_consume(session: ?*nghttp2_session, stream_id: i32, size: usize) callconv(.c) c_int;
extern fn nghttp2_session_upgrade2(
    session: ?*nghttp2_session,
    settings_payload: [*]const u8,
    settings_payloadlen: usize,
    head_request: c_int,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int;
extern fn nghttp2_pack_settings_payload(
    buf: [*]u8,
    buflen: usize,
    iv: [*]const nghttp2_settings_entry,
    niv: usize,
) callconv(.c) isize;
extern fn nghttp2_submit_settings(
    session: ?*nghttp2_session,
    flags: u8,
    iv: [*]const nghttp2_settings_entry,
    niv: usize,
) callconv(.c) c_int;
extern fn nghttp2_submit_request(
    session: ?*nghttp2_session,
    pri_spec: ?*const nghttp2_priority_spec,
    nva: [*]const nghttp2_nv,
    nvlen: usize,
    data_prd: ?*const nghttp2_data_provider,
    stream_user_data: ?*anyopaque,
) callconv(.c) i32;
extern fn nghttp2_submit_rst_stream(
    session: ?*nghttp2_session,
    flags: u8,
    stream_id: i32,
    error_code: u32,
) callconv(.c) c_int;
extern fn nghttp2_submit_ping(
    session: ?*nghttp2_session,
    flags: u8,
    opaque_data: ?*const u8,
) callconv(.c) c_int;
extern fn nghttp2_submit_goaway(
    session: ?*nghttp2_session,
    flags: u8,
    last_stream_id: i32,
    error_code: u32,
    opaque_data: ?[*]const u8,
    opaque_data_len: usize,
) callconv(.c) c_int;
extern fn nghttp2_submit_priority(
    session: ?*nghttp2_session,
    flags: u8,
    stream_id: i32,
    pri_spec: *const nghttp2_priority_spec,
) callconv(.c) c_int;
extern fn nghttp2_submit_window_update(
    session: ?*nghttp2_session,
    flags: u8,
    stream_id: i32,
    window_size_increment: i32,
) callconv(.c) c_int;
extern fn nghttp2_session_resume_data(session: ?*nghttp2_session, stream_id: i32) callconv(.c) c_int;
extern fn nghttp2_session_check_request_allowed(session: ?*nghttp2_session) callconv(.c) c_int;
extern fn nghttp2_session_get_stream_effective_recv_data_length(session: ?*nghttp2_session, stream_id: i32) callconv(.c) i32;
extern fn nghttp2_session_get_stream_effective_local_window_size(session: ?*nghttp2_session, stream_id: i32) callconv(.c) i32;
extern fn nghttp2_session_set_local_window_size(
    session: ?*nghttp2_session,
    flags: u8,
    stream_id: i32,
    window_size: i32,
) callconv(.c) c_int;
extern fn nghttp2_session_get_local_window_size(session: ?*nghttp2_session) callconv(.c) i32;
extern fn nghttp2_session_get_stream_remote_window_size(session: ?*nghttp2_session, stream_id: i32) callconv(.c) i32;
extern fn nghttp2_session_get_remote_window_size(session: ?*nghttp2_session) callconv(.c) i32;

// ============================================================================
// External C Helpers & Accessors
// ============================================================================

extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_easy_init() callconv(.c) ?*Curl_easy;
extern fn curl_easy_strerror(code: CURLcode) callconv(.c) [*:0]const u8;
extern fn curl_url() callconv(.c) ?*CURLU;
extern fn curl_url_cleanup(handle: ?*CURLU) callconv(.c) void;
extern fn curl_url_set(handle: ?*CURLU, what: c_uint, part: ?[*:0]const u8, flags: c_uint) callconv(.c) CURLUcode;
extern fn curl_url_get(handle: ?*CURLU, what: c_uint, part: *?[*:0]u8, flags: c_uint) callconv(.c) CURLUcode;

extern fn Curl_close(datap: *?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_url_set_authority(u: ?*CURLU, authority: [*:0]const u8) callconv(.c) CURLUcode;
extern fn Curl_url_same_origin(u1: ?*CURLU, u2: ?*CURLU) callconv(.c) bool;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*Curl_easy, cf: ?*const Curl_cfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_multi(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_is_verbose_fn(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_debug(data: ?*Curl_easy, info_type: c_uint, ptr: [*]const u8, size: usize) callconv(.c) void;
extern fn Curl_client_write(data: ?*Curl_easy, wtype: c_int, buf: ?[*]const u8, blen: usize) callconv(.c) CURLcode;
extern fn Curl_client_reset(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_bump_headersize(data: ?*Curl_easy, delta: usize, connect_only: bool) callconv(.c) CURLcode;
extern fn Curl_headers_push(data: ?*Curl_easy, line: [*]const u8, clen: usize, htype: u8) callconv(.c) CURLcode;
extern fn Curl_http_decode_status(pstatus: *i32, s: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_http_req_to_h2(h2_headers: *dynhds, req: *httpreq, data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_http_req_free(req: ?*httpreq) callconv(.c) void;
extern fn Curl_http_resp_make(presp: *?*http_resp, status: c_int, description: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_resp_free(resp: ?*http_resp) callconv(.c) void;
extern fn Curl_http_proxy_create_tunnel_request(
    preq: *?*httpreq,
    cf: *Curl_cfilter,
    data: *Curl_easy,
    peer: ?*Curl_peer,
    dest: ?*Curl_peer,
    ver: c_uint,
    udp_tunnel: bool,
) callconv(.c) CURLcode;
extern fn Curl_http_proxy_inspect_tunnel_response(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    resp: ?*http_resp,
    is_udp: bool,
    pres: *proxy_inspect_result,
) callconv(.c) CURLcode;
extern fn Curl_creader_set_null(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_xfer_write_resp_hd(data: ?*Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode;
extern fn Curl_xfer_write_resp(data: ?*Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode;
extern fn Curl_xfer_write_is_paused(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_multi_mark_dirty(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) timediff_t;
extern fn Curl_1st_fatal(result: CURLcode, result2: CURLcode) callconv(.c) CURLcode;
extern fn curlx_base64url_encode(inputbuff: [*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_dyn_addf(s: *dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn Curl_u32_ptrset_init(set: *u32_ptrset, dtor: ?collections.Curl_u32_ptrset_dtor) callconv(.c) void;
extern fn Curl_u32_ptrset_clear(set: *u32_ptrset) callconv(.c) void;
extern fn Curl_u32_ptrset_set(set: *u32_ptrset, id: u32, ptr: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_u32_ptrset_unset(set: *u32_ptrset, id: u32) callconv(.c) bool;
extern fn Curl_u32_ptrset_get(set: *u32_ptrset, id: u32) callconv(.c) ?*anyopaque;

extern fn Curl_cf_create(pcf: *?*Curl_cfilter, cft: *const Curl_cftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_cf_add(data: ?*Curl_easy, conn: ?*connectdata, index: c_int, cf: *Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_insert_after(cf_at: *Curl_cfilter, cf_new: *Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_connect(cf: ?*Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conn_cf_send(cf: ?*Curl_cfilter, data: ?*Curl_easy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_cf_get_socket(cf: ?*Curl_cfilter, data: ?*Curl_easy) callconv(.c) curl_socket_t;
extern fn Curl_cf_send_bufq(cf: ?*Curl_cfilter, data: ?*Curl_easy, bq: *bufq, buf: ?[*]const u8, len: usize, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_recv_bufq(cf: ?*Curl_cfilter, data: ?*Curl_easy, bq: *bufq, maxlen: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_keep_alive(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_conn_http_version(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) u8;
extern fn Curl_conn_get_stream_error(data: ?*Curl_easy, conn: ?*connectdata, index: c_int) callconv(.c) c_int;

extern fn Curl_proxy_start_connect_auth(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_proxy_clear_hd_proxy_auth(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_proxy_req_soft_reset(data: ?*Curl_easy) callconv(.c) void;

extern fn Curl_h2_trc_bind(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_h2_rlimit_per_step(data: ?*Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_h2_rlimit_avail(data: ?*Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_h2_multi_max_concurrent_streams(data: ?*Curl_easy) callconv(.c) u32;
extern fn Curl_h2_has_multi(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_h2_multi_has_push_cb(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_h2_call_push_cb(data: ?*Curl_easy, newhandle: ?*Curl_easy, num_headers: usize, headers: *curl_pushheaders) callconv(.c) c_int;
extern fn Curl_h2_multi_add_perform(data: ?*Curl_easy, newhandle: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLMcode;
extern fn Curl_h2_multi_connchanged(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_h2_multi_get_easy(call_data: ?*Curl_easy, mid: u32) callconv(.c) ?*Curl_easy;
extern fn Curl_h2_easy_mid(data: ?*const Curl_easy) callconv(.c) u32;
extern fn Curl_h2_easy_id(data: ?*const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_h2_easy_conn(data: ?*Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_h2_connclose(conn: ?*connectdata) callconv(.c) void;
extern fn Curl_h2_conn_is_connect_only(conn: ?*const connectdata) callconv(.c) bool;
extern fn Curl_h2_conn_set_http20_multiplex(conn: ?*connectdata) callconv(.c) void;
extern fn Curl_h2_conn_attached_xfers(conn: ?*const connectdata) callconv(.c) u32;
extern fn Curl_h2_duphandle_copy(second: ?*Curl_easy, data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_h2_easy_uh(data: ?*Curl_easy) callconv(.c) ?*CURLU;
extern fn Curl_h2_set_transfer_url_commit(newhandle: ?*Curl_easy, u: ?*CURLU, url: ?[*:0]u8) callconv(.c) void;
extern fn Curl_h2_init_pushed_req(newhandle: ?*Curl_easy) callconv(.c) void;
extern fn Curl_h2_req_want_send(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_h2_get_origin_host_port(data: ?*const Curl_easy, phostname: *?[*:0]const u8, pport: *c_int, pdefport: *c_int) callconv(.c) void;
extern fn Curl_h2_set_upgrade_state(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_h2_set_refused_stream(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_h2_req_no_body(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_h2_req_bytecount(data: ?*const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_h2_set_weight(data: ?*const Curl_easy) callconv(.c) c_int;
extern fn Curl_h2_state_weight(data: ?*const Curl_easy) callconv(.c) c_int;
extern fn Curl_h2_update_state_weight(data: ?*Curl_easy, weight: c_int) callconv(.c) void;
extern fn Curl_h2_custom_request(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_h2_state_httpreq(data: ?*const Curl_easy) callconv(.c) u8;
extern fn Curl_h2_state_url_ptr(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_h2_may_switch_check(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_h2_set_upgraded_req(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_h2_clear_ignorebody(data: ?*Curl_easy) callconv(.c) void;

inline fn goodEasyHandle(data: ?*const Curl_easy) bool {
    const ptr = data orelse return false;
    const magic_ptr: *const c_uint = @ptrCast(@alignCast(ptr));
    return magic_ptr.* == CURLEASY_MAGIC_NUMBER;
}

inline fn trcCfIsVerbose(cf: ?*const Curl_cfilter, data: ?*Curl_easy) bool {
    const c = cf orelse return false;
    return Curl_trc_is_verbose_fn(data) and c.cft.log_level >= CURL_LOG_LVL_INFO;
}

inline fn trcCf(data: ?*Curl_easy, cf: ?*const Curl_cfilter, fmt: [*:0]const u8, args: anytype) void {
    if (trcCfIsVerbose(cf, data)) {
        @call(.auto, Curl_trc_cf_infof, .{ data, cf, fmt } ++ args);
    }
}

inline fn failf(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null) {
        @call(.auto, Curl_failf, .{ data, fmt } ++ args);
    }
}

inline fn infof(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (Curl_trc_is_verbose_fn(data)) {
        @call(.auto, Curl_infof, .{ data, fmt } ++ args);
    }
}

inline fn cfDataSave(save: *cf_call_data, call_data: *cf_call_data, data: ?*Curl_easy) void {
    save.* = call_data.*;
    call_data.data = data;
    call_data.depth += 1;
    Curl_h2_trc_bind(data);
}

inline fn cfDataRestore(call_data: *cf_call_data, save: cf_call_data) void {
    call_data.* = save;
    Curl_h2_trc_bind(call_data.data);
}

inline fn sztouz(v: isize, out: *usize) bool {
    if (v < 0) return false;
    out.* = @intCast(v);
    return true;
}

// ============================================================================
// 1. lib/http2.c — HTTP/2 Direct Filter, Push Headers & Allocators
// ============================================================================

const H2_CHUNK_SIZE: usize = 16 * 1024;
const H2_CONN_WINDOW_SIZE: usize = 10 * 1024 * 1024;
const H2_NW_RECV_CHUNKS: usize = H2_CONN_WINDOW_SIZE / H2_CHUNK_SIZE;
const H2_NW_SEND_CHUNKS: usize = 1;
const H2_STREAM_WINDOW_SIZE_MAX: i32 = 10 * 1024 * 1024;
const H2_STREAM_WINDOW_SIZE_INITIAL: i32 = 64 * 1024;
const H2_STREAM_SEND_CHUNKS: usize = (64 * 1024) / H2_CHUNK_SIZE;
const H2_STREAM_POOL_SPARES: usize = H2_CONN_WINDOW_SIZE / H2_CHUNK_SIZE;
const HTTP2_HUGE_WINDOW_SIZE: i32 = 100 * H2_STREAM_WINDOW_SIZE_MAX;
const H2_SETTINGS_IV_LEN: usize = 3;
const H2_BINSETTINGS_LEN: usize = 80;
const MAX_ACC: usize = 60000;

pub const cf_h2_ctx = extern struct {
    h2: ?*nghttp2_session,
    call_data: cf_call_data,
    inbufq: bufq,
    outbufq: bufq,
    stream_bufcp: bufc_pool,
    scratch: dynbuf,
    streams: u32_ptrset,
    drain_total: usize,
    initial_win_size: u32,
    max_concurrent_streams: u32,
    goaway_error: u32,
    remote_max_sid: i32,
    local_max_sid: i32,
    initialized: bool,
    via_h1_upgrade: bool,
    conn_closed: bool,
    rcvd_goaway: bool,
    sent_goaway: bool,
    enable_push: bool,
    nw_out_blocked: bool,
};

pub const h2_stream_ctx = extern struct {
    sendbuf: bufq,
    h1: h1_req_parser,
    resp_trailers: dynhds,
    resp_hds_len: usize,
    xfer_id: curl_off_t,
    nrcvd_data: curl_off_t,

    push_headers: ?[*][*:0]u8,
    push_headers_used: usize,
    push_headers_alloc: usize,

    id: i32,
    mid: u32,
    @"error": u32,
    xfer_result: CURLcode,
    local_window_size: i32,
    status_code: i32,
    resp_hds_complete: bool,
    closed: bool,
    reset: bool,
    reset_by_server: bool,
    close_handled: bool,
    bodystarted: bool,
    body_eos: bool,
    write_paused: bool,
};

pub const curl_pushheaders = extern struct {
    data: ?*Curl_easy,
    stream: ?*h2_stream_ctx,
    frame: ?*const nghttp2_push_promise,
};

pub fn pushheaderByNumImpl(h_opt: ?*curl_pushheaders, num: usize) ?[*:0]u8 {
    const h = h_opt orelse return null;
    if (!goodEasyHandle(h.data))
        return null;
    if (h.stream) |stream| {
        if (num < stream.push_headers_used) {
            if (stream.push_headers) |hdrs| {
                return hdrs[num];
            }
        }
    }
    return null;
}

pub fn pushheaderByNameImpl(h_opt: ?*curl_pushheaders, name_opt: ?[*:0]const u8) ?[*:0]u8 {
    const h = h_opt orelse return null;
    if (!goodEasyHandle(h.data))
        return null;
    const name = name_opt orelse return null;
    if (name[0] == 0)
        return null;
    const name_slice = std.mem.span(name);
    if (std.mem.eql(u8, name_slice, ":") or std.mem.indexOfScalar(u8, name_slice[1..], ':') != null)
        return null;

    const stream = h.stream orelse return null;
    const hdrs = stream.push_headers orelse return null;
    const len = name_slice.len;
    var i: usize = 0;
    while (i < stream.push_headers_used) : (i += 1) {
        const entry = hdrs[i];
        const entry_slice = std.mem.span(entry);
        if (entry_slice.len > len and std.mem.eql(u8, entry_slice[0..len], name_slice) and entry_slice[len] == ':') {
            return @ptrCast(entry + len + 1);
        }
    }
    return null;
}

pub export fn curl_pushheader_bynum(h: ?*curl_pushheaders, num: usize) callconv(.c) ?[*:0]u8 {
    if (!backend_options.nghttp2) return null;
    return pushheaderByNumImpl(h, num);
}

pub export fn curl_pushheader_byname(h: ?*curl_pushheaders, header: ?[*:0]const u8) callconv(.c) ?[*:0]u8 {
    if (!backend_options.nghttp2) return null;
    return pushheaderByNameImpl(h, header);
}

pub fn Curl_nghttp2_malloc(size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = user_data;
    return if (mem.malloc(size)) |p| @ptrCast(p) else null;
}

pub fn Curl_nghttp2_free(ptr: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void {
    _ = user_data;
    mem.free(ptr);
}

pub fn Curl_nghttp2_calloc(nmemb: usize, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = user_data;
    return if (mem.calloc(nmemb, size)) |p| @ptrCast(p) else null;
}

pub fn Curl_nghttp2_realloc(ptr: ?*anyopaque, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = user_data;
    return if (mem.realloc(ptr, size)) |p| @ptrCast(p) else null;
}

pub fn Curl_nghttp2_fr_print(
    frame: *const nghttp2_frame,
    buffer: [*]u8,
    blen: usize,
) callconv(.c) c_int {
    switch (frame.hd.type) {
        NGHTTP2_DATA => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[DATA, len=%d, eos=%d, padlen=%d]",
                @as(c_int, @intCast(frame.hd.length)),
                @as(c_int, @intFromBool((frame.hd.flags & NGHTTP2_FLAG_END_STREAM) != 0)),
                @as(c_int, @intCast(frame.data.padlen)),
            );
        },
        NGHTTP2_HEADERS => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[HEADERS, len=%d, hend=%d, eos=%d]",
                @as(c_int, @intCast(frame.hd.length)),
                @as(c_int, @intFromBool((frame.hd.flags & NGHTTP2_FLAG_END_HEADERS) != 0)),
                @as(c_int, @intFromBool((frame.hd.flags & NGHTTP2_FLAG_END_STREAM) != 0)),
            );
        },
        NGHTTP2_PRIORITY => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[PRIORITY, len=%d, flags=%d]",
                @as(c_int, @intCast(frame.hd.length)),
                @as(c_int, frame.hd.flags),
            );
        },
        NGHTTP2_RST_STREAM => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[RST_STREAM, len=%d, flags=%d, error=%u]",
                @as(c_int, @intCast(frame.hd.length)),
                @as(c_int, frame.hd.flags),
                frame.rst_stream.error_code,
            );
        },
        NGHTTP2_SETTINGS => {
            if ((frame.hd.flags & NGHTTP2_FLAG_ACK) != 0) {
                return curl_msnprintf(buffer, blen, "FRAME[SETTINGS, ack=1]");
            }
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[SETTINGS, len=%d]",
                @as(c_int, @intCast(frame.hd.length)),
            );
        },
        NGHTTP2_PUSH_PROMISE => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[PUSH_PROMISE, len=%d, hend=%d]",
                @as(c_int, @intCast(frame.hd.length)),
                @as(c_int, @intFromBool((frame.hd.flags & NGHTTP2_FLAG_END_HEADERS) != 0)),
            );
        },
        NGHTTP2_PING => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[PING, len=%d, ack=%d]",
                @as(c_int, @intCast(frame.hd.length)),
                @as(c_int, frame.hd.flags & NGHTTP2_FLAG_ACK),
            );
        },
        NGHTTP2_GOAWAY => {
            var scratch: [128]u8 = undefined;
            const s_len = scratch.len;
            const len = if (frame.goaway.opaque_data_len < s_len)
                frame.goaway.opaque_data_len
            else
                s_len - 1;
            if (len > 0) {
                if (frame.goaway.opaque_data) |od| {
                    @memcpy(scratch[0..len], od[0..len]);
                } else {
                    @memset(scratch[0..len], 0);
                }
            }
            scratch[len] = 0;
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[GOAWAY, error=%u, reason='%s', last_stream=%d]",
                frame.goaway.error_code,
                @as([*:0]const u8, @ptrCast(&scratch)),
                frame.goaway.last_stream_id,
            );
        },
        NGHTTP2_WINDOW_UPDATE => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[WINDOW_UPDATE, incr=%d]",
                frame.window_update.window_size_increment,
            );
        },
        else => {
            return curl_msnprintf(
                buffer,
                blen,
                "FRAME[%d, len=%d, flags=%d]",
                @as(c_int, frame.hd.type),
                @as(c_int, @intCast(frame.hd.length)),
                @as(c_int, frame.hd.flags),
            );
        },
    }
}

fn free_push_headers(stream: *h2_stream_ctx) void {
    if (stream.push_headers) |hdrs| {
        var i: usize = 0;
        while (i < stream.push_headers_used) : (i += 1) {
            mem.free(hdrs[i]);
        }
        mem.free(@ptrCast(hdrs));
        stream.push_headers = null;
    }
    stream.push_headers_used = 0;
}

fn h2_stream_ctx_free(stream: *h2_stream_ctx) void {
    io_buffers.Curl_bufq_free(&stream.sendbuf);
    http1_options.Curl_h1_req_parse_free(&stream.h1);
    io_buffers.Curl_dynhds_free(&stream.resp_trailers);
    free_push_headers(stream);
    stream.* = std.mem.zeroes(h2_stream_ctx);
    stream.id = -1;
    stream.mid = std.math.maxInt(u32);
    stream.xfer_id = -1;
    mem.free(stream);
}

fn h2_stream_hash_free(id: u32, stream_ptr: ?*anyopaque) callconv(.c) void {
    _ = id;
    if (stream_ptr) |raw| {
        const stream: *h2_stream_ctx = @ptrCast(@alignCast(raw));
        h2_stream_ctx_free(stream);
    }
}

fn cf_h2_ctx_init(ctx: *cf_h2_ctx, via_h1_upgrade: bool) void {
    io_buffers.Curl_bufcp_init(&ctx.stream_bufcp, H2_CHUNK_SIZE, H2_STREAM_POOL_SPARES);
    io_buffers.Curl_bufq_initp(&ctx.inbufq, &ctx.stream_bufcp, H2_NW_RECV_CHUNKS, 0);
    io_buffers.Curl_bufq_initp(&ctx.outbufq, &ctx.stream_bufcp, H2_NW_SEND_CHUNKS, 0);
    containers.curlx_dyn_init(&ctx.scratch, CURL_MAX_HTTP_HEADER);
    Curl_u32_ptrset_init(&ctx.streams, h2_stream_hash_free);
    ctx.remote_max_sid = std.math.maxInt(i32);
    ctx.via_h1_upgrade = via_h1_upgrade;
    ctx.initialized = true;
}

fn cf_h2_ctx_free(ctx_opt: ?*cf_h2_ctx) void {
    const ctx = ctx_opt orelse return;
    if (ctx.initialized) {
        if (ctx.h2) |h2| {
            nghttp2_session_del(h2);
        }
        io_buffers.Curl_bufq_free(&ctx.inbufq);
        io_buffers.Curl_bufq_free(&ctx.outbufq);
        io_buffers.Curl_bufcp_free(&ctx.stream_bufcp);
        containers.curlx_dyn_free(&ctx.scratch);
        Curl_u32_ptrset_clear(&ctx.streams);
        ctx.* = std.mem.zeroes(cf_h2_ctx);
    }
    mem.free(ctx);
}

fn cf_h2_initial_win_size(data: ?*Curl_easy) u32 {
    const rps = Curl_h2_rlimit_per_step(data);
    if (rps > 0 and rps < H2_STREAM_WINDOW_SIZE_INITIAL) {
        const rps_u32: u32 = @intCast(rps);
        return @max(rps_u32, @as(u32, 8192));
    }
    return @intCast(H2_STREAM_WINDOW_SIZE_INITIAL);
}

fn populate_settings(
    iv: *[H2_SETTINGS_IV_LEN]nghttp2_settings_entry,
    data: ?*Curl_easy,
    ctx: ?*cf_h2_ctx,
) usize {
    iv[0] = .{
        .settings_id = NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS,
        .value = Curl_h2_multi_max_concurrent_streams(data),
    };
    iv[1] = .{
        .settings_id = NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE,
        .value = cf_h2_initial_win_size(data),
    };
    if (ctx) |c| {
        c.initial_win_size = iv[1].value;
    }
    iv[2] = .{
        .settings_id = NGHTTP2_SETTINGS_ENABLE_PUSH,
        .value = @intFromBool(Curl_h2_multi_has_push_cb(data)),
    };
    return 3;
}

fn populate_binsettings(binsettings: *[H2_BINSETTINGS_LEN]u8, data: ?*Curl_easy) isize {
    var iv: [H2_SETTINGS_IV_LEN]nghttp2_settings_entry = undefined;
    const ivlen = populate_settings(&iv, data, null);
    return nghttp2_pack_settings_payload(binsettings, H2_BINSETTINGS_LEN, &iv, ivlen);
}

fn cf_h2_update_settings(ctx: *cf_h2_ctx, initial_win_size: u32) CURLcode {
    var entry = [1]nghttp2_settings_entry{.{
        .settings_id = NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE,
        .value = initial_win_size,
    }};
    if (nghttp2_submit_settings(ctx.h2, NGHTTP2_FLAG_NONE, &entry, 1) != 0)
        return CURLE_SEND_ERROR;
    ctx.initial_win_size = initial_win_size;
    return CURLE_OK;
}

inline fn h2StreamCtx(ctx: *cf_h2_ctx, data: ?*const Curl_easy) ?*h2_stream_ctx {
    const d = data orelse return null;
    const raw = Curl_u32_ptrset_get(&ctx.streams, Curl_h2_easy_mid(d)) orelse return null;
    return @ptrCast(@alignCast(raw));
}

fn h2_stream_ctx_create(ctx: *cf_h2_ctx, data: *Curl_easy) ?*h2_stream_ctx {
    const raw = mem.calloc(1, @sizeOf(h2_stream_ctx)) orelse return null;
    const stream: *h2_stream_ctx = @ptrCast(@alignCast(raw));

    stream.id = -1;
    stream.xfer_id = Curl_h2_easy_id(data);
    stream.mid = Curl_h2_easy_mid(data);
    io_buffers.Curl_bufq_initp(
        &stream.sendbuf,
        &ctx.stream_bufcp,
        H2_STREAM_SEND_CHUNKS,
        io_buffers.BUFQ_OPT_NONE,
    );
    http1_options.Curl_h1_req_parse_init(&stream.h1, H1_PARSE_DEFAULT_MAX_LINE_LEN);
    io_buffers.Curl_dynhds_init(&stream.resp_trailers, MAX_HTTP_RESP_HEADER_COUNT, DYN_HTTP_REQUEST);
    stream.bodystarted = false;
    stream.status_code = -1;
    stream.closed = false;
    stream.close_handled = false;
    stream.@"error" = NGHTTP2_NO_ERROR;
    stream.local_window_size = H2_STREAM_WINDOW_SIZE_INITIAL;
    stream.nrcvd_data = 0;
    return stream;
}

fn cf_h2_get_stream_xfer(
    cf: *Curl_cfilter,
    stream_id: i32,
    pstream: ?*?*h2_stream_ctx,
) ?*Curl_easy {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    if (pstream) |ps| {
        ps.* = null;
    }
    const raw_stream = nghttp2_session_get_stream_user_data(ctx.h2, stream_id) orelse return null;
    const s: *h2_stream_ctx = @ptrCast(@alignCast(raw_stream));
    if (s.mid != std.math.maxInt(u32)) {
        const call_data = ctx.call_data.data;
        if (!goodEasyHandle(call_data) or !Curl_h2_has_multi(call_data)) {
            return null;
        }
        const data = Curl_h2_multi_get_easy(call_data, s.mid);
        if (data != null and
            @as(*const u32, @ptrCast(@alignCast(data.?))).* == CURLEASY_MAGIC_NUMBER and
            Curl_h2_easy_mid(data) == s.mid and
            Curl_h2_easy_id(data) == s.xfer_id)
        {
            if (pstream) |ps| {
                ps.* = s;
            }
            return data;
        }
    }
    _ = nghttp2_session_set_stream_user_data(ctx.h2, stream_id, null);
    return null;
}

fn cf_h2_get_desired_local_win(cf: *Curl_cfilter, data: ?*Curl_easy) i32 {
    _ = cf;
    const avail = Curl_h2_rlimit_avail(data);
    if (avail < std.math.maxInt(curl_off_t)) {
        if (avail <= 0)
            return 0;
        if (avail < std.math.maxInt(i32))
            return @intCast(avail);
    }
    return H2_STREAM_WINDOW_SIZE_MAX;
}

fn cf_h2_update_local_win(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    stream: *h2_stream_ctx,
) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const dwsize: i32 = if (stream.write_paused or stream.xfer_result != CURLE_OK)
        0
    else
        cf_h2_get_desired_local_win(cf, data);

    if (dwsize != stream.local_window_size) {
        const wsize = nghttp2_session_get_stream_effective_local_window_size(ctx.h2, stream.id);
        if (dwsize > wsize) {
            var rv = nghttp2_session_set_local_window_size(ctx.h2, NGHTTP2_FLAG_NONE, stream.id, dwsize);
            if (rv != 0) {
                failf(
                    data,
                    "[%d] nghttp2 set_local_window_size(%d) failed: %s(%d)",
                    .{ stream.id, dwsize, nghttp2_strerror(rv), rv },
                );
                return CURLE_HTTP2;
            }
            rv = nghttp2_submit_window_update(ctx.h2, NGHTTP2_FLAG_NONE, stream.id, dwsize - wsize);
            if (rv != 0) {
                failf(
                    data,
                    "[%d] nghttp2_submit_window_update() failed: %s(%d)",
                    .{ stream.id, nghttp2_strerror(rv), rv },
                );
                return CURLE_HTTP2;
            }
            stream.local_window_size = dwsize;
            trcCf(data, cf, "[%d] local window update by %d", .{ stream.id, dwsize - wsize });
        } else {
            const rv = nghttp2_session_set_local_window_size(ctx.h2, NGHTTP2_FLAG_NONE, stream.id, dwsize);
            if (rv != 0) {
                failf(
                    data,
                    "[%d] nghttp2_session_set_local_window_size() failed: %s(%d)",
                    .{ stream.id, nghttp2_strerror(rv), rv },
                );
                return CURLE_HTTP2;
            }
            stream.local_window_size = dwsize;
            trcCf(data, cf, "[%d] local window size now %d", .{ stream.id, dwsize });
        }
    }
    return CURLE_OK;
}

fn http2_data_setup(
    cf: *Curl_cfilter,
    data_opt: ?*Curl_easy,
    pstream: *?*h2_stream_ctx,
) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if (h2StreamCtx(ctx, data)) |existing| {
        pstream.* = existing;
        return CURLE_OK;
    }

    const stream = h2_stream_ctx_create(ctx, data) orelse return CURLE_OUT_OF_MEMORY;
    if (Curl_u32_ptrset_set(&ctx.streams, Curl_h2_easy_mid(data), stream) != CURLE_OK) {
        h2_stream_ctx_free(stream);
        return CURLE_OUT_OF_MEMORY;
    }
    pstream.* = stream;
    return CURLE_OK;
}

fn nw_out_flush(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var nwritten: usize = 0;

    if (io_buffers.Curl_bufq_is_empty(&ctx.outbufq))
        return CURLE_OK;

    const result = Curl_cf_send_bufq(cf.next, data, &ctx.outbufq, null, 0, &nwritten);
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            trcCf(
                data,
                cf,
                "flush nw send buffer(%zu) -> EAGAIN",
                .{io_buffers.Curl_bufq_len(&ctx.outbufq)},
            );
            ctx.nw_out_blocked = true;
        }
        return result;
    }
    return if (io_buffers.Curl_bufq_is_empty(&ctx.outbufq)) CURLE_OK else CURLE_AGAIN;
}

fn http2_data_done(cf: *Curl_cfilter, data: ?*Curl_easy) void {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const stream = h2StreamCtx(ctx, data) orelse return;

    if (ctx.h2) |h2| {
        if (stream.id > 0) {
            _ = nghttp2_session_set_stream_user_data(h2, stream.id, null);
        }

        if (ctx.initialized and !stream.closed and stream.id > 0) {
            trcCf(data, cf, "[%d] premature DATA_DONE, RST stream", .{stream.id});
            stream.closed = true;
            stream.reset = true;
            _ = nghttp2_submit_rst_stream(h2, NGHTTP2_FLAG_NONE, stream.id, NGHTTP2_STREAM_CLOSED);
            _ = nghttp2_session_send(h2);
            _ = nw_out_flush(cf, data);
        }
    }

    const s_mid = stream.mid;
    if (s_mid != std.math.maxInt(u32)) {
        _ = Curl_u32_ptrset_unset(&ctx.streams, s_mid);
    } else if (data) |d| {
        _ = Curl_u32_ptrset_unset(&ctx.streams, Curl_h2_easy_mid(d));
    }
}

fn h2_client_new(cf: *Curl_cfilter, cbs: ?*nghttp2_session_callbacks) c_int {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var o: ?*nghttp2_option = null;
    var h2_mem = nghttp2_mem{
        .mem_user_data = null,
        .malloc = Curl_nghttp2_malloc,
        .free = Curl_nghttp2_free,
        .calloc = Curl_nghttp2_calloc,
        .realloc = Curl_nghttp2_realloc,
    };

    var rc = nghttp2_option_new(&o);
    if (rc != 0)
        return rc;
    nghttp2_option_set_no_auto_window_update(o, 1);
    nghttp2_option_set_no_rfc9113_leading_and_trailing_ws_validation(o, 1);
    rc = nghttp2_session_client_new3(&ctx.h2, cbs, cf, o, &h2_mem);
    nghttp2_option_del(o);
    return rc;
}

fn should_close_session(ctx: *cf_h2_ctx) bool {
    return ctx.drain_total == 0 and
        nghttp2_session_want_read(ctx.h2) == 0 and
        nghttp2_session_want_write(ctx.h2) == 0;
}

fn h2_process_pending_input(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var buf: ?[*]const u8 = null;
    var blen: usize = 0;
    var nread: usize = 0;

    while (io_buffers.Curl_bufq_peek(&ctx.inbufq, &buf, &blen)) {
        const rv = nghttp2_session_mem_recv(ctx.h2, buf.?, blen);
        if (!sztouz(rv, &nread)) {
            failf(data, "nghttp2 recv error %zd: %s", .{ rv, nghttp2_strerror(@intCast(rv)) });
            return CURLE_RECV_ERROR;
        }
        io_buffers.Curl_bufq_skip(&ctx.inbufq, nread);
        if (io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) {
            break;
        } else {
            trcCf(
                data,
                cf,
                "process_pending_input: %zu bytes left in connection buffer",
                .{io_buffers.Curl_bufq_len(&ctx.inbufq)},
            );
        }
    }

    if (nghttp2_session_check_request_allowed(ctx.h2) == 0) {
        if (Curl_trc_is_verbose_fn(data)) {
            Curl_trc_multi(data, "http/2: No new requests allowed");
        }
        Curl_h2_connclose(cf.conn);
    }

    return CURLE_OK;
}

fn http2_connisalive(cf: *Curl_cfilter, data: ?*Curl_easy, input_pending: *bool) bool {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var alive = true;

    input_pending.* = false;
    const next = cf.next orelse return false;
    if (!next.cft.is_alive(next, data, input_pending))
        return false;

    if (input_pending.*) {
        var nread: usize = 0;
        input_pending.* = false;
        var result = Curl_cf_recv_bufq(cf.next, data, &ctx.inbufq, 0, &nread);
        trcCf(data, cf, "connisalive, recv pending input -> %d, %zu", .{ @as(c_int, @intCast(result)), nread });
        if (result == CURLE_OK) {
            result = h2_process_pending_input(cf, data);
            if (result != CURLE_OK) {
                alive = false;
            } else {
                alive = !should_close_session(ctx);
            }
        } else if (result != CURLE_AGAIN) {
            alive = false;
        }
    }

    return alive;
}

fn http2_send_ping(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var rc = nghttp2_submit_ping(ctx.h2, 0, null);
    if (rc != 0) {
        failf(data, "nghttp2_submit_ping() failed: %s(%d)", .{ nghttp2_strerror(rc), rc });
        return CURLE_HTTP2;
    }
    rc = nghttp2_session_send(ctx.h2);
    if (rc != 0) {
        failf(data, "nghttp2_session_send() failed: %s(%d)", .{ nghttp2_strerror(rc), rc });
        return CURLE_SEND_ERROR;
    }
    return CURLE_OK;
}

pub fn Curl_http2_ver(p: [*]u8, len: usize) callconv(.c) void {
    const h2 = nghttp2_version(0);
    _ = curl_msnprintf(p, len, "nghttp2/%s", h2.version_str);
}

fn send_callback(
    h2: ?*nghttp2_session,
    buf: [*]const u8,
    blen: usize,
    flags: c_int,
    userp: ?*anyopaque,
) callconv(.c) isize {
    _ = h2;
    _ = flags;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;
    var nwritten: usize = 0;

    const result = if (!cf.isConnected())
        io_buffers.Curl_bufq_write(&ctx.outbufq, buf, blen, &nwritten)
    else
        Curl_cf_send_bufq(cf.next, data, &ctx.outbufq, buf, blen, &nwritten);

    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            ctx.nw_out_blocked = true;
            return NGHTTP2_ERR_WOULDBLOCK;
        }
        failf(data, "Failed sending HTTP2 data", .{});
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    if (nwritten == 0) {
        ctx.nw_out_blocked = true;
        return NGHTTP2_ERR_WOULDBLOCK;
    }
    return if (nwritten > std.math.maxInt(isize))
        NGHTTP2_ERR_CALLBACK_FAILURE
    else
        @intCast(nwritten);
}

fn h2_duphandle(cf: *Curl_cfilter, data: *Curl_easy) ?*Curl_easy {
    const second = curl_easy_init() orelse return null;
    var second_stream: ?*h2_stream_ctx = null;
    _ = http2_data_setup(cf, second, &second_stream);
    Curl_h2_duphandle_copy(second, data);
    return second;
}

fn set_transfer_url(
    newhandle: *Curl_easy,
    hp: *curl_pushheaders,
    data: *Curl_easy,
) c_int {
    var url: ?[*:0]u8 = null;
    var rc: c_int = 0;
    const u = curl_url() orelse return 5;

    if (curl_pushheader_byname(hp, HTTP_PSEUDO_SCHEME)) |v| {
        if (curl_url_set(u, CURLUPART_SCHEME, v, 0) != CURLUE_OK) {
            curl_url_cleanup(u);
            return 1;
        }
    }

    if (curl_pushheader_byname(hp, HTTP_PSEUDO_AUTHORITY)) |v| {
        if (Curl_url_set_authority(u, v) != CURLUE_OK) {
            curl_url_cleanup(u);
            return 2;
        }
    }

    if (curl_pushheader_byname(hp, HTTP_PSEUDO_PATH)) |v| {
        if (curl_url_set(u, CURLUPART_PATH, v, 0) != CURLUE_OK) {
            curl_url_cleanup(u);
            return 3;
        }
    }

    if (!Curl_url_same_origin(Curl_h2_easy_uh(data), u)) {
        curl_url_cleanup(u);
        return 1;
    }

    if (curl_url_get(u, CURLUPART_URL, &url, 0) != CURLUE_OK) {
        rc = 4;
    }
    if (rc != 0) {
        curl_url_cleanup(u);
        return rc;
    }

    Curl_h2_set_transfer_url_commit(newhandle, u, url);
    return 0;
}

fn discard_newhandle(cf: *Curl_cfilter, newhandle: *Curl_easy) void {
    http2_data_done(cf, newhandle);
    var nh: ?*Curl_easy = newhandle;
    _ = Curl_close(&nh);
}

fn push_promise(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    frame: *const nghttp2_push_promise,
) c_int {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    trcCf(data, cf, "[%d] PUSH_PROMISE received", .{frame.promised_stream_id});

    if (Curl_h2_multi_has_push_cb(data)) {
        var newstream: ?*h2_stream_ctx = null;
        var heads: curl_pushheaders = undefined;

        const newhandle = h2_duphandle(cf, data) orelse {
            infof(data, "failed to duplicate handle", .{});
            return CURL_PUSH_DENY;
        };

        const stream = h2StreamCtx(ctx, data) orelse {
            failf(data, "Internal NULL stream", .{});
            discard_newhandle(cf, newhandle);
            return CURL_PUSH_DENY;
        };

        heads = .{
            .data = data,
            .stream = stream,
            .frame = frame,
        };

        var rv = set_transfer_url(newhandle, &heads, data);
        if (rv != 0) {
            trcCf(data, cf, "[%d] PUSH_PROMISE, failed to set URL -> %d", .{ frame.promised_stream_id, rv });
            discard_newhandle(cf, newhandle);
            return CURL_PUSH_DENY;
        }

        rv = Curl_h2_call_push_cb(data, newhandle, stream.push_headers_used, &heads);
        free_push_headers(stream);

        if (rv != 0) {
            trcCf(data, cf, "[%d] PUSH_PROMISE, denied by application -> %d", .{ frame.promised_stream_id, rv });
            discard_newhandle(cf, newhandle);
            return rv;
        }

        const mresult = Curl_h2_multi_add_perform(data, newhandle, cf.conn);
        if (mresult != CURLM_OK) {
            infof(data, "failed to add handle to multi", .{});
            discard_newhandle(cf, newhandle);
            return CURL_PUSH_DENY;
        }

        const result = http2_data_setup(cf, newhandle, &newstream);
        if (result != CURLE_OK) {
            failf(data, "error setting up stream: %d", .{@as(c_int, @intCast(result))});
            discard_newhandle(cf, newhandle);
            return CURL_PUSH_DENY;
        }

        const ns = newstream.?;
        ns.id = frame.promised_stream_id;
        Curl_h2_init_pushed_req(newhandle);

        trcCf(data, cf, "promise easy handle added to multi, mid=%u", .{Curl_h2_easy_mid(newhandle)});
        rv = nghttp2_session_set_stream_user_data(ctx.h2, ns.id, ns);
        if (rv != 0) {
            infof(data, "failed to set user_data for stream %d", .{ns.id});
            discard_newhandle(cf, newhandle);
            return CURL_PUSH_DENY;
        }

        if (ns.id > ctx.local_max_sid)
            ctx.local_max_sid = ns.id;
        return rv;
    } else {
        trcCf(data, cf, "Got PUSH_PROMISE, ignore it", .{});
        return CURL_PUSH_DENY;
    }
}

fn h2_xfer_write_resp_hd(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    stream: *h2_stream_ctx,
    buf: [*]const u8,
    blen: usize,
    eos: bool,
) void {
    if (stream.xfer_result == CURLE_OK) {
        stream.xfer_result = Curl_xfer_write_resp_hd(data, buf, blen, eos);
        if (stream.xfer_result == CURLE_OK and !eos)
            stream.xfer_result = cf_h2_update_local_win(cf, data, stream);
        if (stream.xfer_result != CURLE_OK) {
            trcCf(
                data,
                cf,
                "[%d] error %d writing %zu bytes of headers",
                .{ stream.id, @as(c_int, @intCast(stream.xfer_result)), blen },
            );
        }
    }
}

fn h2_xfer_write_resp(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    stream: *h2_stream_ctx,
    buf: [*]const u8,
    blen: usize,
    eos: bool,
) void {
    if (stream.xfer_result == CURLE_OK)
        stream.xfer_result = Curl_xfer_write_resp(data, buf, blen, eos);
    if (stream.xfer_result != CURLE_OK) {
        const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
        trcCf(
            data,
            cf,
            "[%d] error %d writing %zu bytes of data, RST-ing stream",
            .{ stream.id, @as(c_int, @intCast(stream.xfer_result)), blen },
        );
        _ = nghttp2_submit_rst_stream(ctx.h2, 0, stream.id, @bitCast(NGHTTP2_ERR_CALLBACK_FAILURE));
    } else if (!stream.write_paused and Curl_xfer_write_is_paused(data)) {
        trcCf(data, cf, "[%d] stream output paused", .{stream.id});
        stream.write_paused = true;
    } else if (stream.write_paused and !Curl_xfer_write_is_paused(data)) {
        trcCf(data, cf, "[%d] stream output unpaused", .{stream.id});
        stream.write_paused = false;
    }

    if (stream.xfer_result == CURLE_OK and !eos)
        stream.xfer_result = cf_h2_update_local_win(cf, data, stream);
}

fn on_stream_frame(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    stream_opt: ?*h2_stream_ctx,
    frame: *const nghttp2_frame,
) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const stream_id = frame.hd.stream_id;

    const stream = stream_opt orelse {
        trcCf(data, cf, "[%d] No stream_ctx set", .{stream_id});
        return CURLE_FAILED_INIT;
    };

    switch (frame.hd.type) {
        NGHTTP2_DATA => {
            trcCf(
                data,
                cf,
                "[%d] DATA, window=%d/%d",
                .{
                    stream_id,
                    nghttp2_session_get_stream_effective_recv_data_length(ctx.h2, stream.id),
                    nghttp2_session_get_stream_effective_local_window_size(ctx.h2, stream.id),
                },
            );
            if (!stream.bodystarted) {
                const rv = nghttp2_submit_rst_stream(ctx.h2, NGHTTP2_FLAG_NONE, stream_id, NGHTTP2_PROTOCOL_ERROR);
                if (nghttp2_is_fatal(rv) != 0)
                    return CURLE_RECV_ERROR;
            }
        },
        NGHTTP2_HEADERS => {
            if (!stream.bodystarted) {
                if (stream.status_code == -1)
                    return CURLE_RECV_ERROR;

                if (@divTrunc(stream.status_code, 100) != 1) {
                    stream.resp_hds_complete = true;
                    stream.bodystarted = true;
                } else {
                    stream.status_code = -1;
                }

                h2_xfer_write_resp_hd(cf, data, stream, "\r\n", 2, stream.closed);
                Curl_multi_mark_dirty(data);
            }
        },
        NGHTTP2_PUSH_PROMISE => {
            const rv = push_promise(cf, data, &frame.push_promise);
            if (rv != 0) {
                const rst_rv = nghttp2_submit_rst_stream(
                    ctx.h2,
                    NGHTTP2_FLAG_NONE,
                    frame.push_promise.promised_stream_id,
                    NGHTTP2_CANCEL,
                );
                if (nghttp2_is_fatal(rst_rv) != 0) {
                    return CURLE_SEND_ERROR;
                } else if (rv == CURL_PUSH_ERROROUT) {
                    trcCf(data, cf, "[%d] fail in PUSH_PROMISE received", .{stream_id});
                    return CURLE_RECV_ERROR;
                }
            }
        },
        NGHTTP2_RST_STREAM => {
            if (frame.rst_stream.error_code != 0)
                stream.reset_by_server = true;
            Curl_multi_mark_dirty(data);
        },
        NGHTTP2_WINDOW_UPDATE => {
            if (Curl_h2_req_want_send(data) and io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) {
                Curl_multi_mark_dirty(data);
            } else if (!io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) {
                const rv = nghttp2_session_resume_data(ctx.h2, stream.id);
                if (nghttp2_is_fatal(rv) != 0)
                    return CURLE_SEND_ERROR;
            }
        },
        else => {},
    }

    if ((frame.hd.flags & NGHTTP2_FLAG_END_STREAM) != 0) {
        if (!stream.closed and !stream.body_eos and
            (stream.status_code >= 400 or stream.status_code < 200))
        {
            trcCf(
                data,
                cf,
                "[%d] EOS frame with unfinished upload and HTTP status %d, abort upload by RST",
                .{ stream_id, stream.status_code },
            );
            _ = nghttp2_submit_rst_stream(ctx.h2, NGHTTP2_FLAG_NONE, stream.id, NGHTTP2_STREAM_CLOSED);
            stream.closed = true;
        }
        Curl_multi_mark_dirty(data);
    }
    return CURLE_OK;
}

fn on_frame_send(
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;

    if (trcCfIsVerbose(cf, data)) {
        var buffer: [256]u8 = undefined;
        const len = Curl_nghttp2_fr_print(frame, &buffer, buffer.len - 1);
        if (len >= 0 and @as(usize, @intCast(len)) < buffer.len) {
            buffer[@intCast(len)] = 0;
        } else {
            buffer[buffer.len - 1] = 0;
        }
        trcCf(data, cf, "[%d] -> %s", .{ frame.hd.stream_id, @as([*:0]const u8, @ptrCast(&buffer)) });
    }
    if (frame.hd.type == NGHTTP2_GOAWAY and !ctx.sent_goaway) {
        failf(
            data,
            "nghttp2 shuts down connection with error %u: %s",
            .{ frame.goaway.error_code, nghttp2_http2_strerror(frame.goaway.error_code) },
        );
    }
    return 0;
}

fn on_frame_recv(
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;
    const stream_id = frame.hd.stream_id;

    if (trcCfIsVerbose(cf, data)) {
        var buffer: [256]u8 = undefined;
        const len = Curl_nghttp2_fr_print(frame, &buffer, buffer.len - 1);
        if (len >= 0 and @as(usize, @intCast(len)) < buffer.len) {
            buffer[@intCast(len)] = 0;
        } else {
            buffer[buffer.len - 1] = 0;
        }
        trcCf(data, cf, "[%d] <- %s", .{ frame.hd.stream_id, @as([*:0]const u8, @ptrCast(&buffer)) });
    }

    if (stream_id == 0) {
        switch (frame.hd.type) {
            NGHTTP2_SETTINGS => {
                if ((frame.hd.flags & NGHTTP2_FLAG_ACK) == 0) {
                    const max_conn = ctx.max_concurrent_streams;
                    ctx.max_concurrent_streams = nghttp2_session_get_remote_settings(
                        session,
                        NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS,
                    );
                    ctx.enable_push = nghttp2_session_get_remote_settings(
                        session,
                        NGHTTP2_SETTINGS_ENABLE_PUSH,
                    ) != 0;
                    trcCf(data, cf, "[0] MAX_CONCURRENT_STREAMS: %u", .{ctx.max_concurrent_streams});
                    trcCf(
                        data,
                        cf,
                        "[0] ENABLE_PUSH: %s",
                        .{@as([*:0]const u8, if (ctx.enable_push) "TRUE" else "false")},
                    );
                    if (data != null and max_conn != ctx.max_concurrent_streams) {
                        trcCf(data, cf, "[0] notify MAX_CONCURRENT_STREAMS: %u", .{ctx.max_concurrent_streams});
                        Curl_h2_multi_connchanged(data);
                    }
                    if (Curl_h2_req_want_send(data)) {
                        Curl_multi_mark_dirty(data);
                    }
                }
            },
            NGHTTP2_GOAWAY => {
                ctx.rcvd_goaway = true;
                ctx.goaway_error = frame.goaway.error_code;
                ctx.remote_max_sid = frame.goaway.last_stream_id;
                if (data != null) {
                    infof(
                        data,
                        "received GOAWAY, error=%u, last_stream=%d",
                        .{ ctx.goaway_error, ctx.remote_max_sid },
                    );
                    Curl_h2_multi_connchanged(data);
                }
            },
            else => {},
        }
        return 0;
    }

    var stream: ?*h2_stream_ctx = null;
    const data_s = cf_h2_get_stream_xfer(cf, stream_id, &stream) orelse {
        trcCf(data, cf, "[%d] No Curl_easy associated", .{stream_id});
        return 0;
    };

    return if (on_stream_frame(cf, data_s, stream, frame) != CURLE_OK)
        NGHTTP2_ERR_CALLBACK_FAILURE
    else
        0;
}

fn cf_h2_on_invalid_frame_recv(
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    ngerr: c_int,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const stream_id = frame.hd.stream_id;

    var stream: ?*h2_stream_ctx = null;
    if (cf_h2_get_stream_xfer(cf, stream_id, &stream)) |data| {
        var buffer: [256]u8 = undefined;
        const len = Curl_nghttp2_fr_print(frame, &buffer, buffer.len - 1);
        if (len >= 0 and @as(usize, @intCast(len)) < buffer.len) {
            buffer[@intCast(len)] = 0;
        } else {
            buffer[buffer.len - 1] = 0;
        }
        failf(
            data,
            "[HTTP2] [%d] received invalid frame: %s, error %d: %s",
            .{ stream_id, @as([*:0]const u8, @ptrCast(&buffer)), ngerr, nghttp2_strerror(ngerr) },
        );
        if (stream) |s| {
            _ = nghttp2_submit_rst_stream(ctx.h2, NGHTTP2_FLAG_NONE, s.id, NGHTTP2_STREAM_CLOSED);
            s.@"error" = @bitCast(ngerr);
            s.closed = true;
            s.reset = true;
        }
    }
    return 0;
}

fn on_data_chunk_recv(
    session: ?*nghttp2_session,
    flags: u8,
    stream_id: i32,
    mem_ptr: [*]const u8,
    len: usize,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = flags;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var stream: ?*h2_stream_ctx = null;

    const data_s = cf_h2_get_stream_xfer(cf, stream_id, &stream) orelse {
        trcCf(ctx.call_data.data, cf, "[%d] Data for unknown", .{stream_id});
        _ = nghttp2_session_consume(session, stream_id, len);
        return 0;
    };

    const s = stream orelse return NGHTTP2_ERR_CALLBACK_FAILURE;
    h2_xfer_write_resp(cf, data_s, s, mem_ptr, len, false);
    _ = nghttp2_session_consume(ctx.h2, stream_id, len);
    s.nrcvd_data += @intCast(len);
    return 0;
}

fn on_stream_close(
    session: ?*nghttp2_session,
    stream_id: i32,
    error_code: u32,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const call_data = ctx.call_data.data;
    var stream: ?*h2_stream_ctx = null;

    const data_s = if (stream_id != 0) cf_h2_get_stream_xfer(cf, stream_id, &stream) else null;
    if (data_s == null) {
        trcCf(call_data, cf, "[%d] on_stream_close, no easy set on stream", .{stream_id});
        return 0;
    }
    if (!goodEasyHandle(data_s)) {
        trcCf(call_data, cf, "[%d] on_stream_close, not a GOOD easy on stream", .{stream_id});
        _ = nghttp2_session_set_stream_user_data(session, stream_id, null);
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    const s = stream orelse {
        trcCf(data_s, cf, "[%d] on_stream_close, GOOD easy but no stream", .{stream_id});
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    };

    s.closed = true;
    s.@"error" = error_code;
    if (s.@"error" != 0) {
        s.reset = true;
        if (s.@"error" == NGHTTP2_REFUSED_STREAM and ctx.rcvd_goaway and ctx.goaway_error != 0) {
            s.@"error" = ctx.goaway_error;
        }
    }

    if (s.@"error" != 0) {
        trcCf(
            data_s,
            cf,
            "[%d] RESET: %s (err %u)",
            .{ stream_id, nghttp2_http2_strerror(error_code), error_code },
        );
    } else {
        trcCf(data_s, cf, "[%d] CLOSED", .{stream_id});
    }
    Curl_multi_mark_dirty(data_s);

    const rv = nghttp2_session_set_stream_user_data(session, stream_id, null);
    if (rv != 0) {
        infof(data_s, "http/2: failed to clear user_data for stream %d", .{stream_id});
    }
    return 0;
}

fn cf_h2_header_error(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    stream_opt: ?*h2_stream_ctx,
    result: CURLcode,
) void {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    failf(
        data,
        "Error receiving HTTP2 header: %d(%s)",
        .{ @as(c_int, @intCast(result)), curl_easy_strerror(result) },
    );
    if (stream_opt) |stream| {
        _ = nghttp2_submit_rst_stream(ctx.h2, NGHTTP2_FLAG_NONE, stream.id, NGHTTP2_STREAM_CLOSED);
        stream.closed = true;
        stream.reset = true;
    }
}

fn on_header(
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    name: [*]const u8,
    namelen: usize,
    value: [*]const u8,
    valuelen: usize,
    flags: u8,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = flags;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const stream_id = frame.hd.stream_id;
    var stream_opt: ?*h2_stream_ctx = null;

    const data = cf_h2_get_stream_xfer(cf, stream_id, &stream_opt);
    if (!goodEasyHandle(data))
        return NGHTTP2_ERR_CALLBACK_FAILURE;

    const stream = stream_opt orelse {
        failf(data, "Internal NULL stream", .{});
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    };

    if (frame.hd.type == NGHTTP2_PUSH_PROMISE) {
        if (namelen == HTTP_PSEUDO_AUTHORITY.len and
            std.mem.eql(u8, name[0..namelen], HTTP_PSEUDO_AUTHORITY))
        {
            var rc: c_int = 0;
            var hostname: ?[*:0]const u8 = null;
            var port: c_int = 0;
            var defport: c_int = 0;
            Curl_h2_get_origin_host_port(data, &hostname, &port, &defport);
            const check = curl_maprintf("%s:%d", hostname.?, port) orelse
                return NGHTTP2_ERR_CALLBACK_FAILURE;
            const check_slice = std.mem.span(check);
            const host_slice = if (hostname) |h| std.mem.span(h) else "";
            const value_slice = value[0..valuelen];
            if (!std.ascii.eqlIgnoreCase(check_slice, value_slice) and
                (port != defport or !std.ascii.eqlIgnoreCase(host_slice, value_slice)))
            {
                _ = nghttp2_submit_rst_stream(session, NGHTTP2_FLAG_NONE, stream_id, NGHTTP2_PROTOCOL_ERROR);
                rc = NGHTTP2_ERR_CALLBACK_FAILURE;
            }
            mem.free(check);
            if (rc != 0)
                return rc;
        }
        if (namelen == 1 and name[0] == ':') {
            return 0;
        }
        if (namelen == "content-length".len and
            std.ascii.eqlIgnoreCase(name[0..namelen], "content-length"))
        {
            return 0;
        }

        if (stream.push_headers == null) {
            stream.push_headers_alloc = 10;
            const raw_hdrs = mem.malloc(stream.push_headers_alloc * @sizeOf([*:0]u8)) orelse
                return NGHTTP2_ERR_CALLBACK_FAILURE;
            stream.push_headers = @ptrCast(@alignCast(raw_hdrs));
            stream.push_headers_used = 0;
        } else if (stream.push_headers_used == stream.push_headers_alloc) {
            if (stream.push_headers_alloc > 1000) {
                failf(data, "Too many PUSH_PROMISE headers", .{});
                free_push_headers(stream);
                return NGHTTP2_ERR_CALLBACK_FAILURE;
            }
            stream.push_headers_alloc *= 2;
            const raw_hdrs = mem.realloc(
                @ptrCast(stream.push_headers),
                stream.push_headers_alloc * @sizeOf([*:0]u8),
            ) orelse {
                free_push_headers(stream);
                return NGHTTP2_ERR_CALLBACK_FAILURE;
            };
            stream.push_headers = @ptrCast(@alignCast(raw_hdrs));
        }

        const name_slice = name[0..namelen];
        const value_slice = value[0..valuelen];
        if (std.mem.indexOfScalar(u8, name_slice, 0) != null or
            std.mem.indexOfScalar(u8, value_slice, 0) != null)
        {
            free_push_headers(stream);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        }
        const total_len = std.math.add(usize, namelen, valuelen) catch {
            free_push_headers(stream);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        };
        const alloc_len = std.math.add(usize, total_len, 2) catch {
            free_push_headers(stream);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        };
        const h_raw = mem.malloc(alloc_len) orelse {
            free_push_headers(stream);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        };
        const h_buf: [*]u8 = @ptrCast(h_raw);
        @memcpy(h_buf[0..namelen], name_slice);
        h_buf[namelen] = ':';
        @memcpy(h_buf[namelen + 1 .. namelen + 1 + valuelen], value_slice);
        h_buf[namelen + 1 + valuelen] = 0;
        const h: [*:0]u8 = @ptrCast(h_buf);
        stream.push_headers.?[stream.push_headers_used] = h;
        stream.push_headers_used += 1;
        return 0;
    }

    if (stream.bodystarted) {
        trcCf(
            data,
            cf,
            "[%d] trailer: %.*s: %.*s",
            .{ stream.id, @as(c_int, @intCast(namelen)), name, @as(c_int, @intCast(valuelen)), value },
        );
        const result = io_buffers.Curl_dynhds_add(&stream.resp_trailers, name, namelen, value, valuelen);
        if (result != CURLE_OK) {
            cf_h2_header_error(cf, data, stream, result);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        }
        return 0;
    }

    if (namelen == HTTP_PSEUDO_STATUS.len and
        std.mem.eql(u8, name[0..namelen], HTTP_PSEUDO_STATUS))
    {
        var buffer: [32]u8 = undefined;
        var result = Curl_http_decode_status(&stream.status_code, value, valuelen);
        if (result != CURLE_OK) {
            cf_h2_header_error(cf, data, stream, result);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        }
        const hlen_i = curl_msnprintf(&buffer, buffer.len, HTTP_PSEUDO_STATUS ++ ":%d\r", stream.status_code);
        const hlen: usize = if (hlen_i > 0) @intCast(hlen_i) else 0;
        result = Curl_headers_push(data, &buffer, hlen, CURLH_PSEUDO);
        if (result != CURLE_OK) {
            cf_h2_header_error(cf, data, stream, result);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        }
        containers.curlx_dyn_reset(&ctx.scratch);
        result = containers.curlx_dyn_addn(&ctx.scratch, "HTTP/2 ", "HTTP/2 ".len);
        if (result == CURLE_OK)
            result = containers.curlx_dyn_addn(&ctx.scratch, value, valuelen);
        if (result == CURLE_OK)
            result = containers.curlx_dyn_addn(&ctx.scratch, " \r\n", " \r\n".len);
        if (result == CURLE_OK) {
            if (containers.curlx_dyn_ptr(&ctx.scratch)) |p| {
                h2_xfer_write_resp_hd(cf, data, stream, p, containers.curlx_dyn_len(&ctx.scratch), false);
            }
        }
        if (result != CURLE_OK) {
            cf_h2_header_error(cf, data, stream, result);
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        }
        if (ctx.call_data.data != data)
            Curl_multi_mark_dirty(data);

        trcCf(data, cf, "[%d] status: HTTP/2 %03d", .{ stream.id, stream.status_code });
        return 0;
    }

    containers.curlx_dyn_reset(&ctx.scratch);
    var result = containers.curlx_dyn_addn(&ctx.scratch, name, namelen);
    if (result == CURLE_OK)
        result = containers.curlx_dyn_addn(&ctx.scratch, ": ", 2);
    if (result == CURLE_OK)
        result = containers.curlx_dyn_addn(&ctx.scratch, value, valuelen);
    if (result == CURLE_OK)
        result = containers.curlx_dyn_addn(&ctx.scratch, "\r\n", 2);
    if (result == CURLE_OK) {
        if (containers.curlx_dyn_ptr(&ctx.scratch)) |p| {
            h2_xfer_write_resp_hd(cf, data, stream, p, containers.curlx_dyn_len(&ctx.scratch), false);
        }
    }
    if (result != CURLE_OK) {
        cf_h2_header_error(cf, data, stream, result);
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    if (ctx.call_data.data != data)
        Curl_multi_mark_dirty(data);

    trcCf(
        data,
        cf,
        "[%d] header: %.*s: %.*s",
        .{ stream.id, @as(c_int, @intCast(namelen)), name, @as(c_int, @intCast(valuelen)), value },
    );
    return 0;
}

fn req_body_read_callback(
    session: ?*nghttp2_session,
    stream_id: i32,
    buf: [*]u8,
    length: usize,
    data_flags: *u32,
    source: *nghttp2_data_source,
    userp: ?*anyopaque,
) callconv(.c) isize {
    _ = session;
    _ = source;
    if (stream_id == 0)
        return NGHTTP2_ERR_INVALID_ARGUMENT;

    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    var stream_opt: ?*h2_stream_ctx = null;
    const data_s = cf_h2_get_stream_xfer(cf, stream_id, &stream_opt);
    const stream = stream_opt orelse return NGHTTP2_ERR_CALLBACK_FAILURE;
    if (data_s == null)
        return NGHTTP2_ERR_CALLBACK_FAILURE;

    var n: usize = 0;
    const result = io_buffers.Curl_bufq_read(&stream.sendbuf, buf, length, &n);
    var nread: isize = 0;
    if (result != CURLE_OK) {
        if (result != CURLE_AGAIN)
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        nread = 0;
    } else {
        nread = @intCast(n);
    }

    trcCf(
        data_s,
        cf,
        "[%d] req_body_read(len=%zu) eos=%d -> %zd, %d",
        .{ stream_id, length, @as(c_int, @intFromBool(stream.body_eos)), nread, @as(c_int, @intCast(result)) },
    );

    if (stream.body_eos and io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) {
        data_flags.* = NGHTTP2_DATA_FLAG_EOF;
        return nread;
    }
    return if (nread == 0) NGHTTP2_ERR_DEFERRED else nread;
}

fn error_callback(
    session: ?*nghttp2_session,
    lib_error_code: c_int,
    msg: [*]const u8,
    len: usize,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    _ = lib_error_code;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;
    failf(data, "%.*s", .{ @as(c_int, @intCast(len)), msg });
    return 0;
}

pub fn Curl_http2_request_upgrade(req: *dynbuf, data: *Curl_easy) callconv(.c) CURLcode {
    var base64: ?[*:0]u8 = null;
    var blen: usize = 0;
    var binsettings: [H2_BINSETTINGS_LEN]u8 = undefined;
    var binlen: usize = 0;

    const rc = populate_binsettings(&binsettings, data);
    if (!sztouz(rc, &binlen) or binlen == 0) {
        failf(data, "nghttp2 unexpectedly failed on pack_settings_payload", .{});
        containers.curlx_dyn_free(req);
        return CURLE_FAILED_INIT;
    }

    var result = curlx_base64url_encode(&binsettings, binlen, &base64, &blen);
    if (result != CURLE_OK) {
        containers.curlx_dyn_free(req);
        return result;
    }

    result = curlx_dyn_addf(
        req,
        "Upgrade: %s\r\nHTTP2-Settings: %s\r\n",
        NGHTTP2_CLEARTEXT_PROTO_VERSION_ID,
        base64.?,
    );
    mem.free(base64);

    Curl_h2_set_upgrade_state(data);
    return result;
}

fn http2_handle_stream_close(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    stream: *h2_stream_ctx,
    pnlen: *usize,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    pnlen.* = 0;
    if (stream.reset) {
        if (stream.@"error" == NGHTTP2_REFUSED_STREAM) {
            infof(
                data,
                "HTTP/2 stream %d refused by server, try again on a new connection",
                .{stream.id},
            );
            Curl_h2_connclose(cf.conn);
            Curl_h2_set_refused_stream(data);
            return CURLE_RECV_ERROR;
        } else if (stream.resp_hds_complete and Curl_h2_req_no_body(data)) {
            trcCf(
                data,
                cf,
                "[%d] error after response headers, but we did not want a body anyway, ignore: %s (err %u)",
                .{ stream.id, nghttp2_http2_strerror(stream.@"error"), stream.@"error" },
            );
            stream.close_handled = true;
            return CURLE_OK;
        }
        failf(
            data,
            "HTTP/2 stream %d reset by %s (error 0x%x %s)",
            .{
                stream.id,
                @as([*:0]const u8, if (stream.reset_by_server) "server" else "curl"),
                stream.@"error",
                nghttp2_http2_strerror(stream.@"error"),
            },
        );
        return if (stream.@"error" != 0)
            CURLE_HTTP2_STREAM
        else if (Curl_h2_req_bytecount(data) != 0)
            CURLE_PARTIAL_FILE
        else
            CURLE_HTTP2;
    } else if (!stream.bodystarted) {
        failf(
            data,
            "HTTP/2 stream %d was closed cleanly, but before getting all response header fields, treated as error",
            .{stream.id},
        );
        return CURLE_HTTP2_STREAM;
    }

    if (io_buffers.Curl_dynhds_count(&stream.resp_trailers) > 0) {
        var dbuf: dynbuf = undefined;
        var i: usize = 0;

        result = CURLE_OK;
        containers.curlx_dyn_init(&dbuf, DYN_TRAILERS);
        while (i < io_buffers.Curl_dynhds_count(&stream.resp_trailers)) : (i += 1) {
            const e = io_buffers.Curl_dynhds_getn(&stream.resp_trailers, i) orelse break;
            containers.curlx_dyn_reset(&dbuf);
            result = curlx_dyn_addf(
                &dbuf,
                "%.*s: %.*s\r\n",
                @as(c_int, @intCast(e.namelen)),
                e.name,
                @as(c_int, @intCast(e.valuelen)),
                e.value,
            );
            if (result != CURLE_OK)
                break;
            if (containers.curlx_dyn_ptr(&dbuf)) |p| {
                const dlen = containers.curlx_dyn_len(&dbuf);
                Curl_debug(data, CURLINFO_HEADER_IN, p, dlen);
                result = Curl_client_write(data, CLIENTWRITE_HEADER | CLIENTWRITE_TRAILER, p, dlen);
                if (result != CURLE_OK)
                    break;
                result = Curl_bump_headersize(data, dlen, false);
                if (result != CURLE_OK) {
                    containers.curlx_dyn_free(&dbuf);
                    return result;
                }
            }
        }
        containers.curlx_dyn_free(&dbuf);
        if (result != CURLE_OK) {
            trcCf(data, cf, "handle_stream_close -> %d, %zu", .{ @as(c_int, @intCast(result)), pnlen.* });
            return result;
        }
    }

    stream.close_handled = true;
    result = CURLE_OK;
    trcCf(data, cf, "handle_stream_close -> %d, %zu", .{ @as(c_int, @intCast(result)), pnlen.* });
    return result;
}

fn sweight_wanted(data: ?*const Curl_easy) c_int {
    const w = Curl_h2_set_weight(data);
    return if (w != 0) w else NGHTTP2_DEFAULT_WEIGHT;
}

fn sweight_in_effect(data: ?*const Curl_easy) c_int {
    const w = Curl_h2_state_weight(data);
    return if (w != 0) w else NGHTTP2_DEFAULT_WEIGHT;
}

fn h2_pri_spec(data: ?*Curl_easy, pri_spec: *nghttp2_priority_spec) void {
    const prio = Curl_h2_set_weight(data);
    nghttp2_priority_spec_init(pri_spec, 0, sweight_wanted(data), 0);
    Curl_h2_update_state_weight(data, prio);
}

fn h2_progress_egress(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var rv: c_int = 0;

    if (sweight_wanted(data) != sweight_in_effect(data)) {
        if (h2StreamCtx(ctx, data)) |stream| {
            if (stream.id > 0 and sweight_wanted(data) != sweight_in_effect(data)) {
                var pri_spec: nghttp2_priority_spec = undefined;
                h2_pri_spec(data, &pri_spec);
                trcCf(data, cf, "[%d] Queuing PRIORITY", .{stream.id});
                rv = nghttp2_submit_priority(ctx.h2, NGHTTP2_FLAG_NONE, stream.id, &pri_spec);
            }
        }
    }

    ctx.nw_out_blocked = false;
    while (rv == 0 and !ctx.nw_out_blocked and nghttp2_session_want_write(ctx.h2) != 0) {
        rv = nghttp2_session_send(ctx.h2);
    }

    if (nghttp2_is_fatal(rv) != 0) {
        trcCf(data, cf, "nghttp2_session_send error (%s)%d", .{ nghttp2_strerror(rv), rv });
        return CURLE_SEND_ERROR;
    }

    if (!cf.isConnected() and !Curl_h2_conn_is_connect_only(cf.conn))
        return CURLE_OK;
    return nw_out_flush(cf, data);
}

fn stream_recv(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    stream: *h2_stream_ctx,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) CURLcode {
    _ = buf;
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_AGAIN;

    pnread.* = 0;

    if (stream.xfer_result == CURLE_OK)
        stream.xfer_result = cf_h2_update_local_win(cf, data, stream);

    if (stream.xfer_result != CURLE_OK) {
        trcCf(data, cf, "[%d] xfer write failed", .{stream.id});
        result = stream.xfer_result;
    } else if (stream.closed) {
        trcCf(data, cf, "[%d] returning CLOSE", .{stream.id});
        result = http2_handle_stream_close(cf, data, stream, pnread);
    } else if (stream.reset or
        (ctx.conn_closed and io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) or
        (ctx.rcvd_goaway and ctx.remote_max_sid < stream.id))
    {
        trcCf(data, cf, "[%d] returning ERR", .{stream.id});
        result = if (Curl_h2_req_bytecount(data) != 0) CURLE_PARTIAL_FILE else CURLE_HTTP2;
    }

    if (result != CURLE_OK and result != CURLE_AGAIN) {
        trcCf(
            data,
            cf,
            "[%d] stream_recv(len=%zu) -> %d, %zu",
            .{ stream.id, len, @as(c_int, @intCast(result)), pnread.* },
        );
    }
    return result;
}

fn h2_progress_ingress(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    data_max_bytes_arg: usize,
) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;
    var data_max_bytes = data_max_bytes_arg;

    if (should_close_session(ctx)) {
        trcCf(data, cf, "[0] ingress: session is closed", .{});
        return CURLE_HTTP2;
    }

    if (!io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) {
        trcCf(
            data,
            cf,
            "Process %zu bytes in connection buffer",
            .{io_buffers.Curl_bufq_len(&ctx.inbufq)},
        );
        result = h2_process_pending_input(cf, data);
        if (result != CURLE_OK)
            return result;
    }

    if (data_max_bytes == 0)
        data_max_bytes = H2_CHUNK_SIZE;

    while (!ctx.conn_closed and io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) {
        if (h2StreamCtx(ctx, data)) |stream| {
            if (stream.closed or data_max_bytes == 0) {
                if (cf.next == null or !cf.next.?.cft.has_data_pending(cf.next.?, data))
                    Curl_multi_mark_dirty(data);
                break;
            }
        }

        result = Curl_cf_recv_bufq(cf.next, data, &ctx.inbufq, 0, &nread);
        if (result != CURLE_OK) {
            if (result != CURLE_AGAIN) {
                failf(
                    data,
                    "Failed receiving HTTP2 data: %d(%s)",
                    .{ @as(c_int, @intCast(result)), curl_easy_strerror(result) },
                );
                return result;
            }
            break;
        } else if (nread == 0) {
            trcCf(data, cf, "[0] ingress: connection closed", .{});
            ctx.conn_closed = true;
            break;
        } else {
            trcCf(data, cf, "[0] ingress: read %zu bytes", .{nread});
            data_max_bytes = if (data_max_bytes > nread) (data_max_bytes - nread) else 0;
        }

        result = h2_process_pending_input(cf, data);
        if (result != CURLE_OK)
            return result;
        trcCf(data, cf, "[0] ingress: nw-in buffered %zu", .{io_buffers.Curl_bufq_len(&ctx.inbufq)});
    }

    if (ctx.conn_closed and io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) {
        trcCf(
            data,
            cf,
            "server closed %s",
            .{@as([*:0]const u8, if (ctx.rcvd_goaway) "with GOAWAY" else "abruptly")},
        );
        Curl_h2_connclose(cf.conn);
    }

    trcCf(data, cf, "[0] ingress: done", .{});
    return CURLE_OK;
}

fn cf_h2_recv(
    cf: *Curl_cfilter,
    data_opt: ?*Curl_easy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;

    const data = data_opt orelse return CURLE_HTTP2;
    pnread.* = 0;

    const stream = h2StreamCtx(ctx, data) orelse {
        failf(
            data,
            "http/2 recv on a transfer never opened or already cleared, mid=%u",
            .{Curl_h2_easy_mid(data)},
        );
        return CURLE_HTTP2;
    };

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    var result = stream_recv(cf, data, stream, buf, len, pnread);
    if (result == CURLE_OK or result == CURLE_AGAIN) {
        if (result != CURLE_OK) {
            result = h2_progress_ingress(cf, data, len);
            if (result == CURLE_OK) {
                result = stream_recv(cf, data, stream, buf, len, pnread);
            }
        }

        if (pnread.* > 0) {
            _ = nghttp2_session_consume(ctx.h2, stream.id, pnread.*);
            if (stream.closed) {
                trcCf(data, cf, "[%d] DRAIN closed stream", .{stream.id});
                Curl_multi_mark_dirty(data);
            }
        }
    }

    const r2 = h2_progress_egress(cf, data);
    if (r2 == CURLE_AGAIN) {
        if (!Curl_h2_req_want_send(data))
            Curl_multi_mark_dirty(data);
    } else if (r2 != CURLE_OK) {
        result = r2;
    }

    trcCf(
        data,
        cf,
        "[%d] cf_recv(len=%zu) -> %d, %zu, window=%d/%d, connection %d/%d",
        .{
            stream.id,
            len,
            @as(c_int, @intCast(result)),
            pnread.*,
            nghttp2_session_get_stream_effective_recv_data_length(ctx.h2, stream.id),
            nghttp2_session_get_stream_effective_local_window_size(ctx.h2, stream.id),
            nghttp2_session_get_local_window_size(ctx.h2),
            HTTP2_HUGE_WINDOW_SIZE,
        },
    );

    return result;
}

fn cf_h2_body_send(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    stream: *h2_stream_ctx,
    buf: [*]const u8,
    blen: usize,
    eos: bool,
    pnwritten: *usize,
) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    pnwritten.* = 0;

    if (stream.closed) {
        if (stream.resp_hds_complete) {
            trcCf(data, cf, "[%d] discarding dataon closed stream with response", .{stream.id});
            if (eos)
                stream.body_eos = true;
            pnwritten.* = blen;
            return CURLE_OK;
        }
        infof(data, "stream %d closed", .{stream.id});
        return CURLE_SEND_ERROR;
    }

    const result = io_buffers.Curl_bufq_write(&stream.sendbuf, buf, blen, pnwritten);
    if (result != CURLE_OK)
        return result;

    if (eos and blen == pnwritten.*)
        stream.body_eos = true;

    if (eos or !io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) {
        const rv = nghttp2_session_resume_data(ctx.h2, stream.id);
        if (nghttp2_is_fatal(rv) != 0)
            return CURLE_SEND_ERROR;
    }

    return CURLE_OK;
}

fn h2_submit(
    pstream: *?*h2_stream_ctx,
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var stream: ?*h2_stream_ctx = null;
    var h2_headers: dynhds = undefined;
    var nva: ?[*]nghttp2_nv = null;
    var nheader: usize = 0;
    var data_prd: nghttp2_data_provider = undefined;
    var pri_spec: nghttp2_priority_spec = undefined;
    var nwritten: usize = 0;
    var result: CURLcode = CURLE_OK;

    pnwritten.* = 0;
    io_buffers.Curl_dynhds_init(&h2_headers, MAX_HTTP_RESP_HEADER_COUNT, DYN_HTTP_REQUEST);

    defer {
        trcCf(
            data,
            cf,
            "[%d] submit -> %d, %zu",
            .{
                if (stream) |s| s.id else @as(i32, -1),
                @as(c_int, @intCast(result)),
                pnwritten.*,
            },
        );
        mem.free(nva);
        pstream.* = stream;
        io_buffers.Curl_dynhds_free(&h2_headers);
    }

    result = http2_data_setup(cf, data, &stream);
    if (result != CURLE_OK)
        return result;

    const s = stream.?;
    result = http1_options.Curl_h1_req_parse_read(
        &s.h1,
        buf,
        len,
        null,
        Curl_h2_custom_request(data),
        0,
        &nwritten,
    );
    if (result != CURLE_OK)
        return result;
    pnwritten.* = nwritten;
    if (s.h1.done == 0)
        return result;

    result = Curl_http_req_to_h2(&h2_headers, s.h1.req.?, data);
    if (result != CURLE_OK)
        return result;
    http1_options.Curl_h1_req_parse_free(&s.h1);

    nva = io_buffers.Curl_dynhds_to_nva(&h2_headers, &nheader);
    if (nva == null) {
        result = CURLE_OUT_OF_MEMORY;
        return result;
    }

    h2_pri_spec(data, &pri_spec);
    if (nghttp2_session_check_request_allowed(ctx.h2) == 0)
        trcCf(data, cf, "send request NOT allowed (via nghttp2)", .{});

    const initial_win_size = cf_h2_initial_win_size(data);
    if (initial_win_size != ctx.initial_win_size) {
        result = cf_h2_update_settings(ctx, initial_win_size);
        if (result != CURLE_OK)
            return result;
    }

    const httpreq_type = Curl_h2_state_httpreq(data);
    const stream_id: i32 = switch (httpreq_type) {
        HTTPREQ_POST, HTTPREQ_POST_FORM, HTTPREQ_POST_MIME, HTTPREQ_PUT => blk: {
            data_prd = .{
                .source = .{ .ptr = null },
                .read_callback = req_body_read_callback,
            };
            break :blk nghttp2_submit_request(ctx.h2, &pri_spec, nva.?, nheader, &data_prd, s);
        },
        else => nghttp2_submit_request(ctx.h2, &pri_spec, nva.?, nheader, null, s),
    };

    if (stream_id < 0) {
        trcCf(
            data,
            cf,
            "send: nghttp2_submit_request error (%s)%d",
            .{ nghttp2_strerror(stream_id), stream_id },
        );
        result = CURLE_SEND_ERROR;
        return result;
    }

    if (Curl_trc_is_verbose_fn(data)) {
        var acc: usize = 0;
        var i: usize = 0;
        const url_ptr = Curl_h2_state_url_ptr(data) orelse "";
        infof(data, "[HTTP/2] [%d] OPENED stream for %s", .{ stream_id, url_ptr });
        while (i < nheader) : (i += 1) {
            acc += nva.?[i].namelen + nva.?[i].valuelen;
            infof(
                data,
                "[HTTP/2] [%d] [%.*s: %.*s]",
                .{
                    stream_id,
                    @as(c_int, @intCast(nva.?[i].namelen)),
                    nva.?[i].name.?,
                    @as(c_int, @intCast(nva.?[i].valuelen)),
                    nva.?[i].value.?,
                },
            );
        }
        if (acc > MAX_ACC) {
            infof(
                data,
                "[HTTP/2] Warning: The cumulative length of all headers exceeds %d bytes and that could cause the stream to be rejected.",
                .{@as(c_int, @intCast(MAX_ACC))},
            );
        }
    }

    s.id = stream_id;

    const body = buf + pnwritten.*;
    const bodylen = len - pnwritten.*;

    if (bodylen > 0 or eos) {
        var n: usize = 0;
        result = cf_h2_body_send(cf, data, s, body, bodylen, eos, &n);
        if (result == CURLE_OK) {
            pnwritten.* += n;
        } else if (result == CURLE_AGAIN) {
            result = CURLE_OK;
        } else {
            result = CURLE_SEND_ERROR;
        }
    }

    return result;
}

fn cf_h2_send(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var stream = h2StreamCtx(ctx, data);
    var save: cf_call_data = undefined;
    var result: CURLcode = CURLE_OK;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    pnwritten.* = 0;

    if (stream == null or stream.?.id == -1) {
        result = h2_submit(&stream, cf, data, buf, len, eos, pnwritten);
        if (result != CURLE_OK)
            return finishCfH2Send(cf, ctx, data, stream, len, pnwritten, result);
    } else if (stream.?.body_eos) {
        var n: usize = 0;
        result = cf_h2_body_send(cf, data, stream.?, buf, 0, eos, &n);
        trcCf(
            data,
            cf,
            "[%d] cf_body_send last CHUNK -> %d, %zu, eos=%d",
            .{ stream.?.id, @as(c_int, @intCast(result)), n, @as(c_int, @intFromBool(eos)) },
        );
        if (result != CURLE_OK)
            return finishCfH2Send(cf, ctx, data, stream, len, pnwritten, result);
        pnwritten.* = len;
    } else {
        result = cf_h2_body_send(cf, data, stream.?, buf, len, eos, pnwritten);
        trcCf(
            data,
            cf,
            "[%d] cf_body_send(len=%zu) -> %d, %zu, eos=%d",
            .{ stream.?.id, len, @as(c_int, @intCast(result)), pnwritten.*, @as(c_int, @intFromBool(eos)) },
        );
    }

    const r2 = h2_progress_egress(cf, data);

    if (stream != null and stream.?.closed and !stream.?.resp_hds_complete) {
        infof(data, "stream %d closed", .{stream.?.id});
        result = CURLE_SEND_ERROR;
        return finishCfH2Send(cf, ctx, data, stream, len, pnwritten, result);
    } else if (r2 != CURLE_OK and r2 != CURLE_AGAIN) {
        result = r2;
        return finishCfH2Send(cf, ctx, data, stream, len, pnwritten, result);
    }

    if (should_close_session(ctx)) {
        if (stream != null and stream.?.closed) {
            result = http2_handle_stream_close(cf, data.?, stream.?, pnwritten);
        } else {
            trcCf(data, cf, "send: nothing to do in this session", .{});
            result = CURLE_HTTP2;
        }
    }

    return finishCfH2Send(cf, ctx, data, stream, len, pnwritten, result);
}

fn finishCfH2Send(
    cf: *Curl_cfilter,
    ctx: *cf_h2_ctx,
    data: ?*Curl_easy,
    stream_opt: ?*h2_stream_ctx,
    len: usize,
    pnwritten: *usize,
    result: CURLcode,
) CURLcode {
    if (stream_opt) |stream| {
        trcCf(
            data,
            cf,
            "[%d] cf_send(len=%zu) -> %d, %zu, eos=%d, h2 windows %d-%d (stream-conn), buffers %zu-%zu (stream-conn)",
            .{
                stream.id,
                len,
                @as(c_int, @intCast(result)),
                pnwritten.*,
                @as(c_int, @intFromBool(stream.body_eos)),
                nghttp2_session_get_stream_remote_window_size(ctx.h2, stream.id),
                nghttp2_session_get_remote_window_size(ctx.h2),
                io_buffers.Curl_bufq_len(&stream.sendbuf),
                io_buffers.Curl_bufq_len(&ctx.outbufq),
            },
        );
    } else {
        trcCf(
            data,
            cf,
            "cf_send(len=%zu) -> %d, %zu, connection-window=%d, nw_send_buffer(%zu)",
            .{
                len,
                @as(c_int, @intCast(result)),
                pnwritten.*,
                nghttp2_session_get_remote_window_size(ctx.h2),
                io_buffers.Curl_bufq_len(&ctx.outbufq),
            },
        );
    }
    return result;
}

fn cf_h2_flush(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const stream = h2StreamCtx(ctx, data);
    var save: cf_call_data = undefined;
    var result: CURLcode = CURLE_OK;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    if (stream) |s| {
        if (!io_buffers.Curl_bufq_is_empty(&s.sendbuf)) {
            const rv = nghttp2_session_resume_data(ctx.h2, s.id);
            if (nghttp2_is_fatal(rv) != 0) {
                result = CURLE_SEND_ERROR;
                return finishCfH2Flush(cf, ctx, data, stream, result);
            }
        }
    }

    result = h2_progress_egress(cf, data);
    return finishCfH2Flush(cf, ctx, data, stream, result);
}

fn finishCfH2Flush(
    cf: *Curl_cfilter,
    ctx: *cf_h2_ctx,
    data: ?*Curl_easy,
    stream_opt: ?*h2_stream_ctx,
    result: CURLcode,
) CURLcode {
    if (stream_opt) |stream| {
        trcCf(
            data,
            cf,
            "[%d] flush -> %d, h2 windows %d-%d (stream-conn), buffers %zu-%zu (stream-conn)",
            .{
                stream.id,
                @as(c_int, @intCast(result)),
                nghttp2_session_get_stream_remote_window_size(ctx.h2, stream.id),
                nghttp2_session_get_remote_window_size(ctx.h2),
                io_buffers.Curl_bufq_len(&stream.sendbuf),
                io_buffers.Curl_bufq_len(&ctx.outbufq),
            },
        );
    } else {
        trcCf(
            data,
            cf,
            "flush -> %d, connection-window=%d, nw_send_buffer(%zu)",
            .{
                @as(c_int, @intCast(result)),
                nghttp2_session_get_remote_window_size(ctx.h2),
                io_buffers.Curl_bufq_len(&ctx.outbufq),
            },
        );
    }
    return result;
}

fn cf_h2_adjust_pollset(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const ps_ptr: *headers_sock.EasyPollset = @ptrCast(@alignCast(ps));
    var save: cf_call_data = undefined;
    var want_recv = false;
    var want_send = false;
    var result: CURLcode = CURLE_OK;

    if (ctx.h2 == null)
        return CURLE_OK;

    const sock = Curl_conn_cf_get_socket(cf, data);
    headers_sock.Curl_pollset_check(data, ps_ptr, sock, &want_recv, &want_send);
    if (want_recv or want_send) {
        const stream = h2StreamCtx(ctx, data);
        cfDataSave(&save, &ctx.call_data, data);
        defer cfDataRestore(&ctx.call_data, save);
        const c_exhaust = want_send and (nghttp2_session_get_remote_window_size(ctx.h2) == 0);
        const s_exhaust = want_send and stream != null and stream.?.id >= 0 and
            (nghttp2_session_get_stream_remote_window_size(ctx.h2, stream.?.id) == 0);
        want_recv = want_recv or c_exhaust or s_exhaust;
        want_send = (!s_exhaust and want_send) or
            (!c_exhaust and nghttp2_session_want_write(ctx.h2) != 0) or
            !io_buffers.Curl_bufq_is_empty(&ctx.outbufq);

        result = headers_sock.Curl_pollset_set(data, ps_ptr, sock, want_recv, want_send);
    } else if (ctx.sent_goaway and !cf.isShutdown()) {
        cfDataSave(&save, &ctx.call_data, data);
        defer cfDataRestore(&ctx.call_data, save);
        want_send = (nghttp2_session_want_write(ctx.h2) != 0) or
            !io_buffers.Curl_bufq_is_empty(&ctx.outbufq);
        want_recv = nghttp2_session_want_read(ctx.h2) != 0;
        result = headers_sock.Curl_pollset_set(data, ps_ptr, sock, want_recv, want_send);
    }
    return result;
}

fn cf_h2_ctx_open(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var stream: ?*h2_stream_ctx = null;
    var result: CURLcode = CURLE_OUT_OF_MEMORY;
    var cbs: ?*nghttp2_session_callbacks = null;

    defer {
        if (cbs != null)
            nghttp2_session_callbacks_del(cbs);
    }

    var rc = nghttp2_session_callbacks_new(&cbs);
    if (rc != 0) {
        failf(data, "Could not initialize nghttp2 callbacks", .{});
        return result;
    }

    nghttp2_session_callbacks_set_send_callback(cbs, send_callback);
    nghttp2_session_callbacks_set_on_frame_recv_callback(cbs, on_frame_recv);
    nghttp2_session_callbacks_set_on_invalid_frame_recv_callback(cbs, cf_h2_on_invalid_frame_recv);
    nghttp2_session_callbacks_set_on_frame_send_callback(cbs, on_frame_send);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(cbs, on_data_chunk_recv);
    nghttp2_session_callbacks_set_on_stream_close_callback(cbs, on_stream_close);
    nghttp2_session_callbacks_set_on_header_callback(cbs, on_header);
    nghttp2_session_callbacks_set_error_callback2(cbs, error_callback);

    rc = h2_client_new(cf, cbs);
    if (rc != 0) {
        failf(data, "Could not initialize nghttp2", .{});
        return result;
    }

    ctx.max_concurrent_streams = if (Curl_h2_has_multi(data))
        Curl_h2_multi_max_concurrent_streams(data)
    else
        DEFAULT_MAX_CONCURRENT_STREAMS;

    if (ctx.via_h1_upgrade) {
        var binsettings: [H2_BINSETTINGS_LEN]u8 = undefined;
        var binlen: usize = 0;

        const rclen = populate_binsettings(&binsettings, data);
        if (!sztouz(rclen, &binlen) or binlen == 0) {
            failf(data, "nghttp2 unexpectedly failed on pack_settings_payload", .{});
            result = CURLE_FAILED_INIT;
            return result;
        }

        result = http2_data_setup(cf, data, &stream);
        if (result != CURLE_OK)
            return result;

        stream.?.id = 1;
        rc = nghttp2_session_upgrade2(
            ctx.h2,
            &binsettings,
            binlen,
            @intFromBool(Curl_h2_state_httpreq(data) == HTTPREQ_HEAD),
            null,
        );
        if (rc != 0) {
            failf(data, "nghttp2_session_upgrade2() failed: %s(%d)", .{ nghttp2_strerror(rc), rc });
            result = CURLE_HTTP2;
            return result;
        }

        rc = nghttp2_session_set_stream_user_data(ctx.h2, stream.?.id, stream);
        if (rc != 0) {
            infof(data, "http/2: failed to set user_data for stream %d", .{stream.?.id});
        }
        trcCf(data, cf, "created session via Upgrade", .{});
    } else {
        var iv: [H2_SETTINGS_IV_LEN]nghttp2_settings_entry = undefined;
        const ivlen = populate_settings(&iv, data, ctx);
        rc = nghttp2_submit_settings(ctx.h2, NGHTTP2_FLAG_NONE, &iv, ivlen);
        if (rc != 0) {
            failf(data, "nghttp2_submit_settings() failed: %s(%d)", .{ nghttp2_strerror(rc), rc });
            result = CURLE_HTTP2;
            return result;
        }
    }

    rc = nghttp2_session_set_local_window_size(ctx.h2, NGHTTP2_FLAG_NONE, 0, HTTP2_HUGE_WINDOW_SIZE);
    if (rc != 0) {
        failf(data, "nghttp2_session_set_local_window_size() failed: %s(%d)", .{ nghttp2_strerror(rc), rc });
        result = CURLE_HTTP2;
        return result;
    }

    result = CURLE_OK;
    trcCf(
        data,
        cf,
        "[0] created h2 session%s",
        .{@as([*:0]const u8, if (ctx.via_h1_upgrade) " (via h1 upgrade)" else "")},
    );
    return result;
}

fn cf_h2_connect(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    var save: cf_call_data = undefined;
    var first_time = false;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    if (cf.next) |next| {
        if (!next.isConnected()) {
            result = Curl_conn_cf_connect(next, data, done);
            if (result != CURLE_OK or !done.*)
                return result;
        }
    }

    done.* = false;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    if (ctx.h2 == null) {
        result = cf_h2_ctx_open(cf, data);
        if (result != CURLE_OK) {
            trcCf(data, cf, "cf_connect() -> %d, %d, ", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
            return result;
        }
        first_time = true;
    }

    if (!first_time) {
        result = h2_progress_ingress(cf, data, 0);
        if (result != CURLE_OK) {
            trcCf(data, cf, "cf_connect() -> %d, %d, ", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
            return result;
        }
    }

    result = h2_progress_egress(cf, data);
    if (result != CURLE_OK and result != CURLE_AGAIN) {
        trcCf(data, cf, "cf_connect() -> %d, %d, ", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
        return result;
    }

    done.* = true;
    cf.setConnected(true);
    result = CURLE_OK;

    trcCf(data, cf, "cf_connect() -> %d, %d, ", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
    return result;
}

fn cf_h2_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    _ = data;
    if (cf.ctx) |raw| {
        const ctx: *cf_h2_ctx = @ptrCast(@alignCast(raw));
        cf_h2_ctx_free(ctx);
        cf.ctx = null;
    }
}

fn cf_h2_shutdown(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;
    var result: CURLcode = CURLE_OK;

    if (!cf.isConnected() or ctx.h2 == null or cf.isShutdown() or ctx.conn_closed) {
        done.* = true;
        return CURLE_OK;
    }

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    if (!ctx.sent_goaway) {
        ctx.sent_goaway = true;
        const rv = nghttp2_submit_goaway(
            ctx.h2,
            NGHTTP2_FLAG_NONE,
            ctx.local_max_sid,
            0,
            "shutdown",
            "shutdown".len + 1,
        );
        if (rv != 0) {
            failf(data, "nghttp2_submit_goaway() failed: %s(%d)", .{ nghttp2_strerror(rv), rv });
            result = CURLE_SEND_ERROR;
            cf.setShutdown(result != CURLE_OK or done.*);
            return result;
        }
    }

    result = CURLE_OK;
    if (nghttp2_session_want_write(ctx.h2) != 0 or !io_buffers.Curl_bufq_is_empty(&ctx.outbufq))
        result = h2_progress_egress(cf, data);
    if (result == CURLE_OK and nghttp2_session_want_read(ctx.h2) != 0)
        result = h2_progress_ingress(cf, data, 0);

    if (result == CURLE_AGAIN)
        result = CURLE_OK;

    done.* = ctx.conn_closed or
        (result == CURLE_OK and
            nghttp2_session_want_write(ctx.h2) == 0 and
            nghttp2_session_want_read(ctx.h2) == 0 and
            io_buffers.Curl_bufq_is_empty(&ctx.outbufq));

    cf.setShutdown(result != CURLE_OK or done.*);
    return result;
}

fn http2_data_pause(cf: *Curl_cfilter, data: ?*Curl_easy, pause: bool) CURLcode {
    const ctx_raw = cf.ctx orelse return CURLE_OK;
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(ctx_raw));
    const stream = h2StreamCtx(ctx, data);

    if (ctx.h2 != null and stream != null) {
        const s = stream.?;
        s.write_paused = pause;
        const result = cf_h2_update_local_win(cf, data, s);
        if (result != CURLE_OK)
            return result;

        _ = h2_progress_egress(cf, data);

        if (!pause) {
            Curl_multi_mark_dirty(data);
        }
        trcCf(
            data,
            cf,
            "[%d] stream now %spaused",
            .{ s.id, @as([*:0]const u8, if (pause) "" else "un") },
        );
    }
    return CURLE_OK;
}

fn cf_h2_cntrl(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = arg2;
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    var save: cf_call_data = undefined;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    switch (event) {
        CF_CTRL_DATA_SETUP => {},
        CF_CTRL_DATA_PAUSE => {
            result = http2_data_pause(cf, data, arg1 != 0);
        },
        CF_CTRL_FLUSH => {
            result = cf_h2_flush(cf, data);
        },
        CF_CTRL_DATA_DONE => {
            http2_data_done(cf, data);
        },
        CF_CTRL_CONN_INFO_UPDATE => {
            if (cf.sockindex == 0 and cf.isConnected()) {
                Curl_h2_conn_set_http20_multiplex(cf.conn);
            }
        },
        else => {},
    }
    return result;
}

fn cf_h2_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool {
    if (cf.ctx) |raw| {
        const ctx: *cf_h2_ctx = @ptrCast(@alignCast(raw));
        if (!io_buffers.Curl_bufq_is_empty(&ctx.inbufq))
            return true;
    }
    if (cf.next) |next| {
        return next.cft.has_data_pending(next, data);
    }
    return false;
}

fn cf_h2_is_alive(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    input_pending: *bool,
) callconv(.c) bool {
    const ctx_opt: ?*cf_h2_ctx = if (cf.ctx) |raw| @ptrCast(@alignCast(raw)) else null;
    input_pending.* = false;
    const ctx = ctx_opt orelse return false;
    var save: cf_call_data = undefined;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    const alive = (ctx.h2 != null) and http2_connisalive(cf, data, input_pending);
    trcCf(
        data,
        cf,
        "conn alive -> %d, input_pending=%d",
        .{ @as(c_int, @intFromBool(alive)), @as(c_int, @intFromBool(input_pending.*)) },
    );
    return alive;
}

fn cf_h2_keep_alive(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    const result = http2_send_ping(cf, data);
    return result;
}

fn cf_h2_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;

    switch (query) {
        CF_QUERY_MAX_CONCURRENT => {
            cfDataSave(&save, &ctx.call_data, data);
            defer cfDataRestore(&ctx.call_data, save);
            const effective_max: usize = if (ctx.h2 == null or nghttp2_session_check_request_allowed(ctx.h2) == 0)
                Curl_h2_conn_attached_xfers(cf.conn)
            else
                ctx.max_concurrent_streams;
            if (pres1) |p1| {
                p1.* = if (effective_max > std.math.maxInt(c_int))
                    std.math.maxInt(c_int)
                else
                    @intCast(effective_max);
            }
            return CURLE_OK;
        },
        CF_QUERY_STREAM_ERROR => {
            const stream = h2StreamCtx(ctx, data);
            if (pres1) |p1| {
                p1.* = if (stream) |s| @bitCast(s.@"error") else 0;
            }
            return CURLE_OK;
        },
        CF_QUERY_NEED_FLUSH => {
            const stream = h2StreamCtx(ctx, data);
            if (!io_buffers.Curl_bufq_is_empty(&ctx.outbufq) or
                (stream != null and !io_buffers.Curl_bufq_is_empty(&stream.?.sendbuf)))
            {
                if (pres1) |p1| p1.* = 1;
                return CURLE_OK;
            }
        },
        CF_QUERY_HTTP_VERSION => {
            if (pres1) |p1| p1.* = 20;
            return CURLE_OK;
        },
        else => {},
    }
    if (cf.next) |next| {
        return next.cft.query(next, data, query, pres1, pres2);
    }
    return CURLE_UNKNOWN_OPTION;
}

pub var Curl_cft_nghttp2: Curl_cftype = .{
    .name = "HTTP/2",
    .flags = CF_TYPE_MULTIPLEX | CF_TYPE_HTTP,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_h2_destroy,
    .do_connect = cf_h2_connect,
    .do_shutdown = cf_h2_shutdown,
    .adjust_pollset = cf_h2_adjust_pollset,
    .has_data_pending = cf_h2_data_pending,
    .do_send = cf_h2_send,
    .do_recv = cf_h2_recv,
    .cntrl = cf_h2_cntrl,
    .is_alive = cf_h2_is_alive,
    .keep_alive = cf_h2_keep_alive,
    .query = cf_h2_query,
};

fn http2_cfilter_add(
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    via_h1_upgrade: bool,
) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const raw = mem.calloc(1, @sizeOf(cf_h2_ctx)) orelse {
        pcf.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(raw));
    cf_h2_ctx_init(ctx, via_h1_upgrade);

    const result = Curl_cf_create(&cf, &Curl_cft_nghttp2, ctx);
    if (result != CURLE_OK) {
        cf_h2_ctx_free(ctx);
        pcf.* = null;
        return result;
    }

    Curl_conn_cf_add(data, conn, sockindex, cf.?);
    pcf.* = cf;
    return CURLE_OK;
}

fn http2_cfilter_insert_after(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    via_h1_upgrade: bool,
) CURLcode {
    _ = data;
    var cf_h2: ?*Curl_cfilter = null;
    const raw = mem.calloc(1, @sizeOf(cf_h2_ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(raw));
    cf_h2_ctx_init(ctx, via_h1_upgrade);

    const result = Curl_cf_create(&cf_h2, &Curl_cft_nghttp2, ctx);
    if (result != CURLE_OK) {
        cf_h2_ctx_free(ctx);
        return result;
    }

    Curl_conn_cf_insert_after(cf, cf_h2.?);
    return CURLE_OK;
}

pub fn Curl_http2_may_switch(data: ?*Curl_easy) callconv(.c) bool {
    return Curl_h2_may_switch_check(data);
}

pub fn Curl_http2_switch(data: ?*Curl_easy) callconv(.c) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const conn = Curl_h2_easy_conn(data);

    const result = http2_cfilter_add(&cf, data, conn, FIRSTSOCKET, false);
    if (result != CURLE_OK)
        return result;
    trcCf(data, cf, "switching connection to HTTP/2", .{});

    if (cf.?.next != null) {
        var done = false;
        return Curl_conn_cf_connect(cf, data, &done);
    }
    return CURLE_OK;
}

pub fn Curl_http2_switch_at(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode {
    const result = http2_cfilter_insert_after(cf, data, false);
    if (result != CURLE_OK)
        return result;

    const cf_h2 = cf.next.?;
    if (cf_h2.next != null) {
        var done = false;
        return Curl_conn_cf_connect(cf_h2, data, &done);
    }
    return CURLE_OK;
}

pub fn Curl_http2_upgrade(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    mem_ptr: [*]const u8,
    nread: usize,
) callconv(.c) CURLcode {
    var cf: ?*Curl_cfilter = null;
    var result = http2_cfilter_add(&cf, data, conn, sockindex, true);
    if (result != CURLE_OK)
        return result;
    trcCf(data, cf, "upgrading connection to HTTP/2", .{});

    const ctx: *cf_h2_ctx = @ptrCast(@alignCast(cf.?.ctx.?));
    Curl_h2_set_upgraded_req(data);

    if (nread > 0) {
        var copied: usize = 0;
        result = io_buffers.Curl_bufq_write(&ctx.inbufq, mem_ptr, nread, &copied);
        if (result != CURLE_OK) {
            failf(data, "error on copying HTTP Upgrade response: %d", .{@as(c_int, @intCast(result))});
            return CURLE_RECV_ERROR;
        }
        if (copied < nread) {
            failf(
                data,
                "connection buffer size could not take all data from HTTP Upgrade response header: copied=%zu, datalen=%zu",
                .{ copied, nread },
            );
            return CURLE_HTTP2;
        }
        infof(
            data,
            "Copied HTTP/2 data in stream buffer to connection buffer after upgrade: len=%zu",
            .{nread},
        );
    }

    if (cf.?.next != null) {
        var done = false;
        result = Curl_conn_cf_connect(cf, data, &done);
        if (result == CURLE_OK) {
            _ = cf.?.cft.cntrl(cf.?, data, CF_CTRL_CONN_INFO_UPDATE, 0, null);
        }
    }
    return result;
}

pub fn Curl_h2_http_1_1_error(data: ?*Curl_easy) callconv(.c) bool {
    const conn = Curl_h2_easy_conn(data);
    if (Curl_conn_http_version(data, conn) == 20) {
        const err = Curl_conn_get_stream_error(data, conn, FIRSTSOCKET);
        return err == @as(c_int, @intCast(NGHTTP2_HTTP_1_1_REQUIRED));
    }
    return false;
}

// ============================================================================
// 2. lib/cf-h2-proxy.c — HTTP/2 Proxy Tunnel Connection Filter
// ============================================================================

const PROXY_H2_CHUNK_SIZE: usize = 16 * 1024;
const PROXY_HTTP2_HUGE_WINDOW_SIZE: i32 = 100 * 1024 * 1024;
const H2_TUNNEL_WINDOW_SIZE: u32 = 10 * 1024 * 1024;
const PROXY_H2_NW_RECV_CHUNKS: usize = H2_TUNNEL_WINDOW_SIZE / PROXY_H2_CHUNK_SIZE;
const PROXY_H2_NW_SEND_CHUNKS: usize = 1;
const H2_TUNNEL_RECV_CHUNKS: usize = H2_TUNNEL_WINDOW_SIZE / PROXY_H2_CHUNK_SIZE;
const H2_TUNNEL_SEND_CHUNKS: usize = (128 * 1024) / PROXY_H2_CHUNK_SIZE;

pub const h2_tunnel_state = enum(c_uint) {
    H2_TUNNEL_INIT = 0,
    H2_TUNNEL_CONNECT = 1,
    H2_TUNNEL_RESPONSE = 2,
    H2_TUNNEL_ESTABLISHED = 3,
    H2_TUNNEL_FAILED = 4,
};

pub const tunnel_stream = extern struct {
    resp: ?*http_resp,
    recvbuf: bufq,
    sendbuf: bufq,
    authority: ?[*:0]u8,
    stream_id: i32,
    @"error": u32,
    state: h2_tunnel_state,
    has_final_response: bool,
    closed: bool,
    reset: bool,
};

pub const cf_h2_proxy_ctx = extern struct {
    h2: ?*nghttp2_session,
    call_data: cf_call_data,
    inbufq: bufq,
    outbufq: bufq,
    peer: ?*Curl_peer,
    dest: ?*Curl_peer,
    tunnel: tunnel_stream,
    goaway_error: i32,
    remote_max_sid: i32,
    conn_closed: bool,
    rcvd_goaway: bool,
    sent_goaway: bool,
    nw_out_blocked: bool,
    udp_tunnel: bool,
};

inline fn peerIsIpv6(peer: *const Curl_peer) bool {
    return (peer.flags & 0x04) != 0;
}

fn tunnel_stream_init(ts: *tunnel_stream, dest: *Curl_peer) CURLcode {
    ts.state = .H2_TUNNEL_INIT;
    ts.stream_id = -1;
    io_buffers.Curl_bufq_init2(
        &ts.recvbuf,
        PROXY_H2_CHUNK_SIZE,
        H2_TUNNEL_RECV_CHUNKS,
        io_buffers.BUFQ_OPT_SOFT_LIMIT,
    );
    io_buffers.Curl_bufq_init(&ts.sendbuf, PROXY_H2_CHUNK_SIZE, H2_TUNNEL_SEND_CHUNKS);

    const is_ipv6 = peerIsIpv6(dest);
    ts.authority = curl_maprintf(
        "%s%s%s:%u",
        @as([*:0]const u8, if (is_ipv6) "[" else ""),
        dest.hostname,
        @as([*:0]const u8, if (is_ipv6) "]" else ""),
        @as(c_uint, dest.port),
    );
    if (ts.authority == null)
        return CURLE_OUT_OF_MEMORY;

    return CURLE_OK;
}

fn tunnel_stream_reset(ts: *tunnel_stream) void {
    Curl_http_resp_free(ts.resp);
    ts.resp = null;
    io_buffers.Curl_bufq_reset(&ts.recvbuf);
    io_buffers.Curl_bufq_reset(&ts.sendbuf);
    ts.stream_id = -1;
    ts.@"error" = 0;
    ts.has_final_response = false;
    ts.closed = false;
    ts.reset = false;
    ts.state = .H2_TUNNEL_INIT;
}

fn tunnel_stream_clear(ts: *tunnel_stream) void {
    Curl_http_resp_free(ts.resp);
    io_buffers.Curl_bufq_free(&ts.recvbuf);
    io_buffers.Curl_bufq_free(&ts.sendbuf);
    mem.free(ts.authority);
    ts.* = std.mem.zeroes(tunnel_stream);
    ts.state = .H2_TUNNEL_INIT;
}

fn h2_tunnel_go_state(
    cf: *Curl_cfilter,
    ts: *tunnel_stream,
    new_state: h2_tunnel_state,
    data: ?*Curl_easy,
    udp_tunnel: bool,
) void {
    if (ts.state == new_state)
        return;

    switch (ts.state) {
        .H2_TUNNEL_CONNECT => {
            Curl_h2_clear_ignorebody(data);
        },
        else => {},
    }

    switch (new_state) {
        .H2_TUNNEL_INIT => {
            trcCf(data, cf, "[%d] new tunnel state 'init'", .{ts.stream_id});
            tunnel_stream_reset(ts);
        },
        .H2_TUNNEL_CONNECT => {
            trcCf(data, cf, "[%d] new tunnel state 'connect'", .{ts.stream_id});
            ts.state = .H2_TUNNEL_CONNECT;
        },
        .H2_TUNNEL_RESPONSE => {
            trcCf(data, cf, "[%d] new tunnel state 'response'", .{ts.stream_id});
            ts.state = .H2_TUNNEL_RESPONSE;
        },
        .H2_TUNNEL_ESTABLISHED => {
            trcCf(data, cf, "[%d] new tunnel state 'established'", .{ts.stream_id});
            infof(
                data,
                "CONNECT%s phase completed for HTTP/2 proxy",
                .{@as([*:0]const u8, if (udp_tunnel) "-UDP" else "")},
            );
            Curl_proxy_start_connect_auth(data);
            ts.state = .H2_TUNNEL_ESTABLISHED;
            Curl_proxy_clear_hd_proxy_auth(data);
        },
        .H2_TUNNEL_FAILED => {
            trcCf(data, cf, "[%d] new tunnel state 'failed'", .{ts.stream_id});
            ts.state = .H2_TUNNEL_FAILED;
            Curl_proxy_clear_hd_proxy_auth(data);
        },
    }
}

fn cf_h2_proxy_ctx_clear(ctx: *cf_h2_proxy_ctx) void {
    const save = ctx.call_data;
    if (ctx.h2) |h2| {
        nghttp2_session_del(h2);
    }
    io_buffers.Curl_bufq_free(&ctx.inbufq);
    io_buffers.Curl_bufq_free(&ctx.outbufq);
    altsvc_hsts_peer.Curl_peer_unlink(&ctx.peer);
    altsvc_hsts_peer.Curl_peer_unlink(&ctx.dest);
    tunnel_stream_clear(&ctx.tunnel);
    ctx.* = std.mem.zeroes(cf_h2_proxy_ctx);
    ctx.call_data = save;
}

fn cf_h2_proxy_ctx_free(ctx_opt: ?*cf_h2_proxy_ctx) void {
    if (ctx_opt) |ctx| {
        cf_h2_proxy_ctx_clear(ctx);
        ctx.* = std.mem.zeroes(cf_h2_proxy_ctx);
        mem.free(ctx);
    }
}

fn drain_tunnel(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    tunnel: *tunnel_stream,
) void {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    if (!tunnel.closed and !tunnel.reset and
        (!io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf) or
            !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.recvbuf)))
    {
        Curl_multi_mark_dirty(data);
    }
}

fn proxy_h2_nw_out_writer(
    writer_ctx: ?*anyopaque,
    buf: [*]const u8,
    buflen: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    pnwritten.* = 0;
    if (writer_ctx) |raw| {
        const cf: *Curl_cfilter = @ptrCast(@alignCast(raw));
        const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
        const data = ctx.call_data.data;
        const result = Curl_conn_cf_send(cf.next, data, buf, buflen, false, pnwritten);
        trcCf(data, cf, "[0] nw_out_writer(len=%zu) -> %d, %zu", .{ buflen, @as(c_int, @intCast(result)), pnwritten.* });
        return result;
    }
    return CURLE_FAILED_INIT;
}

fn proxy_h2_client_new(cf: *Curl_cfilter, cbs: ?*nghttp2_session_callbacks) c_int {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var o: ?*nghttp2_option = null;
    var h2_mem = nghttp2_mem{
        .mem_user_data = null,
        .malloc = Curl_nghttp2_malloc,
        .free = Curl_nghttp2_free,
        .calloc = Curl_nghttp2_calloc,
        .realloc = Curl_nghttp2_realloc,
    };

    var rc = nghttp2_option_new(&o);
    if (rc != 0)
        return rc;
    nghttp2_option_set_no_auto_window_update(o, 1);
    nghttp2_option_set_no_rfc9113_leading_and_trailing_ws_validation(o, 1);
    rc = nghttp2_session_client_new3(&ctx.h2, cbs, cf, o, &h2_mem);
    nghttp2_option_del(o);
    return rc;
}

fn proxy_h2_should_close_session(ctx: *cf_h2_proxy_ctx) bool {
    return nghttp2_session_want_read(ctx.h2) == 0 and
        nghttp2_session_want_write(ctx.h2) == 0;
}

fn proxy_h2_nw_out_flush(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var nwritten: usize = 0;

    if (io_buffers.Curl_bufq_is_empty(&ctx.outbufq))
        return CURLE_OK;

    const result = io_buffers.Curl_bufq_pass(&ctx.outbufq, proxy_h2_nw_out_writer, cf, &nwritten);
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            trcCf(data, cf, "[0] flush nw send buffer(%zu) -> EAGAIN", .{io_buffers.Curl_bufq_len(&ctx.outbufq)});
            ctx.nw_out_blocked = true;
        }
        return result;
    }
    trcCf(data, cf, "[0] nw send buffer flushed", .{});
    return if (io_buffers.Curl_bufq_is_empty(&ctx.outbufq)) CURLE_OK else CURLE_AGAIN;
}

fn proxy_h2_process_pending_input(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var buf: ?[*]const u8 = null;
    var blen: usize = 0;
    var nread: usize = 0;

    while (io_buffers.Curl_bufq_peek(&ctx.inbufq, &buf, &blen)) {
        const rv = nghttp2_session_mem_recv(ctx.h2, buf.?, blen);
        trcCf(data, cf, "[0] %zu bytes to nghttp2 -> %zd", .{ blen, rv });
        if (!sztouz(rv, &nread)) {
            failf(
                data,
                "process_pending_input: nghttp2_session_mem_recv() returned %zd:%s",
                .{ rv, nghttp2_strerror(@intCast(rv)) },
            );
            return CURLE_RECV_ERROR;
        } else if (nread == 0) {
            break;
        }
        io_buffers.Curl_bufq_skip(&ctx.inbufq, nread);
        if (io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) {
            trcCf(data, cf, "[0] all data in connection buffer processed", .{});
            break;
        } else {
            trcCf(
                data,
                cf,
                "[0] process_pending_input: %zu bytes left in connection buffer",
                .{io_buffers.Curl_bufq_len(&ctx.inbufq)},
            );
        }
    }
    return CURLE_OK;
}

fn proxy_h2_progress_ingress(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;

    if (!io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) {
        trcCf(data, cf, "[0] process %zu bytes in connection buffer", .{io_buffers.Curl_bufq_len(&ctx.inbufq)});
        result = proxy_h2_process_pending_input(cf, data);
        if (result != CURLE_OK)
            return result;
    }

    while (!ctx.conn_closed and
        !ctx.tunnel.closed and
        io_buffers.Curl_bufq_is_empty(&ctx.inbufq) and
        !io_buffers.Curl_bufq_is_full(&ctx.tunnel.recvbuf))
    {
        result = Curl_cf_recv_bufq(cf.next, data, &ctx.inbufq, 0, &nread);
        trcCf(
            data,
            cf,
            "[0] read %zu bytes nw data -> %d, %zu",
            .{ io_buffers.Curl_bufq_len(&ctx.inbufq), @as(c_int, @intCast(result)), nread },
        );
        if (result != CURLE_OK) {
            if (result != CURLE_AGAIN) {
                failf(data, "Failed receiving HTTP2 proxy data", .{});
                return result;
            }
            break;
        } else if (nread == 0) {
            trcCf(data, cf, "server closed connection", .{});
            ctx.conn_closed = true;
            break;
        }

        result = proxy_h2_process_pending_input(cf, data);
        if (result != CURLE_OK)
            return result;
    }

    return CURLE_OK;
}

fn proxy_h2_progress_egress(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var rv: c_int = 0;

    ctx.nw_out_blocked = false;
    while (rv == 0 and !ctx.nw_out_blocked and nghttp2_session_want_write(ctx.h2) != 0) {
        rv = nghttp2_session_send(ctx.h2);
    }

    if (nghttp2_is_fatal(rv) != 0) {
        trcCf(data, cf, "[0] nghttp2_session_send error (%s)%d", .{ nghttp2_strerror(rv), rv });
        return CURLE_SEND_ERROR;
    }
    return proxy_h2_nw_out_flush(cf, data);
}

fn on_session_send(
    h2: ?*nghttp2_session,
    buf: [*]const u8,
    blen: usize,
    flags: c_int,
    userp: ?*anyopaque,
) callconv(.c) isize {
    _ = h2;
    _ = flags;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;
    var nwritten: usize = 0;

    const result = io_buffers.Curl_bufq_write_pass(
        &ctx.outbufq,
        buf,
        blen,
        proxy_h2_nw_out_writer,
        cf,
        &nwritten,
    );
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            ctx.nw_out_blocked = true;
            return NGHTTP2_ERR_WOULDBLOCK;
        }
        failf(data, "Failed sending HTTP2 data", .{});
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    if (nwritten == 0)
        return NGHTTP2_ERR_WOULDBLOCK;

    return if (nwritten > std.math.maxInt(isize))
        NGHTTP2_ERR_CALLBACK_FAILURE
    else
        @intCast(nwritten);
}

fn proxy_h2_on_frame_send(
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;

    if (trcCfIsVerbose(cf, data)) {
        var buffer: [256]u8 = undefined;
        const len = Curl_nghttp2_fr_print(frame, &buffer, buffer.len - 1);
        if (len >= 0 and @as(usize, @intCast(len)) < buffer.len) {
            buffer[@intCast(len)] = 0;
        } else {
            buffer[buffer.len - 1] = 0;
        }
        trcCf(data, cf, "[%d] -> %s", .{ frame.hd.stream_id, @as([*:0]const u8, @ptrCast(&buffer)) });
    }
    return 0;
}

fn proxy_h2_on_frame_recv(
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;
    const stream_id = frame.hd.stream_id;

    if (trcCfIsVerbose(cf, data)) {
        var buffer: [256]u8 = undefined;
        const len = Curl_nghttp2_fr_print(frame, &buffer, buffer.len - 1);
        if (len >= 0 and @as(usize, @intCast(len)) < buffer.len) {
            buffer[@intCast(len)] = 0;
        } else {
            buffer[buffer.len - 1] = 0;
        }
        trcCf(data, cf, "[%d] <- %s", .{ frame.hd.stream_id, @as([*:0]const u8, @ptrCast(&buffer)) });
    }

    if (stream_id == 0) {
        switch (frame.hd.type) {
            NGHTTP2_SETTINGS => {
                if (Curl_h2_req_want_send(data)) {
                    drain_tunnel(cf, data, &ctx.tunnel);
                }
            },
            NGHTTP2_GOAWAY => {
                ctx.rcvd_goaway = true;
                ctx.remote_max_sid = frame.goaway.last_stream_id;
                if (data != null) {
                    infof(
                        data,
                        "received GOAWAY, error=%u, last_stream=%d",
                        .{ frame.goaway.error_code, ctx.remote_max_sid },
                    );
                }
            },
            else => {},
        }
        return 0;
    }

    if (stream_id != ctx.tunnel.stream_id) {
        trcCf(data, cf, "[%d] rcvd FRAME not for tunnel", .{stream_id});
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    switch (frame.hd.type) {
        NGHTTP2_HEADERS => {
            const resp = ctx.tunnel.resp orelse return NGHTTP2_ERR_CALLBACK_FAILURE;
            trcCf(data, cf, "[%d] got http status: %d", .{ stream_id, resp.status });
            if (!ctx.tunnel.has_final_response and @divTrunc(resp.status, 100) != 1)
                ctx.tunnel.has_final_response = true;
        },
        NGHTTP2_WINDOW_UPDATE => {
            if (Curl_h2_req_want_send(data)) {
                drain_tunnel(cf, data, &ctx.tunnel);
            }
        },
        NGHTTP2_RST_STREAM => {
            if (frame.rst_stream.error_code != 0)
                ctx.tunnel.reset = true;
        },
        else => {},
    }
    return 0;
}

fn proxy_h2_on_header(
    session: ?*nghttp2_session,
    frame: *const nghttp2_frame,
    name: [*]const u8,
    namelen: usize,
    value: [*]const u8,
    valuelen: usize,
    flags: u8,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;
    const stream_id = frame.hd.stream_id;

    if (stream_id != ctx.tunnel.stream_id) {
        trcCf(
            data,
            cf,
            "[%d] header for non-tunnel stream: %.*s: %.*s",
            .{ stream_id, @as(c_int, @intCast(namelen)), name, @as(c_int, @intCast(valuelen)), value },
        );
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }

    if (frame.hd.type == NGHTTP2_PUSH_PROMISE)
        return NGHTTP2_ERR_CALLBACK_FAILURE;

    if (ctx.tunnel.has_final_response)
        return 0;

    if (namelen == HTTP_PSEUDO_STATUS.len and
        std.mem.eql(u8, name[0..namelen], HTTP_PSEUDO_STATUS))
    {
        var http_status: i32 = 0;
        var resp: ?*http_resp = null;

        var result = Curl_http_decode_status(&http_status, value, valuelen);
        if (result != CURLE_OK)
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        result = Curl_http_resp_make(&resp, @intCast(http_status), null);
        if (result != CURLE_OK)
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        if (ctx.tunnel.resp) |old_resp| {
            Curl_http_resp_free(old_resp);
        }
        ctx.tunnel.resp = resp;
        trcCf(data, cf, "[%d] status: HTTP/2 %03d", .{ stream_id, ctx.tunnel.resp.?.status });
        return 0;
    }

    const resp = ctx.tunnel.resp orelse return NGHTTP2_ERR_CALLBACK_FAILURE;
    const result = io_buffers.Curl_dynhds_add(&resp.headers, name, namelen, value, valuelen);
    if (result != CURLE_OK)
        return NGHTTP2_ERR_CALLBACK_FAILURE;

    trcCf(
        data,
        cf,
        "[%d] header: %.*s: %.*s",
        .{ stream_id, @as(c_int, @intCast(namelen)), name, @as(c_int, @intCast(valuelen)), value },
    );
    return 0;
}

fn tunnel_send_callback(
    session: ?*nghttp2_session,
    stream_id: i32,
    buf: [*]u8,
    length: usize,
    data_flags: *u32,
    source: *nghttp2_data_source,
    userp: ?*anyopaque,
) callconv(.c) isize {
    _ = source;
    if (stream_id == 0)
        return NGHTTP2_ERR_INVALID_ARGUMENT;

    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;

    const raw_ts = nghttp2_session_get_stream_user_data(session, stream_id) orelse
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    const ts: *tunnel_stream = @ptrCast(@alignCast(raw_ts));

    var nread: usize = 0;
    const result = io_buffers.Curl_bufq_read(&ts.sendbuf, buf, length, &nread);
    if (result != CURLE_OK) {
        if (result != CURLE_AGAIN)
            return NGHTTP2_ERR_CALLBACK_FAILURE;
        return NGHTTP2_ERR_DEFERRED;
    }
    if (ts.closed and io_buffers.Curl_bufq_is_empty(&ts.sendbuf))
        data_flags.* = NGHTTP2_DATA_FLAG_EOF;

    trcCf(data, cf, "[%d] tunnel_send_callback -> %zu", .{ ts.stream_id, nread });
    return if (nread > std.math.maxInt(isize))
        NGHTTP2_ERR_CALLBACK_FAILURE
    else
        @intCast(nread);
}

fn tunnel_recv_callback(
    session: ?*nghttp2_session,
    flags: u8,
    stream_id: i32,
    mem_ptr: [*]const u8,
    len: usize,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var nwritten: usize = 0;

    if (stream_id != ctx.tunnel.stream_id)
        return NGHTTP2_ERR_CALLBACK_FAILURE;

    const result = io_buffers.Curl_bufq_write(&ctx.tunnel.recvbuf, mem_ptr, len, &nwritten);
    if (result != CURLE_OK) {
        if (result != CURLE_AGAIN)
            return NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

fn proxy_h2_on_stream_close(
    session: ?*nghttp2_session,
    stream_id: i32,
    error_code: u32,
    userp: ?*anyopaque,
) callconv(.c) c_int {
    _ = session;
    const cf: *Curl_cfilter = @ptrCast(@alignCast(userp.?));
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const data = ctx.call_data.data;

    if (stream_id != ctx.tunnel.stream_id)
        return 0;

    trcCf(
        data,
        cf,
        "[%d] proxy_h2_on_stream_close, %s (err %u)",
        .{ stream_id, nghttp2_http2_strerror(error_code), error_code },
    );
    ctx.tunnel.closed = true;
    ctx.tunnel.@"error" = error_code;
    if (error_code != 0)
        ctx.tunnel.reset = true;

    return 0;
}

fn proxy_h2_submit(
    pstream_id: *i32,
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    h2: ?*nghttp2_session,
    req: *httpreq,
    pri_spec: ?*const nghttp2_priority_spec,
    stream_user_data: ?*anyopaque,
    read_callback: ?nghttp2_data_source_read_callback,
    read_ctx: ?*anyopaque,
) CURLcode {
    _ = cf;
    var h2_headers: dynhds = undefined;
    var nva: ?[*]nghttp2_nv = null;
    var stream_id: i32 = -1;
    var nheader: usize = 0;
    var result: CURLcode = CURLE_OK;

    io_buffers.Curl_dynhds_init(&h2_headers, MAX_HTTP_RESP_HEADER_COUNT, DYN_HTTP_REQUEST);
    defer {
        mem.free(nva);
        io_buffers.Curl_dynhds_free(&h2_headers);
        pstream_id.* = stream_id;
    }

    result = Curl_http_req_to_h2(&h2_headers, req, data);
    if (result != CURLE_OK)
        return result;

    nva = io_buffers.Curl_dynhds_to_nva(&h2_headers, &nheader);
    if (nva == null) {
        result = CURLE_OUT_OF_MEMORY;
        return result;
    }

    if (read_callback) |cb| {
        var data_prd = nghttp2_data_provider{
            .source = .{ .ptr = read_ctx },
            .read_callback = cb,
        };
        stream_id = nghttp2_submit_request(h2, pri_spec, nva.?, nheader, &data_prd, stream_user_data);
    } else {
        stream_id = nghttp2_submit_request(h2, pri_spec, nva.?, nheader, null, stream_user_data);
    }

    if (stream_id < 0) {
        failf(
            data,
            "nghttp2_session_upgrade2() failed: %s(%d)",
            .{ nghttp2_strerror(stream_id), stream_id },
        );
        result = CURLE_SEND_ERROR;
        return result;
    }
    return CURLE_OK;
}

fn submit_CONNECT(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *tunnel_stream,
) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var req: ?*httpreq = null;

    var result = Curl_http_proxy_create_tunnel_request(
        &req,
        cf,
        data,
        ctx.peer,
        ctx.dest,
        PROXY_HTTP_V2,
        ctx.udp_tunnel,
    );
    if (result == CURLE_OK) {
        result = Curl_creader_set_null(data);
    }
    if (result == CURLE_OK) {
        result = proxy_h2_submit(
            &ts.stream_id,
            cf,
            data,
            ctx.h2,
            req.?,
            null,
            ts,
            tunnel_send_callback,
            cf,
        );
        if (result != CURLE_OK) {
            trcCf(
                data,
                cf,
                "[%d] send, nghttp2_submit_request error: %s",
                .{ ts.stream_id, nghttp2_strerror(ts.stream_id) },
            );
        }
    }

    if (req != null)
        Curl_http_req_free(req);
    if (result != CURLE_OK)
        failf(data, "Failed sending CONNECT to proxy", .{});
    return result;
}

fn inspect_response(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *tunnel_stream,
) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var res: proxy_inspect_result = .PROXY_INSPECT_OK;

    var result = Curl_http_proxy_inspect_tunnel_response(
        cf,
        data,
        ts.resp,
        ctx.udp_tunnel,
        &res,
    );
    if (result != CURLE_OK)
        return result;

    switch (res) {
        .PROXY_INSPECT_OK => {
            h2_tunnel_go_state(cf, ts, .H2_TUNNEL_ESTABLISHED, data, ctx.udp_tunnel);
        },
        .PROXY_INSPECT_FAILED => {
            h2_tunnel_go_state(cf, ts, .H2_TUNNEL_FAILED, data, ctx.udp_tunnel);
            result = CURLE_COULDNT_CONNECT;
        },
        .PROXY_INSPECT_AUTH_RETRY => {
            h2_tunnel_go_state(cf, ts, .H2_TUNNEL_INIT, data, ctx.udp_tunnel);
        },
    }
    return result;
}

fn H2_CONNECT(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *tunnel_stream,
) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;

    if (ctx.conn_closed) {
        failf(data, "proxy closed connection", .{});
        return CURLE_COULDNT_CONNECT;
    }

    while (true) {
        switch (ts.state) {
            .H2_TUNNEL_INIT => {
                trcCf(data, cf, "[0] CONNECT start for %s", .{ts.authority.?});
                result = submit_CONNECT(cf, data, ts);
                if (result != CURLE_OK)
                    break;
                h2_tunnel_go_state(cf, ts, .H2_TUNNEL_CONNECT, data, ctx.udp_tunnel);
                continue;
            },
            .H2_TUNNEL_CONNECT => {
                result = proxy_h2_progress_ingress(cf, data);
                if (result == CURLE_OK)
                    result = proxy_h2_progress_egress(cf, data);
                if (result != CURLE_OK and result != CURLE_AGAIN) {
                    h2_tunnel_go_state(cf, ts, .H2_TUNNEL_FAILED, data, ctx.udp_tunnel);
                    break;
                }

                if (ts.has_final_response) {
                    h2_tunnel_go_state(cf, ts, .H2_TUNNEL_RESPONSE, data, ctx.udp_tunnel);
                    result = inspect_response(cf, data, ts);
                    if (result != CURLE_OK)
                        break;
                } else {
                    result = CURLE_OK;
                    break;
                }
            },
            .H2_TUNNEL_RESPONSE => {
                result = inspect_response(cf, data, ts);
                if (result != CURLE_OK)
                    break;
            },
            .H2_TUNNEL_ESTABLISHED => return CURLE_OK,
            .H2_TUNNEL_FAILED => return CURLE_RECV_ERROR,
        }
        if (ts.state != .H2_TUNNEL_INIT)
            break;
    }

    if ((result != CURLE_OK and result != CURLE_AGAIN) or ctx.tunnel.closed)
        h2_tunnel_go_state(cf, ts, .H2_TUNNEL_FAILED, data, ctx.udp_tunnel);
    return result;
}

fn cf_h2_proxy_ctx_init(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OUT_OF_MEMORY;
    var cbs: ?*nghttp2_session_callbacks = null;

    defer {
        if (cbs != null)
            nghttp2_session_callbacks_del(cbs);
        trcCf(data, cf, "[0] init proxy ctx -> %d", .{@as(c_int, @intCast(result))});
    }

    ctx.tunnel = std.mem.zeroes(tunnel_stream);
    io_buffers.Curl_bufq_init(&ctx.inbufq, PROXY_H2_CHUNK_SIZE, PROXY_H2_NW_RECV_CHUNKS);
    io_buffers.Curl_bufq_init(&ctx.outbufq, PROXY_H2_CHUNK_SIZE, PROXY_H2_NW_SEND_CHUNKS);
    ctx.remote_max_sid = std.math.maxInt(i32);

    if (tunnel_stream_init(&ctx.tunnel, ctx.dest.?) != CURLE_OK)
        return result;

    var rc = nghttp2_session_callbacks_new(&cbs);
    if (rc != 0) {
        failf(data, "Could not initialize nghttp2 callbacks", .{});
        return result;
    }

    nghttp2_session_callbacks_set_send_callback(cbs, on_session_send);
    nghttp2_session_callbacks_set_on_frame_recv_callback(cbs, proxy_h2_on_frame_recv);
    nghttp2_session_callbacks_set_on_frame_send_callback(cbs, proxy_h2_on_frame_send);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(cbs, tunnel_recv_callback);
    nghttp2_session_callbacks_set_on_stream_close_callback(cbs, proxy_h2_on_stream_close);
    nghttp2_session_callbacks_set_on_header_callback(cbs, proxy_h2_on_header);

    rc = proxy_h2_client_new(cf, cbs);
    if (rc != 0) {
        failf(data, "Could not initialize nghttp2", .{});
        return result;
    }

    var iv = [3]nghttp2_settings_entry{
        .{
            .settings_id = NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS,
            .value = Curl_h2_multi_max_concurrent_streams(data),
        },
        .{
            .settings_id = NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE,
            .value = H2_TUNNEL_WINDOW_SIZE,
        },
        .{
            .settings_id = NGHTTP2_SETTINGS_ENABLE_PUSH,
            .value = 0,
        },
    };
    rc = nghttp2_submit_settings(ctx.h2, NGHTTP2_FLAG_NONE, &iv, 3);
    if (rc != 0) {
        failf(data, "nghttp2_submit_settings() failed: %s(%d)", .{ nghttp2_strerror(rc), rc });
        result = CURLE_HTTP2;
        return result;
    }

    rc = nghttp2_session_set_local_window_size(ctx.h2, NGHTTP2_FLAG_NONE, 0, PROXY_HTTP2_HUGE_WINDOW_SIZE);
    if (rc != 0) {
        failf(data, "nghttp2_session_set_local_window_size() failed: %s(%d)", .{ nghttp2_strerror(rc), rc });
        result = CURLE_HTTP2;
        return result;
    }

    result = CURLE_OK;
    return result;
}

fn cf_h2_proxy_connect(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    var save: cf_call_data = undefined;
    const ts = &ctx.tunnel;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    if (cf.next) |next| {
        if (!next.isConnected()) {
            result = Curl_conn_cf_connect(next, data, done);
            if (result != CURLE_OK or !done.*)
                return result;
        }
    }

    done.* = false;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    if (ctx.h2 == null) {
        result = cf_h2_proxy_ctx_init(cf, data);
        if (result != CURLE_OK) {
            return result;
        }
    }

    if (Curl_timeleft_ms(data) < 0) {
        failf(data, "Proxy CONNECT aborted due to timeout", .{});
        result = CURLE_OPERATION_TIMEDOUT;
    } else {
        result = H2_CONNECT(cf, data.?, ts);
    }

    done.* = (result == CURLE_OK) and (ts.state == .H2_TUNNEL_ESTABLISHED);
    if (done.*) {
        cf.setConnected(true);
        Curl_proxy_req_soft_reset(data);
        Curl_client_reset(data);
    }
    return result;
}

fn cf_h2_proxy_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    _ = data;
    if (cf.ctx) |raw| {
        const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(raw));
        cf_h2_proxy_ctx_free(ctx);
        cf.ctx = null;
    }
}

fn cf_h2_proxy_shutdown(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;
    var result: CURLcode = CURLE_OK;

    if (!cf.isConnected() or ctx.h2 == null or cf.isShutdown() or ctx.conn_closed) {
        done.* = true;
        return CURLE_OK;
    }

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    if (!ctx.sent_goaway) {
        const rv = nghttp2_submit_goaway(
            ctx.h2,
            NGHTTP2_FLAG_NONE,
            0,
            0,
            "shutdown",
            "shutdown".len + 1,
        );
        if (rv != 0) {
            failf(data, "nghttp2_submit_goaway() failed: %s(%d)", .{ nghttp2_strerror(rv), rv });
            result = CURLE_SEND_ERROR;
            cf.setShutdown(result != CURLE_OK or done.*);
            return result;
        }
        ctx.sent_goaway = true;
    }

    result = CURLE_OK;
    if (nghttp2_session_want_write(ctx.h2) != 0)
        result = proxy_h2_progress_egress(cf, data);
    if (result == CURLE_OK and nghttp2_session_want_read(ctx.h2) != 0)
        result = proxy_h2_progress_ingress(cf, data);

    done.* = ctx.conn_closed or
        (result == CURLE_OK and
            nghttp2_session_want_write(ctx.h2) == 0 and
            nghttp2_session_want_read(ctx.h2) == 0);

    cf.setShutdown(result != CURLE_OK or done.*);
    return result;
}

fn cf_h2_proxy_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool {
    if (cf.ctx) |raw| {
        const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(raw));
        if (!io_buffers.Curl_bufq_is_empty(&ctx.inbufq) or
            (ctx.tunnel.state == .H2_TUNNEL_ESTABLISHED and
                !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.recvbuf)))
        {
            return true;
        }
    }
    if (cf.next) |next| {
        return next.cft.has_data_pending(next, data);
    }
    return false;
}

fn cf_h2_proxy_adjust_pollset(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const ps_ptr: *headers_sock.EasyPollset = @ptrCast(@alignCast(ps));
    var save: cf_call_data = undefined;
    const sock = Curl_conn_cf_get_socket(cf, data);
    var want_recv = false;
    var want_send = false;
    var result: CURLcode = CURLE_OK;

    if (!cf.isConnected() and ctx.h2 != null) {
        want_send = nghttp2_session_want_write(ctx.h2) != 0 or
            !io_buffers.Curl_bufq_is_empty(&ctx.outbufq) or
            !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf);
        want_recv = nghttp2_session_want_read(ctx.h2) != 0;
    } else {
        headers_sock.Curl_pollset_check(data, ps_ptr, sock, &want_recv, &want_send);
    }

    if (ctx.h2 != null and (want_recv or want_send)) {
        cfDataSave(&save, &ctx.call_data, data);
        defer cfDataRestore(&ctx.call_data, save);
        const c_exhaust = nghttp2_session_get_remote_window_size(ctx.h2) == 0;
        const s_exhaust = ctx.tunnel.stream_id >= 0 and
            nghttp2_session_get_stream_remote_window_size(ctx.h2, ctx.tunnel.stream_id) == 0;
        want_recv = want_recv or c_exhaust or s_exhaust;
        want_send = (!s_exhaust and want_send) or
            (!c_exhaust and nghttp2_session_want_write(ctx.h2) != 0) or
            !io_buffers.Curl_bufq_is_empty(&ctx.outbufq) or
            !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf);

        result = headers_sock.Curl_pollset_set(data, ps_ptr, sock, want_recv, want_send);
        trcCf(
            data,
            cf,
            "adjust_pollset, want_recv=%d want_send=%d -> %d",
            .{ @as(c_int, @intFromBool(want_recv)), @as(c_int, @intFromBool(want_send)), @as(c_int, @intCast(result)) },
        );
    } else if (ctx.sent_goaway and !cf.isShutdown()) {
        cfDataSave(&save, &ctx.call_data, data);
        defer cfDataRestore(&ctx.call_data, save);
        want_send = nghttp2_session_want_write(ctx.h2) != 0 or
            !io_buffers.Curl_bufq_is_empty(&ctx.outbufq) or
            !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf);
        want_recv = nghttp2_session_want_read(ctx.h2) != 0;
        result = headers_sock.Curl_pollset_set(data, ps_ptr, sock, want_recv, want_send);
        trcCf(
            data,
            cf,
            "adjust_pollset, want_recv=%d want_send=%d -> %d",
            .{ @as(c_int, @intFromBool(want_recv)), @as(c_int, @intFromBool(want_send)), @as(c_int, @intCast(result)) },
        );
    }
    return result;
}

fn h2_handle_tunnel_close(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    pnread: *usize,
) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    pnread.* = 0;

    if (ctx.tunnel.@"error" != 0) {
        failf(
            data,
            "HTTP/2 stream %d reset by %s (error 0x%x %s)",
            .{
                ctx.tunnel.stream_id,
                @as([*:0]const u8, if (ctx.tunnel.reset) "server" else "curl"),
                ctx.tunnel.@"error",
                nghttp2_http2_strerror(ctx.tunnel.@"error"),
            },
        );
        return CURLE_RECV_ERROR;
    }

    trcCf(data, cf, "[%d] handle_tunnel_close -> 0", .{ctx.tunnel.stream_id});
    return CURLE_OK;
}

fn tunnel_recv(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_AGAIN;

    pnread.* = 0;
    if (!io_buffers.Curl_bufq_is_empty(&ctx.tunnel.recvbuf)) {
        result = io_buffers.Curl_bufq_cread(&ctx.tunnel.recvbuf, buf, len, pnread);
    } else {
        if (ctx.tunnel.closed) {
            result = h2_handle_tunnel_close(cf, data, pnread);
        } else if (ctx.tunnel.reset or
            (ctx.conn_closed and io_buffers.Curl_bufq_is_empty(&ctx.inbufq)) or
            (ctx.rcvd_goaway and ctx.remote_max_sid < ctx.tunnel.stream_id))
        {
            result = CURLE_RECV_ERROR;
        } else {
            result = CURLE_AGAIN;
        }
    }

    trcCf(
        data,
        cf,
        "[%d] tunnel_recv(len=%zu) -> %d, %zu",
        .{ ctx.tunnel.stream_id, len, @as(c_int, @intCast(result)), pnread.* },
    );
    return result;
}

fn cf_h2_proxy_recv(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;
    var result: CURLcode = CURLE_OK;

    pnread.* = 0;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    if (ctx.tunnel.state != .H2_TUNNEL_ESTABLISHED) {
        result = CURLE_RECV_ERROR;
        return finishCfH2ProxyRecv(cf, ctx, data, len, pnread, result);
    }

    if (io_buffers.Curl_bufq_is_empty(&ctx.tunnel.recvbuf)) {
        result = proxy_h2_progress_ingress(cf, data);
        if (result != CURLE_OK)
            return finishCfH2ProxyRecv(cf, ctx, data, len, pnread, result);
    }

    result = tunnel_recv(cf, data, buf, len, pnread);
    if (result == CURLE_OK) {
        trcCf(data, cf, "[%d] increase window by %zu", .{ ctx.tunnel.stream_id, pnread.* });
        _ = nghttp2_session_consume(ctx.h2, ctx.tunnel.stream_id, pnread.*);
    }

    result = Curl_1st_fatal(result, proxy_h2_progress_egress(cf, data));
    return finishCfH2ProxyRecv(cf, ctx, data, len, pnread, result);
}

fn finishCfH2ProxyRecv(
    cf: *Curl_cfilter,
    ctx: *cf_h2_proxy_ctx,
    data: ?*Curl_easy,
    len: usize,
    pnread: *usize,
    result: CURLcode,
) CURLcode {
    if ((!io_buffers.Curl_bufq_is_empty(&ctx.tunnel.recvbuf) or
        !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf)) and
        (result == CURLE_OK or result == CURLE_AGAIN))
    {
        drain_tunnel(cf, data, &ctx.tunnel);
    }
    trcCf(
        data,
        cf,
        "[%d] cf_recv(len=%zu) -> %d, %zu",
        .{ ctx.tunnel.stream_id, len, @as(c_int, @intCast(result)), pnread.* },
    );
    return result;
}

fn cf_h2_proxy_send(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    _ = eos;
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;
    var result: CURLcode = CURLE_OK;

    pnwritten.* = 0;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    if (ctx.tunnel.state != .H2_TUNNEL_ESTABLISHED or ctx.tunnel.closed) {
        result = CURLE_SEND_ERROR;
        return finishCfH2ProxySend(cf, ctx, data, len, pnwritten, result);
    }

    result = io_buffers.Curl_bufq_write(&ctx.tunnel.sendbuf, buf, len, pnwritten);
    trcCf(data, cf, "cf_send(), bufq_write %d, %zu", .{ @as(c_int, @intCast(result)), pnwritten.* });
    if (result != CURLE_OK and result != CURLE_AGAIN)
        return finishCfH2ProxySend(cf, ctx, data, len, pnwritten, result);

    if (!io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf)) {
        const rv = nghttp2_session_resume_data(ctx.h2, ctx.tunnel.stream_id);
        if (nghttp2_is_fatal(rv) != 0) {
            result = CURLE_SEND_ERROR;
            return finishCfH2ProxySend(cf, ctx, data, len, pnwritten, result);
        }
    }

    result = Curl_1st_fatal(result, proxy_h2_progress_ingress(cf, data));
    result = Curl_1st_fatal(result, proxy_h2_progress_egress(cf, data));

    if (result == CURLE_OK and proxy_h2_should_close_session(ctx)) {
        if (ctx.tunnel.closed) {
            result = CURLE_SEND_ERROR;
        } else {
            trcCf(data, cf, "[0] send: nothing to do in this session", .{});
            result = CURLE_HTTP2;
        }
    }

    return finishCfH2ProxySend(cf, ctx, data, len, pnwritten, result);
}

fn finishCfH2ProxySend(
    cf: *Curl_cfilter,
    ctx: *cf_h2_proxy_ctx,
    data: ?*Curl_easy,
    len: usize,
    pnwritten: *usize,
    result: CURLcode,
) CURLcode {
    if ((!io_buffers.Curl_bufq_is_empty(&ctx.tunnel.recvbuf) or
        !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf)) and
        (result == CURLE_OK or result == CURLE_AGAIN))
    {
        drain_tunnel(cf, data, &ctx.tunnel);
    }
    trcCf(
        data,
        cf,
        "[%d] cf_send(len=%zu) -> %d, %zu, h2 windows %d-%d (stream-conn), buffers %zu-%zu (stream-conn)",
        .{
            ctx.tunnel.stream_id,
            len,
            @as(c_int, @intCast(result)),
            pnwritten.*,
            nghttp2_session_get_stream_remote_window_size(ctx.h2, ctx.tunnel.stream_id),
            nghttp2_session_get_remote_window_size(ctx.h2),
            io_buffers.Curl_bufq_len(&ctx.tunnel.sendbuf),
            io_buffers.Curl_bufq_len(&ctx.outbufq),
        },
    );
    return result;
}

fn cf_h2_proxy_flush(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var save: cf_call_data = undefined;
    var result: CURLcode = CURLE_OK;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    if (!io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf)) {
        const rv = nghttp2_session_resume_data(ctx.h2, ctx.tunnel.stream_id);
        if (nghttp2_is_fatal(rv) != 0) {
            result = CURLE_SEND_ERROR;
            return finishCfH2ProxyFlush(cf, ctx, data, result);
        }
    }

    result = proxy_h2_progress_egress(cf, data);
    return finishCfH2ProxyFlush(cf, ctx, data, result);
}

fn finishCfH2ProxyFlush(
    cf: *Curl_cfilter,
    ctx: *cf_h2_proxy_ctx,
    data: ?*Curl_easy,
    result: CURLcode,
) CURLcode {
    trcCf(
        data,
        cf,
        "[%d] flush -> %d, h2 windows %d-%d (stream-conn), buffers %zu-%zu (stream-conn)",
        .{
            ctx.tunnel.stream_id,
            @as(c_int, @intCast(result)),
            nghttp2_session_get_stream_remote_window_size(ctx.h2, ctx.tunnel.stream_id),
            nghttp2_session_get_remote_window_size(ctx.h2),
            io_buffers.Curl_bufq_len(&ctx.tunnel.sendbuf),
            io_buffers.Curl_bufq_len(&ctx.outbufq),
        },
    );
    return result;
}

fn proxy_h2_connisalive(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    input_pending: *bool,
) bool {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var alive = true;

    input_pending.* = false;
    const next = cf.next orelse return false;
    if (!next.cft.is_alive(next, data, input_pending))
        return false;

    if (input_pending.*) {
        var nread: usize = 0;
        input_pending.* = false;
        const result = Curl_cf_recv_bufq(cf.next, data, &ctx.inbufq, 0, &nread);
        if (result == CURLE_OK) {
            if (proxy_h2_process_pending_input(cf, data) != CURLE_OK) {
                alive = false;
            } else {
                alive = !proxy_h2_should_close_session(ctx);
            }
        } else if (result != CURLE_AGAIN) {
            alive = false;
        }
    }

    return alive;
}

fn cf_h2_proxy_is_alive(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    input_pending: *bool,
) callconv(.c) bool {
    const ctx_opt: ?*cf_h2_proxy_ctx = if (cf.ctx) |raw| @ptrCast(@alignCast(raw)) else null;
    input_pending.* = false;
    const ctx = ctx_opt orelse return false;
    var save: cf_call_data = undefined;

    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    const alive = (ctx.h2 != null) and proxy_h2_connisalive(cf, data, input_pending);
    trcCf(
        data,
        cf,
        "[0] conn alive -> %d, input_pending=%d",
        .{ @as(c_int, @intFromBool(alive)), @as(c_int, @intFromBool(input_pending.*)) },
    );
    return alive;
}

fn cf_h2_proxy_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));

    switch (query) {
        CF_QUERY_HOST_PORT => {
            if (pres1) |p1| p1.* = @intCast(ctx.dest.?.port);
            if (pres2) |p2| {
                const host_out: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                host_out.* = ctx.dest.?.hostname;
            }
            return CURLE_OK;
        },
        CF_QUERY_NEED_FLUSH => {
            if (!io_buffers.Curl_bufq_is_empty(&ctx.outbufq) or
                !io_buffers.Curl_bufq_is_empty(&ctx.tunnel.sendbuf))
            {
                trcCf(data, cf, "needs flush", .{});
                if (pres1) |p1| p1.* = 1;
                return CURLE_OK;
            }
        },
        CF_QUERY_ALPN_NEGOTIATED => {
            if (pres2) |p2| {
                const palpn: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                palpn.* = null;
            }
            return CURLE_OK;
        },
        else => {},
    }
    if (cf.next) |next| {
        return next.cft.query(next, data, query, pres1, pres2);
    }
    return CURLE_UNKNOWN_OPTION;
}

fn cf_h2_proxy_cntrl(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = arg1;
    _ = arg2;
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    var save: cf_call_data = undefined;

    switch (event) {
        CF_CTRL_FLUSH => {
            cfDataSave(&save, &ctx.call_data, data);
            defer cfDataRestore(&ctx.call_data, save);
            result = cf_h2_proxy_flush(cf, data);
        },
        else => {},
    }
    return result;
}

pub var Curl_cft_h2_proxy: Curl_cftype = .{
    .name = "H2-PROXY",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_PROXY,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_h2_proxy_destroy,
    .do_connect = cf_h2_proxy_connect,
    .do_shutdown = cf_h2_proxy_shutdown,
    .adjust_pollset = cf_h2_proxy_adjust_pollset,
    .has_data_pending = cf_h2_proxy_data_pending,
    .do_send = cf_h2_proxy_send,
    .do_recv = cf_h2_proxy_recv,
    .cntrl = cf_h2_proxy_cntrl,
    .is_alive = cf_h2_proxy_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_h2_proxy_query,
};

pub fn Curl_cf_h2_proxy_insert_after(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    peer: *Curl_peer,
    dest: *Curl_peer,
    udp_tunnel: bool,
) callconv(.c) CURLcode {
    _ = data;
    var cf_h2_proxy: ?*Curl_cfilter = null;
    const raw = mem.calloc(1, @sizeOf(cf_h2_proxy_ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *cf_h2_proxy_ctx = @ptrCast(@alignCast(raw));
    altsvc_hsts_peer.Curl_peer_link(&ctx.peer, peer);
    altsvc_hsts_peer.Curl_peer_link(&ctx.dest, dest);
    ctx.udp_tunnel = udp_tunnel;

    const result = Curl_cf_create(&cf_h2_proxy, &Curl_cft_h2_proxy, ctx);
    if (result != CURLE_OK) {
        cf_h2_proxy_ctx_free(ctx);
        return result;
    }
    Curl_conn_cf_insert_after(cf, cf_h2_proxy.?);
    return CURLE_OK;
}

comptime {
    if (backend_options.nghttp2) {
        @export(&Curl_cft_nghttp2, .{ .name = "Curl_cft_nghttp2", .linkage = .strong });
        @export(&Curl_http2_ver, .{ .name = "Curl_http2_ver", .linkage = .strong });
        @export(&Curl_http2_may_switch, .{ .name = "Curl_http2_may_switch", .linkage = .strong });
        @export(&Curl_http2_switch, .{ .name = "Curl_http2_switch", .linkage = .strong });
        @export(&Curl_http2_switch_at, .{ .name = "Curl_http2_switch_at", .linkage = .strong });
        @export(&Curl_http2_upgrade, .{ .name = "Curl_http2_upgrade", .linkage = .strong });
        @export(&Curl_http2_request_upgrade, .{ .name = "Curl_http2_request_upgrade", .linkage = .strong });
        @export(&Curl_h2_http_1_1_error, .{ .name = "Curl_h2_http_1_1_error", .linkage = .strong });
        @export(&Curl_nghttp2_malloc, .{ .name = "Curl_nghttp2_malloc", .linkage = .strong });
        @export(&Curl_nghttp2_free, .{ .name = "Curl_nghttp2_free", .linkage = .strong });
        @export(&Curl_nghttp2_calloc, .{ .name = "Curl_nghttp2_calloc", .linkage = .strong });
        @export(&Curl_nghttp2_realloc, .{ .name = "Curl_nghttp2_realloc", .linkage = .strong });
        @export(&Curl_nghttp2_fr_print, .{ .name = "Curl_nghttp2_fr_print", .linkage = .strong });
        @export(&Curl_cft_h2_proxy, .{ .name = "Curl_cft_h2_proxy", .linkage = .strong });
        @export(&Curl_cf_h2_proxy_insert_after, .{ .name = "Curl_cf_h2_proxy_insert_after", .linkage = .strong });
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "curl_pushheader_bynum and curl_pushheader_byname lookup and validation" {
    try std.testing.expect(curl_pushheader_bynum(null, 0) == null);
    try std.testing.expect(curl_pushheader_byname(null, ":path") == null);

    var fake_magic: c_uint = CURLEASY_MAGIC_NUMBER;
    const fake_easy: *Curl_easy = @ptrCast(&fake_magic);

    const h0 = mem.strdup(":method:GET") orelse return error.OutOfMemory;
    defer mem.free(h0);
    const h1 = mem.strdup(":path:/index.html") orelse return error.OutOfMemory;
    defer mem.free(h1);
    const h2 = mem.strdup("x-custom:hello:world") orelse return error.OutOfMemory;
    defer mem.free(h2);

    var hdr_array = [_][*:0]u8{ h0, h1, h2 };
    var stream = std.mem.zeroes(h2_stream_ctx);
    stream.push_headers = &hdr_array;
    stream.push_headers_used = hdr_array.len;

    var hp = curl_pushheaders{
        .data = fake_easy,
        .stream = &stream,
        .frame = null,
    };

    try std.testing.expectEqualStrings(":method:GET", std.mem.span(pushheaderByNumImpl(&hp, 0).?));
    try std.testing.expectEqualStrings(":path:/index.html", std.mem.span(pushheaderByNumImpl(&hp, 1).?));
    try std.testing.expect(pushheaderByNumImpl(&hp, 3) == null);

    try std.testing.expectEqualStrings("GET", std.mem.span(pushheaderByNameImpl(&hp, ":method").?));
    try std.testing.expectEqualStrings("/index.html", std.mem.span(pushheaderByNameImpl(&hp, ":path").?));
    try std.testing.expectEqualStrings("hello:world", std.mem.span(pushheaderByNameImpl(&hp, "x-custom").?));

    // Prefix that isn't followed by ':' or invalid header names must return null
    try std.testing.expect(pushheaderByNameImpl(&hp, ":meth") == null);
    try std.testing.expect(pushheaderByNameImpl(&hp, "") == null);
    try std.testing.expect(pushheaderByNameImpl(&hp, ":") == null);
    try std.testing.expect(pushheaderByNameImpl(&hp, "x-custom:hello") == null);

    // Invalid easy handle magic must be rejected
    fake_magic = 0;
    try std.testing.expect(pushheaderByNumImpl(&hp, 0) == null);
    try std.testing.expect(pushheaderByNameImpl(&hp, ":path") == null);
}

test "Curl_nghttp2_* allocators" {
    const p1 = Curl_nghttp2_malloc(32, null);
    try std.testing.expect(p1 != null);
    const bytes1: [*]u8 = @ptrCast(p1.?);
    @memset(bytes1[0..32], 0x5a);

    const p2 = Curl_nghttp2_realloc(p1, 64, null);
    try std.testing.expect(p2 != null);
    const bytes2: [*]const u8 = @ptrCast(p2.?);
    for (bytes2[0..32]) |b| {
        try std.testing.expectEqual(@as(u8, 0x5a), b);
    }
    Curl_nghttp2_free(p2, null);

    const p3 = Curl_nghttp2_calloc(8, 4, null);
    try std.testing.expect(p3 != null);
    const bytes3: [*]const u8 = @ptrCast(p3.?);
    for (bytes3[0..32]) |b| {
        try std.testing.expectEqual(@as(u8, 0), b);
    }
    Curl_nghttp2_free(p3, null);
}

test "Curl_nghttp2_fr_print formatting for HTTP/2 frame types" {
    var buf: [256]u8 = undefined;
    var frame: nghttp2_frame = std.mem.zeroes(nghttp2_frame);

    frame.data = .{
        .hd = .{
            .length = 128,
            .stream_id = 1,
            .type = NGHTTP2_DATA,
            .flags = NGHTTP2_FLAG_END_STREAM,
            .reserved = 0,
        },
        .padlen = 4,
    };
    var n = Curl_nghttp2_fr_print(&frame, &buf, buf.len);
    try std.testing.expect(n > 0);
    try std.testing.expectEqualStrings("FRAME[DATA, len=128, eos=1, padlen=4]", buf[0..@intCast(n)]);

    frame = std.mem.zeroes(nghttp2_frame);
    frame.hd = .{
        .length = 0,
        .stream_id = 0,
        .type = NGHTTP2_SETTINGS,
        .flags = NGHTTP2_FLAG_ACK,
        .reserved = 0,
    };
    n = Curl_nghttp2_fr_print(&frame, &buf, buf.len);
    try std.testing.expect(n > 0);
    try std.testing.expectEqualStrings("FRAME[SETTINGS, ack=1]", buf[0..@intCast(n)]);

    var reason = "bye".*;
    frame = std.mem.zeroes(nghttp2_frame);
    frame.goaway = .{
        .hd = .{
            .length = 11,
            .stream_id = 0,
            .type = NGHTTP2_GOAWAY,
            .flags = 0,
            .reserved = 0,
        },
        .last_stream_id = 7,
        .error_code = NGHTTP2_NO_ERROR,
        .opaque_data = &reason,
        .opaque_data_len = 3,
        .reserved = 0,
    };
    n = Curl_nghttp2_fr_print(&frame, &buf, buf.len);
    try std.testing.expect(n > 0);
    try std.testing.expectEqualStrings("FRAME[GOAWAY, error=0, reason='bye', last_stream=7]", buf[0..@intCast(n)]);
}
