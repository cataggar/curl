const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const headers_sock = @import("headers_sock.zig");

const CURLcode = c_uint;
const CURLE_OK: CURLcode = 0;
const CURLE_FAILED_INIT: CURLcode = 2;
const CURLE_WRITE_ERROR: CURLcode = 23;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
const CURLE_UNKNOWN_OPTION: CURLcode = 48;
const CURLE_SEND_ERROR: CURLcode = 55;
const CURLE_RECV_ERROR: CURLcode = 56;
const CURLE_FILESIZE_EXCEEDED: CURLcode = 63;
const CURLE_AGAIN: CURLcode = 81;
const CURLE_NO_CONNECTION_AVAILABLE: CURLcode = 89;
const CURLE_TOO_LARGE: CURLcode = 100;

const curl_socket_t = headers_sock.curl_socket_t;
const CURL_SOCKET_BAD = headers_sock.CURL_SOCKET_BAD;

pub const CurlEasy = opaque {};
pub const ConnectData = opaque {};
pub const CurlMulti = opaque {};
pub const CurlShare = opaque {};
pub const Bufq = opaque {};
pub const Cshutdn = opaque {};
pub const EasyPollset = headers_sock.EasyPollset;

pub const CurlTime = extern struct {
    tv_sec: i64,
    tv_usec: c_int,
};

pub const CurlRlimit = extern struct {
    rate_per_sec: i64,
    burst_per_sec: i64,
    rate_per_step: i64,
    burst_per_step: i64,
    step_us: i64,
    tokens: i64,
    spare_us: i64,
    ts: CurlTime,
    flags: u8,
};

pub const DynBuf = extern struct {
    bufr: ?[*]u8,
    leng: usize,
    allc: usize,
    toobig: usize,
};

pub const CurlHashDtor = ?*const fn (?*anyopaque) callconv(.c) void;

pub const CurlHash = extern struct {
    table: ?*?*anyopaque,
    dtor: CurlHashDtor,
    slots: usize,
    size: usize,
    type: u8,
};

pub const Uint32Tbl = extern struct {
    rows: ?*?*anyopaque,
    nrows: u32,
    nentries: u32,
    last_key_added: u32,
};

pub const Uint32Bset = extern struct {
    slots: ?[*]u64,
    nslots: u32,
    first_slot_used: u32,
};

pub const Uint32SpbsetChunk = extern struct {
    next: ?*Uint32SpbsetChunk,
    slots: [4]u64,
    offset: u32,
};

pub const Uint32Spbset = extern struct {
    head: Uint32SpbsetChunk,
};

pub const CurlMapiGuard = extern struct {
    multi: ?*CurlMulti,
    depth: u8,
};

const CURL_CBAPI_FN_easy_cw_out_cb: c_uint = 133;
const CURL_CBAPI_FN_easy_fprogress: c_uint = 138;
const CURL_CBAPI_FN_easy_fxferinfo: c_uint = 143;

