const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const curlx_parse = @import("curlx_parse.zig");
const containers = @import("containers.zig");
const os_leaf = @import("os_leaf.zig");

pub const CURLcode = curlx_parse.CURLcode;
pub const CURLE_OK = curlx_parse.CURLE_OK;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY = curlx_parse.CURLE_OUT_OF_MEMORY;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT = curlx_parse.CURLE_BAD_FUNCTION_ARGUMENT;
pub const CURLE_TOO_LARGE = curlx_parse.CURLE_TOO_LARGE;

pub const dynbuf = containers.dynbuf;
pub const bufref = containers.bufref;
pub const curl_slist = containers.curl_slist;
pub const CVaListParam = containers.CVaListParam;

extern fn curlx_dyn_init(s: *dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const dynbuf) callconv(.c) usize;

extern fn Curl_bufref_init(br: *bufref) callconv(.c) void;
extern fn Curl_bufref_free(br: *bufref) callconv(.c) void;
extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?containers.BufrefDtor) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8;
extern fn Curl_bufref_memdup0(br: *bufref, ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;

extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?*anyopaque;

// ============================================================================
// Cross-platform C va_list reader
// ============================================================================

const VaReader = switch (builtin.cpu.arch) {
    .x86_64 => if (builtin.os.tag == .windows) struct {
        ap: [*]u8,

        pub fn init(param: CVaListParam) @This() {
            return .{ .ap = param };
        }

        pub fn nextGp(self: *@This(), comptime T: type) T {
            const addr = @intFromPtr(self.ap);
            self.ap += 8;
            return @as(*align(1) const T, @ptrFromInt(addr)).*;
        }

        pub fn nextDouble(self: *@This()) f64 {
            const addr = @intFromPtr(self.ap);
            self.ap += 8;
            return @as(*align(1) const f64, @ptrFromInt(addr)).*;
        }

        pub fn nextLongDouble(self: *@This()) f64 {
            if (@sizeOf(c_longdouble) > 8) {
                const ptr = self.nextGp(*align(1) const c_longdouble);
                return @floatCast(ptr.*);
            } else {
                return self.nextDouble();
            }
        }
    } else struct {
        ap: *std.builtin.VaListX86_64,

        pub fn init(param: CVaListParam) @This() {
            return .{ .ap = param };
        }

        pub fn nextGp(self: *@This(), comptime T: type) T {
            const addr: usize = if (self.ap.gp_offset <= 40) blk: {
                const p = @intFromPtr(self.ap.reg_save_area) + self.ap.gp_offset;
                self.ap.gp_offset += 8;
                break :blk p;
            } else blk: {
                const p = @intFromPtr(self.ap.overflow_arg_area);
                self.ap.overflow_arg_area = @ptrFromInt(p + 8);
                break :blk p;
            };
            return @as(*align(1) const T, @ptrFromInt(addr)).*;
        }

        pub fn nextDouble(self: *@This()) f64 {
            const addr: usize = if (self.ap.fp_offset <= 160) blk: {
                const p = @intFromPtr(self.ap.reg_save_area) + self.ap.fp_offset;
                self.ap.fp_offset += 16;
                break :blk p;
            } else blk: {
                const p = @intFromPtr(self.ap.overflow_arg_area);
                self.ap.overflow_arg_area = @ptrFromInt(p + 8);
                break :blk p;
            };
            return @as(*align(1) const f64, @ptrFromInt(addr)).*;
        }

        pub fn nextLongDouble(self: *@This()) f64 {
            const aligned = std.mem.alignForward(usize, @intFromPtr(self.ap.overflow_arg_area), 16);
            self.ap.overflow_arg_area = @ptrFromInt(aligned + 16);
            const val = @as(*align(16) const c_longdouble, @ptrFromInt(aligned)).*;
            return @floatCast(val);
        }
    },
    .aarch64, .aarch64_be => switch (builtin.os.tag) {
        .macos, .ios, .tvos, .watchos, .visionos, .driverkit, .maccatalyst, .windows => struct {
            ap: [*]u8,

            pub fn init(param: CVaListParam) @This() {
                return .{ .ap = param };
            }

            pub fn nextGp(self: *@This(), comptime T: type) T {
                const addr = @intFromPtr(self.ap);
                self.ap += 8;
                return @as(*align(1) const T, @ptrFromInt(addr)).*;
            }

            pub fn nextDouble(self: *@This()) f64 {
                const addr = @intFromPtr(self.ap);
                self.ap += 8;
                return @as(*align(1) const f64, @ptrFromInt(addr)).*;
            }

            pub fn nextLongDouble(self: *@This()) f64 {
                return self.nextDouble();
            }
        },
        else => struct {
            ap: std.builtin.VaListAarch64,

            pub fn init(param: CVaListParam) @This() {
                return .{ .ap = param };
            }

            pub fn nextGp(self: *@This(), comptime T: type) T {
                const offs = self.ap.__gr_offs;
                if (offs < 0) {
                    self.ap.__gr_offs = offs + 8;
                    if (offs >= -64) {
                        const addr = @intFromPtr(self.ap.__gr_top) - @as(usize, @intCast(-offs));
                        return @as(*align(1) const T, @ptrFromInt(addr)).*;
                    }
                }
                const addr = @intFromPtr(self.ap.__stack);
                self.ap.__stack = @ptrFromInt(addr + 8);
                return @as(*align(1) const T, @ptrFromInt(addr)).*;
            }

            pub fn nextDouble(self: *@This()) f64 {
                const offs = self.ap.__vr_offs;
                if (offs < 0) {
                    self.ap.__vr_offs = offs + 16;
                    if (offs >= -128) {
                        const addr = @intFromPtr(self.ap.__vr_top) - @as(usize, @intCast(-offs));
                        return @as(*align(1) const f64, @ptrFromInt(addr)).*;
                    }
                }
                const addr = @intFromPtr(self.ap.__stack);
                self.ap.__stack = @ptrFromInt(addr + 8);
                return @as(*align(1) const f64, @ptrFromInt(addr)).*;
            }

            pub fn nextLongDouble(self: *@This()) f64 {
                const offs = self.ap.__vr_offs;
                if (offs < 0) {
                    self.ap.__vr_offs = offs + 16;
                    if (offs >= -128) {
                        const addr = @intFromPtr(self.ap.__vr_top) - @as(usize, @intCast(-offs));
                        const val = @as(*align(1) const c_longdouble, @ptrFromInt(addr)).*;
                        return @floatCast(val);
                    }
                }
                const aligned = std.mem.alignForward(usize, @intFromPtr(self.ap.__stack), 16);
                self.ap.__stack = @ptrFromInt(aligned + 16);
                const val = @as(*align(16) const c_longdouble, @ptrFromInt(aligned)).*;
                return @floatCast(val);
            }
        },
    },
    else => @compileError("Unsupported architecture for VaReader"),
};

// ============================================================================
// Standard I/O helpers across Linux, macOS, and Windows
// ============================================================================

const stdio_c = struct {
    extern "c" fn fputc(c: c_int, stream: ?*anyopaque) c_int;
    extern "c" fn fwrite(ptr: [*]const u8, size: usize, nmemb: usize, stream: ?*anyopaque) usize;
    extern "c" fn fread(ptr: [*]u8, size: usize, nmemb: usize, stream: ?*anyopaque) callconv(.c) usize;
    extern "c" fn snprintf(buf: [*]u8, size: usize, format: [*:0]const u8, ...) c_int;
    extern "c" fn vsnprintf(buf: [*]u8, size: usize, format: [*:0]const u8, ap: [*]u8) c_int;
};

const stdio_streams = if (builtin.os.tag == .windows) struct {
    extern "c" fn __acrt_iob_func(ix: c_uint) callconv(.c) ?*anyopaque;
    pub fn getStdin() ?*anyopaque {
        return __acrt_iob_func(0);
    }
    pub fn getStdout() ?*anyopaque {
        return __acrt_iob_func(1);
    }
} else if (builtin.os.tag.isDarwin()) struct {
    extern "c" var __stdinp: ?*anyopaque;
    extern "c" var __stdoutp: ?*anyopaque;
    pub fn getStdin() ?*anyopaque {
        return __stdinp;
    }
    pub fn getStdout() ?*anyopaque {
        return __stdoutp;
    }
} else struct {
    extern "c" var stdin: ?*anyopaque;
    extern "c" var stdout: ?*anyopaque;
    pub fn getStdin() ?*anyopaque {
        return stdin;
    }
    pub fn getStdout() ?*anyopaque {
        return stdout;
    }
};

// ============================================================================
// 1. lib/mprintf.c (include/curl/mprintf.h, lib/curl_printf.h)
// ============================================================================

const BUFFSIZE: usize = 326;
const MAX_PARAMETERS: usize = 128;
const MAX_SEGMENTS: usize = 128;
const ASPRINTF_STAGE_SIZE: usize = 512;
const DYN_APRINTF: usize = 8000000;

pub const MERR_OK: c_int = 0;
pub const MERR_MEM: c_int = 1;
pub const MERR_TOO_LARGE: c_int = 2;

export const Curl_ldigits: [17]u8 = "0123456789abcdef\x00".*;
export const Curl_udigits: [17]u8 = "0123456789ABCDEF\x00".*;

const FormatType = enum(c_uint) {
    MTYPE_STRING,
    MTYPE_PTR,
    MTYPE_INTPTR,
    MTYPE_INT,
    MTYPE_LONG,
    MTYPE_LONGLONG,
    MTYPE_INTU,
    MTYPE_LONGU,
    MTYPE_LONGLONGU,
    MTYPE_DOUBLE,
    MTYPE_LONGDOUBLE,
    MTYPE_WIDTH,
    MTYPE_PRECISION,
};

const FLAGS_SPACE: c_uint = 1 << 0;
const FLAGS_SHOWSIGN: c_uint = 1 << 1;
const FLAGS_LEFT: c_uint = 1 << 2;
const FLAGS_ALT: c_uint = 1 << 3;
const FLAGS_SHORT: c_uint = 1 << 4;
const FLAGS_LONG: c_uint = 1 << 5;
const FLAGS_LONGLONG: c_uint = 1 << 6;
const FLAGS_LONGDOUBLE: c_uint = 1 << 7;
const FLAGS_PAD_NIL: c_uint = 1 << 8;
const FLAGS_UNSIGNED: c_uint = 1 << 9;
const FLAGS_OCTAL: c_uint = 1 << 10;
const FLAGS_HEX: c_uint = 1 << 11;
const FLAGS_UPPER: c_uint = 1 << 12;
const FLAGS_WIDTH: c_uint = 1 << 13;
const FLAGS_WIDTHPARAM: c_uint = 1 << 14;
const FLAGS_PREC: c_uint = 1 << 15;
const FLAGS_PRECPARAM: c_uint = 1 << 16;
const FLAGS_CHAR: c_uint = 1 << 17;
const FLAGS_FLOATE: c_uint = 1 << 18;
const FLAGS_FLOATG: c_uint = 1 << 19;
const FLAGS_SUBSTR: c_uint = 1 << 20;

const DOLLAR_UNKNOWN: c_int = 0;
const DOLLAR_NOPE: c_int = 1;
const DOLLAR_USE: c_int = 2;

const PFMT_OK: c_int = 0;
const PFMT_DOLLAR: c_int = 1;
const PFMT_DOLLARWIDTH: c_int = 2;
const PFMT_DOLLARPREC: c_int = 3;
const PFMT_MANYARGS: c_int = 4;
const PFMT_PREC: c_int = 5;
const PFMT_PRECMIX: c_int = 6;
const PFMT_WIDTH: c_int = 7;
const PFMT_INPUTGAP: c_int = 8;
const PFMT_WIDTHARG: c_int = 9;
const PFMT_PRECARG: c_int = 10;
const PFMT_MANYSEGS: c_int = 11;

const VaInputVal = extern union {
    str: ?[*]const u8,
    ptr: ?*anyopaque,
    nums: i64,
    numu: u64,
    dnum: f64,
};

const VaInput = struct {
    type: FormatType,
    val: VaInputVal,
};

const OutSegment = struct {
    width: c_int,
    precision: c_int,
    flags: c_uint,
    input: c_uint,
    start: [*:0]const u8,
    outlen: usize,
};

const Nsprintf = struct {
    buffer: ?[*]u8,
    length: usize,
    max: usize,
};

const Asprintf = struct {
    b: *dynbuf,
    merr: c_int,
    nstage: usize,
    stage: [ASPRINTF_STAGE_SIZE]u8,
};

const Ioprintf = struct {
    fd: ?*anyopaque,
    err: bool,
};

const MProperty = struct {
    width: c_int,
    prec: c_int,
    flags: c_uint,
};

const MpStream = *const fn (u8, *anyopaque) c_int;
const MpStreamN = *const fn ([*]const u8, usize, *anyopaque) usize;
const MpFlush = *const fn (*anyopaque) c_int;

fn dollarstring(p_in: [*:0]const u8, end: *[*:0]const u8) c_int {
    var p = p_in;
    var num: i64 = 0;
    if (curlx_str_number(&p, &num, @as(i64, MAX_PARAMETERS)) != 0 or
        curlx_str_single(&p, '$') != 0 or num == 0)
    {
        return -1;
    }
    end.* = p;
    return @as(c_int, @intCast(num)) - 1;
}

inline fn isArgUsed(used: *const [MAX_PARAMETERS / 8]u8, idx: usize) bool {
    return (used[idx / 8] & (@as(u8, 1) << @intCast(idx & 7))) != 0;
}

inline fn markArgUsed(used: *[MAX_PARAMETERS / 8]u8, idx: usize) void {
    used[idx / 8] |= (@as(u8, 1) << @intCast(idx & 7));
}

fn parseFlags(
    fmtp: *[*:0]const u8,
    flagsp: *c_uint,
    use_dollar: c_int,
    precp: *c_int,
    widthp: *c_int,
) c_int {
    var fmt = fmtp.*;
    var loopit = true;
    var flags: c_uint = 0;
    var width: c_int = 0;
    var precision: c_int = 0;

    while (loopit) {
        const ch = fmt[0];
        fmt += 1;
        switch (ch) {
            ' ' => {
                flags |= FLAGS_SPACE;
            },
            '+' => {
                flags |= FLAGS_SHOWSIGN;
            },
            '-' => {
                flags |= FLAGS_LEFT;
                flags &= ~FLAGS_PAD_NIL;
            },
            '#' => {
                flags |= FLAGS_ALT;
            },
            '.' => {
                if (fmt[0] == '*') {
                    flags |= FLAGS_PRECPARAM;
                    fmt += 1;
                    if (use_dollar == DOLLAR_USE) {
                        precision = dollarstring(fmt, &fmt);
                        if (precision < 0) return PFMT_DOLLARPREC;
                    } else {
                        precision = -1;
                    }
                } else {
                    flags |= FLAGS_PREC;
                    const is_neg = (fmt[0] == '-');
                    if (is_neg) fmt += 1;
                    var num: i64 = 0;
                    if (curlx_str_number(&fmt, &num, std.math.maxInt(c_int)) != 0) {
                        return PFMT_PREC;
                    }
                    precision = @intCast(num);
                    if (is_neg) precision = -precision;
                }
                if ((flags & (FLAGS_PREC | FLAGS_PRECPARAM)) == (FLAGS_PREC | FLAGS_PRECPARAM)) {
                    return PFMT_PRECMIX;
                }
            },
            'h' => {
                flags |= FLAGS_SHORT;
            },
            'I' => {
                if (builtin.os.tag == .windows) {
                    if (fmt[0] == '3' and fmt[1] == '2') {
                        flags |= FLAGS_LONG;
                        fmt += 2;
                    } else if (fmt[0] == '6' and fmt[1] == '4') {
                        flags |= FLAGS_LONGLONG;
                        fmt += 2;
                    } else {
                        if (@sizeOf(usize) > @sizeOf(c_long)) {
                            flags |= FLAGS_LONGLONG;
                        } else {
                            flags |= FLAGS_LONG;
                        }
                    }
                } else {
                    loopit = false;
                    fmt -= 1;
                }
            },
            'l' => {
                if ((flags & FLAGS_LONG) != 0) {
                    flags |= FLAGS_LONGLONG;
                } else {
                    flags |= FLAGS_LONG;
                }
            },
            'L' => {
                flags |= FLAGS_LONGDOUBLE;
            },
            'q' => {
                flags |= FLAGS_LONGLONG;
            },
            'z' => {
                if (@sizeOf(usize) > @sizeOf(c_long)) {
                    flags |= FLAGS_LONGLONG;
                } else {
                    flags |= FLAGS_LONG;
                }
            },
            'O' => {
                if (@sizeOf(i64) > @sizeOf(c_long)) {
                    flags |= FLAGS_LONGLONG;
                } else {
                    flags |= FLAGS_LONG;
                }
            },
            '0' => {
                if ((flags & FLAGS_LEFT) == 0) {
                    flags |= FLAGS_PAD_NIL;
                }
                var num: i64 = 0;
                flags |= FLAGS_WIDTH;
                fmt -= 1;
                if (curlx_str_number(&fmt, &num, std.math.maxInt(c_int)) != 0) {
                    return PFMT_WIDTH;
                }
                width = @intCast(num);
            },
            '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                var num: i64 = 0;
                flags |= FLAGS_WIDTH;
                fmt -= 1;
                if (curlx_str_number(&fmt, &num, std.math.maxInt(c_int)) != 0) {
                    return PFMT_WIDTH;
                }
                width = @intCast(num);
            },
            '*' => {
                flags |= FLAGS_WIDTHPARAM;
                if (use_dollar == DOLLAR_USE) {
                    width = dollarstring(fmt, &fmt);
                    if (width < 0) return PFMT_DOLLARWIDTH;
                } else {
                    width = -1;
                }
            },
            else => {
                loopit = false;
                fmt -= 1;
            },
        }
    }

    flagsp.* = flags;
    precp.* = precision;
    widthp.* = width;
    fmtp.* = fmt;
    return PFMT_OK;
}

