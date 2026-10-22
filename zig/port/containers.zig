const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const curlx_parse = @import("curlx_parse.zig");

pub const CURLcode = curlx_parse.CURLcode;
pub const CURLE_OK = curlx_parse.CURLE_OK;
pub const CURLE_OUT_OF_MEMORY = curlx_parse.CURLE_OUT_OF_MEMORY;
pub const CURLE_BAD_FUNCTION_ARGUMENT = curlx_parse.CURLE_BAD_FUNCTION_ARGUMENT;
pub const CURLE_TOO_LARGE = curlx_parse.CURLE_TOO_LARGE;

const MERR_TOO_LARGE: c_int = 2;
const MIN_FIRST_ALLOC: usize = 32;

// ============================================================================
// 1. lib/curlx/dynbuf.c (lib/curlx/dynbuf.h)
// ============================================================================

pub const dynbuf = extern struct {
    bufr: ?[*]u8,
    leng: usize,
    allc: usize,
    toobig: usize,
};

pub const CVaListParam = switch (builtin.cpu.arch) {
    .x86_64 => if (builtin.os.tag == .windows) [*]u8 else *std.builtin.VaListX86_64,
    .aarch64, .aarch64_be => switch (builtin.os.tag) {
        .macos, .ios, .tvos, .watchos, .visionos, .driverkit, .maccatalyst, .windows => [*]u8,
        else => std.builtin.VaListAarch64,
    },
    else => *anyopaque,
};

const libcurl_printf = struct {
    extern fn curlx_dyn_vprintf(dyn: *dynbuf, format: [*:0]const u8, args: CVaListParam) callconv(.c) c_int;
};

const cli_printf = struct {
    extern fn curl_mvaprintf(format: [*:0]const u8, args: CVaListParam) callconv(.c) ?[*:0]u8;
    extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
};

const test_libc = struct {
    extern "c" fn vsnprintf(buf: [*]u8, size: usize, format: [*:0]const u8, ap: CVaListParam) c_int;
};

pub export fn curlx_dyn_init(s: *dynbuf, toobig: usize) callconv(.c) void {
    s.bufr = null;
    s.leng = 0;
    s.allc = 0;
    s.toobig = toobig;
}

pub export fn curlx_dyn_free(s: *dynbuf) callconv(.c) void {
    if (s.bufr) |b| {
        mem.free(b);
    }
    s.bufr = null;
    s.leng = 0;
    s.allc = 0;
}

fn dynNappend(s: *dynbuf, mem_ptr: ?[*]const u8, len: usize) CURLcode {
    const idx = s.leng;
    var a = s.allc;
    const len_plus_idx = std.math.add(usize, len, idx) catch {
        curlx_dyn_free(s);
        return CURLE_TOO_LARGE;
    };
    const fit = std.math.add(usize, len_plus_idx, 1) catch {
        curlx_dyn_free(s);
        return CURLE_TOO_LARGE;
    };

    if (fit > s.toobig) {
        curlx_dyn_free(s);
        return CURLE_TOO_LARGE;
    } else if (a == 0) {
        if (MIN_FIRST_ALLOC > s.toobig) {
            a = s.toobig;
        } else if (fit < MIN_FIRST_ALLOC) {
            a = MIN_FIRST_ALLOC;
        } else {
            a = fit;
        }
    } else {
        while (a < fit) {
            a *|= 2;
        }
        if (a > s.toobig) {
            a = s.toobig;
        }
    }

    if (a != s.allc) {
        const p = mem.realloc(s.bufr, a) orelse {
            curlx_dyn_free(s);
            return CURLE_OUT_OF_MEMORY;
        };
        s.bufr = p;
        s.allc = a;
    }

    const bufr = s.bufr.?;
    if (len > 0) {
        if (mem_ptr) |src| {
            @memcpy(bufr[idx .. idx + len], src[0..len]);
        }
    }
    s.leng = idx + len;
    bufr[s.leng] = 0;
    return CURLE_OK;
}

pub export fn curlx_dyn_reset(s: *dynbuf) callconv(.c) void {
    if (s.leng > 0) {
        if (s.bufr) |b| {
            b[0] = 0;
        }
    }
    s.leng = 0;
}

pub export fn curlx_dyn_tail(s: *dynbuf, trail: usize) callconv(.c) CURLcode {
    if (trail > s.leng) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    } else if (trail == s.leng) {
        return CURLE_OK;
    } else if (trail == 0) {
        curlx_dyn_reset(s);
    } else {
        const b = s.bufr.?;
        std.mem.copyForwards(u8, b[0..trail], b[s.leng - trail .. s.leng]);
        s.leng = trail;
        b[s.leng] = 0;
    }
    return CURLE_OK;
}

fn rawToConstBytes(ptr: ?*const anyopaque) ?[*]const u8 {
    return @ptrCast(ptr);
}