extern fn Curl_cbapi_enter(
    guard: *CurlMapiGuard,
    easy: ?*CurlEasy,
    multi: ?*CurlMulti,
    cb_fn: c_uint,
) callconv(.c) void;
extern fn Curl_cbapi_leave(guard: *CurlMapiGuard) callconv(.c) void;
extern fn Curl_failf(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_is_verbose_fn(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_trc_ft_is_verbose_fn(data: ?*CurlEasy, ft: *const anyopaque) callconv(.c) bool;
const Curl_trc_is_verbose = Curl_trc_is_verbose_fn;
const Curl_trc_ft_is_verbose = Curl_trc_ft_is_verbose_fn;
extern fn Curl_trc_cf_infof(data: ?*CurlEasy, cf: ?*CurlCfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_multi(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_write(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern const Curl_trc_feat_write: u8;

extern fn curl_msnprintf(buffer: [*c]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_mfprintf(fd: ?*anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn fflush(stream: ?*anyopaque) callconv(.c) c_int;
extern fn curlx_strcopy(dest: [*c]u8, dsize: usize, src: [*:0]const u8, slen: usize) callconv(.c) void;

extern fn curlx_pnow(pnow: *CurlTime) callconv(.c) void;
extern fn curlx_ptimediff_ms(newer: *const CurlTime, older: *const CurlTime) callconv(.c) i64;
extern fn curlx_ptimediff_us(newer: *const CurlTime, older: *const CurlTime) callconv(.c) i64;

// ============================================================================
// 1. progress.c
// ============================================================================

const CURL_SPEED_RECORDS: usize = 6;
const EXPIRE_SPEEDCHECK: c_uint = 3;
const CURL_PROGRESSFUNC_CONTINUE: c_int = 0x10000001;

pub const PgrsDir = extern struct {
    total_size: i64,
    cur_size: i64,
    speed: i64,
    rlimit: CurlRlimit,
};

pub const PgrsDelta = extern struct {
    startop_us: i64,
    startsingle_us: i64,
    startqueue_us: i64,
    startredirect_us: i64,
    lastshow_us: i64,
};

pub const PgrsTotal = extern struct {
    spent_us: i64,
    queued_us: i64,
    nslookup_us: i64,
    connect_us: i64,
    appconnect_us: i64,
    pretransfer_us: i64,
    starttransfer_us: i64,
    posttransfer_us: i64,
};

pub const Progress = extern struct {
    now: CurlTime,
    start: CurlTime,
    ul: PgrsDir,
    dl: PgrsDir,
    deliver: i64,
    current_speed: i64,
    earlydata_sent: i64,
    delta: PgrsDelta,
    total: PgrsTotal,
    speed_amount: [CURL_SPEED_RECORDS]i64,
    speed_time: [CURL_SPEED_RECORDS]i64,
    speeder_c: u32,
    flags: u8,

    // bit 0: hide
    // bit 1: ul_size_known
    // bit 2: dl_size_known
    // bit 3: headers_out
    // bit 4: callback
    // bit 5: startransfer_added
    pub fn isHide(self: *const Progress) bool {
        return (self.flags & (1 << 0)) != 0;
    }
    pub fn setHide(self: *Progress, v: bool) void {
        if (v) self.flags |= (1 << 0) else self.flags &= ~@as(u8, 1 << 0);
    }
    pub fn isUlSizeKnown(self: *const Progress) bool {
        return (self.flags & (1 << 1)) != 0;
    }
    pub fn setUlSizeKnown(self: *Progress, v: bool) void {
        if (v) self.flags |= (1 << 1) else self.flags &= ~@as(u8, 1 << 1);
    }
    pub fn isDlSizeKnown(self: *const Progress) bool {
        return (self.flags & (1 << 2)) != 0;
    }
    pub fn setDlSizeKnown(self: *Progress, v: bool) void {
        if (v) self.flags |= (1 << 2) else self.flags &= ~@as(u8, 1 << 2);
    }
    pub fn isHeadersOut(self: *const Progress) bool {
        return (self.flags & (1 << 3)) != 0;
    }
    pub fn setHeadersOut(self: *Progress, v: bool) void {
        if (v) self.flags |= (1 << 3) else self.flags &= ~@as(u8, 1 << 3);
    }
    pub fn isCallback(self: *const Progress) bool {
        return (self.flags & (1 << 4)) != 0;
    }
    pub fn setCallback(self: *Progress, v: bool) void {
        if (v) self.flags |= (1 << 4) else self.flags &= ~@as(u8, 1 << 4);
    }
    pub fn isStartransferAdded(self: *const Progress) bool {
        return (self.flags & (1 << 5)) != 0;
    }
    pub fn setStartransferAdded(self: *Progress, v: bool) void {
        if (v) self.flags |= (1 << 5) else self.flags &= ~@as(u8, 1 << 5);
    }
};

pub const CurlXferInfoCallback = ?*const fn (
    ?*anyopaque,
    i64,
    i64,
    i64,
    i64,
) callconv(.c) c_int;

pub const CurlProgressCallback = ?*const fn (
    ?*anyopaque,
    f64,
    f64,
    f64,
    f64,
) callconv(.c) c_int;

extern fn Curl_xfer_recv_is_paused(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_send_is_paused(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_expire_set(data: ?*CurlEasy, id: c_uint, ms: i64, pnow: *const CurlTime) callconv(.c) void;
extern fn Curl_rlimit_drain(r: *CurlRlimit, tokens: usize, pnow: ?*const CurlTime) callconv(.c) void;

pub export fn time2str(r: [*c]u8, rsize: usize, seconds: i64) callconv(.c) void {
    if (seconds <= 0) {
        curlx_strcopy(r, rsize, "       ", 7);
        return;
    }
    var h: i64 = @divTrunc(seconds, 3600);
    if (h <= 99) {
        const m: i64 = @divTrunc(seconds - (h * 3600), 60);
        if (h <= 9) {
            const s: i64 = (seconds - (h * 3600)) - (m * 60);
            if (h != 0) {
                _ = curl_msnprintf(r, rsize, "%lld:%02lld:%02lld", @as(c_longlong, h), @as(c_longlong, m), @as(c_longlong, s));
            } else {
                _ = curl_msnprintf(r, rsize, "  %02lld:%02lld", @as(c_longlong, m), @as(c_longlong, s));
            }
        } else {
            _ = curl_msnprintf(r, rsize, "%lldh %02lldm", @as(c_longlong, h), @as(c_longlong, m));
        }
    } else {
        const d: i64 = @divTrunc(seconds, 86400);
        h = @divTrunc(seconds - (d * 86400), 3600);
        if (d <= 99) {
            _ = curl_msnprintf(r, rsize, "%2lldd %02lldh", @as(c_longlong, d), @as(c_longlong, h));
        } else if (d <= 999) {
            _ = curl_msnprintf(r, rsize, "%6lldd", @as(c_longlong, d));
        } else {
            const m: i64 = @divTrunc(d, 30);
            if (m <= 999) {
                _ = curl_msnprintf(r, rsize, "%6lldm", @as(c_longlong, m));
            } else {
                const y: i64 = @divTrunc(d, 365);
                if (y <= 99999) {
                    _ = curl_msnprintf(r, rsize, "%6lldy", @as(c_longlong, y));
                } else {
                    curlx_strcopy(r, rsize, ">99999y", 7);
                }
            }
        }
    }
}

pub export fn max6out(bytes_arg: i64, max6: [*c]u8, mlen: usize) callconv(.c) [*c]u8 {
    var bytes = bytes_arg;
    if (bytes < 100000) {
        _ = curl_msnprintf(max6, mlen, "%6lld", @as(c_longlong, bytes));
    } else {
        const unit = [_]u8{ 'k', 'M', 'G', 'T', 'P', 'E', 0 };
        var k: usize = 0;
        var nbytes: i64 = 0;
        while (true) {
            nbytes = @divTrunc(bytes, 1024);
            if (nbytes < 1000)
                break;
            bytes = nbytes;
            k += 1;
            std.debug.assert(unit[k] != 0);
            if (unit[k] == 0)
                break;
        }
        const rest: i64 = @rem(bytes, 1024);
        if (nbytes <= 99) {
            _ = curl_msnprintf(
                max6,
                mlen,
                "%2lld.%02lld%c",
                @as(c_longlong, nbytes),
                @as(c_longlong, @divTrunc(rest * 100, 1024)),
                @as(c_int, unit[k]),
            );
        } else {
            _ = curl_msnprintf(
                max6,
                mlen,
                "%3lld.%lld%c",
                @as(c_longlong, nbytes),
                @as(c_longlong, @divTrunc(rest * 10, 1024)),
                @as(c_int, unit[k]),
            );
        }
    }
    return max6;
}

fn pgrsSpeedinit(keeps_speed: *CurlTime) void {
    keeps_speed.* = .{ .tv_sec = 0, .tv_usec = 0 };
}

pub export fn pgrs_speedcheck_zig(
    data: ?*CurlEasy,
    pnow: *const CurlTime,
    p: *Progress,
    low_speed_time: u32,
    low_speed_limit: i64,
    keeps_speed: *CurlTime,
) callconv(.c) CURLcode {
    if (low_speed_time == 0 or low_speed_limit == 0 or
        Curl_xfer_recv_is_paused(data) or Curl_xfer_send_is_paused(data))
    {
        return CURLE_OK;
    }

    if (p.current_speed >= 0) {
        if (p.current_speed < low_speed_limit) {
            if (keeps_speed.tv_sec == 0) {
                keeps_speed.* = pnow.*;
            } else {
                const howlong: i64 = curlx_ptimediff_ms(pnow, keeps_speed);
                if (howlong >= @as(i64, low_speed_time) * 1000) {
                    Curl_failf(
                        data,
                        "Operation too slow. Less than %lld bytes/sec transferred the last %u seconds",
                        @as(c_longlong, low_speed_limit),
                        low_speed_time,
                    );
                    return CURLE_OPERATION_TIMEDOUT;
                }
            }
        } else {
            keeps_speed.tv_sec = 0;
        }
    }

    Curl_expire_set(data, EXPIRE_SPEEDCHECK, 1000, pnow);
    return CURLE_OK;
}

pub export fn Curl_pgrs_now_zig(
    data: ?*CurlEasy,
    p: *Progress,
) callconv(.c) *const CurlTime {
    _ = data;
    curlx_pnow(&p.now);
    return &p.now;
}

pub export fn Curl_pgrsDone_zig(
    data: ?*CurlEasy,
    pnow: *const CurlTime,
    p: *Progress,
    req_done: bool,
    resume_from: i64,
    err_file: ?*anyopaque,
    fxferinfo: CurlXferInfoCallback,
    fprogress: CurlProgressCallback,
    progress_client: ?*anyopaque,
) callconv(.c) c_int {
    p.delta.lastshow_us = -1;
    const rc = Curl_pgrsUpdateX_zig(
        data,
        pnow,
        p,
        req_done,
        resume_from,
        err_file,
        fxferinfo,
        fprogress,
        progress_client,
    );
    if (rc != CURLE_OK)
        return @intCast(rc);

    if (!p.isHide() and !p.isCallback()) {
        _ = curl_mfprintf(err_file, "\n");
    }
    return 0;
}

pub export fn Curl_pgrsReset_zig(
    data: ?*CurlEasy,
    p: *Progress,
    keeps_speed: *CurlTime,
) callconv(.c) void {
    Curl_pgrsSetUploadCounter_zig(data, 0, p);
    p.dl.cur_size = 0;
    Curl_pgrsSetUploadSize_zig(data, -1, p);
    Curl_pgrsSetDownloadSize_zig(data, -1, p);
    p.speeder_c = 0;
    p.deliver = 0;
    pgrsSpeedinit(keeps_speed);
}

pub export fn Curl_pgrsResetTransferSizes_zig(
    data: ?*CurlEasy,
    p: *Progress,
) callconv(.c) void {
    Curl_pgrsSetDownloadSize_zig(data, -1, p);
    Curl_pgrsSetUploadSize_zig(data, -1, p);
}

pub export fn Curl_pgrsRecvPause_zig(
    data: ?*CurlEasy,
    enable: bool,
    p: *Progress,
    keeps_speed: *CurlTime,
) callconv(.c) void {
    _ = data;
    if (!enable) {
        p.speeder_c = 0;
        pgrsSpeedinit(keeps_speed);
    }
}

pub export fn Curl_pgrsSendPause_zig(
    data: ?*CurlEasy,
    enable: bool,
    p: *Progress,
    keeps_speed: *CurlTime,
) callconv(.c) void {
    _ = data;
    if (!enable) {
        p.speeder_c = 0;
        pgrsSpeedinit(keeps_speed);
    }
}

const pgrs_timer_names = [_][*:0]const u8{
    "PGRS-NONE",
    "PGRS-STARTOP",
    "PGRS-STARTSINGLE",
    "PGRS-POSTQUEUE",
    "PGRS-NAMELOOKUP",
    "PGRS-CONNECT",
    "PGRS-APPCONNECT",
    "PGRS-PRETRANSFER",
    "PGRS-STARTTRANSFER",
    "PGRS-POSTRANSFER",
    "PGRS-REDIRECT",
};

fn pgrsTimerName(timer: c_int) [*:0]const u8 {
    if (timer >= 0 and @as(usize, @intCast(timer)) < pgrs_timer_names.len)
        return pgrs_timer_names[@intCast(timer)];
    return "?";
}

pub export fn Curl_pgrsTimeWas_zig(
    data: ?*CurlEasy,
    timer: c_int,
    timestamp: CurlTime,
    p: *Progress,
) callconv(.c) void {
    var delta: ?*i64 = null;

    switch (timer) {
        0 => {}, // TIMER_NONE
        1 => { // TIMER_STARTOP
            p.delta.startop_us = curlx_ptimediff_us(&timestamp, &p.start);
            p.delta.startqueue_us = p.delta.startop_us;
        },
        2 => { // TIMER_STARTSINGLE
            p.delta.startsingle_us = curlx_ptimediff_us(&timestamp, &p.start);
            p.setStartransferAdded(false);
        },
        3 => { // TIMER_POSTQUEUE
            p.total.queued_us += curlx_ptimediff_us(&timestamp, &p.start) - p.delta.startqueue_us;
        },
        4 => { // TIMER_NAMELOOKUP
            delta = &p.total.nslookup_us;
        },
        5 => { // TIMER_CONNECT
            delta = &p.total.connect_us;
        },
        6 => { // TIMER_APPCONNECT
            delta = &p.total.appconnect_us;
        },
        7 => { // TIMER_PRETRANSFER
            delta = &p.total.pretransfer_us;
        },
        8 => { // TIMER_STARTTRANSFER
            if (p.isStartransferAdded()) {
                if (Curl_trc_is_verbose(data)) {
                    Curl_trc_multi(data, "[%s] ignored", pgrsTimerName(timer));
                }
                return;
            }
            p.setStartransferAdded(true);
            delta = &p.total.starttransfer_us;
        },
        9 => { // TIMER_POSTRANSFER
            delta = &p.total.posttransfer_us;
        },
        10 => { // TIMER_REDIRECT
            p.delta.startredirect_us = curlx_ptimediff_us(&timestamp, &p.start);
            p.delta.startqueue_us = p.delta.startredirect_us;
        },
        else => {},
    }
    if (delta) |d| {
        var us: i64 = curlx_ptimediff_us(&timestamp, &p.start) - p.delta.startsingle_us;
        if (us < 1)
            us = 1;
        d.* += us;
        if (Curl_trc_is_verbose(data)) {
            Curl_trc_multi(data, "[%s] added %lldus", pgrsTimerName(timer), @as(c_longlong, us));
        }
    } else {
        if (Curl_trc_is_verbose(data)) {
            Curl_trc_multi(data, "[%s] set", pgrsTimerName(timer));
        }
    }
}

pub export fn Curl_pgrsTime_zig(
    data: ?*CurlEasy,
    timer: c_int,
    p: *Progress,
) callconv(.c) void {
    const pnow = Curl_pgrs_now_zig(data, p);
    Curl_pgrsTimeWas_zig(data, timer, pnow.*, p);
}

pub export fn Curl_pgrsStart_zig(
    data: ?*CurlEasy,
    pnow_arg: ?*const CurlTime,
    p: *Progress,
) callconv(.c) void {
    const pnow: *const CurlTime = pnow_arg orelse Curl_pgrs_now_zig(data, p);
    p.speeder_c = 0;
    p.start = pnow.*;
    p.delta = std.mem.zeroes(PgrsDelta);
    p.total = std.mem.zeroes(PgrsTotal);
    p.setStartransferAdded(false);
    p.dl.cur_size = 0;
    p.ul.cur_size = 0;
    p.setDlSizeKnown(false);
    p.setUlSizeKnown(false);
}

pub export fn Curl_pgrs_deliver_check_zig(
    data: ?*CurlEasy,
    delta: usize,
    p: *const Progress,
    max_filesize: i64,
) callconv(.c) CURLcode {
    if (max_filesize != 0 and (@as(i64, @intCast(delta)) > max_filesize - p.deliver)) {
        Curl_failf(data, "Would have exceeded max file size");
        return CURLE_FILESIZE_EXCEEDED;
    }
    return CURLE_OK;
}

pub export fn Curl_pgrs_deliver_inc_zig(
    data: ?*CurlEasy,
    delta: usize,
    p: *Progress,
) callconv(.c) void {
    _ = data;
    p.deliver += @intCast(delta);
}

pub export fn Curl_pgrs_download_inc_zig(
    data: ?*CurlEasy,
    delta: usize,
    p: *Progress,
) callconv(.c) void {
    _ = data;
    if (delta != 0) {
        p.dl.cur_size += @intCast(delta);
        Curl_rlimit_drain(&p.dl.rlimit, delta, null);
    }
}

pub export fn Curl_pgrs_upload_inc_zig(
    data: ?*CurlEasy,
    delta: usize,
    p: *Progress,
) callconv(.c) void {
    _ = data;
    if (delta != 0) {
        p.ul.cur_size += @intCast(delta);
        Curl_rlimit_drain(&p.ul.rlimit, delta, null);
    }
}

pub export fn Curl_pgrsSetUploadCounter_zig(
    data: ?*CurlEasy,
    size: i64,
    p: *Progress,
) callconv(.c) void {
    _ = data;
    p.ul.cur_size = size;
}

pub export fn Curl_pgrsSetDownloadSize_zig(
    data: ?*CurlEasy,
    size: i64,
    p: *Progress,
) callconv(.c) void {
    _ = data;
    if (size >= 0) {
        p.dl.total_size = size;
        p.setDlSizeKnown(true);
    } else {
        p.dl.total_size = 0;
        p.setDlSizeKnown(false);
    }
}

pub export fn Curl_pgrsSetUploadSize_zig(
    data: ?*CurlEasy,
    size: i64,
    p: *Progress,
) callconv(.c) void {
    _ = data;
    if (size >= 0) {
        p.ul.total_size = size;
        p.setUlSizeKnown(true);
    } else {
        p.ul.total_size = 0;
        p.setUlSizeKnown(false);
    }
}

pub export fn Curl_pgrsEarlyData_zig(
    data: ?*CurlEasy,
    sent: i64,
    p: *Progress,
) callconv(.c) void {
    _ = data;
    p.earlydata_sent = sent;
}

fn trspeed(size: i64, us: i64) i64 {
    if (us < 1)
        return size * 1000000;
    if (size < std.math.maxInt(i64) / 1000000)
        return @divTrunc(size * 1000000, us);
    if (us >= 1000000)
        return @divTrunc(size, @divTrunc(us, 1000000));
    return std.math.maxInt(i64);
}

fn progressCalc(p: *Progress, req_done: bool, pnow: *const CurlTime) bool {
    const elapsed_us: i64 = curlx_ptimediff_us(pnow, &p.start);
    p.total.spent_us = elapsed_us;
    p.dl.speed = trspeed(p.dl.cur_size, p.total.spent_us);
    p.ul.speed = trspeed(p.ul.cur_size, p.total.spent_us);

    if (p.speeder_c == 0) {
        p.speed_amount[0] = p.dl.cur_size + p.ul.cur_size;
        p.speed_time[0] = elapsed_us;
        p.speeder_c += 1;
        p.current_speed = p.ul.speed + p.dl.speed;
        p.delta.lastshow_us = elapsed_us;
        return true;
    }

    const i_next: usize = p.speeder_c % CURL_SPEED_RECORDS;
    var i_latest: usize = if (i_next > 0) (i_next - 1) else (CURL_SPEED_RECORDS - 1);

    if ((elapsed_us - p.speed_time[i_latest]) >= (1000 * 1000)) {
        p.speeder_c += 1;
        i_latest = i_next;
        p.speed_amount[i_latest] = p.dl.cur_size + p.ul.cur_size;
        p.speed_time[i_latest] = elapsed_us;
    } else if (req_done) {
        if (p.current_speed == 0) {
            p.speed_amount[i_latest] = p.dl.cur_size + p.ul.cur_size;
            p.speed_time[i_latest] = elapsed_us;
        }
    } else {
        return false;
    }

    const i_oldest: usize = if (p.speeder_c < CURL_SPEED_RECORDS)
        0
    else
        ((i_latest + 1) % CURL_SPEED_RECORDS);

    const amount: i64 = p.speed_amount[i_latest] - p.speed_amount[i_oldest];
    var duration_us: i64 = p.speed_time[i_latest] - p.speed_time[i_oldest];
    if (duration_us <= 0)
        duration_us = 1;

    if (amount > (std.math.maxInt(i64) / 1000000)) {
        p.current_speed = @as(i64, @intFromFloat((@as(f64, @floatFromInt(amount)) * 1000000.0) / @as(f64, @floatFromInt(duration_us))));
    } else {
        p.current_speed = @divTrunc(amount * 1000000, duration_us);
    }

    if ((p.delta.lastshow_us >= 0) and !req_done and
        ((elapsed_us - p.delta.lastshow_us) < (1000 * 1000)))
    {
        return false;
    }
    p.delta.lastshow_us = elapsed_us;
    return true;
}

const PgrsEstimate = struct {
    secs: i64 = 0,
    percent: i64 = 0,
};

fn pgrsEstPercent(total: i64, cur: i64) i64 {
    if (total > 10000)
        return @divTrunc(cur, @divTrunc(total, 100));
    if (total > 0)
        return @divTrunc(cur * 100, total);
    return 0;
}

fn pgrsEstimates(d: *const PgrsDir, total_known: bool, est: *PgrsEstimate) void {
    est.secs = 0;
    est.percent = 0;
    if (total_known and (d.speed > 0)) {
        est.secs = @divTrunc(d.total_size, d.speed);
        est.percent = pgrsEstPercent(d.total_size, d.cur_size);
    }
}

fn progressMeter(
    p: *Progress,
    resume_from: i64,
    err_file: ?*anyopaque,
) void {
    var max6: [6][7]u8 = undefined;
    var dl_estm: PgrsEstimate = .{};
    var ul_estm: PgrsEstimate = .{};
    var total_estm: PgrsEstimate = .{};
    var time_left: [8]u8 = undefined;
    var time_total: [8]u8 = undefined;
    var time_spent: [8]u8 = undefined;
    const cur_secs: i64 = @divTrunc(p.total.spent_us, 1000000);

    if (!p.isHeadersOut()) {
        if (resume_from != 0) {
            _ = curl_mfprintf(
                err_file,
                "** Resuming transfer from byte position %lld\n",
                @as(c_longlong, resume_from),
            );
        }
        _ = curl_mfprintf(
            err_file,
            "  %% Total    %% Received %% Xferd  Average Speed  Time    Time    Time   Current\n                                 Dload  Upload  Total   Spent   Left   Speed\n",
        );
        p.setHeadersOut(true);
    }

    pgrsEstimates(&p.ul, p.isUlSizeKnown(), &ul_estm);
    pgrsEstimates(&p.dl, p.isDlSizeKnown(), &dl_estm);

    total_estm.secs = @max(ul_estm.secs, dl_estm.secs);
    time2str(&time_left, time_left.len, if (total_estm.secs > 0) (total_estm.secs - cur_secs) else 0);
    time2str(&time_total, time_total.len, total_estm.secs);
    time2str(&time_spent, time_spent.len, cur_secs);

    var total_expected_size: i64 = if (p.isUlSizeKnown()) p.ul.total_size else p.ul.cur_size;
    const dl_size: i64 = if (p.isDlSizeKnown()) p.dl.total_size else p.dl.cur_size;

    if ((std.math.maxInt(i64) - total_expected_size) < dl_size) {
        total_expected_size = std.math.maxInt(i64);
    } else {
        total_expected_size += dl_size;
    }

    const total_cur_size: i64 = p.dl.cur_size + p.ul.cur_size;
    total_estm.percent = pgrsEstPercent(total_expected_size, total_cur_size);

    _ = curl_mfprintf(
        err_file,
        "\r%3lld %s %3lld %s %3lld %s %s %s %s %s %s %s",
        @as(c_longlong, total_estm.percent),
        max6out(total_expected_size, &max6[2], max6[2].len),
        @as(c_longlong, dl_estm.percent),
        max6out(p.dl.cur_size, &max6[0], max6[0].len),
        @as(c_longlong, ul_estm.percent),
        max6out(p.ul.cur_size, &max6[1], max6[1].len),
        max6out(p.dl.speed, &max6[3], max6[3].len),
        max6out(p.ul.speed, &max6[4], max6[4].len),
        &time_total,
        &time_spent,
        &time_left,
        max6out(p.current_speed, &max6[5], max6[5].len),
    );

    _ = fflush(err_file);
}

fn pgrsupdate(
    data: ?*CurlEasy,
    p: *Progress,
    showprogress: bool,
    resume_from: i64,
    err_file: ?*anyopaque,
    fxferinfo: CurlXferInfoCallback,
    fprogress: CurlProgressCallback,
    progress_client: ?*anyopaque,
) CURLcode {
    if (!p.isHide()) {
        if (fxferinfo) |cb| {
            var guard: CurlMapiGuard = undefined;
            Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_fxferinfo);
            const rc = cb(
                progress_client,
                p.dl.total_size,
                p.dl.cur_size,
                p.ul.total_size,
                p.ul.cur_size,
            );
            Curl_cbapi_leave(&guard);
            if (rc != CURL_PROGRESSFUNC_CONTINUE) {
                if (rc != 0) {
                    Curl_failf(data, "Callback aborted");
                    return CURLE_ABORTED_BY_CALLBACK;
                }
                return CURLE_OK;
            }
        } else if (fprogress) |cb| {
            var guard: CurlMapiGuard = undefined;
            Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_fprogress);
            const rc = cb(
                progress_client,
                @as(f64, @floatFromInt(p.dl.total_size)),
                @as(f64, @floatFromInt(p.dl.cur_size)),
                @as(f64, @floatFromInt(p.ul.total_size)),
                @as(f64, @floatFromInt(p.ul.cur_size)),
            );
            Curl_cbapi_leave(&guard);
            if (rc != CURL_PROGRESSFUNC_CONTINUE) {
                if (rc != 0) {
                    Curl_failf(data, "Callback aborted");
                    return CURLE_ABORTED_BY_CALLBACK;
                }
                return CURLE_OK;
            }
        }

        if (showprogress)
            progressMeter(p, resume_from, err_file);
    }
    return CURLE_OK;
}

pub export fn Curl_pgrsUpdateX_zig(
    data: ?*CurlEasy,
    pnow: *const CurlTime,
    p: *Progress,
    req_done: bool,
    resume_from: i64,
    err_file: ?*anyopaque,
    fxferinfo: CurlXferInfoCallback,
    fprogress: CurlProgressCallback,
    progress_client: ?*anyopaque,
) callconv(.c) CURLcode {
    const showprogress = progressCalc(p, req_done, pnow);
    return pgrsupdate(data, p, showprogress, resume_from, err_file, fxferinfo, fprogress, progress_client);
}

pub export fn Curl_pgrsUpdate_zig(
    data: ?*CurlEasy,
    p: *Progress,
    req_done: bool,
    resume_from: i64,
    err_file: ?*anyopaque,
    fxferinfo: CurlXferInfoCallback,
    fprogress: CurlProgressCallback,
    progress_client: ?*anyopaque,
) callconv(.c) CURLcode {
    const pnow = Curl_pgrs_now_zig(data, p);
    return Curl_pgrsUpdateX_zig(data, pnow, p, req_done, resume_from, err_file, fxferinfo, fprogress, progress_client);
}

pub export fn Curl_pgrsCheckX_zig(
    data: ?*CurlEasy,
    pnow: *const CurlTime,
    p: *Progress,
    req_done: bool,
    resume_from: i64,
    err_file: ?*anyopaque,
    fxferinfo: CurlXferInfoCallback,
    fprogress: CurlProgressCallback,
    progress_client: ?*anyopaque,
    low_speed_time: u32,
    low_speed_limit: i64,
    keeps_speed: *CurlTime,
) callconv(.c) CURLcode {
    var result = Curl_pgrsUpdateX_zig(
        data,
        pnow,
        p,
        req_done,
        resume_from,
        err_file,
        fxferinfo,
        fprogress,
        progress_client,
    );
    if (result == CURLE_OK and !req_done)
        result = pgrs_speedcheck_zig(data, pnow, p, low_speed_time, low_speed_limit, keeps_speed);
    return result;
}

pub export fn Curl_pgrsCheck_zig(
    data: ?*CurlEasy,
    p: *Progress,
    req_done: bool,
    resume_from: i64,
    err_file: ?*anyopaque,
    fxferinfo: CurlXferInfoCallback,
    fprogress: CurlProgressCallback,
    progress_client: ?*anyopaque,
    low_speed_time: u32,
    low_speed_limit: i64,
    keeps_speed: *CurlTime,
) callconv(.c) CURLcode {
    const pnow = Curl_pgrs_now_zig(data, p);
    return Curl_pgrsCheckX_zig(
        data,
        pnow,
        p,
        req_done,
        resume_from,
        err_file,
        fxferinfo,
        fprogress,
        progress_client,
        low_speed_time,
        low_speed_limit,
        keeps_speed,
    );
}

pub export fn Curl_pgrsUpdate_nometer_zig(
    data: ?*CurlEasy,
    p: *Progress,
    req_done: bool,
) callconv(.c) void {
    const pnow = Curl_pgrs_now_zig(data, p);
    _ = progressCalc(p, req_done, pnow);
}

pub export fn Curl_pgrsCompleted_zig(
    data: ?*CurlEasy,
    p: *Progress,
) callconv(.c) void {
    const pnow = Curl_pgrs_now_zig(data, p);
    p.total.spent_us = curlx_ptimediff_us(pnow, &p.start);
}

pub export fn Curl_pgrs_since_ms_zig(
    data: ?*CurlEasy,
    pnow_arg: ?*const CurlTime,
    timer: c_int,
    p: *Progress,
) callconv(.c) i64 {
    const pnow = pnow_arg orelse Curl_pgrs_now_zig(data, p);
    return switch (timer) {
        1 => @divTrunc(curlx_ptimediff_us(pnow, &p.start) - p.delta.startop_us, 1000), // TIMER_STARTOP
        2 => @divTrunc(curlx_ptimediff_us(pnow, &p.start) - p.delta.startsingle_us, 1000), // TIMER_STARTSINGLE
        else => 0,
    };
}

// ============================================================================
// 2. cw-out.c
// ============================================================================

const CLIENTWRITE_BODY: c_int = 1 << 0;
const CLIENTWRITE_INFO: c_int = 1 << 1;
const CLIENTWRITE_HEADER: c_int = 1 << 2;
const CLIENTWRITE_EOS: c_int = 1 << 7;
const CLIENTWRITE_0LEN: c_int = 1 << 8;

const CURL_WRITEFUNC_PAUSE: usize = 0x10000001;
const CURL_WRITEFUNC_ERROR: usize = 0xFFFFFFFF;
const DYN_PAUSE_BUFFER: usize = 64 * 1024 * 1024;

pub const CurlWriteCallback = ?*const fn (
    [*]const u8,
    usize,
    usize,
    ?*anyopaque,
) callconv(.c) usize;

pub const CurlCwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: ?*const fn (?*CurlEasy, *CurlCwriter) callconv(.c) CURLcode,
    do_write: ?*const fn (?*CurlEasy, *CurlCwriter, c_int, [*]const u8, usize) callconv(.c) CURLcode,
    do_flush: ?*const fn (?*CurlEasy, *CurlCwriter) callconv(.c) CURLcode,
    do_close: ?*const fn (?*CurlEasy, *CurlCwriter) callconv(.c) void,
    cwriter_size: usize,
};

pub const CurlCwriter = extern struct {
    cwt: *const CurlCwtype,
    next: ?*CurlCwriter,
    ctx: ?*anyopaque,
    phase: c_uint,
};

const CwOutType = enum(c_int) {
    CW_OUT_NONE = 0,
    CW_OUT_BODY = 1,
    CW_OUT_BODY_0LEN = 2,
    CW_OUT_HDS = 3,
};

const CwOutBuf = extern struct {
    next: ?*CwOutBuf,
    b: DynBuf,
    otype: CwOutType,
};

const CwOutCtx = extern struct {
    super: CurlCwriter,
    buf: ?*CwOutBuf,
    tail: ?*CwOutBuf,
    buffered_len: usize,
    flags: u8,

    fn isErrored(self: *const CwOutCtx) bool {
        return (self.flags & (1 << 0)) != 0;
    }
    fn setErrored(self: *CwOutCtx, v: bool) void {
        if (v) self.flags |= (1 << 0) else self.flags &= ~@as(u8, 1 << 0);
    }
};

extern fn curlx_dyn_init(s: *DynBuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *DynBuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *DynBuf, mem: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const DynBuf) callconv(.c) ?[*]u8;
extern fn curlx_dyn_len(s: *const DynBuf) callconv(.c) usize;
extern fn curlx_dyn_tail(s: *DynBuf, length: usize) callconv(.c) CURLcode;

extern fn Curl_cwriter_get_by_type(data: ?*CurlEasy, cwt: *const CurlCwtype) callconv(.c) ?*CurlCwriter;
extern fn Curl_client_flush(data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_xfer_pause_recv(data: ?*CurlEasy, enable: bool) callconv(.c) CURLcode;

extern fn Curl_cw_out_get_writefunc(
    data: ?*CurlEasy,
    otype: c_int,
    pwcb: *CurlWriteCallback,
    pwcb_data: *?*anyopaque,
    pmax_write: *usize,
    pmin_write: *usize,
) callconv(.c) void;
extern fn Curl_cw_out_is_paused(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_cw_out_set_paused(data: ?*CurlEasy, paused: bool) callconv(.c) void;
extern fn Curl_cw_out_is_nonetwork(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_cw_out_include_header(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_easy_progress(data: ?*CurlEasy) callconv(.c) *Progress;
extern fn Curl_easy_max_filesize(data: ?*CurlEasy) callconv(.c) i64;

pub export const Curl_cwt_out: CurlCwtype = .{
    .name = "cw-out",
    .alias = null,
    .flags = 0,
    .do_init = cwOutInit,
    .do_write = cwOutWrite,
    .do_flush = cwOutFlush,
    .do_close = cwOutClose,
    .cwriter_size = @sizeOf(CwOutCtx),
};

fn cwOutBufCreate(otype: CwOutType) ?*CwOutBuf {
    const raw = mem.calloc(1, @sizeOf(CwOutBuf)) orelse return null;
    const cwbuf: *CwOutBuf = @ptrCast(@alignCast(raw));
    cwbuf.otype = otype;
    curlx_dyn_init(&cwbuf.b, DYN_PAUSE_BUFFER);
    return cwbuf;
}

fn cwOutBufFree(cwbuf: ?*CwOutBuf) void {
    if (cwbuf) |b| {
        curlx_dyn_free(&b.b);
        mem.free(@ptrCast(b));
    }
}

fn cwOutInit(data: ?*CurlEasy, writer: *CurlCwriter) callconv(.c) CURLcode {
    _ = data;
    const ctx: *CwOutCtx = @ptrCast(@alignCast(writer.ctx));
    ctx.buf = null;
    ctx.tail = null;
    ctx.buffered_len = 0;
    return CURLE_OK;
}

fn cwOutBufsFree(ctx: *CwOutCtx) void {
    while (ctx.buf) |head| {
        const next = head.next;
        cwOutBufFree(head);
        ctx.buf = next;
    }
    ctx.tail = null;
    ctx.buffered_len = 0;
}

fn cwOutClose(data: ?*CurlEasy, writer: *CurlCwriter) callconv(.c) void {
    _ = data;
    const ctx: *CwOutCtx = @ptrCast(@alignCast(writer.ctx));
    cwOutBufsFree(ctx);
}

fn cwOutCbWrite(
    data: ?*CurlEasy,
    wcb: CurlWriteCallback,
    wcb_data: ?*anyopaque,
    otype: CwOutType,
    buf: [*]const u8,
    blen: usize,
    pnwritten: *usize,
) CURLcode {
    pnwritten.* = 0;
    var guard: CurlMapiGuard = undefined;
    Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_cw_out_cb);
    const nwritten = wcb.?(buf, 1, blen, wcb_data);
    Curl_cbapi_leave(&guard);

    if (Curl_trc_is_verbose(data) and Curl_trc_ft_is_verbose(data, &Curl_trc_feat_write)) {
        const kind: [*:0]const u8 = if (otype == .CW_OUT_HDS) "header" else "body";
        Curl_trc_write(
            data,
            "[OUT] wrote %zu %s bytes, type=%x -> %zu",
            blen,
            kind,
            @as(c_uint, @intCast(@backingInt(otype))),
            nwritten,
        );
    }

    if (nwritten == CURL_WRITEFUNC_PAUSE) {
        if (Curl_cw_out_is_nonetwork(data)) {
            Curl_failf(data, "Write callback asked for PAUSE when not supported");
            return CURLE_WRITE_ERROR;
        }
        Curl_cw_out_set_paused(data, true);
        if (Curl_trc_is_verbose(data) and Curl_trc_ft_is_verbose(data, &Curl_trc_feat_write)) {
            Curl_trc_write(data, "[OUT] PAUSE requested by client");
        }
        const result = Curl_xfer_pause_recv(data, true);
        return if (result != CURLE_OK) result else CURLE_AGAIN;
    } else if (nwritten == CURL_WRITEFUNC_ERROR) {
        Curl_failf(data, "client returned ERROR on write of %zu bytes", blen);
        return CURLE_WRITE_ERROR;
    } else if (nwritten != blen) {
        Curl_failf(
            data,
            "Failure writing output to destination, passed %zu returned %zu",
            blen,
            nwritten,
        );
        return CURLE_WRITE_ERROR;
    }
    pnwritten.* = nwritten;
    return CURLE_OK;
}

fn cwOutPtrFlush(
    ctx: *CwOutCtx,
    data: ?*CurlEasy,
    otype: CwOutType,
    flush_all: bool,
    buf_arg: [*]const u8,
    blen_arg: usize,
    pconsumed: *usize,
) CURLcode {
    var wcb: CurlWriteCallback = null;
    var wcb_data: ?*anyopaque = null;
    var max_write: usize = 0;
    var min_write: usize = 0;
    var nwritten: usize = 0;
    var result: CURLcode = CURLE_OK;

    if (ctx.isErrored())
        return CURLE_WRITE_ERROR;

    Curl_cw_out_get_writefunc(data, @backingInt(otype), &wcb, &wcb_data, &max_write, &min_write);
    if (wcb == null) {
        pconsumed.* = blen_arg;
        return CURLE_OK;
    }

    pconsumed.* = 0;
    if (otype == .CW_OUT_BODY_0LEN) {
        std.debug.assert(blen_arg == 0);
        return cwOutCbWrite(data, wcb, wcb_data, otype, buf_arg, blen_arg, &nwritten);
    } else {
        var blen = blen_arg;
        var buf = buf_arg;
        const p = Curl_easy_progress(data);
        while (blen != 0 and !Curl_cw_out_is_paused(data)) {
            if (!flush_all and blen < min_write)
                break;
            const wlen: usize = if (max_write != 0) @min(blen, max_write) else blen;
            if (otype == .CW_OUT_BODY) {
                result = Curl_pgrs_deliver_check_zig(data, wlen, p, Curl_easy_max_filesize(data));
            }
            if (result == CURLE_OK) {
                result = cwOutCbWrite(data, wcb, wcb_data, otype, buf, wlen, &nwritten);
            }
            if (result != CURLE_OK)
                return result;
            if (otype == .CW_OUT_BODY) {
                Curl_pgrs_deliver_inc_zig(data, nwritten, p);
            }
            pconsumed.* += nwritten;
            blen -= nwritten;
            buf += nwritten;
            Curl_cw_out_get_writefunc(data, @backingInt(otype), &wcb, &wcb_data, &max_write, &min_write);
            if (wcb == null) {
                pconsumed.* += blen;
                break;
            }
        }
    }
    return CURLE_OK;
}

fn cwOutBufFlush(
    ctx: *CwOutCtx,
    data: ?*CurlEasy,
    cwbuf: *CwOutBuf,
    flush_all: bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (curlx_dyn_len(&cwbuf.b) != 0 or cwbuf.otype == .CW_OUT_BODY_0LEN) {
        var consumed: usize = 0;
        const ptr = curlx_dyn_ptr(&cwbuf.b) orelse @as([*]const u8, "");
        result = cwOutPtrFlush(
            ctx,
            data,
            cwbuf.otype,
            flush_all,
            ptr,
            curlx_dyn_len(&cwbuf.b),
            &consumed,
        );
        if (result != CURLE_OK and result != CURLE_AGAIN)
            return result;
        result = CURLE_OK;

        if (consumed != 0) {
            if (consumed == curlx_dyn_len(&cwbuf.b)) {
                curlx_dyn_free(&cwbuf.b);
            } else {
                std.debug.assert(consumed < curlx_dyn_len(&cwbuf.b));
                result = curlx_dyn_tail(&cwbuf.b, curlx_dyn_len(&cwbuf.b) - consumed);
                if (result != CURLE_OK)
                    return result;
            }
        }
    }
    return result;
}

fn cwOutFlushChain(
    ctx: *CwOutCtx,
    data: ?*CurlEasy,
    flush_all: bool,
) CURLcode {
    while (ctx.buf) |cwbuf| {
        if (Curl_cw_out_is_paused(data))
            return CURLE_OK;

        const blen_before = curlx_dyn_len(&cwbuf.b);
        const result = cwOutBufFlush(ctx, data, cwbuf, flush_all);
        if (result != CURLE_OK)
            return result;
        ctx.buffered_len -= blen_before - curlx_dyn_len(&cwbuf.b);

        if (curlx_dyn_len(&cwbuf.b) != 0) {
            std.debug.assert(Curl_cw_out_is_paused(data));
            return CURLE_OK;
        }

        ctx.buf = cwbuf.next;
        if (ctx.buf == null)
            ctx.tail = null;
        cwOutBufFree(cwbuf);
    }
    return CURLE_OK;
}

fn cwOutAppend(
    ctx: *CwOutCtx,
    data: ?*CurlEasy,
    otype: CwOutType,
    buf: [*]const u8,
    blen: usize,
) CURLcode {
    if (Curl_trc_is_verbose(data) and Curl_trc_ft_is_verbose(data, &Curl_trc_feat_write)) {
        Curl_trc_write(
            data,
            "[OUT] paused, buffering %zu more bytes (%zu/%d)",
            blen,
            ctx.buffered_len,
            @as(c_int, DYN_PAUSE_BUFFER),
        );
    }
    if (ctx.buffered_len + blen > DYN_PAUSE_BUFFER) {
        Curl_failf(data, "pause buffer not large enough -> CURLE_TOO_LARGE");
        return CURLE_TOO_LARGE;
    }

    if (ctx.tail == null or ctx.tail.?.otype != otype or otype == .CW_OUT_HDS) {
        const cwbuf = cwOutBufCreate(otype) orelse return CURLE_OUT_OF_MEMORY;
        if (ctx.tail) |t| {
            t.next = cwbuf;
        } else {
            ctx.buf = cwbuf;
        }
        ctx.tail = cwbuf;
    }
    std.debug.assert(ctx.tail != null and ctx.tail.?.otype == otype);
    const result = curlx_dyn_addn(&ctx.tail.?.b, buf, blen);
    if (result == CURLE_OK)
        ctx.buffered_len += blen;
    return result;
}

fn cwOutDoWrite(
    ctx: *CwOutCtx,
    data: ?*CurlEasy,
    otype: CwOutType,
    flush_all: bool,
    buf: [*]const u8,
    blen: usize,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (ctx.tail != null and ctx.tail.?.otype != otype) {
        result = cwOutFlushChain(ctx, data, true);
        if (result != CURLE_OK) {
            ctx.setErrored(true);
            cwOutBufsFree(ctx);
            return result;
        }
    }

    if (ctx.buf != null) {
        result = cwOutAppend(ctx, data, otype, buf, blen);
        if (result == CURLE_OK) {
            result = cwOutFlushChain(ctx, data, flush_all);
        }
    } else {
        var consumed: usize = 0;
        result = cwOutPtrFlush(ctx, data, otype, flush_all, buf, blen, &consumed);
        if (result != CURLE_OK and result != CURLE_AGAIN) {
            ctx.setErrored(true);
            cwOutBufsFree(ctx);
            return result;
        }
        result = CURLE_OK;
        if (consumed < blen) {
            result = cwOutAppend(ctx, data, otype, buf + consumed, blen - consumed);
        }
    }

    if (result != CURLE_OK) {
        ctx.setErrored(true);
        cwOutBufsFree(ctx);
    }
    return result;
}

fn cwOutWrite(
    data: ?*CurlEasy,
    writer: *CurlCwriter,
    type_flags: c_int,
    buf: [*]const u8,
    blen: usize,
) callconv(.c) CURLcode {
    const ctx: *CwOutCtx = @ptrCast(@alignCast(writer.ctx));
    const flush_all: bool = (type_flags & CLIENTWRITE_EOS) != 0;

    if ((type_flags & CLIENTWRITE_BODY) != 0 or
        ((type_flags & CLIENTWRITE_HEADER) != 0 and Curl_cw_out_include_header(data)))
    {
        const otype: CwOutType = if (blen == 0 and (type_flags & CLIENTWRITE_0LEN) != 0)
            .CW_OUT_BODY_0LEN
        else
            .CW_OUT_BODY;
        const result = cwOutDoWrite(ctx, data, otype, flush_all, buf, blen);
        if (result != CURLE_OK)
            return result;
    }

    if ((type_flags & (CLIENTWRITE_HEADER | CLIENTWRITE_INFO)) != 0) {
        const result = cwOutDoWrite(ctx, data, .CW_OUT_HDS, flush_all, buf, blen);
        if (result != CURLE_OK)
            return result;
    }

    return CURLE_OK;
}

fn cwOutDoFlush(
    data: ?*CurlEasy,
    cw_out: *CurlCwriter,
    flush_all: bool,
) CURLcode {
    const ctx: *CwOutCtx = @ptrCast(@alignCast(cw_out));
    if (ctx.isErrored())
        return CURLE_WRITE_ERROR;

    if (!Curl_cw_out_is_paused(data) and ctx.buf != null) {
        if (Curl_trc_is_verbose(data) and Curl_trc_ft_is_verbose(data, &Curl_trc_feat_write)) {
            Curl_trc_write(data, "[OUT] flush");
        }
        const result = cwOutFlushChain(ctx, data, flush_all);
        if (result != CURLE_OK) {
            ctx.setErrored(true);
            cwOutBufsFree(ctx);
            return result;
        }
    }
    return CURLE_OK;
}

fn cwOutFlush(data: ?*CurlEasy, writer: *CurlCwriter) callconv(.c) CURLcode {
    return cwOutDoFlush(data, writer, false);
}

pub export fn Curl_cw_out_done(data: ?*CurlEasy) callconv(.c) CURLcode {
    const cw_out = Curl_cwriter_get_by_type(data, &Curl_cwt_out) orelse return CURLE_OK;
    if (Curl_trc_is_verbose(data) and Curl_trc_ft_is_verbose(data, &Curl_trc_feat_write)) {
        Curl_trc_write(data, "[OUT] done");
    }
    var result = Curl_client_flush(data);
    if (result == CURLE_OK)
        result = cwOutDoFlush(data, cw_out, true);
    return result;
}

// ============================================================================
// 3. cfilters.c
// ============================================================================

const FIRSTSOCKET: i8 = 0;
const SECONDARYSOCKET: i8 = 1;

const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
const CF_TYPE_SSL: c_int = 1 << 1;
const CF_TYPE_MULTIPLEX: c_int = 1 << 2;
const CF_TYPE_PROXY: c_int = 1 << 3;
const CF_TYPE_HTTP: c_int = 1 << 4;
const CF_TYPE_SETUP: c_int = 1 << 5;
const CF_TYPE_DNS: c_int = 1 << 6;

const CF_CTRL_DATA_SETUP: c_int = 4;
const CF_CTRL_DATA_PAUSE: c_int = 6;
const CF_CTRL_DATA_DONE: c_int = 7;
const CF_CTRL_DATA_DONE_SEND: c_int = 8;
const CF_CTRL_CONN_INFO_UPDATE: c_int = 256;
const CF_CTRL_FLUSH: c_int = 258;
const CF_CTRL_REPORT_STATS: c_int = 259;

const CF_QUERY_MAX_CONCURRENT: c_int = 1;
const CF_QUERY_SOCKET: c_int = 3;
const CF_QUERY_STREAM_ERROR: c_int = 6;
const CF_QUERY_NEED_FLUSH: c_int = 7;
const CF_QUERY_IP_INFO: c_int = 8;
const CF_QUERY_HTTP_VERSION: c_int = 9;
const CF_QUERY_REMOTE_ADDR: c_int = 10;
const CF_QUERY_HOST_PORT: c_int = 11;
const CF_QUERY_TRANSPORT: c_int = 14;
const CF_QUERY_ALPN_NEGOTIATED: c_int = 15;
const CF_QUERY_REALLY_CONNECTED: c_int = 16;

const PROTOPT_NONETWORK: c_uint = 1 << 4;

const TRNSPRT_TCP: u8 = 3;
const TRNSPRT_UNIX: u8 = 6;

const SOCK_STREAM: c_int = 1;
const SOCK_DGRAM: c_int = 2;
const IPPROTO_IP: c_int = 0;
const IPPROTO_TCP: c_int = 6;
const IPPROTO_UDP: c_int = 17;

pub const CurlCftype = extern struct {
    name: [*:0]const u8,
    flags: c_int,
    log_level: c_int,
    destroy: ?*const fn (*CurlCfilter, ?*CurlEasy) callconv(.c) void,
    do_connect: ?*const fn (*CurlCfilter, ?*CurlEasy, *bool) callconv(.c) CURLcode,
    do_shutdown: ?*const fn (*CurlCfilter, ?*CurlEasy, *bool) callconv(.c) CURLcode,
    adjust_pollset: ?*const fn (*CurlCfilter, ?*CurlEasy, *EasyPollset) callconv(.c) CURLcode,
    has_data_pending: ?*const fn (*CurlCfilter, ?*const CurlEasy) callconv(.c) bool,
    do_send: ?*const fn (*CurlCfilter, ?*CurlEasy, [*]const u8, usize, bool, *usize) callconv(.c) CURLcode,
    do_recv: ?*const fn (*CurlCfilter, ?*CurlEasy, [*]u8, usize, *usize) callconv(.c) CURLcode,
    cntrl: ?*const fn (*CurlCfilter, ?*CurlEasy, c_int, c_int, ?*anyopaque) callconv(.c) CURLcode,
    is_alive: ?*const fn (*CurlCfilter, ?*CurlEasy, *bool) callconv(.c) bool,
    keep_alive: ?*const fn (*CurlCfilter, ?*CurlEasy) callconv(.c) CURLcode,
    query: ?*const fn (*CurlCfilter, ?*CurlEasy, c_int, ?*c_int, ?*anyopaque) callconv(.c) CURLcode,
};

pub const CurlCfilter = extern struct {
    cft: *const CurlCftype,
    next: ?*CurlCfilter,
    ctx: ?*anyopaque,
    conn: ?*ConnectData,
    sockindex: i8,
    flags: u8,

    // bit 0: connected
    // bit 1: shutdown
    pub fn isConnected(self: *const CurlCfilter) bool {
        return (self.flags & (1 << 0)) != 0;
    }
    pub fn setConnected(self: *CurlCfilter, v: bool) void {
        if (v) self.flags |= (1 << 0) else self.flags &= ~@as(u8, 1 << 0);
    }
    pub fn isShutdown(self: *const CurlCfilter) bool {
        return (self.flags & (1 << 1)) != 0;
    }
    pub fn setShutdown(self: *CurlCfilter, v: bool) void {
        if (v) self.flags |= (1 << 1) else self.flags &= ~@as(u8, 1 << 1);
    }
};

pub const CurlRecvFn = ?*const fn (?*CurlEasy, i8, [*]u8, usize, *usize) callconv(.c) CURLcode;
pub const CurlSendFn = ?*const fn (?*CurlEasy, i8, *const anyopaque, usize, bool, *usize) callconv(.c) CURLcode;

const CfIoCtx = extern struct {
    data: ?*CurlEasy,
    cf: *CurlCfilter,
};

const BufqReader = *const fn (?*anyopaque, [*]u8, usize, *usize) callconv(.c) CURLcode;
const BufqWriter = *const fn (?*anyopaque, [*]const u8, usize, *usize) callconv(.c) CURLcode;

extern fn Curl_bufq_sipn(
    q: *Bufq,
    max_len: usize,
    reader: BufqReader,
    reader_ctx: ?*anyopaque,
    pnread: *usize,
) callconv(.c) CURLcode;
extern fn Curl_bufq_write_pass(
    q: *Bufq,
    buf: [*]const u8,
    len: usize,
    writer: BufqWriter,
    writer_ctx: ?*anyopaque,
    pwritten: *usize,
) callconv(.c) CURLcode;
extern fn Curl_bufq_pass(
    q: *Bufq,
    writer: BufqWriter,
    writer_ctx: ?*anyopaque,
    pwritten: *usize,
) callconv(.c) CURLcode;

extern fn Curl_easy_conn_cfilter(data: ?*CurlEasy, sockindex: i8) callconv(.c) ?*CurlCfilter;
extern fn Curl_conn_get_cfilters(conn: ?*ConnectData) callconv(.c) [*]?*CurlCfilter;

fn connSockIdxValid(x: i8) bool {
    return x >= FIRSTSOCKET and x <= SECONDARYSOCKET;
}

pub export fn Curl_cf_def_connect(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }
    if (cf.next) |next| {
        const result = next.cft.do_connect.?(next, data, done);
        if (result != CURLE_OK or !done.*)
            return result;
    }
    cf.setConnected(true);
    done.* = true;
    return CURLE_OK;
}

pub export fn Curl_cf_def_shutdown(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    _ = cf;
    _ = data;
    done.* = true;
    return CURLE_OK;
}

pub export fn Curl_cf_def_adjust_pollset(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ps: *EasyPollset,
) callconv(.c) CURLcode {
    _ = cf;
    _ = data;
    _ = ps;
    return CURLE_OK;
}

pub export fn Curl_cf_def_data_pending(
    cf: *CurlCfilter,
    data: ?*const CurlEasy,
) callconv(.c) bool {
    return if (cf.next) |next| next.cft.has_data_pending.?(next, data) else false;
}

pub export fn Curl_cf_def_send(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    if (cf.next) |next|
        return next.cft.do_send.?(next, data, buf, len, eos, pnwritten);
    pnwritten.* = 0;
    return CURLE_RECV_ERROR;
}

pub export fn Curl_cf_def_recv(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    if (cf.next) |next|
        return next.cft.do_recv.?(next, data, buf, len, pnread);
    pnread.* = 0;
    return CURLE_SEND_ERROR;
}

pub export fn Curl_cf_def_conn_is_alive(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    input_pending: *bool,
) callconv(.c) bool {
    return if (cf.next) |next|
        next.cft.is_alive.?(next, data, input_pending)
    else
        false;
}

pub export fn Curl_cf_def_conn_keep_alive(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) CURLcode {
    return if (cf.next) |next|
        next.cft.keep_alive.?(next, data)
    else
        CURLE_OK;
}

pub export fn Curl_cf_def_query(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    return if (cf.next) |next|
        next.cft.query.?(next, data, query, pres1, pres2)
    else
        CURLE_UNKNOWN_OPTION;
}

pub export fn Curl_conn_trc_filters_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    info: [*:0]const u8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) void {
    if (Curl_trc_is_verbose(data) and conn_cfilters != null) {
        var cf = conn_cfilters.?[@intCast(sockindex)];
        if (cf != null) {
            var msg: [256]u8 = undefined;
            var buf: [*]u8 = &msg;
            var blen: usize = msg.len - 1;
            var n: c_int = curl_msnprintf(buf, blen, "%s [%d]", info, @as(c_int, sockindex));
            if (n > 0) {
                const un: usize = @intCast(n);
                buf += un;
                blen -|= un;
            }
            while (cf != null and blen != 0) : (cf = cf.?.next) {
                const prefix: [*:0]const u8 = if (cf.?.isConnected()) "" else "!";
                n = curl_msnprintf(buf, blen, "[%s%s]", prefix, cf.?.cft.name);
                if (n > 0) {
                    const un: usize = @intCast(n);
                    buf += un;
                    blen -|= un;
                }
            }
            const suffix: [*:0]const u8 = if (blen != 0) "" else "...";
            Curl_trc_multi(data, "%s%s", @as([*:0]const u8, @ptrCast(&msg)), suffix);
        } else {
            Curl_trc_multi(data, "%s [%d][-]", info, @as(c_int, sockindex));
        }
    }
}

pub export fn Curl_conn_cf_discard_chain(
    pcf: *?*CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) void {
    var cf = pcf.*;
    if (cf != null) {
        pcf.* = null;
        while (cf) |cur| {
            const cfn = cur.next;
            cur.next = null;
            cur.cft.destroy.?(cur, data);
            mem.free(@ptrCast(cur));
            cf = cfn;
        }
    }
}

pub export fn Curl_conn_cf_discard_all_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: [*]?*CurlCfilter,
    shutdown_start_ms: [*]i64,
) callconv(.c) void {
    _ = conn;
    shutdown_start_ms[@intCast(sockindex)] = -1;
    Curl_conn_cf_discard_chain(&conn_cfilters[@intCast(sockindex)], data);
}

pub export fn Curl_cf_recv(
    data: ?*CurlEasy,
    sockindex: i8,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    var cf = Curl_easy_conn_cfilter(data, sockindex);
    while (cf != null and !cf.?.isConnected()) {
        cf = cf.?.next;
    }
    if (cf) |c| {
        return c.cft.do_recv.?(c, data, buf, len, pnread);
    }
    Curl_failf(data, "recv: no filter connected");
    pnread.* = 0;
    return CURLE_FAILED_INIT;
}

pub export fn Curl_cf_send(
    data: ?*CurlEasy,
    sockindex: i8,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    var cf = Curl_easy_conn_cfilter(data, sockindex);
    while (cf != null and !cf.?.isConnected()) {
        cf = cf.?.next;
    }
    if (cf) |c| {
        return c.cft.do_send.?(c, data, buf, len, eos, pnwritten);
    }
    Curl_failf(data, "send: no filter connected");
    pnwritten.* = 0;
    return CURLE_FAILED_INIT;
}

fn cfBufqReader(
    writer_ctx: ?*anyopaque,
    buf: [*]u8,
    blen: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    const io: *CfIoCtx = @ptrCast(@alignCast(writer_ctx));
    return Curl_conn_cf_recv(io.cf, io.data, buf, blen, pnread);
}

pub export fn Curl_cf_recv_bufq(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    bufq: *Bufq,
    maxlen: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    if (cf == null or data == null) {
        pnread.* = 0;
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    var io = CfIoCtx{ .data = data, .cf = cf.? };
    return Curl_bufq_sipn(bufq, maxlen, cfBufqReader, &io, pnread);
}

fn cfBufqWriter(
    writer_ctx: ?*anyopaque,
    buf: [*]const u8,
    buflen: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    const io: *CfIoCtx = @ptrCast(@alignCast(writer_ctx));
    return Curl_conn_cf_send(io.cf, io.data, buf, buflen, false, pnwritten);
}

pub export fn Curl_cf_send_bufq(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    bufq: *Bufq,
    buf: ?[*]const u8,
    blen: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    if (cf == null or data == null) {
        pnwritten.* = 0;
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    var io = CfIoCtx{ .data = data, .cf = cf.? };
    if (buf != null and blen != 0) {
        return Curl_bufq_write_pass(bufq, buf.?, blen, cfBufqWriter, &io, pnwritten);
    } else {
        return Curl_bufq_pass(bufq, cfBufqWriter, &io, pnwritten);
    }
}

pub export fn Curl_cf_create(
    pcf: *?*CurlCfilter,
    cft: *const CurlCftype,
    ctx: ?*anyopaque,
) callconv(.c) CURLcode {
    pcf.* = null;
    const raw = mem.calloc(1, @sizeOf(CurlCfilter)) orelse return CURLE_OUT_OF_MEMORY;
    const cf: *CurlCfilter = @ptrCast(@alignCast(raw));
    cf.cft = cft;
    cf.ctx = ctx;
    pcf.* = cf;
    return CURLE_OK;
}

pub export fn Curl_conn_cf_add_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    cf: *CurlCfilter,
    conn_cfilters: [*]?*CurlCfilter,
) callconv(.c) void {
    std.debug.assert(conn != null);
    std.debug.assert(cf.conn == null);
    std.debug.assert(cf.next == null);

    cf.next = conn_cfilters[@intCast(sockindex)];
    cf.conn = conn;
    cf.sockindex = sockindex;
    conn_cfilters[@intCast(sockindex)] = cf;
    if (Curl_trc_is_verbose(data) and cf.cft.log_level >= 1) {
        Curl_trc_cf_infof(data, cf, "added");
    }
}

pub export fn Curl_conn_cf_insert_after(
    cf_at: *CurlCfilter,
    cf_new_arg: *CurlCfilter,
) callconv(.c) void {
    std.debug.assert(cf_new_arg.conn == null);
    const tail = cf_at.next;
    cf_at.next = cf_new_arg;
    var cf_new: ?*CurlCfilter = cf_new_arg;
    var pnext: *?*CurlCfilter = &cf_new_arg.next;
    while (cf_new) |c| {
        c.conn = cf_at.conn;
        c.sockindex = cf_at.sockindex;
        pnext = &c.next;
        cf_new = c.next;
    }
    pnext.* = tail;
}

pub export fn Curl_conn_cf_discard_zig(
    pcf: ?*?*CurlCfilter,
    data: ?*CurlEasy,
    conn_cfilters: ?[*]?*CurlCfilter,
) callconv(.c) bool {
    const pcf_nonnull = pcf orelse return false;
    const cf = pcf_nonnull.* orelse return false;
    var found = false;
    if (cf.conn != null and conn_cfilters != null) {
        var pprev: *?*CurlCfilter = &conn_cfilters.?[@intCast(cf.sockindex)];
        while (pprev.*) |cur| {
            if (cur == cf) {
                pprev.* = cf.next;
                cf.next = null;
                found = true;
                break;
            }
            pprev = &cur.next;
        }
    }
    Curl_conn_cf_discard_chain(pcf_nonnull, data);
    return found;
}

pub export fn Curl_conn_cf_connect(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    if (cf) |c| {
        return c.cft.do_connect.?(c, data, done);
    }
    return CURLE_FAILED_INIT;
}

pub export fn Curl_conn_cf_send(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    if (cf) |c| {
        return c.cft.do_send.?(c, data, buf, len, eos, pnwritten);
    }
    pnwritten.* = 0;
    return CURLE_SEND_ERROR;
}

pub export fn Curl_conn_cf_recv(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    if (cf) |c| {
        return c.cft.do_recv.?(c, data, buf, len, pnread);
    }
    pnread.* = 0;
    return CURLE_RECV_ERROR;
}

fn cfCntrlAll(
    conn_cfilters: ?[*]const ?*CurlCfilter,
    data: ?*CurlEasy,
    ignore_result: bool,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) CURLcode {
    const cfs = conn_cfilters orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;
    for (0..2) |i| {
        result = Curl_conn_cf_cntrl(cfs[i], data, ignore_result, event, arg1, arg2);
        if (!ignore_result and result != CURLE_OK)
            break;
    }
    return result;
}

pub export fn Curl_conn_cf_is_ip_connected(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) bool {
    if (cf) |c| {
        var value: c_int = 0;
        if (c.cft.query.?(c, data, CF_QUERY_REALLY_CONNECTED, &value, null) == CURLE_OK)
            return value != 0;
    }
    return false;
}

pub export fn Curl_conn_cntrl_update_info_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) void {
    _ = conn;
    _ = cfCntrlAll(conn_cfilters, data, true, CF_CTRL_CONN_INFO_UPDATE, 0, null);
}

pub export fn Curl_conn_cntrl_report_stats_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: c_int,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) void {
    _ = conn;
    if (conn_cfilters) |cfs| {
        if (sockindex >= 0 and sockindex < 2) {
            _ = Curl_conn_cf_cntrl(cfs[@intCast(sockindex)], data, true, CF_CTRL_REPORT_STATS, 0, null);
        }
    }
}

pub export fn Curl_conn_remove_setup_filters_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    conn_cfilters: ?[*]?*CurlCfilter,
) callconv(.c) void {
    const cfs = conn_cfilters orelse return;
    var anchor: *?*CurlCfilter = &cfs[@intCast(sockindex)];
    while (anchor.*) |cf| {
        if (cf.isConnected() and (cf.cft.flags & CF_TYPE_SETUP) != 0) {
            anchor.* = cf.next;
            cf.next = null;
            if (Curl_trc_is_verbose(data) and cf.cft.log_level >= 1) {
                Curl_trc_cf_infof(data, cf, "removing connected setup filter");
            }
            cf.cft.destroy.?(cf, data);
            mem.free(@ptrCast(cf));
        } else {
            anchor = &cf.next;
        }
    }
}

pub export fn Curl_conn_is_setup_zig(
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    _ = conn;
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    return conn_cfilters.?[@intCast(sockindex)] != null;
}

pub export fn Curl_conn_is_connected_zig(
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
    scheme_flags: c_uint,
) callconv(.c) bool {
    _ = conn;
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    if (conn_cfilters.?[@intCast(sockindex)]) |cf| {
        return cf.isConnected();
    } else if ((scheme_flags & PROTOPT_NONETWORK) != 0) {
        return true;
    }
    return false;
}

pub export fn Curl_conn_is_ip_connected_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    _ = data;
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    var cf = conn_cfilters.?[@intCast(sockindex)];
    while (cf) |c| : (cf = c.next) {
        if (c.isConnected())
            return true;
        if ((c.cft.flags & CF_TYPE_IP_CONNECT) != 0)
            return false;
    }
    return false;
}

pub export fn Curl_conn_is_tunneling_zig(
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    if (conn == null or !connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    var cf = conn_cfilters.?[@intCast(sockindex)];
    while (cf) |c| : (cf = c.next) {
        if ((c.cft.flags & CF_TYPE_PROXY) != 0)
            return true;
    }
    return false;
}

fn cfIsSsl(cf_start: ?*CurlCfilter) bool {
    var cf = cf_start;
    while (cf) |c| : (cf = c.next) {
        if ((c.cft.flags & CF_TYPE_SSL) != 0 and (c.cft.flags & CF_TYPE_PROXY) == 0)
            return true;
        if ((c.cft.flags & CF_TYPE_IP_CONNECT) != 0)
            return false;
    }
    return false;
}

pub export fn Curl_conn_is_ssl_zig(
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    if (conn == null or !connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    return cfIsSsl(conn_cfilters.?[@intCast(sockindex)]);
}

pub export fn Curl_conn_get_ssl_info_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    query: c_int,
    info: ?*anyopaque,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    if (!connSockIdxValid(sockindex))
        return false;
    if (Curl_conn_is_ssl_zig(conn, sockindex, conn_cfilters)) {
        const cf = conn_cfilters.?[@intCast(sockindex)];
        const result = if (cf) |c|
            c.cft.query.?(c, data, query, null, info)
        else
            CURLE_UNKNOWN_OPTION;
        return result == CURLE_OK;
    }
    return false;
}

pub export fn Curl_conn_get_ip_info_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    is_ipv6: *bool,
    ipquad: ?*anyopaque,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) CURLcode {
    if (!connSockIdxValid(sockindex))
        return CURLE_BAD_FUNCTION_ARGUMENT;
    const cf = if (conn != null and conn_cfilters != null)
        conn_cfilters.?[@intCast(sockindex)]
    else
        null;
    return Curl_conn_cf_get_ip_info(cf, data, is_ipv6, ipquad);
}

pub export fn Curl_conn_is_multiplex_zig(
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    if (conn == null or !connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    var cf = conn_cfilters.?[@intCast(sockindex)];
    while (cf) |c| : (cf = c.next) {
        if ((c.cft.flags & CF_TYPE_MULTIPLEX) != 0)
            return true;
        if ((c.cft.flags & (CF_TYPE_IP_CONNECT | CF_TYPE_SSL)) != 0)
            return false;
    }
    return false;
}

pub export fn Curl_conn_get_transport_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    conn_cfilters: ?[*]const ?*CurlCfilter,
    transport_wanted: u8,
) callconv(.c) u8 {
    _ = conn;
    const cf = if (conn_cfilters) |cfs| cfs[@intCast(FIRSTSOCKET)] else null;
    return Curl_conn_cf_get_transport_zig(cf, data, transport_wanted);
}

pub export fn Curl_socktype_for_transport(transport: u8) callconv(.c) c_int {
    return switch (transport) {
        TRNSPRT_TCP, TRNSPRT_UNIX => SOCK_STREAM,
        else => SOCK_DGRAM,
    };
}

pub export fn Curl_protocol_for_transport(transport: u8) callconv(.c) c_int {
    return switch (transport) {
        TRNSPRT_TCP => IPPROTO_TCP,
        TRNSPRT_UNIX => IPPROTO_IP,
        else => IPPROTO_UDP,
    };
}

pub export fn Curl_conn_get_alpn_negotiated_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) ?[*:0]const u8 {
    _ = conn;
    const cf = if (conn_cfilters) |cfs| cfs[@intCast(FIRSTSOCKET)] else null;
    return Curl_conn_cf_get_alpn_negotiated(cf, data);
}

pub export fn Curl_conn_http_version_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) u8 {
    _ = conn;
    var result: CURLcode = CURLE_UNKNOWN_OPTION;
    var v: u8 = 0;
    var cf = if (conn_cfilters) |cfs| cfs[@intCast(FIRSTSOCKET)] else null;
    while (cf) |c| : (cf = c.next) {
        if ((c.cft.flags & CF_TYPE_HTTP) != 0) {
            var value: c_int = 0;
            result = c.cft.query.?(c, data, CF_QUERY_HTTP_VERSION, &value, null);
            if (result == CURLE_OK and (value < 0 or value > 255))
                result = CURLE_FAILED_INIT
            else
                v = @intCast(value);
            break;
        }
        if ((c.cft.flags & (CF_TYPE_IP_CONNECT | CF_TYPE_SSL)) != 0)
            break;
    }
    return if (result != CURLE_OK) 0 else v;
}

pub export fn Curl_conn_data_pending_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    var cf = conn_cfilters.?[@intCast(sockindex)];
    while (cf != null and !cf.?.isConnected()) {
        cf = cf.?.next;
    }
    if (cf) |c| {
        return c.cft.has_data_pending.?(c, data);
    }
    return false;
}

