const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const io_buffers = @import("io_buffers.zig");
const headers_sock = @import("headers_sock.zig");
const cfilters_progress = @import("cfilters_progress.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_PARTIAL_FILE: CURLcode = 18;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_FILESIZE_EXCEEDED: CURLcode = 63;
pub const CURLE_SEND_FAIL_REWIND: CURLcode = 65;

pub const curl_off_t = i64;
pub const CurlEasy = cfilters_progress.CurlEasy;
pub const ConnectData = cfilters_progress.ConnectData;
pub const CurlTime = headers_sock.Curltime;
pub const CurlRlimit = headers_sock.CurlRlimit;
pub const CurlMapiGuard = cfilters_progress.CurlMapiGuard;

// Client Write flags (lib/sendf.h)
pub const CLIENTWRITE_BODY: c_int = 1 << 0;
pub const CLIENTWRITE_INFO: c_int = 1 << 1;
pub const CLIENTWRITE_HEADER: c_int = 1 << 2;
pub const CLIENTWRITE_STATUS: c_int = 1 << 3;
pub const CLIENTWRITE_CONNECT: c_int = 1 << 4;
pub const CLIENTWRITE_1XX: c_int = 1 << 5;
pub const CLIENTWRITE_TRAILER: c_int = 1 << 6;
pub const CLIENTWRITE_EOS: c_int = 1 << 7;
pub const CLIENTWRITE_0LEN: c_int = 1 << 8;

// Client Writer phases (lib/sendf.h)
pub const CurlCwriterPhase = c_uint;
pub const CURL_CW_RAW: CurlCwriterPhase = 0;
pub const CURL_CW_TRANSFER_DECODE: CurlCwriterPhase = 1;
pub const CURL_CW_PROTOCOL: CurlCwriterPhase = 2;
pub const CURL_CW_BEFORE_DECODE: CurlCwriterPhase = 3;
pub const CURL_CW_CONTENT_DECODE: CurlCwriterPhase = 4;
pub const CURL_CW_CLIENT: CurlCwriterPhase = 5;

pub const CURL_CW_FLAG_BLOWUP: u8 = 1 << 0;

// Client Reader phases (lib/sendf.h)
pub const CurlCreaderPhase = c_uint;
pub const CURL_CR_NET: CurlCreaderPhase = 0;
pub const CURL_CR_TRANSFER_ENCODE: CurlCreaderPhase = 1;
pub const CURL_CR_PROTOCOL: CurlCreaderPhase = 2;
pub const CURL_CR_CONTENT_ENCODE: CurlCreaderPhase = 3;
pub const CURL_CR_CLIENT: CurlCreaderPhase = 4;

// Client Reader control opcodes (lib/sendf.h)
pub const CurlCreaderCntrl = c_uint;
pub const CURL_CRCNTRL_REWIND: CurlCreaderCntrl = 0;
pub const CURL_CRCNTRL_UNPAUSE: CurlCreaderCntrl = 1;
pub const CURL_CRCNTRL_CLEAR_EOS: CurlCreaderCntrl = 2;

const TIMER_STARTTRANSFER: c_uint = 8;
const CURLINFO_DATA_IN: c_uint = 3;

const CONNCTRL_CONN_CLOSE: c_int = 1;
const CONNCTRL_STREAM_CLOSE: c_int = 2;

const CURL_READFUNC_ABORT: usize = 0x10000000;
const CURL_READFUNC_PAUSE: usize = 0x10000001;

const CURL_SEEKFUNC_OK: c_int = 0;
const CURL_SEEKFUNC_CANTSEEK: c_int = 2;

const CURL_CBAPI_FN_easy_cr_in_read: c_uint = 131;
const CURL_CBAPI_FN_easy_cr_in_resume_from: c_uint = 132;

pub const CurlReadCallback = ?*const fn (
    buf: [*]u8,
    size: usize,
    nitems: usize,
    instream: ?*anyopaque,
) callconv(.c) usize;

pub const CurlCwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: *const fn (?*CurlEasy, *CurlCwriter) callconv(.c) CURLcode,
    do_write: *const fn (?*CurlEasy, *CurlCwriter, c_int, ?[*]const u8, usize) callconv(.c) CURLcode,
    do_flush: *const fn (?*CurlEasy, *CurlCwriter) callconv(.c) CURLcode,
    do_close: *const fn (?*CurlEasy, *CurlCwriter) callconv(.c) void,
    cwriter_size: usize,
};

inline fn fromOpaque(comptime T: type, raw: anytype) *T {
    return @ptrCast(@alignCast(raw));
}

pub const CurlCwriter = extern struct {
    cwt: *const CurlCwtype,
    next: ?*CurlCwriter,
    ctx: ?*anyopaque,
    phase: CurlCwriterPhase,

    pub inline fn ctxAs(self: *CurlCwriter, comptime T: type) *T {
        return fromOpaque(T, self.ctx.?);
    }
};

pub const CurlCrtype = extern struct {
    name: [*:0]const u8,
    do_init: *const fn (?*CurlEasy, *CurlCreader) callconv(.c) CURLcode,
    do_read: *const fn (?*CurlEasy, *CurlCreader, ?[*]u8, usize, *usize, *bool) callconv(.c) CURLcode,
    do_close: *const fn (?*CurlEasy, *CurlCreader) callconv(.c) void,
    needs_rewind: *const fn (?*CurlEasy, *CurlCreader) callconv(.c) bool,
    total_length: *const fn (?*CurlEasy, *CurlCreader) callconv(.c) curl_off_t,
    resume_from: *const fn (?*CurlEasy, *CurlCreader, curl_off_t) callconv(.c) CURLcode,
    cntrl: *const fn (?*CurlEasy, *CurlCreader, CurlCreaderCntrl) callconv(.c) CURLcode,
    is_paused: *const fn (?*CurlEasy, *CurlCreader) callconv(.c) bool,
    done: *const fn (?*CurlEasy, *CurlCreader, c_int) callconv(.c) void,
    creader_size: usize,
};

pub const CurlCreader = extern struct {
    crt: *const CurlCrtype,
    next: ?*CurlCreader,
    ctx: ?*anyopaque,
    phase: CurlCreaderPhase,

    pub inline fn ctxAs(self: *CurlCreader, comptime T: type) *T {
        return fromOpaque(T, self.ctx.?);
    }
};

// External functions and globals
extern const Curl_cwt_out: CurlCwtype;
extern const Curl_cwt_pause: CurlCwtype;
extern const Curl_trc_feat_write: u8;
extern const Curl_trc_feat_read: u8;

