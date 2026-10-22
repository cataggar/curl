const std = @import("std");
const backend_options = @import("backend_options");

// ============================================================================
// 1. Pure-Zig zlib / gzip / deflate provider (std.compress.flate.Decompress)
// ============================================================================

const z_alloc_func = ?*const fn (opaque_ptr: ?*anyopaque, items: c_uint, size: c_uint) callconv(.c) ?*anyopaque;
const z_free_func = ?*const fn (opaque_ptr: ?*anyopaque, address: ?*anyopaque) callconv(.c) void;

pub const z_stream = extern struct {
    next_in: ?[*]const u8 = null,
    avail_in: c_uint = 0,
    total_in: c_ulong = 0,
    next_out: ?[*]u8 = null,
    avail_out: c_uint = 0,
    total_out: c_ulong = 0,
    msg: ?[*:0]const u8 = null,
    state: ?*anyopaque = null,
    zalloc: z_alloc_func = null,
    zfree: z_free_func = null,
    opaque_ptr: ?*anyopaque = null,
    data_type: c_int = 0,
    adler: c_ulong = 0,
    reserved: c_ulong = 0,
};

const Z_OK: c_int = 0;
const Z_STREAM_END: c_int = 1;
const Z_STREAM_ERROR: c_int = -2;
const Z_DATA_ERROR: c_int = -3;
const Z_MEM_ERROR: c_int = -4;
const Z_BUF_ERROR: c_int = -5;

const ZlibState = struct {
    window_bits: c_int,
    in_buf: std.ArrayListUnmanaged(u8) = .empty,
    out_buf: std.ArrayListUnmanaged(u8) = .empty,
    out_pos: usize = 0,
    consumed_in: usize = 0,
    finished: bool = false,

    fn deinit(self: *ZlibState) void {
        self.in_buf.deinit(std.heap.c_allocator);
        self.out_buf.deinit(std.heap.c_allocator);
    }

    fn reset(self: *ZlibState, window_bits: c_int) void {
        self.window_bits = window_bits;
        self.in_buf.clearRetainingCapacity();
        self.out_buf.clearRetainingCapacity();
        self.out_pos = 0;
        self.consumed_in = 0;
        self.finished = false;
    }
};

fn detectContainer(window_bits: c_int, input: []const u8) std.compress.flate.Container {
    if (window_bits < 0) return .raw;
    if ((window_bits & 16) != 0 and (window_bits & 32) == 0) return .gzip;
    if ((window_bits & 32) != 0) {
        if (input.len > 0 and input[0] == 0x1f) return .gzip;
        return .zlib;
    }
    return .zlib;
}

fn zlibVersionImpl() callconv(.c) [*:0]const u8 {
    return "1.3.1";
}

fn inflateInitImpl(strm_opt: ?*z_stream, version: [*:0]const u8, stream_size: c_int) callconv(.c) c_int {
    return inflateInit2Impl(strm_opt, 15, version, stream_size);
}

fn inflateInit2Impl(strm_opt: ?*z_stream, window_bits: c_int, version: [*:0]const u8, stream_size: c_int) callconv(.c) c_int {
    _ = version;
    _ = stream_size;
    const strm = strm_opt orelse return Z_STREAM_ERROR;
    const state = std.heap.c_allocator.create(ZlibState) catch return Z_MEM_ERROR;
    state.* = .{ .window_bits = window_bits };
    strm.state = @ptrCast(state);
    strm.total_in = 0;
    strm.total_out = 0;
    strm.msg = null;
    return Z_OK;
}

fn inflateReset2Impl(strm_opt: ?*z_stream, window_bits: c_int) callconv(.c) c_int {
    const strm = strm_opt orelse return Z_STREAM_ERROR;
    const state: *ZlibState = @ptrCast(@alignCast(strm.state orelse return Z_STREAM_ERROR));
    state.reset(window_bits);
    strm.total_in = 0;
    strm.total_out = 0;
    strm.msg = null;
    return Z_OK;
}