pub export fn Curl_conn_cf_needs_flush(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) bool {
    var pending: c_int = 0;
    const result = if (cf) |c|
        c.cft.query.?(c, data, CF_QUERY_NEED_FLUSH, &pending, null)
    else
        CURLE_UNKNOWN_OPTION;
    return (result == CURLE_OK and pending != 0);
}

pub export fn Curl_conn_needs_flush_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) bool {
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return false;
    return Curl_conn_cf_needs_flush(conn_cfilters.?[@intCast(sockindex)], data);
}

pub export fn Curl_conn_cf_adjust_pollset(
    cf_start: ?*CurlCfilter,
    data: ?*CurlEasy,
    ps: *EasyPollset,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var cf = cf_start;
    while (cf != null and result == CURLE_OK) : (cf = cf.?.next) {
        const c = cf.?;
        if (c.isShutdown())
            continue;
        if (c.isConnected() or (c.cft.flags & CF_TYPE_DNS) != 0 or
            c.next == null or c.next.?.isConnected())
        {
            result = c.cft.adjust_pollset.?(c, data, ps);
        }
    }
    return result;
}

pub export fn Curl_conn_adjust_pollset_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    ps: *EasyPollset,
    conn_cfilters: ?[*]?*CurlCfilter,
    shutdown_start_ms: ?[*]const i64,
) callconv(.c) CURLcode {
    _ = conn;
    const cfs = conn_cfilters orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;
    const want_io = ps.n != 0;
    for (0..2) |i| {
        if (result != CURLE_OK) break;
        if (cfs[i]) |cf| {
            const in_shutdown = if (shutdown_start_ms) |sms| sms[i] >= 0 else false;
            if (want_io or !cf.isConnected() or in_shutdown) {
                result = Curl_conn_cf_adjust_pollset(cf, data, ps);
            }
        }
    }
    return result;
}