extern fn Curl_trc_bind_c(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_trc_is_verbose_fn(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_trc_ft_is_verbose_fn(data: ?*CurlEasy, ft: *const anyopaque) callconv(.c) bool;
extern fn Curl_trc_write(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_read(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_debug(data: ?*CurlEasy, info_type: c_uint, ptr: ?[*]const u8, size: usize) callconv(.c) void;

extern fn Curl_cbapi_enter(
    guard: *CurlMapiGuard,
    easy: ?*CurlEasy,
    multi: ?*anyopaque,
    cb_fn: c_uint,
) callconv(.c) void;
extern fn Curl_cbapi_leave(guard: *CurlMapiGuard) callconv(.c) void;

extern fn curlx_sotouz_range(val: curl_off_t, min: usize, max: usize) callconv(.c) usize;
extern fn curlx_sotouz(val: curl_off_t) callconv(.c) usize;

extern fn Curl_pgrsTime(data: ?*CurlEasy, timer: c_uint) callconv(.c) void;
extern fn Curl_pgrs_now(data: ?*CurlEasy) callconv(.c) *const CurlTime;
extern fn Curl_pgrs_download_inc(data: ?*CurlEasy, delta: usize) callconv(.c) void;
extern fn Curl_conncontrol(conn: ?*ConnectData, ctrl: c_int) callconv(.c) void;
extern fn Curl_xfer_pause_send(data: ?*CurlEasy, enable: bool) callconv(.c) CURLcode;

// Helpers in lib/multi.c
extern fn Curl_cw_out_set_paused(data: ?*CurlEasy, paused: bool) callconv(.c) void;
extern fn Curl_cw_out_is_nonetwork(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_easy_max_filesize(data: ?*CurlEasy) callconv(.c) curl_off_t;
extern fn Curl_xfer_get_conn(data: ?*CurlEasy) callconv(.c) ?*ConnectData;
extern fn Curl_xfer_get_dl_rlimit(data: ?*CurlEasy) callconv(.c) *CurlRlimit;
extern fn Curl_xfer_get_ul_rlimit(data: ?*CurlEasy) callconv(.c) *CurlRlimit;

extern fn Curl_sendf_get_writer_stack_ptr(data: ?*CurlEasy) callconv(.c) *?*CurlCwriter;
extern fn Curl_sendf_get_reader_stack_ptr(data: ?*CurlEasy) callconv(.c) *?*CurlCreader;
extern fn Curl_sendf_get_reader_started(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_set_reader_started(data: ?*CurlEasy, val: bool) callconv(.c) void;
extern fn Curl_sendf_reset_req_counts(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_sendf_get_rewind_read(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_set_rewind_read(data: ?*CurlEasy, enable: bool) callconv(.c) void;
extern fn Curl_sendf_get_req_bytecount(data: ?*const CurlEasy) callconv(.c) curl_off_t;
extern fn Curl_sendf_add_req_bytecount(data: ?*CurlEasy, nwrite: usize) callconv(.c) void;
extern fn Curl_sendf_get_upload_done(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_suppress_connect_headers(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_get_no_body(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_set_download_done(data: ?*CurlEasy, done: bool) callconv(.c) void;
extern fn Curl_sendf_get_header_size(data: ?*const CurlEasy) callconv(.c) c_long;
extern fn Curl_sendf_get_maxdownload(data: ?*const CurlEasy) callconv(.c) curl_off_t;
extern fn Curl_sendf_get_req_size(data: ?*const CurlEasy) callconv(.c) curl_off_t;
extern fn Curl_sendf_get_ignorebody(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_get_verbose(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_get_fread_in(data: ?*const CurlEasy, pread_cb: *CurlReadCallback, pcb_user_data: *?*anyopaque) callconv(.c) void;
extern fn Curl_sendf_has_seek_func(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_call_seek_func(data: ?*CurlEasy, offset: curl_off_t) callconv(.c) c_int;
extern fn Curl_sendf_has_ioctl_func(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_call_ioctl_restartread(data: ?*CurlEasy) callconv(.c) c_int;
extern fn Curl_sendf_try_fseek_rewind(data: ?*CurlEasy, perr: *c_int, perrno: *c_int) callconv(.c) bool;
extern fn Curl_sendf_want_crlf_reader(data: ?*const CurlEasy) callconv(.c) bool;
extern fn Curl_sendf_get_infilesize(data: ?*const CurlEasy) callconv(.c) curl_off_t;

inline fn cwriterWrite(
    data: ?*CurlEasy,
    writer: ?*CurlCwriter,
    type_flags: c_int,
    buf: ?[*]const u8,
    nbytes: usize,
) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_write(data, w, type_flags, buf, nbytes);
}

inline fn cwriterFlush(
    data: ?*CurlEasy,
    writer: ?*CurlCwriter,
) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_flush(data, w);
}

// ============================================================================
// 1. lib/sendf.c - Client Writers & Readers
// ============================================================================

fn clResetWriter(data: ?*CurlEasy) void {
    const stack_ptr = Curl_sendf_get_writer_stack_ptr(data);
    var writer = stack_ptr.*;
    while (writer) |w| {
        stack_ptr.* = w.next;
        w.cwt.do_close(data, w);
        mem.freeTyped(w);
        writer = stack_ptr.*;
    }
    Curl_cw_out_set_paused(data, false);
}

fn clResetReader(data: ?*CurlEasy) void {
    const stack_ptr = Curl_sendf_get_reader_stack_ptr(data);
    var reader = stack_ptr.*;
    Curl_sendf_set_reader_started(data, false);
    while (reader) |r| {
        stack_ptr.* = r.next;
        r.crt.do_close(data, r);
        mem.freeTyped(r);
        reader = stack_ptr.*;
    }
}

pub export fn Curl_client_cleanup(data: ?*CurlEasy) callconv(.c) void {
    clResetReader(data);
    clResetWriter(data);
    Curl_sendf_reset_req_counts(data);
}

pub export fn Curl_client_reset(data: ?*CurlEasy) callconv(.c) void {
    if (Curl_sendf_get_rewind_read(data)) {
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
            Curl_trc_read(data, "client_reset, will rewind reader");
        }
    } else {
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
            Curl_trc_read(data, "client_reset, clear readers");
        }
        clResetReader(data);
    }
    clResetWriter(data);
    Curl_sendf_reset_req_counts(data);
}

pub export fn Curl_client_start(data: ?*CurlEasy) callconv(.c) CURLcode {
    if (Curl_sendf_get_rewind_read(data)) {
        var r = Curl_sendf_get_reader_stack_ptr(data).*;
        var result: CURLcode = CURLE_OK;

        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
            Curl_trc_read(data, "client start, rewind readers");
        }
        while (r) |cur| {
            result = cur.crt.cntrl(data, cur, CURL_CRCNTRL_REWIND);
            if (result != CURLE_OK) {
                Curl_trc_bind_c(data);
                Curl_failf(
                    data,
                    "rewind of client reader '%s' failed: %d",
                    cur.crt.name,
                    @as(c_int, @intCast(result)),
                );
                return result;
            }
            r = cur.next;
        }
        Curl_sendf_set_rewind_read(data, false);
        clResetReader(data);
    }
    return CURLE_OK;
}

pub export fn Curl_creader_will_rewind(data: ?*CurlEasy) callconv(.c) bool {
    return Curl_sendf_get_rewind_read(data);
}

pub export fn Curl_creader_set_rewind(data: ?*CurlEasy, enable: bool) callconv(.c) void {
    Curl_sendf_set_rewind_read(data, enable);
}

pub export fn Curl_cwriter_def_init(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
) callconv(.c) CURLcode {
    _ = data;
    _ = writer;
    return CURLE_OK;
}

pub export fn Curl_cwriter_def_write(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
    type_flags: c_int,
    buf: ?[*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    return cwriterWrite(data, writer.next, type_flags, buf, nbytes);
}

pub export fn Curl_cwriter_def_flush(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
) callconv(.c) CURLcode {
    return cwriterFlush(data, writer.next);
}

pub export fn Curl_cwriter_def_close(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
) callconv(.c) void {
    _ = data;
    _ = writer;
}

fn getMaxBodyWriteLen(data: ?*CurlEasy, limit: curl_off_t) usize {
    if (limit != -1) {
        return curlx_sotouz_range(limit - Curl_sendf_get_req_bytecount(data), 0, std.math.maxInt(usize));
    }
    return std.math.maxInt(usize);
}

const CwDownloadCtx = extern struct {
    super: CurlCwriter,
    flags: u8,

    fn startedResponse(self: *const CwDownloadCtx) bool {
        return (self.flags & (1 << 0)) != 0;
    }
    fn setStartedResponse(self: *CwDownloadCtx, v: bool) void {
        if (v) self.flags |= (1 << 0) else self.flags &= ~@as(u8, 1 << 0);
    }
    fn startedBody(self: *const CwDownloadCtx) bool {
        return (self.flags & (1 << 1)) != 0;
    }
    fn setStartedBody(self: *CwDownloadCtx, v: bool) void {
        if (v) self.flags |= (1 << 1) else self.flags &= ~@as(u8, 1 << 1);
    }
};

fn cwDownloadWrite(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
    type_flags: c_int,
    buf: ?[*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    const ctx = writer.ctxAs(CwDownloadCtx);
    var result: CURLcode = CURLE_OK;
    var nwrite: usize = 0;
    var excess_len: usize = 0;
    const is_connect: bool = (type_flags & CLIENTWRITE_CONNECT) != 0;

    if (!ctx.startedResponse() and
        (type_flags & CLIENTWRITE_CONNECT) == 0 and
        ((type_flags & CLIENTWRITE_INFO) == 0 or Curl_sendf_get_upload_done(data)))
    {
        Curl_pgrsTime(data, TIMER_STARTTRANSFER);
        ctx.setStartedResponse(true);
    }

    if ((type_flags & CLIENTWRITE_BODY) == 0) {
        if (is_connect and Curl_sendf_suppress_connect_headers(data))
            return CURLE_OK;
        result = cwriterWrite(data, writer.next, type_flags, buf, nbytes);
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_write)) {
            Curl_trc_write(
                data,
                "download_write header(type=%x, blen=%zu) -> %d",
                @as(c_uint, @intCast(type_flags)),
                nbytes,
                @as(c_int, @intCast(result)),
            );
        }
        return result;
    }

    if (!ctx.startedBody() and
        (type_flags & (CLIENTWRITE_INFO | CLIENTWRITE_CONNECT)) == 0)
    {
        headers_sock.Curl_rlimit_start(
            Curl_xfer_get_dl_rlimit(data),
            Curl_pgrs_now(data),
            Curl_sendf_get_req_size(data),
        );
        ctx.setStartedBody(true);
    }

    const no_body = Curl_sendf_get_no_body(data);
    if (no_body and nbytes > 0) {
        Curl_conncontrol(Curl_xfer_get_conn(data), CONNCTRL_STREAM_CLOSE);
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_write)) {
            Curl_trc_write(
                data,
                "download_write body(type=%x, blen=%zu), did not want a BODY",
                @as(c_uint, @intCast(type_flags)),
                nbytes,
            );
        }
        Curl_sendf_set_download_done(data, true);
        if (Curl_sendf_get_header_size(data) != 0)
            return CURLE_OK;
        return CURLE_WEIRD_SERVER_REPLY;
    }

    nwrite = nbytes;
    const maxdownload = Curl_sendf_get_maxdownload(data);
    if (maxdownload != -1) {
        const wmax = getMaxBodyWriteLen(data, maxdownload);
        if (nwrite > wmax) {
            excess_len = nbytes - wmax;
            nwrite = wmax;
        }

        if (nwrite == wmax) {
            Curl_sendf_set_download_done(data, true);
        }

        const req_size = Curl_sendf_get_req_size(data);
        const bytecount = Curl_sendf_get_req_bytecount(data);
        if ((type_flags & CLIENTWRITE_EOS) != 0 and !no_body and (req_size > bytecount)) {
            Curl_trc_bind_c(data);
            Curl_failf(
                data,
                "end of response with %lld bytes missing",
                @as(c_longlong, req_size - bytecount),
            );
            return CURLE_PARTIAL_FILE;
        }
    }

    const ignorebody = Curl_sendf_get_ignorebody(data);
    const max_filesize = Curl_easy_max_filesize(data);
    if (max_filesize != 0 and !ignorebody) {
        const wmax = getMaxBodyWriteLen(data, max_filesize);
        if (nwrite > wmax) {
            nwrite = wmax;
        }
    }

    if (!ignorebody and (nwrite != 0 or (type_flags & CLIENTWRITE_EOS) != 0)) {
        result = cwriterWrite(data, writer.next, type_flags, buf, nwrite);
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_write)) {
            Curl_trc_write(
                data,
                "download_write body(type=%x, blen=%zu) -> %d",
                @as(c_uint, @intCast(type_flags)),
                nbytes,
                @as(c_int, @intCast(result)),
            );
        }
        if (result != CURLE_OK)
            return result;
    }

    if (nwrite != 0) {
        Curl_sendf_add_req_bytecount(data, nwrite);
        Curl_pgrs_download_inc(data, nwrite);
    }

    if (excess_len != 0) {
        if (!ignorebody) {
            if (Curl_trc_is_verbose_fn(data)) {
                Curl_trc_bind_c(data);
                Curl_infof(
                    data,
                    "Excess found writing body: excess = %zu, size = %lld, maxdownload = %lld, bytecount = %lld",
                    excess_len,
                    @as(c_longlong, Curl_sendf_get_req_size(data)),
                    @as(c_longlong, maxdownload),
                    @as(c_longlong, Curl_sendf_get_req_bytecount(data)),
                );
            }
            Curl_conncontrol(Curl_xfer_get_conn(data), CONNCTRL_CONN_CLOSE);
        }
    } else if ((nwrite < nbytes) and !ignorebody) {
        Curl_trc_bind_c(data);
        Curl_failf(
            data,
            "Exceeded the maximum allowed file size (%lld) with %lld bytes",
            @as(c_longlong, max_filesize),
            @as(c_longlong, Curl_sendf_get_req_bytecount(data)),
        );
        return CURLE_FILESIZE_EXCEEDED;
    }

    return CURLE_OK;
}

const cw_download: CurlCwtype = .{
    .name = "protocol",
    .alias = null,
    .flags = 0,
    .do_init = Curl_cwriter_def_init,
    .do_write = cwDownloadWrite,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = Curl_cwriter_def_close,
    .cwriter_size = @sizeOf(CwDownloadCtx),
};

fn cwRawWrite(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
    type_flags: c_int,
    buf: ?[*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    if ((type_flags & CLIENTWRITE_BODY) != 0 and
        Curl_sendf_get_verbose(data) and
        !Curl_sendf_get_ignorebody(data))
    {
        Curl_trc_bind_c(data);
        Curl_debug(data, CURLINFO_DATA_IN, buf, nbytes);
    }
    return cwriterWrite(data, writer.next, type_flags, buf, nbytes);
}

const cw_raw: CurlCwtype = .{
    .name = "raw",
    .alias = null,
    .flags = 0,
    .do_init = Curl_cwriter_def_init,
    .do_write = cwRawWrite,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = Curl_cwriter_def_close,
    .cwriter_size = @sizeOf(CurlCwriter),
};

fn cwriterAdd(data: ?*CurlEasy, writer: *CurlCwriter) void {
    var anchor = Curl_sendf_get_writer_stack_ptr(data);
    while (anchor.*) |cur| {
        if (cur.phase >= writer.phase) break;
        anchor = &cur.next;
    }
    writer.next = anchor.*;
    anchor.* = writer;
}

fn doInitWriterStack(data: ?*CurlEasy) CURLcode {
    const stack_ptr = Curl_sendf_get_writer_stack_ptr(data);
    var writer: ?*CurlCwriter = null;
    var result: CURLcode = CURLE_OK;

    std.debug.assert(stack_ptr.* == null);
    result = Curl_cwriter_create(stack_ptr, data, &Curl_cwt_out, CURL_CW_CLIENT);
    if (result != CURLE_OK)
        return result;

    result = Curl_cwriter_create(&writer, data, &cw_download, CURL_CW_PROTOCOL);
    if (result != CURLE_OK)
        return result;
    cwriterAdd(data, writer.?);

    result = Curl_cwriter_create(&writer, data, &cw_raw, CURL_CW_RAW);
    if (result != CURLE_OK)
        return result;
    cwriterAdd(data, writer.?);

    return result;
}

pub export fn Curl_client_write(
    data: ?*CurlEasy,
    type_flags: c_int,
    buf: ?[*]const u8,
    len: usize,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;

    std.debug.assert((type_flags & (CLIENTWRITE_BODY | CLIENTWRITE_HEADER | CLIENTWRITE_INFO)) != 0);
    std.debug.assert((type_flags & CLIENTWRITE_BODY) == 0 or
        ((type_flags & ~(CLIENTWRITE_BODY | CLIENTWRITE_EOS)) == 0));
    std.debug.assert((type_flags & CLIENTWRITE_INFO) == 0 or
        ((type_flags & ~(CLIENTWRITE_INFO | CLIENTWRITE_EOS)) == 0));

    const stack_ptr = Curl_sendf_get_writer_stack_ptr(data);
    if (stack_ptr.* == null) {
        result = doInitWriterStack(data);
        if (result != CURLE_OK)
            return result;
        std.debug.assert(stack_ptr.* != null);
    }

    result = cwriterWrite(data, stack_ptr.*, type_flags, buf, len);
    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_write)) {
        Curl_trc_write(
            data,
            "client_write(type=%x, len=%zu) -> %d",
            @as(c_uint, @intCast(type_flags)),
            len,
            @as(c_int, @intCast(result)),
        );
    }
    return result;
}

pub export fn Curl_client_flush(data: ?*CurlEasy) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const stack_ptr = Curl_sendf_get_writer_stack_ptr(data);

    if (stack_ptr.* == null) {
        result = doInitWriterStack(data);
        if (result != CURLE_OK)
            return result;
        std.debug.assert(stack_ptr.* != null);
    }

    result = cwriterFlush(data, stack_ptr.*);
    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_write)) {
        Curl_trc_write(data, "client_flush() -> %d", @as(c_int, @intCast(result)));
    }
    return result;
}

fn cwriterCreateChecked(
    data: ?*CurlEasy,
    cwt: *const CurlCwtype,
    phase: CurlCwriterPhase,
    out_result: *CURLcode,
) error{CurlFailed}!*CurlCwriter {
    std.debug.assert(cwt.cwriter_size >= @sizeOf(CurlCwriter));
    const raw = mem.calloc(1, cwt.cwriter_size) orelse {
        out_result.* = CURLE_OUT_OF_MEMORY;
        return error.CurlFailed;
    };
    const w = fromOpaque(CurlCwriter, raw);
    errdefer mem.freeTyped(w);
    w.cwt = cwt;
    w.ctx = raw;
    w.phase = phase;
    const result = cwt.do_init(data, w);
    out_result.* = result;
    if (result != CURLE_OK)
        return error.CurlFailed;
    return w;
}

pub export fn Curl_cwriter_create(
    pwriter: *?*CurlCwriter,
    data: ?*CurlEasy,
    cwt: *const CurlCwtype,
    phase: CurlCwriterPhase,
) callconv(.c) CURLcode {
    errdefer pwriter.* = null;
    var result: CURLcode = CURLE_OUT_OF_MEMORY;
    const w = cwriterCreateChecked(data, cwt, phase, &result) catch {
        pwriter.* = null;
        return result;
    };
    pwriter.* = w;
    return CURLE_OK;
}

pub export fn Curl_cwriter_free(
    data: ?*CurlEasy,
    writer: ?*CurlCwriter,
) callconv(.c) void {
    if (writer) |w| {
        w.cwt.do_close(data, w);
        mem.freeTyped(w);
    }
}

pub export fn Curl_cwriter_count(
    data: ?*CurlEasy,
    phase: CurlCwriterPhase,
) callconv(.c) usize {
    var w = Curl_sendf_get_writer_stack_ptr(data).*;
    var n: usize = 0;
    while (w) |cur| : (w = cur.next) {
        if (cur.phase == phase)
            n += 1;
    }
    return n;
}

fn cwriterEnsurePauseWriter(data: ?*CurlEasy) CURLcode {
    var writer = Curl_cwriter_get_by_type(data, &Curl_cwt_pause);
    var result: CURLcode = CURLE_OK;

    if (writer == null) {
        result = Curl_cwriter_create(&writer, data, &Curl_cwt_pause, CURL_CW_BEFORE_DECODE);
        if (result == CURLE_OK)
            cwriterAdd(data, writer.?);
    }
    return result;
}

pub export fn Curl_cwriter_add(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const anchor = Curl_sendf_get_writer_stack_ptr(data);

    if (anchor.* == null) {
        result = doInitWriterStack(data);
        if (result != CURLE_OK)
            return result;
    }

    if ((writer.cwt.flags & CURL_CW_FLAG_BLOWUP) != 0) {
        result = cwriterEnsurePauseWriter(data);
        if (result != CURLE_OK)
            return result;
    }

    cwriterAdd(data, writer);
    return CURLE_OK;
}

pub export fn Curl_cwriter_get_by_name(
    data: ?*CurlEasy,
    name: [*:0]const u8,
) callconv(.c) ?*CurlCwriter {
    var writer = Curl_sendf_get_writer_stack_ptr(data).*;
    while (writer) |w| : (writer = w.next) {
        if (std.mem.orderZ(u8, name, w.cwt.name) == .eq)
            return w;
    }
    return null;
}

pub export fn Curl_cwriter_get_by_type(
    data: ?*CurlEasy,
    cwt: *const CurlCwtype,
) callconv(.c) ?*CurlCwriter {
    var writer = Curl_sendf_get_writer_stack_ptr(data).*;
    while (writer) |w| : (writer = w.next) {
        if (w.cwt == cwt)
            return w;
    }
    return null;
}

pub export fn Curl_cwriter_unpause(data: ?*CurlEasy) callconv(.c) CURLcode {
    Curl_cw_out_set_paused(data, false);
    return cwriterFlush(data, Curl_sendf_get_writer_stack_ptr(data).*);
}

pub export fn Curl_creader_read(
    data: ?*CurlEasy,
    reader: ?*CurlCreader,
    buf: ?[*]u8,
    blen: usize,
    nread: *usize,
    eos: *bool,
) callconv(.c) CURLcode {
    nread.* = 0;
    eos.* = false;
    const r = reader orelse return CURLE_READ_ERROR;
    return r.crt.do_read(data, r, buf, blen, nread, eos);
}

pub export fn Curl_creader_clear_eos(
    data: ?*CurlEasy,
    reader_arg: ?*CurlCreader,
) callconv(.c) void {
    var reader = reader_arg;
    while (reader) |r| : (reader = r.next) {
        _ = r.crt.cntrl(data, r, CURL_CRCNTRL_CLEAR_EOS);
    }
}

pub export fn Curl_creader_def_init(
    data: ?*CurlEasy,
    reader: *CurlCreader,
) callconv(.c) CURLcode {
    _ = data;
    _ = reader;
    return CURLE_OK;
}

pub export fn Curl_creader_def_close(
    data: ?*CurlEasy,
    reader: *CurlCreader,
) callconv(.c) void {
    _ = data;
    _ = reader;
}

pub export fn Curl_creader_def_read(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    buf: ?[*]u8,
    blen: usize,
    nread: *usize,
    eos: *bool,
) callconv(.c) CURLcode {
    if (reader.next) |next| {
        return next.crt.do_read(data, next, buf, blen, nread, eos);
    } else {
        nread.* = 0;
        eos.* = false;
        return CURLE_READ_ERROR;
    }
}

pub export fn Curl_creader_def_needs_rewind(
    data: ?*CurlEasy,
    reader: *CurlCreader,
) callconv(.c) bool {
    _ = data;
    _ = reader;
    return false;
}

pub export fn Curl_creader_def_total_length(
    data: ?*CurlEasy,
    reader: *CurlCreader,
) callconv(.c) curl_off_t {
    return if (reader.next) |next| next.crt.total_length(data, next) else -1;
}

pub export fn Curl_creader_def_resume_from(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    offset: curl_off_t,
) callconv(.c) CURLcode {
    _ = data;
    _ = reader;
    _ = offset;
    return CURLE_READ_ERROR;
}

pub export fn Curl_creader_def_cntrl(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    opcode: CurlCreaderCntrl,
) callconv(.c) CURLcode {
    _ = data;
    _ = reader;
    _ = opcode;
    return CURLE_OK;
}

pub export fn Curl_creader_def_is_paused(
    data: ?*CurlEasy,
    reader: *CurlCreader,
) callconv(.c) bool {
    _ = data;
    _ = reader;
    return false;
}

pub export fn Curl_creader_def_done(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    premature: c_int,
) callconv(.c) void {
    _ = data;
    _ = reader;
    _ = premature;
}

const CrInCtx = extern struct {
    super: CurlCreader,
    read_cb: CurlReadCallback,
    cb_user_data: ?*anyopaque,
    total_len: curl_off_t,
    read_len: curl_off_t,
    error_result: CURLcode,
    flags: u8,

    fn seenEos(self: *const CrInCtx) bool {
        return (self.flags & (1 << 0)) != 0;
    }
    fn setSeenEos(self: *CrInCtx, v: bool) void {
        if (v) self.flags |= (1 << 0) else self.flags &= ~@as(u8, 1 << 0);
    }
    fn isErrored(self: *const CrInCtx) bool {
        return (self.flags & (1 << 1)) != 0;
    }
    fn setErrored(self: *CrInCtx, v: bool) void {
        if (v) self.flags |= (1 << 1) else self.flags &= ~@as(u8, 1 << 1);
    }
    fn hasUsedCb(self: *const CrInCtx) bool {
        return (self.flags & (1 << 2)) != 0;
    }
    fn setHasUsedCb(self: *CrInCtx, v: bool) void {
        if (v) self.flags |= (1 << 2) else self.flags &= ~@as(u8, 1 << 2);
    }
    fn isPaused(self: *const CrInCtx) bool {
        return (self.flags & (1 << 3)) != 0;
    }
    fn setPaused(self: *CrInCtx, v: bool) void {
        if (v) self.flags |= (1 << 3) else self.flags &= ~@as(u8, 1 << 3);
    }
};

fn crInInit(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) CURLcode {
    const ctx = reader.ctxAs(CrInCtx);
    Curl_sendf_get_fread_in(data, &ctx.read_cb, &ctx.cb_user_data);
    ctx.total_len = -1;
    ctx.read_len = 0;
    return CURLE_OK;
}

fn crInRead(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    buf: ?[*]u8,
    blen_arg: usize,
    pnread: *usize,
    peos: *bool,
) callconv(.c) CURLcode {
    const ctx = reader.ctxAs(CrInCtx);
    var result: CURLcode = CURLE_OK;
    var blen = blen_arg;

    ctx.setPaused(false);

    if (ctx.isErrored()) {
        pnread.* = 0;
        peos.* = false;
        return ctx.error_result;
    }
    if (ctx.seenEos()) {
        pnread.* = 0;
        peos.* = true;
        return CURLE_OK;
    }
    if (ctx.total_len >= 0) {
        blen = curlx_sotouz_range(ctx.total_len - ctx.read_len, 0, blen);
    }
    var nread: usize = 0;
    if (ctx.read_cb != null and blen != 0) {
        var guard: CurlMapiGuard = undefined;
        Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_cr_in_read);
        nread = ctx.read_cb.?(buf.?, 1, blen, ctx.cb_user_data);
        Curl_cbapi_leave(&guard);
        ctx.setHasUsedCb(true);
    }

    switch (nread) {
        0 => {
            if ((ctx.total_len >= 0) and (ctx.read_len < ctx.total_len)) {
                Curl_trc_bind_c(data);
                Curl_failf(
                    data,
                    "client read function EOF fail, only %lld/%lld of needed bytes read",
                    @as(c_longlong, ctx.read_len),
                    @as(c_longlong, ctx.total_len),
                );
                result = CURLE_READ_ERROR;
            } else {
                pnread.* = 0;
                peos.* = true;
                ctx.setSeenEos(true);
            }
        },
        CURL_READFUNC_ABORT => {
            Curl_trc_bind_c(data);
            Curl_failf(data, "operation aborted by callback");
            pnread.* = 0;
            peos.* = false;
            ctx.setErrored(true);
            ctx.error_result = CURLE_ABORTED_BY_CALLBACK;
            result = CURLE_ABORTED_BY_CALLBACK;
        },
        CURL_READFUNC_PAUSE => {
            if (Curl_cw_out_is_nonetwork(data)) {
                Curl_trc_bind_c(data);
                Curl_failf(data, "Read callback asked for PAUSE when not supported");
                result = CURLE_READ_ERROR;
            } else {
                if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
                    Curl_trc_read(data, "cr_in_read, callback returned CURL_READFUNC_PAUSE");
                }
                ctx.setPaused(true);
                pnread.* = 0;
                peos.* = false;
                result = Curl_xfer_pause_send(data, true);
            }
        },
        else => {
            if (nread > blen) {
                Curl_trc_bind_c(data);
                Curl_failf(data, "read function returned funny value");
                pnread.* = 0;
                peos.* = false;
                ctx.setErrored(true);
                ctx.error_result = CURLE_READ_ERROR;
                result = CURLE_READ_ERROR;
            } else {
                ctx.read_len += @intCast(nread);
                if (ctx.total_len >= 0)
                    ctx.setSeenEos(ctx.read_len >= ctx.total_len);
                pnread.* = nread;
                peos.* = ctx.seenEos();
            }
        },
    }

    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
        Curl_trc_read(
            data,
            "cr_in_read(len=%zu, total=%lld, read=%lld) -> %d, nread=%zu, eos=%d",
            blen,
            @as(c_longlong, ctx.total_len),
            @as(c_longlong, ctx.read_len),
            @as(c_int, @intCast(result)),
            pnread.*,
            @as(c_int, @intFromBool(peos.*)),
        );
    }
    return result;
}