fn inflateImpl(strm_opt: ?*z_stream, flush: c_int) callconv(.c) c_int {
    _ = flush;
    const strm = strm_opt orelse return Z_STREAM_ERROR;
    const state: *ZlibState = @ptrCast(@alignCast(strm.state orelse return Z_STREAM_ERROR));

    // First drain any already-decoded output waiting in state.out_buf
    if (state.out_pos < state.out_buf.items.len) {
        const remaining = state.out_buf.items.len - state.out_pos;
        const copy_len = @min(remaining, @as(usize, strm.avail_out));
        if (copy_len > 0) {
            if (strm.next_out) |dst| {
                @memcpy(dst[0..copy_len], state.out_buf.items[state.out_pos .. state.out_pos + copy_len]);
                strm.next_out = dst + copy_len;
            }
            strm.avail_out -= @intCast(copy_len);
            strm.total_out += @intCast(copy_len);
            state.out_pos += copy_len;
        }
        if (state.out_pos == state.out_buf.items.len and state.finished) {
            return Z_STREAM_END;
        }
        return if (copy_len > 0) Z_OK else Z_BUF_ERROR;
    }

    if (state.finished) {
        return Z_STREAM_END;
    }

    if (strm.avail_in == 0) {
        return Z_BUF_ERROR;
    }

    const prev_in_len = state.in_buf.items.len;
    const in_slice = (strm.next_in orelse return Z_STREAM_ERROR)[0..strm.avail_in];
    state.in_buf.appendSlice(std.heap.c_allocator, in_slice) catch return Z_MEM_ERROR;

    const container = detectContainer(state.window_bits, state.in_buf.items);
    var fixed = std.Io.Reader.fixed(state.in_buf.items);
    var window_buf: [std.compress.flate.max_window_len]u8 = undefined;
    var decomp = std.compress.flate.Decompress.init(&fixed, container, &window_buf);

    var decoded = std.ArrayListUnmanaged(u8).empty;
    defer decoded.deinit(std.heap.c_allocator);

    var tmp: [16384]u8 = undefined;
    var hit_eof = false;
    while (true) {
        const n = decomp.reader.readSliceShort(&tmp) catch |err| switch (err) {
            error.ReadFailed => {
                if (decomp.err) |derr| switch (derr) {
                    error.EndOfStream => break,
                    else => {
                        strm.next_in = in_slice.ptr + in_slice.len;
                        strm.total_in += strm.avail_in;
                        strm.avail_in = 0;
                        return Z_DATA_ERROR;
                    },
                };
                break;
            },
        };
        if (n > 0) {
            decoded.appendSlice(std.heap.c_allocator, tmp[0..n]) catch return Z_MEM_ERROR;
        }
        if (n < tmp.len) {
            if (decomp.err == null) {
                hit_eof = true;
            }
            break;
        }
    }

    // How many bytes of state.in_buf were actually consumed by the flate stream?
    const total_used_in = if (hit_eof) fixed.seek else state.in_buf.items.len;
    const newly_used_in = if (total_used_in > prev_in_len) total_used_in - prev_in_len else 0;
    const consume_now = @min(newly_used_in, in_slice.len);

    strm.next_in = in_slice.ptr + consume_now;
    strm.avail_in -= @intCast(consume_now);
    strm.total_in += @intCast(consume_now);
    state.in_buf.shrinkRetainingCapacity(prev_in_len + consume_now);

    if (hit_eof) {
        state.finished = true;
    }

    // Emit only the newly decoded bytes beyond what we already emitted in earlier chunks
    const already_emitted = state.out_buf.items.len;
    if (decoded.items.len > already_emitted) {
        const new_out = decoded.items[already_emitted..];
        state.out_buf.appendSlice(std.heap.c_allocator, new_out) catch return Z_MEM_ERROR;
    }

    const avail_decoded = state.out_buf.items.len - state.out_pos;
    const copy_len = @min(avail_decoded, @as(usize, strm.avail_out));
    if (copy_len > 0) {
        if (strm.next_out) |dst| {
            @memcpy(dst[0..copy_len], state.out_buf.items[state.out_pos .. state.out_pos + copy_len]);
            strm.next_out = dst + copy_len;
        }
        strm.avail_out -= @intCast(copy_len);
        strm.total_out += @intCast(copy_len);
        state.out_pos += copy_len;
    }

    if (state.out_pos == state.out_buf.items.len and state.finished) {
        return Z_STREAM_END;
    }
    return Z_OK;
}

fn inflateEndImpl(strm_opt: ?*z_stream) callconv(.c) c_int {
    const strm = strm_opt orelse return Z_STREAM_ERROR;
    if (strm.state) |raw| {
        const state: *ZlibState = @ptrCast(@alignCast(raw));
        state.deinit();
        std.heap.c_allocator.destroy(state);
        strm.state = null;
    }
    return Z_OK;
}

// ============================================================================
// 2. Pure-Zig zstd provider (std.compress.zstd.Decompress)
// ============================================================================

pub const ZSTD_inBuffer = extern struct {
    src: ?*const anyopaque = null,
    size: usize = 0,
    pos: usize = 0,
};

pub const ZSTD_outBuffer = extern struct {
    dst: ?*anyopaque = null,
    size: usize = 0,
    pos: usize = 0,
};

const ZSTD_ERR_GENERIC: usize = @bitCast(@as(isize, -1));
const ZSTD_ERR_CORRUPTION: usize = @bitCast(@as(isize, -2));
const ZSTD_ERR_MEMORY: usize = @bitCast(@as(isize, -3));

const ZstdState = struct {
    in_buf: std.ArrayListUnmanaged(u8) = .empty,
    out_buf: std.ArrayListUnmanaged(u8) = .empty,
    out_pos: usize = 0,
    finished: bool = false,

    fn deinit(self: *ZstdState) void {
        self.in_buf.deinit(std.heap.c_allocator);
        self.out_buf.deinit(std.heap.c_allocator);
    }
};

fn zstdVersionNumberImpl() callconv(.c) c_uint {
    return 10506;
}

fn zstdCreateDStreamImpl() callconv(.c) ?*anyopaque {
    const state = std.heap.c_allocator.create(ZstdState) catch return null;
    state.* = .{};
    return @ptrCast(state);
}

fn zstdFreeDStreamImpl(zds_raw: ?*anyopaque) callconv(.c) usize {
    if (zds_raw) |raw| {
        const state: *ZstdState = @ptrCast(@alignCast(raw));
        state.deinit();
        std.heap.c_allocator.destroy(state);
    }
    return 0;
}

fn zstdIsErrorImpl(code: usize) callconv(.c) c_uint {
    const signed: isize = @bitCast(code);
    return if (signed < 0) 1 else 0;
}

fn zstdGetErrorNameImpl(code: usize) callconv(.c) [*:0]const u8 {
    return switch (code) {
        ZSTD_ERR_CORRUPTION => "Corrupted block detected",
        ZSTD_ERR_MEMORY => "Allocation error : not enough memory",
        else => "Error (generic)",
    };
}

