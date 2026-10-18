const std = @import("std");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const os_leaf = @import("os_leaf.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_AGAIN: CURLcode = 81;

pub const Dynbuf = os_leaf.Dynbuf;

extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *Dynbuf, mem_ptr: *const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;

// ============================================================================
// 1. lib/bufq.c + lib/bufq.h
// ============================================================================

pub const BUFQ_OPT_NONE: c_int = 0;
pub const BUFQ_OPT_SOFT_LIMIT: c_int = 1 << 0;
pub const BUFQ_OPT_NO_SPARES: c_int = 1 << 1;

pub const buf_chunk_x = extern union {
    data: [1]u8,
    dummy: ?*anyopaque,
};

pub const buf_chunk = extern struct {
    next: ?*buf_chunk,
    dlen: usize,
    r_offset: usize,
    w_offset: usize,
    x: buf_chunk_x,

    pub inline fn dataPtr(self: *buf_chunk) [*]u8 {
        return @as([*]u8, @ptrCast(&self.x));
    }

    pub inline fn dataPtrConst(self: *const buf_chunk) [*]const u8 {
        return @as([*]const u8, @ptrCast(&self.x));
    }
};

pub const bufc_pool = extern struct {
    spare: ?*buf_chunk,
    chunk_size: usize,
    spare_count: usize,
    spare_max: usize,
};

pub const bufq = extern struct {
    head: ?*buf_chunk,
    tail: ?*buf_chunk,
    spare: ?*buf_chunk,
    pool: ?*bufc_pool,
    chunk_count: usize,
    max_chunks: usize,
    chunk_size: usize,
    opts: c_int,
};

pub const Curl_bufq_writer = *const fn (
    writer_ctx: ?*anyopaque,
    buf: [*]const u8,
    len: usize,
    pwritten: *usize,
) callconv(.c) CURLcode;

pub const Curl_bufq_reader = *const fn (
    reader_ctx: ?*anyopaque,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode;

inline fn chunkIsEmpty(chunk: *const buf_chunk) bool {
    return chunk.r_offset >= chunk.w_offset;
}

inline fn chunkIsFull(chunk: *const buf_chunk) bool {
    return chunk.w_offset >= chunk.dlen;
}

inline fn chunkLen(chunk: *const buf_chunk) usize {
    return chunk.w_offset - chunk.r_offset;
}

inline fn chunkReset(chunk: *buf_chunk) void {
    chunk.next = null;
    chunk.r_offset = 0;
    chunk.w_offset = 0;
}

fn chunkAppend(chunk: *buf_chunk, buf: ?[*]const u8, len: usize) usize {
    const p = chunk.dataPtr() + chunk.w_offset;
    var n = chunk.dlen - chunk.w_offset;
    std.debug.assert(chunk.dlen >= chunk.w_offset);
    if (n != 0) {
        n = @min(n, len);
        if (n != 0) {
            const src = buf.?;
            @memcpy(p[0..n], src[0..n]);
            chunk.w_offset += n;
        }
    }
    return n;
}

fn chunkRead(chunk: *buf_chunk, buf: ?[*]u8, len: usize) usize {
    const p = chunk.dataPtrConst() + chunk.r_offset;
    const n = chunk.w_offset - chunk.r_offset;
    std.debug.assert(chunk.w_offset >= chunk.r_offset);
    if (n == 0) {
        return 0;
    } else if (n <= len) {
        const dst = buf.?;
        @memcpy(dst[0..n], p[0..n]);
        chunk.r_offset = 0;
        chunk.w_offset = 0;
        return n;
    } else {
        if (len != 0) {
            const dst = buf.?;
            @memcpy(dst[0..len], p[0..len]);
            chunk.r_offset += len;
        }
        return len;
    }
}

fn chunkSlurpn(
    chunk: *buf_chunk,
    max_len: usize,
    reader: Curl_bufq_reader,
    reader_ctx: ?*anyopaque,
    pnread: *usize,
) CURLcode {
    const p = chunk.dataPtr() + chunk.w_offset;
    var n = chunk.dlen - chunk.w_offset;
    pnread.* = 0;
    std.debug.assert(chunk.dlen >= chunk.w_offset);
    if (n == 0)
        return CURLE_AGAIN;
    if (max_len != 0 and n > max_len)
        n = max_len;
    const result = reader(reader_ctx, p, n, pnread);
    if (result == CURLE_OK) {
        std.debug.assert(pnread.* <= n);
        chunk.w_offset += pnread.*;
    }
    return result;
}

inline fn chunkPeek(chunk: *const buf_chunk, pbuf: *?[*]const u8, plen: *usize) void {
    std.debug.assert(chunk.w_offset >= chunk.r_offset);
    pbuf.* = chunk.dataPtrConst() + chunk.r_offset;
    plen.* = chunk.w_offset - chunk.r_offset;
}

inline fn chunkPeekAt(chunk: *const buf_chunk, offset_in: usize, pbuf: *?[*]const u8, plen: *usize) void {
    const offset = offset_in + chunk.r_offset;
    std.debug.assert(chunk.w_offset >= offset);
    pbuf.* = chunk.dataPtrConst() + offset;
    plen.* = chunk.w_offset - offset;
}

fn chunkSkip(chunk: *buf_chunk, amount: usize) usize {
    var n = chunk.w_offset - chunk.r_offset;
    std.debug.assert(chunk.w_offset >= chunk.r_offset);
    if (n != 0) {
        n = @min(n, amount);
        chunk.r_offset += n;
        if (chunk.r_offset == chunk.w_offset) {
            chunk.r_offset = 0;
            chunk.w_offset = 0;
        }
    }
    return n;
}

fn chunkListFree(anchor: *?*buf_chunk) void {
    while (anchor.*) |chunk| {
        anchor.* = chunk.next;
        mem.free(chunk);
    }
}

pub export fn Curl_bufcp_init(pool: *bufc_pool, chunk_size: usize, spare_max: usize) callconv(.c) void {
    std.debug.assert(chunk_size > 0);
    std.debug.assert(spare_max > 0);
    pool.* = .{
        .spare = null,
        .chunk_size = chunk_size,
        .spare_count = 0,
        .spare_max = spare_max,
    };
}

pub export fn Curl_bufq_cpool_init(pool: *bufc_pool, chunk_size: usize, spare_max: usize) callconv(.c) void {
    Curl_bufcp_init(pool, chunk_size, spare_max);
}

fn bufcpTake(pool: *bufc_pool, pchunk: *?*buf_chunk) CURLcode {
    if (pool.spare) |chunk| {
        pool.spare = chunk.next;
        pool.spare_count -= 1;
        chunkReset(chunk);
        pchunk.* = chunk;
        return CURLE_OK;
    }

    if (pool.chunk_size > std.math.maxInt(usize) - @sizeOf(buf_chunk)) {
        pchunk.* = null;
        return CURLE_OUT_OF_MEMORY;
    }

    const raw = mem.calloc(1, @sizeOf(buf_chunk) + pool.chunk_size) orelse {
        pchunk.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    const chunk: *buf_chunk = @ptrCast(@alignCast(raw));
    chunk.dlen = pool.chunk_size;
    pchunk.* = chunk;
    return CURLE_OK;
}

fn bufcpPut(pool: *bufc_pool, chunk: *buf_chunk) void {
    if (pool.spare_count >= pool.spare_max) {
        mem.free(chunk);
    } else {
        chunkReset(chunk);
        chunk.next = pool.spare;
        pool.spare = chunk;
        pool.spare_count += 1;
    }
}

pub export fn Curl_bufcp_free(pool: *bufc_pool) callconv(.c) void {
    chunkListFree(&pool.spare);
    pool.spare_count = 0;
}

pub export fn Curl_bufq_cpool_free(pool: *bufc_pool) callconv(.c) void {
    Curl_bufcp_free(pool);
}

fn bufqInit(q: *bufq, pool: ?*bufc_pool, chunk_size: usize, max_chunks: usize, opts: c_int) void {
    std.debug.assert(chunk_size > 0);
    std.debug.assert(max_chunks > 0);
    q.* = .{
        .head = null,
        .tail = null,
        .spare = null,
        .pool = pool,
        .chunk_count = 0,
        .max_chunks = max_chunks,
        .chunk_size = chunk_size,
        .opts = opts,
    };
}

pub export fn Curl_bufq_init2(q: *bufq, chunk_size: usize, max_chunks: usize, opts: c_int) callconv(.c) void {
    bufqInit(q, null, chunk_size, max_chunks, opts);
}

pub export fn Curl_bufq_init(q: *bufq, chunk_size: usize, max_chunks: usize) callconv(.c) void {
    bufqInit(q, null, chunk_size, max_chunks, BUFQ_OPT_NONE);
}

pub export fn Curl_bufq_initp(q: *bufq, pool: *bufc_pool, max_chunks: usize, opts: c_int) callconv(.c) void {
    bufqInit(q, pool, pool.chunk_size, max_chunks, opts);
}

pub export fn Curl_bufq_init_pool(q: *bufq, pool: *bufc_pool, max_chunks: usize, opts: c_int) callconv(.c) void {
    Curl_bufq_initp(q, pool, max_chunks, opts);
}

pub export fn Curl_bufq_Init_pool(q: *bufq, pool: *bufc_pool, max_chunks: usize, opts: c_int) callconv(.c) void {
    Curl_bufq_initp(q, pool, max_chunks, opts);
}

pub export fn Curl_bufq_free(q: *bufq) callconv(.c) void {
    chunkListFree(&q.head);
    chunkListFree(&q.spare);
    q.tail = null;
    q.chunk_count = 0;
}

pub export fn Curl_bufq_reset(q: *bufq) callconv(.c) void {
    while (q.head) |chunk| {
        q.head = chunk.next;
        chunk.next = q.spare;
        q.spare = chunk;
    }
    q.tail = null;
}

pub export fn Curl_bufq_len(q: *const bufq) callconv(.c) usize {
    var chunk = q.head;
    var len: usize = 0;
    while (chunk) |c| {
        len += chunkLen(c);
        chunk = c.next;
    }
    return len;
}

pub export fn Curl_bufq_is_empty(q: *const bufq) callconv(.c) bool {
    if (q.head) |h| {
        return chunkIsEmpty(h);
    }
    return true;
}

pub export fn Curl_bufq_is_full(q: *const bufq) callconv(.c) bool {
    const tail = q.tail orelse return false;
    if (q.spare != null)
        return false;
    if (q.chunk_count < q.max_chunks)
        return false;
    if (q.chunk_count > q.max_chunks)
        return true;
    return chunkIsFull(tail);
}

fn getSpare(q: *bufq) ?*buf_chunk {
    if (q.spare) |chunk| {
        q.spare = chunk.next;
        chunkReset(chunk);
        return chunk;
    }

    if (q.chunk_count >= q.max_chunks and ((q.opts & BUFQ_OPT_SOFT_LIMIT) == 0))
        return null;

    if (q.pool) |pool| {
        var chunk: ?*buf_chunk = null;
        if (bufcpTake(pool, &chunk) != CURLE_OK)
            return null;
        q.chunk_count += 1;
        return chunk;
    } else {
        if (q.chunk_size > std.math.maxInt(usize) - @sizeOf(buf_chunk))
            return null;

        const raw = mem.calloc(1, @sizeOf(buf_chunk) + q.chunk_size) orelse return null;
        const chunk: *buf_chunk = @ptrCast(@alignCast(raw));
        chunk.dlen = q.chunk_size;
        q.chunk_count += 1;
        return chunk;
    }
}

fn pruneHead(q: *bufq) void {
    while (q.head) |chunk| {
        if (!chunkIsEmpty(chunk))
            break;
        q.head = chunk.next;
        if (q.tail == chunk)
            q.tail = q.head;
        if (q.pool) |pool| {
            bufcpPut(pool, chunk);
            q.chunk_count -= 1;
        } else if ((q.chunk_count > q.max_chunks) or ((q.opts & BUFQ_OPT_NO_SPARES) != 0)) {
            mem.free(chunk);
            q.chunk_count -= 1;
        } else {
            chunk.next = q.spare;
            q.spare = chunk;
        }
    }
}

fn getNonFullTail(q: *bufq) ?*buf_chunk {
    if (q.tail) |t| {
        if (!chunkIsFull(t))
            return t;
    }
    const chunk = getSpare(q) orelse return null;
    if (q.tail) |t| {
        t.next = chunk;
        q.tail = chunk;
    } else {
        std.debug.assert(q.head == null);
        q.head = chunk;
        q.tail = chunk;
    }
    return chunk;
}

pub export fn Curl_bufq_write(
    q: *bufq,
    buf_in: ?[*]const u8,
    len_in: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    std.debug.assert(q.max_chunks > 0);
    pnwritten.* = 0;
    var buf = buf_in;
    var len = len_in;
    while (len != 0) {
        const tail = getNonFullTail(q) orelse {
            if ((q.chunk_count < q.max_chunks) or ((q.opts & BUFQ_OPT_SOFT_LIMIT) != 0))
                return CURLE_OUT_OF_MEMORY;
            break;
        };
        const n = chunkAppend(tail, buf, len);
        if (n == 0)
            break;
        pnwritten.* += n;
        if (buf) |b| buf = b + n;
        len -= n;
    }
    return if (pnwritten.* == 0 and len != 0) CURLE_AGAIN else CURLE_OK;
}

pub export fn Curl_bufq_cwrite(
    q: *bufq,
    buf: ?[*]const u8,
    len: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    return Curl_bufq_write(q, buf, len, pnwritten);
}

pub export fn Curl_bufq_read(
    q: *bufq,
    buf_in: ?[*]u8,
    len_in: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    pnread.* = 0;
    var buf = buf_in;
    var len = len_in;
    while (len != 0) {
        const head = q.head orelse break;
        const n = chunkRead(head, buf, len);
        if (n != 0) {
            pnread.* += n;
            if (buf) |b| buf = b + n;
            len -= n;
        }
        pruneHead(q);
    }
    return if (pnread.* == 0) CURLE_AGAIN else CURLE_OK;
}

pub export fn Curl_bufq_cread(
    q: *bufq,
    buf: ?[*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    return Curl_bufq_read(q, buf, len, pnread);
}

pub export fn Curl_bufq_peek(
    q: *bufq,
    pbuf: *?[*]const u8,
    plen: *usize,
) callconv(.c) bool {
    if (q.head) |h| {
        if (chunkIsEmpty(h)) {
            pruneHead(q);
        }
    }
    if (q.head) |h| {
        if (!chunkIsEmpty(h)) {
            chunkPeek(h, pbuf, plen);
            return true;
        }
    }
    pbuf.* = null;
    plen.* = 0;
    return false;
}

pub export fn Curl_bufq_peek_at(
    q: *bufq,
    offset_in: usize,
    pbuf: *?[*]const u8,
    plen: *usize,
) callconv(.c) bool {
    var c = q.head;
    var offset = offset_in;
    while (c) |chunk| {
        const clen = chunkLen(chunk);
        if (clen == 0)
            break;
        if (offset >= clen) {
            offset -= clen;
            c = chunk.next;
            continue;
        }
        chunkPeekAt(chunk, offset, pbuf, plen);
        return true;
    }
    pbuf.* = null;
    plen.* = 0;
    return false;
}

pub export fn Curl_bufq_skip(q: *bufq, amount_in: usize) callconv(.c) void {
    var amount = amount_in;
    while (amount != 0) {
        const head = q.head orelse break;
        const n = chunkSkip(head, amount);
        amount -= n;
        pruneHead(q);
    }
}

pub export fn Curl_bufq_pass(
    q: *bufq,
    writer: Curl_bufq_writer,
    writer_ctx: ?*anyopaque,
    pwritten: *usize,
) callconv(.c) CURLcode {
    var buf: ?[*]const u8 = null;
    var blen: usize = 0;
    var result: CURLcode = CURLE_OK;

    pwritten.* = 0;
    while (Curl_bufq_peek(q, &buf, &blen)) {
        var chunk_written: usize = 0;
        result = writer(writer_ctx, buf.?, blen, &chunk_written);
        if (result != CURLE_OK) {
            if ((result == CURLE_AGAIN) and pwritten.* != 0) {
                result = CURLE_OK;
            }
            break;
        }
        if (chunk_written == 0) {
            if (pwritten.* == 0) {
                result = CURLE_AGAIN;
            }
            break;
        }
        pwritten.* += chunk_written;
        Curl_bufq_skip(q, chunk_written);
    }
    return result;
}

pub export fn Curl_bufq_write_pass(
    q: *bufq,
    buf_in: ?[*]const u8,
    len_in: usize,
    writer: Curl_bufq_writer,
    writer_ctx: ?*anyopaque,
    pwritten: *usize,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var n: usize = 0;
    var buf = buf_in;
    var len = len_in;

    pwritten.* = 0;
    while (len != 0) {
        if (Curl_bufq_is_full(q)) {
            result = Curl_bufq_pass(q, writer, writer_ctx, &n);
            if (result != CURLE_OK) {
                if (result != CURLE_AGAIN) {
                    return result;
                }
                break;
            }
        }

        result = Curl_bufq_write(q, buf, len, &n);
        if (result != CURLE_OK) {
            if (result != CURLE_AGAIN)
                return result;
            if (pwritten.* != 0)
                result = CURLE_OK;
            return result;
        } else if (n == 0) {
            break;
        }

        if (buf) |b| buf = b + n;
        len -= n;
        pwritten.* += n;
    }

    return if (pwritten.* == 0 and len != 0) CURLE_AGAIN else CURLE_OK;
}

pub export fn Curl_bufq_sipn(
    q: *bufq,
    max_len: usize,
    reader: Curl_bufq_reader,
    reader_ctx: ?*anyopaque,
    pnread: *usize,
) callconv(.c) CURLcode {
    pnread.* = 0;
    const tail = getNonFullTail(q) orelse {
        if (q.chunk_count < q.max_chunks)
            return CURLE_OUT_OF_MEMORY;
        return CURLE_AGAIN;
    };

    return chunkSlurpn(tail, max_len, reader, reader_ctx, pnread);
}

fn bufqSlurpn(
    q: *bufq,
    max_len_in: usize,
    reader: Curl_bufq_reader,
    reader_ctx: ?*anyopaque,
    pnread: *usize,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var max_len = max_len_in;

    pnread.* = 0;
    while (true) {
        var n: usize = 0;
        result = Curl_bufq_sipn(q, max_len, reader, reader_ctx, &n);
        if (result != CURLE_OK) {
            if (pnread.* == 0 or result != CURLE_AGAIN) {
                return result;
            }
            result = CURLE_OK;
            break;
        } else if (n == 0) {
            break;
        }
        pnread.* += n;
        if (max_len != 0) {
            std.debug.assert(n <= max_len);
            max_len -= n;
            if (max_len == 0)
                break;
        }
        if (q.tail) |t| {
            if (!chunkIsFull(t))
                break;
        }
    }
    return result;
}

pub export fn Curl_bufq_slurp(
    q: *bufq,
    reader: Curl_bufq_reader,
    reader_ctx: ?*anyopaque,
    pnread: *usize,
) callconv(.c) CURLcode {
    return bufqSlurpn(q, 0, reader, reader_ctx, pnread);
}

// ============================================================================
// 2. lib/dynhds.c + lib/dynhds.h
// ============================================================================

pub const DYNHDS_OPT_NONE: c_int = 0;
pub const DYNHDS_OPT_LOWERCASE: c_int = 1 << 0;

pub const dynhds_entry = extern struct {
    name: [*:0]u8,
    value: [*:0]u8,
    namelen: usize,
    valuelen: usize,
};

pub const dynhds = extern struct {
    hds: ?[*]?*dynhds_entry,
    hds_len: usize,
    hds_allc: usize,
    max_entries: usize,
    strs_len: usize,
    max_strs_size: usize,
    opts: c_int,
};

pub const nghttp2_nv = extern struct {
    name: ?[*]u8,
    value: ?[*]u8,
    namelen: usize,
    valuelen: usize,
    flags: u8,
};

const NGHTTP2_NV_FLAG_NONE: u8 = 0;

fn entryNew(
    name: [*]const u8,
    namelen: usize,
    value: ?[*]const u8,
    valuelen: usize,
    opts: c_int,
) ?*dynhds_entry {
    if ((std.math.maxInt(usize) - namelen - valuelen) < (@sizeOf(dynhds_entry) + 2))
        return null;
    const raw = mem.calloc(1, @sizeOf(dynhds_entry) + namelen + valuelen + 2) orelse return null;
    const e: *dynhds_entry = @ptrCast(@alignCast(raw));
    const p_name = raw + @sizeOf(dynhds_entry);
    @memcpy(p_name[0..namelen], name[0..namelen]);
    e.name = @ptrCast(p_name);
    e.namelen = namelen;
    const p_val = p_name + namelen + 1;
    e.value = @ptrCast(p_val);
    if (valuelen != 0) {
        const v = value.?;
        @memcpy(p_val[0..valuelen], v[0..valuelen]);
        e.valuelen = valuelen;
    }
    if ((opts & DYNHDS_OPT_LOWERCASE) != 0) {
        primitives.Curl_strntolower(e.name, e.name, e.namelen);
    }
    return e;
}

inline fn entryFree(e: ?*dynhds_entry) void {
    mem.free(e);
}

pub export fn Curl_dynhds_init(
    h: ?*dynhds,
    max_entries: usize,
    max_strs_size: usize,
) callconv(.c) void {
    const d = h orelse return;
    std.debug.assert(max_strs_size != 0);
    d.hds = null;
    d.hds_len = 0;
    d.hds_allc = 0;
    d.strs_len = 0;
    d.max_entries = max_entries;
    d.max_strs_size = max_strs_size;
    d.opts = 0;
}

pub export fn Curl_dynhds_free(h: ?*dynhds) callconv(.c) void {
    const d = h orelse return;
    if (d.hds) |hds_arr| {
        if (d.hds_len != 0) {
            for (0..d.hds_len) |i| {
                entryFree(hds_arr[i]);
            }
        }
        mem.free(@ptrCast(hds_arr));
        d.hds = null;
    }
    d.hds_len = 0;
    d.hds_allc = 0;
    d.strs_len = 0;
}

pub export fn Curl_dynhds_reset(h: ?*dynhds) callconv(.c) void {
    const d = h orelse return;
    if (d.hds_len != 0) {
        if (d.hds) |hds_arr| {
            for (0..d.hds_len) |i| {
                entryFree(hds_arr[i]);
                hds_arr[i] = null;
            }
        }
    }
    d.hds_len = 0;
    d.strs_len = 0;
}

pub export fn Curl_dynhds_count(h: ?*const dynhds) callconv(.c) usize {
    const d = h orelse return 0;
    return d.hds_len;
}

pub export fn Curl_dynhds_set_opts(h: ?*dynhds, opts: c_int) callconv(.c) void {
    const d = h orelse return;
    d.opts = opts;
}

pub export fn Curl_dynhds_getn(h: ?*dynhds, n: usize) callconv(.c) ?*dynhds_entry {
    const d = h orelse return null;
    if (n < d.hds_len) {
        if (d.hds) |hds_arr| {
            return hds_arr[n];
        }
    }
    return null;
}

pub export fn Curl_dynhds_get(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
) callconv(.c) ?*dynhds_entry {
    const d = h orelse return null;
    const n = name orelse return null;
    const hds_arr = d.hds orelse return null;
    for (0..d.hds_len) |i| {
        if (hds_arr[i]) |e| {
            if (e.namelen == namelen and primitives.curl_strnequal(e.name, @ptrCast(n), namelen) != 0) {
                return e;
            }
        }
    }
    return null;
}

pub export fn Curl_dynhds_cget(h: ?*dynhds, name: ?[*:0]const u8) callconv(.c) ?*dynhds_entry {
    const n = name orelse return null;
    return Curl_dynhds_get(h, n, std.mem.len(n));
}

pub export fn Curl_dynhds_add(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
    value: ?[*]const u8,
    valuelen: usize,
) callconv(.c) CURLcode {
    const d = h orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const n = name orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (namelen == 0 or (value == null and valuelen != 0)) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    if ((d.max_entries != 0 and (d.hds_len >= d.max_entries)) or
        (d.max_strs_size - d.strs_len < namelen) or
        (d.max_strs_size - d.strs_len - namelen < valuelen))
    {
        return CURLE_OUT_OF_MEMORY;
    }

    const entry = entryNew(n, namelen, value, valuelen, d.opts) orelse return CURLE_OUT_OF_MEMORY;

    if (d.hds_len + 1 >= d.hds_allc) {
        var nallc: usize = if (d.hds_allc != 0) d.hds_allc * 2 else 16;
        if (d.max_entries != 0 and nallc > d.max_entries)
            nallc = d.max_entries;

        const raw = mem.calloc(nallc, @sizeOf(?*dynhds_entry)) orelse {
            entryFree(entry);
            return CURLE_OUT_OF_MEMORY;
        };
        const nhds: [*]?*dynhds_entry = @ptrCast(@alignCast(raw));
        if (d.hds) |old_hds| {
            @memcpy(nhds[0..d.hds_len], old_hds[0..d.hds_len]);
            mem.free(@ptrCast(old_hds));
        }
        d.hds = nhds;
        d.hds_allc = nallc;
    }

    d.hds.?[d.hds_len] = entry;
    d.hds_len += 1;
    d.strs_len += namelen + valuelen;
    return CURLE_OK;
}

pub export fn Curl_dynhds_cadd(
    h: ?*dynhds,
    name: ?[*:0]const u8,
    value: ?[*:0]const u8,
) callconv(.c) CURLcode {
    const n = name orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const val_len: usize = if (value) |v| std.mem.len(v) else 0;
    return Curl_dynhds_add(h, n, std.mem.len(n), value, val_len);
}

pub export fn Curl_dynhds_h1_add_line(
    h: ?*dynhds,
    line: ?[*]const u8,
    line_len: usize,
) callconv(.c) CURLcode {
    const l = line orelse return CURLE_OK;
    if (line_len == 0)
        return CURLE_OK;

    const slice = l[0..line_len];
    const colon_idx = std.mem.indexOfScalar(u8, slice, ':') orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (colon_idx == 0)
        return CURLE_BAD_FUNCTION_ARGUMENT;

    const name = l;
    const namelen = colon_idx;
    var i: usize = namelen + 1;
    while (i < line_len) : (i += 1) {
        const ch = slice[i];
        if (ch != ' ' and ch != '\t')
            break;
    }
    const value = l + i;
    var valuelen = line_len - i;

    const val_slice = value[0..valuelen];
    if (std.mem.indexOfScalar(u8, val_slice, '\r')) |cr_idx| {
        valuelen = cr_idx;
    } else if (std.mem.indexOfScalar(u8, val_slice, '\n')) |lf_idx| {
        valuelen = lf_idx;
    }

    return Curl_dynhds_add(h, name, namelen, value, valuelen);
}

pub export fn Curl_dynhds_h1_cadd_line(h: ?*dynhds, line: ?[*:0]const u8) callconv(.c) CURLcode {
    const l = line orelse return Curl_dynhds_h1_add_line(h, null, 0);
    return Curl_dynhds_h1_add_line(h, l, std.mem.len(l));
}

pub export fn dynhds_contains(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
) callconv(.c) bool {
    return Curl_dynhds_get(h, name, namelen) != null;
}

pub export fn Curl_dynhds_contains(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
) callconv(.c) bool {
    return dynhds_contains(h, name, namelen);
}

pub export fn dynhds_ccontains(h: ?*dynhds, name: ?[*:0]const u8) callconv(.c) bool {
    const n = name orelse return false;
    return dynhds_contains(h, n, std.mem.len(n));
}

pub export fn Curl_dynhds_ccontains(h: ?*dynhds, name: ?[*:0]const u8) callconv(.c) bool {
    return dynhds_ccontains(h, name);
}

pub export fn dynhds_count_name(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
) callconv(.c) usize {
    const d = h orelse return 0;
    const n = name orelse return 0;
    var count: usize = 0;
    if (d.hds_len != 0) {
        if (d.hds) |hds_arr| {
            for (0..d.hds_len) |i| {
                if (hds_arr[i]) |e| {
                    if (namelen == e.namelen and primitives.curl_strnequal(@ptrCast(n), e.name, namelen) != 0) {
                        count += 1;
                    }
                }
            }
        }
    }
    return count;
}

pub export fn Curl_dynhds_count_name(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
) callconv(.c) usize {
    return dynhds_count_name(h, name, namelen);
}

pub export fn dynhds_ccount_name(h: ?*dynhds, name: ?[*:0]const u8) callconv(.c) usize {
    const n = name orelse return 0;
    return dynhds_count_name(h, n, std.mem.len(n));
}

pub export fn Curl_dynhds_ccount_name(h: ?*dynhds, name: ?[*:0]const u8) callconv(.c) usize {
    return dynhds_ccount_name(h, name);
}

pub export fn dynhds_remove(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
) callconv(.c) usize {
    const d = h orelse return 0;
    const name_ptr = name orelse return 0;
    var n: usize = 0;
    if (d.hds_len != 0) {
        if (d.hds) |hds_arr| {
            var i: usize = 0;
            while (i < d.hds_len) {
                const e = hds_arr[i].?;
                if (namelen == e.namelen and primitives.curl_strnequal(@ptrCast(name_ptr), e.name, namelen) != 0) {
                    n += 1;
                    d.hds_len -= 1;
                    d.strs_len -= (e.namelen + e.valuelen);
                    entryFree(e);
                    const rem_len = d.hds_len - i;
                    if (rem_len != 0) {
                        std.mem.copyForwards(?*dynhds_entry, hds_arr[i .. i + rem_len], hds_arr[i + 1 .. i + 1 + rem_len]);
                    }
                } else {
                    i += 1;
                }
            }
        }
    }
    return n;
}

pub export fn Curl_dynhds_rm(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
) callconv(.c) usize {
    return dynhds_remove(h, name, namelen);
}

pub export fn dynhds_cremove(h: ?*dynhds, name: ?[*:0]const u8) callconv(.c) usize {
    const n = name orelse return 0;
    return dynhds_remove(h, n, std.mem.len(n));
}

pub export fn Curl_dynhds_crm(h: ?*dynhds, name: ?[*:0]const u8) callconv(.c) usize {
    return dynhds_cremove(h, name);
}

pub export fn dynhds_set(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
    value: ?[*]const u8,
    valuelen: usize,
) callconv(.c) CURLcode {
    _ = dynhds_remove(h, name, namelen);
    return Curl_dynhds_add(h, name, namelen, value, valuelen);
}

pub export fn Curl_dynhds_set(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
    value: ?[*]const u8,
    valuelen: usize,
) callconv(.c) CURLcode {
    return dynhds_set(h, name, namelen, value, valuelen);
}

pub export fn Curl_dynhds_Set(
    h: ?*dynhds,
    name: ?[*]const u8,
    namelen: usize,
    value: ?[*]const u8,
    valuelen: usize,
) callconv(.c) CURLcode {
    return dynhds_set(h, name, namelen, value, valuelen);
}

pub export fn Curl_dynhds_cset(
    h: ?*dynhds,
    name: ?[*:0]const u8,
    value: ?[*:0]const u8,
) callconv(.c) CURLcode {
    const n = name orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const val_len: usize = if (value) |v| std.mem.len(v) else 0;
    return dynhds_set(h, n, std.mem.len(n), value, val_len);
}

pub export fn Curl_dynhds_h1_dprint(h: ?*dynhds, dbuf: *Dynbuf) callconv(.c) CURLcode {
    const d = h orelse return CURLE_OK;
    if (d.hds_len == 0)
        return CURLE_OK;
    const hds_arr = d.hds orelse return CURLE_OK;

    var result: CURLcode = CURLE_OK;
    for (0..d.hds_len) |i| {
        const e = hds_arr[i].?;
        result = curlx_dyn_addn(dbuf, e.name, e.namelen);
        if (result == CURLE_OK)
            result = curlx_dyn_addn(dbuf, ": ", 2);
        if (result == CURLE_OK)
            result = curlx_dyn_addn(dbuf, e.value, e.valuelen);
        if (result == CURLE_OK)
            result = curlx_dyn_addn(dbuf, "\r\n", 2);
        if (result != CURLE_OK)
            break;
    }
    return result;
}

pub export fn Curl_dynhds_to_nva(h: ?*dynhds, pcount: *usize) callconv(.c) ?[*]nghttp2_nv {
    const d = h orelse {
        pcount.* = 0;
        return null;
    };
    const raw = mem.calloc(1, @sizeOf(nghttp2_nv) * d.hds_len) orelse {
        pcount.* = 0;
        return null;
    };
    const nva: [*]nghttp2_nv = @ptrCast(@alignCast(raw));
    if (d.hds) |hds_arr| {
        for (0..d.hds_len) |i| {
            const e = hds_arr[i].?;
            nva[i] = .{
                .name = e.name,
                .value = e.value,
                .namelen = e.namelen,
                .valuelen = e.valuelen,
                .flags = NGHTTP2_NV_FLAG_NONE,
            };
        }
    }
    pcount.* = d.hds_len;
    return nva;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "bufq init, write, read, peek, skip, reset, soft_limit" {
    var q: bufq = undefined;
    Curl_bufq_init(&q, 16, 2);
    defer Curl_bufq_free(&q);

    try std.testing.expect(Curl_bufq_is_empty(&q));
    try std.testing.expect(!Curl_bufq_is_full(&q));
    try std.testing.expectEqual(@as(usize, 0), Curl_bufq_len(&q));

    var out: [64]u8 = undefined;
    var nread: usize = 0;
    try std.testing.expectEqual(CURLE_AGAIN, Curl_bufq_read(&q, &out, out.len, &nread));

    const msg = "0123456789abcdefABCDEFGHIJKLMNOP"; // 32 bytes = 2 chunks of 16
    var nwritten: usize = 0;
    try std.testing.expectEqual(CURLE_OK, Curl_bufq_write(&q, msg.ptr, msg.len, &nwritten));
    try std.testing.expectEqual(@as(usize, 32), nwritten);
    try std.testing.expect(Curl_bufq_is_full(&q));
    try std.testing.expectEqual(@as(usize, 32), Curl_bufq_len(&q));

    // Full queue rejects additional write without soft limit
    try std.testing.expectEqual(CURLE_AGAIN, Curl_bufq_write(&q, "X", 1, &nwritten));
    try std.testing.expectEqual(@as(usize, 0), nwritten);

    // Peek head and peek_at across chunk boundary
    var pbuf: ?[*]const u8 = null;
    var plen: usize = 0;
    try std.testing.expect(Curl_bufq_peek(&q, &pbuf, &plen));
    try std.testing.expectEqualStrings("0123456789abcdef", pbuf.?[0..plen]);

    try std.testing.expect(Curl_bufq_peek_at(&q, 20, &pbuf, &plen));
    try std.testing.expectEqualStrings("EFGHIJKLMNOP", pbuf.?[0..plen]);
    try std.testing.expect(!Curl_bufq_peek_at(&q, 32, &pbuf, &plen));

    // Skip 10 bytes, then read 12 bytes (crossing first to second chunk)
    Curl_bufq_skip(&q, 10);
    try std.testing.expectEqual(@as(usize, 22), Curl_bufq_len(&q));
    try std.testing.expectEqual(CURLE_OK, Curl_bufq_read(&q, &out, 12, &nread));
    try std.testing.expectEqual(@as(usize, 12), nread);
    try std.testing.expectEqualStrings("abcdefABCDEF", out[0..12]);

    // Reset and verify spare reuse
    Curl_bufq_reset(&q);
    try std.testing.expect(Curl_bufq_is_empty(&q));
    try std.testing.expectEqual(@as(usize, 0), Curl_bufq_len(&q));
}

test "bufq pool, slurp, pass, write_pass, soft limit" {
    var pool: bufc_pool = undefined;
    Curl_bufcp_init(&pool, 8, 4);
    defer Curl_bufcp_free(&pool);

    var q: bufq = undefined;
    Curl_bufq_initp(&q, &pool, 2, BUFQ_OPT_SOFT_LIMIT);
    defer Curl_bufq_free(&q);

    const Ctx = struct {
        src: []const u8,
        rpos: usize = 0,
        dst: [64]u8 = undefined,
        wpos: usize = 0,

        fn reader(ctx_ptr: ?*anyopaque, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode {
            const self: *@This() = @ptrCast(@alignCast(ctx_ptr.?));
            const rem = self.src.len - self.rpos;
            if (rem == 0) {
                pnread.* = 0;
                return CURLE_AGAIN;
            }
            const n = @min(rem, len);
            @memcpy(buf[0..n], self.src[self.rpos .. self.rpos + n]);
            self.rpos += n;
            pnread.* = n;
            return CURLE_OK;
        }

        fn writer(ctx_ptr: ?*anyopaque, buf: [*]const u8, len: usize, pwritten: *usize) callconv(.c) CURLcode {
            const self: *@This() = @ptrCast(@alignCast(ctx_ptr.?));
            const n = @min(self.dst.len - self.wpos, len);
            @memcpy(self.dst[self.wpos .. self.wpos + n], buf[0..n]);
            self.wpos += n;
            pwritten.* = n;
            return CURLE_OK;
        }
    };

    var ctx = Ctx{ .src = "hello buffered world!!" };
    var nread: usize = 0;
    try std.testing.expectEqual(CURLE_OK, Curl_bufq_slurp(&q, Ctx.reader, &ctx, &nread));
    try std.testing.expectEqual(ctx.src.len, nread);
    // Exceeded 2 chunks of 8 bytes = 16 bytes due to SOFT_LIMIT
    try std.testing.expect(Curl_bufq_is_full(&q));

    var nwritten: usize = 0;
    try std.testing.expectEqual(CURLE_OK, Curl_bufq_write_pass(&q, "++extra", 7, Ctx.writer, &ctx, &nwritten));
    try std.testing.expectEqual(@as(usize, 7), nwritten);
    try std.testing.expectEqual(CURLE_OK, Curl_bufq_pass(&q, Ctx.writer, &ctx, &nwritten));
    try std.testing.expect(Curl_bufq_is_empty(&q));
    try std.testing.expectEqualStrings("hello buffered world!!++extra", ctx.dst[0..ctx.wpos]);
    try std.testing.expect(pool.spare_count > 0);
}

test "dynhds add, get, remove, set, contains, lowercase, h1_dprint, to_nva" {
    var hds: dynhds = undefined;
    Curl_dynhds_init(&hds, 4, 256);
    defer Curl_dynhds_free(&hds);

    try std.testing.expectEqual(@as(usize, 0), Curl_dynhds_count(&hds));
    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_cadd(&hds, "Content-Type", "text/plain"));
    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_h1_cadd_line(&hds, "X-Custom:   value1\r\n"));
    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_cadd(&hds, "x-custom", "value2"));
    try std.testing.expectEqual(@as(usize, 3), Curl_dynhds_count(&hds));

    try std.testing.expect(dynhds_ccontains(&hds, "CONTENT-TYPE"));
    try std.testing.expectEqual(@as(usize, 2), dynhds_ccount_name(&hds, "X-CuStOm"));

    const e0 = Curl_dynhds_cget(&hds, "content-type").?;
    try std.testing.expectEqualStrings("Content-Type", e0.name[0..e0.namelen]);
    try std.testing.expectEqualStrings("text/plain", e0.value[0..e0.valuelen]);

    // Replace both X-Custom entries with a single lowercase entry
    Curl_dynhds_set_opts(&hds, DYNHDS_OPT_LOWERCASE);
    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_cset(&hds, "X-Custom", "final"));
    try std.testing.expectEqual(@as(usize, 2), Curl_dynhds_count(&hds));

    const e1 = Curl_dynhds_getn(&hds, 1).?;
    try std.testing.expectEqualStrings("x-custom", e1.name[0..e1.namelen]);
    try std.testing.expectEqualStrings("final", e1.value[0..e1.valuelen]);

    var dbuf: Dynbuf = undefined;
    curlx_dyn_init(&dbuf, 4096);
    defer curlx_dyn_free(&dbuf);

    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_h1_dprint(&hds, &dbuf));
    const printed = curlx_dyn_ptr(&dbuf).?[0..curlx_dyn_len(&dbuf)];
    try std.testing.expectEqualStrings("Content-Type: text/plain\r\nx-custom: final\r\n", printed);

    var nv_count: usize = 0;
    const nva = Curl_dynhds_to_nva(&hds, &nv_count).?;
    defer mem.free(@ptrCast(nva));
    try std.testing.expectEqual(@as(usize, 2), nv_count);
    try std.testing.expectEqualStrings("Content-Type", nva[0].name.?[0..nva[0].namelen]);
    try std.testing.expectEqualStrings("final", nva[1].value.?[0..nva[1].valuelen]);

    try std.testing.expectEqual(@as(usize, 1), dynhds_cremove(&hds, "content-type"));
    try std.testing.expect(!dynhds_ccontains(&hds, "content-type"));
}

test "dynhds limits, overflow, invalid lines, and reset" {
    var hds: dynhds = undefined;
    Curl_dynhds_init(&hds, 2, 16);
    defer Curl_dynhds_free(&hds);

    // Exceed max_entries (2)
    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_add(&hds, "a", 1, "1", 1));
    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_add(&hds, "b", 1, "2", 1));
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, Curl_dynhds_add(&hds, "c", 1, "3", 1));

    // Overflow detection
    try std.testing.expectEqual(
        CURLE_OUT_OF_MEMORY,
        Curl_dynhds_add(&hds, "a", std.math.maxInt(usize) / 2, "b", std.math.maxInt(usize) / 2),
    );

    // Invalid arguments
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_dynhds_add(&hds, "", 0, "v", 1));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_dynhds_add(&hds, "k", 1, null, 2));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_dynhds_h1_cadd_line(&hds, "no-colon-here"));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_dynhds_h1_cadd_line(&hds, ": empty-name"));

    // Reset and test max_strs_size limit (16 bytes)
    Curl_dynhds_reset(&hds);
    try std.testing.expectEqual(@as(usize, 0), Curl_dynhds_count(&hds));
    try std.testing.expectEqual(CURLE_OK, Curl_dynhds_add(&hds, "12345678", 8, "12345678", 8));
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, Curl_dynhds_add(&hds, "x", 1, "", 0));
}
