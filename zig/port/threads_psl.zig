const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const curlx_time_net = @import("curlx_time_net.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_UNRECOVERABLE_POLL: CURLcode = 99;

pub const timediff_t = curlx_time_net.timediff_t;
pub const Curltime = curlx_time_net.Curltime;
pub const Curl_llist = containers.Curl_llist;
pub const Curl_llist_node = containers.Curl_llist_node;

// ============================================================================
// 1. lib/curl_threads.c (lib/curl_threads.h)
// ============================================================================

pub const CurlMutex = extern struct {
    data: [8]u64 align(16) = @splat(0),
};

pub const CurlCond = extern struct {
    data: [8]u64 align(16) = @splat(0),
};

pub const ThreadReturn = if (builtin.os.tag == .windows) u32 else c_uint;
pub const thread_cc: std.builtin.CallingConvention = if (builtin.os.tag == .windows) .winapi else .c;

pub const ThreadFunc = *const fn (?*anyopaque) callconv(thread_cc) ThreadReturn;

pub const curl_thread_t = if (builtin.os.tag == .windows)
    ?*anyopaque
else
    ?*usize;

pub const curl_thread_id_t = if (builtin.os.tag == .windows)
    u32
else
    usize;

const win32 = struct {
    const INFINITE: u32 = 0xFFFFFFFF;
    const WAIT_OBJECT_0: u32 = 0;
    const ERROR_ACCESS_DENIED: u32 = 5;
    const ERROR_NOT_ENOUGH_MEMORY: u32 = 8;
    const ERROR_TIMEOUT: u32 = 1460;
    const EACCES: c_int = 13;
    const EINVAL: c_int = 22;

    extern "kernel32" fn CreateThread(
        lpThreadAttributes: ?*anyopaque,
        dwStackSize: usize,
        lpStartAddress: ThreadFunc,
        lpParameter: ?*anyopaque,
        dwCreationFlags: u32,
        lpThreadId: ?*u32,
    ) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn CloseHandle(hObject: *anyopaque) callconv(.winapi) c_int;
    extern "kernel32" fn WaitForSingleObjectEx(
        hHandle: ?*anyopaque,
        dwMilliseconds: u32,
        bAlertable: c_int,
    ) callconv(.winapi) u32;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn GetCurrentThreadId() callconv(.winapi) u32;
    extern "kernel32" fn InitializeCriticalSectionEx(
        lpCriticalSection: *anyopaque,
        dwSpinCount: u32,
        Flags: u32,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn EnterCriticalSection(lpCriticalSection: *anyopaque) callconv(.winapi) void;
    extern "kernel32" fn LeaveCriticalSection(lpCriticalSection: *anyopaque) callconv(.winapi) void;
    extern "kernel32" fn DeleteCriticalSection(lpCriticalSection: *anyopaque) callconv(.winapi) void;
    extern "kernel32" fn InitializeConditionVariable(ConditionVariable: *anyopaque) callconv(.winapi) void;
    extern "kernel32" fn WakeConditionVariable(ConditionVariable: *anyopaque) callconv(.winapi) void;
    extern "kernel32" fn SleepConditionVariableCS(
        ConditionVariable: *anyopaque,
        CriticalSection: *anyopaque,
        dwMilliseconds: u32,
    ) callconv(.winapi) c_int;
    extern "c" fn _errno() callconv(.c) *c_int;
};

const posix = struct {
    extern "c" fn pthread_create(
        thread: *usize,
        attr: ?*const anyopaque,
        start_routine: *const fn (?*anyopaque) callconv(.c) ?*anyopaque,
        arg: ?*anyopaque,
    ) c_int;
    extern "c" fn pthread_detach(thread: usize) c_int;
    extern "c" fn pthread_join(thread: usize, retval: ?*?*anyopaque) c_int;
    extern "c" fn pthread_self() usize;
    extern "c" fn pthread_equal(t1: usize, t2: usize) c_int;
    extern "c" fn pthread_mutex_init(mutex: *anyopaque, attr: ?*const anyopaque) c_int;
    extern "c" fn pthread_mutex_lock(mutex: *anyopaque) c_int;
    extern "c" fn pthread_mutex_unlock(mutex: *anyopaque) c_int;
    extern "c" fn pthread_mutex_destroy(mutex: *anyopaque) c_int;
    extern "c" fn pthread_cond_init(cond: *anyopaque, attr: ?*const anyopaque) c_int;
    extern "c" fn pthread_cond_destroy(cond: *anyopaque) c_int;
    extern "c" fn pthread_cond_signal(cond: *anyopaque) c_int;
    extern "c" fn pthread_cond_wait(cond: *anyopaque, mutex: *anyopaque) c_int;
    extern "c" fn pthread_cond_timedwait(
        cond: *anyopaque,
        mutex: *anyopaque,
        abstime: *const std.c.timespec,
    ) c_int;
};

pub inline fn mutexInit(m: *CurlMutex) void {
    if (builtin.os.tag == .windows) {
        _ = win32.InitializeCriticalSectionEx(m, 0, 1);
    } else {
        _ = posix.pthread_mutex_init(m, null);
    }
}

pub inline fn mutexAcquire(m: *CurlMutex) void {
    if (builtin.os.tag == .windows) {
        win32.EnterCriticalSection(m);
    } else {
        _ = posix.pthread_mutex_lock(m);
    }
}

pub inline fn mutexRelease(m: *CurlMutex) void {
    if (builtin.os.tag == .windows) {
        win32.LeaveCriticalSection(m);
    } else {
        _ = posix.pthread_mutex_unlock(m);
    }
}

pub inline fn mutexDestroy(m: *CurlMutex) void {
    if (builtin.os.tag == .windows) {
        win32.DeleteCriticalSection(m);
    } else {
        _ = posix.pthread_mutex_destroy(m);
    }
}

pub inline fn condInit(c: *CurlCond) void {
    if (builtin.os.tag == .windows) {
        win32.InitializeConditionVariable(c);
    } else {
        _ = posix.pthread_cond_init(c, null);
    }
}

pub inline fn condDestroy(c: *CurlCond) void {
    if (builtin.os.tag != .windows) {
        _ = posix.pthread_cond_destroy(c);
    }
}

const CurlActualCall = extern struct {
    func: ThreadFunc,
    arg: ?*anyopaque,
};

fn curlThreadCreateThunk(arg: ?*anyopaque) callconv(.c) ?*anyopaque {
    const ac: *CurlActualCall = @ptrCast(@alignCast(arg.?));
    const func = ac.func;
    const real_arg = ac.arg;

    mem.free(ac);
    _ = func(real_arg);
    return null;
}

pub export fn Curl_thread_create(func: ?ThreadFunc, arg: ?*anyopaque) callconv(.c) curl_thread_t {
    const f = func orelse return null;
    if (builtin.os.tag == .windows) {
        const t = win32.CreateThread(null, 0, f, arg, 0, null);
        if (t == null) {
            const gle = win32.GetLastError();
            win32._errno().* = if (gle == win32.ERROR_ACCESS_DENIED or gle == win32.ERROR_NOT_ENOUGH_MEMORY)
                win32.EACCES
            else
                win32.EINVAL;
            return null;
        }
        return t;
    } else {
        const t_raw = mem.malloc(@sizeOf(usize));
        var ac_raw: ?[*]u8 = null;
        if (t_raw != null) {
            ac_raw = mem.malloc(@sizeOf(CurlActualCall));
        }
        if (t_raw == null or ac_raw == null) {
            mem.free(t_raw);
            mem.free(ac_raw);
            return null;
        }
        const t: *usize = @ptrCast(@alignCast(t_raw.?));
        const ac: *CurlActualCall = @ptrCast(@alignCast(ac_raw.?));
        ac.func = f;
        ac.arg = arg;

        const rc = posix.pthread_create(t, null, &curlThreadCreateThunk, ac);
        if (rc != 0) {
            std.c._errno().* = rc;
            mem.free(t_raw);
            mem.free(ac_raw);
            return null;
        }
        return t;
    }
}

pub export fn Curl_thread_destroy(hnd: ?*curl_thread_t) callconv(.c) void {
    const h = hnd orelse return;
    if (builtin.os.tag == .windows) {
        if (h.*) |t| {
            _ = win32.CloseHandle(t);
            h.* = null;
        }
    } else {
        if (h.*) |t| {
            _ = posix.pthread_detach(t.*);
            mem.free(t);
            h.* = null;
        }
    }
}

pub export fn Curl_thread_join(hnd: ?*curl_thread_t) callconv(.c) c_int {
    const h = hnd orelse return 0;
    if (builtin.os.tag == .windows) {
        const ret: c_int = @intFromBool(win32.WaitForSingleObjectEx(h.*, win32.INFINITE, 0) == win32.WAIT_OBJECT_0);
        Curl_thread_destroy(h);
        return ret;
    } else {
        const t = h.* orelse return 0;
        const ret: c_int = @intFromBool(posix.pthread_join(t.*, null) == 0);
        mem.free(t);
        h.* = null;
        return ret;
    }
}

pub export fn Curl_cond_signal(c: *anyopaque) callconv(.c) void {
    if (builtin.os.tag == .windows) {
        win32.WakeConditionVariable(c);
    } else {
        _ = posix.pthread_cond_signal(c);
    }
}

pub export fn Curl_cond_wait(c: *anyopaque, m: *anyopaque) callconv(.c) void {
    if (builtin.os.tag == .windows) {
        _ = win32.SleepConditionVariableCS(c, m, win32.INFINITE);
    } else {
        _ = posix.pthread_cond_wait(c, m);
    }
}

pub export fn Curl_cond_timedwait(c: *anyopaque, m: *anyopaque, timeout_ms: u32) callconv(.c) CURLcode {
    if (builtin.os.tag == .windows) {
        if (win32.SleepConditionVariableCS(c, m, timeout_ms) == 0) {
            const err = win32.GetLastError();
            return if (err == win32.ERROR_TIMEOUT) CURLE_OPERATION_TIMEDOUT else CURLE_UNRECOVERABLE_POLL;
        }
        return CURLE_OK;
    } else {
        var tv: std.c.timeval = undefined;
        _ = std.c.gettimeofday(&tv, null);
        const now_sec = tv.sec;
        const now_usec: timediff_t = @intCast(tv.usec);

        var ts: std.c.timespec = undefined;
        ts.sec = now_sec + @as(@TypeOf(now_sec), @intCast(timeout_ms / 1000));
        var usec: timediff_t = now_usec + @as(timediff_t, @intCast(timeout_ms % 1000)) * 1000;
        if (usec >= 1_000_000) {
            ts.sec += 1;
            usec = @rem(usec, 1_000_000);
        }
        ts.nsec = @intCast(usec * 1000);

        const rc = posix.pthread_cond_timedwait(c, m, &ts);
        if (rc == @backingInt(std.c.E.TIMEDOUT)) {
            return CURLE_OPERATION_TIMEDOUT;
        }
        return if (rc != 0) CURLE_UNRECOVERABLE_POLL else CURLE_OK;
    }
}

pub export fn Curl_thread_get_current_id() callconv(.c) curl_thread_id_t {
    if (builtin.os.tag == .windows) {
        return win32.GetCurrentThreadId();
    } else {
        return posix.pthread_self();
    }
}

pub export fn Curl_thread_is_current(tid: curl_thread_id_t) callconv(.c) bool {
    if (builtin.os.tag == .windows) {
        return tid == win32.GetCurrentThreadId();
    } else {
        return posix.pthread_equal(tid, posix.pthread_self()) != 0;
    }
}

// ============================================================================
// 2. lib/thrdpool.c (lib/thrdpool.h)
// ============================================================================

pub const Curl_thrdpool_take_item_cb = *const fn (
    user_data: ?*anyopaque,
    pdescription: *?[*:0]const u8,
    ptimeout_ms: *timediff_t,
) callconv(.c) ?*anyopaque;

pub const Curl_thrdpool_process_item_cb = *const fn (item: ?*anyopaque) callconv(.c) void;

pub const Curl_thrdpool_return_item_cb = *const fn (
    item: ?*anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) void;

const thrdslot = extern struct {
    node: Curl_llist_node,
    tpool: *curl_thrdpool,
    thread: curl_thread_t,
    await_cond: CurlCond,
    starttime: Curltime,
    work_description: ?[*:0]const u8,
    work_timeout_ms: timediff_t,
    id: u32,
    running: bool,
    idle: bool,
};

pub const curl_thrdpool = extern struct {
    name: ?[*:0]const u8,
    refcount: u64,
    lock: CurlMutex,
    await_cond: CurlCond,
    slots: Curl_llist,
    zombies: Curl_llist,
    fn_take: Curl_thrdpool_take_item_cb,
    fn_process: Curl_thrdpool_process_item_cb,
    fn_return: Curl_thrdpool_return_item_cb,
    fn_user_data: ?*anyopaque,
    fatal_err: CURLcode,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
    next_id: u32,
    aborted: bool,
    detached: bool,
};

pub const CurlTrcFeat = extern struct {
    name: [*:0]const u8,
    log_level: c_int,
};

const CURL_LOG_LVL_INFO: c_int = 1;

const libcurl_trc = struct {
    extern var Curl_trc_feat_threads: CurlTrcFeat;
    extern fn Curl_trc_feat_infof(data: ?*anyopaque, feat: *CurlTrcFeat, fmt: [*:0]const u8, ...) callconv(.c) void;
};

fn thrdslotDestroy(tslot: *thrdslot) void {
    condDestroy(&tslot.await_cond);
    mem.free(tslot);
}

fn thrdslotDone(tslot: *thrdslot) void {
    const tpool = tslot.tpool;
    containers.Curl_node_remove(&tslot.node);
    tslot.running = false;
    containers.Curl_llist_append(&tpool.zombies, tslot, &tslot.node);
    Curl_cond_signal(&tpool.await_cond);
}

fn thrdslotRun(arg: ?*anyopaque) callconv(thread_cc) ThreadReturn {
    const tslot: *thrdslot = @ptrCast(@alignCast(arg.?));
    const tpool = tslot.tpool;

    mutexAcquire(&tpool.lock);
    outer: while (true) {
        while (!tpool.aborted) {
            tslot.work_description = null;
            tslot.work_timeout_ms = 0;
            const item = tpool.fn_take(
                tpool.fn_user_data,
                &tslot.work_description,
                &tslot.work_timeout_ms,
            ) orelse break;
            tslot.starttime = curlx_time_net.curlx_now();
            tslot.idle = false;
            mutexRelease(&tpool.lock);

            tpool.fn_process(item);

            mutexAcquire(&tpool.lock);
            tslot.work_description = null;
            tpool.fn_return(item, if (tpool.aborted) null else tpool.fn_user_data);
        }

        if (tpool.aborted or containers.Curl_llist_count(&tpool.slots) > tpool.max_threads) {
            break :outer;
        }

        tslot.idle = true;
        tslot.starttime = curlx_time_net.curlx_now();
        thrdpoolJoinZombies(tpool);
        Curl_cond_signal(&tpool.await_cond);

        if (tpool.idle_time_ms > 0 and containers.Curl_llist_count(&tpool.slots) > tpool.min_threads) {
            const result = Curl_cond_timedwait(&tslot.await_cond, &tpool.lock, tpool.idle_time_ms);
            if (result == CURLE_OPERATION_TIMEDOUT and
                containers.Curl_llist_count(&tpool.slots) > tpool.min_threads)
            {
                break :outer;
            }
        } else {
            Curl_cond_wait(&tslot.await_cond, &tpool.lock);
        }
    }

    thrdslotDone(tslot);
    if (!thrdpoolUnlink(tslot.tpool, true)) {
        mutexRelease(&tpool.lock);
    }
    return 0;
}

fn thrdslotStart(tpool: *curl_thrdpool) CURLcode {
    const raw = mem.calloc(1, @sizeOf(thrdslot)) orelse return CURLE_OUT_OF_MEMORY;
    const tslot: *thrdslot = @ptrCast(@alignCast(raw));
    tslot.id = tpool.next_id;
    tpool.next_id +%= 1;
    tslot.tpool = tpool;
    tslot.thread = null;
    condInit(&tslot.await_cond);

    tpool.refcount += 1;
    tslot.running = true;
    tslot.thread = Curl_thread_create(&thrdslotRun, tslot);
    if (tslot.thread == null) {
        tslot.running = false;
        _ = thrdpoolUnlink(tpool, true);
        thrdslotDestroy(tslot);
        return CURLE_FAILED_INIT;
    }

    containers.Curl_llist_append(&tpool.slots, tslot, &tslot.node);
    return CURLE_OK;
}

fn thrdpoolWakeAll(tpool: *curl_thrdpool) void {
    var e = containers.Curl_llist_head(&tpool.slots);
    while (e) |node| : (e = containers.Curl_node_next(node)) {
        const tslot: *thrdslot = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        Curl_cond_signal(&tslot.await_cond);
    }
}

fn thrdpoolJoinZombies(tpool: *curl_thrdpool) void {
    while (containers.Curl_llist_head(&tpool.zombies)) |e| {
        const tslot: *thrdslot = @ptrCast(@alignCast(containers.Curl_node_elem(e).?));
        containers.Curl_node_remove(&tslot.node);
        if (tslot.thread != null) {
            mutexRelease(&tpool.lock);
            _ = Curl_thread_join(&tslot.thread);
            mutexAcquire(&tpool.lock);
            tslot.thread = null;
        }
        thrdslotDestroy(tslot);
    }
}

fn thrdpoolUnlink(tpool: *curl_thrdpool, locked: bool) bool {
    if (tpool.refcount > 0) {
        tpool.refcount -= 1;
    }
    if (tpool.refcount > 0) {
        return false;
    }

    thrdpoolJoinZombies(tpool);
    if (locked) {
        mutexRelease(&tpool.lock);
    }
    condDestroy(&tpool.await_cond);
    mutexDestroy(&tpool.lock);
    mem.free(tpool);
    return true;
}

fn thrdpoolSignal(tpool: *curl_thrdpool, nthreads_in: u32) CURLcode {
    var nthreads = nthreads_in;
    var result: CURLcode = CURLE_OK;

    thrdpoolJoinZombies(tpool);

    var e = containers.Curl_llist_head(&tpool.slots);
    while (e != null and nthreads > 0) {
        const node = e.?;
        const n = containers.Curl_node_next(node);
        const tslot: *thrdslot = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        if (tslot.idle) {
            Curl_cond_signal(&tslot.await_cond);
            nthreads -= 1;
        } else if (tslot.starttime.tv_sec == 0 and tslot.starttime.tv_usec == 0) {
            nthreads -= 1;
        }
        e = n;
    }

    while (nthreads > 0 and result == CURLE_OK and
        containers.Curl_llist_count(&tpool.slots) < tpool.max_threads)
    {
        result = thrdslotStart(tpool);
        if (result != CURLE_OK) break;
        nthreads -= 1;
    }

    return result;
}

pub export fn Curl_thrdpool_set_props(
    tpool: *curl_thrdpool,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (max_threads == 0 or min_threads > max_threads) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    mutexAcquire(&tpool.lock);
    tpool.min_threads = min_threads;
    tpool.max_threads = max_threads;
    tpool.idle_time_ms = idle_time_ms;
    const running = containers.Curl_llist_count(&tpool.slots);
    if (tpool.min_threads > running) {
        result = thrdpoolSignal(tpool, tpool.min_threads - @as(u32, @intCast(running)));
    }
    mutexRelease(&tpool.lock);

    return result;
}

pub export fn Curl_thrdpool_create(
    ptpool: *?*curl_thrdpool,
    name: ?[*:0]const u8,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
    fn_take: Curl_thrdpool_take_item_cb,
    fn_process: Curl_thrdpool_process_item_cb,
    fn_return: Curl_thrdpool_return_item_cb,
    user_data: ?*anyopaque,
) callconv(.c) CURLcode {
    const raw = mem.calloc(1, @sizeOf(curl_thrdpool)) orelse {
        ptpool.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    var tpool: ?*curl_thrdpool = @ptrCast(@alignCast(raw));
    const tp = tpool.?;
    tp.refcount = 1;

    mutexInit(&tp.lock);
    condInit(&tp.await_cond);
    containers.Curl_llist_init(&tp.slots, null);
    containers.Curl_llist_init(&tp.zombies, null);
    tp.fn_take = fn_take;
    tp.fn_process = fn_process;
    tp.fn_return = fn_return;
    tp.fn_user_data = user_data;
    tp.name = name;

    const result = Curl_thrdpool_set_props(tp, min_threads, max_threads, idle_time_ms);
    if (result != CURLE_OK) {
        tp.aborted = true;
        _ = thrdpoolUnlink(tp, false);
        tpool = null;
    }
    ptpool.* = tpool;
    return result;
}

pub export fn Curl_thrdpool_destroy(tpool: *curl_thrdpool, join: bool) callconv(.c) void {
    mutexAcquire(&tpool.lock);

    tpool.aborted = true;

    while (join and containers.Curl_llist_count(&tpool.slots) > 0) {
        thrdpoolWakeAll(tpool);
        Curl_cond_wait(&tpool.await_cond, &tpool.lock);
    }

    thrdpoolJoinZombies(tpool);

    if (containers.Curl_llist_count(&tpool.slots) > 0) {
        var e = containers.Curl_llist_head(&tpool.slots);
        while (e) |node| : (e = containers.Curl_node_next(node)) {
            const tslot: *thrdslot = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            if (tslot.thread != null) {
                Curl_thread_destroy(&tslot.thread);
            }
        }
        tpool.detached = true;
    }

    if (!thrdpoolUnlink(tpool, true)) {
        mutexRelease(&tpool.lock);
    }
}

pub export fn Curl_thrdpool_signal(tpool: *curl_thrdpool, nthreads: u32) callconv(.c) CURLcode {
    mutexAcquire(&tpool.lock);
    const result = thrdpoolSignal(tpool, nthreads);
    mutexRelease(&tpool.lock);
    return result;
}

fn thrdpoolAllIdle(tpool: *curl_thrdpool) bool {
    var e = containers.Curl_llist_head(&tpool.slots);
    while (e) |node| : (e = containers.Curl_node_next(node)) {
        const tslot: *thrdslot = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        if (!tslot.idle) return false;
    }
    return true;
}

pub export fn Curl_thrdpool_await_idle(tpool: *curl_thrdpool, timeout_ms: u32) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var end: Curltime = .{ .tv_sec = 0, .tv_usec = 0 };

    mutexAcquire(&tpool.lock);
    if (tpool.aborted) {
        result = CURLE_FAILED_INIT;
    } else {
        while (!thrdpoolAllIdle(tpool)) {
            if (timeout_ms != 0) {
                if (end.tv_sec == 0 and end.tv_usec == 0) {
                    end = curlx_time_net.curlx_now();
                    end.tv_sec += @as(@TypeOf(end.tv_sec), @intCast(timeout_ms / 1000));
                    end.tv_usec += @as(c_int, @intCast(timeout_ms % 1000)) * 1000;
                    if (end.tv_usec >= 1_000_000) {
                        end.tv_sec += 1;
                        end.tv_usec -= 1_000_000;
                    }
                }
                const remain_ms = curlx_time_net.curlx_timediff_ms(end, curlx_time_net.curlx_now());
                const r: CURLcode = if (remain_ms <= 0)
                    CURLE_OPERATION_TIMEDOUT
                else
                    Curl_cond_timedwait(&tpool.await_cond, &tpool.lock, @intCast(remain_ms));
                if (r == CURLE_OPERATION_TIMEDOUT) {
                    result = r;
                    break;
                }
            } else {
                Curl_cond_wait(&tpool.await_cond, &tpool.lock);
            }
        }
    }

    thrdpoolJoinZombies(tpool);
    mutexRelease(&tpool.lock);
    return result;
}

pub export fn Curl_thrdpool_trace(tpool: *curl_thrdpool, data: ?*anyopaque) callconv(.c) void {
    if (builtin.output_mode == .Lib) {
        if (data != null and libcurl_trc.Curl_trc_feat_threads.log_level >= CURL_LOG_LVL_INFO) {
            const feat = &libcurl_trc.Curl_trc_feat_threads;
            const now = curlx_time_net.curlx_now();

            mutexAcquire(&tpool.lock);
            if (containers.Curl_llist_count(&tpool.slots) == 0) {
                libcurl_trc.Curl_trc_feat_infof(data, feat, "[TPOOL-%s] no threads running", tpool.name);
            }
            var e = containers.Curl_llist_head(&tpool.slots);
            while (e) |node| : (e = containers.Curl_node_next(node)) {
                const tslot: *thrdslot = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
                const elapsed_ms: c_longlong = @intCast(curlx_time_net.curlx_ptimediff_ms(&now, &tslot.starttime));
                if (!tslot.running) {
                    libcurl_trc.Curl_trc_feat_infof(data, feat, "[TPOOL-%s] [%u]: not running", tpool.name, tslot.id);
                } else if (tslot.starttime.tv_sec == 0 and tslot.starttime.tv_usec == 0) {
                    libcurl_trc.Curl_trc_feat_infof(data, feat, "[TPOOL-%s] [%u]: starting...", tpool.name, tslot.id);
                } else if (tslot.idle) {
                    libcurl_trc.Curl_trc_feat_infof(data, feat, "[TPOOL-%s] [%u]: idle for %lldms", tpool.name, tslot.id, elapsed_ms);
                } else {
                    const remain_ms: c_longlong = if (tslot.work_timeout_ms != 0)
                        @as(c_longlong, @intCast(tslot.work_timeout_ms)) - elapsed_ms
                    else
                        0;
                    libcurl_trc.Curl_trc_feat_infof(
                        data,
                        feat,
                        "[TPOOL-%s] [%u]: busy %lldms, timeout in %lldms: %s",
                        tpool.name,
                        tslot.id,
                        elapsed_ms,
                        remain_ms,
                        tslot.work_description,
                    );
                }
            }
            mutexRelease(&tpool.lock);
        }
    }
}

// ============================================================================
// 3. lib/thrdqueue.c (lib/thrdqueue.h)
// ============================================================================

pub const CURL_THRDQ_EV_ITEM_DONE: c_uint = 0;

pub const Curl_thrdq_ev_cb = *const fn (
    tqueue: *const curl_thrdq,
    ev: c_uint,
    user_data: ?*anyopaque,
) callconv(.c) void;

pub const Curl_thrdq_item_process_cb = *const fn (item: ?*anyopaque) callconv(.c) void;
pub const Curl_thrdq_item_free_cb = *const fn (item: ?*anyopaque) callconv(.c) void;
pub const Curl_thrdq_item_match_cb = *const fn (item: ?*anyopaque, match_data: ?*anyopaque) callconv(.c) bool;

pub const curl_thrdq = extern struct {
    name: ?[*:0]const u8,
    lock: CurlMutex,
    await_cond: CurlCond,
    sendq: Curl_llist,
    recvq: Curl_llist,
    tpool: ?*curl_thrdpool,
    fn_free: Curl_thrdq_item_free_cb,
    fn_process: Curl_thrdq_item_process_cb,
    fn_event: ?Curl_thrdq_ev_cb,
    fn_user_data: ?*anyopaque,
    aborted: bool,
};

const thrdq_item = extern struct {
    node: Curl_llist_node,
    fn_free: Curl_thrdq_item_free_cb,
    fn_process: Curl_thrdq_item_process_cb,
    item: ?*anyopaque,
    start: Curltime,
    timeout_ms: timediff_t,
    description: ?[*:0]const u8,
};

fn thrdqItemCreate(
    tqueue: *curl_thrdq,
    item: ?*anyopaque,
    description: ?[*:0]const u8,
    timeout_ms: timediff_t,
) ?*thrdq_item {
    const raw = mem.calloc(1, @sizeOf(thrdq_item)) orelse return null;
    const qitem: *thrdq_item = @ptrCast(@alignCast(raw));
    qitem.item = item;
    qitem.description = description;
    qitem.fn_free = tqueue.fn_free;
    qitem.fn_process = tqueue.fn_process;
    if (timeout_ms != 0) {
        qitem.start = curlx_time_net.curlx_now();
        qitem.timeout_ms = timeout_ms;
    }
    return qitem;
}

fn thrdqItemDestroy(qitem: *thrdq_item) void {
    if (qitem.item) |it| {
        qitem.fn_free(it);
    }
    mem.free(qitem);
}

fn thrdqItemListDtor(user_data: ?*anyopaque, elem: ?*anyopaque) callconv(.c) void {
    _ = user_data;
    if (elem) |p| {
        const qitem: *thrdq_item = @ptrCast(@alignCast(p));
        thrdqItemDestroy(qitem);
    }
}

fn thrdqTpoolTake(
    user_data: ?*anyopaque,
    pdescription: *?[*:0]const u8,
    ptimeout_ms: *timediff_t,
) callconv(.c) ?*anyopaque {
    const tqueue: *curl_thrdq = @ptrCast(@alignCast(user_data.?));
    var qitem: ?*thrdq_item = null;
    var fn_event: ?Curl_thrdq_ev_cb = null;
    var fn_user_data: ?*anyopaque = null;

    mutexAcquire(&tqueue.lock);
    pdescription.* = null;
    ptimeout_ms.* = 0;
    if (!tqueue.aborted) {
        var e = containers.Curl_llist_head(&tqueue.sendq);
        if (e != null) {
            const now = curlx_time_net.curlx_now();
            while (e) |node| {
                const qi: *thrdq_item = @ptrCast(@alignCast(containers.Curl_node_take_elem(node).?));
                qitem = qi;
                const timeout_ms: timediff_t = if (qi.timeout_ms == 0)
                    0
                else
                    qi.timeout_ms - curlx_time_net.curlx_ptimediff_ms(&now, &qi.start);
                if (timeout_ms < 0) {
                    containers.Curl_llist_append(&tqueue.recvq, qi, &qi.node);
                    fn_event = tqueue.fn_event;
                    fn_user_data = tqueue.fn_user_data;
                    qitem = null;
                    e = containers.Curl_llist_head(&tqueue.sendq);
                    continue;
                } else {
                    pdescription.* = qi.description;
                    ptimeout_ms.* = timeout_ms;
                    break;
                }
            }
        }
    }
    mutexRelease(&tqueue.lock);
    if (fn_event) |cb| {
        cb(tqueue, CURL_THRDQ_EV_ITEM_DONE, fn_user_data);
    }
    return if (qitem) |qi| @ptrCast(qi) else null;
}

fn thrdqTpoolReturn(item: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void {
    const qitem: *thrdq_item = @ptrCast(@alignCast(item.?));
    const tq_raw = user_data orelse {
        thrdqItemDestroy(qitem);
        return;
    };
    const tqueue: *curl_thrdq = @ptrCast(@alignCast(tq_raw));
    var fn_event: ?Curl_thrdq_ev_cb = null;
    var fn_user_data: ?*anyopaque = null;

    mutexAcquire(&tqueue.lock);
    if (tqueue.aborted) {
        thrdqItemDestroy(qitem);
    } else {
        containers.Curl_llist_append(&tqueue.recvq, qitem, &qitem.node);
        fn_event = tqueue.fn_event;
        fn_user_data = tqueue.fn_user_data;
    }
    mutexRelease(&tqueue.lock);
    if (fn_event) |cb| {
        cb(tqueue, CURL_THRDQ_EV_ITEM_DONE, fn_user_data);
    }
}

fn thrdqTpoolProcess(item: ?*anyopaque) callconv(.c) void {
    const qitem: *thrdq_item = @ptrCast(@alignCast(item.?));
    qitem.fn_process(qitem.item);
}

fn thrdqUnlink(tqueue: *curl_thrdq, locked: bool, join: bool) void {
    if (tqueue.tpool) |tp| {
        if (locked) {
            mutexRelease(&tqueue.lock);
        }
        Curl_thrdpool_destroy(tp, join);
        tqueue.tpool = null;
        if (locked) {
            mutexAcquire(&tqueue.lock);
        }
    }

    containers.Curl_llist_destroy(&tqueue.sendq, null);
    containers.Curl_llist_destroy(&tqueue.recvq, null);
    condDestroy(&tqueue.await_cond);
    if (locked) {
        mutexRelease(&tqueue.lock);
    }
    mutexDestroy(&tqueue.lock);
    mem.free(tqueue);
}

pub export fn Curl_thrdq_create(
    ptqueue: *?*curl_thrdq,
    name: ?[*:0]const u8,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
    fn_free: Curl_thrdq_item_free_cb,
    fn_process: Curl_thrdq_item_process_cb,
    fn_event: ?Curl_thrdq_ev_cb,
    user_data: ?*anyopaque,
) callconv(.c) CURLcode {
    const raw = mem.calloc(1, @sizeOf(curl_thrdq)) orelse {
        ptqueue.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    var tqueue: ?*curl_thrdq = @ptrCast(@alignCast(raw));
    const tq = tqueue.?;

    mutexInit(&tq.lock);
    condInit(&tq.await_cond);
    containers.Curl_llist_init(&tq.sendq, &thrdqItemListDtor);
    containers.Curl_llist_init(&tq.recvq, &thrdqItemListDtor);
    tq.fn_free = fn_free;
    tq.fn_process = fn_process;
    tq.fn_event = fn_event;
    tq.fn_user_data = user_data;
    tq.name = name;

    const result = Curl_thrdpool_create(
        &tq.tpool,
        name,
        min_threads,
        max_threads,
        idle_time_ms,
        &thrdqTpoolTake,
        &thrdqTpoolProcess,
        &thrdqTpoolReturn,
        tq,
    );

    if (result != CURLE_OK) {
        tq.aborted = true;
        thrdqUnlink(tq, false, true);
        tqueue = null;
    }
    ptqueue.* = tqueue;
    return result;
}

pub export fn Curl_thrdq_destroy(tqueue: *curl_thrdq, join: bool) callconv(.c) void {
    mutexAcquire(&tqueue.lock);
    tqueue.aborted = true;
    thrdqUnlink(tqueue, true, join);
}

fn thrdqGetSignals(tqueue: *curl_thrdq) u32 {
    const qlen = containers.Curl_llist_count(&tqueue.sendq);
    return if (qlen <= std.math.maxInt(u32)) @intCast(qlen) else std.math.maxInt(u32);
}

pub export fn Curl_thrdq_send(
    tqueue: *curl_thrdq,
    item: ?*anyopaque,
    description: ?[*:0]const u8,
    timeout_ms: timediff_t,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var signals: u32 = 0;

    mutexAcquire(&tqueue.lock);
    if (tqueue.aborted) {
        result = CURLE_SEND_ERROR;
    } else if (timeout_ms < 0) {
        result = CURLE_OPERATION_TIMEDOUT;
    } else {
        const qitem = thrdqItemCreate(tqueue, item, description, timeout_ms) orelse {
            mutexRelease(&tqueue.lock);
            return CURLE_OUT_OF_MEMORY;
        };
        containers.Curl_llist_append(&tqueue.sendq, qitem, &qitem.node);
        signals = thrdqGetSignals(tqueue);
    }
    mutexRelease(&tqueue.lock);

    if (result == CURLE_OK and signals != 0) {
        _ = Curl_thrdpool_signal(tqueue.tpool.?, signals);
    }
    return result;
}

pub export fn Curl_thrdq_check_started(tqueue: *curl_thrdq) callconv(.c) bool {
    mutexAcquire(&tqueue.lock);
    const unprocessed = if (tqueue.aborted) 0 else containers.Curl_llist_count(&tqueue.sendq);
    mutexRelease(&tqueue.lock);
    if (unprocessed == 0) return true;
    const n: u32 = if (unprocessed <= std.math.maxInt(u32)) @intCast(unprocessed) else std.math.maxInt(u32);
    return Curl_thrdpool_signal(tqueue.tpool.?, n) == CURLE_OK;
}

pub export fn Curl_thrdq_recv(tqueue: *curl_thrdq, pitem: *?*anyopaque) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_AGAIN;
    var signals: u32 = 0;

    pitem.* = null;
    mutexAcquire(&tqueue.lock);
    if (tqueue.aborted) {
        result = CURLE_RECV_ERROR;
    } else if (containers.Curl_llist_head(&tqueue.recvq)) |e| {
        const qitem: *thrdq_item = @ptrCast(@alignCast(containers.Curl_node_take_elem(e).?));
        pitem.* = qitem.item;
        qitem.item = null;
        thrdqItemDestroy(qitem);
        result = CURLE_OK;
    } else {
        signals = thrdqGetSignals(tqueue);
    }
    mutexRelease(&tqueue.lock);

    if (signals != 0) {
        _ = Curl_thrdpool_signal(tqueue.tpool.?, signals);
    }
    return result;
}

fn thrdqLlistCleanMatches(
    llist: *Curl_llist,
    fn_match: Curl_thrdq_item_match_cb,
    match_data: ?*anyopaque,
) void {
    var e = containers.Curl_llist_head(llist);
    while (e) |node| {
        const n = containers.Curl_node_next(node);
        const qitem: *thrdq_item = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        if (fn_match(qitem.item, match_data)) {
            containers.Curl_node_remove(node);
        }
        e = n;
    }
}

pub export fn Curl_thrdq_clear(
    tqueue: *curl_thrdq,
    fn_match: Curl_thrdq_item_match_cb,
    match_data: ?*anyopaque,
) callconv(.c) void {
    mutexAcquire(&tqueue.lock);
    if (!tqueue.aborted) {
        thrdqLlistCleanMatches(&tqueue.sendq, fn_match, match_data);
        thrdqLlistCleanMatches(&tqueue.recvq, fn_match, match_data);
    }
    mutexRelease(&tqueue.lock);
}

pub export fn Curl_thrdq_await_done(tqueue: *curl_thrdq, timeout_ms: u32) callconv(.c) CURLcode {
    return Curl_thrdpool_await_idle(tqueue.tpool.?, timeout_ms);
}

pub export fn thrdq_await_done(tqueue: *curl_thrdq, timeout_ms: u32) callconv(.c) CURLcode {
    return Curl_thrdq_await_done(tqueue, timeout_ms);
}

pub export fn Curl_thrdq_set_props(
    tqueue: *curl_thrdq,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
) callconv(.c) CURLcode {
    mutexAcquire(&tqueue.lock);
    const signals = thrdqGetSignals(tqueue);
    mutexRelease(&tqueue.lock);

    var result = Curl_thrdpool_set_props(tqueue.tpool.?, min_threads, max_threads, idle_time_ms);
    if (result == CURLE_OK and signals != 0) {
        result = Curl_thrdpool_signal(tqueue.tpool.?, signals);
    }
    return result;
}

pub export fn Curl_thrdq_trace(tqueue: *curl_thrdq, data: ?*anyopaque) callconv(.c) void {
    if (builtin.output_mode == .Lib) {
        if (data != null and libcurl_trc.Curl_trc_feat_threads.log_level >= CURL_LOG_LVL_INFO) {
            const feat = &libcurl_trc.Curl_trc_feat_threads;
            if (tqueue.tpool) |tp| {
                Curl_thrdpool_trace(tp, data);
            }
            mutexAcquire(&tqueue.lock);
            if (containers.Curl_llist_count(&tqueue.sendq) == 0 and
                containers.Curl_llist_count(&tqueue.recvq) == 0)
            {
                libcurl_trc.Curl_trc_feat_infof(data, feat, "[TQUEUE-%s] empty", tqueue.name);
            }
            var e = containers.Curl_llist_head(&tqueue.sendq);
            while (e) |node| : (e = containers.Curl_node_next(node)) {
                const qitem: *thrdq_item = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
                libcurl_trc.Curl_trc_feat_infof(data, feat, "[TQUEUE-%s] in: %s", tqueue.name, qitem.description);
            }
            e = containers.Curl_llist_head(&tqueue.recvq);
            while (e) |node| : (e = containers.Curl_node_next(node)) {
                const qitem: *thrdq_item = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
                libcurl_trc.Curl_trc_feat_infof(data, feat, "[TQUEUE-%s] out: %s", tqueue.name, qitem.description);
            }
            mutexRelease(&tqueue.lock);
        }
    }
}

// ============================================================================
// 4. lib/psl.c (lib/psl.h)
// ============================================================================

pub const PslCache = extern struct {
    psl: ?*const anyopaque,
    expires: curlx_time_net.time_t,
    flags: c_uint,
};

pub export fn Curl_psl_destroy(pslcache: ?*PslCache) callconv(.c) void {
    if (pslcache) |cache| {
        cache.psl = null;
        cache.flags = 0;
    }
}

pub export fn Curl_psl_use(easy: ?*anyopaque) callconv(.c) ?*const anyopaque {
    _ = easy;
    return null;
}

pub export fn Curl_psl_release(easy: ?*anyopaque) callconv(.c) void {
    _ = easy;
}

// ============================================================================
// 5. lib/macos.c & lib/amigaos.c (lib/macos.h, lib/amigaos.h)
// ============================================================================

pub export fn Curl_macos_init() callconv(.c) CURLcode {
    if (builtin.os.tag == .macos) {
        const CopyProxiesFn = *const fn (?*const anyopaque) callconv(.c) ?*const anyopaque;
        const CFReleaseFn = *const fn (*const anyopaque) callconv(.c) void;
        const rtld_default: ?*anyopaque = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2))));
        if (std.c.dlsym(rtld_default, "SCDynamicStoreCopyProxies")) |copy_ptr| {
            const copyProxies: CopyProxiesFn = @ptrCast(@alignCast(copy_ptr));
            if (copyProxies(null)) |dict| {
                if (std.c.dlsym(rtld_default, "CFRelease")) |rel_ptr| {
                    const cfRelease: CFReleaseFn = @ptrCast(@alignCast(rel_ptr));
                    cfRelease(dict);
                }
            }
        }
    }
    return CURLE_OK;
}