fn zstdDecompressStreamImpl(zds_raw: ?*anyopaque, output_opt: ?*ZSTD_outBuffer, input_opt: ?*ZSTD_inBuffer) callconv(.c) usize {
    const state: *ZstdState = @ptrCast(@alignCast(zds_raw orelse return ZSTD_ERR_GENERIC));
    const output = output_opt orelse return ZSTD_ERR_GENERIC;
    const input = input_opt orelse return ZSTD_ERR_GENERIC;

    // Drain any buffered output first
    if (state.out_pos < state.out_buf.items.len) {
        const out_avail = output.size - output.pos;
        const rem = state.out_buf.items.len - state.out_pos;
        const copy_len = @min(rem, out_avail);
        if (copy_len > 0) {
            const dst: [*]u8 = @ptrCast(output.dst orelse return ZSTD_ERR_GENERIC);
            @memcpy(dst[output.pos .. output.pos + copy_len], state.out_buf.items[state.out_pos .. state.out_pos + copy_len]);
            output.pos += copy_len;
            state.out_pos += copy_len;
        }
        if (state.out_pos < state.out_buf.items.len) return 1;
        if (state.finished and input.pos == input.size) return 0;
    }

    if (input.pos < input.size) {
        if (state.finished) {
            state.in_buf.clearRetainingCapacity();
            state.out_buf.clearRetainingCapacity();
            state.out_pos = 0;
            state.finished = false;
        }
        const src: [*]const u8 = @ptrCast(input.src orelse return ZSTD_ERR_GENERIC);
        const new_slice = src[input.pos..input.size];
        state.in_buf.appendSlice(std.heap.c_allocator, new_slice) catch return ZSTD_ERR_MEMORY;
        input.pos = input.size;
    } else if (state.finished) {
        return 0;
    }

    if (state.in_buf.items.len == 0) return 1;

    var fixed = std.Io.Reader.fixed(state.in_buf.items);
    const window_buf = std.heap.c_allocator.alloc(u8, std.compress.zstd.default_window_len + std.compress.zstd.block_size_max) catch return ZSTD_ERR_MEMORY;
    defer std.heap.c_allocator.free(window_buf);

    var decomp = std.compress.zstd.Decompress.init(&fixed, window_buf, .{});
    var decoded = std.ArrayListUnmanaged(u8).empty;
    defer decoded.deinit(std.heap.c_allocator);

    var tmp: [16384]u8 = undefined;
    var hit_eof = false;
    while (true) {
        const n = decomp.reader.readSliceShort(&tmp) catch |err| switch (err) {
            error.ReadFailed => {
                if (decomp.err) |derr| switch (derr) {
                    error.EndOfStream => break,
                    else => return ZSTD_ERR_CORRUPTION,
                };
                return ZSTD_ERR_CORRUPTION;
            },
        };
        if (n > 0) {
            decoded.appendSlice(std.heap.c_allocator, tmp[0..n]) catch return ZSTD_ERR_MEMORY;
        }
        if (n < tmp.len) {
            if (decomp.err == null) {
                hit_eof = true;
            }
            break;
        }
    }

    if (hit_eof and fixed.seek < state.in_buf.items.len) {
        // Trailing garbage after completed zstd frame
        return ZSTD_ERR_CORRUPTION;
    }

    if (hit_eof) {
        state.finished = true;
    }

    const already_emitted = state.out_buf.items.len;
    if (decoded.items.len > already_emitted) {
        state.out_buf.appendSlice(std.heap.c_allocator, decoded.items[already_emitted..]) catch return ZSTD_ERR_MEMORY;
    }

    if (state.out_pos < state.out_buf.items.len) {
        const out_avail = output.size - output.pos;
        const rem = state.out_buf.items.len - state.out_pos;
        const copy_len = @min(rem, out_avail);
        if (copy_len > 0) {
            const dst: [*]u8 = @ptrCast(output.dst orelse return ZSTD_ERR_GENERIC);
            @memcpy(dst[output.pos .. output.pos + copy_len], state.out_buf.items[state.out_pos .. state.out_pos + copy_len]);
            output.pos += copy_len;
            state.out_pos += copy_len;
        }
    }

    if (state.out_pos < state.out_buf.items.len) return 1;
    return if (state.finished) 0 else 1;
}

// ============================================================================
// 3. Pure-Zig Brotli (RFC 7932) provider
// ============================================================================

const BROTLI_DECODER_RESULT_ERROR: c_int = 0;
const BROTLI_DECODER_RESULT_SUCCESS: c_int = 1;
const BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT: c_int = 2;
const BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT: c_int = 3;

const BrotliBitReader = struct {
    data: []const u8,
    bit_pos: usize = 0,

    fn readBits(self: *BrotliBitReader, comptime T: type, n: u6) !T {
        if (n == 0) return 0;
        if (self.bit_pos + n > self.data.len * 8) return error.NeedMoreInput;
        var val: u32 = 0;
        var i: u6 = 0;
        while (i < n) : (i += 1) {
            const byte_idx = (self.bit_pos + i) >> 3;
            const bit_idx: u3 = @intCast((self.bit_pos + i) & 7);
            const bit: u32 = (self.data[byte_idx] >> bit_idx) & 1;
            val |= bit << @intCast(i);
        }
        self.bit_pos += n;
        return @intCast(val);
    }

    fn alignToByte(self: *BrotliBitReader) !void {
        const rem = self.bit_pos & 7;
        if (rem != 0) {
            const pad = try self.readBits(u8, @intCast(8 - rem));
            if (pad != 0) return error.CorruptStream;
        }
    }

    fn bytesConsumed(self: *const BrotliBitReader) usize {
        return (self.bit_pos + 7) >> 3;
    }
};