fn parseConversion(f: u8, flagp: *c_uint, typep: *FormatType) bool {
    var flags = flagp.*;
    var ftype: FormatType = undefined;
    switch (f) {
        'S' => {
            flags |= FLAGS_ALT;
            ftype = .MTYPE_STRING;
        },
        's' => {
            ftype = .MTYPE_STRING;
        },
        'n' => {
            ftype = .MTYPE_INTPTR;
        },
        'p' => {
            ftype = .MTYPE_PTR;
        },
        'd', 'i' => {
            if ((flags & FLAGS_LONGLONG) != 0) {
                ftype = .MTYPE_LONGLONG;
            } else if ((flags & FLAGS_LONG) != 0) {
                ftype = .MTYPE_LONG;
            } else {
                ftype = .MTYPE_INT;
            }
        },
        'u' => {
            if ((flags & FLAGS_LONGLONG) != 0) {
                ftype = .MTYPE_LONGLONGU;
            } else if ((flags & FLAGS_LONG) != 0) {
                ftype = .MTYPE_LONGU;
            } else {
                ftype = .MTYPE_INTU;
            }
            flags |= FLAGS_UNSIGNED;
        },
        'o' => {
            if ((flags & FLAGS_LONGLONG) != 0) {
                ftype = .MTYPE_LONGLONGU;
            } else if ((flags & FLAGS_LONG) != 0) {
                ftype = .MTYPE_LONGU;
            } else {
                ftype = .MTYPE_INTU;
            }
            flags |= FLAGS_OCTAL | FLAGS_UNSIGNED;
        },
        'x' => {
            if ((flags & FLAGS_LONGLONG) != 0) {
                ftype = .MTYPE_LONGLONGU;
            } else if ((flags & FLAGS_LONG) != 0) {
                ftype = .MTYPE_LONGU;
            } else {
                ftype = .MTYPE_INTU;
            }
            flags |= FLAGS_HEX | FLAGS_UNSIGNED;
        },
        'X' => {
            if ((flags & FLAGS_LONGLONG) != 0) {
                ftype = .MTYPE_LONGLONGU;
            } else if ((flags & FLAGS_LONG) != 0) {
                ftype = .MTYPE_LONGU;
            } else {
                ftype = .MTYPE_INTU;
            }
            flags |= FLAGS_HEX | FLAGS_UPPER | FLAGS_UNSIGNED;
        },
        'c' => {
            ftype = .MTYPE_INT;
            flags |= FLAGS_CHAR;
        },
        'f' => {
            ftype = if ((flags & FLAGS_LONGDOUBLE) != 0) .MTYPE_LONGDOUBLE else .MTYPE_DOUBLE;
        },
        'F' => {
            ftype = if ((flags & FLAGS_LONGDOUBLE) != 0) .MTYPE_LONGDOUBLE else .MTYPE_DOUBLE;
            flags |= FLAGS_UPPER;
        },
        'e' => {
            ftype = if ((flags & FLAGS_LONGDOUBLE) != 0) .MTYPE_LONGDOUBLE else .MTYPE_DOUBLE;
            flags |= FLAGS_FLOATE;
        },
        'E' => {
            ftype = if ((flags & FLAGS_LONGDOUBLE) != 0) .MTYPE_LONGDOUBLE else .MTYPE_DOUBLE;
            flags |= FLAGS_FLOATE | FLAGS_UPPER;
        },
        'g' => {
            ftype = if ((flags & FLAGS_LONGDOUBLE) != 0) .MTYPE_LONGDOUBLE else .MTYPE_DOUBLE;
            flags |= FLAGS_FLOATG;
        },
        'G' => {
            ftype = if ((flags & FLAGS_LONGDOUBLE) != 0) .MTYPE_LONGDOUBLE else .MTYPE_DOUBLE;
            flags |= FLAGS_FLOATG | FLAGS_UPPER;
        },
        else => return true,
    }
    flagp.* |= flags;
    typep.* = ftype;
    return false;
}