pub export fn Curl_conn_cf_poll(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    timeout_ms: i64,
) callconv(.c) c_int {
    var ps: EasyPollset = undefined;
    headers_sock.Curl_pollset_init(&ps);
    const result = Curl_conn_cf_adjust_pollset(cf, data, &ps);
    const rc: c_int = if (result == CURLE_OK)
        headers_sock.Curl_pollset_poll(@ptrCast(data), &ps, timeout_ms)
    else
        -1;
    headers_sock.Curl_pollset_cleanup(&ps);
    return rc;
}

pub export fn Curl_conn_get_current_host_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    phost: *?[*:0]const u8,
    pport: ?*c_int,
    conn_cfilters: ?[*]const ?*CurlCfilter,
    origin_hostname: ?[*:0]const u8,
    origin_port: c_int,
) callconv(.c) void {
    if (conn_cfilters == null) {
        phost.* = "";
        if (pport) |pp| pp.* = -1;
        return;
    }

    var cf = if (connSockIdxValid(sockindex)) conn_cfilters.?[@intCast(sockindex)] else null;
    var cf_proxy: ?*CurlCfilter = null;
    var portarg: c_int = -1;

    while (cf != null and !cf.?.isConnected()) : (cf = cf.?.next) {
        if ((cf.?.cft.flags & (CF_TYPE_IP_CONNECT | CF_TYPE_PROXY)) == (CF_TYPE_IP_CONNECT | CF_TYPE_PROXY))
            cf_proxy = cf;
    }
    if (cf_proxy == null or cf_proxy.?.cft.query.?(cf_proxy.?, data, CF_QUERY_HOST_PORT, &portarg, @ptrCast(phost)) != CURLE_OK) {
        phost.* = origin_hostname;
        portarg = origin_port;
    }
    if (pport) |pp|
        pp.* = portarg;
}