fn crInNeedsRewind(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) bool {
    _ = data;
    const ctx = reader.ctxAs(CrInCtx);
    return ctx.hasUsedCb();
}

fn crInTotalLength(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) curl_off_t {
    _ = data;
    const ctx = reader.ctxAs(CrInCtx);
    return ctx.total_len;
}

fn crInResumeFrom(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    offset: curl_off_t,
) callconv(.c) CURLcode {
    const ctx = reader.ctxAs(CrInCtx);
    var seekerr: c_int = CURL_SEEKFUNC_CANTSEEK;

    std.debug.assert(Curl_xfer_get_conn(data) != null);
    if (ctx.read_len != 0)
        return CURLE_READ_ERROR;

    if (Curl_sendf_has_seek_func(data)) {
        seekerr = Curl_sendf_call_seek_func(data, offset);
    }

    if (seekerr != CURL_SEEKFUNC_OK) {
        var passed: curl_off_t = 0;

        if (seekerr != CURL_SEEKFUNC_CANTSEEK) {
            Curl_trc_bind_c(data);
            Curl_failf(data, "Could not seek stream");
            return CURLE_READ_ERROR;
        }

        while (true) {
            var guard: CurlMapiGuard = undefined;
            var scratch: [4 * 1024]u8 = undefined;
            const readthisamountnow: usize = if (offset - passed > @as(curl_off_t, scratch.len))
                scratch.len
            else
                curlx_sotouz(offset - passed);

            Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_cr_in_resume_from);
            const actuallyread = ctx.read_cb.?(&scratch, 1, readthisamountnow, ctx.cb_user_data);
            Curl_cbapi_leave(&guard);

            passed += @intCast(actuallyread);
            if (actuallyread == 0 or actuallyread > readthisamountnow) {
                Curl_trc_bind_c(data);
                Curl_failf(
                    data,
                    "Could only read %lld bytes from the input",
                    @as(c_longlong, passed),
                );
                return CURLE_READ_ERROR;
            }
            if (passed >= offset) break;
        }
    }

    if (ctx.total_len > 0) {
        ctx.total_len -= offset;

        if (ctx.total_len <= 0) {
            Curl_trc_bind_c(data);
            Curl_failf(data, "File already completely uploaded");
            return CURLE_PARTIAL_FILE;
        }
    }
    return CURLE_OK;
}