pub export fn Curl_amiga_init() callconv(.c) CURLcode {
    return CURLE_OK;
}

pub export fn Curl_amiga_cleanup() callconv(.c) void {}

// ============================================================================
// Unit Tests
// ============================================================================

const ThreadTestCtx = struct {
    value: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),
    thread_id: curl_thread_id_t = 0,
    is_curr: bool = false,

    fn worker(arg: ?*anyopaque) callconv(thread_cc) ThreadReturn {
        const self: *ThreadTestCtx = @ptrCast(@alignCast(arg.?));
        self.thread_id = Curl_thread_get_current_id();
        self.is_curr = Curl_thread_is_current(self.thread_id);
        _ = self.value.fetchAdd(42, .seq_cst);
        return 0;
    }
};

test "Curl_thread_create, Curl_thread_join, and thread ID helpers" {
    const main_tid = Curl_thread_get_current_id();
    try std.testing.expect(Curl_thread_is_current(main_tid));

    var ctx = ThreadTestCtx{};
    var th = Curl_thread_create(&ThreadTestCtx.worker, &ctx);
    try std.testing.expect(th != null);
    try std.testing.expectEqual(@as(c_int, 1), Curl_thread_join(&th));
    try std.testing.expect(th == null);
    try std.testing.expectEqual(@as(u32, 42), ctx.value.load(.seq_cst));
    try std.testing.expect(ctx.is_curr);
    try std.testing.expect(!Curl_thread_is_current(ctx.thread_id));
}