pub export fn Curl_cf_def_cntrl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = cf;
    _ = data;
    _ = event;
    _ = arg1;
    _ = arg2;
    return CURLE_OK;
}

pub export fn Curl_conn_cf_cntrl(
    cf_start: ?*CurlCfilter,
    data: ?*CurlEasy,
    ignore_result: bool,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var cf = cf_start;
    while (cf) |c| : (cf = c.next) {
        if (c.cft.cntrl == null or c.cft.cntrl.? == &Curl_cf_def_cntrl)
            continue;
        result = c.cft.cntrl.?(c, data, event, arg1, arg2);
        if (!ignore_result and result != CURLE_OK)
            break;
    }
    return result;
}

pub export fn Curl_conn_cf_get_socket(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) curl_socket_t {
    var sock: curl_socket_t = CURL_SOCKET_BAD;
    if (cf) |c| {
        if (c.cft.query.?(c, data, CF_QUERY_SOCKET, null, @ptrCast(&sock)) == CURLE_OK)
            return sock;
    }
    return CURL_SOCKET_BAD;
}

pub export fn Curl_conn_cf_get_transport_zig(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    transport_wanted: u8,
) callconv(.c) u8 {
    var transport: c_int = 0;
    if (cf) |c| {
        if (c.cft.query.?(c, data, CF_QUERY_TRANSPORT, &transport, null) == CURLE_OK)
            return @intCast(transport);
    }
    return transport_wanted;
}

pub export fn Curl_conn_cf_get_alpn_negotiated(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) ?[*:0]const u8 {
    var alpn: ?[*:0]const u8 = null;
    if (cf) |c| {
        if (Curl_trc_is_verbose(data) and c.cft.log_level >= 1) {
            Curl_trc_cf_infof(data, c, "query ALPN");
        }
        if (c.cft.query.?(c, data, CF_QUERY_ALPN_NEGOTIATED, null, @ptrCast(&alpn)) == CURLE_OK)
            return alpn;
    }
    return null;
}

fn cfGetRemoteAddr(cf: ?*CurlCfilter, data: ?*CurlEasy) ?*const anyopaque {
    var remote_addr: ?*const anyopaque = null;
    if (cf) |c| {
        if (c.cft.query.?(c, data, CF_QUERY_REMOTE_ADDR, null, @ptrCast(&remote_addr)) == CURLE_OK)
            return remote_addr;
    }
    return null;
}

pub export fn Curl_conn_cf_get_ip_info(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    is_ipv6: *bool,
    ipquad: ?*anyopaque,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_UNKNOWN_OPTION;
    if (cf) |c| {
        var ipv6: c_int = 0;
        result = c.cft.query.?(c, data, CF_QUERY_IP_INFO, &ipv6, ipquad);
        is_ipv6.* = ipv6 != 0;
    }
    return result;
}

pub export fn Curl_conn_get_first_socket_zig(
    data: ?*CurlEasy,
    conn_cfilters: ?[*]const ?*CurlCfilter,
    conn_sock: ?[*]const curl_socket_t,
) callconv(.c) curl_socket_t {
    if (conn_cfilters == null or conn_sock == null)
        return CURL_SOCKET_BAD;
    const cf = conn_cfilters.?[@intCast(FIRSTSOCKET)];
    if (cf != null and !cf.?.isConnected())
        return Curl_conn_cf_get_socket(cf, data);
    return conn_sock.?[@intCast(FIRSTSOCKET)];
}

pub export fn Curl_conn_get_remote_addr_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) ?*const anyopaque {
    const cf = if (conn_cfilters != null and connSockIdxValid(sockindex))
        conn_cfilters.?[@intCast(sockindex)]
    else
        null;
    return if (cf != null) cfGetRemoteAddr(cf, data) else null;
}

pub export fn Curl_conn_ev_data_setup_zig(
    data: ?*CurlEasy,
    conn_cfilters: ?[*]?*CurlCfilter,
    shutdown_start_ms: ?[*]const i64,
) callconv(.c) CURLcode {
    _ = shutdown_start_ms;
    return cfCntrlAll(conn_cfilters, data, false, CF_CTRL_DATA_SETUP, 0, null);
}

pub export fn Curl_conn_flush_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) CURLcode {
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return CURLE_BAD_FUNCTION_ARGUMENT;
    return Curl_conn_cf_cntrl(conn_cfilters.?[@intCast(sockindex)], data, false, CF_CTRL_FLUSH, 0, null);
}

pub export fn Curl_conn_ev_data_done_send_zig(
    data: ?*CurlEasy,
    conn_cfilters: ?[*]?*CurlCfilter,
    shutdown_start_ms: ?[*]const i64,
) callconv(.c) void {
    _ = shutdown_start_ms;
    _ = cfCntrlAll(conn_cfilters, data, true, CF_CTRL_DATA_DONE_SEND, 0, null);
}

pub export fn Curl_conn_ev_data_done_zig(
    data: ?*CurlEasy,
    premature: bool,
    conn_cfilters: ?[*]?*CurlCfilter,
    shutdown_start_ms: ?[*]const i64,
) callconv(.c) void {
    _ = shutdown_start_ms;
    _ = cfCntrlAll(conn_cfilters, data, true, CF_CTRL_DATA_DONE, if (premature) 1 else 0, null);
}

pub export fn Curl_conn_ev_data_pause_zig(
    data: ?*CurlEasy,
    do_pause: bool,
    conn_cfilters: ?[*]?*CurlCfilter,
    shutdown_start_ms: ?[*]const i64,
) callconv(.c) CURLcode {
    _ = shutdown_start_ms;
    return cfCntrlAll(conn_cfilters, data, false, CF_CTRL_DATA_PAUSE, if (do_pause) 1 else 0, null);
}

pub export fn Curl_conn_is_alive_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    input_pending: *bool,
    conn_cfilters: ?[*]const ?*CurlCfilter,
    conn_bits_close: bool,
) callconv(.c) bool {
    _ = conn;
    if (conn_cfilters == null or conn_bits_close)
        return false;
    const cf = conn_cfilters.?[@intCast(FIRSTSOCKET)] orelse return false;
    return cf.cft.is_alive.?(cf, data, input_pending);
}

pub export fn Curl_conn_keep_alive_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    conn_cfilters: ?[*]?*CurlCfilter,
    shutdown_start_ms: ?[*]const i64,
) callconv(.c) CURLcode {
    _ = conn;
    _ = shutdown_start_ms;
    const cfs = conn_cfilters orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;
    for (0..2) |i| {
        if (result != CURLE_OK) break;
        if (cfs[i]) |cf| {
            result = cf.cft.keep_alive.?(cf, data);
        }
    }
    return result;
}

pub export fn Curl_conn_get_max_concurrent_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) usize {
    _ = conn;
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return 0;
    var n: c_int = -1;
    const cf = conn_cfilters.?[@intCast(sockindex)];
    const result = if (cf) |c|
        c.cft.query.?(c, data, CF_QUERY_MAX_CONCURRENT, &n, null)
    else
        CURLE_UNKNOWN_OPTION;
    return if (result != CURLE_OK or n < 0) 1 else @intCast(n);
}

pub export fn Curl_conn_get_stream_error_zig(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    conn_cfilters: ?[*]const ?*CurlCfilter,
) callconv(.c) c_int {
    _ = conn;
    if (!connSockIdxValid(sockindex) or conn_cfilters == null)
        return 0;
    var n: c_int = 0;
    const cf = conn_cfilters.?[@intCast(sockindex)];
    const result = if (cf) |c|
        c.cft.query.?(c, data, CF_QUERY_STREAM_ERROR, &n, null)
    else
        CURLE_UNKNOWN_OPTION;
    return if (result != CURLE_OK or n < 0) 0 else n;
}

pub export fn Curl_conn_sockindex_zig(
    data: ?*CurlEasy,
    sockfd: curl_socket_t,
    conn_sock: ?[*]const curl_socket_t,
) callconv(.c) i8 {
    _ = data;
    if (conn_sock != null and sockfd != CURL_SOCKET_BAD and sockfd == conn_sock.?[@intCast(SECONDARYSOCKET)])
        return SECONDARYSOCKET;
    return FIRSTSOCKET;
}

pub export fn Curl_conn_recv_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
    conn_recv: ?[*]const CurlRecvFn,
) callconv(.c) CURLcode {
    if (!connSockIdxValid(sockindex))
        return CURLE_BAD_FUNCTION_ARGUMENT;
    if (data != null and conn_recv != null) {
        if (conn_recv.?[@intCast(sockindex)]) |recv_fn| {
            return recv_fn(data, sockindex, buf, len, pnread);
        }
    }
    pnread.* = 0;
    return CURLE_FAILED_INIT;
}

pub export fn Curl_conn_send_zig(
    data: ?*CurlEasy,
    sockindex: i8,
    buf: *const anyopaque,
    len: usize,
    eos: bool,
    pnwritten: *usize,
    conn_send: ?[*]const CurlSendFn,
) callconv(.c) CURLcode {
    if (!connSockIdxValid(sockindex))
        return CURLE_BAD_FUNCTION_ARGUMENT;
    if (data != null and conn_send != null) {
        if (conn_send.?[@intCast(sockindex)]) |send_fn| {
            const result = send_fn(data, sockindex, buf, len, eos, pnwritten);
            if (result == CURLE_OK and pnwritten.* > len) {
                pnwritten.* = 0;
                return CURLE_SEND_ERROR;
            }
            return result;
        }
    }
    pnwritten.* = 0;
    return CURLE_FAILED_INIT;
}

// ============================================================================
// 4. conncache.c
// ============================================================================

const CURL_LOCK_DATA_CONNECT: c_uint = 5;
const CURL_LOCK_ACCESS_SINGLE: c_uint = 2;
const CURL_HASH_TYPE_BYTES: c_uint = 0;

const CpoolBundle = extern struct {
    ids: Uint32Spbset,
    refcount: u32,
};

pub const Cpool = extern struct {
    conns: Uint32Tbl,
    idles: Uint32Bset,
    dest2bundle: CurlHash,
    next_connection_id: i64,
    next_easy_id: i64,
    last_cleanup: CurlTime,
    share: ?*CurlShare,
    flags: u8,

    // bit 0: locked
    // bit 1: initialized
    // bit 2: in_shutdown
    pub fn isLocked(self: *const Cpool) bool {
        return (self.flags & (1 << 0)) != 0;
    }
    pub fn setLocked(self: *Cpool, v: bool) void {
        if (v) self.flags |= (1 << 0) else self.flags &= ~@as(u8, 1 << 0);
    }
    pub fn isInitialized(self: *const Cpool) bool {
        return (self.flags & (1 << 1)) != 0;
    }
    pub fn setInitialized(self: *Cpool, v: bool) void {
        if (v) self.flags |= (1 << 1) else self.flags &= ~@as(u8, 1 << 1);
    }
    pub fn isInShutdown(self: *const Cpool) bool {
        return (self.flags & (1 << 2)) != 0;
    }
    pub fn setInShutdown(self: *Cpool, v: bool) void {
        if (v) self.flags |= (1 << 2) else self.flags &= ~@as(u8, 1 << 2);
    }
};

pub const CpoolMatchResult = enum(c_int) {
    CPOOL_MATCH_FOUND = 0,
    CPOOL_MATCH_CONT = 1,
    CPOOL_MATCH_CLOSE = 2,
    CPOOL_MATCH_TOO_OLD = 3,
};