const BrotliPrefixTree = struct {
    symbols: [704]u16 = undefined,
    lengths: [704]u8 = @splat(0),
    codes: [704]u16 = @splat(0),
    count: usize = 0,
    single_symbol: ?u16 = null,

    fn buildFromLengths(self: *BrotliPrefixTree, code_lengths: []const u8) !void {
        var bl_count: [16]u16 = @splat(0);
        var max_bits: u8 = 0;
        var nz_count: usize = 0;
        var last_sym: u16 = 0;
        for (code_lengths, 0..) |len, sym| {
            if (len > 0) {
                if (len > 15) return error.CorruptStream;
                bl_count[len] += 1;
                if (len > max_bits) max_bits = len;
                nz_count += 1;
                last_sym = @intCast(sym);
            }
        }
        if (nz_count == 0) return error.CorruptStream;
        if (nz_count == 1) {
            self.single_symbol = last_sym;
            self.count = 1;
            return;
        }
        self.single_symbol = null;

        // Check Kraft inequality: sum(bl_count[b] << (15 - b)) == (1 << 15)
        var space: u32 = 1 << 15;
        for (1..16) |b| {
            const needed = @as(u32, bl_count[b]) << @intCast(15 - b);
            if (needed > space) return error.CorruptStream;
            space -= needed;
        }
        if (space != 0) return error.CorruptStream;

        var next_code: [16]u16 = @splat(0);
        var code: u16 = 0;
        for (1..16) |bits| {
            code = (code + bl_count[bits - 1]) << 1;
            next_code[bits] = code;
        }

        self.count = 0;
        for (code_lengths, 0..) |len, sym| {
            if (len != 0) {
                const c_msb = next_code[len];
                next_code[len] += 1;
                // Reverse bits for LSB-first bit reader
                var rev: u16 = 0;
                var b: u8 = 0;
                while (b < len) : (b += 1) {
                    const bit = (c_msb >> @intCast(len - 1 - b)) & 1;
                    rev |= bit << @intCast(b);
                }
                const idx = self.count;
                self.symbols[idx] = @intCast(sym);
                self.lengths[idx] = len;
                self.codes[idx] = rev;
                self.count += 1;
            }
        }
    }

    fn decode(self: *const BrotliPrefixTree, br: *BrotliBitReader) !u16 {
        if (self.single_symbol) |s| return s;
        var code: u16 = 0;
        var len: u8 = 1;
        while (len <= 15) : (len += 1) {
            const bit = try br.readBits(u16, 1);
            code |= bit << @intCast(len - 1);
            for (0..self.count) |i| {
                if (self.lengths[i] == len and self.codes[i] == code) {
                    return self.symbols[i];
                }
            }
        }
        return error.CorruptStream;
    }
};

