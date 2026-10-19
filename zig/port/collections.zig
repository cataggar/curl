const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;

// ============================================================================
// 1. lib/ptrarray.c
// ============================================================================

const CURL_PTRARRAY_MAX_GROW: u32 = 16 * 1024;

pub const ptrarray = extern struct {
    data: ?[*]?*anyopaque,
    n: u32,
    capacity: u32,
};

export fn Curl_ptrarray_init(pa: *ptrarray) callconv(.c) void {
    pa.data = null;
    pa.n = 0;
    pa.capacity = 0;
}

export fn Curl_ptrarray_clear(pa: *ptrarray) callconv(.c) void {
    if (pa.data) |d| {
        mem.free(@ptrCast(d));
        pa.data = null;
    }
    pa.n = 0;
    pa.capacity = 0;
}

export fn Curl_ptrarray_count(pa: *ptrarray) callconv(.c) u32 {
    return pa.n;
}

export fn Curl_ptrarray_add(pa: *ptrarray, ptr: ?*anyopaque) callconv(.c) CURLcode {
    if (ptr == null) return CURLE_BAD_FUNCTION_ARGUMENT;
    if (pa.n >= pa.capacity) {
        if (pa.capacity == std.math.maxInt(u32)) return CURLE_OUT_OF_MEMORY;
        const growth: u32 = if (pa.capacity == 0)
            8
        else if ((std.math.maxInt(u32) / 2) > pa.capacity)
            @min(2 * pa.capacity, CURL_PTRARRAY_MAX_GROW)
        else if ((std.math.maxInt(u32) - pa.capacity) > CURL_PTRARRAY_MAX_GROW)
            CURL_PTRARRAY_MAX_GROW
        else
            std.math.maxInt(u32) - pa.capacity;

        const new_cap: usize = @as(usize, pa.capacity + growth);
        const alloc_bytes = std.math.mul(usize, new_cap, @sizeOf(?*anyopaque)) catch return CURLE_OUT_OF_MEMORY;
        const raw = mem.calloc(1, alloc_bytes) orelse return CURLE_OUT_OF_MEMORY;
        const ndata: [*]?*anyopaque = @ptrCast(@alignCast(raw));
        if (pa.n > 0) {
            const old = pa.data.?;
            @memcpy(ndata[0..pa.n], old[0..pa.n]);
        }
        mem.free(@ptrCast(pa.data));
        pa.data = ndata;
        pa.capacity += growth;
    }
    pa.data.?[pa.n] = ptr;
    pa.n += 1;
    return CURLE_OK;
}

export fn Curl_ptrarray_remove(pa: *ptrarray, idx: u32) callconv(.c) ?*anyopaque {
    if (idx < pa.n) {
        const rem: u32 = pa.n - idx - 1;
        const data = pa.data.?;
        const ptr = data[idx];
        data[idx] = null;
        if (rem > 0) {
            std.mem.copyForwards(?*anyopaque, data[idx .. idx + rem], data[idx + 1 .. idx + 1 + rem]);
        }
        pa.n -= 1;
        if (pa.n == 0) {
            Curl_ptrarray_clear(pa);
        }
        return ptr;
    }
    return null;
}

export fn Curl_ptrarray_get(pa: *ptrarray, idx: u32) callconv(.c) ?*anyopaque {
    return if (idx < pa.n) pa.data.?[idx] else null;
}

// ============================================================================
// 2. lib/uint-bset.c
// ============================================================================

pub const uint32_bset = extern struct {
    slots: ?[*]u64,
    nslots: u32,
    first_slot_used: u32,
};

export fn Curl_popcount64(x: u64) callconv(.c) u32 {
    return @as(u32, @popCount(x));
}

export fn Curl_ctz64(x: u64) callconv(.c) u32 {
    return @as(u32, @ctz(x));
}

export fn Curl_uint32_bset_init(bset: *uint32_bset) callconv(.c) void {
    bset.slots = null;
    bset.nslots = 0;
    bset.first_slot_used = 0;
}

export fn Curl_uint32_bset_resize(bset: *uint32_bset, nmax: u32) callconv(.c) CURLcode {
    const nslots: u32 = if (nmax < (std.math.maxInt(u32) - 63))
        (nmax + 63) / 64
    else
        (std.math.maxInt(u32) / 64);

    if (nslots != bset.nslots) {
        const raw = mem.calloc(@as(usize, nslots), @sizeOf(u64)) orelse return CURLE_OUT_OF_MEMORY;
        const slots: [*]u64 = @ptrCast(@alignCast(raw));
        if (bset.slots) |old_slots| {
            const copy_n: usize = @min(nslots, bset.nslots);
            if (copy_n > 0) {
                @memcpy(slots[0..copy_n], old_slots[0..copy_n]);
            }
            mem.free(@ptrCast(old_slots));
        }
        bset.slots = slots;
        bset.nslots = nslots;
        bset.first_slot_used = 0;
    }
    return CURLE_OK;
}

export fn Curl_uint32_bset_destroy(bset: *uint32_bset) callconv(.c) void {
    mem.free(@ptrCast(bset.slots));
    bset.slots = null;
    bset.nslots = 0;
    bset.first_slot_used = 0;
}

pub fn uint32_bset_capacity(bset: *const uint32_bset) u32 {
    return bset.nslots * 64;
}

export fn Curl_uint32_bset_count(bset: *uint32_bset) callconv(.c) u32 {
    var n: u32 = 0;
    if (bset.slots) |slots| {
        var i: u32 = bset.first_slot_used;
        while (i < bset.nslots) : (i += 1) {
            if (slots[i] != 0) {
                n += @as(u32, @popCount(slots[i]));
            }
        }
    }
    return n;
}

export fn Curl_uint32_bset_empty(bset: *uint32_bset) callconv(.c) bool {
    if (bset.slots) |slots| {
        var i: u32 = bset.first_slot_used;
        while (i < bset.nslots) : (i += 1) {
            if (slots[i] != 0) return false;
        }
    }
    return true;
}

export fn Curl_uint32_bset_clear(bset: *uint32_bset) callconv(.c) void {
    if (bset.nslots > 0) {
        @memset(bset.slots.?[0..bset.nslots], 0);
        bset.first_slot_used = std.math.maxInt(u32);
    }
}

export fn Curl_uint32_bset_add(bset: *uint32_bset, i: u32) callconv(.c) bool {
    const islot: u32 = i / 64;
    if (islot >= bset.nslots) return false;
    const shift: u6 = @intCast(i % 64);
    bset.slots.?[islot] |= (@as(u64, 1) << shift);
    if (islot < bset.first_slot_used) {
        bset.first_slot_used = islot;
    }
    return true;
}

export fn Curl_uint32_bset_remove(bset: *uint32_bset, i: u32) callconv(.c) void {
    const islot: u32 = i / 64;
    if (islot < bset.nslots) {
        const shift: u6 = @intCast(i % 64);
        bset.slots.?[islot] &= ~(@as(u64, 1) << shift);
    }
}

export fn Curl_uint32_bset_contains(bset: *uint32_bset, i: u32) callconv(.c) bool {
    const islot: u32 = i / 64;
    if (islot >= bset.nslots) return false;
    const shift: u6 = @intCast(i % 64);
    return (bset.slots.?[islot] & (@as(u64, 1) << shift)) != 0;
}

export fn Curl_uint32_bset_first(bset: *uint32_bset, pfirst: *u32) callconv(.c) bool {
    if (bset.slots) |slots| {
        var i: u32 = bset.first_slot_used;
        while (i < bset.nslots) : (i += 1) {
            if (slots[i] != 0) {
                pfirst.* = (i * 64) + @as(u32, @ctz(slots[i]));
                bset.first_slot_used = i;
                return true;
            }
        }
    }
    pfirst.* = std.math.maxInt(u32);
    bset.first_slot_used = std.math.maxInt(u32);
    return false;
}

export fn Curl_uint32_bset_next(bset: *uint32_bset, last: u32, pnext: *u32) callconv(.c) bool {
    const next_val: u32 = last +% 1;
    var islot: u32 = next_val / 64;
    if (islot < bset.nslots) {
        const slots = bset.slots.?;
        const shift: u6 = @intCast(next_val % 64);
        const x: u64 = slots[islot] >> shift;
        if (x != 0) {
            pnext.* = next_val + @as(u32, @ctz(x));
            return true;
        }
        islot += 1;
        while (islot < bset.nslots) : (islot += 1) {
            if (slots[islot] != 0) {
                pnext.* = (islot * 64) + @as(u32, @ctz(slots[islot]));
                return true;
            }
        }
    }
    pnext.* = std.math.maxInt(u32);
    return false;
}

// ============================================================================
// 3. lib/uint-spbset.c
// ============================================================================

pub const CURL_UINT32_SPBSET_CH_SLOTS: u32 = 4;
pub const CURL_UINT32_SPBSET_CH_MASK: u32 = (CURL_UINT32_SPBSET_CH_SLOTS * 64) - 1;

pub const uint32_spbset_chunk = extern struct {
    next: ?*uint32_spbset_chunk,
    slots: [CURL_UINT32_SPBSET_CH_SLOTS]u64,
    offset: u32,
};

pub const uint32_spbset = extern struct {
    head: uint32_spbset_chunk,
};

export fn Curl_uint32_spbset_init(bset: *uint32_spbset) callconv(.c) void {
    bset.head = .{
        .next = null,
        .slots = .{ 0, 0, 0, 0 },
        .offset = 0,
    };
}

pub fn uint32_spbset_clear(bset: *uint32_spbset) void {
    var chunk_opt = bset.head.next;
    while (chunk_opt) |chunk| {
        const next = chunk.next;
        mem.free(@ptrCast(chunk));
        chunk_opt = next;
    }
    bset.head = .{
        .next = null,
        .slots = .{ 0, 0, 0, 0 },
        .offset = 0,
    };
}

export fn Curl_uint32_spbset_destroy(bset: *uint32_spbset) callconv(.c) void {
    uint32_spbset_clear(bset);
}