pub export fn curlx_dyn_addn(s: *dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode {
    return dynNappend(s, rawToConstBytes(mem_ptr), len);
}

pub export fn curlx_dyn_add(s: *dynbuf, str: [*:0]const u8) callconv(.c) CURLcode {
    const n = std.mem.len(str);
    return dynNappend(s, str, n);
}

export fn curlx_dyn_vaddf(s: *dynbuf, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) CURLcode {
    if (builtin.output_mode == .Lib) {
        const rc = libcurl_printf.curlx_dyn_vprintf(s, fmt, ap);
        if (rc == 0) return CURLE_OK;
        if (rc == MERR_TOO_LARGE) return CURLE_TOO_LARGE;
        return CURLE_OUT_OF_MEMORY;
    } else if (builtin.is_test) {
        var stack_buf: [4096]u8 = undefined;
        const n = test_libc.vsnprintf(&stack_buf, stack_buf.len, fmt, ap);
        if (n < 0) {
            curlx_dyn_free(s);
            return CURLE_OUT_OF_MEMORY;
        }
        const written: usize = @intCast(n);
        if (written >= stack_buf.len) {
            curlx_dyn_free(s);
            return CURLE_TOO_LARGE;
        }
        return dynNappend(s, &stack_buf, written);
    } else {
        const str = cli_printf.curl_mvaprintf(fmt, ap);
        if (str) |p| {
            const result = dynNappend(s, p, std.mem.len(p));
            cli_printf.curl_free(p);
            return result;
        }
        curlx_dyn_free(s);
        return CURLE_OUT_OF_MEMORY;
    }
}

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin() or builtin.os.tag == .windows,
    else => false,
};