fn parsefmt(
    format: [*:0]const u8,
    out: *[MAX_SEGMENTS]OutSegment,
    in: *[MAX_PARAMETERS]VaInput,
    opieces: *c_int,
    ipieces: *c_int,
    arglist: CVaListParam,
) c_int {
    var fmt = format;
    var param_num: c_int = 0;
    var max_param: c_int = -1;
    var ocount: usize = 0;
    var usedinput: [MAX_PARAMETERS / 8]u8 = @splat(0);
    var outlen: usize = 0;
    var use_dollar: c_int = DOLLAR_UNKNOWN;
    var start = fmt;

    while (fmt[0] != 0) {
        if (fmt[0] == '%') {
            var ftype: FormatType = undefined;
            var flags: c_uint = 0;
            var width: c_int = 0;
            var precision: c_int = 0;
            var param: c_int = -1;

            fmt += 1;
            outlen = (@intFromPtr(fmt) - @intFromPtr(start)) - 1;
            if (fmt[0] == '%') {
                if (outlen != 0) {
                    if (ocount >= MAX_SEGMENTS) return PFMT_MANYSEGS;
                    out[ocount] = .{
                        .width = 0,
                        .precision = 0,
                        .flags = FLAGS_SUBSTR,
                        .input = 0,
                        .start = start,
                        .outlen = outlen,
                    };
                    ocount += 1;
                }
                start = fmt;
                fmt += 1;
                continue;
            }

            if (use_dollar != DOLLAR_NOPE) {
                param = dollarstring(fmt, &fmt);
                if (param < 0) {
                    if (use_dollar == DOLLAR_USE) return PFMT_DOLLAR;
                    param = -1;
                    use_dollar = DOLLAR_NOPE;
                } else {
                    use_dollar = DOLLAR_USE;
                }
            }

            const rc = parseFlags(&fmt, &flags, use_dollar, &precision, &width);
            if (rc != PFMT_OK) return rc;

            if (parseConversion(fmt[0], &flags, &ftype)) {
                continue;
            }

            if ((flags & FLAGS_WIDTHPARAM) != 0) {
                if (width < 0) {
                    width = param_num;
                    param_num += 1;
                } else {
                    if (isArgUsed(&usedinput, @intCast(width))) return PFMT_WIDTHARG;
                }
                if (width >= MAX_PARAMETERS) return PFMT_MANYARGS;
                if (width >= max_param) max_param = width;

                const w_idx: usize = @intCast(width);
                in[w_idx].type = .MTYPE_WIDTH;
                markArgUsed(&usedinput, w_idx);
            }

            if ((flags & FLAGS_PRECPARAM) != 0) {
                if (precision < 0) {
                    precision = param_num;
                    param_num += 1;
                } else {
                    if (isArgUsed(&usedinput, @intCast(precision))) return PFMT_PRECARG;
                }
                if (precision >= MAX_PARAMETERS) return PFMT_MANYARGS;
                if (precision >= max_param) max_param = precision;

                const p_idx: usize = @intCast(precision);
                in[p_idx].type = .MTYPE_PRECISION;
                markArgUsed(&usedinput, p_idx);
            }

            if (param < 0) {
                param = param_num;
                param_num += 1;
            }
            if (param >= MAX_PARAMETERS) return PFMT_MANYARGS;
            if (param >= max_param) max_param = param;

            const param_idx: usize = @intCast(param);
            in[param_idx].type = ftype;
            markArgUsed(&usedinput, param_idx);

            fmt += 1;
            if (ocount >= MAX_SEGMENTS) return PFMT_MANYSEGS;
            out[ocount] = .{
                .width = width,
                .precision = precision,
                .flags = flags,
                .input = @intCast(param),
                .start = start,
                .outlen = outlen,
            };
            ocount += 1;
            start = fmt;
        } else {
            fmt += 1;
        }
    }

    outlen = @intFromPtr(fmt) - @intFromPtr(start);
    if (outlen != 0) {
        if (ocount >= MAX_SEGMENTS) return PFMT_MANYSEGS;
        out[ocount] = .{
            .width = 0,
            .precision = 0,
            .flags = FLAGS_SUBSTR,
            .input = 0,
            .start = start,
            .outlen = outlen,
        };
        ocount += 1;
    }

    var va = VaReader.init(arglist);
    const total_params: usize = @intCast(max_param + 1);
    for (0..total_params) |i| {
        if (!isArgUsed(&usedinput, i)) return PFMT_INPUTGAP;
        const iptr = &in[i];
        switch (iptr.type) {
            .MTYPE_STRING => {
                iptr.val = .{ .str = va.nextGp(?[*]const u8) };
            },
            .MTYPE_INTPTR, .MTYPE_PTR => {
                iptr.val = .{ .ptr = va.nextGp(?*anyopaque) };
            },
            .MTYPE_LONGLONGU => {
                iptr.val = .{ .numu = va.nextGp(u64) };
            },
            .MTYPE_LONGLONG => {
                iptr.val = .{ .nums = va.nextGp(i64) };
            },
            .MTYPE_LONGU => {
                iptr.val = .{ .numu = @intCast(va.nextGp(c_ulong)) };
            },
            .MTYPE_LONG => {
                iptr.val = .{ .nums = @intCast(va.nextGp(c_long)) };
            },
            .MTYPE_INTU => {
                iptr.val = .{ .numu = @intCast(va.nextGp(c_uint)) };
            },
            .MTYPE_INT, .MTYPE_WIDTH, .MTYPE_PRECISION => {
                iptr.val = .{ .nums = @intCast(va.nextGp(c_int)) };
            },
            .MTYPE_DOUBLE => {
                iptr.val = .{ .dnum = va.nextDouble() };
            },
            .MTYPE_LONGDOUBLE => {
                iptr.val = .{ .dnum = va.nextLongDouble() };
            },
        }
    }

    ipieces.* = max_param + 1;
    opieces.* = @intCast(ocount);
    return PFMT_OK;
}

fn streamRun(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    buf: [*]const u8,
    len: usize,
    donep: *c_int,
) bool {
    if (len == 0) return false;
    if (streamn) |sn| {
        const n = sn(buf, len, userp);
        donep.* += @intCast(n);
        return n != len;
    }
    for (0..len) |i| {
        if (stream(buf[i], userp) != 0) return true;
        donep.* += 1;
    }
    return false;
}

const pad_spaces: [16:0]u8 = "                ".*;
const pad_zeros: [16:0]u8 = "0000000000000000".*;
const PAD_RUN: c_int = 16;

fn streamPad(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    pad: u8,
    num_in: c_int,
    donep: *c_int,
) bool {
    var num = num_in;
    if (num <= 0) return false;
    const src: [*]const u8 = if (pad == '0') &pad_zeros else &pad_spaces;
    while (num > PAD_RUN) {
        if (streamRun(userp, stream, streamn, src, @intCast(PAD_RUN), donep)) return true;
        num -= PAD_RUN;
    }
    return streamRun(userp, stream, streamn, src, @intCast(num), donep);
}

fn streamZrun(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    str: [*]const u8,
    len: usize,
    donep: *c_int,
) bool {
    var n: usize = 0;
    while (n < len and str[n] != 0) : (n += 1) {}
    return streamRun(userp, stream, streamn, str, n, donep);
}

inline fn outChar(
    ch: u8,
    userp: *anyopaque,
    stream: MpStream,
    donep: *c_int,
) bool {
    if (stream(ch, userp) != 0) return true;
    donep.* += 1;
    return false;
}

fn outDouble(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    p: *MProperty,
    dnum: f64,
    work: *[BUFFSIZE + 2]u8,
    donep: *c_int,
) bool {
    var fmt: [32]u8 = @splat(0);
    fmt[0] = '%';
    var fidx: usize = 1;
    const flags = p.flags;
    var width = p.width;
    var prec = p.prec;

    if ((flags & FLAGS_LEFT) != 0) {
        fmt[fidx] = '-';
        fidx += 1;
    }
    if ((flags & FLAGS_SHOWSIGN) != 0) {
        fmt[fidx] = '+';
        fidx += 1;
    }
    if ((flags & FLAGS_SPACE) != 0) {
        fmt[fidx] = ' ';
        fidx += 1;
    }
    if ((flags & FLAGS_ALT) != 0) {
        fmt[fidx] = '#';
        fidx += 1;
    }
    fmt[fidx] = 0;

    if (width >= 0) {
        if (width >= @as(c_int, @intCast(BUFFSIZE))) {
            width = @as(c_int, @intCast(BUFFSIZE - 1));
        }
        const written = std.fmt.bufPrint(fmt[fidx .. fmt.len - 1], "{d}", .{width}) catch "";
        fidx += written.len;
    }
    if (prec >= 0) {
        var maxprec: c_int = @intCast(BUFFSIZE - 1);
        var val: f64 = dnum;
        if (prec > maxprec) prec = maxprec - 1;
        if (width > 0 and prec <= width) maxprec -= width;
        while (maxprec > 0 and val >= 10.0) {
            val /= 10.0;
            maxprec -= 1;
        }
        if (prec > maxprec) prec = maxprec - 1;
        if (prec < 0) prec = 0;
        const written = std.fmt.bufPrint(fmt[fidx .. fmt.len - 1], ".{d}", .{prec}) catch "";
        fidx += written.len;
    }
    if ((flags & FLAGS_LONG) != 0) {
        fmt[fidx] = 'l';
        fidx += 1;
    }

    if ((flags & FLAGS_FLOATE) != 0) {
        fmt[fidx] = if ((flags & FLAGS_UPPER) != 0) 'E' else 'e';
    } else if ((flags & FLAGS_FLOATG) != 0) {
        fmt[fidx] = if ((flags & FLAGS_UPPER) != 0) 'G' else 'g';
    } else {
        fmt[fidx] = if ((flags & FLAGS_UPPER) != 0) 'F' else 'f';
    }
    fidx += 1;
    fmt[fidx] = 0;

    const fmt_z: [*:0]const u8 = @ptrCast(&fmt);
    if (builtin.os.tag == .windows) {
        var dnum_bits: u64 = @bitCast(dnum);
        _ = stdio_c.vsnprintf(work, BUFFSIZE, fmt_z, @ptrCast(&dnum_bits));
        work[BUFFSIZE - 1] = 0;
    } else {
        _ = stdio_c.snprintf(work, BUFFSIZE, fmt_z, dnum);
    }
    const work_z: [*:0]const u8 = @ptrCast(work);
    return streamRun(userp, stream, streamn, work, std.mem.len(work_z), donep);
}

fn outNumber(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    p: *MProperty,
    num_in: u64,
    nums: i64,
    work: *[BUFFSIZE + 2]u8,
    donep: *c_int,
) bool {
    var digits: [*]const u8 = &Curl_ldigits;
    const flags = p.flags;
    var width = p.width;
    var prec = p.prec;
    const is_alt = (flags & FLAGS_ALT) != 0;
    var is_neg = false;
    var base: u64 = 10;
    var num = num_in;

    const workend: isize = @intCast(BUFFSIZE - 2);
    var w_idx: isize = workend;

    if ((flags & FLAGS_CHAR) != 0) {
        if ((flags & FLAGS_LEFT) == 0) {
            if (streamPad(userp, stream, streamn, ' ', width - 1, donep)) return true;
            width = 1;
        }
        if (outChar(@truncate(num), userp, stream, donep)) return true;
        if ((flags & FLAGS_LEFT) != 0) {
            if (streamPad(userp, stream, streamn, ' ', width - 1, donep)) return true;
        }
        return false;
    }

    if ((flags & FLAGS_OCTAL) != 0) {
        base = 8;
    } else if ((flags & FLAGS_HEX) != 0) {
        digits = if ((flags & FLAGS_UPPER) != 0) &Curl_udigits else &Curl_ldigits;
        base = 16;
    } else if ((flags & FLAGS_UNSIGNED) != 0) {
        // Decimal unsigned integer
    } else {
        is_neg = (nums < 0);
        if (is_neg) {
            var signed_num: i64 = nums + 1;
            signed_num = -signed_num;
            num = @intCast(signed_num);
            num += 1;
        }
    }

    if (prec == -1) prec = 1;

    switch (base) {
        10 => {
            while (num > 0) {
                work[@intCast(w_idx)] = @intCast('0' + (num % 10));
                w_idx -= 1;
                num /= 10;
            }
        },
        else => {
            while (num > 0) {
                work[@intCast(w_idx)] = digits[@intCast(num % base)];
                w_idx -= 1;
                num /= base;
            }
        },
    }

    const written_digits: c_int = @intCast(workend - w_idx);
    width -= written_digits;
    prec -= written_digits;

    if (is_alt and base == 8 and prec <= 0) {
        work[@intCast(w_idx)] = '0';
        w_idx -= 1;
        width -= 1;
    }

    if (prec > 0) {
        width -= prec;
        while (prec > 0 and w_idx >= 0) {
            prec -= 1;
            work[@intCast(w_idx)] = '0';
            w_idx -= 1;
        }
    }

    if (is_alt and base == 16) width -= 2;

    if (is_neg or (flags & FLAGS_SHOWSIGN) != 0 or (flags & FLAGS_SPACE) != 0) {
        width -= 1;
    }

    if ((flags & FLAGS_LEFT) == 0 and (flags & FLAGS_PAD_NIL) == 0) {
        if (streamPad(userp, stream, streamn, ' ', width, donep)) return true;
        width = 0;
    }

    if (is_neg) {
        if (outChar('-', userp, stream, donep)) return true;
    } else if ((flags & FLAGS_SHOWSIGN) != 0) {
        if (outChar('+', userp, stream, donep)) return true;
    } else if ((flags & FLAGS_SPACE) != 0) {
        if (outChar(' ', userp, stream, donep)) return true;
    }

    if (is_alt and base == 16) {
        if (outChar('0', userp, stream, donep)) return true;
        if ((flags & FLAGS_UPPER) != 0) {
            if (outChar('X', userp, stream, donep)) return true;
        } else {
            if (outChar('x', userp, stream, donep)) return true;
        }
    }

    if ((flags & FLAGS_LEFT) == 0 and (flags & FLAGS_PAD_NIL) != 0) {
        if (streamPad(userp, stream, streamn, '0', width, donep)) return true;
        width = 0;
    }

    const num_start: usize = @intCast(w_idx + 1);
    const num_len: usize = @intCast(workend - w_idx);
    if (streamRun(userp, stream, streamn, work[num_start..].ptr, num_len, donep)) {
        return true;
    }

    if ((flags & FLAGS_LEFT) != 0) {
        if (streamPad(userp, stream, streamn, ' ', width, donep)) return true;
    }

    return false;
}

const nilstr = "(nil)";