export fn Curl_uint32_spbset_count(bset: *uint32_spbset) callconv(.c) u32 {
    var n: u32 = 0;
    var chunk_opt: ?*uint32_spbset_chunk = &bset.head;
    while (chunk_opt) |chunk| : (chunk_opt = chunk.next) {
        for (chunk.slots) |slot| {
            if (slot != 0) {
                n += @as(u32, @popCount(slot));
            }
        }
    }
    return n;
}

fn uint32_spbset_empty_chunk(chunk: *const uint32_spbset_chunk) bool {
    for (chunk.slots) |slot| {
        if (slot != 0) return false;
    }
    return true;
}

fn uint32_spbset_unlink_empty(bset: *uint32_spbset, for_offset: u32) ?*uint32_spbset_chunk {
    var chunk_opt: ?*uint32_spbset_chunk = &bset.head;
    var panchor: ?*?*uint32_spbset_chunk = null;
    while (chunk_opt) |chunk| {
        if (uint32_spbset_empty_chunk(chunk)) break;
        panchor = &chunk.next;
        chunk_opt = chunk.next;
    }
    if (chunk_opt) |chunk| {
        if (chunk == &bset.head) {
            if (bset.head.next == null or for_offset < bset.head.next.?.offset) {
                return &bset.head;
            }
            const next_chunk = bset.head.next.?;
            bset.head = next_chunk.*;
            next_chunk.* = .{
                .next = null,
                .slots = .{ 0, 0, 0, 0 },
                .offset = 0,
            };
            return next_chunk;
        } else {
            panchor.?.* = chunk.next;
            chunk.* = .{
                .next = null,
                .slots = .{ 0, 0, 0, 0 },
                .offset = 0,
            };
            return chunk;
        }
    }
    return null;
}

fn uint32_spbset_insert_chunk(bset: *uint32_spbset, nchunk: *uint32_spbset_chunk) *uint32_spbset_chunk {
    if (nchunk.offset < bset.head.offset) {
        const offset = nchunk.offset;
        nchunk.* = bset.head;
        bset.head = .{
            .next = nchunk,
            .slots = .{ 0, 0, 0, 0 },
            .offset = offset,
        };
        return &bset.head;
    }
    var panchor: *?*uint32_spbset_chunk = &bset.head.next;
    while (panchor.*) |chunk| : (panchor = &chunk.next) {
        if (chunk.offset > nchunk.offset) {
            nchunk.next = chunk;
            panchor.* = nchunk;
            return nchunk;
        }
    }
    panchor.* = nchunk;
    return nchunk;
}

fn uint32_spbset_get_chunk(bset: ?*uint32_spbset, i: u32, grow: bool) ?*uint32_spbset_chunk {
    const set = bset orelse return null;
    const i_offset: u32 = i & ~CURL_UINT32_SPBSET_CH_MASK;

    var chunk_opt: ?*uint32_spbset_chunk = &set.head;
    while (chunk_opt) |chunk| : (chunk_opt = chunk.next) {
        if (chunk.offset == i_offset) {
            return chunk;
        } else if (chunk.offset > i_offset) {
            break;
        }
    }
    if (!grow) return null;

    var chunk: *uint32_spbset_chunk = undefined;
    if (uint32_spbset_unlink_empty(set, i_offset)) |reused| {
        reused.offset = i_offset;
        if (reused == &set.head) return &set.head;
        chunk = reused;
    } else {
        const raw = mem.calloc(1, @sizeOf(uint32_spbset_chunk)) orelse return null;
        chunk = @ptrCast(@alignCast(raw));
        chunk.offset = i_offset;
    }

    return uint32_spbset_insert_chunk(set, chunk);
}

export fn Curl_uint32_spbset_add(bset: ?*uint32_spbset, i: u32) callconv(.c) bool {
    const chunk = uint32_spbset_get_chunk(bset, i, true) orelse return false;
    const rel = i - chunk.offset;
    const shift: u6 = @intCast(rel % 64);
    chunk.slots[rel / 64] |= (@as(u64, 1) << shift);
    return true;
}

export fn Curl_uint32_spbset_remove(bset: ?*uint32_spbset, i: u32) callconv(.c) void {
    if (uint32_spbset_get_chunk(bset, i, false)) |chunk| {
        const rel = i - chunk.offset;
        const shift: u6 = @intCast(rel % 64);
        chunk.slots[rel / 64] &= ~(@as(u64, 1) << shift);
    }
}

export fn Curl_uint32_spbset_contains(bset: ?*uint32_spbset, i: u32) callconv(.c) bool {
    if (uint32_spbset_get_chunk(bset, i, false)) |chunk| {
        const rel = i - chunk.offset;
        const shift: u6 = @intCast(rel % 64);
        return (chunk.slots[rel / 64] & (@as(u64, 1) << shift)) != 0;
    }
    return false;
}

export fn Curl_uint32_spbset_first(bset: *uint32_spbset, pfirst: *u32) callconv(.c) bool {
    var chunk_opt: ?*uint32_spbset_chunk = &bset.head;
    while (chunk_opt) |chunk| : (chunk_opt = chunk.next) {
        var i: u32 = 0;
        while (i < CURL_UINT32_SPBSET_CH_SLOTS) : (i += 1) {
            if (chunk.slots[i] != 0) {
                pfirst.* = chunk.offset + (i * 64) + @as(u32, @ctz(chunk.slots[i]));
                return true;
            }
        }
    }
    pfirst.* = 0;
    return false;
}

fn uint32_spbset_chunk_first(chunk: *const uint32_spbset_chunk, pfirst: *u32) bool {
    var i: u32 = 0;
    while (i < CURL_UINT32_SPBSET_CH_SLOTS) : (i += 1) {
        if (chunk.slots[i] != 0) {
            pfirst.* = chunk.offset + (i * 64) + @as(u32, @ctz(chunk.slots[i]));
            return true;
        }
    }
    pfirst.* = std.math.maxInt(u32);
    return false;
}

fn uint32_spbset_chunk_next(chunk: *const uint32_spbset_chunk, last: u32, pnext: *u32) bool {
    if (chunk.offset <= last) {
        var i: u32 = (last - chunk.offset) / 64;
        if (i < CURL_UINT32_SPBSET_CH_SLOTS) {
            const shift: u6 = @intCast(last % 64);
            const x: u64 = chunk.slots[i] >> shift;
            if (x != 0) {
                pnext.* = last + @as(u32, @ctz(x));
                return true;
            }
            i += 1;
            while (i < CURL_UINT32_SPBSET_CH_SLOTS) : (i += 1) {
                if (chunk.slots[i] != 0) {
                    pnext.* = chunk.offset + (i * 64) + @as(u32, @ctz(chunk.slots[i]));
                    return true;
                }
            }
        }
    }
    pnext.* = std.math.maxInt(u32);
    return false;
}

export fn Curl_uint32_spbset_next(bset: *uint32_spbset, last: u32, pnext: *u32) callconv(.c) bool {
    const next_val: u32 = last +% 1;
    const last_offset: u32 = next_val & ~CURL_UINT32_SPBSET_CH_MASK;

    var chunk_opt: ?*uint32_spbset_chunk = &bset.head;
    while (chunk_opt) |chunk| : (chunk_opt = chunk.next) {
        if (chunk.offset >= last_offset) break;
    }

    if (chunk_opt) |chunk| {
        if (chunk.offset == last_offset) {
            if (uint32_spbset_chunk_next(chunk, next_val, pnext)) {
                return true;
            }
            chunk_opt = chunk.next;
        }
    }

    while (chunk_opt) |chunk| : (chunk_opt = chunk.next) {
        if (uint32_spbset_chunk_first(chunk, pnext)) {
            return true;
        }
    }
    pnext.* = std.math.maxInt(u32);
    return false;
}

// ============================================================================
// 4. lib/uint-table.c
// ============================================================================

pub const uint32_tbl = extern struct {
    rows: ?[*]?*anyopaque,
    nrows: u32,
    nentries: u32,
    last_key_added: u32,
};

export fn Curl_uint32_tbl_init(tbl: *uint32_tbl) callconv(.c) void {
    tbl.rows = null;
    tbl.nrows = 0;
    tbl.nentries = 0;
    tbl.last_key_added = std.math.maxInt(u32);
}

fn uint32_tbl_clear_rows(tbl: *uint32_tbl, from: u32, upto_excluding: u32) void {
    const end: u32 = @min(upto_excluding, tbl.nrows);
    if (tbl.rows) |rows| {
        var i: u32 = from;
        while (i < end) : (i += 1) {
            if (rows[i] != null) {
                rows[i] = null;
                tbl.nentries -= 1;
            }
        }
    }
}

export fn Curl_uint32_tbl_resize(tbl: *uint32_tbl, nrows: u32) callconv(.c) CURLcode {
    if (nrows == 0) return CURLE_BAD_FUNCTION_ARGUMENT;
    if (nrows != tbl.nrows) {
        const raw = mem.calloc(@as(usize, nrows), @sizeOf(?*anyopaque)) orelse return CURLE_OUT_OF_MEMORY;
        const rows: [*]?*anyopaque = @ptrCast(@alignCast(raw));
        if (tbl.rows) |old_rows| {
            const copy_n: usize = @min(nrows, tbl.nrows);
            if (copy_n > 0) {
                @memcpy(rows[0..copy_n], old_rows[0..copy_n]);
            }
            if (nrows < tbl.nrows) {
                uint32_tbl_clear_rows(tbl, nrows, tbl.nrows);
            }
            mem.free(@ptrCast(old_rows));
        }
        tbl.rows = rows;
        tbl.nrows = nrows;
    }
    return CURLE_OK;
}

pub fn uint32_tbl_clear(tbl: *uint32_tbl) void {
    uint32_tbl_clear_rows(tbl, 0, tbl.nrows);
    tbl.last_key_added = std.math.maxInt(u32);
}