fn crInRewind(data: ?*CurlEasy, reader: *CurlCreader) CURLcode {
    const ctx = reader.ctxAs(CrInCtx);

    if (!ctx.hasUsedCb())
        return CURLE_OK;

    if (Curl_sendf_has_seek_func(data)) {
        const err = Curl_sendf_call_seek_func(data, 0);
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
            Curl_trc_read(data, "cr_in, rewind via set.seek_func -> %d", err);
        }
        if (err != 0) {
            Curl_trc_bind_c(data);
            Curl_failf(data, "seek callback returned error %d", err);
            return CURLE_SEND_FAIL_REWIND;
        }
    } else if (Curl_sendf_has_ioctl_func(data)) {
        const err = Curl_sendf_call_ioctl_restartread(data);
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
            Curl_trc_read(data, "cr_in, rewind via set.ioctl_func -> %d", err);
        }
        if (err != 0) {
            Curl_trc_bind_c(data);
            Curl_failf(data, "ioctl callback returned error %d", err);
            return CURLE_SEND_FAIL_REWIND;
        }
    } else {
        var err: c_int = -1;
        var err_no: c_int = 0;
        if (Curl_sendf_try_fseek_rewind(data, &err, &err_no)) {
            if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
                Curl_trc_read(data, "cr_in, rewind via fseek -> %d(%d)", err, err_no);
            }
            if (err != -1)
                return CURLE_OK;
        }

        Curl_trc_bind_c(data);
        Curl_failf(data, "necessary data rewind was not possible");
        return CURLE_SEND_FAIL_REWIND;
    }
    return CURLE_OK;
}