pub const CpoolDoResult = enum(c_int) {
    CPOOL_DO_KEEP = 0,
    CPOOL_DO_IDLE = 1,
    CPOOL_DO_CLOSE = 2,
    CPOOL_DO_TERMINATE = 3,
};

pub const CurlCpoolConnMatchCb = *const fn (*ConnectData, ?*anyopaque) callconv(.c) CpoolMatchResult;
pub const CurlCpoolDoneMatchCb = ?*const fn (?*anyopaque) callconv(.c) bool;
pub const CurlCpoolReturnCb = *const fn (?*CurlEasy, *ConnectData, ?*anyopaque, *const CurlTime) callconv(.c) CpoolDoResult;

extern fn Curl_uint32_tbl_init(tbl: *Uint32Tbl) callconv(.c) void;
extern fn Curl_uint32_tbl_resize(tbl: *Uint32Tbl, nrows: u32) callconv(.c) CURLcode;
extern fn Curl_uint32_tbl_destroy(tbl: *Uint32Tbl) callconv(.c) void;
extern fn Curl_uint32_tbl_capacity(tbl: *Uint32Tbl) callconv(.c) u32;
extern fn Curl_uint32_tbl_count(tbl: *Uint32Tbl) callconv(.c) u32;
extern fn Curl_uint32_tbl_get(tbl: *Uint32Tbl, key: u32) callconv(.c) ?*ConnectData;
extern fn Curl_uint32_tbl_add(tbl: *Uint32Tbl, entry: ?*anyopaque, pkey: *u32) callconv(.c) bool;
extern fn Curl_uint32_tbl_remove(tbl: *Uint32Tbl, key: u32) callconv(.c) void;
extern fn Curl_uint32_tbl_first(tbl: *Uint32Tbl, pkey: *u32, pentry: *?*anyopaque) callconv(.c) bool;
extern fn Curl_uint32_tbl_next(tbl: *Uint32Tbl, last_key: u32, pkey: *u32, pentry: *?*anyopaque) callconv(.c) bool;

extern fn Curl_uint32_bset_init(bset: *Uint32Bset) callconv(.c) void;
extern fn Curl_uint32_bset_resize(bset: *Uint32Bset, nmax: u32) callconv(.c) CURLcode;
extern fn Curl_uint32_bset_destroy(bset: *Uint32Bset) callconv(.c) void;
extern fn Curl_uint32_bset_add(bset: *Uint32Bset, i: u32) callconv(.c) bool;
extern fn Curl_uint32_bset_remove(bset: *Uint32Bset, i: u32) callconv(.c) void;
extern fn Curl_uint32_bset_first(bset: *Uint32Bset, pfirst: *u32) callconv(.c) bool;
extern fn Curl_uint32_bset_next(bset: *Uint32Bset, last: u32, pnext: *u32) callconv(.c) bool;

extern fn Curl_uint32_spbset_init(bset: *Uint32Spbset) callconv(.c) void;
extern fn Curl_uint32_spbset_destroy(bset: *Uint32Spbset) callconv(.c) void;
extern fn Curl_uint32_spbset_count(bset: *Uint32Spbset) callconv(.c) u32;
extern fn Curl_uint32_spbset_add(bset: *Uint32Spbset, i: u32) callconv(.c) bool;
extern fn Curl_uint32_spbset_remove(bset: *Uint32Spbset, i: u32) callconv(.c) void;
extern fn Curl_uint32_spbset_first(bset: *Uint32Spbset, pfirst: *u32) callconv(.c) bool;
extern fn Curl_uint32_spbset_next(bset: *Uint32Spbset, last: u32, pnext: *u32) callconv(.c) bool;

extern fn Curl_hash_init(h: *CurlHash, slots: usize, hash_type: c_uint, dtor: CurlHashDtor) callconv(.c) void;
extern fn Curl_hash_destroy(h: *CurlHash) callconv(.c) void;
extern fn Curl_hash_pick(h: *CurlHash, key: *const anyopaque, key_len: usize) callconv(.c) ?*anyopaque;
extern fn Curl_hash_add(h: *CurlHash, key: *const anyopaque, key_len: usize, p: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn Curl_hash_delete(h: *CurlHash, key: *const anyopaque, key_len: usize) callconv(.c) c_int;

extern fn Curl_share_lock_share(share: *CurlShare, data: ?*CurlEasy, lock_type: c_uint, accesstype: c_uint) callconv(.c) c_uint;
extern fn Curl_share_unlock_share(share: *CurlShare, data: ?*CurlEasy, lock_type: c_uint) callconv(.c) c_uint;

extern fn Curl_get_admin(data: ?*CurlEasy) callconv(.c) ?*CurlEasy;
extern fn Curl_attach_connection(data: ?*CurlEasy, conn: *ConnectData, restore: bool) callconv(.c) void;
extern fn Curl_detach_connection(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_multi_xfers_attached(multi: ?*CurlMulti) callconv(.c) u32;
extern fn Curl_cshutdn_terminate(admin: ?*CurlEasy, conn: *ConnectData, do_shutdown: bool) callconv(.c) void;
extern fn Curl_cshutdn_try_once(admin: ?*CurlEasy, conn: *ConnectData, done: *bool) callconv(.c) void;
extern fn Curl_cshutdn_add(cshutdn: *Cshutdn, multi: ?*CurlMulti, conn: *ConnectData, max_shutdowns: usize) callconv(.c) void;
extern fn Curl_cshutdn_count(cshutdn: *Cshutdn) callconv(.c) usize;
extern fn Curl_cshutdn_dest_count(cshutdn: *Cshutdn, destination: [*:0]const u8) callconv(.c) usize;
extern fn Curl_cshutdn_close_oldest(cshutdn: *Cshutdn, admin: ?*CurlEasy, destination: ?[*:0]const u8, count: usize) callconv(.c) usize;

extern fn Curl_share_keep_connect(share: ?*const CurlShare) callconv(.c) bool;
extern fn Curl_cpool_with_sigpipe(
    admin: ?*CurlEasy,
    cpool: *Cpool,
    fn_ptr: *const fn (*Cpool, ?*CurlEasy) callconv(.c) void,
) callconv(.c) void;
extern fn Curl_conn_get_cpid(conn: *const ConnectData) callconv(.c) u32;
extern fn Curl_conn_set_cpid(conn: *ConnectData, cpid: u32) callconv(.c) void;
extern fn Curl_conn_get_attached_xfers(conn: *const ConnectData) callconv(.c) u32;
extern fn Curl_conn_is_connect_only(conn: *const ConnectData) callconv(.c) bool;
extern fn Curl_conn_set_aborted(conn: *ConnectData, aborted: bool) callconv(.c) void;
extern fn Curl_conn_is_no_reuse_or_close(conn: *const ConnectData) callconv(.c) bool;
extern fn Curl_conn_is_close(conn: *const ConnectData) callconv(.c) bool;
extern fn Curl_conn_set_no_reuse(conn: *ConnectData, no_reuse: bool) callconv(.c) void;
extern fn Curl_conn_get_id(conn: *const ConnectData) callconv(.c) i64;
extern fn Curl_conn_set_id(conn: *ConnectData, id: i64) callconv(.c) void;
extern fn Curl_cpool_conn_get_destination(conn: *const ConnectData) callconv(.c) [*:0]const u8;
extern fn Curl_conn_get_created(conn: *const ConnectData) callconv(.c) *const CurlTime;
extern fn Curl_conn_init_cpool_times(conn: *ConnectData, pnow: *const CurlTime) callconv(.c) void;
extern fn Curl_conn_get_lastused_ms(conn: *const ConnectData) callconv(.c) i64;
extern fn Curl_conn_get_lastchecked_ms(conn: *const ConnectData) callconv(.c) i64;
extern fn Curl_conn_set_lastchecked_ms(conn: *ConnectData, ms: i64) callconv(.c) void;
extern fn Curl_conn_get_lastupkeep_ms(conn: *const ConnectData) callconv(.c) i64;
extern fn Curl_conn_set_lastupkeep_ms(conn: *ConnectData, ms: i64) callconv(.c) void;
extern fn Curl_conn_set_return_times(conn: *ConnectData, ms: i64) callconv(.c) void;
extern fn Curl_conn_get_origin_info(
    conn: *const ConnectData,
    puser_hostname: *?[*:0]const u8,
    pport: *u16,
) callconv(.c) void;
extern fn Curl_conn_has_dead_cb(conn: *const ConnectData) callconv(.c) bool;
extern fn Curl_conn_call_dead_cb(admin: ?*CurlEasy, conn: *ConnectData) callconv(.c) bool;
extern fn Curl_easy_get_multi_cpool(
    data: ?*CurlEasy,
    pmulti: *?*CurlMulti,
    pmulti_admin: *?*CurlEasy,
    pmulti_cpool: *?*Cpool,
    pmulti_cshutdn: *?*Cshutdn,
    pmax_total_conns: *u32,
    pmaxconnects: *u32,
) callconv(.c) void;
extern fn Curl_easy_get_conn_age_limits(
    data: ?*CurlEasy,
    pmax_idle_ms: *i64,
    pmax_age_ms: *i64,
    pupkeep_interval_ms: *i64,
) callconv(.c) void;

fn cpoolLock(cp: ?*Cpool, d: ?*CurlEasy) void {
    if (cp) |c| {
        if (Curl_share_keep_connect(c.share)) {
            _ = Curl_share_lock_share(c.share.?, d, CURL_LOCK_DATA_CONNECT, CURL_LOCK_ACCESS_SINGLE);
        }
        std.debug.assert(!c.isLocked());
        c.setLocked(true);
    }
}

fn cpoolUnlock(cp: ?*Cpool, d: ?*CurlEasy) void {
    if (cp) |c| {
        std.debug.assert(c.isLocked());
        c.setLocked(false);
        if (Curl_share_keep_connect(c.share)) {
            _ = Curl_share_unlock_share(c.share.?, d, CURL_LOCK_DATA_CONNECT);
        }
    }
}

fn cpoolBundleUnlink(pbundle: *?*CpoolBundle) void {
    if (pbundle.*) |bundle| {
        std.debug.assert(bundle.refcount != 0);
        pbundle.* = null;
        if (bundle.refcount != 0)
            bundle.refcount -= 1;
        if (bundle.refcount == 0) {
            Curl_uint32_spbset_destroy(&bundle.ids);
            mem.free(@ptrCast(bundle));
        }
    }
}

fn cpoolBundleLink(pdest: *?*CpoolBundle, src: ?*CpoolBundle) void {
    if (pdest.* != src) {
        cpoolBundleUnlink(pdest);
        pdest.* = src;
        if (src) |s| {
            std.debug.assert(s.refcount < std.math.maxInt(u32));
            s.refcount += 1;
        }
    }
}

fn cpoolCreateBundle() ?*CpoolBundle {
    const raw = mem.calloc(1, @sizeOf(CpoolBundle)) orelse return null;
    const bundle: *CpoolBundle = @ptrCast(@alignCast(raw));
    Curl_uint32_spbset_init(&bundle.ids);
    bundle.refcount = 1;
    return bundle;
}

fn cpoolBundleAddId(
    cpool: *Cpool,
    bundle: *CpoolBundle,
    destination: [*:0]const u8,
    pool_id: u32,
) bool {
    if (!Curl_uint32_spbset_add(&bundle.ids, pool_id))
        return false;
    if (Curl_uint32_spbset_count(&bundle.ids) == 1) {
        var new_ref: ?*CpoolBundle = null;
        cpoolBundleLink(&new_ref, bundle);
        if (Curl_hash_add(&cpool.dest2bundle, destination, std.mem.len(destination), new_ref) == null) {
            cpoolBundleUnlink(&new_ref);
            return false;
        }
    }
    return true;
}

fn cpoolBundleRemoveId(
    cpool: *Cpool,
    bundle: *CpoolBundle,
    destination: [*:0]const u8,
    pool_id: u32,
) void {
    Curl_uint32_spbset_remove(&bundle.ids, pool_id);
    if (Curl_uint32_spbset_count(&bundle.ids) == 0) {
        _ = Curl_hash_delete(&cpool.dest2bundle, destination, std.mem.len(destination));
    }
}

fn cpoolBundleHashDtor(entry: ?*anyopaque) callconv(.c) void {
    var bundle: ?*CpoolBundle = @ptrCast(@alignCast(entry));
    cpoolBundleUnlink(&bundle);
}

fn cpoolGetBundle(cpool: *Cpool, destination: [*:0]const u8) ?*CpoolBundle {
    var bundle: ?*CpoolBundle = null;
    const raw = Curl_hash_pick(&cpool.dest2bundle, destination, std.mem.len(destination));
    cpoolBundleLink(&bundle, @ptrCast(@alignCast(raw)));
    return bundle;
}

fn cpoolRemoveConn(cpool: *Cpool, conn: *ConnectData) void {
    const cpid = Curl_conn_get_cpid(conn);
    if (cpid != std.math.maxInt(u32)) {
        Curl_uint32_tbl_remove(&cpool.conns, cpid);
        Curl_uint32_bset_remove(&cpool.idles, cpid);
        Curl_conn_set_cpid(conn, std.math.maxInt(u32));

        const dest = Curl_cpool_conn_get_destination(conn);
        var bundle = cpoolGetBundle(cpool, dest);
        std.debug.assert(bundle != null);
        if (bundle) |b| {
            cpoolBundleRemoveId(cpool, b, dest, cpid);
        }
        cpoolBundleUnlink(&bundle);
    }
}

fn cpoolDiscardConn(
    cpool: *Cpool,
    data: ?*CurlEasy,
    conn: *ConnectData,
    aborted_arg: bool,
) void {
    var done = false;
    var aborted = aborted_arg;
    const admin = Curl_get_admin(data);
    if (Curl_conn_get_attached_xfers(conn) != 0) {
        if (Curl_trc_is_verbose(admin)) {
            Curl_trc_multi(
                admin,
                "[CPOOL] not discarding #%lld still in use by %u transfers",
                @as(c_longlong, Curl_conn_get_id(conn)),
                Curl_conn_get_attached_xfers(conn),
            );
        }
        return;
    }

    if (Curl_conn_is_connect_only(conn))
        aborted = true;
    Curl_conn_set_aborted(conn, aborted);

    if (aborted)
        done = true;
    if (!done) {
        Curl_cshutdn_try_once(admin, conn, &done);
    }

    var multi: ?*CurlMulti = null;
    var multi_admin: ?*CurlEasy = null;
    var mcp: ?*Cpool = null;
    var mcshutdn: ?*Cshutdn = null;
    var max_total_conns: u32 = 0;
    var maxconnects: u32 = 0;
    Curl_easy_get_multi_cpool(data, &multi, &multi_admin, &mcp, &mcshutdn, &max_total_conns, &maxconnects);

    if (done or multi == null or mcshutdn == null) {
        Curl_cshutdn_terminate(admin, conn, false);
    } else {
        var max_shutdowns: usize = max_total_conns;
        const num_conns: u32 = Curl_uint32_tbl_count(&cpool.conns);
        if (num_conns < max_shutdowns) {
            max_shutdowns -= num_conns;
        } else if (max_shutdowns != 0) {
            max_shutdowns = 1;
        } else {
            max_shutdowns = @max(@as(usize, num_conns / 4), 128);
        }
        Curl_cshutdn_add(mcshutdn.?, multi, conn, max_shutdowns);
    }
}

pub export fn Curl_cpool_init(
    cpool: *Cpool,
    share: ?*CurlShare,
    size: usize,
) callconv(.c) void {
    Curl_uint32_tbl_init(&cpool.conns);
    Curl_uint32_bset_init(&cpool.idles);
    Curl_hash_init(&cpool.dest2bundle, size, CURL_HASH_TYPE_BYTES, cpoolBundleHashDtor);
    cpool.share = share;
    cpool.setInitialized(true);
    cpool.setInShutdown(false);
    cpool.setLocked(false);
}

fn cpoolDestroyAllConns(cpool: *Cpool, admin: ?*CurlEasy) callconv(.c) void {
    var entry: ?*anyopaque = null;
    var cpid: u32 = 0;
    if (Curl_uint32_tbl_first(&cpool.conns, &cpid, &entry)) {
        while (true) {
            const conn: *ConnectData = @ptrCast(@alignCast(entry.?));
            cpoolRemoveConn(cpool, conn);
            cpoolDiscardConn(cpool, admin, conn, false);
            if (!Curl_uint32_tbl_next(&cpool.conns, cpid, &cpid, &entry))
                break;
        }
    }
}

pub export fn Curl_cpool_destroy(
    cpool: ?*Cpool,
    admin: ?*CurlEasy,
) callconv(.c) void {
    if (cpool) |cp| {
        if (cp.isInitialized() and admin != null) {
            if (Curl_trc_is_verbose(admin)) {
                const prefix: [*:0]const u8 = if (cp.share != null) "[SHARE] " else "";
                Curl_trc_multi(
                    admin,
                    "%s[CPOOL] destroy, %u connections",
                    prefix,
                    Curl_uint32_tbl_count(&cp.conns),
                );
            }
            cpoolLock(cp, admin);
            var entry: ?*anyopaque = null;
            var cpid: u32 = 0;
            if (Curl_uint32_tbl_first(&cp.conns, &cpid, &entry)) {
                Curl_cpool_with_sigpipe(admin, cp, cpoolDestroyAllConns);
            }
            cpoolUnlock(cp, admin);
            Curl_hash_destroy(&cp.dest2bundle);
            Curl_uint32_bset_destroy(&cp.idles);
            Curl_uint32_tbl_destroy(&cp.conns);
        }
    }
}

pub export fn Curl_cpool_get_instance_zig(
    data: ?*CurlEasy,
    cpool: ?*Cpool,
) callconv(.c) ?*Cpool {
    _ = data;
    return cpool;
}

pub export fn Curl_cpool_xfer_init_zig(
    data: ?*CurlEasy,
    cpool: ?*Cpool,
    p_easy_id: *i64,
    p_last_conn_id: *i64,
    p_last_cpid: *u32,
) callconv(.c) void {
    if (cpool) |cp| {
        cpoolLock(cp, data);
        p_easy_id.* = cp.next_easy_id;
        cp.next_easy_id += 1;
        if (cp.next_easy_id == std.math.maxInt(i64))
            cp.next_easy_id = 0;
        p_last_conn_id.* = -1;
        p_last_cpid.* = std.math.maxInt(u32);
        cpoolUnlock(cp, data);
    } else {
        p_easy_id.* = 0;
        p_last_conn_id.* = -1;
        p_last_cpid.* = std.math.maxInt(u32);
    }
}

fn cpoolConnCanBeClosed(conn: ?*const ConnectData) bool {
    const c = conn orelse return false;
    return (Curl_conn_get_attached_xfers(c) == 0) and !Curl_conn_is_connect_only(c);
}

fn cpoolBundleGetOldestIdle(
    cpool: *Cpool,
    bundle: *CpoolBundle,
    pnow: *const CurlTime,
) ?*ConnectData {
    var cpid: u32 = 0;
    var oldest_id: u32 = std.math.maxInt(u32);
    var oldest_ms: i64 = -1;

    if (Curl_uint32_spbset_first(&bundle.ids, &cpid)) {
        while (true) {
            const conn = Curl_uint32_tbl_get(&cpool.conns, cpid);
            if (cpoolConnCanBeClosed(conn)) {
                const unused_ms = curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn.?)) - Curl_conn_get_lastused_ms(conn.?);
                if (unused_ms > oldest_ms) {
                    oldest_ms = unused_ms;
                    oldest_id = cpid;
                }
            } else if (conn == null) {
                Curl_uint32_spbset_remove(&bundle.ids, cpid);
            }
            if (!Curl_uint32_spbset_next(&bundle.ids, cpid, &cpid))
                break;
        }
    }
    return Curl_uint32_tbl_get(&cpool.conns, oldest_id);
}