export fn Curl_uint32_tbl_destroy(tbl: *uint32_tbl) callconv(.c) void {
    uint32_tbl_clear(tbl);
    mem.free(@ptrCast(tbl.rows));
    tbl.rows = null;
    tbl.nrows = 0;
    tbl.nentries = 0;
    tbl.last_key_added = 0;
}

export fn Curl_uint32_tbl_capacity(tbl: *uint32_tbl) callconv(.c) u32 {
    return tbl.nrows;
}

export fn Curl_uint32_tbl_count(tbl: *uint32_tbl) callconv(.c) u32 {
    return tbl.nentries;
}

export fn Curl_uint32_tbl_get(tbl: *uint32_tbl, key: u32) callconv(.c) ?*anyopaque {
    return if (key < tbl.nrows) tbl.rows.?[key] else null;
}

export fn Curl_uint32_tbl_add(tbl: *uint32_tbl, entry: ?*anyopaque, pkey: ?*u32) callconv(.c) bool {
    const out_key = pkey orelse return false;
    if (entry == null) return false;
    out_key.* = std.math.maxInt(u32);
    if (tbl.nentries == tbl.nrows) return false;

    const rows = tbl.rows.?;
    const start_pos: u32 = @min(tbl.last_key_added, tbl.nrows) +% 1;
    var key: u32 = start_pos;
    while (key < tbl.nrows) : (key += 1) {
        if (rows[key] == null) {
            rows[key] = entry;
            tbl.nentries += 1;
            tbl.last_key_added = key;
            out_key.* = key;
            return true;
        }
    }
    key = 0;
    while (key < start_pos) : (key += 1) {
        if (rows[key] == null) {
            rows[key] = entry;
            tbl.nentries += 1;
            tbl.last_key_added = key;
            out_key.* = key;
            return true;
        }
    }
    return false;
}

export fn Curl_uint32_tbl_remove(tbl: *uint32_tbl, key: u32) callconv(.c) void {
    if (key < tbl.nrows) {
        uint32_tbl_clear_rows(tbl, key, key + 1);
    }
}

export fn Curl_uint32_tbl_contains(tbl: *uint32_tbl, key: u32) callconv(.c) bool {
    return if (key < tbl.nrows) tbl.rows.?[key] != null else false;
}

fn uint32_tbl_next_at(tbl: *uint32_tbl, start_key: u32, pkey: *u32, pentry: *?*anyopaque) bool {
    if (tbl.rows) |rows| {
        var key: u32 = start_key;
        while (key < tbl.nrows) : (key += 1) {
            if (rows[key]) |entry| {
                pkey.* = key;
                pentry.* = entry;
                return true;
            }
        }
    }
    pkey.* = std.math.maxInt(u32);
    pentry.* = null;
    return false;
}

export fn Curl_uint32_tbl_first(tbl: *uint32_tbl, pkey: ?*u32, pentry: ?*?*anyopaque) callconv(.c) bool {
    const out_key = pkey orelse return false;
    const out_entry = pentry orelse return false;
    if (tbl.nentries != 0 and uint32_tbl_next_at(tbl, 0, out_key, out_entry)) {
        return true;
    }
    out_key.* = std.math.maxInt(u32);
    out_entry.* = null;
    return false;
}

export fn Curl_uint32_tbl_next(tbl: *uint32_tbl, last_key: u32, pkey: ?*u32, pentry: ?*?*anyopaque) callconv(.c) bool {
    const out_key = pkey orelse return false;
    const out_entry = pentry orelse return false;
    if (uint32_tbl_next_at(tbl, last_key +% 1, out_key, out_entry)) {
        return true;
    }
    out_key.* = std.math.maxInt(u32);
    out_entry.* = null;
    return false;
}

// ============================================================================
// 5. lib/u8_strset.c
// ============================================================================

pub const CURL_U8_STRSET_START_BITS: u8 = 3;
pub const CURL_U8_STRSET_START_DIM: usize = 1 << CURL_U8_STRSET_START_BITS;

pub const u8_strset = extern struct {
    data: [*]?[*:0]u8,
    ids: [*]u8,
    psl: [*]u8,
    sdata: [CURL_U8_STRSET_START_DIM]?[*:0]u8,
    sids: [CURL_U8_STRSET_START_DIM]u8,
    spsl: [CURL_U8_STRSET_START_DIM]u8,
    count: u16,
    slotbits: u8,
    slotmask: u8,
};

inline fn u8SlotCnt(bits: u8) u16 {
    return if (bits != 0) @as(u16, 1) << @intCast(bits) else 0;
}

inline fn u8SlotMask(bits: u8) u8 {
    return @truncate((@as(u16, 1) << @intCast(bits)) - 1);
}

inline fn u8StrsetSlotCnt(set: *const u8_strset) u16 {
    return u8SlotCnt(set.slotbits);
}

export fn Curl_u8_strset_init(set: *u8_strset) callconv(.c) void {
    @memset(&set.sdata, null);
    @memset(&set.sids, 0);
    @memset(&set.spsl, 0);
    set.data = &set.sdata;
    set.ids = &set.sids;
    set.psl = &set.spsl;
    set.slotbits = CURL_U8_STRSET_START_BITS;
    set.slotmask = u8SlotMask(set.slotbits);
    set.count = 0;
}

export fn Curl_u8_strset_clear(set: *u8_strset) callconv(.c) void {
    const cnt: usize = u8StrsetSlotCnt(set);
    for (0..cnt) |i| {
        if (set.data[i]) |p| {
            mem.free(@ptrCast(p));
            set.data[i] = null;
        }
    }
    const sdata_ptr: [*]?[*:0]u8 = &set.sdata;
    if (set.data != sdata_ptr) {
        mem.free(@ptrCast(set.data));
    }
    Curl_u8_strset_init(set);
}

fn u8_strset_addn(set: *u8_strset, id_in: u8, val_in: [*:0]u8) void {
    var id: u8 = id_in;
    var val: [*:0]u8 = val_in;
    var i: u8 = id & set.slotmask;
    var psl: u8 = 0;
    while (set.data[i] != null) {
        if (psl > set.psl[i]) {
            const tmpdata = set.data[i].?;
            set.data[i] = val;
            val = tmpdata;

            const tmppsl = set.psl[i];
            set.psl[i] = psl;
            psl = tmppsl;

            const tmpid = set.ids[i];
            set.ids[i] = id;
            id = tmpid;
        }
        i = (i +% 1) & set.slotmask;
        psl +%= 1;
    }
    set.ids[i] = id;
    set.data[i] = val;
    set.psl[i] = psl;
    set.count += 1;
}

fn u8_strset_grow(set: *u8_strset) bool {
    if (set.slotbits >= 8) return false;
    const nslotbits: u8 = set.slotbits + 1;
    const nslots: usize = u8SlotCnt(nslotbits);
    const d = mem.calloc(1, (nslots * @sizeOf(?[*:0]u8)) + (2 * nslots)) orelse return false;

    const prev_data = set.data;
    const prev_ids = set.ids;
    const prev_slots = set.slotbits;

    set.data = @ptrCast(@alignCast(d));
    set.ids = d + (nslots * @sizeOf(?[*:0]u8));
    set.psl = set.ids + nslots;
    set.slotbits = nslotbits;
    set.slotmask = u8SlotMask(set.slotbits);
    set.count = 0;

    const prev_cnt: usize = u8SlotCnt(prev_slots);
    for (0..prev_cnt) |i| {
        if (prev_data[i]) |val| {
            u8_strset_addn(set, prev_ids[i], val);
        }
    }
    const sdata_ptr: [*]?[*:0]u8 = &set.sdata;
    if (prev_data != sdata_ptr) {
        mem.free(@ptrCast(prev_data));
    }
    return true;
}

fn u8_strset_get_index(set: *u8_strset, id: u8, pindex: *u8) bool {
    var i: u8 = id & set.slotmask;
    var psl: u8 = 0;
    while (set.data[i] != null and psl <= set.psl[i]) {
        if (set.ids[i] == id) {
            pindex.* = i;
            return true;
        }
        i = (i +% 1) & set.slotmask;
        psl +%= 1;
    }
    pindex.* = 0;
    return false;
}

export fn Curl_u8_strset_count(set: *u8_strset) callconv(.c) u16 {
    return set.count;
}

pub export fn Curl_u8_strset_get(set: *u8_strset, id: u8) callconv(.c) ?[*:0]const u8 {
    var i: u8 = 0;
    if (u8_strset_get_index(set, id, &i)) {
        return set.data[i];
    }
    return null;
}

pub export fn Curl_u8_strset_setn(set: *u8_strset, id: u8, str: ?[*:0]u8) callconv(.c) CURLcode {
    const val = str orelse {
        Curl_u8_strset_unset(set, id);
        return CURLE_OK;
    };

    var i: u8 = 0;
    if (u8_strset_get_index(set, id, &i)) {
        mem.free(@ptrCast(set.data[i]));
        set.data[i] = val;
        return CURLE_OK;
    }

    if (set.count >= u8StrsetSlotCnt(set) and !u8_strset_grow(set)) {
        mem.free(@ptrCast(val));
        return CURLE_OUT_OF_MEMORY;
    }

    u8_strset_addn(set, id, val);
    return CURLE_OK;
}

pub export fn Curl_u8_strset_setx(set: *u8_strset, id: u8, str: ?[*]const u8, slen: usize) callconv(.c) CURLcode {
    const s = str orelse {
        Curl_u8_strset_unset(set, id);
        return CURLE_OK;
    };

    if (slen >= std.math.maxInt(usize)) return CURLE_OUT_OF_MEMORY;
    const raw = mem.malloc(slen + 1) orelse return CURLE_OUT_OF_MEMORY;
    if (slen > 0) {
        @memcpy(raw[0..slen], s[0..slen]);
    }
    raw[slen] = 0;
    const val: [*:0]u8 = @ptrCast(raw);
    return Curl_u8_strset_setn(set, id, val);
}