fn outString(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    p: *MProperty,
    str_in: ?[*]const u8,
    donep: *c_int,
) bool {
    var flags = p.flags;
    var width = p.width;
    const prec = p.prec;
    var str: [*]const u8 = undefined;
    var len: usize = 0;

    if (str_in) |s| {
        str = s;
        if (prec != -1) {
            len = @intCast(prec);
        } else if (s[0] == 0) {
            len = 0;
        } else {
            len = std.mem.len(@as([*:0]const u8, @ptrCast(s)));
        }
    } else {
        if (prec == -1 or prec >= @as(c_int, @intCast(nilstr.len))) {
            str = nilstr.ptr;
            len = nilstr.len;
            flags &= ~FLAGS_ALT;
        } else {
            str = "".ptr;
            len = 0;
        }
    }

    width -= if (len > @as(usize, @intCast(std.math.maxInt(c_int))))
        std.math.maxInt(c_int)
    else
        @intCast(len);

    if ((flags & FLAGS_ALT) != 0) {
        if (outChar('"', userp, stream, donep)) return true;
    }

    if ((flags & FLAGS_LEFT) == 0) {
        if (streamPad(userp, stream, streamn, ' ', width, donep)) return true;
        width = 0;
    }

    if (prec == -1) {
        if (streamRun(userp, stream, streamn, str, len, donep)) return true;
    } else if (streamZrun(userp, stream, streamn, str, len, donep)) {
        return true;
    }

    if ((flags & FLAGS_LEFT) != 0) {
        if (streamPad(userp, stream, streamn, ' ', width, donep)) return true;
    }

    if ((flags & FLAGS_ALT) != 0) {
        if (outChar('"', userp, stream, donep)) return true;
    }

    return false;
}

fn outPointer(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    p: *MProperty,
    ptr: ?*anyopaque,
    work: *[BUFFSIZE + 2]u8,
    donep: *c_int,
) bool {
    if (ptr) |non_null| {
        const num: u64 = @intCast(@intFromPtr(non_null));
        p.flags |= FLAGS_HEX | FLAGS_ALT;
        if (outNumber(userp, stream, streamn, p, num, 0, work, donep)) return true;
    } else {
        var width = p.width;
        const flags = p.flags;
        width -= @intCast(nilstr.len);
        if ((flags & FLAGS_LEFT) != 0) {
            if (streamPad(userp, stream, streamn, ' ', width, donep)) return true;
            width = 0;
        }
        if (streamRun(userp, stream, streamn, nilstr.ptr, nilstr.len, donep)) return true;
        if ((flags & FLAGS_LEFT) == 0) {
            if (streamPad(userp, stream, streamn, ' ', width, donep)) return true;
        }
    }
    return false;
}

fn formatf(
    userp: *anyopaque,
    stream: MpStream,
    streamn: ?MpStreamN,
    flush: ?MpFlush,
    format: [*:0]const u8,
    ap_save: CVaListParam,
) c_int {
    var done: c_int = 0;
    var ocount: c_int = 0;
    var icount: c_int = 0;

    var output: [MAX_SEGMENTS]OutSegment = undefined;
    var input: [MAX_PARAMETERS]VaInput = undefined;
    var work: [BUFFSIZE + 2]u8 = undefined;

    if (parsefmt(format, &output, &input, &ocount, &icount, ap_save) != PFMT_OK) {
        return 0;
    }

    const total_out: usize = @intCast(ocount);
    for (0..total_out) |i| {
        const optr = &output[i];
        const iptr = &input[@intCast(optr.input)];
        var p: MProperty = undefined;
        const outlen = optr.outlen;

        if (outlen != 0) {
            if (streamZrun(userp, stream, streamn, optr.start, outlen, &done)) {
                return done;
            }
            if ((optr.flags & FLAGS_SUBSTR) != 0) continue;
        }

        p.flags = optr.flags;

        if ((p.flags & FLAGS_WIDTHPARAM) != 0) {
            p.width = @truncate(input[@intCast(optr.width)].val.nums);
            if (p.width < 0) {
                if (p.width == std.math.minInt(c_int)) {
                    p.width = std.math.maxInt(c_int);
                } else {
                    p.width = -p.width;
                }
                p.flags |= FLAGS_LEFT;
                p.flags &= ~FLAGS_PAD_NIL;
            }
        } else {
            p.width = optr.width;
        }

        if ((p.flags & FLAGS_PRECPARAM) != 0) {
            p.prec = @truncate(input[@intCast(optr.precision)].val.nums);
            if (p.prec < 0) p.prec = -1;
        } else if ((p.flags & FLAGS_PREC) != 0) {
            p.prec = optr.precision;
        } else {
            p.prec = -1;
        }

        switch (iptr.type) {
            .MTYPE_INTU, .MTYPE_LONGU, .MTYPE_LONGLONGU => {
                p.flags |= FLAGS_UNSIGNED;
                if (outNumber(userp, stream, streamn, &p, iptr.val.numu, 0, &work, &done)) {
                    return done;
                }
            },
            .MTYPE_INT, .MTYPE_LONG, .MTYPE_LONGLONG => {
                if (outNumber(userp, stream, streamn, &p, iptr.val.numu, iptr.val.nums, &work, &done)) {
                    return done;
                }
            },
            .MTYPE_STRING => {
                if (outString(userp, stream, streamn, &p, iptr.val.str, &done)) {
                    return done;
                }
            },
            .MTYPE_PTR => {
                if (outPointer(userp, stream, streamn, &p, iptr.val.ptr, &work, &done)) {
                    return done;
                }
            },
            .MTYPE_DOUBLE, .MTYPE_LONGDOUBLE => {
                if (outDouble(userp, stream, streamn, &p, iptr.val.dnum, &work, &done)) {
                    return done;
                }
            },
            .MTYPE_INTPTR => {
                if (flush) |fl| {
                    if (fl(userp) != 0) return done;
                }
                if (iptr.val.ptr) |ptr| {
                    if ((p.flags & FLAGS_LONGLONG) != 0) {
                        @as(*align(1) i64, @ptrCast(ptr)).* = @intCast(done);
                    } else if ((p.flags & FLAGS_LONG) != 0) {
                        @as(*align(1) c_long, @ptrCast(ptr)).* = @intCast(done);
                    } else if ((p.flags & FLAGS_SHORT) == 0) {
                        @as(*align(1) c_int, @ptrCast(ptr)).* = done;
                    } else {
                        @as(*align(1) c_short, @ptrCast(ptr)).* = @truncate(done);
                    }
                }
            },
            else => {},
        }
    }
    return done;
}

fn addbyter(outc: u8, f: *anyopaque) c_int {
    const infop: *Nsprintf = @ptrCast(@alignCast(f));
    if (infop.length < infop.max) {
        if (infop.buffer) |b| {
            b[0] = outc;
            infop.buffer = b + 1;
        }
        infop.length += 1;
        return 0;
    }
    return 1;
}

fn addrun(buf: [*]const u8, len_in: usize, f: *anyopaque) usize {
    const infop: *Nsprintf = @ptrCast(@alignCast(f));
    const fit = infop.max - infop.length;
    const len = @min(len_in, fit);
    if (len != 0) {
        if (infop.buffer) |b| {
            @memcpy(b[0..len], buf[0..len]);
            infop.buffer = b + len;
        }
        infop.length += len;
    }
    return len;
}

pub export fn curl_mvsnprintf(
    buffer: ?[*]u8,
    maxlength: usize,
    format: [*:0]const u8,
    args: CVaListParam,
) callconv(.c) c_int {
    var info: Nsprintf = .{
        .buffer = buffer,
        .length = 0,
        .max = maxlength,
    };

    var retcode = formatf(@ptrCast(&info), &addbyter, &addrun, null, format, args);
    if (info.max != 0) {
        if (info.max == info.length) {
            if (info.buffer) |b| {
                (b - 1)[0] = 0;
            }
            retcode -= 1;
        } else if (info.buffer) |b| {
            b[0] = 0;
        }
    }
    return retcode;
}

fn allocFlush(f: *anyopaque) c_int {
    const infop: *Asprintf = @ptrCast(@alignCast(f));
    if (infop.nstage != 0) {
        const result = curlx_dyn_addn(infop.b, &infop.stage, infop.nstage);
        infop.nstage = 0;
        if (result != CURLE_OK) {
            infop.merr = if (result == CURLE_TOO_LARGE) MERR_TOO_LARGE else MERR_MEM;
            return 1;
        }
    }
    return 0;
}

fn allocAddn(infop: *Asprintf, buf: [*]const u8, len: usize) c_int {
    const result = curlx_dyn_addn(infop.b, buf, len);
    if (result != CURLE_OK) {
        infop.merr = if (result == CURLE_TOO_LARGE) MERR_TOO_LARGE else MERR_MEM;
        return 1;
    }
    return 0;
}

fn allocFits(infop: *const Asprintf, more: usize) bool {
    const sum1 = std.math.add(usize, infop.b.leng, infop.nstage) catch return false;
    const sum2 = std.math.add(usize, sum1, more) catch return false;
    const total = std.math.add(usize, sum2, 1) catch return false;
    return total <= infop.b.toobig;
}

fn allocAddbyter(outc: u8, f: *anyopaque) c_int {
    const infop: *Asprintf = @ptrCast(@alignCast(f));
    if (infop.nstage == ASPRINTF_STAGE_SIZE and allocFlush(f) != 0) {
        return 1;
    }
    if (!allocFits(infop, 1)) {
        if (allocFlush(f) != 0) return 1;
        var ch = outc;
        return allocAddn(infop, @ptrCast(&ch), 1);
    }
    infop.stage[infop.nstage] = outc;
    infop.nstage += 1;
    return 0;
}

fn allocAddrun(buf: [*]const u8, len: usize, f: *anyopaque) usize {
    const infop: *Asprintf = @ptrCast(@alignCast(f));
    var accepted: usize = 0;
    while (accepted < len) {
        var room = ASPRINTF_STAGE_SIZE - infop.nstage;
        if (room == 0) {
            if (allocFlush(f) != 0) return accepted;
            room = ASPRINTF_STAGE_SIZE;
        }
        var n = len - accepted;
        if (n > room) n = room;
        if (!allocFits(infop, n)) {
            const used = infop.b.leng + infop.nstage + 1;
            const fits = if (infop.b.toobig > used) infop.b.toobig - used else 0;
            if (fits != 0) {
                @memcpy(infop.stage[infop.nstage .. infop.nstage + fits], buf[accepted .. accepted + fits]);
                infop.nstage += fits;
                accepted += fits;
            }
            if (allocFlush(f) != 0) return accepted;
            if (allocAddn(infop, buf + accepted, 1) != 0) return accepted;
            accepted += 1;
            continue;
        }
        @memcpy(infop.stage[infop.nstage .. infop.nstage + n], buf[accepted .. accepted + n]);
        infop.nstage += n;
        accepted += n;
    }
    return accepted;
}

pub export fn curlx_dyn_vprintf(dyn: *dynbuf, format: [*:0]const u8, args: CVaListParam) callconv(.c) c_int {
    var info: Asprintf = .{
        .b = dyn,
        .merr = MERR_OK,
        .nstage = 0,
        .stage = undefined,
    };

    _ = formatf(@ptrCast(&info), &allocAddbyter, &allocAddrun, &allocFlush, format, args);
    if (info.merr == MERR_OK) {
        _ = allocFlush(@ptrCast(&info));
    }
    if (info.merr != MERR_OK) {
        curlx_dyn_free(info.b);
        return info.merr;
    }
    return 0;
}

pub export fn curl_mvaprintf(format: [*:0]const u8, args: CVaListParam) callconv(.c) ?[*:0]u8 {
    var dyn: dynbuf = undefined;
    curlx_dyn_init(&dyn, DYN_APRINTF);
    var info: Asprintf = .{
        .b = &dyn,
        .merr = MERR_OK,
        .nstage = 0,
        .stage = undefined,
    };

    _ = formatf(@ptrCast(&info), &allocAddbyter, &allocAddrun, &allocFlush, format, args);
    if (info.merr == MERR_OK) {
        _ = allocFlush(@ptrCast(&info));
    }
    if (info.merr != MERR_OK) {
        curlx_dyn_free(info.b);
        return null;
    }
    if (curlx_dyn_len(info.b) != 0) {
        return curlx_dyn_ptr(info.b);
    }
    return mem.strdup("");
}

fn storebuffer(outc: u8, f: *anyopaque) c_int {
    const buffer_ptr: *[*]u8 = @ptrCast(@alignCast(f));
    buffer_ptr.*[0] = outc;
    buffer_ptr.* += 1;
    return 0;
}

fn storerun(buf: [*]const u8, len: usize, f: *anyopaque) usize {
    const buffer_ptr: *[*]u8 = @ptrCast(@alignCast(f));
    @memcpy(buffer_ptr.*[0..len], buf[0..len]);
    buffer_ptr.* += len;
    return len;
}