fn crInCntrl(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    opcode: CurlCreaderCntrl,
) callconv(.c) CURLcode {
    const ctx = reader.ctxAs(CrInCtx);

    switch (opcode) {
        CURL_CRCNTRL_REWIND => return crInRewind(data, reader),
        CURL_CRCNTRL_UNPAUSE => ctx.setPaused(false),
        CURL_CRCNTRL_CLEAR_EOS => ctx.setSeenEos(false),
        else => {},
    }
    return CURLE_OK;
}

fn crInIsPaused(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) bool {
    _ = data;
    const ctx = reader.ctxAs(CrInCtx);
    return ctx.isPaused();
}

const cr_in: CurlCrtype = .{
    .name = "cr-in",
    .do_init = crInInit,
    .do_read = crInRead,
    .do_close = Curl_creader_def_close,
    .needs_rewind = crInNeedsRewind,
    .total_length = crInTotalLength,
    .resume_from = crInResumeFrom,
    .cntrl = crInCntrl,
    .is_paused = crInIsPaused,
    .done = Curl_creader_def_done,
    .creader_size = @sizeOf(CrInCtx),
};

fn creaderCreateChecked(
    data: ?*CurlEasy,
    crt: *const CurlCrtype,
    phase: CurlCreaderPhase,
    out_result: *CURLcode,
) error{CurlFailed}!*CurlCreader {
    std.debug.assert(crt.creader_size >= @sizeOf(CurlCreader));
    const raw = mem.calloc(1, crt.creader_size) orelse {
        out_result.* = CURLE_OUT_OF_MEMORY;
        return error.CurlFailed;
    };
    const r = fromOpaque(CurlCreader, raw);
    errdefer mem.freeTyped(r);
    r.crt = crt;
    r.ctx = raw;
    r.phase = phase;
    const result = crt.do_init(data, r);
    out_result.* = result;
    if (result != CURLE_OK)
        return error.CurlFailed;
    return r;
}