pub fn u8_strset_set(set: *u8_strset, id: u8, str: ?[*:0]const u8) CURLcode {
    if (str) |s| {
        return Curl_u8_strset_setx(set, id, s, std.mem.len(s));
    }
    return Curl_u8_strset_setx(set, id, null, 0);
}

fn u8_strset_unset_impl(set: *u8_strset, id: u8, zero: bool) void {
    var i: u8 = 0;
    if (u8_strset_get_index(set, id, &i)) {
        if (set.data[i]) |s| {
            if (zero) {
                const len = std.mem.len(s);
                if (len > 0) {
                    std.crypto.secureZero(u8, s[0..len]);
                }
            }
            mem.free(@ptrCast(s));
            set.data[i] = null;
        }
        set.ids[i] = 0;
        set.psl[i] = 0;
        set.count -= 1;
        var j: u8 = (i +% 1) & set.slotmask;
        while (set.data[j] != null and set.psl[j] != 0) {
            set.data[i] = set.data[j];
            set.ids[i] = set.ids[j];
            set.psl[i] = set.psl[j] - 1;
            set.data[j] = null;
            set.ids[j] = 0;
            set.psl[j] = 0;
            i = j;
            j = (i +% 1) & set.slotmask;
        }
    }
}

pub export fn Curl_u8_strset_unset(set: *u8_strset, id: u8) callconv(.c) void {
    u8_strset_unset_impl(set, id, false);
}

pub export fn Curl_u8_strset_unset0(set: *u8_strset, id: u8) callconv(.c) void {
    u8_strset_unset_impl(set, id, true);
}

export fn Curl_u8_strset_copy(dest: *u8_strset, src: *u8_strset) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    Curl_u8_strset_clear(dest);
    const cnt: usize = u8StrsetSlotCnt(src);
    var i: usize = 0;
    while (result == CURLE_OK and i < cnt) : (i += 1) {
        if (src.data[i]) |s| {
            result = u8_strset_set(dest, src.ids[i], s);
        }
    }
    return result;
}

// ============================================================================
// 6. lib/u32_ptrset.c
// ============================================================================

pub const Curl_u32_ptrset_dtor = *const fn (u32, ?*anyopaque) callconv(.c) void;
pub const Curl_u32_ptrset_visit_cb = *const fn (u32, ?*anyopaque, ?*anyopaque) callconv(.c) bool;

pub const u32_ptrset = extern struct {
    data: ?[*]?*anyopaque,
    ids: ?[*]u32,
    psl: ?[*]u32,
    slotmask: u32,
    count: u32,
    dtor: ?Curl_u32_ptrset_dtor,
    slotbits: u8,
};

inline fn u32SlotCnt(bits: u8) u32 {
    return if (bits != 0) @as(u32, 1) << @intCast(bits) else 0;
}

inline fn u32PtrsetSlotCnt(set: *const u32_ptrset) u32 {
    return u32SlotCnt(set.slotbits);
}

export fn Curl_u32_ptrset_init(set: *u32_ptrset, dtor: ?Curl_u32_ptrset_dtor) callconv(.c) void {
    set.data = null;
    set.ids = null;
    set.psl = null;
    set.slotmask = 0;
    set.count = 0;
    set.dtor = dtor;
    set.slotbits = 0;
}

export fn Curl_u32_ptrset_clear(set: *u32_ptrset) callconv(.c) void {
    if (set.dtor) |dtor| {
        if (set.data) |data| {
            const ids = set.ids.?;
            const cnt: usize = u32PtrsetSlotCnt(set);
            for (0..cnt) |i| {
                if (data[i]) |p| {
                    dtor(ids[i], p);
                }
            }
        }
    }
    if (set.data) |data| {
        mem.free(@ptrCast(data));
    }
    Curl_u32_ptrset_init(set, set.dtor);
}

fn u32_ptrset_add(set: *u32_ptrset, id_in: u32, ptr_in: *anyopaque) void {
    var id: u32 = id_in;
    var ptr: *anyopaque = ptr_in;
    var i: u32 = id & set.slotmask;
    var psl: u32 = 0;
    const data = set.data.?;
    const ids = set.ids.?;
    const psls = set.psl.?;
    while (data[i] != null) {
        if (psl > psls[i]) {
            const tmpdata = data[i].?;
            data[i] = ptr;
            ptr = tmpdata;

            const tmppsl = psls[i];
            psls[i] = psl;
            psl = tmppsl;

            const tmpid = ids[i];
            ids[i] = id;
            id = tmpid;
        }
        i = (i +% 1) & set.slotmask;
        psl +%= 1;
    }
    ids[i] = id;
    data[i] = ptr;
    psls[i] = psl;
    set.count += 1;
}

fn u32_ptrset_grow(set: *u32_ptrset) bool {
    if (set.slotbits >= 31) return false;
    const nslotbits: u8 = if (set.slotbits != 0) set.slotbits + 1 else 5;
    const nslots: usize = u32SlotCnt(nslotbits);
    const slot_size: usize = @sizeOf(?*anyopaque) + (2 * @sizeOf(u32));
    if (nslots > (std.math.maxInt(usize) / slot_size)) return false;

    const d = mem.calloc(1, nslots * slot_size) orelse return false;

    const prev_data = set.data;
    const prev_ids = set.ids;
    const pslotbits = set.slotbits;

    const data_ptr: [*]?*anyopaque = @ptrCast(@alignCast(d));
    const ids_ptr: [*]u32 = @ptrCast(@alignCast(data_ptr + nslots));
    const psl_ptr: [*]u32 = ids_ptr + nslots;

    set.data = data_ptr;
    set.ids = ids_ptr;
    set.psl = psl_ptr;
    set.slotbits = nslotbits;
    set.slotmask = (@as(u32, 1) << @intCast(set.slotbits)) - 1;
    set.count = 0;

    if (prev_data) |pdata| {
        const pids = prev_ids.?;
        const prev_cnt: usize = u32SlotCnt(pslotbits);
        for (0..prev_cnt) |i| {
            if (pdata[i]) |p| {
                u32_ptrset_add(set, pids[i], p);
            }
        }
        mem.free(@ptrCast(pdata));
    }
    return true;
}

fn u32_ptrset_get_index(set: *u32_ptrset, id: u32, pindex: *u32) bool {
    const data = set.data orelse return false;
    const ids = set.ids.?;
    const psls = set.psl.?;
    var i: u32 = id & set.slotmask;
    var psl: u32 = 0;
    while (data[i] != null and psl <= psls[i]) {
        if (ids[i] == id) {
            pindex.* = i;
            return true;
        }
        i = (i +% 1) & set.slotmask;
        psl +%= 1;
    }
    pindex.* = 0;
    return false;
}

export fn Curl_u32_ptrset_count(set: *u32_ptrset) callconv(.c) u32 {
    return set.count;
}

export fn Curl_u32_ptrset_get(set: *u32_ptrset, id: u32) callconv(.c) ?*anyopaque {
    var i: u32 = 0;
    if (u32_ptrset_get_index(set, id, &i)) {
        return set.data.?[i];
    }
    return null;
}

export fn Curl_u32_ptrset_set(set: *u32_ptrset, id: u32, ptr: ?*anyopaque) callconv(.c) CURLcode {
    const p = ptr orelse {
        Curl_u32_ptrset_unset(set, id);
        return CURLE_OK;
    };

    var i: u32 = 0;
    if (u32_ptrset_get_index(set, id, &i)) {
        const data = set.data.?;
        const ids = set.ids.?;
        if (set.dtor) |dtor| {
            if (data[i] != p) {
                dtor(ids[i], data[i]);
            }
        }
        data[i] = p;
        return CURLE_OK;
    }

    if (set.count >= u32PtrsetSlotCnt(set) and !u32_ptrset_grow(set)) {
        return CURLE_OUT_OF_MEMORY;
    }

    u32_ptrset_add(set, id, p);
    return CURLE_OK;
}

export fn Curl_u32_ptrset_unset(set: *u32_ptrset, id: u32) callconv(.c) void {
    var i: u32 = 0;
    if (u32_ptrset_get_index(set, id, &i)) {
        const data = set.data.?;
        const ids = set.ids.?;
        const psls = set.psl.?;
        if (set.dtor) |dtor| {
            dtor(ids[i], data[i]);
        }
        data[i] = null;
        ids[i] = 0;
        psls[i] = 0;
        set.count -= 1;
        var j: u32 = (i +% 1) & set.slotmask;
        while (data[j] != null and psls[j] != 0) {
            data[i] = data[j];
            ids[i] = ids[j];
            psls[i] = psls[j] - 1;
            data[j] = null;
            ids[j] = 0;
            psls[j] = 0;
            i = j;
            j = (i +% 1) & set.slotmask;
        }
    }
}

export fn Curl_u32_ptrset_visit(set: *u32_ptrset, cb: Curl_u32_ptrset_visit_cb, user_data: ?*anyopaque) callconv(.c) void {
    const cnt: usize = u32PtrsetSlotCnt(set);
    if (cnt == 0) return;
    const data = set.data orelse return;
    const ids = set.ids.?;
    for (0..cnt) |i| {
        if (data[i]) |p| {
            if (!cb(ids[i], p, user_data)) break;
        }
    }
}

// ============================================================================
// 7. lib/hash.c
// ============================================================================

pub const Curl_hash_dtor = *const fn (?*anyopaque) callconv(.c) void;
pub const Curl_hash_elem_dtor = *const fn (?*const anyopaque, usize, ?*anyopaque) callconv(.c) void;

pub const Curl_hash_type = c_uint;
pub const CURL_HASH_TYPE_BYTES: Curl_hash_type = 0;
pub const CURL_HASH_TYPE_SOCKET: Curl_hash_type = 1;
pub const CURL_HASH_TYPE_LAST: Curl_hash_type = 2;

pub const Curl_hash_element = extern struct {
    next: ?*Curl_hash_element,
    ptr: ?*anyopaque,
    dtor: ?Curl_hash_elem_dtor,
    key_len: usize,
    key: [1]u8,
};