fn cpoolGetOldestIdle(
    cpool: *Cpool,
    pnow: *const CurlTime,
    min_age_ms: i64,
) ?*ConnectData {
    var cpid: u32 = 0;
    var oldest_id: u32 = std.math.maxInt(u32);
    var oldest_idle_ms: i64 = -1;

    if (Curl_uint32_bset_first(&cpool.idles, &cpid)) {
        while (true) {
            const conn = Curl_uint32_tbl_get(&cpool.conns, cpid);
            if (cpoolConnCanBeClosed(conn)) {
                const idle_ms = curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn.?)) - Curl_conn_get_lastused_ms(conn.?);
                if (idle_ms >= min_age_ms and idle_ms > oldest_idle_ms) {
                    oldest_idle_ms = idle_ms;
                    oldest_id = cpid;
                }
            } else {
                Curl_uint32_bset_remove(&cpool.idles, cpid);
            }
            if (!Curl_uint32_bset_next(&cpool.idles, cpid, &cpid))
                break;
        }
    }
    return Curl_uint32_tbl_get(&cpool.conns, oldest_id);
}

fn cpoolConnClose(
    cpool_arg: ?*Cpool,
    data: ?*CurlEasy,
    conn: *ConnectData,
    aborted_arg: bool,
) void {
    const cpool = cpool_arg orelse return;
    if (Curl_conn_get_attached_xfers(conn) != 0 and !aborted_arg)
        return;

    const admin = Curl_get_admin(data);
    const do_lock = !cpool.isLocked();
    if (do_lock)
        cpoolLock(cpool, admin);

    if (Curl_conn_get_cpid(conn) != std.math.maxInt(u32)) {
        cpoolRemoveConn(cpool, conn);
    }

    var aborted = aborted_arg;
    if (Curl_conn_is_connect_only(conn))
        aborted = true;

    var multi: ?*CurlMulti = null;
    var multi_admin: ?*CurlEasy = null;
    var mcp: ?*Cpool = null;
    var mcshutdn: ?*Cshutdn = null;
    var max_total_conns: u32 = 0;
    var maxconnects: u32 = 0;
    Curl_easy_get_multi_cpool(data, &multi, &multi_admin, &mcp, &mcshutdn, &max_total_conns, &maxconnects);

    if (multi != null and mcp != null) {
        const verb: [*:0]const u8 = if (aborted) "closing" else "shutting down";
        Curl_infof(data, "%s connection #%lld", verb, @as(c_longlong, Curl_conn_get_id(conn)));
        cpoolDiscardConn(mcp.?, data, conn, aborted);
    } else {
        Curl_infof(data, "closing connection #%lld", @as(c_longlong, Curl_conn_get_id(conn)));
        Curl_cshutdn_terminate(admin, conn, !aborted);
    }

    if (do_lock)
        cpoolUnlock(cpool, admin);
}

pub export fn Curl_conn_close_zig(
    data: ?*CurlEasy,
    conn: *ConnectData,
    aborted: bool,
    cpool: ?*Cpool,
) callconv(.c) void {
    cpoolConnClose(cpool, data, conn, aborted);
}

fn cpoolEvictConn(
    cpool: *Cpool,
    admin: ?*CurlEasy,
    conn: *ConnectData,
) void {
    if (cpool.share != null) {
        cpoolRemoveConn(cpool, conn);
        Curl_cshutdn_terminate(admin, conn, true);
    } else {
        cpoolConnClose(cpool, admin, conn, false);
    }
}

const CPOOL_LIMIT_OK: c_int = 0;
const CPOOL_LIMIT_DEST: c_int = 1;
const CPOOL_LIMIT_TOTAL: c_int = 2;

fn cpoolCheckLimits(
    cpool: ?*Cpool,
    data: ?*CurlEasy,
    data_internal: bool,
    max_total: u32,
    to_add: *ConnectData,
    max_host: u32,
    bundle: ?*CpoolBundle,
    pnow: *const CurlTime,
) c_int {
    const cp = cpool orelse return CPOOL_LIMIT_OK;
    if (max_total == 0 and max_host == 0)
        return CPOOL_LIMIT_OK;

    var multi: ?*CurlMulti = null;
    var multi_admin: ?*CurlEasy = null;
    var mcp: ?*Cpool = null;
    var cshutdn: ?*Cshutdn = null;
    var max_total_conns: u32 = 0;
    var maxconnects: u32 = 0;
    Curl_easy_get_multi_cpool(data, &multi, &multi_admin, &mcp, &cshutdn, &max_total_conns, &maxconnects);
    var admin: ?*CurlEasy = null;

    if (max_host != 0) {
        var live: usize = 0;
        var shutdowns: usize = 0;
        admin = Curl_get_admin(data);
        if (bundle) |b| {
            live = Curl_uint32_spbset_count(&b.ids);
            if (live >= max_host) {
                var over: usize = live - max_host + 1;
                while (over != 0) : (over -= 1) {
                    const oldest_idle = cpoolBundleGetOldestIdle(cp, b, pnow) orelse break;
                    if (Curl_trc_is_verbose(admin)) {
                        Curl_trc_multi(
                            admin,
                            "Shutting down connection #%lld to '%s' due to destination limit of %u",
                            @as(c_longlong, Curl_conn_get_id(oldest_idle)),
                            Curl_cpool_conn_get_destination(oldest_idle),
                            max_host,
                        );
                    }
                    cpoolEvictConn(cp, admin, oldest_idle);
                }
                live = Curl_uint32_spbset_count(&b.ids);
            }
        }
        if (cshutdn) |cs| {
            const dest = Curl_cpool_conn_get_destination(to_add);
            shutdowns = Curl_cshutdn_dest_count(cs, dest);
            if (shutdowns != 0 and (live + shutdowns) >= max_host) {
                const over: usize = live + shutdowns - max_host + 1;
                shutdowns -= Curl_cshutdn_close_oldest(cs, admin, dest, over);
            }
        }
        if ((live + shutdowns) >= max_host)
            return CPOOL_LIMIT_DEST;
    }

    if (max_total != 0 and !data_internal) {
        var shutdowns: usize = 0;
        var num_conns: u32 = Curl_uint32_tbl_count(&cp.conns);
        if (admin == null)
            admin = Curl_get_admin(data);
        if (num_conns >= max_total) {
            var over: usize = num_conns - max_total + 1;
            while (over != 0) : (over -= 1) {
                const oldest_idle = cpoolGetOldestIdle(cp, pnow, 0) orelse break;
                if (Curl_trc_is_verbose(admin)) {
                    Curl_trc_multi(
                        admin,
                        "Shutting down idle connection #%lld to '%s' due to total limit of %u",
                        @as(c_longlong, Curl_conn_get_id(oldest_idle)),
                        Curl_cpool_conn_get_destination(oldest_idle),
                        max_total,
                    );
                }
                cpoolEvictConn(cp, admin, oldest_idle);
            }
        }

        num_conns = Curl_uint32_tbl_count(&cp.conns);
        if (cshutdn) |cs| {
            shutdowns = Curl_cshutdn_count(cs);
            if (shutdowns != 0 and (num_conns + shutdowns) >= max_total) {
                const over: usize = num_conns + shutdowns - max_total + 1;
                shutdowns -= Curl_cshutdn_close_oldest(cs, admin, null, over);
            }
        }
        if ((num_conns + shutdowns) >= max_total)
            return CPOOL_LIMIT_TOTAL;
    }

    return CPOOL_LIMIT_OK;
}

pub export fn Curl_cpool_add_zig(
    data: ?*CurlEasy,
    conn: *ConnectData,
    max_total: u32,
    max_host: u32,
    pnow: *const CurlTime,
    cpool_arg: ?*Cpool,
    data_internal: bool,
) callconv(.c) CURLcode {
    const result: CURLcode = CURLE_OK;
    var bundle: ?*CpoolBundle = null;
    const cpool = cpool_arg orelse return CURLE_FAILED_INIT;

    Curl_conn_init_cpool_times(conn, pnow);

    cpoolLock(cpool, data);
    defer {
        cpoolBundleUnlink(&bundle);
        cpoolUnlock(cpool, data);
    }

    const dest = Curl_cpool_conn_get_destination(conn);
    bundle = cpoolGetBundle(cpool, dest);

    switch (cpoolCheckLimits(cpool, data, data_internal, max_total, conn, max_host, bundle, pnow)) {
        CPOOL_LIMIT_DEST => {
            Curl_infof(data, "No more connections allowed to host");
            return CURLE_NO_CONNECTION_AVAILABLE;
        },
        CPOOL_LIMIT_TOTAL => {
            var multi: ?*CurlMulti = null;
            var multi_admin: ?*CurlEasy = null;
            var mcp: ?*Cpool = null;
            var mcshutdn: ?*Cshutdn = null;
            var max_total_conns: u32 = 0;
            var maxconnects: u32 = 0;
            Curl_easy_get_multi_cpool(data, &multi, &multi_admin, &mcp, &mcshutdn, &max_total_conns, &maxconnects);
            Curl_infof(data, "No connections available, total of %u reached.", max_total_conns);
            return CURLE_NO_CONNECTION_AVAILABLE;
        },
        else => {},
    }

    const capacity = Curl_uint32_tbl_capacity(&cpool.conns);
    if (capacity == std.math.maxInt(u32)) {
        Curl_infof(data, "No connections available, pool at max capacity");
        return CURLE_NO_CONNECTION_AVAILABLE;
    }
    if (Curl_uint32_tbl_count(&cpool.conns) >= capacity) {
        const growth: u32 = @max(capacity, 16);
        const ncapacity: u32 = if ((std.math.maxInt(u32) - growth) >= capacity)
            capacity + growth
        else
            std.math.maxInt(u32);
        if (Curl_uint32_bset_resize(&cpool.idles, ncapacity) != CURLE_OK or
            Curl_uint32_tbl_resize(&cpool.conns, ncapacity) != CURLE_OK)
        {
            return CURLE_OUT_OF_MEMORY;
        }
    }

    if (bundle == null) {
        bundle = cpoolCreateBundle() orelse return CURLE_OUT_OF_MEMORY;
    }

    var cpid: u32 = 0;
    if (!Curl_uint32_tbl_add(&cpool.conns, conn, &cpid)) {
        return CURLE_OUT_OF_MEMORY;
    }
    Curl_conn_set_cpid(conn, cpid);

    if (!cpoolBundleAddId(cpool, bundle.?, dest, cpid)) {
        Curl_uint32_tbl_remove(&cpool.conns, cpid);
        Curl_conn_set_cpid(conn, std.math.maxInt(u32));
        return CURLE_OUT_OF_MEMORY;
    }

    Curl_conn_set_id(conn, cpool.next_connection_id);
    cpool.next_connection_id += 1;
    if (Curl_trc_is_verbose(data)) {
        Curl_trc_multi(
            data,
            "[CPOOL] added connection %lld. The cache now contains %u members",
            @as(c_longlong, Curl_conn_get_id(conn)),
            Curl_uint32_tbl_count(&cpool.conns),
        );
    }
    return result;
}

fn cpoolForeach(
    data: ?*CurlEasy,
    cpool: ?*Cpool,
    param: ?*anyopaque,
    func: *const fn (*Cpool, ?*CurlEasy, *ConnectData, ?*anyopaque) callconv(.c) c_int,
) bool {
    const cp = cpool orelse return false;
    var entry: ?*anyopaque = null;
    var cpid: u32 = 0;
    if (Curl_uint32_tbl_first(&cp.conns, &cpid, &entry)) {
        while (true) {
            if (entry) |e| {
                const conn: *ConnectData = @ptrCast(@alignCast(e));
                if (func(cp, data, conn, param) == 1)
                    return true;
            }
            if (!Curl_uint32_tbl_next(&cp.conns, cpid, &cpid, &entry))
                break;
        }
    }
    return false;
}

fn cpoolConnNowIdle(
    cpool: ?*Cpool,
    data: ?*CurlEasy,
    conn: *ConnectData,
    pnow: *const CurlTime,
) bool {
    var multi: ?*CurlMulti = null;
    var multi_admin: ?*CurlEasy = null;
    var mcp: ?*Cpool = null;
    var mcshutdn: ?*Cshutdn = null;
    var max_total_conns: u32 = 0;
    var multi_maxconnects: u32 = 0;
    Curl_easy_get_multi_cpool(data, &multi, &multi_admin, &mcp, &mcshutdn, &max_total_conns, &multi_maxconnects);

    var kept = true;
    var min_age_ms: i64 = 0;
    if (data == null or multi == null)
        return kept;

    const cp = cpool orelse return kept;
    _ = Curl_uint32_bset_add(&cp.idles, Curl_conn_get_cpid(conn));

    var maxconnects: u32 = 0;
    if (multi_maxconnects == 0) {
        const attached = Curl_multi_xfers_attached(multi);
        maxconnects = if (attached <= std.math.maxInt(u32) / 2) attached * 2 else std.math.maxInt(u32);
        min_age_ms = 1000;
    } else {
        maxconnects = multi_maxconnects;
    }

    if (maxconnects != 0 and maxconnects < std.math.maxInt(u32)) {
        const num_conns = Curl_uint32_tbl_count(&cp.conns);
        const admin = Curl_get_admin(data);
        if (num_conns > maxconnects) {
            Curl_infof(data, "Connection pool is full, closing the oldest of %u/%u", num_conns, maxconnects);
            const oldest_idle = cpoolGetOldestIdle(cp, pnow, min_age_ms);
            kept = (oldest_idle != conn);
            if (oldest_idle) |oi| {
                cpoolEvictConn(cp, admin, oi);
            }
        }
    }
    return kept;
}

fn cpoolFindAct(
    cpool: *Cpool,
    data: ?*CurlEasy,
    conn: *ConnectData,
    match: CpoolMatchResult,
) bool {
    switch (match) {
        .CPOOL_MATCH_FOUND => return true,
        .CPOOL_MATCH_TOO_OLD => {
            if (!cpoolConnCanBeClosed(conn))
                return false;
            cpoolConnClose(cpool, data, conn, false);
        },
        .CPOOL_MATCH_CLOSE => {
            cpoolConnClose(cpool, data, conn, false);
        },
        .CPOOL_MATCH_CONT => {},
    }
    return false;
}

const CpoolReaperCtx = struct {
    reaped: usize = 0,
    pnow: *const CurlTime,
};

fn cpoolReapDeadCb(
    cpool: *Cpool,
    admin: ?*CurlEasy,
    conn: *ConnectData,
    param: ?*anyopaque,
) callconv(.c) c_int {
    const reaper: *CpoolReaperCtx = @ptrCast(@alignCast(param));
    if (cpoolConnCanBeClosed(conn)) {
        if (Curl_conn_is_no_reuse_or_close(conn) or
            !Curl_cpool_conn_seems_healthy(conn, admin, reaper.pnow))
        {
            reaper.reaped += 1;
            cpoolConnClose(cpool, admin, conn, false);
        }
    }
    return 0;
}

fn cpoolPruneDead(
    cpool: *Cpool,
    data: ?*CurlEasy,
    pnow: *const CurlTime,
) void {
    const elapsed_ms = curlx_ptimediff_ms(pnow, &cpool.last_cleanup);
    if (elapsed_ms >= 1000) {
        const admin = Curl_get_admin(data);
        var reaper = CpoolReaperCtx{ .reaped = 0, .pnow = pnow };
        _ = cpoolForeach(admin, cpool, &reaper, cpoolReapDeadCb);
        cpool.last_cleanup = pnow.*;
    }
}