pub export fn Curl_creader_create(
    preader: *?*CurlCreader,
    data: ?*CurlEasy,
    crt: *const CurlCrtype,
    phase: CurlCreaderPhase,
) callconv(.c) CURLcode {
    errdefer preader.* = null;
    var result: CURLcode = CURLE_OUT_OF_MEMORY;
    const r = creaderCreateChecked(data, crt, phase, &result) catch {
        preader.* = null;
        return result;
    };
    preader.* = r;
    return CURLE_OK;
}

pub export fn Curl_creader_free(
    data: ?*CurlEasy,
    reader: ?*CurlCreader,
) callconv(.c) void {
    if (reader) |r| {
        r.crt.do_close(data, r);
        mem.freeTyped(r);
    }
}

const CrLcCtx = extern struct {
    super: CurlCreader,
    buf: io_buffers.bufq,
    flags: u8,

    fn readEos(self: *const CrLcCtx) bool {
        return (self.flags & (1 << 0)) != 0;
    }
    fn setReadEos(self: *CrLcCtx, v: bool) void {
        if (v) self.flags |= (1 << 0) else self.flags &= ~@as(u8, 1 << 0);
    }
    fn isEos(self: *const CrLcCtx) bool {
        return (self.flags & (1 << 1)) != 0;
    }
    fn setEos(self: *CrLcCtx, v: bool) void {
        if (v) self.flags |= (1 << 1) else self.flags &= ~@as(u8, 1 << 1);
    }
    fn prevCr(self: *const CrLcCtx) bool {
        return (self.flags & (1 << 2)) != 0;
    }
    fn setPrevCr(self: *CrLcCtx, v: bool) void {
        if (v) self.flags |= (1 << 2) else self.flags &= ~@as(u8, 1 << 2);
    }
};

fn crLcInit(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) CURLcode {
    _ = data;
    const ctx = reader.ctxAs(CrLcCtx);
    io_buffers.Curl_bufq_init2(&ctx.buf, 16 * 1024, 1, io_buffers.BUFQ_OPT_SOFT_LIMIT);
    return CURLE_OK;
}

fn crLcClose(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) void {
    _ = data;
    const ctx = reader.ctxAs(CrLcCtx);
    io_buffers.Curl_bufq_free(&ctx.buf);
}

fn crLcRead(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    buf_opt: ?[*]u8,
    blen: usize,
    pnread: *usize,
    peos: *bool,
) callconv(.c) CURLcode {
    const ctx = reader.ctxAs(CrLcCtx);
    const buf = buf_opt.?;
    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;
    var i: usize = 0;
    var start: usize = 0;
    var n: usize = 0;
    var eos: bool = false;

    if (ctx.isEos()) {
        pnread.* = 0;
        peos.* = true;
        return CURLE_OK;
    }

    if (io_buffers.Curl_bufq_is_empty(&ctx.buf)) {
        if (ctx.readEos()) {
            ctx.setEos(true);
            pnread.* = 0;
            peos.* = true;
            return CURLE_OK;
        }
        result = Curl_creader_read(data, reader.next, buf, blen, &nread, &eos);
        if (result != CURLE_OK)
            return result;
        ctx.setReadEos(eos);

        if (nread == 0 or std.mem.indexOfScalar(u8, buf[0..nread], '\n') == null) {
            if (nread != 0)
                ctx.setPrevCr(buf[nread - 1] == '\r');
            if (ctx.readEos())
                ctx.setEos(true);
            pnread.* = nread;
            peos.* = ctx.isEos();
            if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
                Curl_trc_read(
                    data,
                    "cr_lc_read(len=%zu) -> %d, nread=%zu, eos=%d",
                    blen,
                    @as(c_int, @intCast(result)),
                    pnread.*,
                    @as(c_int, @intFromBool(peos.*)),
                );
            }
            return result;
        }

        i = 0;
        start = 0;
        while (i < nread) : (i += 1) {
            if (buf[i] != '\n' or ctx.prevCr()) {
                ctx.setPrevCr(buf[i] == '\r');
                continue;
            }
            ctx.setPrevCr(false);
            result = io_buffers.Curl_bufq_cwrite(&ctx.buf, buf + start, i - start, &n);
            if (result == CURLE_OK)
                result = io_buffers.Curl_bufq_cwrite(&ctx.buf, "\r\n", 2, &n);
            if (result != CURLE_OK)
                return result;
            start = i + 1;
        }

        if (start < i) {
            result = io_buffers.Curl_bufq_cwrite(&ctx.buf, buf + start, i - start, &n);
            if (result != CURLE_OK)
                return result;
        }
    }

    std.debug.assert(!io_buffers.Curl_bufq_is_empty(&ctx.buf));
    peos.* = false;
    result = io_buffers.Curl_bufq_cread(&ctx.buf, buf, blen, pnread);
    if (result == CURLE_OK and ctx.readEos() and io_buffers.Curl_bufq_is_empty(&ctx.buf)) {
        ctx.setEos(true);
        peos.* = true;
    }

    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
        Curl_trc_read(
            data,
            "cr_lc_read(len=%zu) -> %d, nread=%zu, eos=%d",
            blen,
            @as(c_int, @intCast(result)),
            pnread.*,
            @as(c_int, @intFromBool(peos.*)),
        );
    }
    return result;
}

fn crLcTotalLength(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) curl_off_t {
    _ = data;
    _ = reader;
    return -1;
}

const cr_lc: CurlCrtype = .{
    .name = "cr-lineconv",
    .do_init = crLcInit,
    .do_read = crLcRead,
    .do_close = crLcClose,
    .needs_rewind = Curl_creader_def_needs_rewind,
    .total_length = crLcTotalLength,
    .resume_from = Curl_creader_def_resume_from,
    .cntrl = Curl_creader_def_cntrl,
    .is_paused = Curl_creader_def_is_paused,
    .done = Curl_creader_def_done,
    .creader_size = @sizeOf(CrLcCtx),
};

fn crLcAddChecked(data: ?*CurlEasy, out_result: *CURLcode) error{CurlFailed}!void {
    const r = try creaderCreateChecked(data, &cr_lc, CURL_CR_CONTENT_ENCODE, out_result);
    errdefer Curl_creader_free(data, r);
    const result = Curl_creader_add(data, r);
    out_result.* = result;
    if (result != CURLE_OK)
        return error.CurlFailed;
}

fn crLcAdd(data: ?*CurlEasy) CURLcode {
    var result: CURLcode = CURLE_OK;
    crLcAddChecked(data, &result) catch return result;
    return CURLE_OK;
}

fn doInitReaderStack(data: ?*CurlEasy, r: *CurlCreader) CURLcode {
    var result: CURLcode = CURLE_OK;
    const stack_ptr = Curl_sendf_get_reader_stack_ptr(data);

    std.debug.assert(r.phase == CURL_CR_CLIENT);
    std.debug.assert(stack_ptr.* == null);

    stack_ptr.* = r;
    const clen = r.crt.total_length(data, r);
    if (clen != 0 and Curl_sendf_want_crlf_reader(data)) {
        result = crLcAdd(data);
        if (result != CURLE_OK)
            return result;
    }

    return result;
}

pub export fn Curl_creader_set_fread(
    data: ?*CurlEasy,
    len: curl_off_t,
) callconv(.c) CURLcode {
    var r: ?*CurlCreader = null;
    var result = Curl_creader_create(&r, data, &cr_in, CURL_CR_CLIENT);
    if (result == CURLE_OK and r != null) {
        const ctx = r.?.ctxAs(CrInCtx);
        ctx.total_len = len;

        clResetReader(data);
        result = doInitReaderStack(data, r.?);
    }
    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
        Curl_trc_read(
            data,
            "add fread reader, len=%lld -> %d",
            @as(c_longlong, len),
            @as(c_int, @intCast(result)),
        );
    }
    return result;
}

pub export fn Curl_creader_add(
    data: ?*CurlEasy,
    reader: *CurlCreader,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var anchor = Curl_sendf_get_reader_stack_ptr(data);

    if (anchor.* == null) {
        result = Curl_creader_set_fread(data, Curl_sendf_get_infilesize(data));
        if (result != CURLE_OK)
            return result;
    }

    while (anchor.*) |cur| {
        if (cur.phase >= reader.phase) break;
        anchor = &cur.next;
    }
    reader.next = anchor.*;
    anchor.* = reader;
    return CURLE_OK;
}