pub const Curl_hash = extern struct {
    table: ?[*]?*Curl_hash_element,
    dtor: ?Curl_hash_dtor,
    slots: usize,
    size: usize,
    type: u8,
};

pub const Curl_hash_iterator = extern struct {
    hash: ?*Curl_hash,
    slot_index: usize,
    current: ?*Curl_hash_element,
};

const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
const use_libcurl_rand = (builtin.output_mode == .Lib);

const libcurl_rand = struct {
    extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
};

var hash_seed: usize = 0;
var hash_seeded: bool = false;

export fn Curl_hash_global_init() callconv(.c) CURLcode {
    if (hash_seeded) return CURLE_OK;

    var buf: [@sizeOf(usize)]u8 = undefined;
    if (use_libcurl_rand) {
        const result = libcurl_rand.Curl_rand_bytes(null, &buf, buf.len);
        if (result != CURLE_OK) return result;
    } else {
        for (&buf, 0..) |*b, idx| {
            b.* = @truncate(idx + 1);
        }
    }

    var seed: usize = 0;
    for (buf) |b| {
        seed = (seed << 8) | @as(usize, b);
    }

    hash_seed = if (seed != 0) seed else 1;
    hash_seeded = true;
    return CURLE_OK;
}

pub fn hash_str_seeded(key: ?*const anyopaque, key_length: usize, slots_num: usize, seed: usize) usize {
    var h: usize = 5381 ^ seed;
    if (key_length > 0) {
        if (key) |k| {
            const key_chars: [*]const c_char = @ptrCast(k);
            for (key_chars[0..key_length]) |c| {
                const j: usize = if (@typeInfo(c_char).int.signedness == .signed)
                    @bitCast(@as(isize, c))
                else
                    @as(usize, c);
                h +%= h << 5;
                h ^= j;
            }
        }
    }
    return h % slots_num;
}

pub fn hash_str(key: ?*const anyopaque, key_length: usize, slots_num: usize) usize {
    return hash_str_seeded(key, key_length, slots_num, hash_seed);
}

inline fn hash_elem_key(he: *Curl_hash_element) [*]u8 {
    const base: [*]u8 = @ptrCast(he);
    return base + @offsetOf(Curl_hash_element, "key");
}

fn hash_socket(key: ?*const anyopaque, key_length: usize, slots_num: usize) usize {
    if (key_length != @sizeOf(curl_socket_t)) return 0;
    const k = key orelse return 0;
    var socket: curl_socket_t = 0;
    const src: [*]const u8 = @ptrCast(k);
    @memcpy(std.mem.asBytes(&socket), src[0..@sizeOf(curl_socket_t)]);
    if (builtin.os.tag == .windows) {
        return socket % slots_num;
    } else {
        const s_slots: curl_socket_t = @intCast(slots_num);
        const rem = @rem(socket, s_slots);
        return @bitCast(@as(isize, rem));
    }
}

fn compare_socket(key1: ?*const anyopaque, key1_len: usize, key2: ?*const anyopaque, key2_len: usize) bool {
    if (key1_len != @sizeOf(curl_socket_t) or key2_len != @sizeOf(curl_socket_t)) return false;
    const k1: [*]const u8 = @ptrCast(key1 orelse return false);
    const k2: [*]const u8 = @ptrCast(key2 orelse return false);
    var socket1: curl_socket_t = 0;
    var socket2: curl_socket_t = 0;
    @memcpy(std.mem.asBytes(&socket1), k1[0..@sizeOf(curl_socket_t)]);
    @memcpy(std.mem.asBytes(&socket2), k2[0..@sizeOf(curl_socket_t)]);
    return socket1 == socket2;
}

fn compare_bytes(key1: ?*const anyopaque, key1_len: usize, key2: ?*const anyopaque, key2_len: usize) bool {
    if (key1_len != key2_len) return false;
    if (key1_len == 0) return true;
    const k1: [*]const u8 = @ptrCast(key1 orelse return false);
    const k2: [*]const u8 = @ptrCast(key2 orelse return false);
    return std.mem.eql(u8, k1[0..key1_len], k2[0..key2_len]);
}

inline fn hash_compute(hash_type: u8, key: ?*const anyopaque, key_len: usize, slots: usize) usize {
    return if (hash_type == CURL_HASH_TYPE_SOCKET)
        hash_socket(key, key_len, slots)
    else
        hash_str(key, key_len, slots);
}

inline fn hash_compare(hash_type: u8, key1: ?*const anyopaque, key1_len: usize, key2: ?*const anyopaque, key2_len: usize) bool {
    return if (hash_type == CURL_HASH_TYPE_SOCKET)
        compare_socket(key1, key1_len, key2, key2_len)
    else
        compare_bytes(key1, key1_len, key2, key2_len);
}

inline fn hash_key_is_valid(hash_type: u8, key_len: usize) bool {
    return (hash_type == CURL_HASH_TYPE_BYTES) or
        (hash_type == CURL_HASH_TYPE_SOCKET and key_len == @sizeOf(curl_socket_t));
}

export fn Curl_hash_init(
    h: *Curl_hash,
    slots: usize,
    hash_type: Curl_hash_type,
    dtor: ?Curl_hash_dtor,
) callconv(.c) void {
    h.table = null;
    h.dtor = dtor;
    h.size = 0;
    h.slots = slots;
    h.type = @truncate(hash_type);
}

fn hash_elem_create(
    key: ?*const anyopaque,
    key_len: usize,
    p: ?*anyopaque,
    dtor: ?Curl_hash_elem_dtor,
) ?*Curl_hash_element {
    const total = std.math.add(usize, @sizeOf(Curl_hash_element), key_len) catch return null;
    const raw = mem.malloc(total) orelse return null;
    const he: *Curl_hash_element = @ptrCast(@alignCast(raw));
    he.next = null;
    if (key_len > 0) {
        if (key) |k| {
            const src: [*]const u8 = @ptrCast(k);
            @memcpy(hash_elem_key(he)[0..key_len], src[0..key_len]);
        }
    }
    he.key_len = key_len;
    he.ptr = p;
    he.dtor = dtor;
    return he;
}

fn hash_elem_clear_ptr(h: *Curl_hash, he: *Curl_hash_element) void {
    if (he.ptr) |p| {
        if (he.dtor) |elem_dtor| {
            elem_dtor(hash_elem_key(he), he.key_len, p);
        } else if (h.dtor) |hash_dtor| {
            hash_dtor(p);
        }
        he.ptr = null;
    }
}

fn hash_elem_destroy(h: *Curl_hash, he: *Curl_hash_element) void {
    hash_elem_clear_ptr(h, he);
    mem.free(@ptrCast(he));
}

fn hash_elem_unlink(h: *Curl_hash, he_anchor: *?*Curl_hash_element, he: *Curl_hash_element) void {
    he_anchor.* = he.next;
    h.size -= 1;
}

fn hash_elem_link(h: *Curl_hash, he_anchor: *?*Curl_hash_element, he: *Curl_hash_element) void {
    he.next = he_anchor.*;
    he_anchor.* = he;
    h.size += 1;
}

export fn Curl_hash_add2(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
    p: ?*anyopaque,
    dtor: ?Curl_hash_elem_dtor,
) callconv(.c) ?*anyopaque {
    if (!hash_key_is_valid(h.type, key_len)) return null;
    if (h.table == null) {
        const raw = mem.calloc(h.slots, @sizeOf(?*Curl_hash_element)) orelse return null;
        h.table = @ptrCast(@alignCast(raw));
    }

    const table = h.table.?;
    const slot_idx = hash_compute(h.type, key, key_len, h.slots);
    const slot = &table[slot_idx];
    var he_opt = slot.*;
    while (he_opt) |he| : (he_opt = he.next) {
        if (hash_compare(h.type, hash_elem_key(he), he.key_len, key, key_len)) {
            hash_elem_clear_ptr(h, he);
            he.ptr = p;
            he.dtor = dtor;
            return p;
        }
    }

    const he = hash_elem_create(key, key_len, p, dtor) orelse return null;
    hash_elem_link(h, slot, he);
    return p;
}

export fn Curl_hash_add(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
    p: ?*anyopaque,
) callconv(.c) ?*anyopaque {
    return Curl_hash_add2(h, key, key_len, p, null);
}

export fn Curl_hash_delete(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
) callconv(.c) c_int {
    if (!hash_key_is_valid(h.type, key_len)) return 1;
    if (h.table) |table| {
        const slot_idx = hash_compute(h.type, key, key_len, h.slots);
        var he_anchor: *?*Curl_hash_element = &table[slot_idx];
        while (he_anchor.*) |he| {
            if (hash_compare(h.type, hash_elem_key(he), he.key_len, key, key_len)) {
                hash_elem_unlink(h, he_anchor, he);
                hash_elem_destroy(h, he);
                return 0;
            }
            he_anchor = &he.next;
        }
    }
    return 1;
}

export fn Curl_hash_pick(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
) callconv(.c) ?*anyopaque {
    if (!hash_key_is_valid(h.type, key_len)) return null;
    if (h.table) |table| {
        const slot_idx = hash_compute(h.type, key, key_len, h.slots);
        var he_opt = table[slot_idx];
        while (he_opt) |he| : (he_opt = he.next) {
            if (hash_compare(h.type, hash_elem_key(he), he.key_len, key, key_len)) {
                return he.ptr;
            }
        }
    }
    return null;
}

export fn Curl_hash_clean(h: ?*Curl_hash) callconv(.c) void {
    const hash = h orelse return;
    if (hash.table) |table| {
        for (0..hash.slots) |i| {
            const he_anchor: *?*Curl_hash_element = &table[i];
            while (he_anchor.*) |he| {
                hash_elem_unlink(hash, he_anchor, he);
                hash_elem_destroy(hash, he);
            }
        }
    }
}