pub export fn curl_mvsprintf(buffer: [*]u8, format: [*:0]const u8, args: CVaListParam) callconv(.c) c_int {
    var buf_cursor = buffer;
    const retcode = formatf(@ptrCast(&buf_cursor), &storebuffer, &storerun, null, format, args);
    buf_cursor[0] = 0;
    return retcode;
}

fn fputcWrapper(outc: u8, f: *anyopaque) c_int {
    const i: *Ioprintf = @ptrCast(@alignCast(f));
    const rc = stdio_c.fputc(@intCast(outc), i.fd);
    i.err = (rc == -1);
    return @intFromBool(rc == -1);
}

fn fwriteWrapper(buf: [*]const u8, len: usize, f: *anyopaque) usize {
    const i: *Ioprintf = @ptrCast(@alignCast(f));
    const n = stdio_c.fwrite(buf, 1, len, i.fd);
    i.err = (n != len);
    return n;
}

pub export fn curl_mvfprintf(fd: ?*anyopaque, format: [*:0]const u8, args: CVaListParam) callconv(.c) c_int {
    var info: Ioprintf = .{
        .fd = fd,
        .err = false,
    };
    const n = formatf(@ptrCast(&info), &fputcWrapper, &fwriteWrapper, null, format, args);
    if (info.err) return -1;
    return n;
}

pub export fn curl_mvprintf(format: [*:0]const u8, args: CVaListParam) callconv(.c) c_int {
    return curl_mvfprintf(stdio_streams.getStdout(), format, args);
}

// ============================================================================
// 2. lib/formdata.c (lib/formdata.h, include/curl/curl.h)
// ============================================================================

pub const CURLFORMcode = c_uint;
pub const CURL_FORMADD_OK: CURLFORMcode = 0;
pub const CURL_FORMADD_MEMORY: CURLFORMcode = 1;
pub const CURL_FORMADD_OPTION_TWICE: CURLFORMcode = 2;
pub const CURL_FORMADD_NULL: CURLFORMcode = 3;
pub const CURL_FORMADD_UNKNOWN_OPTION: CURLFORMcode = 4;
pub const CURL_FORMADD_INCOMPLETE: CURLFORMcode = 5;
pub const CURL_FORMADD_ILLEGAL_ARRAY: CURLFORMcode = 6;
pub const CURL_FORMADD_DISABLED: CURLFORMcode = 7;

pub const CURLformoption = c_uint;
pub const CURLFORM_NOTHING: CURLformoption = 0;
pub const CURLFORM_COPYNAME: CURLformoption = 1;
pub const CURLFORM_PTRNAME: CURLformoption = 2;
pub const CURLFORM_NAMELENGTH: CURLformoption = 3;
pub const CURLFORM_COPYCONTENTS: CURLformoption = 4;
pub const CURLFORM_PTRCONTENTS: CURLformoption = 5;
pub const CURLFORM_CONTENTSLENGTH: CURLformoption = 6;
pub const CURLFORM_FILECONTENT: CURLformoption = 7;
pub const CURLFORM_ARRAY: CURLformoption = 8;
pub const CURLFORM_OBSOLETE: CURLformoption = 9;
pub const CURLFORM_FILE: CURLformoption = 10;
pub const CURLFORM_BUFFER: CURLformoption = 11;
pub const CURLFORM_BUFFERPTR: CURLformoption = 12;
pub const CURLFORM_BUFFERLENGTH: CURLformoption = 13;
pub const CURLFORM_CONTENTTYPE: CURLformoption = 14;
pub const CURLFORM_CONTENTHEADER: CURLformoption = 15;
pub const CURLFORM_FILENAME: CURLformoption = 16;
pub const CURLFORM_END: CURLformoption = 17;
pub const CURLFORM_OBSOLETE2: CURLformoption = 18;
pub const CURLFORM_STREAM: CURLformoption = 19;
pub const CURLFORM_CONTENTLEN: CURLformoption = 20;

pub const CURL_HTTPPOST_FILENAME: u8 = 1 << 0;
pub const CURL_HTTPPOST_READFILE: u8 = 1 << 1;
pub const CURL_HTTPPOST_PTRNAME: u8 = 1 << 2;
pub const CURL_HTTPPOST_PTRCONTENTS: u8 = 1 << 3;
pub const CURL_HTTPPOST_BUFFER: u8 = 1 << 4;
pub const CURL_HTTPPOST_PTRBUFFER: u8 = 1 << 5;
pub const CURL_HTTPPOST_CALLBACK: u8 = 1 << 6;
pub const CURL_HTTPPOST_LARGE: u8 = 1 << 7;

const FILE_CONTENTTYPE_DEFAULT = "application/octet-stream";
const MIMESTRATEGY_FORM: c_uint = 1;
const CURL_READFUNC_ABORT: usize = 0x10000000;
const CURL_ZERO_TERMINATED: usize = std.math.maxInt(usize);

pub const curl_read_callback = *const fn ([*]u8, usize, usize, ?*anyopaque) callconv(.c) usize;
pub const curl_seek_callback = *const fn (?*anyopaque, i64, c_int) callconv(.c) c_int;
pub const curl_free_callback = *const fn (?*anyopaque) callconv(.c) void;
pub const curl_formget_callback = *const fn (?*anyopaque, [*]const u8, usize) callconv(.c) usize;

pub const curl_httppost = extern struct {
    next: ?*curl_httppost,
    name: ?[*:0]u8,
    namelength: c_long,
    contents: ?[*:0]u8,
    contentslength: c_long,
    buffer: ?[*]u8,
    bufferlength: c_long,
    contenttype: ?[*:0]u8,
    contentheader: ?*curl_slist,
    more: ?*curl_httppost,
    flags: c_long,
    showfilename: ?[*:0]u8,
    userp: ?*anyopaque,
    contentlen: i64,
};

pub const curl_forms = extern struct {
    option: CURLformoption,
    value: ?*const anyopaque,
};

pub const FormInfo = extern struct {
    name: bufref,
    value: bufref,
    contenttype: bufref,
    showfilename: bufref,
    buffer: ?[*]u8,
    userp: ?*anyopaque,
    more: ?*FormInfo,
    contentheader: ?*curl_slist,
    contentslength: i64,
    namelength: usize,
    bufferlength: usize,
    flags: u8,
};

pub const mime_state = extern struct {
    state: c_uint,
    ptr: ?*anyopaque,
    offset: i64,
};

pub const mime_encoder_state = extern struct {
    pos: usize,
    bufbeg: usize,
    bufend: usize,
    buf: [256]u8,
};

pub const curl_mimepart = extern struct {
    parent: ?*anyopaque,
    nextpart: ?*curl_mimepart,
    kind: c_uint,
    flags: c_uint,
    data: ?[*]u8,
    readfunc: ?curl_read_callback,
    seekfunc: ?curl_seek_callback,
    freefunc: ?curl_free_callback,
    arg: ?*anyopaque,
    fp: ?*anyopaque,
    curlheaders: ?*curl_slist,
    userheaders: ?*curl_slist,
    mimetype: ?[*:0]u8,
    filename: ?[*:0]u8,
    name: ?[*:0]u8,
    datasize: i64,
    state: mime_state,
    encoder: ?*const anyopaque,
    encstate: mime_encoder_state,
    lastreadstatus: usize,
};