fn creaderSetChecked(data: ?*CurlEasy, r: *CurlCreader, out_result: *CURLcode) error{CurlFailed}!void {
    errdefer Curl_creader_free(data, r);
    const result = doInitReaderStack(data, r);
    out_result.* = result;
    if (result != CURLE_OK)
        return error.CurlFailed;
}

pub export fn Curl_creader_set(
    data: ?*CurlEasy,
    r: *CurlCreader,
) callconv(.c) CURLcode {
    std.debug.assert(r.phase == CURL_CR_CLIENT);

    clResetReader(data);
    var result: CURLcode = CURLE_OK;
    creaderSetChecked(data, r, &result) catch return result;
    return CURLE_OK;
}

pub export fn Curl_client_read(
    data: ?*CurlEasy,
    buf: [*]u8,
    blen_arg: usize,
    nread: *usize,
    eos: *bool,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var blen = blen_arg;

    std.debug.assert(blen != 0);
    nread.* = 0;

    const stack_ptr = Curl_sendf_get_reader_stack_ptr(data);
    if (stack_ptr.* == null) {
        result = Curl_creader_set_fread(data, Curl_sendf_get_infilesize(data));
        if (result != CURLE_OK)
            return result;
        std.debug.assert(stack_ptr.* != null);
    }
    const ul_rlimit = Curl_xfer_get_ul_rlimit(data);
    if (!Curl_sendf_get_reader_started(data)) {
        headers_sock.Curl_rlimit_start(ul_rlimit, Curl_pgrs_now(data), -1);
        Curl_sendf_set_reader_started(data, true);
    }

    var do_read = true;
    if (headers_sock.Curl_rlimit_active(ul_rlimit)) {
        const ul_avail = headers_sock.Curl_rlimit_avail(ul_rlimit, null);
        if (ul_avail <= 0) {
            result = CURLE_OK;
            eos.* = false;
            do_read = false;
        } else if (ul_avail < @as(curl_off_t, @intCast(blen))) {
            blen = @intCast(ul_avail);
        }
    }
    if (do_read) {
        result = Curl_creader_read(data, stack_ptr.*, buf, blen, nread, eos);
    }

    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
        Curl_trc_read(
            data,
            "client_read(len=%zu) -> %d, nread=%zu, eos=%d",
            blen,
            @as(c_int, @intCast(result)),
            nread.*,
            @as(c_int, @intFromBool(eos.*)),
        );
    }
    return result;
}

pub export fn Curl_creader_needs_rewind(data: ?*CurlEasy) callconv(.c) bool {
    var reader = Curl_sendf_get_reader_stack_ptr(data).*;
    while (reader) |r| : (reader = r.next) {
        if (r.crt.needs_rewind(data, r)) {
            if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
                Curl_trc_read(data, "client reader needs rewind before next request");
            }
            return true;
        }
    }
    return false;
}

fn crNullRead(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    buf: ?[*]u8,
    blen: usize,
    pnread: *usize,
    peos: *bool,
) callconv(.c) CURLcode {
    _ = data;
    _ = reader;
    _ = buf;
    _ = blen;
    pnread.* = 0;
    peos.* = true;
    return CURLE_OK;
}

fn crNullTotalLength(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) curl_off_t {
    _ = data;
    _ = reader;
    return 0;
}

const cr_null: CurlCrtype = .{
    .name = "cr-null",
    .do_init = Curl_creader_def_init,
    .do_read = crNullRead,
    .do_close = Curl_creader_def_close,
    .needs_rewind = Curl_creader_def_needs_rewind,
    .total_length = crNullTotalLength,
    .resume_from = Curl_creader_def_resume_from,
    .cntrl = Curl_creader_def_cntrl,
    .is_paused = Curl_creader_def_is_paused,
    .done = Curl_creader_def_done,
    .creader_size = @sizeOf(CurlCreader),
};

pub export fn Curl_creader_set_null(data: ?*CurlEasy) callconv(.c) CURLcode {
    var r: ?*CurlCreader = null;
    const result = Curl_creader_create(&r, data, &cr_null, CURL_CR_CLIENT);
    if (result != CURLE_OK)
        return result;

    clResetReader(data);
    return doInitReaderStack(data, r.?);
}

const CrBufCtx = extern struct {
    super: CurlCreader,
    buf: ?[*]const u8,
    blen: usize,
    index: usize,
};

fn crBufRead(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    buf_opt: ?[*]u8,
    blen: usize,
    pnread: *usize,
    peos: *bool,
) callconv(.c) CURLcode {
    const ctx = reader.ctxAs(CrBufCtx);
    var nread = ctx.blen - ctx.index;

    if (nread == 0 or ctx.buf == null) {
        pnread.* = 0;
        peos.* = true;
    } else {
        if (nread > blen)
            nread = blen;
        const dst = buf_opt.?;
        const src = ctx.buf.? + ctx.index;
        @memcpy(dst[0..nread], src[0..nread]);
        pnread.* = nread;
        ctx.index += nread;
        peos.* = (ctx.index == ctx.blen);
    }
    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
        Curl_trc_read(
            data,
            "cr_buf_read(len=%zu) -> 0, nread=%zu, eos=%d",
            blen,
            pnread.*,
            @as(c_int, @intFromBool(peos.*)),
        );
    }
    return CURLE_OK;
}

fn crBufNeedsRewind(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) bool {
    _ = data;
    const ctx = reader.ctxAs(CrBufCtx);
    return ctx.index > 0;
}

fn crBufCntrl(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    opcode: CurlCreaderCntrl,
) callconv(.c) CURLcode {
    _ = data;
    const ctx = reader.ctxAs(CrBufCtx);
    switch (opcode) {
        CURL_CRCNTRL_REWIND => ctx.index = 0,
        else => {},
    }
    return CURLE_OK;
}

fn crBufTotalLength(data: ?*CurlEasy, reader: *CurlCreader) callconv(.c) curl_off_t {
    _ = data;
    const ctx = reader.ctxAs(CrBufCtx);
    return @intCast(ctx.blen);
}

fn crBufResumeFrom(
    data: ?*CurlEasy,
    reader: *CurlCreader,
    offset: curl_off_t,
) callconv(.c) CURLcode {
    const ctx = reader.ctxAs(CrBufCtx);
    std.debug.assert(Curl_xfer_get_conn(data) != null);
    if (ctx.index != 0)
        return CURLE_READ_ERROR;
    const boffset = curlx_sotouz_range(offset, 0, std.math.maxInt(usize));
    if (boffset == 0)
        return CURLE_OK;
    if (boffset > ctx.blen)
        return CURLE_READ_ERROR;

    if (ctx.buf) |b| ctx.buf = b + boffset;
    ctx.blen -= boffset;
    return CURLE_OK;
}

const cr_buf: CurlCrtype = .{
    .name = "cr-buf",
    .do_init = Curl_creader_def_init,
    .do_read = crBufRead,
    .do_close = Curl_creader_def_close,
    .needs_rewind = crBufNeedsRewind,
    .total_length = crBufTotalLength,
    .resume_from = crBufResumeFrom,
    .cntrl = crBufCntrl,
    .is_paused = Curl_creader_def_is_paused,
    .done = Curl_creader_def_done,
    .creader_size = @sizeOf(CrBufCtx),
};

pub export fn Curl_creader_set_buf(
    data: ?*CurlEasy,
    buf: ?[*]const u8,
    blen: usize,
) callconv(.c) CURLcode {
    var r: ?*CurlCreader = null;
    var result = Curl_creader_create(&r, data, &cr_buf, CURL_CR_CLIENT);
    if (result == CURLE_OK) {
        const ctx = r.?.ctxAs(CrBufCtx);
        ctx.buf = buf;
        ctx.blen = blen;
        ctx.index = 0;

        clResetReader(data);
        result = doInitReaderStack(data, r.?);
    }
    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
        Curl_trc_read(
            data,
            "add buf reader, len=%zu -> %d",
            blen,
            @as(c_int, @intCast(result)),
        );
    }
    return result;
}

pub export fn Curl_creader_total_length(data: ?*CurlEasy) callconv(.c) curl_off_t {
    const r = Curl_sendf_get_reader_stack_ptr(data).*;
    return if (r) |cur| cur.crt.total_length(data, cur) else -1;
}

pub export fn Curl_creader_client_length(data: ?*CurlEasy) callconv(.c) curl_off_t {
    var r = Curl_sendf_get_reader_stack_ptr(data).*;
    while (r) |cur| : (r = cur.next) {
        if (cur.phase == CURL_CR_CLIENT)
            return cur.crt.total_length(data, cur);
    }
    return -1;
}