export fn Curl_hash_destroy(h: *Curl_hash) callconv(.c) void {
    if (h.table) |table| {
        Curl_hash_clean(h);
        mem.free(@ptrCast(table));
        h.table = null;
    }
    h.slots = 0;
}

export fn Curl_hash_count(h: *Curl_hash) callconv(.c) usize {
    return h.size;
}

pub const Curl_hash_criterium_fn = *const fn (?*anyopaque, ?*anyopaque) callconv(.c) c_int;

export fn Curl_hash_clean_with_criterium(
    h: ?*Curl_hash,
    user: ?*anyopaque,
    comp: ?Curl_hash_criterium_fn,
) callconv(.c) void {
    const hash = h orelse return;
    const table = hash.table orelse return;
    for (0..hash.slots) |i| {
        var he_anchor: *?*Curl_hash_element = &table[i];
        while (he_anchor.*) |he| {
            const should_remove = if (comp) |cb| cb(user, he.ptr) != 0 else true;
            if (should_remove) {
                hash_elem_unlink(hash, he_anchor, he);
                hash_elem_destroy(hash, he);
            } else {
                he_anchor = &he.next;
            }
        }
    }
}

export fn Curl_hash_start_iterate(hash: *Curl_hash, iter: *Curl_hash_iterator) callconv(.c) void {
    iter.hash = hash;
    iter.slot_index = 0;
    iter.current = null;
}

export fn Curl_hash_next_element(iter: *Curl_hash_iterator) callconv(.c) ?*Curl_hash_element {
    const h = iter.hash orelse return null;
    const table = h.table orelse return null;

    if (iter.current) |curr| {
        iter.current = curr.next;
    }

    if (iter.current == null) {
        var i: usize = iter.slot_index;
        while (i < h.slots) : (i += 1) {
            if (table[i]) |elem| {
                iter.current = elem;
                iter.slot_index = i + 1;
                break;
            }
        }
    }

    return iter.current;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "ptrarray operations and growth" {
    var pa: ptrarray = undefined;
    var d0: u8 = '0';
    var d1: u8 = '1';

    Curl_ptrarray_init(&pa);
    try std.testing.expectEqual(@as(u32, 0), Curl_ptrarray_count(&pa));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_ptrarray_add(&pa, null));

    try std.testing.expectEqual(CURLE_OK, Curl_ptrarray_add(&pa, &d0));
    try std.testing.expectEqual(@as(?*anyopaque, &d0), Curl_ptrarray_get(&pa, 0));
    try std.testing.expectEqual(@as(u32, 1), Curl_ptrarray_count(&pa));

    try std.testing.expectEqual(CURLE_OK, Curl_ptrarray_add(&pa, &d1));
    try std.testing.expectEqual(@as(?*anyopaque, &d1), Curl_ptrarray_get(&pa, 1));
    try std.testing.expectEqual(@as(u32, 2), Curl_ptrarray_count(&pa));

    try std.testing.expectEqual(@as(?*anyopaque, &d0), Curl_ptrarray_remove(&pa, 0));
    try std.testing.expectEqual(@as(u32, 1), Curl_ptrarray_count(&pa));
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_ptrarray_get(&pa, 1));
    try std.testing.expectEqual(@as(?*anyopaque, &d1), Curl_ptrarray_get(&pa, 0));

    try std.testing.expectEqual(@as(?*anyopaque, &d1), Curl_ptrarray_remove(&pa, 0));
    try std.testing.expectEqual(@as(u32, 0), Curl_ptrarray_count(&pa));
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_ptrarray_remove(&pa, 0));

    for (0..300) |i| {
        const p: *anyopaque = if ((i & 1) != 0) &d1 else &d0;
        try std.testing.expectEqual(CURLE_OK, Curl_ptrarray_add(&pa, p));
    }
    try std.testing.expectEqual(@as(u32, 300), Curl_ptrarray_count(&pa));
    for (0..300) |i| {
        const expected: ?*anyopaque = if ((i & 1) != 0) &d1 else &d0;
        try std.testing.expectEqual(expected, Curl_ptrarray_get(&pa, @intCast(i)));
    }

    Curl_ptrarray_clear(&pa);
    try std.testing.expectEqual(@as(u32, 0), Curl_ptrarray_count(&pa));
}

fn checkBset(capacity: u32, s: []const u32) !void {
    var bset: uint32_bset = undefined;
    var n: u32 = 0;

    Curl_uint32_bset_init(&bset);
    defer Curl_uint32_bset_destroy(&bset);

    try std.testing.expectEqual(CURLE_OK, Curl_uint32_bset_resize(&bset, capacity));
    const cap = uint32_bset_capacity(&bset);
    try std.testing.expectEqual(((capacity + 63) / 64) * 64, cap);

    Curl_uint32_bset_clear(&bset);
    try std.testing.expectEqual(@as(u32, 0), Curl_uint32_bset_count(&bset));
    try std.testing.expect(Curl_uint32_bset_empty(&bset));

    for (s, 0..) |val, i| {
        try std.testing.expect(Curl_uint32_bset_add(&bset, val));
        for (s[i + 1 ..]) |later| {
            try std.testing.expect(!Curl_uint32_bset_contains(&bset, later));
        }
    }
    try std.testing.expect(!Curl_uint32_bset_empty(&bset));

    for (s) |val| {
        try std.testing.expect(Curl_uint32_bset_contains(&bset, val));
    }

    try std.testing.expect(Curl_uint32_bset_first(&bset, &n));
    try std.testing.expectEqual(s[0], n);
    for (s[1..]) |expected| {
        try std.testing.expect(Curl_uint32_bset_next(&bset, n, &n));
        try std.testing.expectEqual(expected, n);
    }
    try std.testing.expect(!Curl_uint32_bset_next(&bset, n, &n));

    try std.testing.expect(!Curl_uint32_bset_add(&bset, cap));
    try std.testing.expectEqual(@as(u32, @intCast(s.len)), Curl_uint32_bset_count(&bset));

    var idx: usize = 0;
    while (idx < s.len) : (idx += 2) {
        Curl_uint32_bset_remove(&bset, s[idx]);
        try std.testing.expect(!Curl_uint32_bset_contains(&bset, s[idx]));
    }
    idx = 1;
    while (idx < s.len) : (idx += 2) {
        try std.testing.expect(Curl_uint32_bset_contains(&bset, s[idx]));
    }
    try std.testing.expectEqual(@as(u32, @intCast(s.len / 2)), Curl_uint32_bset_count(&bset));

    Curl_uint32_bset_clear(&bset);
    try std.testing.expectEqual(@as(u32, 0), Curl_uint32_bset_count(&bset));
    for (s) |val| {
        try std.testing.expect(!Curl_uint32_bset_contains(&bset, val));
    }

    for (s) |val| {
        try std.testing.expect(Curl_uint32_bset_add(&bset, val));
    }

    try std.testing.expectEqual(CURLE_OK, Curl_uint32_bset_resize(&bset, capacity * 2));
    for (s) |val| {
        try std.testing.expect(Curl_uint32_bset_contains(&bset, val));
    }

    try std.testing.expectEqual(CURLE_OK, Curl_uint32_bset_resize(&bset, capacity));
    for (s) |val| {
        try std.testing.expect(Curl_uint32_bset_contains(&bset, val));
    }

    try std.testing.expectEqual(CURLE_OK, Curl_uint32_bset_resize(&bset, capacity / 2));
    const half_cap = uint32_bset_capacity(&bset);
    var remain: u32 = 0;
    for (s) |val| {
        if (val < half_cap) remain += 1;
    }
    try std.testing.expectEqual(remain, Curl_uint32_bset_count(&bset));
}

test "uint32_bset operations, popcount64, ctz64" {
    try std.testing.expectEqual(@as(u32, 0), Curl_popcount64(0));
    try std.testing.expectEqual(@as(u32, 64), Curl_popcount64(std.math.maxInt(u64)));
    try std.testing.expectEqual(@as(u32, 64), Curl_ctz64(0));
    try std.testing.expectEqual(@as(u32, 0), Curl_ctz64(1));
    try std.testing.expectEqual(@as(u32, 63), Curl_ctz64(@as(u64, 1) << 63));

    const s1 = [_]u32{ 0, 1, 4, 17, 63, 64, 65, 66, 90, 99 };
    var s2: [64]u32 = undefined;
    for (&s2, 0..) |*v, i| {
        v.* = @intCast(64 + i);
    }
    try checkBset(100, &s1);
    try checkBset(1000, &s2);
}

fn checkSpbset(s: []const u32) !void {
    var bset: uint32_spbset = undefined;
    var n: u32 = 0;

    Curl_uint32_spbset_init(&bset);
    defer Curl_uint32_spbset_destroy(&bset);

    uint32_spbset_clear(&bset);
    try std.testing.expectEqual(@as(u32, 0), Curl_uint32_spbset_count(&bset));

    for (s, 0..) |val, i| {
        try std.testing.expect(Curl_uint32_spbset_add(&bset, val));
        for (s[i + 1 ..]) |later| {
            try std.testing.expect(!Curl_uint32_spbset_contains(&bset, later));
        }
    }

    for (s) |val| {
        try std.testing.expect(Curl_uint32_spbset_contains(&bset, val));
    }

    try std.testing.expect(Curl_uint32_spbset_first(&bset, &n));
    try std.testing.expectEqual(s[0], n);
    for (s[1..]) |expected| {
        try std.testing.expect(Curl_uint32_spbset_next(&bset, n, &n));
        try std.testing.expectEqual(expected, n);
    }
    try std.testing.expect(!Curl_uint32_spbset_next(&bset, n, &n));

    var idx: usize = 0;
    while (idx < s.len) : (idx += 2) {
        Curl_uint32_spbset_remove(&bset, s[idx]);
        try std.testing.expect(!Curl_uint32_spbset_contains(&bset, s[idx]));
    }
    idx = 1;
    while (idx < s.len) : (idx += 2) {
        try std.testing.expect(Curl_uint32_spbset_contains(&bset, s[idx]));
    }
    try std.testing.expectEqual(@as(u32, @intCast(s.len / 2)), Curl_uint32_spbset_count(&bset));

    uint32_spbset_clear(&bset);
    try std.testing.expectEqual(@as(u32, 0), Curl_uint32_spbset_count(&bset));
    for (s) |val| {
        try std.testing.expect(!Curl_uint32_spbset_contains(&bset, val));
    }

    for (s) |val| {
        try std.testing.expect(Curl_uint32_spbset_add(&bset, val));
    }
}