extern fn Curl_mime_initpart(part: *curl_mimepart) callconv(.c) void;
extern fn Curl_mime_cleanpart(part: *curl_mimepart) callconv(.c) void;
extern fn Curl_mime_prepare_headers(
    data: ?*anyopaque,
    part: *curl_mimepart,
    contenttype: ?[*:0]const u8,
    disposition: ?[*:0]const u8,
    strategy: c_uint,
) callconv(.c) CURLcode;
extern fn Curl_mime_read(buffer: [*]u8, size: usize, nitems: usize, instream: *anyopaque) callconv(.c) usize;
extern fn Curl_mime_contenttype(filename: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;

extern fn curl_mime_init(easy: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn curl_mime_addpart(mime: ?*anyopaque) callconv(.c) ?*curl_mimepart;
extern fn curl_mime_name(part: *curl_mimepart, name: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_filename(part: *curl_mimepart, filename: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_type(part: *curl_mimepart, mimetype: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_data(part: *curl_mimepart, data: ?[*]const u8, datasize: usize) callconv(.c) CURLcode;
extern fn curl_mime_filedata(part: *curl_mimepart, filename: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_data_cb(
    part: *curl_mimepart,
    datasize: i64,
    readfunc: ?curl_read_callback,
    seekfunc: ?curl_seek_callback,
    freefunc: ?curl_free_callback,
    arg: ?*anyopaque,
) callconv(.c) CURLcode;
extern fn curl_mime_subparts(part: *curl_mimepart, subparts: ?*anyopaque) callconv(.c) CURLcode;
extern fn curl_mime_headers(part: *curl_mimepart, headers: ?*curl_slist, take_ownership: c_int) callconv(.c) CURLcode;

fn httppostAdd(
    src: *FormInfo,
    parent_post: ?*curl_httppost,
    httppost: *?*curl_httppost,
    last_post: *?*curl_httppost,
) ?*curl_httppost {
    var namelength = src.namelength;
    if (namelength == 0) {
        if (Curl_bufref_ptr(&src.name)) |n| {
            namelength = std.mem.len(n);
        }
    }
    const max_long: usize = @intCast(std.math.maxInt(c_long));
    if (src.bufferlength > max_long or namelength > max_long) {
        return null;
    }
    const raw = mem.calloc(1, @sizeOf(curl_httppost)) orelse return null;
    const post: *curl_httppost = @ptrCast(@alignCast(raw));
    post.name = @constCast(Curl_bufref_ptr(&src.name));
    post.namelength = @intCast(namelength);
    post.contents = @constCast(Curl_bufref_ptr(&src.value));
    post.contentlen = src.contentslength;
    post.buffer = src.buffer;
    post.bufferlength = @intCast(src.bufferlength);
    post.contenttype = @constCast(Curl_bufref_ptr(&src.contenttype));
    post.flags = @intCast(src.flags | CURL_HTTPPOST_LARGE);
    post.contentheader = src.contentheader;
    post.showfilename = @constCast(Curl_bufref_ptr(&src.showfilename));
    post.userp = src.userp;

    if (parent_post) |p| {
        post.more = p.more;
        p.more = post;
    } else {
        if (last_post.*) |lp| {
            lp.next = post;
        } else {
            httppost.* = post;
        }
        last_post.* = post;
    }
    return post;
}

fn forminfoNew() ?*FormInfo {
    const raw = mem.calloc(1, @sizeOf(FormInfo)) orelse return null;
    const form_info: *FormInfo = @ptrCast(@alignCast(raw));
    Curl_bufref_init(&form_info.name);
    Curl_bufref_init(&form_info.value);
    Curl_bufref_init(&form_info.contenttype);
    Curl_bufref_init(&form_info.showfilename);
    return form_info;
}

fn forminfoCopyfield(field: *bufref, len_in: usize) CURLcode {
    const value = Curl_bufref_ptr(field) orelse return CURLE_OK;
    const len = if (len_in != 0) len_in else std.mem.len(value);
    return Curl_bufref_memdup0(field, value, len);
}

fn forminfoAdd(form_info: *FormInfo, parent: ?*FormInfo) void {
    form_info.flags |= CURL_HTTPPOST_FILENAME;
    if (parent) |p| {
        form_info.more = p.more;
        p.more = form_info;
    }
}

fn freeFormlist(ptr_in: ?*FormInfo) void {
    var ptr = ptr_in;
    while (ptr) |p| : (ptr = p.more) {
        Curl_bufref_free(&p.name);
        Curl_bufref_free(&p.value);
        Curl_bufref_free(&p.contenttype);
        Curl_bufref_free(&p.showfilename);
    }
}

fn formaddCheck(
    first_form: ?*FormInfo,
    httppost: *?*curl_httppost,
    last_post: *?*curl_httppost,
) CURLFORMcode {
    var prevtype: ?[*:0]const u8 = null;
    var form = first_form;
    var post: ?*curl_httppost = null;

    while (form) |f| : (form = f.more) {
        const name = Curl_bufref_ptr(&f.name);
        if (((name == null or Curl_bufref_ptr(&f.value) == null) and post == null) or
            (f.contentslength != 0 and (f.flags & CURL_HTTPPOST_FILENAME) != 0) or
            ((f.flags & CURL_HTTPPOST_FILENAME) != 0 and (f.flags & CURL_HTTPPOST_PTRCONTENTS) != 0) or
            (f.buffer == null and (f.flags & CURL_HTTPPOST_BUFFER) != 0 and (f.flags & CURL_HTTPPOST_PTRBUFFER) != 0) or
            ((f.flags & CURL_HTTPPOST_READFILE) != 0 and (f.flags & CURL_HTTPPOST_PTRCONTENTS) != 0))
        {
            return CURL_FORMADD_INCOMPLETE;
        }

        if (((f.flags & CURL_HTTPPOST_FILENAME) != 0 or (f.flags & CURL_HTTPPOST_BUFFER) != 0) and
            Curl_bufref_ptr(&f.contenttype) == null)
        {
            const fn_ptr = Curl_bufref_ptr(if ((f.flags & CURL_HTTPPOST_BUFFER) != 0) &f.showfilename else &f.value);
            var ctype = Curl_mime_contenttype(fn_ptr);
            if (ctype == null) ctype = prevtype;
            const final_type: [*:0]const u8 = ctype orelse FILE_CONTENTTYPE_DEFAULT;
            if (Curl_bufref_memdup0(&f.contenttype, final_type, std.mem.len(final_type)) != CURLE_OK) {
                return CURL_FORMADD_MEMORY;
            }
        }

        if (name) |n| {
            if (f.namelength != 0) {
                const n_bytes: [*]const u8 = @ptrCast(n);
                if (std.mem.indexOfScalar(u8, n_bytes[0..f.namelength], 0) != null) {
                    return CURL_FORMADD_NULL;
                }
            }
        }

        if ((f.flags & CURL_HTTPPOST_PTRNAME) == 0 and
            forminfoCopyfield(&f.name, f.namelength) != CURLE_OK)
        {
            return CURL_FORMADD_MEMORY;
        }

        const no_copy_val_mask = CURL_HTTPPOST_FILENAME | CURL_HTTPPOST_READFILE |
            CURL_HTTPPOST_PTRCONTENTS | CURL_HTTPPOST_PTRBUFFER | CURL_HTTPPOST_CALLBACK;
        if ((f.flags & no_copy_val_mask) == 0) {
            if (f.contentslength < 0) return CURL_FORMADD_ILLEGAL_ARRAY;
            if (forminfoCopyfield(&f.value, @intCast(f.contentslength)) != CURLE_OK) {
                return CURL_FORMADD_MEMORY;
            }
        }

        post = httppostAdd(f, post, httppost, last_post);
        if (post == null) return CURL_FORMADD_MEMORY;

        if (Curl_bufref_ptr(&f.contenttype)) |ct| {
            prevtype = ct;
        }
    }

    return CURL_FORMADD_OK;
}

fn freeChain(c_in: ?*curl_httppost) void {
    var c = c_in;
    while (c) |node| {
        const next = node.next;
        if (node.more) |more| {
            freeChain(more);
        }
        mem.free(node);
        c = next;
    }
}

pub export fn Curl_vformadd(
    httppost: *?*curl_httppost,
    last_post: *?*curl_httppost,
    params: CVaListParam,
) callconv(.c) CURLFORMcode {
    const first_form = forminfoNew() orelse return CURL_FORMADD_MEMORY;
    var curr: *FormInfo = first_form;
    var retval: CURLFORMcode = CURL_FORMADD_OK;
    var forms: ?[*]const curl_forms = null;
    var avalue_raw: usize = 0;
    var newchain: ?*curl_httppost = null;
    var lastnode: ?*curl_httppost = null;
    var va = VaReader.init(params);

    while (retval == CURL_FORMADD_OK) {
        var option: CURLformoption = CURLFORM_NOTHING;
        var from_forms = false;

        if (forms) |f_arr| {
            option = f_arr[0].option;
            avalue_raw = if (f_arr[0].value) |v| @intFromPtr(v) else 0;
            from_forms = true;
            forms = f_arr + 1;
            if (option == CURLFORM_END) {
                forms = null;
                continue;
            }
        } else {
            option = @bitCast(va.nextGp(c_int));
            if (option == CURLFORM_END) break;
        }

        switch (option) {
            CURLFORM_ARRAY => {
                if (from_forms) {
                    retval = CURL_FORMADD_ILLEGAL_ARRAY;
                } else {
                    const arr = va.nextGp(?[*]const curl_forms);
                    if (arr) |a| {
                        forms = a;
                    } else {
                        retval = CURL_FORMADD_NULL;
                    }
                }
            },
            CURLFORM_PTRNAME, CURLFORM_COPYNAME => {
                if (option == CURLFORM_PTRNAME) {
                    curr.flags |= CURL_HTTPPOST_PTRNAME;
                }
                if (Curl_bufref_ptr(&curr.name) != null) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const avalue: ?[*:0]u8 = if (from_forms)
                        (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                    else
                        va.nextGp(?[*:0]u8);
                    if (avalue) |av| {
                        Curl_bufref_set(&curr.name, av, 0, null);
                    } else {
                        retval = CURL_FORMADD_NULL;
                    }
                }
            },
            CURLFORM_NAMELENGTH => {
                if (curr.namelength != 0) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const nlen: c_long = if (from_forms)
                        @bitCast(@as(c_ulong, @truncate(avalue_raw)))
                    else
                        va.nextGp(c_long);
                    curr.namelength = @bitCast(@as(isize, nlen));
                }
            },
            CURLFORM_PTRCONTENTS, CURLFORM_COPYCONTENTS => {
                if (option == CURLFORM_PTRCONTENTS) {
                    curr.flags |= CURL_HTTPPOST_PTRCONTENTS;
                }
                if (Curl_bufref_ptr(&curr.value) != null) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const avalue: ?[*]u8 = if (from_forms)
                        (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                    else
                        va.nextGp(?[*]u8);
                    if (avalue) |av| {
                        Curl_bufref_set(&curr.value, av, 0, null);
                    } else {
                        retval = CURL_FORMADD_NULL;
                    }
                }
            },
            CURLFORM_CONTENTSLENGTH => {
                const clen: c_long = if (from_forms)
                    @bitCast(@as(c_ulong, @truncate(avalue_raw)))
                else
                    va.nextGp(c_long);
                if (clen < 0) {
                    retval = CURL_FORMADD_INCOMPLETE;
                } else {
                    curr.contentslength = @intCast(clen);
                }
            },
            CURLFORM_CONTENTLEN => {
                const clen: i64 = if (from_forms)
                    @bitCast(@as(u64, avalue_raw))
                else
                    va.nextGp(i64);
                if (clen < 0) {
                    retval = CURL_FORMADD_INCOMPLETE;
                } else {
                    curr.flags |= CURL_HTTPPOST_LARGE;
                    curr.contentslength = clen;
                }
            },
            CURLFORM_FILECONTENT => {
                if ((curr.flags & (CURL_HTTPPOST_PTRCONTENTS | CURL_HTTPPOST_READFILE)) != 0) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const avalue: ?[*:0]const u8 = if (from_forms)
                        (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                    else
                        va.nextGp(?[*:0]const u8);
                    if (avalue) |av| {
                        if (Curl_bufref_memdup0(&curr.value, av, std.mem.len(av)) != CURLE_OK) {
                            retval = CURL_FORMADD_MEMORY;
                        } else {
                            curr.flags |= CURL_HTTPPOST_READFILE;
                        }
                    } else {
                        retval = CURL_FORMADD_NULL;
                    }
                }
            },
            CURLFORM_FILE => {
                const avalue: ?[*:0]const u8 = if (from_forms)
                    (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                else
                    va.nextGp(?[*:0]const u8);
                if (Curl_bufref_ptr(&curr.value) != null) {
                    if ((curr.flags & CURL_HTTPPOST_FILENAME) != 0) {
                        if (avalue) |av| {
                            const form = forminfoNew();
                            if (form == null or Curl_bufref_memdup0(&form.?.value, av, std.mem.len(av)) != CURLE_OK) {
                                mem.free(form);
                                retval = CURL_FORMADD_MEMORY;
                            } else {
                                forminfoAdd(form.?, curr);
                                curr = form.?;
                            }
                        } else {
                            retval = CURL_FORMADD_NULL;
                        }
                    } else {
                        retval = CURL_FORMADD_OPTION_TWICE;
                    }
                } else {
                    if (avalue) |av| {
                        if (Curl_bufref_memdup0(&curr.value, av, std.mem.len(av)) != CURLE_OK) {
                            retval = CURL_FORMADD_MEMORY;
                        } else {
                            curr.flags |= CURL_HTTPPOST_FILENAME;
                        }
                    } else {
                        retval = CURL_FORMADD_NULL;
                    }
                }
            },
            CURLFORM_BUFFERPTR => {
                curr.flags |= CURL_HTTPPOST_PTRBUFFER | CURL_HTTPPOST_BUFFER;
                if (curr.buffer != null) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const avalue: ?[*]u8 = if (from_forms)
                        (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                    else
                        va.nextGp(?[*]u8);
                    if (avalue) |av| {
                        curr.buffer = av;
                        Curl_bufref_set(&curr.value, av, 0, null);
                    } else {
                        retval = CURL_FORMADD_NULL;
                    }
                }
            },
            CURLFORM_BUFFERLENGTH => {
                if (curr.bufferlength != 0) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const blen: c_long = if (from_forms)
                        @bitCast(@as(c_ulong, @truncate(avalue_raw)))
                    else
                        va.nextGp(c_long);
                    curr.bufferlength = @bitCast(@as(isize, blen));
                }
            },
            CURLFORM_STREAM => {
                curr.flags |= CURL_HTTPPOST_CALLBACK;
                if (curr.userp != null) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const avalue: ?*anyopaque = if (from_forms)
                        (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                    else
                        va.nextGp(?*anyopaque);
                    if (avalue) |av| {
                        curr.userp = av;
                        Curl_bufref_set(&curr.value, av, 0, null);
                    } else {
                        retval = CURL_FORMADD_NULL;
                    }
                }
            },
            CURLFORM_CONTENTTYPE => {
                const avalue: ?[*:0]const u8 = if (from_forms)
                    (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                else
                    va.nextGp(?[*:0]const u8);
                if (Curl_bufref_ptr(&curr.contenttype) != null) {
                    if ((curr.flags & CURL_HTTPPOST_FILENAME) != 0) {
                        if (avalue) |av| {
                            const form = forminfoNew();
                            if (form == null or Curl_bufref_memdup0(&form.?.contenttype, av, std.mem.len(av)) != CURLE_OK) {
                                mem.free(form);
                                retval = CURL_FORMADD_MEMORY;
                            } else {
                                forminfoAdd(form.?, curr);
                                curr = form.?;
                            }
                        } else {
                            retval = CURL_FORMADD_NULL;
                        }
                    } else {
                        retval = CURL_FORMADD_OPTION_TWICE;
                    }
                } else if (avalue) |av| {
                    if (Curl_bufref_memdup0(&curr.contenttype, av, std.mem.len(av)) != CURLE_OK) {
                        retval = CURL_FORMADD_MEMORY;
                    }
                } else {
                    retval = CURL_FORMADD_NULL;
                }
            },
            CURLFORM_CONTENTHEADER => {
                const list: ?*curl_slist = if (from_forms)
                    (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                else
                    va.nextGp(?*curl_slist);
                if (curr.contentheader != null) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    curr.contentheader = list;
                }
            },
            CURLFORM_FILENAME, CURLFORM_BUFFER => {
                const avalue: ?[*:0]const u8 = if (from_forms)
                    (if (avalue_raw != 0) @ptrFromInt(avalue_raw) else null)
                else
                    va.nextGp(?[*:0]const u8);
                if (Curl_bufref_ptr(&curr.showfilename) != null) {
                    retval = CURL_FORMADD_OPTION_TWICE;
                } else {
                    const av_len = if (avalue) |av| std.mem.len(av) else 0;
                    if (Curl_bufref_memdup0(&curr.showfilename, avalue, av_len) != CURLE_OK) {
                        retval = CURL_FORMADD_MEMORY;
                    }
                }
            },
            else => {
                retval = CURL_FORMADD_UNKNOWN_OPTION;
            },
        }
    }

    if (retval == CURL_FORMADD_OK) {
        retval = formaddCheck(first_form, &newchain, &lastnode);
    }

    if (retval != CURL_FORMADD_OK) {
        freeFormlist(first_form);
    }

    var fi_opt: ?*FormInfo = first_form;
    while (fi_opt) |fi| {
        const next_fi = fi.more;
        mem.free(fi);
        fi_opt = next_fi;
    }

    if (retval == CURL_FORMADD_OK) {
        if (last_post.*) |lp| {
            lp.next = newchain;
        } else {
            httppost.* = newchain;
        }
        last_post.* = lastnode;
    } else {
        freeChain(newchain);
    }

    return retval;
}

pub export fn curl_formget(
    form: ?*curl_httppost,
    arg: ?*anyopaque,
    append: ?curl_formget_callback,
) callconv(.c) c_int {
    const append_cb = append orelse return @intCast(CURLE_BAD_FUNCTION_ARGUMENT);

    var toppart: curl_mimepart = undefined;
    Curl_mime_initpart(&toppart);
    var result = Curl_getformdata(null, &toppart, form, null);
    if (result == CURLE_OK) {
        result = Curl_mime_prepare_headers(null, &toppart, "multipart/form-data", null, MIMESTRATEGY_FORM);
    }

    while (result == CURLE_OK) {
        var buffer: [8192]u8 = undefined;
        const nread = Curl_mime_read(&buffer, 1, buffer.len, @ptrCast(&toppart));
        if (nread == 0) break;
        if (nread > buffer.len or append_cb(arg, &buffer, nread) != nread) {
            result = CURLE_READ_ERROR;
            if (nread == CURL_READFUNC_ABORT) {
                result = CURLE_ABORTED_BY_CALLBACK;
            }
        }
    }

    Curl_mime_cleanpart(&toppart);
    return @intCast(result);
}

pub export fn curl_formfree(form_in: ?*curl_httppost) callconv(.c) void {
    var form = form_in orelse return;
    while (true) {
        const next = form.next;
        curl_formfree(form.more);

        if ((form.flags & @as(c_long, CURL_HTTPPOST_PTRNAME)) == 0) {
            mem.free(form.name);
        }
        const no_free_contents_mask: c_long = @intCast(CURL_HTTPPOST_PTRCONTENTS | CURL_HTTPPOST_BUFFER | CURL_HTTPPOST_CALLBACK);
        if ((form.flags & no_free_contents_mask) == 0) {
            mem.free(form.contents);
        }
        mem.free(form.contenttype);
        mem.free(form.showfilename);
        mem.free(form);
        form = next orelse break;
    }
}

fn setname(part: *curl_mimepart, name: ?[*]const u8, len: usize) CURLcode {
    if (name == null or len == 0) {
        return curl_mime_name(part, if (name) |n| @ptrCast(n) else null);
    }
    const zname_raw = curlx_memdup0(name, len) orelse return CURLE_OUT_OF_MEMORY;
    const zname: [*:0]u8 = @ptrCast(zname_raw);
    const result = curl_mime_name(part, zname);
    mem.free(zname_raw);
    return result;
}

pub export fn Curl_getformdata(
    data: ?*anyopaque,
    finalform: *curl_mimepart,
    post_in: ?*curl_httppost,
    fread_func: ?curl_read_callback,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    Curl_mime_cleanpart(finalform);

    var post = post_in orelse return result;

    const form = curl_mime_init(data);
    if (form == null) {
        result = CURLE_OUT_OF_MEMORY;
    }
    if (result == CURLE_OK) {
        result = curl_mime_subparts(finalform, form);
    }

    while (result == CURLE_OK) {
        var multipart = form;
        if (post.more != null) {
            const part = curl_mime_addpart(form);
            if (part == null) {
                result = CURLE_OUT_OF_MEMORY;
            }
            if (result == CURLE_OK) {
                if (post.namelength < 0) {
                    result = CURLE_BAD_FUNCTION_ARGUMENT;
                } else {
                    const n_ptr: ?[*]const u8 = if (post.name) |n| @ptrCast(n) else null;
                    result = setname(part.?, n_ptr, @intCast(post.namelength));
                }
            }
            if (result == CURLE_OK) {
                multipart = curl_mime_init(data);
                if (multipart == null) {
                    result = CURLE_OUT_OF_MEMORY;
                }
            }
            if (result == CURLE_OK) {
                result = curl_mime_subparts(part.?, multipart);
            }
        }

        var file_opt: ?*curl_httppost = post;
        while (result == CURLE_OK and file_opt != null) : (file_opt = file_opt.?.more) {
            const file = file_opt.?;
            const part = curl_mime_addpart(multipart);
            if (part == null) {
                result = CURLE_OUT_OF_MEMORY;
            }
            if (result == CURLE_OK) {
                result = curl_mime_headers(part.?, file.contentheader, 0);
            }
            if (result == CURLE_OK and file.contenttype != null) {
                result = curl_mime_type(part.?, file.contenttype);
            }
            if (result == CURLE_OK and post.more == null) {
                if (post.namelength < 0) {
                    result = CURLE_BAD_FUNCTION_ARGUMENT;
                } else {
                    const n_ptr: ?[*]const u8 = if (post.name) |n| @ptrCast(n) else null;
                    result = setname(part.?, n_ptr, @intCast(post.namelength));
                }
            }
            if (result == CURLE_OK) {
                var clen: i64 = @intCast(post.contentslength);
                if ((post.flags & @as(c_long, CURL_HTTPPOST_LARGE)) != 0) {
                    clen = post.contentlen;
                }

                if ((post.flags & @as(c_long, CURL_HTTPPOST_FILENAME | CURL_HTTPPOST_READFILE)) != 0) {
                    const contents_str = if (file.contents) |c| std.mem.span(c) else "";
                    if (std.mem.eql(u8, contents_str, "-")) {
                        result = curl_mime_data_cb(
                            part.?,
                            -1,
                            &stdio_c.fread,
                            &os_leaf.curlx_fseek,
                            null,
                            stdio_streams.getStdin(),
                        );
                    } else {
                        result = curl_mime_filedata(part.?, file.contents);
                    }
                    if (result == CURLE_OK and (post.flags & @as(c_long, CURL_HTTPPOST_READFILE)) != 0) {
                        result = curl_mime_filename(part.?, null);
                    }
                } else if ((post.flags & @as(c_long, CURL_HTTPPOST_BUFFER)) != 0) {
                    const blen: usize = if (post.bufferlength > 0)
                        @intCast(post.bufferlength)
                    else
                        CURL_ZERO_TERMINATED;
                    result = curl_mime_data(part.?, post.buffer, blen);
                } else if ((post.flags & @as(c_long, CURL_HTTPPOST_CALLBACK)) != 0) {
                    if (clen == 0) clen = -1;
                    result = curl_mime_data_cb(part.?, clen, fread_func, null, null, post.userp);
                } else if (clen < 0) {
                    result = CURLE_BAD_FUNCTION_ARGUMENT;
                } else {
                    const uclen: usize = if (clen == 0) CURL_ZERO_TERMINATED else @intCast(clen);
                    const c_ptr: ?[*]const u8 = if (post.contents) |c| @ptrCast(c) else null;
                    result = curl_mime_data(part.?, c_ptr, uclen);
                }
            }
            if (result == CURLE_OK and post.showfilename != null) {
                const show_mask: c_long = @intCast(CURL_HTTPPOST_FILENAME | CURL_HTTPPOST_BUFFER | CURL_HTTPPOST_CALLBACK);
                if (post.more != null or (post.flags & show_mask) != 0) {
                    result = curl_mime_filename(part.?, post.showfilename);
                }
            }
        }

        post = post.next orelse break;
    }

    if (result != CURLE_OK) {
        Curl_mime_cleanpart(finalform);
    }
    return result;
}

// ============================================================================
// Variadic C ABI entry points across all 4 targets
// ============================================================================

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin(),
    else => false,
};

const variadic_impl = if (use_c_vastart) struct {
    pub fn curl_msnprintf(buffer: ?[*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        return curl_mvsnprintf(buffer, maxlength, format, param);
    }

    pub fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8 {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        return curl_mvaprintf(format, param);
    }

    pub fn curl_msprintf(buffer: [*]u8, format: [*:0]const u8, ...) callconv(.c) c_int {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        return curl_mvsprintf(buffer, format, param);
    }

    pub fn curl_mfprintf(fd: ?*anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        return curl_mvfprintf(fd, format, param);
    }

    pub fn curl_mprintf(format: [*:0]const u8, ...) callconv(.c) c_int {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        return curl_mvprintf(format, param);
    }

    pub fn curl_formadd(httppost: *?*curl_httppost, last_post: *?*curl_httppost, ...) callconv(.c) CURLFORMcode {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        return Curl_vformadd(httppost, last_post, param);
    }
} else if (builtin.cpu.arch == .x86_64 and builtin.os.tag == .windows) struct {
    pub fn curl_msnprintf() callconv(.naked) void {
        asm volatile (
            \\movq %%r9, 32(%%rsp)
            \\leaq 32(%%rsp), %%r9
            \\jmp curl_mvsnprintf
        );
    }

    pub fn curl_maprintf() callconv(.naked) void {
        asm volatile (
            \\movq %%rdx, 16(%%rsp)
            \\movq %%r8, 24(%%rsp)
            \\movq %%r9, 32(%%rsp)
            \\leaq 16(%%rsp), %%rdx
            \\jmp curl_mvaprintf
        );
    }

    pub fn curl_msprintf() callconv(.naked) void {
        asm volatile (
            \\movq %%r8, 24(%%rsp)
            \\movq %%r9, 32(%%rsp)
            \\leaq 24(%%rsp), %%r8
            \\jmp curl_mvsprintf
        );
    }

    pub fn curl_mfprintf() callconv(.naked) void {
        asm volatile (
            \\movq %%r8, 24(%%rsp)
            \\movq %%r9, 32(%%rsp)
            \\leaq 24(%%rsp), %%r8
            \\jmp curl_mvfprintf
        );
    }

    pub fn curl_mprintf() callconv(.naked) void {
        asm volatile (
            \\movq %%rdx, 16(%%rsp)
            \\movq %%r8, 24(%%rsp)
            \\movq %%r9, 32(%%rsp)
            \\leaq 16(%%rsp), %%rdx
            \\jmp curl_mvprintf
        );
    }

    pub fn curl_formadd() callconv(.naked) void {
        asm volatile (
            \\movq %%r8, 24(%%rsp)
            \\movq %%r9, 32(%%rsp)
            \\leaq 24(%%rsp), %%r8
            \\jmp Curl_vformadd
        );
    }
} else if (builtin.cpu.arch == .aarch64) struct {
    pub fn curl_msnprintf() callconv(.naked) void {
        asm volatile (
            \\sub sp, sp, #256
            \\stp x29, x30, [sp, #240]
            \\add x29, sp, #240
            \\str x3, [x29, #-104]
            \\stp x4, x5, [x29, #-96]
            \\stp x6, x7, [x29, #-80]
            \\stp q0, q1, [sp]
            \\stp q2, q3, [sp, #32]
            \\stp q4, q5, [sp, #64]
            \\stp q6, q7, [sp, #96]
            \\add x9, x29, #16
            \\sub x8, x29, #64
            \\stp x9, x8, [x29, #-64]
            \\add x9, sp, #128
            \\mov x8, #-40
            \\movk x8, #65408, lsl #32
            \\stp x9, x8, [x29, #-48]
            \\sub x3, x29, #64
            \\bl curl_mvsnprintf
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }

    pub fn curl_maprintf() callconv(.naked) void {
        asm volatile (
            \\sub sp, sp, #256
            \\stp x29, x30, [sp, #240]
            \\add x29, sp, #240
            \\str x1, [x29, #-120]
            \\stp x2, x3, [x29, #-112]
            \\stp x4, x5, [x29, #-96]
            \\stp x6, x7, [x29, #-80]
            \\stp q0, q1, [sp]
            \\stp q2, q3, [sp, #32]
            \\stp q4, q5, [sp, #64]
            \\stp q6, q7, [sp, #96]
            \\add x9, x29, #16
            \\sub x8, x29, #64
            \\stp x9, x8, [x29, #-64]
            \\add x9, sp, #128
            \\mov x8, #-56
            \\movk x8, #65408, lsl #32
            \\stp x9, x8, [x29, #-48]
            \\sub x1, x29, #64
            \\bl curl_mvaprintf
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }

    pub fn curl_msprintf() callconv(.naked) void {
        asm volatile (
            \\sub sp, sp, #256
            \\stp x29, x30, [sp, #240]
            \\add x29, sp, #240
            \\stp x2, x3, [x29, #-112]
            \\stp x4, x5, [x29, #-96]
            \\stp x6, x7, [x29, #-80]
            \\stp q0, q1, [sp]
            \\stp q2, q3, [sp, #32]
            \\stp q4, q5, [sp, #64]
            \\stp q6, q7, [sp, #96]
            \\add x9, x29, #16
            \\sub x8, x29, #64
            \\stp x9, x8, [x29, #-64]
            \\add x9, sp, #128
            \\mov x8, #-48
            \\movk x8, #65408, lsl #32
            \\stp x9, x8, [x29, #-48]
            \\sub x2, x29, #64
            \\bl curl_mvsprintf
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }

    pub fn curl_mfprintf() callconv(.naked) void {
        asm volatile (
            \\sub sp, sp, #256
            \\stp x29, x30, [sp, #240]
            \\add x29, sp, #240
            \\stp x2, x3, [x29, #-112]
            \\stp x4, x5, [x29, #-96]
            \\stp x6, x7, [x29, #-80]
            \\stp q0, q1, [sp]
            \\stp q2, q3, [sp, #32]
            \\stp q4, q5, [sp, #64]
            \\stp q6, q7, [sp, #96]
            \\add x9, x29, #16
            \\sub x8, x29, #64
            \\stp x9, x8, [x29, #-64]
            \\add x9, sp, #128
            \\mov x8, #-48
            \\movk x8, #65408, lsl #32
            \\stp x9, x8, [x29, #-48]
            \\sub x2, x29, #64
            \\bl curl_mvfprintf
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }

    pub fn curl_mprintf() callconv(.naked) void {
        asm volatile (
            \\sub sp, sp, #256
            \\stp x29, x30, [sp, #240]
            \\add x29, sp, #240
            \\str x1, [x29, #-120]
            \\stp x2, x3, [x29, #-112]
            \\stp x4, x5, [x29, #-96]
            \\stp x6, x7, [x29, #-80]
            \\stp q0, q1, [sp]
            \\stp q2, q3, [sp, #32]
            \\stp q4, q5, [sp, #64]
            \\stp q6, q7, [sp, #96]
            \\add x9, x29, #16
            \\sub x8, x29, #64
            \\stp x9, x8, [x29, #-64]
            \\add x9, sp, #128
            \\mov x8, #-56
            \\movk x8, #65408, lsl #32
            \\stp x9, x8, [x29, #-48]
            \\sub x1, x29, #64
            \\bl curl_mvprintf
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }

    pub fn curl_formadd() callconv(.naked) void {
        asm volatile (
            \\sub sp, sp, #256
            \\stp x29, x30, [sp, #240]
            \\add x29, sp, #240
            \\stp x2, x3, [x29, #-112]
            \\stp x4, x5, [x29, #-96]
            \\stp x6, x7, [x29, #-80]
            \\stp q0, q1, [sp]
            \\stp q2, q3, [sp, #32]
            \\stp q4, q5, [sp, #64]
            \\stp q6, q7, [sp, #96]
            \\add x9, x29, #16
            \\sub x8, x29, #64
            \\stp x9, x8, [x29, #-64]
            \\add x9, sp, #128
            \\mov x8, #-48
            \\movk x8, #65408, lsl #32
            \\stp x9, x8, [x29, #-48]
            \\sub x2, x29, #64
            \\bl Curl_vformadd
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }
} else struct {};

comptime {
    @export(&variadic_impl.curl_msnprintf, .{ .name = "curl_msnprintf", .linkage = .strong });
    @export(&variadic_impl.curl_maprintf, .{ .name = "curl_maprintf", .linkage = .strong });
    @export(&variadic_impl.curl_msprintf, .{ .name = "curl_msprintf", .linkage = .strong });
    @export(&variadic_impl.curl_mfprintf, .{ .name = "curl_mfprintf", .linkage = .strong });
    @export(&variadic_impl.curl_mprintf, .{ .name = "curl_mprintf", .linkage = .strong });
    @export(&variadic_impl.curl_formadd, .{ .name = "curl_formadd", .linkage = .strong });
}

extern fn curl_msnprintf(buffer: ?[*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_msprintf(buffer: [*]u8, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_formadd(httppost: *?*curl_httppost, last_post: *?*curl_httppost, ...) callconv(.c) CURLFORMcode;

// ============================================================================
// Unit Tests
// ============================================================================

test "curl_msnprintf and curl_msprintf formatting" {
    var buf: [256]u8 = undefined;

    const n1 = curl_msnprintf(&buf, buf.len, "Hello %s %d %#x %%", "curl", @as(c_int, -42), @as(c_uint, 0xbeef));
    try std.testing.expectEqual(@as(c_int, 23), n1);
    try std.testing.expectEqualStrings("Hello curl -42 0xbeef %", std.mem.sliceTo(&buf, 0));

    // Positional parameters ($), width (*), precision (.*), %S (quoted string), %n
    var written_so_far: c_int = 0;
    const n2 = curl_msnprintf(
        &buf,
        buf.len,
        "%2$*1$.*3$s %4$S%5$n!",
        @as(c_int, 6),
        "abcdef",
        @as(c_int, 3),
        "hi",
        &written_so_far,
    );
    try std.testing.expectEqual(@as(c_int, 12), n2);
    try std.testing.expectEqual(@as(c_int, 11), written_so_far);
    try std.testing.expectEqualStrings("   abc \"hi\"!", std.mem.sliceTo(&buf, 0));

    // Truncation behavior
    var small: [5]u8 = @splat(0xaa);
    const n3 = curl_msnprintf(&small, small.len, "12345678");
    try std.testing.expectEqual(@as(c_int, 4), n3);
    try std.testing.expectEqualStrings("1234", std.mem.sliceTo(&small, 0));

    // curl_msprintf with 64-bit ints, octal, hex, char, pointer, and float
    const n4 = curl_msprintf(
        &buf,
        "%08lld %llu %#o %#X %c %p %.2f",
        @as(i64, -99),
        @as(u64, 12345),
        @as(c_uint, 0o755),
        @as(c_uint, 0x1a2b),
        @as(c_int, 'Z'),
        @as(?*anyopaque, null),
        @as(f64, 3.25),
    );
    try std.testing.expectEqual(@as(c_int, 39), n4);
    try std.testing.expectEqualStrings("-0000099 12345 0755 0X1A2B Z (nil) 3.25", std.mem.sliceTo(&buf, 0));
}

test "curl_maprintf and curlx_dyn_vprintf" {
    const s = curl_maprintf("host=%s port=%u nil=%s", "example.com", @as(c_uint, 8080), @as(?[*:0]const u8, null)) orelse return error.OutOfMemory;
    defer mem.free(s);
    try std.testing.expectEqualStrings("host=example.com port=8080 nil=(nil)", std.mem.span(s));

    const empty = curl_maprintf("") orelse return error.OutOfMemory;
    defer mem.free(empty);
    try std.testing.expectEqualStrings("", std.mem.span(empty));

    // INT64_MIN edge case and stage boundary (> 512 bytes)
    const min_i64 = curl_maprintf("%lld", @as(i64, std.math.minInt(i64))) orelse return error.OutOfMemory;
    defer mem.free(min_i64);
    try std.testing.expectEqualStrings("-9223372036854775808", std.mem.span(min_i64));

    const wide = curl_maprintf("%600d", @as(c_int, 7)) orelse return error.OutOfMemory;
    defer mem.free(wide);
    const wide_slice = std.mem.span(wide);
    try std.testing.expectEqual(@as(usize, 600), wide_slice.len);
    try std.testing.expectEqual(@as(u8, '7'), wide_slice[599]);
}

test "curl_formadd, curl_formget, and curl_formfree" {
    var post: ?*curl_httppost = null;
    var last: ?*curl_httppost = null;
    defer curl_formfree(post);

    const rc1 = curl_formadd(
        &post,
        &last,
        CURLFORM_COPYNAME,
        "field1",
        CURLFORM_COPYCONTENTS,
        "value1",
        CURLFORM_END,
    );
    try std.testing.expectEqual(CURL_FORMADD_OK, rc1);
    try std.testing.expect(post != null);
    try std.testing.expectEqualStrings("field1", std.mem.span(post.?.name.?));
    try std.testing.expectEqualStrings("value1", std.mem.span(post.?.contents.?));

    const forms_arr = [_]curl_forms{
        .{ .option = CURLFORM_COPYNAME, .value = @ptrCast("arr_field") },
        .{ .option = CURLFORM_COPYCONTENTS, .value = @ptrCast("arr_val") },
        .{ .option = CURLFORM_END, .value = null },
    };
    const rc2 = curl_formadd(
        &post,
        &last,
        CURLFORM_ARRAY,
        &forms_arr,
        CURLFORM_END,
    );
    try std.testing.expectEqual(CURL_FORMADD_OK, rc2);
    try std.testing.expect(post.?.next != null);
    try std.testing.expectEqualStrings("arr_field", std.mem.span(post.?.next.?.name.?));
    try std.testing.expectEqualStrings("arr_val", std.mem.span(post.?.next.?.contents.?));

    // Buffer upload part + custom content-type
    const raw_buf = "binary-payload";
    const rc3 = curl_formadd(
        &post,
        &last,
        CURLFORM_PTRNAME,
        "filebuf",
        CURLFORM_BUFFER,
        "report.txt",
        CURLFORM_BUFFERPTR,
        raw_buf.ptr,
        CURLFORM_BUFFERLENGTH,
        @as(c_long, @intCast(raw_buf.len)),
        CURLFORM_END,
    );
    try std.testing.expectEqual(CURL_FORMADD_OK, rc3);

    // Error cases: incomplete form and option twice
    var bad_post: ?*curl_httppost = null;
    var bad_last: ?*curl_httppost = null;
    try std.testing.expectEqual(
        CURL_FORMADD_INCOMPLETE,
        curl_formadd(&bad_post, &bad_last, CURLFORM_COPYNAME, "only_name", CURLFORM_END),
    );
    try std.testing.expectEqual(
        CURL_FORMADD_OPTION_TWICE,
        curl_formadd(&bad_post, &bad_last, CURLFORM_COPYNAME, "n1", CURLFORM_COPYNAME, "n2", CURLFORM_END),
    );
    try std.testing.expect(bad_post == null);

    const Accum = struct {
        var total: usize = 0;
        fn cb(arg: ?*anyopaque, buf: [*]const u8, len: usize) callconv(.c) usize {
            _ = arg;
            _ = buf;
            total += len;
            return len;
        }
    };
    Accum.total = 0;
    try std.testing.expectEqual(@as(c_int, 0), curl_formget(post, null, &Accum.cb));
    try std.testing.expect(Accum.total > 0);
}

test "adversarial mprintf width/precision overflow and positional $ argument bounds" {
    var buf: [64]u8 = undefined;

    // Out-of-range / gapped positional $ arguments: %2$s (gap at 1), %1$s %129$s (MAX_PARAMETERS = 128), and huge index overflow
    try std.testing.expectEqual(@as(c_int, 0), curl_msnprintf(&buf, buf.len, "%2$s", @as([*:0]const u8, "x")));
    try std.testing.expectEqualStrings("", std.mem.sliceTo(&buf, 0));

    try std.testing.expectEqual(
        @as(c_int, 0),
        curl_msnprintf(&buf, buf.len, "%1$s %129$s", @as([*:0]const u8, "x"), @as([*:0]const u8, "y")),
    );
    try std.testing.expectEqualStrings("", std.mem.sliceTo(&buf, 0));

    try std.testing.expectEqual(
        @as(c_int, 0),
        curl_msnprintf(&buf, buf.len, "%1$s %99999999999$s", @as([*:0]const u8, "x"), @as([*:0]const u8, "y")),
    );
    try std.testing.expectEqualStrings("", std.mem.sliceTo(&buf, 0));

    // Extreme width and precision exceeding i32 max must fail safely without panic or OOB
    try std.testing.expectEqual(@as(c_int, 0), curl_msnprintf(&buf, buf.len, "%2147483648s", @as([*:0]const u8, "x")));
    try std.testing.expectEqual(@as(c_int, 0), curl_msnprintf(&buf, buf.len, "%.2147483648s", @as([*:0]const u8, "x")));

    // Mixing positional and non-positional parameters must be rejected
    try std.testing.expectEqual(
        @as(c_int, 0),
        curl_msnprintf(&buf, buf.len, "%1$s %s", @as([*:0]const u8, "a"), @as([*:0]const u8, "b")),
    );
}