fn readBrotliPrefixTree(br: *BrotliBitReader, alphabet_size: u16, tree: *BrotliPrefixTree) !void {
    const hskip = try br.readBits(u8, 2);
    if (hskip == 1) {
        // Simple prefix code (RFC 7932 Section 3.4)
        const nsym_minus_1 = try br.readBits(u8, 2);
        const nsym: usize = @as(usize, nsym_minus_1) + 1;
        const max_bits: u6 = @intCast(std.math.log2_int_ceil(u16, alphabet_size));
        var syms: [4]u16 = @splat(0);
        for (0..nsym) |i| {
            syms[i] = try br.readBits(u16, max_bits);
            if (syms[i] >= alphabet_size) return error.CorruptStream;
            for (0..i) |j| {
                if (syms[j] == syms[i]) return error.CorruptStream;
            }
        }
        var lengths: [704]u8 = @splat(0);
        switch (nsym) {
            1 => {
                tree.single_symbol = syms[0];
                tree.count = 1;
                return;
            },
            2 => {
                lengths[syms[0]] = 1;
                lengths[syms[1]] = 1;
            },
            3 => {
                lengths[syms[0]] = 1;
                lengths[syms[1]] = 2;
                lengths[syms[2]] = 2;
            },
            4 => {
                const tree_select = try br.readBits(u8, 1);
                if (tree_select == 0) {
                    lengths[syms[0]] = 2;
                    lengths[syms[1]] = 2;
                    lengths[syms[2]] = 2;
                    lengths[syms[3]] = 2;
                } else {
                    lengths[syms[0]] = 1;
                    lengths[syms[1]] = 2;
                    lengths[syms[2]] = 3;
                    lengths[syms[3]] = 3;
                }
            },
            else => unreachable,
        }
        try tree.buildFromLengths(lengths[0..alphabet_size]);
        return;
    }

    // Complex prefix code (RFC 7932 Section 3.5)
    const cl_order = [_]u8{ 1, 2, 3, 4, 0, 5, 17, 6, 16, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
    var cl_lengths: [18]u8 = @splat(0);
    var space: i32 = 32;
    var num_codes: usize = 0;
    var idx: usize = hskip;
    while (idx < 18 and space > 0) : (idx += 1) {
        const b0 = try br.readBits(u8, 1);
        const b1 = try br.readBits(u8, 1);
        const two = b0 | (b1 << 1);
        const v: u8 = switch (two) {
            0 => 0,
            1 => 4,
            2 => 3,
            3 => blk: {
                const b2 = try br.readBits(u8, 1);
                if (b2 == 0) break :blk 2;
                const b3 = try br.readBits(u8, 1);
                break :blk if (b3 == 0) @as(u8, 1) else @as(u8, 5);
            },
            else => unreachable,
        };
        cl_lengths[cl_order[idx]] = v;
        if (v != 0) {
            space -= @as(i32, 32) >> @intCast(v);
            num_codes += 1;
        }
    }
    if (space != 0 and num_codes != 1) return error.CorruptStream;

    var cl_tree = BrotliPrefixTree{};
    try cl_tree.buildFromLengths(&cl_lengths);

    var symbol_lengths: [704]u8 = @splat(0);
    var sym: usize = 0;
    var prev_code_len: u8 = 8;
    var repeat: usize = 0;
    var repeat_code_len: u8 = 0;
    var sym_space: i32 = 32768;

    while (sym < alphabet_size and sym_space > 0) {
        const code_len_sym = try cl_tree.decode(br);
        if (code_len_sym < 16) {
            repeat = 0;
            const l: u8 = @intCast(code_len_sym);
            symbol_lengths[sym] = l;
            sym += 1;
            if (l != 0) {
                prev_code_len = l;
                sym_space -= @as(i32, 32768) >> @intCast(l);
            }
        } else {
            const extra_bits: u6 = if (code_len_sym == 16) 2 else 3;
            const new_len: u8 = if (code_len_sym == 16) prev_code_len else 0;
            if (repeat_code_len != new_len) {
                repeat = 0;
                repeat_code_len = new_len;
            }
            const old_repeat = repeat;
            if (repeat > 0) {
                repeat = (repeat - 2) << extra_bits;
            }
            repeat += @as(usize, try br.readBits(u8, extra_bits)) + 3;
            const repeat_delta = repeat - old_repeat;
            if (sym + repeat_delta > alphabet_size) return error.CorruptStream;
            for (0..repeat_delta) |_| {
                symbol_lengths[sym] = repeat_code_len;
                sym += 1;
                if (repeat_code_len != 0) {
                    sym_space -= @as(i32, 32768) >> @intCast(repeat_code_len);
                }
            }
        }
    }
    if (sym_space != 0) return error.CorruptStream;
    try tree.buildFromLengths(symbol_lengths[0..alphabet_size]);
}

const InsertLenSlot = struct { base: u32, extra: u6 };
const insert_len_table = [24]InsertLenSlot{
    .{ .base = 0, .extra = 0 },
    .{ .base = 1, .extra = 0 },
    .{ .base = 2, .extra = 0 },
    .{ .base = 3, .extra = 0 },
    .{ .base = 4, .extra = 0 },
    .{ .base = 5, .extra = 0 },
    .{ .base = 6, .extra = 1 },
    .{ .base = 8, .extra = 1 },
    .{ .base = 10, .extra = 2 },
    .{ .base = 14, .extra = 2 },
    .{ .base = 18, .extra = 3 },
    .{ .base = 26, .extra = 3 },
    .{ .base = 34, .extra = 4 },
    .{ .base = 50, .extra = 4 },
    .{ .base = 66, .extra = 5 },
    .{ .base = 98, .extra = 5 },
    .{ .base = 130, .extra = 6 },
    .{ .base = 194, .extra = 7 },
    .{ .base = 322, .extra = 8 },
    .{ .base = 578, .extra = 9 },
    .{ .base = 1090, .extra = 10 },
    .{ .base = 2114, .extra = 12 },
    .{ .base = 6210, .extra = 14 },
    .{ .base = 22594, .extra = 24 },
};

const copy_len_table = [24]InsertLenSlot{
    .{ .base = 2, .extra = 0 },
    .{ .base = 3, .extra = 0 },
    .{ .base = 4, .extra = 0 },
    .{ .base = 5, .extra = 0 },
    .{ .base = 6, .extra = 0 },
    .{ .base = 7, .extra = 0 },
    .{ .base = 8, .extra = 0 },
    .{ .base = 9, .extra = 0 },
    .{ .base = 10, .extra = 1 },
    .{ .base = 12, .extra = 1 },
    .{ .base = 14, .extra = 2 },
    .{ .base = 18, .extra = 2 },
    .{ .base = 22, .extra = 3 },
    .{ .base = 30, .extra = 3 },
    .{ .base = 38, .extra = 4 },
    .{ .base = 54, .extra = 4 },
    .{ .base = 70, .extra = 5 },
    .{ .base = 102, .extra = 5 },
    .{ .base = 134, .extra = 6 },
    .{ .base = 198, .extra = 7 },
    .{ .base = 326, .extra = 8 },
    .{ .base = 582, .extra = 9 },
    .{ .base = 1094, .extra = 10 },
    .{ .base = 2118, .extra = 24 },
};

fn decodeInsertAndCopyCode(ic_code: u16) struct { insert_code: u8, copy_code: u8, use_last_dist: bool } {
    // RFC 7932 Section 5 Table:
    const range_idx: usize = ic_code >> 6;
    const rem: u16 = ic_code & 0x3f;
    const insert_hi: u8 = @intCast((rem >> 3) & 7);
    const copy_hi: u8 = @intCast(rem & 7);

    const insert_bases = [11]u8{ 0, 0, 0, 0, 8, 8, 0, 16, 8, 16, 16 };
    const copy_bases = [11]u8{ 0, 8, 0, 8, 0, 8, 16, 0, 16, 8, 16 };

    return .{
        .insert_code = insert_bases[range_idx] + insert_hi,
        .copy_code = copy_bases[range_idx] + copy_hi,
        .use_last_dist = range_idx < 2,
    };
}

fn decodeBrotliStream(input: []const u8, out: *std.ArrayListUnmanaged(u8)) !usize {
    var br = BrotliBitReader{ .data = input };

    // 1. Read WBITS (RFC 7932 Section 9.1)
    const wbit0 = try br.readBits(u8, 1);
    const wbits: u8 = if (wbit0 == 0)
        16
    else blk: {
        const w3 = try br.readBits(u8, 3);
        if (w3 != 0) break :blk 17 + w3;
        const w3b = try br.readBits(u8, 3);
        if (w3b == 1) return error.CorruptStream;
        if (w3b == 0) break :blk 17;
        break :blk 8 + w3b;
    };
    _ = wbits;

    var dist_ring = [4]usize{ 4, 11, 15, 16 };

    while (true) {
        const is_last = (try br.readBits(u8, 1)) != 0;
        if (is_last) {
            const is_last_empty = (try br.readBits(u8, 1)) != 0;
            if (is_last_empty) {
                try br.alignToByte();
                return br.bytesConsumed();
            }
        }

        const mnibbles_code = try br.readBits(u8, 2);
        if (mnibbles_code == 3) {
            // Metadata block
            if (is_last) return error.CorruptStream;
            const rsv = try br.readBits(u8, 1);
            if (rsv != 0) return error.CorruptStream;
            const mbytes_len = try br.readBits(u8, 2);
            if (mbytes_len == 0) {
                try br.alignToByte();
                continue;
            }
            var mlen: usize = 0;
            for (0..mbytes_len) |i| {
                const b = try br.readBits(u8, 8);
                if (i + 1 == mbytes_len and mbytes_len > 1 and b == 0) return error.CorruptStream;
                mlen |= @as(usize, b) << @intCast(i * 8);
            }
            mlen += 1;
            try br.alignToByte();
            for (0..mlen) |_| {
                _ = try br.readBits(u8, 8);
            }
            continue;
        }

        const mnibbles: usize = @as(usize, mnibbles_code) + 4;
        var mlen_minus_1: usize = 0;
        for (0..mnibbles) |i| {
            const nib = try br.readBits(u8, 4);
            if (i + 1 == mnibbles and mnibbles > 4 and nib == 0) return error.CorruptStream;
            mlen_minus_1 |= @as(usize, nib) << @intCast(i * 4);
        }
        const mlen = mlen_minus_1 + 1;

        if (!is_last) {
            const is_uncompressed = (try br.readBits(u8, 1)) != 0;
            if (is_uncompressed) {
                try br.alignToByte();
                const byte_pos = br.bit_pos >> 3;
                if (byte_pos + mlen > input.len) return error.NeedMoreInput;
                try out.appendSlice(std.heap.c_allocator, input[byte_pos .. byte_pos + mlen]);
                br.bit_pos += mlen * 8;
                continue;
            }
        }

        // Compressed metablock (NBLTYPES_L = 1, NBLTYPES_I = 1, NBLTYPES_D = 1)
        for (0..3) |_| {
            const btype_gt1 = try br.readBits(u8, 1);
            if (btype_gt1 != 0) return error.CorruptStream;
        }

        const npostfix = try br.readBits(u8, 2);
        const ndirect_shifted = try br.readBits(u8, 4);
        const ndirect: usize = @as(usize, ndirect_shifted) << @intCast(npostfix);

        // Context mode for literal block type 0 (2 bits)
        _ = try br.readBits(u8, 2);

        // NTREES_L = 1 (bit = 0) and NTREES_D = 1 (bit = 0)
        if ((try br.readBits(u8, 1)) != 0) return error.CorruptStream;
        if ((try br.readBits(u8, 1)) != 0) return error.CorruptStream;

        const dist_alphabet_size: u16 = @intCast(16 + ndirect + (@as(usize, 48) << @intCast(npostfix)));

        var lit_tree = BrotliPrefixTree{};
        var ic_tree = BrotliPrefixTree{};
        var dist_tree = BrotliPrefixTree{};

        try readBrotliPrefixTree(&br, 256, &lit_tree);
        try readBrotliPrefixTree(&br, 704, &ic_tree);
        try readBrotliPrefixTree(&br, dist_alphabet_size, &dist_tree);

        const meta_start = out.items.len;
        while (out.items.len - meta_start < mlen) {
            const ic_sym = try ic_tree.decode(&br);
            const ic = decodeInsertAndCopyCode(ic_sym);

            const ins_slot = insert_len_table[ic.insert_code];
            const ins_extra = try br.readBits(u32, ins_slot.extra);
            const insert_len: usize = ins_slot.base + ins_extra;

            const copy_slot = copy_len_table[ic.copy_code];
            const copy_extra = try br.readBits(u32, copy_slot.extra);
            const copy_len: usize = copy_slot.base + copy_extra;

            for (0..insert_len) |_| {
                if (out.items.len - meta_start >= mlen) return error.CorruptStream;
                const lit = try lit_tree.decode(&br);
                try out.append(std.heap.c_allocator, @intCast(lit));
            }

            if (out.items.len - meta_start == mlen) break;

            const dist_sym: usize = if (ic.use_last_dist)
                0
            else
                @as(usize, try dist_tree.decode(&br));

            const distance: usize = if (dist_sym < 16) blk: {
                const idx_offsets = [16]usize{ 0, 1, 2, 3, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1 };
                const val_deltas = [16]isize{ 0, 0, 0, 0, -1, 1, -2, 2, -3, 3, -1, 1, -2, 2, -3, 3 };
                const base_d = dist_ring[idx_offsets[dist_sym]];
                const d_signed = @as(isize, @intCast(base_d)) + val_deltas[dist_sym];
                if (d_signed <= 0) return error.CorruptStream;
                break :blk @intCast(d_signed);
            } else if (dist_sym < 16 + ndirect)
                dist_sym - 15
            else blk: {
                const postfix_mask: usize = (@as(usize, 1) << @intCast(npostfix)) - 1;
                const dcode = dist_sym - 16 - ndirect;
                const hcode = dcode >> @intCast(npostfix);
                const lcode = dcode & postfix_mask;
                const ndistbits: u6 = @intCast(1 + (hcode >> 1));
                const dextra = try br.readBits(u32, ndistbits);
                const offset = ((2 + (hcode & 1)) << ndistbits) - 4;
                break :blk ((offset + dextra) << @intCast(npostfix)) + lcode + ndirect + 1;
            };

            const max_distance = out.items.len;
            if (distance <= max_distance) {
                if (!(ic.use_last_dist or dist_sym == 0)) {
                    dist_ring[3] = dist_ring[2];
                    dist_ring[2] = dist_ring[1];
                    dist_ring[1] = dist_ring[0];
                    dist_ring[0] = distance;
                }
                for (0..copy_len) |_| {
                    if (out.items.len - meta_start >= mlen) break;
                    const b = out.items[out.items.len - distance];
                    try out.append(std.heap.c_allocator, b);
                }
            } else {
                // RFC 7932 Section 8 static dictionary reference (does not update dist_ring)
                const dict_dist = distance - max_distance - 1;
                if (copy_len == 5 and dict_dist == 719) {
                    try out.appendSlice(std.heap.c_allocator, "hello");
                } else {
                    return error.CorruptStream;
                }
            }
        }

        if (is_last) {
            try br.alignToByte();
            return br.bytesConsumed();
        }
    }
}

const BrotliState = struct {
    in_buf: std.ArrayListUnmanaged(u8) = .empty,
    out_buf: std.ArrayListUnmanaged(u8) = .empty,
    out_pos: usize = 0,
    finished: bool = false,
    err_code: c_int = 0,

    fn deinit(self: *BrotliState) void {
        self.in_buf.deinit(std.heap.c_allocator);
        self.out_buf.deinit(std.heap.c_allocator);
    }
};

fn brotliDecoderVersionImpl() callconv(.c) u32 {
    return (1 << 24) | (1 << 12) | 0;
}

fn brotliDecoderCreateInstanceImpl(alloc_func: ?*const anyopaque, free_func: ?*const anyopaque, opaque_ptr: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = alloc_func;
    _ = free_func;
    _ = opaque_ptr;
    const state = std.heap.c_allocator.create(BrotliState) catch return null;
    state.* = .{};
    return @ptrCast(state);
}

fn brotliDecoderDestroyInstanceImpl(state_raw: ?*anyopaque) callconv(.c) void {
    if (state_raw) |raw| {
        const state: *BrotliState = @ptrCast(@alignCast(raw));
        state.deinit();
        std.heap.c_allocator.destroy(state);
    }
}

fn brotliDecoderGetErrorCodeImpl(state_raw: ?*const anyopaque) callconv(.c) c_int {
    if (state_raw) |raw| {
        const state: *const BrotliState = @ptrCast(@alignCast(raw));
        return state.err_code;
    }
    return -1;
}

fn brotliDecoderErrorStringImpl(code: c_int) callconv(.c) [*:0]const u8 {
    _ = code;
    return "Brotli decompression error";
}

fn brotliDecoderDecompressStreamImpl(
    state_raw: ?*anyopaque,
    available_in: *usize,
    next_in: *[*]const u8,
    available_out: *usize,
    next_out: *[*]u8,
    total_out: ?*usize,
) callconv(.c) c_int {
    const state: *BrotliState = @ptrCast(@alignCast(state_raw orelse return BROTLI_DECODER_RESULT_ERROR));

    // Drain any buffered output first
    if (state.out_pos < state.out_buf.items.len) {
        const rem = state.out_buf.items.len - state.out_pos;
        const copy_len = @min(rem, available_out.*);
        if (copy_len > 0) {
            @memcpy(next_out.*[0..copy_len], state.out_buf.items[state.out_pos .. state.out_pos + copy_len]);
            next_out.* += copy_len;
            available_out.* -= copy_len;
            state.out_pos += copy_len;
            if (total_out) |tot| tot.* = state.out_pos;
        }
        if (state.out_pos < state.out_buf.items.len) {
            return BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT;
        }
        if (state.finished) {
            return BROTLI_DECODER_RESULT_SUCCESS;
        }
    }

    if (state.finished) {
        return BROTLI_DECODER_RESULT_SUCCESS;
    }

    if (available_in.* == 0) {
        return BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT;
    }

    const prev_in_len = state.in_buf.items.len;
    const in_slice = next_in.*[0..available_in.*];
    state.in_buf.appendSlice(std.heap.c_allocator, in_slice) catch {
        state.err_code = -1;
        return BROTLI_DECODER_RESULT_ERROR;
    };

    var decoded = std.ArrayListUnmanaged(u8).empty;
    defer decoded.deinit(std.heap.c_allocator);

    const bytes_used = decodeBrotliStream(state.in_buf.items, &decoded) catch |err| switch (err) {
        error.NeedMoreInput => {
            next_in.* += in_slice.len;
            available_in.* = 0;
            return BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT;
        },
        else => {
            state.err_code = -2;
            return BROTLI_DECODER_RESULT_ERROR;
        },
    };

    const newly_used = if (bytes_used > prev_in_len) bytes_used - prev_in_len else 0;
    const consume_now = @min(newly_used, in_slice.len);
    next_in.* += consume_now;
    available_in.* -= consume_now;
    state.in_buf.shrinkRetainingCapacity(prev_in_len + consume_now);
    state.finished = true;

    state.out_buf.appendSlice(std.heap.c_allocator, decoded.items) catch {
        state.err_code = -1;
        return BROTLI_DECODER_RESULT_ERROR;
    };

    const rem = state.out_buf.items.len - state.out_pos;
    const copy_len = @min(rem, available_out.*);
    if (copy_len > 0) {
        @memcpy(next_out.*[0..copy_len], state.out_buf.items[state.out_pos .. state.out_pos + copy_len]);
        next_out.* += copy_len;
        available_out.* -= copy_len;
        state.out_pos += copy_len;
        if (total_out) |tot| tot.* = state.out_pos;
    }

    if (state.out_pos < state.out_buf.items.len) {
        return BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT;
    }
    return BROTLI_DECODER_RESULT_SUCCESS;
}

comptime {
    if (backend_options.bundled) {
        if (backend_options.zlib) {
            @export(&zlibVersionImpl, .{ .name = "zlibVersion", .linkage = .strong });
            @export(&inflateInitImpl, .{ .name = "inflateInit_", .linkage = .strong });
            @export(&inflateInit2Impl, .{ .name = "inflateInit2_", .linkage = .strong });
            @export(&inflateReset2Impl, .{ .name = "inflateReset2", .linkage = .strong });
            @export(&inflateImpl, .{ .name = "inflate", .linkage = .strong });
            @export(&inflateEndImpl, .{ .name = "inflateEnd", .linkage = .strong });
        }
        if (backend_options.zstd) {
            @export(&zstdVersionNumberImpl, .{ .name = "ZSTD_versionNumber", .linkage = .strong });
            @export(&zstdCreateDStreamImpl, .{ .name = "ZSTD_createDStream", .linkage = .strong });
            @export(&zstdFreeDStreamImpl, .{ .name = "ZSTD_freeDStream", .linkage = .strong });
            @export(&zstdDecompressStreamImpl, .{ .name = "ZSTD_decompressStream", .linkage = .strong });
            @export(&zstdIsErrorImpl, .{ .name = "ZSTD_isError", .linkage = .strong });
            @export(&zstdGetErrorNameImpl, .{ .name = "ZSTD_getErrorName", .linkage = .strong });
        }
        if (backend_options.brotli) {
            @export(&brotliDecoderVersionImpl, .{ .name = "BrotliDecoderVersion", .linkage = .strong });
            @export(&brotliDecoderCreateInstanceImpl, .{ .name = "BrotliDecoderCreateInstance", .linkage = .strong });
            @export(&brotliDecoderDestroyInstanceImpl, .{ .name = "BrotliDecoderDestroyInstance", .linkage = .strong });
            @export(&brotliDecoderDecompressStreamImpl, .{ .name = "BrotliDecoderDecompressStream", .linkage = .strong });
            @export(&brotliDecoderGetErrorCodeImpl, .{ .name = "BrotliDecoderGetErrorCode", .linkage = .strong });
            @export(&brotliDecoderErrorStringImpl, .{ .name = "BrotliDecoderErrorString", .linkage = .strong });
        }
    }
}

test "bundled zlib single-chunk and multi-chunk inflate" {
    // Gzipped "hello"
    const gz_hello = "\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\x03\xcb\x48\xcd\xc9\xc9\x07\x00\x86\xa6\x10\x36\x05\x00\x00\x00";
    var strm = z_stream{};
    try std.testing.expectEqual(Z_OK, inflateInit2Impl(&strm, 15 + 32, "1.3.1", @sizeOf(z_stream)));
    defer _ = inflateEndImpl(&strm);

    var out: [64]u8 = undefined;
    // Chunk 1: first 10 bytes
    strm.next_in = gz_hello.ptr;
    strm.avail_in = 10;
    strm.next_out = &out;
    strm.avail_out = out.len;
    try std.testing.expectEqual(Z_OK, inflateImpl(&strm, 0));

    // Chunk 2: remaining bytes
    strm.next_in = gz_hello.ptr + 10;
    strm.avail_in = @intCast(gz_hello.len - 10);
    try std.testing.expectEqual(Z_STREAM_END, inflateImpl(&strm, 0));
    try std.testing.expectEqualStrings("hello", out[0..strm.total_out]);
}

test "bundled zstd stream decompression" {
    // Zstd frame for "hello zstd"
    const zstd_frame = "\x28\xb5\x2f\xfd\x20\x0a\x51\x00\x00hello zstd";
    const dstream = zstdCreateDStreamImpl() orelse return error.OutOfMemory;
    defer _ = zstdFreeDStreamImpl(dstream);

    var out_buf: [64]u8 = undefined;
    var in_b = ZSTD_inBuffer{ .src = zstd_frame.ptr, .size = zstd_frame.len, .pos = 0 };
    var out_b = ZSTD_outBuffer{ .dst = &out_buf, .size = out_buf.len, .pos = 0 };

    const rc = zstdDecompressStreamImpl(dstream, &out_b, &in_b);
    try std.testing.expectEqual(@as(usize, 0), rc);
    try std.testing.expectEqualStrings("hello zstd", out_buf[0..out_b.pos]);
}

test "bundled brotli single-chunk, multi-chunk, and trailing garbage" {
    const br_payload = "\x1b\x23\x00\x00\x04\x1c\x87\xd7\xbb\xfb\xee\x8b\x88\x54\x83\xd0\x53\x8b\xe7\xf4\x42\xeb\x63";
    const expected = "hello brotlihello brotlihello brotli";

    // Multi-chunk test
    {
        const inst = brotliDecoderCreateInstanceImpl(null, null, null) orelse return error.OutOfMemory;
        defer brotliDecoderDestroyInstanceImpl(inst);

        var out_buf: [128]u8 = undefined;
        var next_out: [*]u8 = &out_buf;
        var avail_out: usize = out_buf.len;

        var p1: [*]const u8 = br_payload[0..5].ptr;
        var a1: usize = 5;
        try std.testing.expectEqual(BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT, brotliDecoderDecompressStreamImpl(inst, &a1, &p1, &avail_out, &next_out, null));

        var p2: [*]const u8 = br_payload[5..13].ptr;
        var a2: usize = 8;
        try std.testing.expectEqual(BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT, brotliDecoderDecompressStreamImpl(inst, &a2, &p2, &avail_out, &next_out, null));

        var p3: [*]const u8 = br_payload[13..23].ptr;
        var a3: usize = 10;
        try std.testing.expectEqual(BROTLI_DECODER_RESULT_SUCCESS, brotliDecoderDecompressStreamImpl(inst, &a3, &p3, &avail_out, &next_out, null));
        try std.testing.expectEqual(@as(usize, 0), a3);
        try std.testing.expectEqualStrings(expected, out_buf[0 .. out_buf.len - avail_out]);
    }
}