test "uint32_spbset operations and chunk reuse" {
    const s1 = [_]u32{ 0, 1, 4, 17, 63, 64, 65, 66, 90, 99 };
    var s2: [64]u32 = undefined;
    for (&s2, 0..) |*v, i| {
        v.* = @intCast(64 + i);
    }
    const s3 = [_]u32{
        2232,  5167,  8204,  8526,  8641,  10056, 10140, 10611,
        10998, 11626, 13735, 15539, 17947, 24295, 27833, 30318,
    };
    try checkSpbset(&s1);
    try checkSpbset(&s2);
    try checkSpbset(&s3);

    // Test out-of-order chunk insertion and empty chunk reuse
    var bset: uint32_spbset = undefined;
    Curl_uint32_spbset_init(&bset);
    defer Curl_uint32_spbset_destroy(&bset);

    try std.testing.expect(Curl_uint32_spbset_add(&bset, 1000));
    try std.testing.expect(Curl_uint32_spbset_add(&bset, 500));
    try std.testing.expect(Curl_uint32_spbset_add(&bset, 10));
    Curl_uint32_spbset_remove(&bset, 500);
    try std.testing.expect(Curl_uint32_spbset_add(&bset, 2000));
    try std.testing.expectEqual(@as(u32, 3), Curl_uint32_spbset_count(&bset));
}

test "uint32_tbl operations and round-robin keys" {
    const tbl_size: u32 = 100;
    var tbl: uint32_tbl = undefined;
    var dummy: c_int = 42;
    var key: u32 = 0;
    var entry: ?*anyopaque = null;

    Curl_uint32_tbl_init(&tbl);
    defer Curl_uint32_tbl_destroy(&tbl);

    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_uint32_tbl_resize(&tbl, 0));
    try std.testing.expectEqual(CURLE_OK, Curl_uint32_tbl_resize(&tbl, tbl_size));
    try std.testing.expectEqual(tbl_size, Curl_uint32_tbl_capacity(&tbl));

    for (0..tbl_size) |i| {
        try std.testing.expect(Curl_uint32_tbl_add(&tbl, &dummy, &key));
        try std.testing.expectEqual(@as(u32, @intCast(i)), key);
    }
    try std.testing.expectEqual(tbl_size, Curl_uint32_tbl_count(&tbl));
    try std.testing.expect(!Curl_uint32_tbl_add(&tbl, &dummy, &key));

    var n: u32 = tbl_size;
    var i: u32 = 0;
    while (i < tbl_size) : (i += 2) {
        Curl_uint32_tbl_remove(&tbl, i);
        n -= 1;
        try std.testing.expectEqual(n, Curl_uint32_tbl_count(&tbl));
    }
    i = 0;
    while (i < tbl_size) : (i += 2) {
        Curl_uint32_tbl_remove(&tbl, i);
        try std.testing.expectEqual(n, Curl_uint32_tbl_count(&tbl));
    }
    i = 1;
    while (i < tbl_size) : (i += 2) {
        try std.testing.expect(Curl_uint32_tbl_contains(&tbl, i));
        try std.testing.expectEqual(@as(?*anyopaque, &dummy), Curl_uint32_tbl_get(&tbl, i));
    }

    try std.testing.expect(Curl_uint32_tbl_first(&tbl, &key, &entry));
    try std.testing.expectEqual(@as(u32, 1), key);
    try std.testing.expectEqual(@as(?*anyopaque, &dummy), entry);

    try std.testing.expect(Curl_uint32_tbl_next(&tbl, 1, &key, &entry));
    try std.testing.expectEqual(@as(u32, 3), key);
    try std.testing.expectEqual(@as(?*anyopaque, &dummy), entry);

    try std.testing.expect(Curl_uint32_tbl_next(&tbl, 42, &key, &entry));
    try std.testing.expectEqual(@as(u32, 43), key);
    try std.testing.expectEqual(@as(?*anyopaque, &dummy), entry);

    try std.testing.expectEqual(CURLE_OK, Curl_uint32_tbl_resize(&tbl, tbl_size * 2));
    try std.testing.expectEqual(n, Curl_uint32_tbl_count(&tbl));

    try std.testing.expectEqual(CURLE_OK, Curl_uint32_tbl_resize(&tbl, tbl_size / 2));
    try std.testing.expectEqual(n / 2, Curl_uint32_tbl_count(&tbl));

    uint32_tbl_clear(&tbl);
    try std.testing.expectEqual(@as(u32, 0), Curl_uint32_tbl_count(&tbl));

    try std.testing.expect(Curl_uint32_tbl_add(&tbl, &dummy, &key));
    try std.testing.expectEqual(@as(u32, 0), key);
    Curl_uint32_tbl_remove(&tbl, key);
    try std.testing.expect(Curl_uint32_tbl_add(&tbl, &dummy, &key));
    try std.testing.expectEqual(@as(u32, 1), key);

    uint32_tbl_clear(&tbl);
    for (0..Curl_uint32_tbl_capacity(&tbl)) |_| {
        try std.testing.expect(Curl_uint32_tbl_add(&tbl, &dummy, &key));
    }
    try std.testing.expect(!Curl_uint32_tbl_add(&tbl, &dummy, &key));
    Curl_uint32_tbl_remove(&tbl, 17);
    try std.testing.expect(Curl_uint32_tbl_add(&tbl, &dummy, &key));
    try std.testing.expectEqual(@as(u32, 17), key);
    Curl_uint32_tbl_remove(&tbl, 17);
    try std.testing.expect(Curl_uint32_tbl_add(&tbl, &dummy, &key));
    try std.testing.expectEqual(@as(u32, 17), key);
}

fn fmtStrId(buf: *[64]u8, idx: u8) ![*:0]const u8 {
    const slice = try std.fmt.bufPrint(buf[0 .. buf.len - 1], "str-{d}", .{idx});
    buf[slice.len] = 0;
    return @ptrCast(buf);
}

test "u8_strset operations, collisions, growth, copy, unset0" {
    var set: u8_strset = undefined;
    var buf: [64]u8 = undefined;

    Curl_u8_strset_init(&set);
    defer Curl_u8_strset_clear(&set);

    try std.testing.expectEqual(@as(u16, 0), Curl_u8_strset_count(&set));

    try std.testing.expectEqual(CURLE_OK, u8_strset_set(&set, 0, "123"));
    try std.testing.expectEqualStrings("123", std.mem.span(Curl_u8_strset_get(&set, 0).?));
    try std.testing.expectEqual(CURLE_OK, u8_strset_set(&set, 0, "456"));
    try std.testing.expectEqualStrings("456", std.mem.span(Curl_u8_strset_get(&set, 0).?));
    Curl_u8_strset_unset0(&set, 0);
    try std.testing.expectEqual(@as(?[*:0]const u8, null), Curl_u8_strset_get(&set, 0));

    // Add 8 hash collisions
    for (0..8) |i| {
        const idx: u8 = @intCast((8 * i) + 3);
        const s = try fmtStrId(&buf, idx);
        try std.testing.expectEqual(CURLE_OK, u8_strset_set(&set, idx, s));
        try std.testing.expectEqualStrings(std.mem.span(s), std.mem.span(Curl_u8_strset_get(&set, idx).?));
    }

    // Remove collided entry 2, check remaining
    const rem_idx: u8 = (8 * 2) + 3;
    Curl_u8_strset_unset(&set, rem_idx);
    try std.testing.expectEqual(@as(?[*:0]const u8, null), Curl_u8_strset_get(&set, rem_idx));
    for (0..8) |i| {
        if (i == 2) continue;
        const idx: u8 = @intCast((8 * i) + 3);
        const s = try fmtStrId(&buf, idx);
        try std.testing.expectEqualStrings(std.mem.span(s), std.mem.span(Curl_u8_strset_get(&set, idx).?));
    }

    // Re-add entry 2
    {
        const s = try fmtStrId(&buf, rem_idx);
        try std.testing.expectEqual(CURLE_OK, u8_strset_set(&set, rem_idx, s));
    }

    // Add 9th to trigger grow
    try std.testing.expectEqual(@as(u16, 8), Curl_u8_strset_count(&set));
    const idx9: u8 = (9 * 4) + 3;
    {
        const s = try fmtStrId(&buf, idx9);
        try std.testing.expectEqual(CURLE_OK, u8_strset_set(&set, idx9, s));
        try std.testing.expectEqualStrings(std.mem.span(s), std.mem.span(Curl_u8_strset_get(&set, idx9).?));
    }
    try std.testing.expectEqual(@as(u16, 9), Curl_u8_strset_count(&set));

    // Test copy
    var copy_set: u8_strset = undefined;
    Curl_u8_strset_init(&copy_set);
    defer Curl_u8_strset_clear(&copy_set);
    try std.testing.expectEqual(CURLE_OK, Curl_u8_strset_copy(&copy_set, &set));
    try std.testing.expectEqual(@as(u16, 9), Curl_u8_strset_count(&copy_set));
    for (0..8) |i| {
        const idx: u8 = @intCast((8 * i) + 3);
        const s = try fmtStrId(&buf, idx);
        try std.testing.expectEqualStrings(std.mem.span(s), std.mem.span(Curl_u8_strset_get(&copy_set, idx).?));
    }
    {
        const s = try fmtStrId(&buf, idx9);
        try std.testing.expectEqualStrings(std.mem.span(s), std.mem.span(Curl_u8_strset_get(&copy_set, idx9).?));
    }

    Curl_u8_strset_clear(&set);
    for (0..256) |j| {
        const i: u8 = @intCast(j);
        const s = try fmtStrId(&buf, i);
        try std.testing.expectEqual(CURLE_OK, u8_strset_set(&set, i, s));
        try std.testing.expectEqualStrings(std.mem.span(s), std.mem.span(Curl_u8_strset_get(&set, i).?));
    }
    try std.testing.expectEqual(@as(u16, 256), Curl_u8_strset_count(&set));
    Curl_u8_strset_clear(&set);
    try std.testing.expectEqual(@as(u16, 0), Curl_u8_strset_count(&set));
}