test "Curl_cond_timedwait timeout" {
    var m = CurlMutex{};
    var c = CurlCond{};
    mutexInit(&m);
    defer mutexDestroy(&m);
    condInit(&c);
    defer condDestroy(&c);

    mutexAcquire(&m);
    const rc = Curl_cond_timedwait(&c, &m, 5);
    mutexRelease(&m);
    try std.testing.expectEqual(CURLE_OPERATION_TIMEDOUT, rc);
}

const ThrdpoolTestCtx = struct {
    remaining: u32 = 8,
    processed: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),
    returned: u32 = 0,
    tokens: [8]u32 = .{ 1, 2, 3, 4, 5, 6, 7, 8 },

    fn take(
        user_data: ?*anyopaque,
        pdescription: *?[*:0]const u8,
        ptimeout_ms: *timediff_t,
    ) callconv(.c) ?*anyopaque {
        const self: *ThrdpoolTestCtx = @ptrCast(@alignCast(user_data.?));
        pdescription.* = "pool-item";
        ptimeout_ms.* = 1000;
        if (self.remaining == 0) return null;
        self.remaining -= 1;
        return @ptrCast(&self.tokens[self.remaining]);
    }

    fn process(item: ?*anyopaque) callconv(.c) void {
        const val: *u32 = @ptrCast(@alignCast(item.?));
        val.* *= 10;
    }

    fn ret(item: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void {
        _ = item;
        if (user_data) |ud| {
            const self: *ThrdpoolTestCtx = @ptrCast(@alignCast(ud));
            self.returned += 1;
            _ = self.processed.fetchAdd(1, .seq_cst);
        }
    }
};