pub export fn Curl_cpool_find_zig(
    data: ?*CurlEasy,
    destination: [*:0]const u8,
    prune_dead: bool,
    pnow: *const CurlTime,
    conn_cb: CurlCpoolConnMatchCb,
    done_cb: CurlCpoolDoneMatchCb,
    userdata: ?*anyopaque,
    cpool_arg: ?*Cpool,
    p_last_conn_id: *i64,
    p_last_cpid: *u32,
) callconv(.c) bool {
    const cpool = cpool_arg orelse return false;
    var bundle: ?*CpoolBundle = null;
    var found = false;

    cpoolLock(cpool, data);
    defer {
        cpoolBundleUnlink(&bundle);
        cpoolUnlock(cpool, data);
    }

    if (prune_dead)
        cpoolPruneDead(cpool, data, pnow);

    if (p_last_cpid.* != std.math.maxInt(u32)) {
        const conn = Curl_uint32_tbl_get(&cpool.conns, p_last_cpid.*);
        if (conn != null and p_last_conn_id.* == Curl_conn_get_id(conn.?)) {
            found = cpoolFindAct(cpool, data, conn.?, conn_cb(conn.?, userdata));
            if (found) {
                if (done_cb) |dcb| found = dcb(userdata);
                return found;
            }
        } else {
            p_last_conn_id.* = -1;
            p_last_cpid.* = std.math.maxInt(u32);
        }
    }

    bundle = cpoolGetBundle(cpool, destination);
    if (bundle) |b| {
        var cpid: u32 = 0;
        if (Curl_uint32_spbset_first(&b.ids, &cpid)) {
            while (true) {
                if (Curl_uint32_tbl_get(&cpool.conns, cpid)) |conn| {
                    if (p_last_conn_id.* != Curl_conn_get_id(conn)) {
                        found = cpoolFindAct(cpool, data, conn, conn_cb(conn, userdata));
                        if (found)
                            break;
                    }
                } else {
                    Curl_uint32_spbset_remove(&b.ids, cpid);
                }
                if (!Curl_uint32_spbset_next(&b.ids, cpid, &cpid))
                    break;
            }
        }
    }

    if (done_cb) |dcb| {
        found = dcb(userdata);
    }
    return found;
}

fn connUpkeep(
    cpool: *Cpool,
    admin: ?*CurlEasy,
    conn: *ConnectData,
    param: ?*anyopaque,
) callconv(.c) c_int {
    _ = param;
    const pnow = Curl_pgrs_now_zig(admin, Curl_easy_progress(admin));
    var max_idle_ms: i64 = 0;
    var max_age_ms: i64 = 0;
    var upkeep_interval_ms: i64 = 0;
    Curl_easy_get_conn_age_limits(admin, &max_idle_ms, &max_age_ms, &upkeep_interval_ms);

    const age_ms = curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn));
    if ((age_ms - Curl_conn_get_lastupkeep_ms(conn)) >= upkeep_interval_ms) {
        Curl_conn_set_lastupkeep_ms(conn, age_ms);
        Curl_attach_connection(admin, conn, false);
        const cfilters = Curl_conn_get_cfilters(conn);
        const result = Curl_conn_keep_alive_zig(admin, conn, cfilters, null);
        Curl_detach_connection(admin);

        if (result != CURLE_OK and cpoolConnCanBeClosed(conn)) {
            cpoolConnClose(cpool, admin, conn, false);
        }
    }
    return 0;
}

pub export fn Curl_cpool_upkeep_zig(
    data: ?*CurlEasy,
    cpool_arg: ?*Cpool,
) callconv(.c) CURLcode {
    const cpool = cpool_arg orelse return CURLE_OK;
    const admin = Curl_get_admin(data);
    cpoolLock(cpool, admin);
    _ = cpoolForeach(admin, cpool, null, connUpkeep);
    cpoolUnlock(cpool, admin);
    return CURLE_OK;
}

pub export fn Curl_cpool_get_last_conn_zig(
    data: ?*CurlEasy,
    cpool_arg: ?*Cpool,
    p_last_conn_id: *i64,
    p_last_cpid: *u32,
) callconv(.c) ?*ConnectData {
    if (cpool_arg) |cpool| {
        if (p_last_cpid.* != std.math.maxInt(u32)) {
            cpoolLock(cpool, data);
            const conn = Curl_uint32_tbl_get(&cpool.conns, p_last_cpid.*);
            cpoolUnlock(cpool, data);
            if (conn != null and p_last_conn_id.* == Curl_conn_get_id(conn.?))
                return conn;
            p_last_cpid.* = std.math.maxInt(u32);
            p_last_conn_id.* = -1;
        }
    }
    return null;
}

pub export fn Curl_cpool_return_zig(
    data: ?*CurlEasy,
    conn: *ConnectData,
    cb: CurlCpoolReturnCb,
    cbdata: ?*anyopaque,
    pnow: *const CurlTime,
    cpool: ?*Cpool,
    p_last_conn_id: *i64,
    p_last_cpid: *u32,
) callconv(.c) void {
    cpoolLock(cpool, data);

    const age_ms = curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn));
    Curl_conn_set_return_times(conn, age_ms);

    switch (cb(data, conn, cbdata, pnow)) {
        .CPOOL_DO_KEEP => {},
        .CPOOL_DO_IDLE => {
            if (cpoolConnNowIdle(cpool, data, conn, pnow)) {
                var user_hostname: ?[*:0]const u8 = null;
                var port: u16 = 0;
                Curl_conn_get_origin_info(conn, &user_hostname, &port);
                Curl_infof(
                    data,
                    "Connection #%lld to host %s:%u left intact",
                    @as(c_longlong, Curl_conn_get_id(conn)),
                    user_hostname orelse "",
                    @as(c_uint, port),
                );
            } else {
                p_last_conn_id.* = -1;
                p_last_cpid.* = std.math.maxInt(u32);
            }
        },
        .CPOOL_DO_CLOSE => {
            cpoolConnClose(cpool, data, conn, false);
        },
        .CPOOL_DO_TERMINATE => {
            cpoolConnClose(cpool, data, conn, true);
        },
    }

    cpoolUnlock(cpool, data);
}

fn cpoolReapNoReuse(
    cpool: *Cpool,
    admin: ?*CurlEasy,
    conn: *ConnectData,
    param: ?*anyopaque,
) callconv(.c) c_int {
    _ = param;
    Curl_conn_set_no_reuse(conn, true);
    if (cpoolConnCanBeClosed(conn))
        cpoolConnClose(cpool, admin, conn, false);
    return 0;
}

pub export fn Curl_cpool_nw_changed(
    cpool: ?*Cpool,
    admin: ?*CurlEasy,
) callconv(.c) void {
    if (cpool != null and admin != null) {
        cpoolLock(cpool, admin);
        _ = cpoolForeach(admin, cpool, null, cpoolReapNoReuse);
        cpoolUnlock(cpool, admin);
    }
}

fn cpoolConnTooOld(
    data: ?*CurlEasy,
    conn: *ConnectData,
    pnow: *const CurlTime,
) bool {
    var max_idle_ms: i64 = 0;
    var max_age_ms: i64 = 0;
    var upkeep_interval_ms: i64 = 0;
    Curl_easy_get_conn_age_limits(data, &max_idle_ms, &max_age_ms, &upkeep_interval_ms);

    if (max_idle_ms != 0) {
        const age_ms = curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn)) - Curl_conn_get_lastused_ms(conn);
        if (age_ms > max_idle_ms) {
            Curl_infof(
                data,
                "Too old connection (%lld ms idle, max idle is %lld ms), disconnect it",
                @as(c_longlong, age_ms),
                @as(c_longlong, max_idle_ms),
            );
            return true;
        }
    }

    if (max_age_ms != 0) {
        const age_ms = curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn));
        if (age_ms > max_age_ms) {
            Curl_infof(
                data,
                "Too old connection (created %lld ms ago, max lifetime is %lld ms), disconnect it",
                @as(c_longlong, age_ms),
                @as(c_longlong, max_age_ms),
            );
            return true;
        }
    }

    return false;
}

pub export fn Curl_cpool_conn_seems_healthy(
    conn: *ConnectData,
    data: ?*CurlEasy,
    pnow: *const CurlTime,
) callconv(.c) bool {
    if (cpoolConnCanBeClosed(conn) and cpoolConnTooOld(data, conn, pnow))
        return false;

    const cfilters = Curl_conn_get_cfilters(conn);
    const has_dead_cb = Curl_conn_has_dead_cb(conn);
    const poll_input = cpoolConnCanBeClosed(conn) and
        !Curl_conn_is_multiplex_zig(conn, FIRSTSOCKET, cfilters) and
        !has_dead_cb;
    const elapsed_check_ms = curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn)) - Curl_conn_get_lastchecked_ms(conn);
    if (!poll_input and elapsed_check_ms < 1000)
        return true;

    const admin = Curl_get_admin(data);
    var healthy = true;
    if (has_dead_cb) {
        Curl_attach_connection(admin, conn, false);
        healthy = !Curl_conn_call_dead_cb(admin, conn);
        Curl_detach_connection(admin);
    } else {
        var input_pending = false;
        Curl_attach_connection(admin, conn, false);
        healthy = Curl_conn_is_alive_zig(admin, conn, &input_pending, cfilters, Curl_conn_is_close(conn));
        Curl_detach_connection(admin);
        if (healthy and input_pending and poll_input) {
            healthy = false;
        }
    }

    if (healthy) {
        Curl_conn_set_lastchecked_ms(conn, curlx_ptimediff_ms(pnow, Curl_conn_get_created(conn)));
    }
    return healthy;
}

pub export fn Curl_cpool_conn_was_used_zig(
    data: ?*CurlEasy,
    conn: *ConnectData,
    pnow: *const CurlTime,
    conn_created: *const CurlTime,
    p_lastupkeep_ms: *i64,
) callconv(.c) void {
    _ = data;
    _ = conn;
    p_lastupkeep_ms.* = curlx_ptimediff_ms(pnow, conn_created);
}

pub export fn Curl_cpool_conn_age_ms_zig(
    data: ?*CurlEasy,
    conn: *ConnectData,
    pnow: *const CurlTime,
    conn_created: *const CurlTime,
) callconv(.c) i64 {
    _ = data;
    _ = conn;
    return curlx_ptimediff_ms(pnow, conn_created);
}

// ============================================================================
// Unit Tests
// ============================================================================

test "time2str formats durations" {
    var buf: [16]u8 = undefined;
    time2str(&buf, buf.len, 0);
    try std.testing.expectEqualStrings("       ", std.mem.sliceTo(&buf, 0));

    time2str(&buf, buf.len, 65);
    try std.testing.expectEqualStrings("  01:05", std.mem.sliceTo(&buf, 0));

    time2str(&buf, buf.len, 3661);
    try std.testing.expectEqualStrings("1:01:01", std.mem.sliceTo(&buf, 0));

    time2str(&buf, buf.len, 100 * 3600);
    try std.testing.expectEqualStrings(" 4d 04h", std.mem.sliceTo(&buf, 0));
}

test "max6out formats byte counts" {
    var buf: [16]u8 = undefined;
    _ = max6out(42, &buf, buf.len);
    try std.testing.expectEqualStrings("    42", std.mem.sliceTo(&buf, 0));

    _ = max6out(204800, &buf, buf.len);
    try std.testing.expectEqualStrings("200.0k", std.mem.sliceTo(&buf, 0));
}

test "Curl_socktype_for_transport and Curl_protocol_for_transport" {
    try std.testing.expectEqual(SOCK_STREAM, Curl_socktype_for_transport(TRNSPRT_TCP));
    try std.testing.expectEqual(SOCK_STREAM, Curl_socktype_for_transport(TRNSPRT_UNIX));
    try std.testing.expectEqual(SOCK_DGRAM, Curl_socktype_for_transport(4));
    try std.testing.expectEqual(IPPROTO_TCP, Curl_protocol_for_transport(TRNSPRT_TCP));
    try std.testing.expectEqual(IPPROTO_IP, Curl_protocol_for_transport(TRNSPRT_UNIX));
    try std.testing.expectEqual(IPPROTO_UDP, Curl_protocol_for_transport(4));
}

test "Progress bitflags and size setters" {
    var p = std.mem.zeroes(Progress);
    Curl_pgrsSetDownloadSize_zig(null, 1024, &p);
    try std.testing.expect(p.isDlSizeKnown());
    try std.testing.expectEqual(@as(i64, 1024), p.dl.total_size);

    Curl_pgrsResetTransferSizes_zig(null, &p);
    try std.testing.expect(!p.isDlSizeKnown());
    try std.testing.expectEqual(@as(i64, 0), p.dl.total_size);
}

// ============================================================================
// C-Zig ABI & Struct Layout Verification
// ============================================================================

comptime {
    std.debug.assert(@sizeOf(CurlCfilter) == 40);
    std.debug.assert(@alignOf(CurlCfilter) == 8);
    std.debug.assert(@offsetOf(CurlCfilter, "cft") == 0);
    std.debug.assert(@offsetOf(CurlCfilter, "next") == 8);
    std.debug.assert(@offsetOf(CurlCfilter, "ctx") == 16);
    std.debug.assert(@offsetOf(CurlCfilter, "conn") == 24);
    std.debug.assert(@offsetOf(CurlCfilter, "sockindex") == 32);

    std.debug.assert(@sizeOf(CurlCftype) == 104);
    std.debug.assert(@alignOf(CurlCftype) == 8);
    std.debug.assert(@offsetOf(CurlCftype, "name") == 0);
    std.debug.assert(@offsetOf(CurlCftype, "flags") == 8);
    std.debug.assert(@offsetOf(CurlCftype, "log_level") == 12);
    std.debug.assert(@offsetOf(CurlCftype, "destroy") == 16);
    std.debug.assert(@offsetOf(CurlCftype, "do_connect") == 24);
    std.debug.assert(@offsetOf(CurlCftype, "do_shutdown") == 32);
    std.debug.assert(@offsetOf(CurlCftype, "adjust_pollset") == 40);
    std.debug.assert(@offsetOf(CurlCftype, "has_data_pending") == 48);
    std.debug.assert(@offsetOf(CurlCftype, "do_send") == 56);
    std.debug.assert(@offsetOf(CurlCftype, "do_recv") == 64);
    std.debug.assert(@offsetOf(CurlCftype, "cntrl") == 72);
    std.debug.assert(@offsetOf(CurlCftype, "is_alive") == 80);
    std.debug.assert(@offsetOf(CurlCftype, "keep_alive") == 88);
    std.debug.assert(@offsetOf(CurlCftype, "query") == 96);

    std.debug.assert(@sizeOf(CurlCwtype) == 64);
    std.debug.assert(@alignOf(CurlCwtype) == 8);
    std.debug.assert(@offsetOf(CurlCwtype, "name") == 0);
    std.debug.assert(@offsetOf(CurlCwtype, "alias") == 8);
    std.debug.assert(@offsetOf(CurlCwtype, "flags") == 16);
    std.debug.assert(@offsetOf(CurlCwtype, "do_init") == 24);
    std.debug.assert(@offsetOf(CurlCwtype, "do_write") == 32);
    std.debug.assert(@offsetOf(CurlCwtype, "do_flush") == 40);
    std.debug.assert(@offsetOf(CurlCwtype, "do_close") == 48);
    std.debug.assert(@offsetOf(CurlCwtype, "cwriter_size") == 56);

    std.debug.assert(@sizeOf(CurlCwriter) == 32);
    std.debug.assert(@alignOf(CurlCwriter) == 8);
    std.debug.assert(@offsetOf(CurlCwriter, "cwt") == 0);
    std.debug.assert(@offsetOf(CurlCwriter, "next") == 8);
    std.debug.assert(@offsetOf(CurlCwriter, "ctx") == 16);
    std.debug.assert(@offsetOf(CurlCwriter, "phase") == 24);

    std.debug.assert(@sizeOf(Progress) == 472);
    std.debug.assert(@alignOf(Progress) == 8);
    std.debug.assert(@offsetOf(Progress, "now") == 0);
    std.debug.assert(@offsetOf(Progress, "start") == 16);
    std.debug.assert(@offsetOf(Progress, "ul") == 32);
    std.debug.assert(@offsetOf(Progress, "dl") == 136);
    std.debug.assert(@offsetOf(Progress, "deliver") == 240);
    std.debug.assert(@offsetOf(Progress, "current_speed") == 248);
    std.debug.assert(@offsetOf(Progress, "earlydata_sent") == 256);
    std.debug.assert(@offsetOf(Progress, "delta") == 264);
    std.debug.assert(@offsetOf(Progress, "total") == 304);
    std.debug.assert(@offsetOf(Progress, "speed_amount") == 368);
    std.debug.assert(@offsetOf(Progress, "speed_time") == 416);
    std.debug.assert(@offsetOf(Progress, "speeder_c") == 464);
    std.debug.assert(@offsetOf(Progress, "flags") == 468);

    std.debug.assert(@sizeOf(Cpool) == 128);
    std.debug.assert(@alignOf(Cpool) == 8);
    std.debug.assert(@offsetOf(Cpool, "conns") == 0);
    std.debug.assert(@offsetOf(Cpool, "idles") == 24);
    std.debug.assert(@offsetOf(Cpool, "dest2bundle") == 40);
    std.debug.assert(@offsetOf(Cpool, "next_connection_id") == 80);
    std.debug.assert(@offsetOf(Cpool, "next_easy_id") == 88);
    std.debug.assert(@offsetOf(Cpool, "last_cleanup") == 96);
    std.debug.assert(@offsetOf(Cpool, "share") == 112);
}

extern fn Curl_zig_abi_sizeof_cfilter() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cftype() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cwtype() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cwriter() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_progress() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cpool() callconv(.c) usize;

test "C-Zig ABI struct sizes in cfilters_progress" {
    try std.testing.expectEqual(@sizeOf(CurlCfilter), Curl_zig_abi_sizeof_cfilter());
    try std.testing.expectEqual(@sizeOf(CurlCftype), Curl_zig_abi_sizeof_cftype());
    try std.testing.expectEqual(@sizeOf(CurlCwtype), Curl_zig_abi_sizeof_cwtype());
    try std.testing.expectEqual(@sizeOf(CurlCwriter), Curl_zig_abi_sizeof_cwriter());
    try std.testing.expectEqual(@sizeOf(Progress), Curl_zig_abi_sizeof_progress());
    try std.testing.expectEqual(@sizeOf(Cpool), Curl_zig_abi_sizeof_cpool());
}