pub export fn Curl_creader_unpause(data: ?*CurlEasy) callconv(.c) CURLcode {
    var reader = Curl_sendf_get_reader_stack_ptr(data).*;
    var result: CURLcode = CURLE_OK;

    while (reader) |r| : (reader = r.next) {
        result = r.crt.cntrl(data, r, CURL_CRCNTRL_UNPAUSE);
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_read)) {
            Curl_trc_read(data, "unpausing %s -> %d", r.crt.name, @as(c_int, @intCast(result)));
        }
        if (result != CURLE_OK)
            break;
    }
    return result;
}

pub export fn Curl_creader_is_paused(data: ?*CurlEasy) callconv(.c) bool {
    var reader = Curl_sendf_get_reader_stack_ptr(data).*;
    while (reader) |r| : (reader = r.next) {
        if (r.crt.is_paused(data, r))
            return true;
    }
    return false;
}

pub export fn Curl_creader_done(data: ?*CurlEasy, premature: c_int) callconv(.c) void {
    var reader = Curl_sendf_get_reader_stack_ptr(data).*;
    while (reader) |r| : (reader = r.next) {
        r.crt.done(data, r, premature);
    }
}

pub export fn Curl_creader_get_by_type(
    data: ?*CurlEasy,
    crt: *const CurlCrtype,
) callconv(.c) ?*CurlCreader {
    var r = Curl_sendf_get_reader_stack_ptr(data).*;
    while (r) |cur| : (r = cur.next) {
        if (cur.crt == crt)
            return cur;
    }
    return null;
}

// ============================================================================
// 2. lib/dllmain.c - Windows DLL Entry Point
// ============================================================================

pub const DLL_PROCESS_DETACH: u32 = 0;
pub const DLL_PROCESS_ATTACH: u32 = 1;
pub const DLL_THREAD_ATTACH: u32 = 2;
pub const DLL_THREAD_DETACH: u32 = 3;

const dllmain_cc: std.builtin.CallingConvention = if (builtin.os.tag == .windows) .winapi else .c;

pub fn dllMainImpl(
    hinstDLL: ?*anyopaque,
    fdwReason: u32,
    lpvReserved: ?*anyopaque,
    thread_stop_cb: ?*const fn () callconv(.c) void,
) c_int {
    _ = hinstDLL;
    _ = lpvReserved;
    switch (fdwReason) {
        DLL_PROCESS_ATTACH => {},
        DLL_PROCESS_DETACH => {},
        DLL_THREAD_ATTACH => {},
        DLL_THREAD_DETACH => {
            if (thread_stop_cb) |cb| cb();
        },
        else => {},
    }
    return 1;
}

pub fn DllMain(
    hinstDLL: ?*anyopaque,
    fdwReason: u32,
    lpvReserved: ?*anyopaque,
) callconv(dllmain_cc) c_int {
    return dllMainImpl(hinstDLL, fdwReason, lpvReserved, null);
}

comptime {
    if (builtin.os.tag == .windows and builtin.link_mode == .dynamic) {
        @export(&DllMain, .{ .name = "DllMain" });
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_cwriter_create and default writer operations" {
    var w: ?*CurlCwriter = null;
    const rc = Curl_cwriter_create(&w, null, &cw_raw, CURL_CW_RAW);
    try std.testing.expectEqual(CURLE_OK, rc);
    try std.testing.expect(w != null);
    defer Curl_cwriter_free(null, w);

    try std.testing.expectEqual(CURL_CW_RAW, w.?.phase);
    try std.testing.expectEqual(@as(?*CurlCwriter, null), w.?.next);
    try std.testing.expectEqual(CURLE_WRITE_ERROR, Curl_cwriter_def_write(null, w.?, CLIENTWRITE_BODY, "abc", 3));
    try std.testing.expectEqual(CURLE_WRITE_ERROR, Curl_cwriter_def_flush(null, w.?));
}

test "Curl_creader_create with cr_null and cr_buf" {
    var r_null: ?*CurlCreader = null;
    try std.testing.expectEqual(CURLE_OK, Curl_creader_create(&r_null, null, &cr_null, CURL_CR_CLIENT));
    try std.testing.expect(r_null != null);
    defer Curl_creader_free(null, r_null);

    try std.testing.expectEqual(@as(curl_off_t, 0), r_null.?.crt.total_length(null, r_null.?));
    var nread: usize = 99;
    var eos: bool = false;
    var out_buf: [16]u8 = undefined;
    try std.testing.expectEqual(CURLE_OK, Curl_creader_read(null, r_null, &out_buf, out_buf.len, &nread, &eos));
    try std.testing.expectEqual(@as(usize, 0), nread);
    try std.testing.expect(eos);

    var r_buf: ?*CurlCreader = null;
    try std.testing.expectEqual(CURLE_OK, Curl_creader_create(&r_buf, null, &cr_buf, CURL_CR_CLIENT));
    try std.testing.expect(r_buf != null);
    defer Curl_creader_free(null, r_buf);

    const payload = "hello world";
    const ctx: *CrBufCtx = @ptrCast(@alignCast(r_buf.?.ctx));
    ctx.buf = payload.ptr;
    ctx.blen = payload.len;
    ctx.index = 0;

    try std.testing.expectEqual(@as(curl_off_t, 11), r_buf.?.crt.total_length(null, r_buf.?));
    try std.testing.expect(!r_buf.?.crt.needs_rewind(null, r_buf.?));

    try std.testing.expectEqual(CURLE_OK, Curl_creader_read(null, r_buf, &out_buf, 5, &nread, &eos));
    try std.testing.expectEqual(@as(usize, 5), nread);
    try std.testing.expect(!eos);
    try std.testing.expectEqualStrings("hello", out_buf[0..nread]);
    try std.testing.expect(r_buf.?.crt.needs_rewind(null, r_buf.?));

    try std.testing.expectEqual(CURLE_OK, r_buf.?.crt.cntrl(null, r_buf.?, CURL_CRCNTRL_REWIND));
    try std.testing.expect(!r_buf.?.crt.needs_rewind(null, r_buf.?));

    try std.testing.expectEqual(CURLE_OK, Curl_creader_read(null, r_buf, &out_buf, out_buf.len, &nread, &eos));
    try std.testing.expectEqual(@as(usize, 11), nread);
    try std.testing.expect(eos);
    try std.testing.expectEqualStrings("hello world", out_buf[0..nread]);
}

test "cr_lc line ending conversion" {
    var r_buf: ?*CurlCreader = null;
    try std.testing.expectEqual(CURLE_OK, Curl_creader_create(&r_buf, null, &cr_buf, CURL_CR_CLIENT));
    defer Curl_creader_free(null, r_buf);

    const payload = "a\nb\r\nc\n";
    const buf_ctx: *CrBufCtx = @ptrCast(@alignCast(r_buf.?.ctx));
    buf_ctx.buf = payload.ptr;
    buf_ctx.blen = payload.len;
    buf_ctx.index = 0;

    var r_lc: ?*CurlCreader = null;
    try std.testing.expectEqual(CURLE_OK, Curl_creader_create(&r_lc, null, &cr_lc, CURL_CR_CONTENT_ENCODE));
    defer Curl_creader_free(null, r_lc);
    r_lc.?.next = r_buf;

    var out: [32]u8 = undefined;
    var nread: usize = 0;
    var eos: bool = false;
    try std.testing.expectEqual(CURLE_OK, Curl_creader_read(null, r_lc, &out, out.len, &nread, &eos));
    try std.testing.expect(eos);
    try std.testing.expectEqualStrings("a\r\nb\r\nc\r\n", out[0..nread]);
}

test "dllMainImpl lifecycle callbacks" {
    const State = struct {
        var count: usize = 0;
        fn onThreadStop() callconv(.c) void {
            count += 1;
        }
    };
    State.count = 0;
    try std.testing.expectEqual(@as(c_int, 1), dllMainImpl(null, DLL_PROCESS_ATTACH, null, State.onThreadStop));
    try std.testing.expectEqual(@as(usize, 0), State.count);
    try std.testing.expectEqual(@as(c_int, 1), dllMainImpl(null, DLL_THREAD_ATTACH, null, State.onThreadStop));
    try std.testing.expectEqual(@as(usize, 0), State.count);
    try std.testing.expectEqual(@as(c_int, 1), dllMainImpl(null, DLL_THREAD_DETACH, null, State.onThreadStop));
    try std.testing.expectEqual(@as(usize, 1), State.count);
    try std.testing.expectEqual(@as(c_int, 1), dllMainImpl(null, DLL_PROCESS_DETACH, null, State.onThreadStop));
    try std.testing.expectEqual(@as(usize, 1), State.count);
}