var ptrset_dtor_calls: usize = 0;
fn testPtrsetDtor(_: u32, _: ?*anyopaque) callconv(.c) void {
    ptrset_dtor_calls += 1;
}

fn testPtrsetVisit(_: u32, _: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) bool {
    const counter: *usize = @ptrCast(@alignCast(user_data.?));
    counter.* += 1;
    return true;
}

test "u32_ptrset operations, collisions, growth, dtor, visit" {
    var set: u32_ptrset = undefined;
    var v1: u8 = 1;
    var v2: u8 = 2;
    var v3: u8 = 3;

    ptrset_dtor_calls = 0;
    Curl_u32_ptrset_init(&set, testPtrsetDtor);
    defer Curl_u32_ptrset_clear(&set);

    try std.testing.expectEqual(@as(u32, 0), Curl_u32_ptrset_count(&set));
    try std.testing.expectEqual(CURLE_OK, Curl_u32_ptrset_set(&set, 0, &v1));
    try std.testing.expectEqual(@as(?*anyopaque, &v1), Curl_u32_ptrset_get(&set, 0));
    try std.testing.expectEqual(CURLE_OK, Curl_u32_ptrset_set(&set, 0, &v2));
    try std.testing.expectEqual(@as(usize, 1), ptrset_dtor_calls);
    try std.testing.expectEqual(@as(?*anyopaque, &v2), Curl_u32_ptrset_get(&set, 0));
    Curl_u32_ptrset_unset(&set, 0);
    try std.testing.expectEqual(@as(usize, 2), ptrset_dtor_calls);
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_u32_ptrset_get(&set, 0));

    for (0..64) |i| {
        const idx: u32 = @intCast((64 * i) + 3);
        try std.testing.expectEqual(CURLE_OK, Curl_u32_ptrset_set(&set, idx, &v1));
        try std.testing.expectEqual(@as(?*anyopaque, &v1), Curl_u32_ptrset_get(&set, idx));
    }

    const rem_idx: u32 = (64 * 2) + 3;
    Curl_u32_ptrset_unset(&set, rem_idx);
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_u32_ptrset_get(&set, rem_idx));
    try std.testing.expectEqual(CURLE_OK, Curl_u32_ptrset_set(&set, rem_idx, &v2));
    try std.testing.expectEqual(@as(?*anyopaque, &v2), Curl_u32_ptrset_get(&set, rem_idx));

    try std.testing.expectEqual(@as(u32, 64), Curl_u32_ptrset_count(&set));
    const idx65: u32 = (65 * 4) + 3;
    try std.testing.expectEqual(CURLE_OK, Curl_u32_ptrset_set(&set, idx65, &v3));
    try std.testing.expectEqual(@as(?*anyopaque, &v3), Curl_u32_ptrset_get(&set, idx65));
    try std.testing.expectEqual(@as(u32, 65), Curl_u32_ptrset_count(&set));

    var visited: usize = 0;
    Curl_u32_ptrset_visit(&set, testPtrsetVisit, &visited);
    try std.testing.expectEqual(@as(usize, 65), visited);

    Curl_u32_ptrset_clear(&set);
    try std.testing.expectEqual(@as(u32, 0), Curl_u32_ptrset_count(&set));
}

fn noopHashDtor(_: ?*anyopaque) callconv(.c) void {}

var test_elem_dtor_calls: usize = 0;
fn testElemDtor(_: ?*const anyopaque, _: usize, _: ?*anyopaque) callconv(.c) void {
    test_elem_dtor_calls += 1;
}

fn testCriteriumMatch(user: ?*anyopaque, ptr: ?*anyopaque) callconv(.c) c_int {
    return if (user == ptr) 1 else 0;
}

test "Curl_hash bytes and socket keys, iteration, and cleanup" {
    try std.testing.expectEqual(CURLE_OK, Curl_hash_global_init());
    try std.testing.expectEqual(@as(usize, 95), hash_str_seeded("a", 1, 97, 0x1234));

    var hash_static: Curl_hash = undefined;
    Curl_hash_init(&hash_static, 3, CURL_HASH_TYPE_BYTES, noopHashDtor);
    defer Curl_hash_destroy(&hash_static);

    var key1 = "key1".*;
    var key2 = "key2b".*;
    var key3 = "key3".*;
    var key4 = "key4".*;
    var notakey = "notakey".*;

    try std.testing.expectEqual(@as(?*anyopaque, &key1), Curl_hash_add(&hash_static, &key1, key1.len, &key1));
    try std.testing.expectEqual(@as(?*anyopaque, &key1), Curl_hash_pick(&hash_static, &key1, key1.len));

    try std.testing.expectEqual(@as(?*anyopaque, &key2), Curl_hash_add(&hash_static, &key2, key2.len, &key2));
    try std.testing.expectEqual(@as(?*anyopaque, &key3), Curl_hash_add(&hash_static, &key3, key3.len, &key3));
    try std.testing.expectEqual(@as(?*anyopaque, &key4), Curl_hash_add(&hash_static, &key4, key4.len, &key4));
    try std.testing.expectEqual(@as(usize, 4), Curl_hash_count(&hash_static));

    var iter: Curl_hash_iterator = undefined;
    Curl_hash_start_iterate(&hash_static, &iter);
    var iter_count: usize = 0;
    while (Curl_hash_next_element(&iter)) |_| {
        iter_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 4), iter_count);

    try std.testing.expectEqual(@as(c_int, 0), Curl_hash_delete(&hash_static, &key4, key4.len));
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_hash_pick(&hash_static, &key4, key4.len));
    try std.testing.expectEqual(@as(c_int, 1), Curl_hash_delete(&hash_static, &key4, key4.len));

    try std.testing.expectEqual(@as(?*anyopaque, &notakey), Curl_hash_add(&hash_static, &key1, key1.len, &notakey));
    try std.testing.expectEqual(@as(?*anyopaque, &notakey), Curl_hash_pick(&hash_static, &key1, key1.len));

    test_elem_dtor_calls = 0;
    try std.testing.expectEqual(@as(?*anyopaque, &key1), Curl_hash_add2(&hash_static, &key1, key1.len, &key1, testElemDtor));
    try std.testing.expectEqual(@as(usize, 0), test_elem_dtor_calls);
    try std.testing.expectEqual(@as(?*anyopaque, &key1), Curl_hash_add2(&hash_static, &key1, key1.len, &key1, testElemDtor));
    try std.testing.expectEqual(@as(usize, 1), test_elem_dtor_calls);
    try std.testing.expectEqual(@as(c_int, 0), Curl_hash_delete(&hash_static, &key1, key1.len));
    try std.testing.expectEqual(@as(usize, 2), test_elem_dtor_calls);

    Curl_hash_clean_with_criterium(&hash_static, &key2, testCriteriumMatch);
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_hash_pick(&hash_static, &key2, key2.len));
    try std.testing.expectEqual(@as(?*anyopaque, &key3), Curl_hash_pick(&hash_static, &key3, key3.len));

    Curl_hash_clean(&hash_static);
    try std.testing.expectEqual(@as(usize, 0), Curl_hash_count(&hash_static));

    // Test socket hash type
    var sock_hash: Curl_hash = undefined;
    Curl_hash_init(&sock_hash, 3, CURL_HASH_TYPE_SOCKET, noopHashDtor);
    defer Curl_hash_destroy(&sock_hash);

    var skey: curl_socket_t = 1;
    var scollision: curl_socket_t = 4;
    var val1: c_int = 1;
    var val2: c_int = 2;
    var val3: c_int = 3;

    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_hash_add(&sock_hash, &skey, @sizeOf(curl_socket_t) - 1, &val1));
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_hash_pick(&sock_hash, &skey, @sizeOf(curl_socket_t) - 1));
    try std.testing.expectEqual(@as(c_int, 1), Curl_hash_delete(&sock_hash, &skey, @sizeOf(curl_socket_t) - 1));

    try std.testing.expectEqual(@as(?*anyopaque, &val1), Curl_hash_add(&sock_hash, &skey, @sizeOf(curl_socket_t), &val1));
    try std.testing.expectEqual(@as(?*anyopaque, &val3), Curl_hash_add(&sock_hash, &skey, @sizeOf(curl_socket_t), &val3));
    try std.testing.expectEqual(@as(usize, 1), Curl_hash_count(&sock_hash));
    try std.testing.expectEqual(@as(?*anyopaque, &val3), Curl_hash_pick(&sock_hash, &skey, @sizeOf(curl_socket_t)));

    try std.testing.expectEqual(@as(?*anyopaque, &val2), Curl_hash_add(&sock_hash, &scollision, @sizeOf(curl_socket_t), &val2));
    try std.testing.expectEqual(@as(usize, 2), Curl_hash_count(&sock_hash));
    try std.testing.expectEqual(@as(?*anyopaque, &val2), Curl_hash_pick(&sock_hash, &scollision, @sizeOf(curl_socket_t)));

    try std.testing.expectEqual(@as(c_int, 0), Curl_hash_delete(&sock_hash, &skey, @sizeOf(curl_socket_t)));
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_hash_pick(&sock_hash, &skey, @sizeOf(curl_socket_t)));
    try std.testing.expectEqual(@as(?*anyopaque, &val2), Curl_hash_pick(&sock_hash, &scollision, @sizeOf(curl_socket_t)));
}