test "Curl_thrdpool_create, signal, set_props, await_idle, destroy" {
    var ctx = ThrdpoolTestCtx{};
    var tpool: ?*curl_thrdpool = null;

    try std.testing.expectEqual(
        CURLE_BAD_FUNCTION_ARGUMENT,
        Curl_thrdpool_create(&tpool, "test-pool", 3, 2, 100, &ThrdpoolTestCtx.take, &ThrdpoolTestCtx.process, &ThrdpoolTestCtx.ret, &ctx),
    );
    try std.testing.expect(tpool == null);

    try std.testing.expectEqual(
        CURLE_OK,
        Curl_thrdpool_create(&tpool, "test-pool", 1, 2, 50, &ThrdpoolTestCtx.take, &ThrdpoolTestCtx.process, &ThrdpoolTestCtx.ret, &ctx),
    );
    const tp = tpool orelse return error.UnexpectedNull;

    try std.testing.expectEqual(CURLE_OK, Curl_thrdpool_signal(tp, 4));
    try std.testing.expectEqual(CURLE_OK, Curl_thrdpool_await_idle(tp, 5000));
    try std.testing.expectEqual(@as(u32, 8), ctx.processed.load(.seq_cst));
    try std.testing.expectEqual(@as(u32, 8), ctx.returned);

    for (ctx.tokens, 1..) |tok, idx| {
        try std.testing.expectEqual(@as(u32, @intCast(idx * 10)), tok);
    }

    Curl_thrdpool_destroy(tp, true);
}