const addf_impl = if (use_c_vastart) struct {
    pub fn curlx_dyn_addf(s: *dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        if (builtin.cpu.arch == .x86_64) {
            return curlx_dyn_vaddf(s, fmt, &ap);
        } else {
            return curlx_dyn_vaddf(s, fmt, @ptrCast(ap));
        }
    }
} else if (builtin.cpu.arch == .x86_64 and builtin.os.tag == .windows) struct {
    pub fn curlx_dyn_addf() callconv(.naked) void {
        asm volatile (
            \\movq %%r8, 24(%%rsp)
            \\movq %%r9, 32(%%rsp)
            \\leaq 24(%%rsp), %%r8
            \\jmp curlx_dyn_vaddf
        );
    }
} else if (builtin.cpu.arch == .aarch64) struct {
    pub fn curlx_dyn_addf() callconv(.naked) void {
        asm volatile (
            \\sub sp, sp, #256
            \\stp x29, x30, [sp, #240]
            \\add x29, sp, #240
            \\stp x2, x3, [x29, #-48]
            \\stp x4, x5, [x29, #-32]
            \\stp x6, x7, [x29, #-16]
            \\stp q0, q1, [sp, #32]
            \\stp q2, q3, [sp, #64]
            \\stp q4, q5, [sp, #96]
            \\stp q6, q7, [sp, #128]
            \\add x8, x29, #16
            \\str x8, [sp, #0]
            \\sub x8, x29, #0
            \\str x8, [sp, #8]
            \\add x8, sp, #160
            \\str x8, [sp, #16]
            \\mov w8, #-48
            \\str w8, [sp, #24]
            \\mov w8, #-128
            \\str w8, [sp, #28]
            \\mov x2, sp
            \\bl curlx_dyn_vaddf
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }
} else struct {};

comptime {
    @export(&addf_impl.curlx_dyn_addf, .{ .name = "curlx_dyn_addf", .linkage = .strong });
}

pub extern fn curlx_dyn_addf(s: *dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;

pub export fn curlx_dyn_ptr(s: *const dynbuf) callconv(.c) ?[*:0]u8 {
    return if (s.bufr) |b| b[0..s.leng :0].ptr else null;
}

pub export fn curlx_dyn_take(s: *dynbuf, plen: *usize) callconv(.c) ?[*:0]u8 {
    const ptr = curlx_dyn_ptr(s);
    plen.* = s.leng;
    s.bufr = null;
    s.leng = 0;
    s.allc = 0;
    return ptr;
}

pub export fn curlx_dyn_uptr(s: *const dynbuf) callconv(.c) ?[*]u8 {
    return s.bufr;
}

pub export fn curlx_dyn_len(s: *const dynbuf) callconv(.c) usize {
    return s.leng;
}

pub export fn curlx_dyn_setlen(s: *dynbuf, set: usize) callconv(.c) CURLcode {
    if (set > s.leng) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    s.leng = set;
    if (s.bufr) |b| {
        b[s.leng] = 0;
    }
    return CURLE_OK;
}

// ============================================================================
// 2. lib/bufref.c (lib/bufref.h)
// ============================================================================

pub const BufrefDtor = *const fn (?*anyopaque) callconv(.c) void;

pub const bufref = extern struct {
    dtor: ?BufrefDtor,
    ptr: ?[*]const u8,
    len: usize,
};

fn bufrefFreeCallback(ptr: ?*anyopaque) callconv(.c) void {
    mem.free(ptr);
}

export fn Curl_bufref_init(br: *bufref) callconv(.c) void {
    br.dtor = null;
    br.ptr = null;
    br.len = 0;
}

export fn Curl_bufref_free(br: *bufref) callconv(.c) void {
    if (br.ptr) |p| {
        if (br.dtor) |dtor| {
            dtor(@constCast(p));
        }
    }
    br.dtor = null;
    br.ptr = null;
    br.len = 0;
}

export fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?BufrefDtor) callconv(.c) void {
    Curl_bufref_free(br);
    br.ptr = rawToConstBytes(ptr);
    br.len = len;
    br.dtor = dtor;
}

export fn Curl_bufref_uptr(br: *const bufref) callconv(.c) ?[*]const u8 {
    return br.ptr;
}

export fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8 {
    return @ptrCast(br.ptr);
}

export fn Curl_bufref_len(br: *const bufref) callconv(.c) usize {
    return br.len;
}

export fn Curl_bufref_memdup0(br: *bufref, ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode {
    var cpy: ?[*:0]u8 = null;
    if (rawToConstBytes(ptr)) |src| {
        cpy = mem.memdup0(src, len) orelse return CURLE_OUT_OF_MEMORY;
    }
    Curl_bufref_set(br, cpy, len, &bufrefFreeCallback);
    return CURLE_OK;
}

// ============================================================================
// 3. lib/llist.c (lib/llist.h)
// ============================================================================

pub const Curl_llist_dtor = *const fn (?*anyopaque, ?*anyopaque) callconv(.c) void;

pub const Curl_llist = extern struct {
    _head: ?*Curl_llist_node,
    _tail: ?*Curl_llist_node,
    _dtor: ?Curl_llist_dtor,
    _size: usize,
};

pub const Curl_llist_node = extern struct {
    _list: ?*Curl_llist,
    _ptr: ?*anyopaque,
    _prev: ?*Curl_llist_node,
    _next: ?*Curl_llist_node,
};

pub export fn Curl_llist_init(l: *Curl_llist, dtor: ?Curl_llist_dtor) callconv(.c) void {
    l._size = 0;
    l._dtor = dtor;
    l._head = null;
    l._tail = null;
}

pub export fn llist_insert_next(
    list: *Curl_llist,
    e: ?*Curl_llist_node,
    p: ?*const anyopaque,
    ne: *Curl_llist_node,
) callconv(.c) void {
    ne._ptr = if (p) |ptr| @constCast(ptr) else null;
    ne._list = list;
    if (list._size == 0) {
        list._head = ne;
        ne._prev = null;
        ne._next = null;
        list._tail = ne;
    } else {
        ne._next = if (e) |entry| entry._next else list._head;
        ne._prev = e;
        if (e == null) {
            if (list._head) |h| {
                h._prev = ne;
            }
            list._head = ne;
        } else if (e.?._next) |enext| {
            enext._prev = ne;
        } else {
            list._tail = ne;
        }
        if (e) |entry| {
            entry._next = ne;
        }
    }
    list._size += 1;
}

pub export fn Curl_llist_insert_next(
    list: *Curl_llist,
    e: ?*Curl_llist_node,
    p: ?*const anyopaque,
    ne: *Curl_llist_node,
) callconv(.c) void {
    llist_insert_next(list, e, p, ne);
}

pub export fn Curl_llist_append(
    list: *Curl_llist,
    p: ?*const anyopaque,
    ne: *Curl_llist_node,
) callconv(.c) void {
    llist_insert_next(list, list._tail, p, ne);
}

pub export fn Curl_node_take_elem(e: ?*Curl_llist_node) callconv(.c) ?*anyopaque {
    const node = e orelse return null;
    if (node._list) |list| {
        if (node == list._head) {
            list._head = node._next;
            if (list._head == null) {
                list._tail = null;
            } else if (node._next) |next| {
                next._prev = null;
            }
        } else {
            if (node._prev) |prev| {
                prev._next = node._next;
            }
            if (node._next) |next| {
                next._prev = node._prev;
            } else {
                list._tail = node._prev;
            }
        }
        list._size -= 1;
    }
    const ptr = node._ptr;
    node._list = null;
    node._ptr = null;
    node._prev = null;
    node._next = null;
    return ptr;
}

fn nodeUremove(e: ?*Curl_llist_node, user: ?*anyopaque) void {
    const node = e orelse return;
    if (node._list) |list| {
        const ptr = Curl_node_take_elem(node);
        if (list._dtor) |dtor| {
            dtor(user, ptr);
        }
    }
}

pub export fn Curl_node_remove(e: ?*Curl_llist_node) callconv(.c) void {
    nodeUremove(e, null);
}

pub export fn Curl_llist_remove(
    list: ?*Curl_llist,
    e: ?*Curl_llist_node,
    user: ?*anyopaque,
) callconv(.c) void {
    _ = list;
    nodeUremove(e, user);
}

pub export fn Curl_llist_destroy(list: ?*Curl_llist, user: ?*anyopaque) callconv(.c) void {
    if (list) |l| {
        while (l._size > 0) {
            nodeUremove(l._tail, user);
        }
    }
}

pub export fn Curl_llist_head(list: *const Curl_llist) callconv(.c) ?*Curl_llist_node {
    return list._head;
}

pub export fn llist_tail(list: *const Curl_llist) callconv(.c) ?*Curl_llist_node {
    return list._tail;
}

pub export fn Curl_llist_tail(list: *const Curl_llist) callconv(.c) ?*Curl_llist_node {
    return list._tail;
}

pub export fn Curl_llist_count(list: *const Curl_llist) callconv(.c) usize {
    return list._size;
}

pub export fn Curl_node_elem(n: *const Curl_llist_node) callconv(.c) ?*anyopaque {
    return n._ptr;
}

pub export fn Curl_node_next(n: *const Curl_llist_node) callconv(.c) ?*Curl_llist_node {
    return n._next;
}

pub export fn llist_node_prev(n: *const Curl_llist_node) callconv(.c) ?*Curl_llist_node {
    return n._prev;
}

pub export fn Curl_node_prev(n: *const Curl_llist_node) callconv(.c) ?*Curl_llist_node {
    return n._prev;
}

pub export fn Curl_node_llist(n: *const Curl_llist_node) callconv(.c) ?*Curl_llist {
    return n._list;
}

// ============================================================================
// 4. lib/slist.c (include/curl/curl.h, lib/slist.h)
// ============================================================================

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

fn slistGetLast(list: ?*curl_slist) ?*curl_slist {
    var item = list orelse return null;
    while (item.next) |n| {
        item = n;
    }
    return item;
}

export fn Curl_slist_append_nodup(list: ?*curl_slist, data: ?[*:0]const u8) callconv(.c) ?*curl_slist {
    const new_item = mem.alloc(curl_slist) orelse return null;
    new_item.next = null;
    new_item.data = if (data) |d| @constCast(d) else null;

    if (list == null) return new_item;

    const last = slistGetLast(list).?;
    last.next = new_item;
    return list;
}

fn slistAppendInner(list: ?*curl_slist, d: [*:0]const u8) error{OutOfMemory}!*curl_slist {
    const dupdata = mem.strdup(d) orelse return error.OutOfMemory;
    errdefer mem.free(dupdata);
    return Curl_slist_append_nodup(list, dupdata) orelse return error.OutOfMemory;
}

export fn curl_slist_append(list: ?*curl_slist, data: ?[*:0]const u8) callconv(.c) ?*curl_slist {
    const d = data orelse return null;
    return slistAppendInner(list, d) catch null;
}

export fn Curl_slist_duplicate(inlist: ?*curl_slist) callconv(.c) ?*curl_slist {
    var outlist: ?*curl_slist = null;
    var tail: *?*curl_slist = &outlist;
    var cur = inlist;
    while (cur) |node| : (cur = node.next) {
        const tmp = curl_slist_append(null, node.data) orelse {
            curl_slist_free_all(outlist);
            return null;
        };
        tail.* = tmp;
        tail = &tmp.next;
    }
    return outlist;
}

export fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void {
    var item = list;
    while (item) |node| {
        const next = node.next;
        if (node.data) |d| {
            mem.free(d);
            node.data = null;
        }
        mem.free(node);
        item = next;
    }
}

// ============================================================================
// 5. lib/splay.c (lib/splay.h)
// ============================================================================

pub const timediff_t = i64;
pub const TIMEDIFF_T_MAX: timediff_t = std.math.maxInt(timediff_t);
pub const TIMEDIFF_T_MIN: timediff_t = std.math.minInt(timediff_t);

pub const curltime = extern struct {
    tv_sec: i64,
    tv_usec: c_int,
};

pub const Curl_tree = extern struct {
    smaller: ?*Curl_tree,
    larger: ?*Curl_tree,
    same: ?*Curl_tree,
    key: timediff_t,
    id: u32,
    flags: c_uint,

    pub inline fn isRegistered(self: *const Curl_tree) bool {
        return (self.flags & 1) != 0;
    }

    pub inline fn setRegistered(self: *Curl_tree, val: bool) void {
        if (val) {
            self.flags |= 1;
        } else {
            self.flags &= ~@as(c_uint, 1);
        }
    }
};

pub const Curl_timeouts = extern struct {
    tree: ?*Curl_tree,
    time_base_sec: i64,
};

const timeval_ext = struct {
    extern fn curlx_pnow(pnow: *curltime) callconv(.c) void;
};

fn ptimediffUs(newer: *const curltime, older: *const curltime) timediff_t {
    const diff: timediff_t = newer.tv_sec -| older.tv_sec;
    if (diff >= @divTrunc(TIMEDIFF_T_MAX, 1_000_000))
        return TIMEDIFF_T_MAX;
    if (diff <= @divTrunc(TIMEDIFF_T_MIN, 1_000_000))
        return TIMEDIFF_T_MIN;
    return (diff * 1_000_000) + @as(timediff_t, newer.tv_usec) - @as(timediff_t, older.tv_usec);
}

fn usToCeilMs(us: timediff_t) timediff_t {
    return @divTrunc(us, 1000) + @intFromBool(us > 0 and @rem(us, 1000) != 0);
}

export fn Curl_splayget(node: *Curl_tree) callconv(.c) u32 {
    return node.id;
}

export fn Curl_timeouts_init(timeouts: *Curl_timeouts, ptime_base: ?*const curltime) callconv(.c) void {
    var time_base: curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    if (ptime_base) |p| {
        time_base = p.*;
    } else if (!builtin.is_test) {
        timeval_ext.curlx_pnow(&time_base);
    }
    timeouts.tree = null;
    timeouts.time_base_sec = time_base.tv_sec;
}

export fn Curl_timeouts_has_node(node: ?*const Curl_tree) callconv(.c) bool {
    const n = node orelse return false;
    return n.isRegistered();
}

export fn Curl_timeouts_offset_us(timeouts: *Curl_timeouts, pts: *const curltime) callconv(.c) timediff_t {
    const time_base: curltime = .{
        .tv_sec = timeouts.time_base_sec,
        .tv_usec = 0,
    };
    return ptimediffUs(pts, &time_base);
}

export fn Curl_timeouts_next_ms(
    timeouts: *Curl_timeouts,
    pnow: *const curltime,
    pexpire_offset_us: ?*timediff_t,
    pmid: ?*u32,
) callconv(.c) c_int {
    if (timeouts.tree) |t| {
        timeouts.tree = Curl_splay(TIMEDIFF_T_MIN, t);
    }

    if (timeouts.tree) |tree| {
        const elapsed_us = Curl_timeouts_offset_us(timeouts, pnow);
        const delta_us = tree.key - elapsed_us;
        if (pmid) |m| m.* = tree.id;
        if (pexpire_offset_us) |e| e.* = tree.key;
        if (delta_us > 0) {
            const ms = usToCeilMs(delta_us);
            return if (ms > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(ms);
        } else {
            return 0;
        }
    }
    if (pmid) |m| m.* = std.math.maxInt(u32);
    if (pexpire_offset_us) |e| e.* = 0;
    return -1;
}

export fn Curl_splay(key: timediff_t, root_in: ?*Curl_tree) callconv(.c) ?*Curl_tree {
    var root = root_in orelse return null;
    var N: Curl_tree = .{
        .smaller = null,
        .larger = null,
        .same = null,
        .key = 0,
        .id = 0,
        .flags = 0,
    };
    var l: *Curl_tree = &N;
    var r: *Curl_tree = &N;

    while (true) {
        if (key < root.key) {
            const sm = root.smaller orelse break;
            if (key < sm.key) {
                const y = sm;
                root.smaller = y.larger;
                y.larger = root;
                root = y;
                if (root.smaller == null) break;
            }
            r.smaller = root;
            r = root;
            root = root.smaller.?;
        } else if (key > root.key) {
            const lg = root.larger orelse break;
            if (key > lg.key) {
                const y = lg;
                root.larger = y.smaller;
                y.smaller = root;
                root = y;
                if (root.larger == null) break;
            }
            l.larger = root;
            l = root;
            root = root.larger.?;
        } else {
            break;
        }
    }

    l.larger = root.smaller;
    r.smaller = root.larger;
    root.smaller = N.larger;
    root.larger = N.smaller;

    return root;
}

export fn splay(key: timediff_t, root_in: ?*Curl_tree) callconv(.c) ?*Curl_tree {
    return Curl_splay(key, root_in);
}

export fn Curl_splayinsert(
    key: timediff_t,
    root_in: ?*Curl_tree,
    node: *Curl_tree,
    id: u32,
) callconv(.c) ?*Curl_tree {
    node.key = key;
    node.id = id;
    node.same = null;
    node.setRegistered(true);

    var root = root_in;
    if (root) |r_in| {
        const r = Curl_splay(key, r_in).?;
        root = r;
        if (key == r.key) {
            var panchor: *?*Curl_tree = &r.same;
            while (panchor.*) |curr| {
                panchor = &curr.same;
            }
            panchor.* = node;
            return r;
        }
    }

    if (root) |r| {
        if (key < r.key) {
            node.smaller = r.smaller;
            node.larger = r;
            r.smaller = null;
        } else {
            node.larger = r.larger;
            node.smaller = r;
            r.larger = null;
        }
    } else {
        node.smaller = null;
        node.larger = null;
    }

    return node;
}

export fn splayinsert(
    key: timediff_t,
    root_in: ?*Curl_tree,
    node: *Curl_tree,
    id: u32,
) callconv(.c) ?*Curl_tree {
    return Curl_splayinsert(key, root_in, node, id);
}

export fn Curl_timeouts_add_node(
    timeouts: *Curl_timeouts,
    node: *Curl_tree,
    mid: u32,
    offset_us: timediff_t,
) callconv(.c) void {
    timeouts.tree = Curl_splayinsert(offset_us, timeouts.tree, node, mid);
}

export fn Curl_splaygetbest(
    key: timediff_t,
    root_in: ?*Curl_tree,
    removed: *?*Curl_tree,
) callconv(.c) ?*Curl_tree {
    const r_in = root_in orelse {
        removed.* = null;
        return null;
    };

    const root = Curl_splay(TIMEDIFF_T_MIN, r_in).?;
    if (key < root.key) {
        removed.* = null;
        return root;
    }

    if (root.same) |x| {
        x.larger = root.larger;
        x.smaller = root.smaller;
        root.same = null;
        root.setRegistered(false);
        removed.* = root;
        return x;
    }

    const x = root.larger;
    root.setRegistered(false);
    removed.* = root;
    return x;
}

export fn splaygetbest(
    key: timediff_t,
    root_in: ?*Curl_tree,
    removed: *?*Curl_tree,
) callconv(.c) ?*Curl_tree {
    return Curl_splaygetbest(key, root_in, removed);
}

export fn Curl_timeouts_remove_expired(
    timeouts: *Curl_timeouts,
    ts: *const curltime,
    pmid: *u32,
) callconv(.c) bool {
    if (timeouts.tree) |tree| {
        var t: ?*Curl_tree = null;
        const elapsed_us = Curl_timeouts_offset_us(timeouts, ts);
        timeouts.tree = Curl_splaygetbest(elapsed_us, tree, &t);
        if (t) |removed| {
            pmid.* = removed.id;
            return true;
        }
    }
    pmid.* = std.math.maxInt(u32);
    return false;
}

export fn Curl_splayremove(
    root_in: ?*Curl_tree,
    removenode: *Curl_tree,
    newroot: *?*Curl_tree,
) callconv(.c) c_int {
    const r_in = root_in orelse return 1;

    if (!removenode.isRegistered()) {
        return 2;
    }

    const root = Curl_splay(removenode.key, r_in).?;

    if (root.key != removenode.key) {
        return 2;
    }

    if (root != removenode) {
        var panchor: *?*Curl_tree = &root.same;
        while (panchor.*) |curr| : (panchor = &curr.same) {
            if (curr == removenode) {
                panchor.* = removenode.same;
                removenode.same = null;
                removenode.setRegistered(false);
                newroot.* = root;
                return 0;
            }
        }
        return 2;
    }

    var x: ?*Curl_tree = null;
    if (root.same) |same_node| {
        x = same_node;
        same_node.larger = root.larger;
        same_node.smaller = root.smaller;
        root.same = null;
    } else {
        if (root.smaller) |sm| {
            const splayed = Curl_splay(removenode.key, sm).?;
            splayed.larger = root.larger;
            x = splayed;
        } else {
            x = root.larger;
        }
    }
    removenode.setRegistered(false);
    newroot.* = x;
    return 0;
}

export fn splayremove(
    root_in: ?*Curl_tree,
    removenode: *Curl_tree,
    newroot: *?*Curl_tree,
) callconv(.c) c_int {
    return Curl_splayremove(root_in, removenode, newroot);
}

export fn Curl_timeouts_remove_node(
    timeouts: *Curl_timeouts,
    node: *Curl_tree,
) callconv(.c) bool {
    if (node.isRegistered()) {
        _ = Curl_splayremove(timeouts.tree, node, &timeouts.tree);
        return true;
    }
    return false;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "dynbuf init, add, addn, addf, tail, setlen, reset, take, free" {
    var db: dynbuf = undefined;
    curlx_dyn_init(&db, 64);
    defer curlx_dyn_free(&db);

    try std.testing.expectEqual(@as(usize, 0), curlx_dyn_len(&db));
    try std.testing.expect(curlx_dyn_ptr(&db) == null);
    try std.testing.expect(curlx_dyn_uptr(&db) == null);

    try std.testing.expectEqual(CURLE_OK, curlx_dyn_add(&db, "hello"));
    try std.testing.expectEqual(@as(usize, 5), curlx_dyn_len(&db));
    try std.testing.expectEqualStrings("hello", std.mem.span(curlx_dyn_ptr(&db).?));

    try std.testing.expectEqual(CURLE_OK, curlx_dyn_addn(&db, " world!", 6));
    try std.testing.expectEqual(@as(usize, 11), curlx_dyn_len(&db));
    try std.testing.expectEqualStrings("hello world", std.mem.span(curlx_dyn_ptr(&db).?));

    try std.testing.expectEqual(CURLE_OK, curlx_dyn_addf(&db, " %d %s", @as(c_int, 42), "ok".ptr));
    try std.testing.expectEqualStrings("hello world 42 ok", std.mem.span(curlx_dyn_ptr(&db).?));

    // tail
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, curlx_dyn_tail(&db, 100));
    try std.testing.expectEqual(CURLE_OK, curlx_dyn_tail(&db, 5));
    try std.testing.expectEqual(@as(usize, 5), curlx_dyn_len(&db));
    try std.testing.expectEqualStrings("42 ok", std.mem.span(curlx_dyn_ptr(&db).?));

    // setlen
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, curlx_dyn_setlen(&db, 6));
    try std.testing.expectEqual(CURLE_OK, curlx_dyn_setlen(&db, 2));
    try std.testing.expectEqual(@as(usize, 2), curlx_dyn_len(&db));
    try std.testing.expectEqualStrings("42", std.mem.span(curlx_dyn_ptr(&db).?));

    // reset keeps allocation
    const prev_allc = db.allc;
    curlx_dyn_reset(&db);
    try std.testing.expectEqual(@as(usize, 0), curlx_dyn_len(&db));
    try std.testing.expectEqual(prev_allc, db.allc);
    try std.testing.expectEqual(@as(u8, 0), curlx_dyn_uptr(&db).?[0]);

    // take transfers ownership
    try std.testing.expectEqual(CURLE_OK, curlx_dyn_add(&db, "taken"));
    var taken_len: usize = 0;
    const taken = curlx_dyn_take(&db, &taken_len) orelse return error.UnexpectedNull;
    defer mem.free(taken);
    try std.testing.expectEqual(@as(usize, 5), taken_len);
    try std.testing.expectEqualStrings("taken", std.mem.span(taken));
    try std.testing.expect(curlx_dyn_ptr(&db) == null);
    try std.testing.expectEqual(@as(usize, 0), curlx_dyn_len(&db));

    // exceeding toobig frees buffer and returns CURLE_TOO_LARGE
    var small: dynbuf = undefined;
    curlx_dyn_init(&small, 10);
    try std.testing.expectEqual(CURLE_OK, curlx_dyn_add(&small, "123456789"));
    try std.testing.expectEqual(CURLE_TOO_LARGE, curlx_dyn_add(&small, "0"));
    try std.testing.expect(curlx_dyn_ptr(&small) == null);
    try std.testing.expectEqual(@as(usize, 0), curlx_dyn_len(&small));
}

const BufrefTestState = struct {
    var freecount: usize = 0;

    fn testFree(p: ?*anyopaque) callconv(.c) void {
        if (p != null) {
            freecount += 1;
            mem.free(p);
        }
    }
};

test "bufref init, set, ptr, uptr, len, memdup0, free (unit1661)" {
    BufrefTestState.freecount = 0;
    var br: bufref = undefined;
    Curl_bufref_init(&br);
    defer Curl_bufref_free(&br);

    try std.testing.expect(Curl_bufref_ptr(&br) == null);
    try std.testing.expect(Curl_bufref_uptr(&br) == null);
    try std.testing.expectEqual(@as(usize, 0), Curl_bufref_len(&br));
    try std.testing.expect(br.dtor == null);

    const buffer = mem.malloc(13) orelse return error.OutOfMemory;
    @memcpy(buffer[0..13], "hello_bufref\x00");
    Curl_bufref_set(&br, buffer, 13, &BufrefTestState.testFree);

    try std.testing.expectEqual(@as(?[*]const u8, buffer), Curl_bufref_uptr(&br));
    try std.testing.expectEqual(@as(usize, 13), Curl_bufref_len(&br));

    // Curl_bufref_memdup0 triggers previous dtor and null-terminates truncated copy
    try std.testing.expectEqual(CURLE_OK, Curl_bufref_memdup0(&br, "1661", 3));
    try std.testing.expectEqual(@as(usize, 1), BufrefTestState.freecount);
    try std.testing.expectEqual(@as(usize, 3), Curl_bufref_len(&br));
    const dup_ptr = Curl_bufref_ptr(&br) orelse return error.UnexpectedNull;
    try std.testing.expectEqual(@as(u8, 0), dup_ptr[3]);
    try std.testing.expectEqualStrings("166", std.mem.span(dup_ptr));

    Curl_bufref_free(&br);
    try std.testing.expectEqual(@as(usize, 1), BufrefTestState.freecount);
    try std.testing.expect(Curl_bufref_ptr(&br) == null);
    try std.testing.expectEqual(@as(usize, 0), Curl_bufref_len(&br));
}

const LlistTestState = struct {
    var dtor_calls: usize = 0;

    fn dtor(user: ?*anyopaque, elem: ?*anyopaque) callconv(.c) void {
        _ = user;
        _ = elem;
        dtor_calls += 1;
    }
};

test "llist operations (unit1300)" {
    LlistTestState.dtor_calls = 0;
    var list: Curl_llist = undefined;
    Curl_llist_init(&list, &LlistTestState.dtor);

    var d1: c_int = 1;
    var d2: c_int = 2;
    var d3: c_int = 3;
    var n1: Curl_llist_node = undefined;
    var n2: Curl_llist_node = undefined;
    var n3: Curl_llist_node = undefined;
    var n4: Curl_llist_node = undefined;

    try std.testing.expectEqual(@as(usize, 0), Curl_llist_count(&list));
    try std.testing.expect(Curl_llist_head(&list) == null);
    try std.testing.expect(llist_tail(&list) == null);

    llist_insert_next(&list, Curl_llist_head(&list), &d1, &n1);
    try std.testing.expectEqual(@as(usize, 1), Curl_llist_count(&list));
    try std.testing.expectEqual(@as(?*anyopaque, &d1), Curl_node_elem(Curl_llist_head(&list).?));
    try std.testing.expectEqual(Curl_llist_head(&list), llist_tail(&list));
    try std.testing.expectEqual(@as(?*Curl_llist, &list), Curl_node_llist(&n1));

    llist_insert_next(&list, Curl_llist_head(&list), &d3, &n3);
    try std.testing.expectEqual(@as(?*anyopaque, &d3), Curl_node_elem(Curl_node_next(Curl_llist_head(&list).?).?));
    try std.testing.expectEqual(@as(?*anyopaque, &d3), Curl_node_elem(llist_tail(&list).?));

    llist_insert_next(&list, Curl_llist_head(&list), &d2, &n2);
    try std.testing.expectEqual(@as(?*anyopaque, &d2), Curl_node_elem(Curl_node_next(Curl_llist_head(&list).?).?));
    try std.testing.expect(Curl_node_elem(llist_tail(&list).?) != @as(?*anyopaque, &d2));

    // Remove head
    const head = Curl_llist_head(&list).?;
    const element_next = Curl_node_next(head);
    Curl_node_remove(head);
    try std.testing.expectEqual(@as(usize, 2), Curl_llist_count(&list));
    try std.testing.expectEqual(element_next, Curl_llist_head(&list));
    try std.testing.expect(llist_node_prev(Curl_llist_head(&list).?) == null);

    // Insert and remove middle node
    llist_insert_next(&list, Curl_llist_head(&list), &d3, &n4);
    try std.testing.expectEqual(@as(usize, 3), Curl_llist_count(&list));
    const to_remove = Curl_node_next(Curl_llist_head(&list).?).?;
    const next_of_rem = Curl_node_next(to_remove);
    const prev_of_rem = llist_node_prev(to_remove).?;
    Curl_node_remove(to_remove);
    try std.testing.expectEqual(next_of_rem, Curl_node_next(prev_of_rem));
    try std.testing.expectEqual(@as(?*Curl_llist_node, prev_of_rem), llist_node_prev(next_of_rem.?));

    // Remove tail
    const tail_rem = llist_tail(&list).?;
    const prev_tail = llist_node_prev(tail_rem);
    Curl_node_remove(tail_rem);
    try std.testing.expectEqual(prev_tail, llist_tail(&list));

    // Remove last remaining element via Curl_node_take_elem (does not call dtor)
    const dtor_before = LlistTestState.dtor_calls;
    const taken = Curl_node_take_elem(Curl_llist_head(&list));
    try std.testing.expectEqual(@as(?*anyopaque, &d2), taken);
    try std.testing.expectEqual(dtor_before, LlistTestState.dtor_calls);
    try std.testing.expect(Curl_llist_head(&list) == null);
    try std.testing.expect(llist_tail(&list) == null);

    // Append and destroy
    Curl_llist_append(&list, &d1, &n1);
    Curl_llist_append(&list, &d2, &n2);
    Curl_llist_append(&list, &d3, &n3);
    try std.testing.expectEqual(@as(usize, 3), Curl_llist_count(&list));
    Curl_llist_destroy(&list, null);
    try std.testing.expectEqual(@as(usize, 0), Curl_llist_count(&list));
    try std.testing.expectEqual(dtor_before + 3, LlistTestState.dtor_calls);
}

test "slist append, append_nodup, duplicate, free_all" {
    var list: ?*curl_slist = null;
    list = curl_slist_append(list, "first");
    try std.testing.expect(list != null);
    list = curl_slist_append(list, "second");
    try std.testing.expect(list != null);

    const raw_third = mem.strdup("third") orelse return error.OutOfMemory;
    list = Curl_slist_append_nodup(list, raw_third);
    try std.testing.expect(list != null);
    defer curl_slist_free_all(list);

    const dup = Curl_slist_duplicate(list) orelse return error.OutOfMemory;
    defer curl_slist_free_all(dup);

    try std.testing.expect(dup != list);
    try std.testing.expectEqualStrings("first", std.mem.span(dup.data.?));
    try std.testing.expectEqualStrings("second", std.mem.span(dup.next.?.data.?));
    try std.testing.expectEqualStrings("third", std.mem.span(dup.next.?.next.?.data.?));
    try std.testing.expect(dup.next.?.next.?.next == null);
}

test "splay tree insert, getbest, remove, and timeouts (unit1309)" {
    // 1. Timeouts nonzero usec base test from unit1309
    var timeouts: Curl_timeouts = undefined;
    var node: Curl_tree = std.mem.zeroes(Curl_tree);
    const base: curltime = .{ .tv_sec = 10, .tv_usec = 750_000 };
    const deadline: curltime = .{ .tv_sec = 12, .tv_usec = 250_000 };
    const now: curltime = .{ .tv_sec = 11, .tv_usec = 100_000 };

    const orig_deadline_offset = ptimediffUs(&deadline, &base);
    const orig_now_offset = ptimediffUs(&now, &base);

    Curl_timeouts_init(&timeouts, &base);
    const deadline_offset = Curl_timeouts_offset_us(&timeouts, &deadline);
    const now_offset = Curl_timeouts_offset_us(&timeouts, &now);

    try std.testing.expectEqual(@as(timediff_t, base.tv_usec), deadline_offset - orig_deadline_offset);
    try std.testing.expectEqual(@as(timediff_t, base.tv_usec), now_offset - orig_now_offset);

    Curl_timeouts_add_node(&timeouts, &node, 42, deadline_offset);
    try std.testing.expect(Curl_timeouts_has_node(&node));

    var expire_offset: timediff_t = 0;
    var mid: u32 = 0;
    const timeout_ms = Curl_timeouts_next_ms(&timeouts, &now, &expire_offset, &mid);
    try std.testing.expectEqual(@as(c_int, 1150), timeout_ms);
    try std.testing.expectEqual(deadline_offset, expire_offset);
    try std.testing.expectEqual(@as(u32, 42), mid);

    try std.testing.expect(Curl_timeouts_remove_node(&timeouts, &node));
    try std.testing.expect(!Curl_timeouts_has_node(&node));

    // 2. Full splay tree test with duplicates, removals, and best-fit order from unit1309
    const NUM_NODES = 50;
    var nodes: [NUM_NODES * 3]Curl_tree = undefined;
    var root: ?*Curl_tree = null;

    for (0..NUM_NODES) |i| {
        const key: timediff_t = @intCast((541 * i) % 1023);
        root = Curl_splayinsert(key, root, &nodes[i], @intCast(key));
        try std.testing.expect(nodes[i].isRegistered());
    }

    for (NUM_NODES..NUM_NODES * 2) |i| {
        const key: timediff_t = @intCast((541 * i) % 1023);
        root = Curl_splayinsert(key, root, &nodes[i], @intCast(key));
        try std.testing.expect(nodes[i].isRegistered());
    }

    for (NUM_NODES * 2..NUM_NODES * 3) |i| {
        const key: timediff_t = @intCast((541 * i) % 1023);
        root = Curl_splayinsert(key, root, &nodes[i], @intCast(key));
        try std.testing.expect(nodes[i].isRegistered());
    }

    var j: usize = 0;
    while (j < NUM_NODES * 3) : (j += 3) {
        try std.testing.expect(nodes[j].isRegistered());
        try std.testing.expectEqual(@as(c_int, 0), Curl_splayremove(root, &nodes[j], &root));
        try std.testing.expect(!nodes[j].isRegistered());
    }

    j = 0;
    while (j < NUM_NODES * 3) : (j += 3) {
        try std.testing.expect(!nodes[j].isRegistered());
        try std.testing.expect(Curl_splayremove(root, &nodes[j], &root) != 0);
        try std.testing.expect(!nodes[j].isRegistered());
    }

    var tv_now: timediff_t = 0;
    var timeout_last: timediff_t = 0;
    var removed_count: usize = 0;
    var removed: ?*Curl_tree = null;
    while (root != null) {
        var id_val: u32 = std.math.maxInt(u32);
        root = Curl_splaygetbest(tv_now, root, &removed);
        if (removed) |rem| {
            try std.testing.expect(!rem.isRegistered());
            try std.testing.expect(rem.key >= timeout_last);
            timeout_last = rem.key;
            id_val = Curl_splayget(rem);
            try std.testing.expectEqual(@as(timediff_t, id_val), rem.key);
            removed_count += 1;
        } else {
            tv_now += 10;
        }
    }
    try std.testing.expectEqual(@as(usize, NUM_NODES * 2), removed_count);
}