const ThrdqTestItem = struct {
    id: u32,
    processed: bool = false,
};

const ThrdqTestCtx = struct {
    events: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),
    freed: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),

    fn freeItem(item: ?*anyopaque) callconv(.c) void {
        if (item) |p| {
            mem.free(p);
        }
    }

    fn processItem(item: ?*anyopaque) callconv(.c) void {
        const it: *ThrdqTestItem = @ptrCast(@alignCast(item.?));
        it.processed = true;
    }

    fn eventCb(tqueue: *const curl_thrdq, ev: c_uint, user_data: ?*anyopaque) callconv(.c) void {
        _ = tqueue;
        if (ev == CURL_THRDQ_EV_ITEM_DONE) {
            const self: *ThrdqTestCtx = @ptrCast(@alignCast(user_data.?));
            _ = self.events.fetchAdd(1, .seq_cst);
        }
    }

    fn matchId(item: ?*anyopaque, match_data: ?*anyopaque) callconv(.c) bool {
        const it: *ThrdqTestItem = @ptrCast(@alignCast(item.?));
        const target: *const u32 = @ptrCast(@alignCast(match_data.?));
        return it.id == target.*;
    }
};

test "Curl_thrdq_create, send, recv, clear, await_done, destroy" {
    var ctx = ThrdqTestCtx{};
    var tqueue: ?*curl_thrdq = null;

    try std.testing.expectEqual(
        CURLE_OK,
        Curl_thrdq_create(
            &tqueue,
            "test-q",
            0,
            2,
            100,
            &ThrdqTestCtx.freeItem,
            &ThrdqTestCtx.processItem,
            &ThrdqTestCtx.eventCb,
            &ctx,
        ),
    );
    const tq = tqueue orelse return error.UnexpectedNull;

    try std.testing.expectEqual(CURLE_OPERATION_TIMEDOUT, Curl_thrdq_send(tq, null, "expired", -1));

    var i: u32 = 0;
    while (i < 4) : (i += 1) {
        const raw = mem.calloc(1, @sizeOf(ThrdqTestItem)) orelse return error.OutOfMemory;
        const item: *ThrdqTestItem = @ptrCast(@alignCast(raw));
        item.id = i + 1;
        item.processed = false;
        try std.testing.expectEqual(CURLE_OK, Curl_thrdq_send(tq, item, "item", 0));
    }

    try std.testing.expect(Curl_thrdq_check_started(tq));

    var received: u32 = 0;
    var spins: u32 = 0;
    while (received < 4 and spins < 1000) : (spins += 1) {
        _ = Curl_thrdq_await_done(tq, 100);
        var out_raw: ?*anyopaque = null;
        const rc = Curl_thrdq_recv(tq, &out_raw);
        if (rc == CURLE_OK) {
            const it: *ThrdqTestItem = @ptrCast(@alignCast(out_raw.?));
            try std.testing.expect(it.processed);
            mem.free(it);
            received += 1;
        } else {
            try std.testing.expectEqual(CURLE_AGAIN, rc);
            _ = curlx_time_net.curlx_wait_ms(2);
        }
    }
    try std.testing.expectEqual(@as(u32, 4), received);
    try std.testing.expectEqual(@as(u32, 4), ctx.events.load(.seq_cst));

    try std.testing.expectEqual(CURLE_OK, Curl_thrdq_set_props(tq, 0, 2, 50));
    Curl_thrdq_destroy(tq, true);
}

test "Curl_psl_*, Curl_macos_init, Curl_amiga_init" {
    var cache = PslCache{
        .psl = @ptrFromInt(0x1234),
        .expires = 100,
        .flags = 1,
    };
    Curl_psl_destroy(&cache);
    try std.testing.expect(cache.psl == null);
    try std.testing.expectEqual(@as(c_uint, 0), cache.flags);
    try std.testing.expect(Curl_psl_use(null) == null);
    Curl_psl_release(null);

    try std.testing.expectEqual(CURLE_OK, Curl_macos_init());
    try std.testing.expectEqual(CURLE_OK, Curl_amiga_init());
    Curl_amiga_cleanup();
}
