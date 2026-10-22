const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const crypto = @import("crypto.zig");
const threads_psl = @import("threads_psl.zig");
const headers_sock = @import("headers_sock.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_TOO_LARGE: CURLcode = 100;

pub const CURLMcode = c_int;
pub const CURLM_OK: CURLMcode = 0;

pub const CURLSHcode = c_uint;
pub const CURLSHE_OK: CURLSHcode = 0;
pub const CURLSHE_BAD_OPTION: CURLSHcode = 1;
pub const CURLSHE_IN_USE: CURLSHcode = 2;
pub const CURLSHE_INVALID: CURLSHcode = 3;
pub const CURLSHE_NOMEM: CURLSHcode = 4;
pub const CURLSHE_NOT_BUILT_IN: CURLSHcode = 5;

pub const CURLHcode = c_uint;
pub const CURLHE_OK: CURLHcode = 0;
pub const CURLHE_BADINDEX: CURLHcode = 1;
pub const CURLHE_MISSING: CURLHcode = 2;
pub const CURLHE_NOHEADERS: CURLHcode = 3;
pub const CURLHE_NOREQUEST: CURLHcode = 4;
pub const CURLHE_OUT_OF_MEMORY: CURLHcode = 5;
pub const CURLHE_BAD_ARGUMENT: CURLHcode = 6;
pub const CURLHE_NOT_BUILT_IN: CURLHcode = 7;

pub const timediff_t = curlx_time_net.timediff_t;
pub const time_t = curlx_time_net.time_t;
pub const Curltime = curlx_time_net.Curltime;
pub const curl_socket_t = curlx_time_net.curl_socket_t;

pub const dynbuf = containers.dynbuf;
pub const curl_slist = containers.curl_slist;
pub const Curl_str = curlx_parse.Curl_str;
pub const Curl_llist = containers.Curl_llist;
pub const Curl_llist_node = containers.Curl_llist_node;
pub const ptrarray = collections.ptrarray;

extern fn Curl_hexencode(src: [*]const u8, len: usize, out: [*]u8, olen: usize) callconv(.c) void;
extern fn curl_easy_escape(curl: ?*anyopaque, string: ?[*]const u8, length: c_int) callconv(.c) ?[*:0]u8;
extern fn curlx_memzero(buf: ?[*]u8, size: usize) callconv(.c) void;
extern fn curlx_str_assign(out: *Curl_str, str: ?[*]const u8, len: usize) callconv(.c) void;
extern fn curlx_str_until(linep: *[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_casecompare(str: *const Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_cmp(str: *const Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_passblanks(linep: *[*:0]const u8) callconv(.c) void;
extern fn Curl_ptrarray_init(pa: *ptrarray) callconv(.c) void;
extern fn Curl_ptrarray_clear(pa: *ptrarray) callconv(.c) void;
extern fn Curl_ptrarray_add(pa: *ptrarray, ptr: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_ptrarray_remove(pa: *ptrarray, idx: u32) callconv(.c) ?*anyopaque;
extern fn curl_msnprintf(buffer: ?[*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn Curl_slist_append_nodup(list: ?*curl_slist, data: ?[*:0]const u8) callconv(.c) ?*curl_slist;
extern fn curl_slist_append(list: ?*curl_slist, data: ?[*:0]const u8) callconv(.c) ?*curl_slist;
extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;

// ============================================================================
// 1. lib/http_aws_sigv4.c
// ============================================================================

const TIMESTAMP_SIZE: usize = 17;
const CURL_SHA256_DIGEST_LENGTH: usize = 32;
const SHA256_HEX_LENGTH: usize = (2 * CURL_SHA256_DIGEST_LENGTH) + 1;
const MAX_QUERY_COMPONENTS: usize = 128;
const MAX_SIGV4_LEN: usize = 64;
const DATE_HDR_KEY_LEN: usize = MAX_SIGV4_LEN + "X--Date".len + 1;
const DATE_FULL_HDR_LEN: usize = DATE_HDR_KEY_LEN + TIMESTAMP_SIZE + 1;
const CONTENT_SHA256_KEY_LEN: usize = MAX_SIGV4_LEN + "X--Content-Sha256".len + 1;
const CONTENT_SHA256_HDR_LEN: usize = CONTENT_SHA256_KEY_LEN + 2 + SHA256_HEX_LENGTH;
const CURL_MAX_HTTP_HEADER: usize = 100 * 1024;
const S3_UNSIGNED_PAYLOAD = "UNSIGNED-PAYLOAD";

pub const Curl_HttpReq = c_uint;
pub const HTTPREQ_GET: Curl_HttpReq = 0;
pub const HTTPREQ_POST: Curl_HttpReq = 1;
pub const HTTPREQ_POST_FORM: Curl_HttpReq = 2;
pub const HTTPREQ_POST_MIME: Curl_HttpReq = 3;
pub const HTTPREQ_PUT: Curl_HttpReq = 4;
pub const HTTPREQ_HEAD: Curl_HttpReq = 5;

const Pair = extern struct {
    key: dynbuf,
    value: dynbuf,
};

const StructTm = extern struct {
    tm_sec: c_int = 0,
    tm_min: c_int = 0,
    tm_hour: c_int = 0,
    tm_mday: c_int = 0,
    tm_mon: c_int = 0,
    tm_year: c_int = 0,
    tm_wday: c_int = 0,
    tm_yday: c_int = 0,
    tm_isdst: c_int = 0,
    _extra: [32]u8 = @splat(0),
};

extern const Curl_HMAC_SHA256: crypto.HMAC_params;
extern fn Curl_sha256it(outbuffer: [*]u8, input: ?[*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_checkheaders(data: ?*anyopaque, thisheader: [*]const u8, thislen: usize) callconv(.c) ?[*:0]u8;
extern fn Curl_http_method(data: ?*anyopaque, method: *?[*:0]const u8, reqp: *Curl_HttpReq) callconv(.c) void;
extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_aws_sigv4_dispatch(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn getenv(name: [*:0]const u8) callconv(.c) ?[*:0]const u8;

const libc_time = struct {
    extern "c" fn _time64(tloc: ?*i64) callconv(.c) i64;
    extern "c" fn time(tloc: ?*time_t) callconv(.c) time_t;

    fn now() time_t {
        if (builtin.os.tag == .windows) {
            return _time64(null);
        } else {
            return time(null);
        }
    }
};

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

inline fn isAlnum(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
}

inline fn isXdigit(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
}

inline fn hexVal(c: u8) u8 {
    if (c >= '0' and c <= '9') return c - '0';
    if (c >= 'a' and c <= 'f') return c - 'a' + 10;
    if (c >= 'A' and c <= 'F') return c - 'A' + 10;
    return 0;
}

inline fn isUrlPuntcs(c: u8) bool {
    return c == '-' or c == '.' or c == '_' or c == '~';
}

inline fn isReservedChar(c: u8) bool {
    return isAlnum(c) or isUrlPuntcs(c);
}

fn sha256ToHex(dst: [*]u8, sha: [*]const u8) void {
    Curl_hexencode(sha, CURL_SHA256_DIGEST_LENGTH, dst, SHA256_HEX_LENGTH);
}

fn findDateHdr(data: ?*anyopaque, sig_hdr: [*:0]const u8) ?[*:0]u8 {
    if (Curl_checkheaders(data, sig_hdr, std.mem.len(sig_hdr))) |tmp| {
        return tmp;
    }
    return Curl_checkheaders(data, "Date", 4);
}

fn trimHeaders(head: ?*curl_slist) void {
    var l_opt = head;
    while (l_opt) |l| : (l_opt = l.next) {
        const data_ptr = l.data orelse continue;
        var colon: usize = 0;
        while (data_ptr[colon] != 0 and data_ptr[colon] != ':') : (colon += 1) {}
        primitives.Curl_strntolower(data_ptr, data_ptr, colon);

        if (data_ptr[colon] == 0)
            continue;

        var value: [*:0]const u8 = data_ptr + colon + 1;
        var store: [*]u8 = data_ptr + colon + 1;

        curlx_str_passblanks(&value);

        while (value[0] != 0) {
            var space: usize = 0;
            while (isBlank(value[0])) {
                value += 1;
                space += 1;
            }
            if (space != 0) {
                if (value[0] != 0) {
                    store[0] = ' ';
                    store += 1;
                }
            } else {
                store[0] = value[0];
                store += 1;
                value += 1;
            }
        }
        store[0] = 0;
    }
}

fn pairArrayFree(pair_array: [*]Pair, num_elements: usize) void {
    for (0..num_elements) |idx| {
        containers.curlx_dyn_free(&pair_array[idx].key);
        containers.curlx_dyn_free(&pair_array[idx].value);
    }
}

fn dynArrayFree(db: [*]dynbuf, num_elements: usize) void {
    for (0..num_elements) |idx| {
        containers.curlx_dyn_free(&db[idx]);
    }
}

fn splitToDynArray(
    source: [*:0]const u8,
    db: *[MAX_QUERY_COMPONENTS]dynbuf,
    num_splits_out: *usize,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const len = std.mem.len(source);
    var start: usize = 0;
    var segment_length: usize = 0;
    var index: usize = 0;
    var num_splits: usize = 0;

    for (0..len) |pos| {
        if (source[pos] == '&') {
            if (segment_length != 0) {
                containers.curlx_dyn_init(&db[index], segment_length + 1);
                result = containers.curlx_dyn_addn(&db[index], source + start, segment_length);
                if (result != CURLE_OK) {
                    num_splits_out.* = num_splits;
                    return result;
                }

                segment_length = 0;
                index += 1;
                num_splits += 1;
                if (num_splits == MAX_QUERY_COMPONENTS) {
                    num_splits_out.* = num_splits;
                    return CURLE_TOO_LARGE;
                }
            }
            start = pos + 1;
        } else {
            segment_length += 1;
        }
    }

    if (segment_length != 0) {
        containers.curlx_dyn_init(&db[index], segment_length + 1);
        result = containers.curlx_dyn_addn(&db[index], source + start, segment_length);
        if (result == CURLE_OK) {
            num_splits += 1;
            if (num_splits == MAX_QUERY_COMPONENTS) {
                result = CURLE_TOO_LARGE;
            }
        }
    }

    num_splits_out.* = num_splits;
    return result;
}

fn addPercentHex(db: *dynbuf, byte: u8) CURLcode {
    const hex = "0123456789ABCDEF";
    const buf = [3]u8{ '%', hex[byte >> 4], hex[byte & 0x0f] };
    return containers.curlx_dyn_addn(db, &buf, 3);
}

fn uriEncodePath(original_path: *const Curl_str, new_path: *dynbuf) CURLcode {
    const p = original_path.str orelse return CURLE_OK;
    for (0..original_path.len) |i| {
        const c = p[i];
        const result = if (isReservedChar(c) or c == '/')
            containers.curlx_dyn_addn(new_path, p + i, 1)
        else
            addPercentHex(new_path, c);
        if (result != CURLE_OK)
            return result;
    }
    return CURLE_OK;
}

fn normalizeQuery(string_in: [*]const u8, len_in: usize, db: *dynbuf) CURLcode {
    var string = string_in;
    var len = len_in;
    var result: CURLcode = CURLE_OK;

    while (len != 0 and result == CURLE_OK) {
        var in_byte: u8 = string[0];
        if (in_byte == '%' and len > 2 and isXdigit(string[1]) and isXdigit(string[2])) {
            in_byte = (hexVal(string[1]) << 4) | hexVal(string[2]);
            string += 3;
            len -= 3;
            if (in_byte == '+') {
                result = containers.curlx_dyn_addn(db, "%2B", 3);
                continue;
            }
        } else {
            string += 1;
            len -= 1;
        }

        if (isReservedChar(in_byte)) {
            const b = [1]u8{in_byte};
            result = containers.curlx_dyn_addn(db, &b, 1);
        } else if (in_byte == '+') {
            result = containers.curlx_dyn_add(db, "%20");
        } else {
            result = addPercentHex(db, in_byte);
        }
    }
    return result;
}

fn shouldUrlencode(service_name: *const Curl_str) bool {
    if (curlx_str_cmp(service_name, "s3") != 0 or
        curlx_str_cmp(service_name, "s3express") != 0 or
        curlx_str_cmp(service_name, "s3-outposts") != 0 or
        curlx_str_cmp(service_name, "s3-object-lambda") != 0)
    {
        return false;
    }
    return true;
}

fn findChar(s: [*:0]const u8, ch: u8) ?[*:0]u8 {
    var p: [*:0]u8 = @constCast(s);
    while (p[0] != 0) : (p += 1) {
        if (p[0] == ch)
            return p;
    }
    return null;
}

fn compareHeaderNames(a: [*:0]const u8, b: [*:0]const u8) c_int {
    const colon_a = findChar(a, ':');
    const colon_b = findChar(b, ':');

    const len_a: usize = if (colon_a) |ca| @intFromPtr(ca) - @intFromPtr(a) else std.mem.len(a);
    const len_b: usize = if (colon_b) |cb| @intFromPtr(cb) - @intFromPtr(b) else std.mem.len(b);
    const min_len = @min(len_a, len_b);

    for (0..min_len) |i| {
        if (a[i] != b[i]) {
            return if (a[i] < b[i]) -1 else 1;
        }
    }
    if (len_a == len_b) return 0;
    return if (len_a < len_b) -1 else 1;
}

fn mergeOneDuplicateHeader(curr: *curl_slist, next: *curl_slist, curr_data: [*:0]const u8, next_data: [*:0]const u8) error{ OutOfMemory, BadArgument }!void {
    var buf: dynbuf = undefined;
    containers.curlx_dyn_init(&buf, CURL_MAX_HTTP_HEADER);
    errdefer containers.curlx_dyn_free(&buf);

    if (containers.curlx_dyn_add(&buf, curr_data) != CURLE_OK)
        return error.OutOfMemory;

    const colon_next = findChar(next_data, ':') orelse return error.BadArgument;
    const val_next: [*:0]const u8 = colon_next + 1;

    if (containers.curlx_dyn_addn(&buf, ",", 1) != CURLE_OK)
        return error.OutOfMemory;

    if (containers.curlx_dyn_add(&buf, val_next) != CURLE_OK)
        return error.OutOfMemory;

    mem.free(curr.data);
    curr.data = containers.curlx_dyn_ptr(&buf);

    curr.next = next.next;
    mem.free(next.data);
    mem.freeTyped(next);
}

fn mergeDuplicateHeaders(head: ?*curl_slist) CURLcode {
    var curr_opt = head;
    while (curr_opt) |curr| {
        const next = curr.next orelse break;
        const curr_data = curr.data orelse break;
        const next_data = next.data orelse break;

        if (compareHeaderNames(curr_data, next_data) == 0) {
            mergeOneDuplicateHeader(curr, next, curr_data, next_data) catch |err| return switch (err) {
                error.OutOfMemory => CURLE_OUT_OF_MEMORY,
                error.BadArgument => CURLE_BAD_FUNCTION_ARGUMENT,
            };
        } else {
            curr_opt = curr.next;
        }
    }
    return CURLE_OK;
}

fn makeHeaders(
    data: ?*anyopaque,
    http_host: ?[*:0]const u8,
    custom_headers: ?*curl_slist,
    timestamp: *[TIMESTAMP_SIZE - 1:0]u8,
    provider1: [*]const u8,
    plen: usize,
    date_header: *?[*:0]u8,
    content_sha256_header: [*:0]const u8,
    canonical_headers: *dynbuf,
    signed_headers: *dynbuf,
) CURLcode {
    makeHeadersInner(
        data,
        http_host,
        custom_headers,
        timestamp,
        provider1,
        plen,
        date_header,
        content_sha256_header,
        canonical_headers,
        signed_headers,
    ) catch return CURLE_OUT_OF_MEMORY;
    return CURLE_OK;
}

fn makeHeadersInner(
    data: ?*anyopaque,
    http_host: ?[*:0]const u8,
    custom_headers: ?*curl_slist,
    timestamp: *[TIMESTAMP_SIZE - 1:0]u8,
    provider1: [*]const u8,
    plen: usize,
    date_header: *?[*:0]u8,
    content_sha256_header: [*:0]const u8,
    canonical_headers: *dynbuf,
    signed_headers: *dynbuf,
) error{OutOfMemory}!void {
    var date_hdr_key: [DATE_HDR_KEY_LEN - 1:0]u8 = @splat(0);
    var date_full_hdr: [DATE_FULL_HDR_LEN - 1:0]u8 = @splat(0);
    var head: ?*curl_slist = null;
    defer curl_slist_free_all(head);

    _ = curl_msnprintf(
        &date_hdr_key,
        DATE_HDR_KEY_LEN,
        "X-%.*s-Date",
        @as(c_int, @intCast(plen)),
        provider1,
    );
    primitives.Curl_strntolower(date_hdr_key[2..].ptr, provider1, plen);
    date_hdr_key[2] = primitives.rawToupper(provider1[0]);

    _ = curl_msnprintf(
        &date_full_hdr,
        DATE_FULL_HDR_LEN,
        "x-%.*s-date:%s",
        @as(c_int, @intCast(plen)),
        provider1,
        @as([*:0]const u8, timestamp),
    );
    primitives.Curl_strntolower(date_full_hdr[2..].ptr, provider1, plen);

    if (Curl_checkheaders(data, "Host", 4) == null) {
        if (http_host) |hh| {
            const fullhost = mem.strdup(hh) orelse return error.OutOfMemory;
            head = Curl_slist_append_nodup(null, fullhost) orelse {
                mem.freeTyped(fullhost);
                return error.OutOfMemory;
            };
        }
    }

    if (content_sha256_header[0] != 0) {
        head = curl_slist_append(head, content_sha256_header) orelse return error.OutOfMemory;
    }

    var l_opt = custom_headers;
    while (l_opt) |l| : (l_opt = l.next) {
        const l_data = l.data orelse continue;
        var sep = findChar(l_data, ':');
        if (sep == null)
            sep = findChar(l_data, ';');
        const sep_ptr = sep orelse continue;
        if (sep_ptr[0] == ':' and sep_ptr[1] == 0)
            continue;

        var ptr: [*:0]const u8 = sep_ptr + 1;
        while (isBlank(ptr[0])) : (ptr += 1) {}
        if (ptr[0] == 0 and @intFromPtr(ptr) != @intFromPtr(sep_ptr + 1))
            continue;

        const dupdata = mem.strdup(l_data) orelse return error.OutOfMemory;
        const sep_offset = @intFromPtr(sep_ptr) - @intFromPtr(l_data);
        dupdata[sep_offset] = ':';
        head = Curl_slist_append_nodup(head, dupdata) orelse {
            mem.freeTyped(dupdata);
            return error.OutOfMemory;
        };
    }

    trimHeaders(head);

    const date_hdr_key_z: [*:0]const u8 = &date_hdr_key;
    const date_full_hdr_z: [*:0]const u8 = &date_full_hdr;
    date_header.* = findDateHdr(data, date_hdr_key_z);
    if (date_header.* == null) {
        head = curl_slist_append(head, date_full_hdr_z) orelse return error.OutOfMemory;
        date_header.* = curl_maprintf(
            "%s: %s\r\n",
            date_hdr_key_z,
            @as([*:0]const u8, timestamp),
        ) orelse return error.OutOfMemory;
    } else {
        const dh = date_header.*.?;
        const colon = findChar(dh, ':') orelse {
            date_header.* = null;
            return error.OutOfMemory;
        };
        var value: [*:0]const u8 = colon + 1;
        curlx_str_passblanks(&value);
        var endp: [*:0]const u8 = value;
        while (endp[0] != 0 and isAlnum(endp[0])) : (endp += 1) {}
        if ((@intFromPtr(endp) - @intFromPtr(value)) == TIMESTAMP_SIZE - 1) {
            @memcpy(timestamp[0 .. TIMESTAMP_SIZE - 1], value[0 .. TIMESTAMP_SIZE - 1]);
            timestamp[TIMESTAMP_SIZE - 1] = 0;
        } else {
            timestamp[0] = 0;
        }
        date_header.* = null;
    }

    var again = true;
    while (again) {
        again = false;
        var it = head;
        while (it) |curr| : (it = curr.next) {
            if (curr.next) |next| {
                if (compareHeaderNames(curr.data.?, next.data.?) > 0) {
                    const tmp = curr.data;
                    curr.data = next.data;
                    next.data = tmp;
                    again = true;
                }
            }
        }
    }

    if (mergeDuplicateHeaders(head) != CURLE_OK) {
        return error.OutOfMemory;
    }

    var it = head;
    while (it) |curr| : (it = curr.next) {
        const curr_data = curr.data.?;
        if (containers.curlx_dyn_add(canonical_headers, curr_data) != CURLE_OK or
            containers.curlx_dyn_add(canonical_headers, "\n") != CURLE_OK)
        {
            return error.OutOfMemory;
        }

        if (findChar(curr_data, ':')) |tmp| {
            tmp[0] = 0;
        }

        if (curr != head) {
            if (containers.curlx_dyn_add(signed_headers, ";") != CURLE_OK) {
                return error.OutOfMemory;
            }
        }
        if (containers.curlx_dyn_add(signed_headers, curr_data) != CURLE_OK) {
            return error.OutOfMemory;
        }
    }
}

fn parseContentShaHdr(
    data: ?*anyopaque,
    provider1: [*]const u8,
    plen: usize,
    value_len: *usize,
) ?[*]const u8 {
    var key: [CONTENT_SHA256_KEY_LEN]u8 = @splat(0);
    const key_len_int = curl_msnprintf(
        &key,
        key.len,
        "x-%.*s-content-sha256",
        @as(c_int, @intCast(plen)),
        provider1,
    );
    if (key_len_int <= 0) return null;
    const key_len: usize = @intCast(key_len_int);

    const hdr = Curl_checkheaders(data, &key, key_len) orelse return null;
    const colon = findChar(hdr, ':') orelse return null;
    var value: [*:0]const u8 = colon + 1;
    curlx_str_passblanks(&value);

    var len = std.mem.len(value);
    while (len > 0 and isBlank(value[len - 1])) : (len -= 1) {}

    value_len.* = len;
    return value;
}

fn calcPayloadHash(
    postfields: ?[*:0]const u8,
    postfieldsize: i64,
    sha_hash: *[CURL_SHA256_DIGEST_LENGTH]u8,
    sha_hex: *[SHA256_HEX_LENGTH - 1:0]u8,
) CURLcode {
    var post_data_len: usize = 0;
    var post_ptr: ?[*]const u8 = null;
    if (postfields) |pf| {
        post_ptr = pf;
        if (postfieldsize < 0) {
            post_data_len = std.mem.len(pf);
        } else {
            post_data_len = @intCast(postfieldsize);
        }
    }
    const result = Curl_sha256it(sha_hash, post_ptr, post_data_len);
    if (result == CURLE_OK) {
        sha256ToHex(sha_hex, sha_hash);
    }
    return result;
}

fn calcS3PayloadHash(
    httpreq: Curl_HttpReq,
    postfields: ?[*:0]const u8,
    postfieldsize: i64,
    filesize: i64,
    provider1: [*]const u8,
    plen: usize,
    sha_hash: *[CURL_SHA256_DIGEST_LENGTH]u8,
    sha_hex: *[SHA256_HEX_LENGTH - 1:0]u8,
    header: *[CONTENT_SHA256_HDR_LEN + 1:0]u8,
) CURLcode {
    const empty_method = (httpreq == HTTPREQ_GET or httpreq == HTTPREQ_HEAD);
    const empty_payload = (empty_method or filesize == 0);
    const post_payload = (httpreq == HTTPREQ_POST and postfields != null);

    if (empty_payload or post_payload) {
        const result = calcPayloadHash(postfields, postfieldsize, sha_hash, sha_hex);
        if (result != CURLE_OK)
            return result;
    } else {
        @memcpy(sha_hex[0..S3_UNSIGNED_PAYLOAD.len], S3_UNSIGNED_PAYLOAD);
        sha_hex[S3_UNSIGNED_PAYLOAD.len] = 0;
    }

    _ = curl_msnprintf(
        header,
        CONTENT_SHA256_HDR_LEN,
        "x-%.*s-content-sha256: %s",
        @as(c_int, @intCast(plen)),
        provider1,
        @as([*:0]const u8, sha_hex),
    );
    return CURLE_OK;
}

fn comparePair(a: *const Pair, b: *const Pair) c_int {
    const aa_key_len = containers.curlx_dyn_len(&a.key);
    const bb_key_len = containers.curlx_dyn_len(&b.key);
    const aa_val_len = containers.curlx_dyn_len(&a.value);
    const bb_val_len = containers.curlx_dyn_len(&b.value);

    if (aa_key_len == 0 and bb_key_len == 0) return 0;
    if (aa_key_len == 0) return -1;
    if (bb_key_len == 0) return 1;

    const key_a = std.mem.span(containers.curlx_dyn_ptr(&a.key).?);
    const key_b = std.mem.span(containers.curlx_dyn_ptr(&b.key).?);
    switch (std.mem.order(u8, key_a, key_b)) {
        .lt => return -1,
        .gt => return 1,
        .eq => {},
    }

    if (aa_val_len == 0 and bb_val_len == 0) return 0;
    if (aa_val_len == 0) return -1;
    if (bb_val_len == 0) return 1;

    const val_a = std.mem.span(containers.curlx_dyn_ptr(&a.value).?);
    const val_b = std.mem.span(containers.curlx_dyn_ptr(&b.value).?);
    return switch (std.mem.order(u8, val_a, val_b)) {
        .lt => -1,
        .gt => 1,
        .eq => 0,
    };
}

pub export fn canon_path(
    q: [*:0]const u8,
    len: usize,
    new_path: *dynbuf,
    do_uri_encode: bool,
) callconv(.c) CURLcode {
    var original_path: Curl_str = undefined;
    curlx_str_assign(&original_path, q, len);

    var result = if (do_uri_encode)
        uriEncodePath(&original_path, new_path)
    else
        containers.curlx_dyn_addn(new_path, q, len);

    if (result == CURLE_OK and containers.curlx_dyn_len(new_path) == 0) {
        result = containers.curlx_dyn_add(new_path, "/");
    }
    return result;
}

pub export fn canon_query(
    query: ?[*:0]const u8,
    dq: *dynbuf,
) callconv(.c) CURLcode {
    const q = query orelse return CURLE_OK;

    var query_array: [MAX_QUERY_COMPONENTS]dynbuf = undefined;
    var encoded_query_array: [MAX_QUERY_COMPONENTS]Pair = undefined;
    var num_query_components: usize = 0;
    var counted_query_components: usize = 0;

    var result = splitToDynArray(q, &query_array, &num_query_components);
    if (result != CURLE_OK) {
        dynArrayFree(&query_array, num_query_components);
        return result;
    }

    for (0..num_query_components) |index| {
        const query_part_len = containers.curlx_dyn_len(&query_array[index]);
        const query_part = containers.curlx_dyn_ptr(&query_array[index]).?;
        const in_key: [*:0]const u8 = query_part;
        const offset = findChar(query_part, '=');
        const in_key_len: usize = if (offset) |off|
            @intFromPtr(off) - @intFromPtr(in_key)
        else
            std.mem.len(in_key);

        containers.curlx_dyn_init(&encoded_query_array[index].key, (query_part_len * 3) + 1);
        containers.curlx_dyn_init(&encoded_query_array[index].value, (query_part_len * 3) + 1);
        counted_query_components += 1;

        result = normalizeQuery(in_key, in_key_len, &encoded_query_array[index].key);
        if (result != CURLE_OK)
            break;

        if (offset) |off| {
            if (@intFromPtr(off) != @intFromPtr(query_part) + query_part_len - 1) {
                const in_value: [*]const u8 = off + 1;
                const in_value_len = (@intFromPtr(query_part) + query_part_len) - @intFromPtr(in_value);
                result = normalizeQuery(in_value, in_value_len, &encoded_query_array[index].value);
            } else {
                containers.curlx_dyn_init(&encoded_query_array[index].value, 2);
                result = containers.curlx_dyn_addn(&encoded_query_array[index].value, "", 1);
            }
        } else {
            containers.curlx_dyn_init(&encoded_query_array[index].value, 2);
            result = containers.curlx_dyn_addn(&encoded_query_array[index].value, "", 1);
        }
        if (result != CURLE_OK)
            break;
    }

    if (result == CURLE_OK) {
        // Insertion sort matching qsort behavior on Pair array
        var i: usize = 1;
        while (i < num_query_components) : (i += 1) {
            const tmp = encoded_query_array[i];
            var j = i;
            while (j > 0 and comparePair(&encoded_query_array[j - 1], &tmp) > 0) : (j -= 1) {
                encoded_query_array[j] = encoded_query_array[j - 1];
            }
            encoded_query_array[j] = tmp;
        }

        for (0..num_query_components) |index| {
            if (index != 0) {
                result = containers.curlx_dyn_addn(dq, "&", 1);
            }
            if (result == CURLE_OK) {
                const key_ptr = containers.curlx_dyn_ptr(&encoded_query_array[index].key).?;
                const value_ptr = containers.curlx_dyn_ptr(&encoded_query_array[index].value);
                const vlen = containers.curlx_dyn_len(&encoded_query_array[index].value);
                result = containers.curlx_dyn_add(dq, key_ptr);
                if (result == CURLE_OK) {
                    result = containers.curlx_dyn_addn(dq, "=", 1);
                }
                if (result == CURLE_OK and value_ptr != null and vlen != 0) {
                    result = containers.curlx_dyn_add(dq, value_ptr.?);
                }
            }
            if (result != CURLE_OK)
                break;
        }
    }

    if (counted_query_components != 0)
        pairArrayFree(&encoded_query_array, counted_query_components);
    dynArrayFree(&query_array, num_query_components);
    return result;
}

fn parseSigv4Params(
    data: ?*anyopaque,
    provider_opt: ?[*:0]const u8,
    hostname: ?[*:0]const u8,
    provider0: *Curl_str,
    provider1: *Curl_str,
    region: *Curl_str,
    service: *Curl_str,
) CURLcode {
    var line: [*:0]const u8 = if (provider_opt != null and provider_opt.?[0] != 0)
        provider_opt.?
    else
        "aws:amz";

    if (curlx_str_until(&line, provider0, MAX_SIGV4_LEN, ':') != 0) {
        Curl_failf(data, "first aws-sigv4 provider cannot be empty");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    if (curlx_str_single(&line, ':') != 0 or
        curlx_str_until(&line, provider1, MAX_SIGV4_LEN, ':') != 0)
    {
        provider1.* = provider0.*;
    } else if (curlx_str_single(&line, ':') != 0 or
        curlx_str_until(&line, region, MAX_SIGV4_LEN, ':') != 0 or
        curlx_str_single(&line, ':') != 0 or
        curlx_str_until(&line, service, MAX_SIGV4_LEN, ':') != 0)
    {
        // nothing to do
    }

    if (service.len == 0) {
        var p: [*:0]const u8 = hostname orelse "";
        if (curlx_str_until(&p, service, MAX_SIGV4_LEN, '.') != 0 or
            curlx_str_single(&p, '.') != 0)
        {
            Curl_failf(data, "aws-sigv4: service missing in parameters and hostname");
            return CURLE_URL_MALFORMAT;
        }

        Curl_infof(
            data,
            "aws_sigv4: picked service %.*s from host",
            @as(c_int, @intCast(service.len)),
            service.str.?,
        );

        if (region.len == 0) {
            if (curlx_str_until(&p, region, MAX_SIGV4_LEN, '.') != 0 or
                curlx_str_single(&p, '.') != 0)
            {
                Curl_failf(data, "aws-sigv4: region missing in parameters and hostname");
                return CURLE_URL_MALFORMAT;
            }
            Curl_infof(
                data,
                "aws_sigv4: picked region %.*s from host",
                @as(c_int, @intCast(region.len)),
                region.str.?,
            );
        }
    }
    return CURLE_OK;
}

fn getPayloadHash(
    data: ?*anyopaque,
    httpreq: Curl_HttpReq,
    postfields: ?[*:0]const u8,
    postfieldsize: i64,
    filesize: i64,
    provider0: *const Curl_str,
    provider1: *const Curl_str,
    service: *const Curl_str,
    sha_hash: *[CURL_SHA256_DIGEST_LENGTH]u8,
    sha_hex: *[SHA256_HEX_LENGTH - 1:0]u8,
    content_sha256_hdr: *[CONTENT_SHA256_HDR_LEN + 1:0]u8,
    payload_hash_out: *?[*]const u8,
    payload_hash_len_out: *usize,
) CURLcode {
    payload_hash_out.* = parseContentShaHdr(data, provider1.str.?, provider1.len, payload_hash_len_out);
    if (payload_hash_out.* == null) {
        const sign_as_s3 = (curlx_str_casecompare(provider0, "aws") != 0) and
            (curlx_str_casecompare(service, "s3") != 0);

        const result = if (sign_as_s3)
            calcS3PayloadHash(
                httpreq,
                postfields,
                postfieldsize,
                filesize,
                provider1.str.?,
                provider1.len,
                sha_hash,
                sha_hex,
                content_sha256_hdr,
            )
        else
            calcPayloadHash(postfields, postfieldsize, sha_hash, sha_hex);

        if (result != CURLE_OK)
            return result;

        payload_hash_out.* = sha_hex;
        payload_hash_len_out.* = std.mem.len(@as([*:0]const u8, sha_hex));
    }
    return CURLE_OK;
}

fn getTimestamp(timestamp: *[TIMESTAMP_SIZE - 1:0]u8) CURLcode {
    const clock: time_t = if (getenv("CURL_FORCETIME") != null) 0 else libc_time.now();
    var tm: StructTm = .{};
    const result = curlx_time_net.curlx_gmtime(clock, &tm);
    if (result != CURLE_OK)
        return result;

    const written = curl_msnprintf(
        timestamp,
        TIMESTAMP_SIZE,
        "%04d%02d%02dT%02d%02d%02dZ",
        tm.tm_year + 1900,
        tm.tm_mon + 1,
        tm.tm_mday,
        tm.tm_hour,
        tm.tm_min,
        tm.tm_sec,
    );
    if (written != TIMESTAMP_SIZE - 1)
        return CURLE_OUT_OF_MEMORY;
    return CURLE_OK;
}

pub export fn Curl_output_aws_sigv4_ex(
    data: ?*anyopaque,
    path_as_is: bool,
    provider_opt: ?[*:0]const u8,
    origin_hostname: ?[*:0]const u8,
    http_host: ?[*:0]const u8,
    custom_headers: ?*curl_slist,
    postfields: ?[*:0]const u8,
    postfieldsize: i64,
    filesize: i64,
    up_query: ?[*:0]const u8,
    up_path: ?[*:0]const u8,
    user_in: [*:0]const u8,
    passwd_in: [*:0]const u8,
    hd_auth: *?[*:0]u8,
    auth_done: *bool,
) callconv(.c) CURLcode {
    var provider0: Curl_str = .{ .str = null, .len = 0 };
    var provider1: Curl_str = .{ .str = null, .len = 0 };
    var region: Curl_str = .{ .str = null, .len = 0 };
    var service: Curl_str = .{ .str = null, .len = 0 };
    var timestamp: [TIMESTAMP_SIZE - 1:0]u8 = @splat(0);
    var date: [8:0]u8 = @splat(0);
    var canonical_headers: dynbuf = undefined;
    var signed_headers: dynbuf = undefined;
    var date_header: ?[*:0]u8 = null;
    var httpreq: Curl_HttpReq = HTTPREQ_GET;
    var method: ?[*:0]const u8 = null;
    var payload_hash: ?[*]const u8 = null;
    var payload_hash_len: usize = 0;
    var sha_hash: [CURL_SHA256_DIGEST_LENGTH]u8 = @splat(0);
    var sha_hex: [SHA256_HEX_LENGTH - 1:0]u8 = @splat(0);
    var content_sha256_hdr: [CONTENT_SHA256_HDR_LEN + 1:0]u8 = @splat(0);
    var canonical_request: ?[*:0]u8 = null;
    var request_type: ?[*:0]u8 = null;
    var credential_scope: ?[*:0]u8 = null;
    var str_to_sign: ?[*:0]u8 = null;

    if (path_as_is) {
        Curl_failf(data, "Cannot use sigv4 authentication with path-as-is flag");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    if (Curl_checkheaders(data, "Authorization", 13) != null)
        return CURLE_OK;

    containers.curlx_dyn_init(&canonical_headers, CURL_MAX_HTTP_HEADER);
    containers.curlx_dyn_init(&signed_headers, CURL_MAX_HTTP_HEADER);
    defer {
        containers.curlx_dyn_free(&canonical_headers);
        containers.curlx_dyn_free(&signed_headers);
        mem.free(canonical_request);
        mem.free(request_type);
        mem.free(credential_scope);
        mem.free(str_to_sign);
        mem.free(date_header);
    }

    var result = parseSigv4Params(
        data,
        provider_opt,
        origin_hostname,
        &provider0,
        &provider1,
        &region,
        &service,
    );
    if (result == CURLE_OK) {
        Curl_http_method(data, &method, &httpreq);
        result = getPayloadHash(
            data,
            httpreq,
            postfields,
            postfieldsize,
            filesize,
            &provider0,
            &provider1,
            &service,
            &sha_hash,
            &sha_hex,
            &content_sha256_hdr,
            &payload_hash,
            &payload_hash_len,
        );
    }

    if (result == CURLE_OK)
        result = getTimestamp(&timestamp);

    if (result == CURLE_OK) {
        var canonical_query: dynbuf = undefined;
        var canonical_path: dynbuf = undefined;
        containers.curlx_dyn_init(&canonical_query, CURL_MAX_HTTP_HEADER);
        containers.curlx_dyn_init(&canonical_path, CURL_MAX_HTTP_HEADER);
        defer {
            containers.curlx_dyn_free(&canonical_query);
            containers.curlx_dyn_free(&canonical_path);
        }

        result = makeHeaders(
            data,
            http_host,
            custom_headers,
            &timestamp,
            provider1.str.?,
            provider1.len,
            &date_header,
            &content_sha256_hdr,
            &canonical_headers,
            &signed_headers,
        );
        if (result == CURLE_OK)
            result = canon_query(up_query, &canonical_query);
        if (result == CURLE_OK) {
            const path_str: [*:0]const u8 = up_path orelse "/";
            result = canon_path(
                path_str,
                std.mem.len(path_str),
                &canonical_path,
                shouldUrlencode(&service),
            );
        }
        if (result == CURLE_OK) {
            const cq_ptr: [*:0]const u8 = containers.curlx_dyn_ptr(&canonical_query) orelse "";
            canonical_request = curl_maprintf(
                "%s\n%s\n%s\n%s\n%s\n%.*s",
                method.?,
                containers.curlx_dyn_ptr(&canonical_path).?,
                cq_ptr,
                containers.curlx_dyn_ptr(&canonical_headers).?,
                containers.curlx_dyn_ptr(&signed_headers).?,
                @as(c_int, @intCast(payload_hash_len)),
                payload_hash.?,
            );
            if (canonical_request == null)
                result = CURLE_OUT_OF_MEMORY;
        }
    }

    if (result == CURLE_OK) {
        @memcpy(date[0..8], timestamp[0..8]);
        date[8] = 0;

        request_type = curl_maprintf(
            "%.*s4_request",
            @as(c_int, @intCast(provider0.len)),
            provider0.str.?,
        );
        if (request_type == null) {
            result = CURLE_OUT_OF_MEMORY;
        } else {
            primitives.Curl_strntolower(request_type.?, request_type.?, provider0.len);
            credential_scope = curl_maprintf(
                "%s/%.*s/%.*s/%s",
                @as([*:0]const u8, &date),
                @as(c_int, @intCast(region.len)),
                region.str.?,
                @as(c_int, @intCast(service.len)),
                service.str.?,
                request_type.?,
            );
            if (credential_scope == null) {
                result = CURLE_OUT_OF_MEMORY;
            } else {
                const creq = canonical_request.?;
                if (Curl_sha256it(&sha_hash, creq, std.mem.len(creq)) != CURLE_OK) {
                    result = CURLE_OUT_OF_MEMORY;
                } else {
                    sha256ToHex(&sha_hex, &sha_hash);
                    str_to_sign = curl_maprintf(
                        "%.*s4-HMAC-SHA256\n%s\n%s\n%s",
                        @as(c_int, @intCast(provider0.len)),
                        provider0.str.?,
                        @as([*:0]const u8, &timestamp),
                        credential_scope.?,
                        @as([*:0]const u8, &sha_hex),
                    );
                    if (str_to_sign == null) {
                        result = CURLE_OUT_OF_MEMORY;
                    } else {
                        primitives.Curl_strntoupper(str_to_sign.?, provider0.str.?, provider0.len);
                        Curl_infof(data, "aws_sigv4: String to sign (enclosed in []) - [%s]", str_to_sign.?);
                    }
                }
            }
        }
    }

    if (result == CURLE_OK) {
        const user_esc = curl_easy_escape(null, user_in, 0) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(user_esc);

        const secret = curl_maprintf(
            "%.*s4%s",
            @as(c_int, @intCast(provider0.len)),
            provider0.str.?,
            passwd_in,
        ) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(secret);

        primitives.Curl_strntoupper(secret, provider0.str.?, provider0.len);

        var sign0: [CURL_SHA256_DIGEST_LENGTH]u8 = @splat(0);
        var sign1: [CURL_SHA256_DIGEST_LENGTH]u8 = @splat(0);

        result = crypto.Curl_hmacit(&Curl_HMAC_SHA256, secret, std.mem.len(secret), &date, 8, &sign0);
        if (result != CURLE_OK) return result;
        result = crypto.Curl_hmacit(&Curl_HMAC_SHA256, &sign0, sign0.len, region.str.?, region.len, &sign1);
        if (result != CURLE_OK) return result;
        result = crypto.Curl_hmacit(&Curl_HMAC_SHA256, &sign1, sign1.len, service.str.?, service.len, &sign0);
        if (result != CURLE_OK) return result;
        const rt = request_type.?;
        result = crypto.Curl_hmacit(&Curl_HMAC_SHA256, &sign0, sign0.len, rt, std.mem.len(rt), &sign1);
        if (result != CURLE_OK) return result;
        const sts = str_to_sign.?;
        result = crypto.Curl_hmacit(&Curl_HMAC_SHA256, &sign1, sign1.len, sts, std.mem.len(sts), &sign0);
        if (result != CURLE_OK) return result;

        sha256ToHex(&sha_hex, &sign0);
        Curl_infof(data, "aws_sigv4: Signature - %s", @as([*:0]const u8, &sha_hex));

        const dh_str: [*:0]const u8 = date_header orelse "";
        const csha_str: [*:0]const u8 = &content_sha256_hdr;
        const csha_crlf: [*:0]const u8 = if (content_sha256_hdr[0] != 0) "\r\n" else "";

        const auth_headers = curl_maprintf(
            "Authorization: %.*s4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s\r\n%s%s%s",
            @as(c_int, @intCast(provider0.len)),
            provider0.str.?,
            user_esc,
            credential_scope.?,
            containers.curlx_dyn_ptr(&signed_headers).?,
            @as([*:0]const u8, &sha_hex),
            dh_str,
            csha_str,
            csha_crlf,
        ) orelse return CURLE_OUT_OF_MEMORY;

        primitives.Curl_strntoupper(auth_headers + "Authorization: ".len, provider0.str.?, provider0.len);

        mem.free(hd_auth.*);
        hd_auth.* = auth_headers;
        auth_done.* = true;
        result = CURLE_OK;
    }

    return result;
}

pub export fn Curl_output_aws_sigv4(data: ?*anyopaque) callconv(.c) CURLcode {
    return Curl_aws_sigv4_dispatch(data);
}

// ============================================================================
// 2. lib/curl_share.c
// ============================================================================

pub const CURL_GOOD_SHARE: c_uint = 0x7e117a1e;

pub const CURL_LOCK_DATA_NONE: c_uint = 0;
pub const CURL_LOCK_DATA_SHARE: c_uint = 1;
pub const CURL_LOCK_DATA_COOKIE: c_uint = 2;
pub const CURL_LOCK_DATA_DNS: c_uint = 3;
pub const CURL_LOCK_DATA_SSL_SESSION: c_uint = 4;
pub const CURL_LOCK_DATA_CONNECT: c_uint = 5;
pub const CURL_LOCK_DATA_PSL: c_uint = 6;
pub const CURL_LOCK_DATA_HSTS: c_uint = 7;

pub const CURL_LOCK_ACCESS_NONE: c_uint = 0;
pub const CURL_LOCK_ACCESS_SHARED: c_uint = 1;
pub const CURL_LOCK_ACCESS_SINGLE: c_uint = 2;

pub const CURLSHOPT_NONE: c_uint = 0;
pub const CURLSHOPT_SHARE: c_uint = 1;
pub const CURLSHOPT_UNSHARE: c_uint = 2;
pub const CURLSHOPT_LOCKFUNC: c_uint = 3;
pub const CURLSHOPT_UNLOCKFUNC: c_uint = 4;
pub const CURLSHOPT_USERDATA: c_uint = 5;

pub const curl_lock_function = *const fn (
    handle: ?*anyopaque,
    data: c_uint,
    locktype: c_uint,
    userptr: ?*anyopaque,
) callconv(.c) void;

pub const curl_unlock_function = *const fn (
    handle: ?*anyopaque,
    data: c_uint,
    userptr: ?*anyopaque,
) callconv(.c) void;

pub const Curl_dnscache = extern struct {
    entries: collections.Curl_hash,
};

pub const cpool_struct = extern struct {
    conns: collections.uint32_tbl,
    idles: collections.uint32_bset,
    dest2bundle: collections.Curl_hash,
    next_connection_id: i64,
    next_easy_id: i64,
    last_cleanup: Curltime,
    share: ?*Curl_share,
    flags: u8,

    pub inline fn isInitialized(self: *const @This()) bool {
        return (self.flags & 0x02) != 0;
    }
};

pub const Curl_share = extern struct {
    magic: c_uint,
    specifier: c_uint,
    ref_count: u32,
    has_been_shared: c_int,
    lockfunc: ?curl_lock_function,
    unlockfunc: ?curl_unlock_function,
    clientdata: ?*anyopaque,
    admin: ?*anyopaque,
    cookies: ?*anyopaque,
    hsts: ?*anyopaque,
    ssl_scache: ?*anyopaque,
    dnscache: Curl_dnscache,
    cpool: cpool_struct,
    psl: threads_psl.PslCache,
    lock: threads_psl.CurlMutex,
};

extern fn curl_easy_init() callconv(.c) ?*anyopaque;
extern fn Curl_close(datap: *?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cpool_init(cpool: *cpool_struct, share: *Curl_share, size: usize) callconv(.c) void;
extern fn Curl_cpool_destroy(cpool: *cpool_struct, admin: ?*anyopaque) callconv(.c) void;
extern fn Curl_dnscache_init(dns: *Curl_dnscache, size: usize) callconv(.c) void;
extern fn Curl_dnscache_destroy(dns: *Curl_dnscache) callconv(.c) void;
extern fn Curl_cookie_init() callconv(.c) ?*anyopaque;
extern fn Curl_cookie_cleanup(c: ?*anyopaque) callconv(.c) void;
extern fn Curl_detach_connection(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_share_init_admin(admin: ?*anyopaque) callconv(.c) void;
extern fn Curl_share_hsts_init(phsts: *?*anyopaque) callconv(.c) CURLSHcode;
extern fn Curl_share_hsts_cleanup(phsts: *?*anyopaque) callconv(.c) void;
extern fn Curl_share_ssl_scache_init(pscache: *?*anyopaque) callconv(.c) CURLSHcode;
extern fn Curl_share_ssl_scache_cleanup(pscache: *?*anyopaque) callconv(.c) void;
extern fn Curl_share_get_easy_share(data: ?*anyopaque) callconv(.c) ?*Curl_share;
extern fn Curl_share_easy_unlink_dispatch(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_share_easy_link_dispatch(data: ?*anyopaque, share: ?*Curl_share) callconv(.c) CURLcode;

const share_mutex = struct {
    extern "kernel32" fn InitializeCriticalSectionEx(
        lpCriticalSection: *anyopaque,
        dwSpinCount: u32,
        Flags: u32,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn EnterCriticalSection(lpCriticalSection: *anyopaque) callconv(.winapi) void;
    extern "kernel32" fn LeaveCriticalSection(lpCriticalSection: *anyopaque) callconv(.winapi) void;
    extern "kernel32" fn DeleteCriticalSection(lpCriticalSection: *anyopaque) callconv(.winapi) void;

    extern "c" fn pthread_mutex_init(mutex: *anyopaque, attr: ?*const anyopaque) callconv(.c) c_int;
    extern "c" fn pthread_mutex_lock(mutex: *anyopaque) callconv(.c) c_int;
    extern "c" fn pthread_mutex_unlock(mutex: *anyopaque) callconv(.c) c_int;
    extern "c" fn pthread_mutex_destroy(mutex: *anyopaque) callconv(.c) c_int;

    fn init(m: *threads_psl.CurlMutex) void {
        if (builtin.os.tag == .windows) {
            _ = InitializeCriticalSectionEx(m, 0, 1);
        } else {
            _ = pthread_mutex_init(m, null);
        }
    }

    fn acquire(m: *threads_psl.CurlMutex) void {
        if (builtin.os.tag == .windows) {
            EnterCriticalSection(m);
        } else {
            _ = pthread_mutex_lock(m);
        }
    }

    fn release(m: *threads_psl.CurlMutex) void {
        if (builtin.os.tag == .windows) {
            LeaveCriticalSection(m);
        } else {
            _ = pthread_mutex_unlock(m);
        }
    }

    fn destroy(m: *threads_psl.CurlMutex) void {
        if (builtin.os.tag == .windows) {
            DeleteCriticalSection(m);
        } else {
            _ = pthread_mutex_destroy(m);
        }
    }
};

inline fn goodShareHandle(sh: ?*const Curl_share) bool {
    const s = sh orelse return false;
    return s.magic == CURL_GOOD_SHARE;
}

fn shareDestroy(share_opt: ?*Curl_share) void {
    const share = share_opt orelse return;

    if ((share.specifier & (@as(c_uint, 1) << CURL_LOCK_DATA_CONNECT)) != 0) {
        Curl_cpool_destroy(&share.cpool, share.admin);
    }

    Curl_dnscache_destroy(&share.dnscache);
    Curl_cookie_cleanup(share.cookies);
    Curl_share_hsts_cleanup(&share.hsts);
    Curl_share_ssl_scache_cleanup(&share.ssl_scache);
    threads_psl.Curl_psl_destroy(&share.psl);
    _ = Curl_close(&share.admin);

    share_mutex.destroy(&share.lock);
    curlx_memzero(std.mem.asBytes(share).ptr, @sizeOf(Curl_share));
    mem.freeTyped(share);
}

pub export fn curl_share_init() callconv(.c) ?*Curl_share {
    return shareInitInner() catch null;
}

fn shareInitInner() error{InitFailed}!*Curl_share {
    const share = mem.create(Curl_share) orelse return error.InitFailed;
    errdefer shareDestroy(share);

    share.magic = CURL_GOOD_SHARE;
    share.specifier |= (@as(c_uint, 1) << CURL_LOCK_DATA_SHARE);
    share_mutex.init(&share.lock);
    share.ref_count = 1;
    Curl_dnscache_init(&share.dnscache, 23);
    share.admin = curl_easy_init();
    if (share.admin == null) {
        return error.InitFailed;
    }
    Curl_share_init_admin(share.admin);
    return share;
}

fn shareRefInc(share: *Curl_share) u32 {
    share_mutex.acquire(&share.lock);
    share.ref_count += 1;
    const n = share.ref_count;
    share.has_been_shared = 1;
    share_mutex.release(&share.lock);
    return n;
}

fn shareRefDec(share: *Curl_share) u32 {
    share_mutex.acquire(&share.lock);
    share.ref_count -= 1;
    const n = share.ref_count;
    share_mutex.release(&share.lock);
    return n;
}

fn shareHasBeenShared(share: *Curl_share) bool {
    share_mutex.acquire(&share.lock);
    const was_shared = (share.has_been_shared != 0);
    share_mutex.release(&share.lock);
    return was_shared;
}

fn shareLockAcquire(share: *Curl_share, data: ?*anyopaque) bool {
    if (share.lockfunc != null and share.unlockfunc != null and
        (data != null or shareHasBeenShared(share)))
    {
        share.lockfunc.?(data, CURL_LOCK_DATA_SHARE, CURL_LOCK_ACCESS_SINGLE, share.clientdata);
        return true;
    }
    return false;
}

fn shareLockRelease(share: *Curl_share, data: ?*anyopaque, locked: bool) void {
    if (locked) {
        if (share.unlockfunc) |uf| {
            uf(data, CURL_LOCK_DATA_SHARE, share.clientdata);
        }
    }
}

fn shareInUse(share: *Curl_share) bool {
    share_mutex.acquire(&share.lock);
    const in_use = (share.ref_count > 1);
    share_mutex.release(&share.lock);
    return in_use;
}

fn shareUnlink(pshare: *?*Curl_share, data: ?*anyopaque, locked: bool) void {
    const share = pshare.* orelse return;
    pshare.* = null;
    const n = shareRefDec(share);
    if (locked)
        shareLockRelease(share, data, locked);
    if (n == 0)
        shareDestroy(share);
}

fn shareSetoptImpl(sh: ?*Curl_share, option: c_uint, arg: usize) CURLSHcode {
    if (!goodShareHandle(sh))
        return CURLSHE_INVALID;
    const share = sh.?;

    if (shareInUse(share))
        return CURLSHE_IN_USE;

    var res: CURLSHcode = CURLSHE_OK;

    switch (option) {
        CURLSHOPT_SHARE => {
            const type_arg: c_int = @truncate(@as(isize, @bitCast(arg)));
            if (type_arg < 0 or type_arg >= 32)
                return CURLSHE_BAD_OPTION;
            const dtype: c_uint = @intCast(type_arg);
            switch (dtype) {
                CURL_LOCK_DATA_DNS => {},
                CURL_LOCK_DATA_COOKIE => {
                    if (share.cookies == null) {
                        share.cookies = Curl_cookie_init();
                        if (share.cookies == null)
                            res = CURLSHE_NOMEM;
                    }
                },
                CURL_LOCK_DATA_HSTS => {
                    res = Curl_share_hsts_init(&share.hsts);
                },
                CURL_LOCK_DATA_SSL_SESSION => {
                    res = Curl_share_ssl_scache_init(&share.ssl_scache);
                },
                CURL_LOCK_DATA_CONNECT => {
                    if (!share.cpool.isInitialized()) {
                        Curl_cpool_init(&share.cpool, share, 103);
                    }
                },
                CURL_LOCK_DATA_PSL => {
                    if (comptime !backend_options.psl) {
                        res = CURLSHE_NOT_BUILT_IN;
                    }
                },
                else => {
                    res = CURLSHE_BAD_OPTION;
                },
            }
            if (res == CURLSHE_OK) {
                share.specifier |= (@as(c_uint, 1) << @intCast(dtype));
            }
        },
        CURLSHOPT_UNSHARE => {
            const type_arg: c_int = @truncate(@as(isize, @bitCast(arg)));
            if (type_arg < 0 or type_arg >= 32)
                return CURLSHE_BAD_OPTION;
            const dtype: c_uint = @intCast(type_arg);
            switch (dtype) {
                CURL_LOCK_DATA_DNS => {},
                CURL_LOCK_DATA_COOKIE => {
                    if (share.cookies != null) {
                        Curl_cookie_cleanup(share.cookies);
                        share.cookies = null;
                    }
                },
                CURL_LOCK_DATA_HSTS => {
                    if (share.hsts != null) {
                        Curl_share_hsts_cleanup(&share.hsts);
                    }
                },
                CURL_LOCK_DATA_SSL_SESSION => {
                    if (share.ssl_scache != null) {
                        Curl_share_ssl_scache_cleanup(&share.ssl_scache);
                    }
                },
                CURL_LOCK_DATA_CONNECT => {},
                else => {
                    res = CURLSHE_BAD_OPTION;
                },
            }
            if (res == CURLSHE_OK) {
                share.specifier &= ~(@as(c_uint, 1) << @intCast(dtype));
            }
        },
        CURLSHOPT_LOCKFUNC => {
            share.lockfunc = if (arg != 0) @ptrFromInt(arg) else null;
        },
        CURLSHOPT_UNLOCKFUNC => {
            share.unlockfunc = if (arg != 0) @ptrFromInt(arg) else null;
        },
        CURLSHOPT_USERDATA => {
            share.clientdata = if (arg != 0) @ptrFromInt(arg) else null;
        },
        else => {
            res = CURLSHE_BAD_OPTION;
        },
    }

    return res;
}

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin(),
    else => false,
};

const share_variadic_impl = if (use_c_vastart) struct {
    pub fn curl_share_setopt(sh: ?*Curl_share, option: c_uint, ...) callconv(.c) CURLSHcode {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const arg: usize = switch (option) {
            CURLSHOPT_SHARE, CURLSHOPT_UNSHARE => @bitCast(@as(isize, @cVaArg(&ap, c_int))),
            CURLSHOPT_LOCKFUNC, CURLSHOPT_UNLOCKFUNC, CURLSHOPT_USERDATA => @cVaArg(&ap, usize),
            else => 0,
        };
        return shareSetoptImpl(sh, option, arg);
    }
} else struct {
    pub fn curl_share_setopt(sh: ?*Curl_share, option: c_uint, arg: usize) callconv(.c) CURLSHcode {
        return shareSetoptImpl(sh, option, arg);
    }
};

comptime {
    @export(&share_variadic_impl.curl_share_setopt, .{ .name = "curl_share_setopt", .linkage = .strong });
}

pub export fn curl_share_cleanup(sh: ?*Curl_share) callconv(.c) CURLSHcode {
    if (!goodShareHandle(sh))
        return CURLSHE_INVALID;
    var share = sh;
    if (shareInUse(share.?))
        return CURLSHE_IN_USE;

    const locked = shareLockAcquire(share.?, null);
    shareUnlink(&share, null, locked);
    return CURLSHE_OK;
}

pub export fn Curl_share_lock_share(
    share_opt: ?*Curl_share,
    data: ?*anyopaque,
    dtype: c_uint,
    accesstype: c_uint,
) callconv(.c) CURLSHcode {
    const share = share_opt orelse return CURLSHE_INVALID;
    if (dtype < 32 and (share.specifier & (@as(c_uint, 1) << @intCast(dtype))) != 0) {
        if (share.lockfunc) |lf| {
            lf(data, dtype, accesstype, share.clientdata);
        }
    }
    return CURLSHE_OK;
}

pub export fn Curl_share_lock(
    data: ?*anyopaque,
    dtype: c_uint,
    accesstype: c_uint,
) callconv(.c) CURLSHcode {
    return Curl_share_lock_share(Curl_share_get_easy_share(data), data, dtype, accesstype);
}

pub export fn Curl_share_unlock_share(
    share_opt: ?*Curl_share,
    data: ?*anyopaque,
    dtype: c_uint,
) callconv(.c) CURLSHcode {
    const share = share_opt orelse return CURLSHE_INVALID;
    if (dtype < 32 and (share.specifier & (@as(c_uint, 1) << @intCast(dtype))) != 0) {
        if (share.unlockfunc) |uf| {
            uf(data, dtype, share.clientdata);
        }
    }
    return CURLSHE_OK;
}

pub export fn Curl_share_unlock(
    data: ?*anyopaque,
    dtype: c_uint,
) callconv(.c) CURLSHcode {
    return Curl_share_unlock_share(Curl_share_get_easy_share(data), data, dtype);
}

pub export fn Curl_share_easy_unlink_ex(
    data: ?*anyopaque,
    pshare: *?*Curl_share,
    conn: ?*anyopaque,
    last_conn_id: *i64,
    last_cpid: *u32,
    pcookies: ?*?*anyopaque,
    phsts: ?*?*anyopaque,
    ppsl: ?*?*threads_psl.PslCache,
    multi_psl: ?*threads_psl.PslCache,
) callconv(.c) CURLcode {
    if (pshare.*) |share| {
        const locked = shareLockAcquire(share, data);

        if ((share.specifier & (@as(c_uint, 1) << CURL_LOCK_DATA_CONNECT)) != 0) {
            if (conn != null)
                Curl_detach_connection(data);
            last_conn_id.* = -1;
            last_cpid.* = std.math.maxInt(u32);
        }

        if (pcookies) |pc| {
            if (share.cookies == pc.*)
                pc.* = null;
        }
        if (phsts) |ph| {
            if (share.hsts == ph.*)
                ph.* = null;
        }
        if (ppsl) |pp| {
            if (&share.psl == pp.*)
                pp.* = multi_psl;
        }

        shareUnlink(pshare, data, locked);
    }
    return CURLE_OK;
}

pub export fn Curl_share_easy_unlink(data: ?*anyopaque) callconv(.c) CURLcode {
    return Curl_share_easy_unlink_dispatch(data);
}

pub export fn Curl_share_easy_link_ex(
    data: ?*anyopaque,
    share_opt: ?*Curl_share,
    pshare: *?*Curl_share,
    last_conn_id: *i64,
    last_cpid: *u32,
    pcookies: ?*?*anyopaque,
    phsts: ?*?*anyopaque,
    ppsl: ?*?*threads_psl.PslCache,
) callconv(.c) CURLcode {
    if (pshare.* != null)
        return CURLE_FAILED_INIT;

    if (share_opt) |share| {
        const locked = shareLockAcquire(share, data);

        if ((share.specifier & (@as(c_uint, 1) << CURL_LOCK_DATA_CONNECT)) != 0) {
            last_conn_id.* = -1;
            last_cpid.* = std.math.maxInt(u32);
        }

        _ = shareRefInc(share);
        pshare.* = share;

        if (pcookies) |pc| {
            if (share.cookies != null) {
                Curl_cookie_cleanup(pc.*);
                pc.* = share.cookies;
            }
        }
        if (phsts) |ph| {
            if (share.hsts != null) {
                Curl_share_hsts_cleanup(ph);
                ph.* = share.hsts;
            }
        }
        if (ppsl) |pp| {
            if ((share.specifier & (@as(c_uint, 1) << CURL_LOCK_DATA_PSL)) != 0) {
                pp.* = &share.psl;
            }
        }

        shareLockRelease(share, data, locked);
    }
    return CURLE_OK;
}

pub export fn Curl_share_easy_link(
    data: ?*anyopaque,
    share: ?*Curl_share,
) callconv(.c) CURLcode {
    return Curl_share_easy_link_dispatch(data, share);
}

// ============================================================================
// 3. lib/headers.c
// ============================================================================

pub const CURLH_HEADER: c_uint = 1 << 0;
pub const CURLH_TRAILER: c_uint = 1 << 1;
pub const CURLH_CONNECT: c_uint = 1 << 2;
pub const CURLH_1XX: c_uint = 1 << 3;
pub const CURLH_PSEUDO: c_uint = 1 << 4;

const MAX_HTTP_RESP_HEADER_COUNT: usize = 5000;

const CURLPROTO_HTTP: c_uint = 1 << 0;
const CURLPROTO_HTTPS: c_uint = 1 << 1;
const CURLPROTO_WS: c_uint = 1 << 30;
const CURLPROTO_WSS: c_uint = 1 << 31;
const PROTO_FAMILY_HTTP: c_uint = CURLPROTO_HTTP | CURLPROTO_HTTPS | CURLPROTO_WS | CURLPROTO_WSS;

const CLIENTWRITE_HEADER: c_int = 1 << 2;
const CLIENTWRITE_STATUS: c_int = 1 << 3;
const CLIENTWRITE_CONNECT: c_int = 1 << 4;
const CLIENTWRITE_1XX: c_int = 1 << 5;
const CLIENTWRITE_TRAILER: c_int = 1 << 6;

const CURL_CW_PROTOCOL: c_uint = 2;

const CURL_EAPI_FN_easy_header: c_uint = 3;
const CURL_EAPI_FN_easy_nextheader: c_uint = 4;

pub const curl_header = extern struct {
    name: ?[*:0]u8,
    value: ?[*:0]u8,
    amount: usize,
    index: usize,
    origin: c_uint,
    anchor: ?*Curl_llist_node,
};

pub const Curl_header_store = extern struct {
    node: Curl_llist_node,
    name: ?[*:0]u8,
    value: ?[*:0]u8,
    nh_amount: usize,
    nh_index: usize,
    request: c_int,
    type: u8,
    buffer: [1]u8,
};

const Curl_eapi_guard = extern struct {
    data: ?*anyopaque,
    depth: u16,
};

const Curl_cwriter = extern struct {
    cwt: *const Curl_cwtype,
    next: ?*Curl_cwriter,
    ctx: ?*anyopaque,
    phase: c_uint,
};

const Curl_cwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: *const fn (data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_write: *const fn (data: ?*anyopaque, writer: *Curl_cwriter, wtype: c_int, buf: [*]const u8, nbytes: usize) callconv(.c) CURLcode,
    do_flush: *const fn (data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_close: *const fn (data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) void,
    cwriter_size: usize,
};

extern fn Curl_eapi_enter(guard: *Curl_eapi_guard, curl: ?*anyopaque, fn_id: c_uint, presult: *CURLcode) callconv(.c) bool;
extern fn Curl_eapi_leave(guard: *Curl_eapi_guard) callconv(.c) void;
extern fn Curl_eapi_hcode(result: CURLcode) callconv(.c) CURLHcode;

extern fn Curl_cwriter_def_init(data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_def_flush(data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_def_close(data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) void;
extern fn Curl_cwriter_get_by_name(data: ?*anyopaque, name: [*:0]const u8) callconv(.c) ?*Curl_cwriter;
extern fn Curl_cwriter_create(pwriter: *?*Curl_cwriter, data: ?*anyopaque, cwt: *const Curl_cwtype, phase: c_uint) callconv(.c) CURLcode;
extern fn Curl_cwriter_add(data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_free(data: ?*anyopaque, writer: *Curl_cwriter) callconv(.c) void;

extern fn Curl_headers_auto_register(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_headers_get_protocol(data: ?*anyopaque) callconv(.c) c_uint;

const HeaderReg = struct {
    data: ?*anyopaque = null,
    httphdrs: *Curl_llist = undefined,
    headerout: [*]curl_header = undefined,
    nh_origin: *c_uint = undefined,
    nh_request: *c_int = undefined,
    nh_count: *usize = undefined,
    requests: *c_int = undefined,
};

const HEADER_REG_CAP: usize = 512;
var header_regs: [HEADER_REG_CAP]HeaderReg = @splat(.{});
var header_reg_cursor: usize = 0;
var header_reg_lock: std.atomic.Value(bool) = .init(false);

inline fn lockHeaderReg() void {
    while (header_reg_lock.cmpxchgWeak(false, true, .acquire, .monotonic) != null) {}
}

inline fn unlockHeaderReg() void {
    header_reg_lock.store(false, .release);
}

pub export fn Curl_headers_Register(
    data: ?*anyopaque,
    httphdrs: *Curl_llist,
    headerout: [*]curl_header,
    nh_origin: *c_uint,
    nh_request: *c_int,
    nh_count: *usize,
    requests: *c_int,
) callconv(.c) void {
    const d = data orelse return;
    lockHeaderReg();
    defer unlockHeaderReg();

    for (&header_regs) |*slot| {
        if (slot.data == d) {
            slot.httphdrs = httphdrs;
            slot.headerout = headerout;
            slot.nh_origin = nh_origin;
            slot.nh_request = nh_request;
            slot.nh_count = nh_count;
            slot.requests = requests;
            return;
        }
    }
    for (&header_regs) |*slot| {
        if (slot.data == null) {
            slot.* = .{
                .data = d,
                .httphdrs = httphdrs,
                .headerout = headerout,
                .nh_origin = nh_origin,
                .nh_request = nh_request,
                .nh_count = nh_count,
                .requests = requests,
            };
            return;
        }
    }
    header_regs[header_reg_cursor] = .{
        .data = d,
        .httphdrs = httphdrs,
        .headerout = headerout,
        .nh_origin = nh_origin,
        .nh_request = nh_request,
        .nh_count = nh_count,
        .requests = requests,
    };
    header_reg_cursor = (header_reg_cursor + 1) % HEADER_REG_CAP;
}

fn getHeaderReg(data: ?*anyopaque) ?HeaderReg {
    const d = data orelse return null;
    {
        lockHeaderReg();
        defer unlockHeaderReg();
        for (&header_regs) |slot| {
            if (slot.data == d)
                return slot;
        }
    }
    Curl_headers_auto_register(d);
    {
        lockHeaderReg();
        defer unlockHeaderReg();
        for (&header_regs) |slot| {
            if (slot.data == d)
                return slot;
        }
    }
    return null;
}

fn copyHeaderExternal(
    hs: *Curl_header_store,
    index: usize,
    amount: usize,
    e: *Curl_llist_node,
    hout: *curl_header,
) void {
    hout.name = hs.name;
    hout.value = hs.value;
    hout.amount = amount;
    hout.index = index;
    hout.origin = @as(c_uint, hs.type) | (1 << 27);
    hout.anchor = e;
}

pub export fn curl_easy_header(
    curl: ?*anyopaque,
    name: ?[*:0]const u8,
    nameindex: usize,
    origin: c_uint,
    request_in: c_int,
    hout: ?*?*curl_header,
) callconv(.c) CURLHcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var hresult: CURLHcode = CURLHE_OK;
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_header, &result) and curl != null) {
        const max_origin = CURLH_HEADER | CURLH_TRAILER | CURLH_CONNECT | CURLH_1XX | CURLH_PSEUDO;
        if (name == null or hout == null or curl == null or
            origin > max_origin or origin == 0 or request_in < -1)
        {
            hresult = CURLHE_BAD_ARGUMENT;
        } else if (getHeaderReg(curl)) |reg| {
            if (containers.Curl_llist_count(reg.httphdrs) == 0) {
                hresult = CURLHE_NOHEADERS;
            } else if (request_in > reg.requests.*) {
                hresult = CURLHE_NOREQUEST;
            } else {
                const request = if (request_in == -1) reg.requests.* else request_in;
                var amount: usize = 0;
                var pick: ?*Curl_header_store = null;
                var e_pick: ?*Curl_llist_node = null;

                var e_opt = containers.Curl_llist_head(reg.httphdrs);
                while (e_opt) |e| : (e_opt = containers.Curl_node_next(e)) {
                    const hs = collections.llistElemTyped(Curl_header_store, e).?;
                    if (primitives.curl_strequal(hs.name, name) != 0 and
                        (@as(c_uint, hs.type) & origin) != 0 and
                        hs.request == request)
                    {
                        amount += 1;
                        pick = hs;
                        e_pick = e;
                    }
                }

                if (amount == 0) {
                    hresult = CURLHE_MISSING;
                } else if (nameindex >= amount) {
                    hresult = CURLHE_BADINDEX;
                } else {
                    var hs_final: ?*Curl_header_store = null;
                    if (nameindex == amount - 1) {
                        hs_final = pick;
                    } else {
                        var match: usize = 0;
                        var it_opt = containers.Curl_llist_head(reg.httphdrs);
                        while (it_opt) |e| : (it_opt = containers.Curl_node_next(e)) {
                            const hs = collections.llistElemTyped(Curl_header_store, e).?;
                            if (primitives.curl_strequal(hs.name, name) != 0 and
                                (@as(c_uint, hs.type) & origin) != 0 and
                                hs.request == request)
                            {
                                if (match == nameindex) {
                                    hs_final = hs;
                                    e_pick = e;
                                    break;
                                }
                                match += 1;
                            }
                        }
                    }

                    if (hs_final == null or e_pick == null) {
                        hresult = CURLHE_MISSING;
                    } else {
                        copyHeaderExternal(hs_final.?, nameindex, amount, e_pick.?, &reg.headerout[0]);
                        hout.?.* = &reg.headerout[0];
                        hresult = CURLHE_OK;
                    }
                }
            }
        } else {
            hresult = CURLHE_NOHEADERS;
        }
    }

    Curl_eapi_leave(&guard);
    if (result != CURLE_OK)
        hresult = Curl_eapi_hcode(result);
    return hresult;
}

const NextheaderCacheEntry = struct {
    header: *Curl_header_store,
    order: usize,
};

fn nextheaderCompare(e1: NextheaderCacheEntry, e2: NextheaderCacheEntry) c_int {
    var n1: [*:0]const u8 = e1.header.name.?;
    var n2: [*:0]const u8 = e2.header.name.?;

    while (n1[0] != 0 and n2[0] != 0) {
        const c1 = primitives.rawToupper(n1[0]);
        const c2 = primitives.rawToupper(n2[0]);
        n1 += 1;
        n2 += 1;
        if (c1 != c2)
            return if (c1 > c2) 1 else -1;
    }
    if (n1[0] != 0) return 1;
    if (n2[0] != 0) return -1;
    if (e1.order != e2.order)
        return if (e1.order > e2.order) 1 else -1;
    return 0;
}

fn nextheaderCacheBuild(
    reg: HeaderReg,
    origin: c_uint,
    request: c_int,
    count: usize,
) bool {
    const headers = mem.allocMany(NextheaderCacheEntry, count) orelse return false;
    defer mem.freeTyped(headers);

    var i: usize = 0;
    var e_opt = containers.Curl_llist_head(reg.httphdrs);
    while (e_opt) |e| : (e_opt = containers.Curl_node_next(e)) {
        const hs = collections.llistElemTyped(Curl_header_store, e).?;
        if ((@as(c_uint, hs.type) & origin) != 0 and hs.request == request) {
            headers[i] = .{ .header = hs, .order = i };
            i += 1;
        }
    }

    // Insertion sort matching qsort on NextheaderCacheEntry
    var idx: usize = 1;
    while (idx < i) : (idx += 1) {
        const tmp = headers[idx];
        var j = idx;
        while (j > 0 and nextheaderCompare(headers[j - 1], tmp) > 0) : (j -= 1) {
            headers[j] = headers[j - 1];
        }
        headers[j] = tmp;
    }

    var first: usize = 0;
    while (first < i) {
        var last = first + 1;
        while (last < i and primitives.curl_strequal(headers[first].header.name, headers[last].header.name) != 0) {
            last += 1;
        }
        for (first..last) |k| {
            headers[k].header.nh_amount = last - first;
            headers[k].header.nh_index = k - first;
        }
        first = last;
    }

    reg.nh_origin.* = origin;
    reg.nh_request.* = request;
    reg.nh_count.* = count;
    return true;
}

pub export fn curl_easy_nextheader(
    curl: ?*anyopaque,
    origin: c_uint,
    request_in: c_int,
    prev: ?*curl_header,
) callconv(.c) ?*curl_header {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var hd: ?*curl_header = null;
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_nextheader, &result) and curl != null) {
        if (getHeaderReg(curl)) |reg| {
            if (request_in <= reg.requests.*) {
                const request = if (request_in == -1) reg.requests.* else request_in;
                var pick_opt: ?*Curl_llist_node = null;
                var valid_prev = true;

                if (prev) |p| {
                    if (p.anchor) |prev_node| {
                        pick_opt = containers.Curl_node_next(prev_node);
                    } else {
                        valid_prev = false;
                    }
                } else {
                    pick_opt = containers.Curl_llist_head(reg.httphdrs);
                }

                if (valid_prev) {
                    while (pick_opt) |node| {
                        const hs = collections.llistElemTyped(Curl_header_store, node).?;
                        if ((@as(c_uint, hs.type) & origin) != 0 and hs.request == request)
                            break;
                        pick_opt = containers.Curl_node_next(node);
                    }

                    if (pick_opt) |pick| {
                        const hs = collections.llistElemTyped(Curl_header_store, pick).?;
                        const count = containers.Curl_llist_count(reg.httphdrs);
                        var amount: usize = 0;
                        var index: usize = 0;

                        if ((reg.nh_count.* == count and
                            reg.nh_origin.* == origin and
                            reg.nh_request.* == request) or
                            nextheaderCacheBuild(reg, origin, request, count))
                        {
                            amount = hs.nh_amount;
                            index = hs.nh_index;
                        } else {
                            var e_opt = containers.Curl_llist_head(reg.httphdrs);
                            while (e_opt) |e| : (e_opt = containers.Curl_node_next(e)) {
                                const check = collections.llistElemTyped(Curl_header_store, e).?;
                                if (primitives.curl_strequal(hs.name, check.name) != 0 and
                                    check.request == request and
                                    (@as(c_uint, check.type) & origin) != 0)
                                {
                                    amount += 1;
                                }
                                if (e == pick)
                                    index = amount - 1;
                            }
                        }

                        copyHeaderExternal(hs, index, amount, pick, &reg.headerout[1]);
                        hd = &reg.headerout[1];
                    }
                }
            }
        }
    }

    Curl_eapi_leave(&guard);
    return hd;
}

fn namevalue(
    header: [*:0]u8,
    hlen: usize,
    htype: c_uint,
    name: *?[*:0]u8,
    value: *?[*:0]u8,
) CURLcode {
    var ptr = header;
    var end = header + hlen - 1;
    name.* = header;

    if (htype == CURLH_PSEUDO) {
        if (ptr[0] != ':')
            return CURLE_BAD_FUNCTION_ARGUMENT;
        ptr += 1;
    }

    while (ptr[0] != 0 and ptr[0] != ':') : (ptr += 1) {}

    if (ptr[0] != 0) {
        ptr[0] = 0;
        ptr += 1;
    } else {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    while (isBlank(ptr[0])) : (ptr += 1) {}
    value.* = ptr;

    while (@intFromPtr(end) > @intFromPtr(ptr) and isBlank(end[0])) {
        end[0] = 0;
        end -= 1;
    }
    return CURLE_OK;
}

pub export fn Curl_headers_push(
    data: ?*anyopaque,
    header_in: [*]const u8,
    hlen_in: usize,
    htype: u8,
) callconv(.c) CURLcode {
    var header = header_in;
    var hlen = hlen_in;
    const ilen = hlen_in;

    if (hlen > 0 and (header[0] == '\r' or header[0] == '\n'))
        return CURLE_OK;

    if (hlen > 0 and header[hlen - 1] == '\n')
        hlen -= 1;
    if (hlen > 0 and header[hlen - 1] == '\r')
        hlen -= 1;
    if (hlen == ilen)
        return CURLE_WEIRD_SERVER_REPLY;

    if (hlen > 0 and isBlank(header[0])) {
        while (hlen > 0 and isBlank(header[0])) {
            header += 1;
            hlen -= 1;
        }
        if (hlen == 0)
            return CURLE_WEIRD_SERVER_REPLY;
    }

    const reg = getHeaderReg(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if (containers.Curl_llist_count(reg.httphdrs) >= MAX_HTTP_RESP_HEADER_COUNT) {
        Curl_failf(data, "Too many response headers, %d is max", @as(c_int, MAX_HTTP_RESP_HEADER_COUNT));
        return CURLE_TOO_LARGE;
    }

    return pushHeaderStore(data, reg, header, hlen, htype) catch |err| switch (err) {
        error.OutOfMemory => CURLE_OUT_OF_MEMORY,
        error.InvalidHeader => CURLE_BAD_FUNCTION_ARGUMENT,
    };
}

fn pushHeaderStore(
    data: ?*anyopaque,
    reg: HeaderReg,
    header: [*]const u8,
    hlen: usize,
    htype: u8,
) error{ OutOfMemory, InvalidHeader }!CURLcode {
    const raw = mem.callocMany(u8, @sizeOf(Curl_header_store) + hlen) orelse return error.OutOfMemory;
    const hs: *Curl_header_store = @ptrCast(@alignCast(raw));
    errdefer mem.freeTyped(hs);
    const buf_ptr: [*:0]u8 = (&hs.buffer)[0..0 :0].ptr;
    @memcpy(buf_ptr[0..hlen], header[0..hlen]);
    buf_ptr[hlen] = 0;

    var name: ?[*:0]u8 = null;
    var value: ?[*:0]u8 = null;
    const result = namevalue(buf_ptr, hlen, htype, &name, &value);
    if (result != CURLE_OK) {
        Curl_failf(data, "Invalid response header");
        return error.InvalidHeader;
    }
    hs.name = name;
    hs.value = value;
    hs.type = htype;
    hs.request = reg.requests.*;
    containers.Curl_llist_append(reg.httphdrs, hs, &hs.node);
    return CURLE_OK;
}

fn hdsCwCollectWrite(
    data: ?*anyopaque,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    blen: usize,
) callconv(.c) CURLcode {
    if ((wtype & CLIENTWRITE_HEADER) != 0 and (wtype & CLIENTWRITE_STATUS) == 0) {
        const htype: u8 = if ((wtype & CLIENTWRITE_CONNECT) != 0)
            @intCast(CURLH_CONNECT)
        else if ((wtype & CLIENTWRITE_1XX) != 0)
            @intCast(CURLH_1XX)
        else if ((wtype & CLIENTWRITE_TRAILER) != 0)
            @intCast(CURLH_TRAILER)
        else
            @intCast(CURLH_HEADER);

        const result = Curl_headers_push(data, buf, blen, htype);
        if (result != CURLE_OK)
            return result;
    }
    if (writer.next) |next_w| {
        return next_w.cwt.do_write(data, next_w, wtype, buf, blen);
    }
    return CURLE_WRITE_ERROR;
}

const hds_cw_collect: Curl_cwtype = .{
    .name = "hds-collect",
    .alias = null,
    .flags = 0,
    .do_init = Curl_cwriter_def_init,
    .do_write = hdsCwCollectWrite,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = Curl_cwriter_def_close,
    .cwriter_size = @sizeOf(Curl_cwriter),
};

pub export fn Curl_headers_init_ex(
    data: ?*anyopaque,
    protocol: c_uint,
) callconv(.c) CURLcode {
    if ((protocol & PROTO_FAMILY_HTTP) != 0) {
        if (Curl_cwriter_get_by_name(data, hds_cw_collect.name) != null)
            return CURLE_OK;

        return initHeaderCollector(data) catch |err| switch (err) {
            error.CreateFailed => CURLE_OUT_OF_MEMORY,
        };
    }
    return CURLE_OK;
}

fn initHeaderCollector(data: ?*anyopaque) error{CreateFailed}!CURLcode {
    var writer: ?*Curl_cwriter = null;
    var result = Curl_cwriter_create(&writer, data, &hds_cw_collect, CURL_CW_PROTOCOL);
    if (result != CURLE_OK)
        return result;
    errdefer Curl_cwriter_free(data, writer.?);

    result = Curl_cwriter_add(data, writer.?);
    if (result != CURLE_OK) {
        Curl_cwriter_free(data, writer.?);
        return result;
    }
    return CURLE_OK;
}

pub export fn Curl_headers_init(data: ?*anyopaque) callconv(.c) CURLcode {
    _ = getHeaderReg(data);
    return Curl_headers_init_ex(data, Curl_headers_get_protocol(data));
}

pub export fn Curl_headers_cleanup(data: ?*anyopaque) callconv(.c) CURLcode {
    const reg = getHeaderReg(data) orelse return CURLE_OK;
    var e_opt = containers.Curl_llist_head(reg.httphdrs);
    while (e_opt) |e| {
        const hs = containers.Curl_node_elem(e);
        const n = containers.Curl_node_next(e);
        mem.free(hs);
        e_opt = n;
    }
    containers.Curl_llist_init(reg.httphdrs, null);
    reg.nh_count.* = 0;
    return CURLE_OK;
}

// ============================================================================
// 4. lib/cshutdn.c
// ============================================================================

const DEFAULT_SHUTDOWN_TIMEOUT_MS: timediff_t = 2 * 1000;
const EXPIRE_SHUTDOWN: c_uint = 15;
const FIRSTSOCKET: i8 = 0;
const SECONDARYSOCKET: i8 = 1;
const NUM_POLLS_ON_STACK: c_uint = 10;

pub const cshutdn = extern struct {
    conns: ptrarray,
};

const CurlSigpipeCtx = extern struct {
    data: [32]u64 align(16) = @splat(0),
};

extern fn Curl_pgrs_now(data: ?*anyopaque) callconv(.c) *const Curltime;
extern fn Curl_expire_set(data: ?*anyopaque, id: c_uint, ms: timediff_t, nowp: *const Curltime) callconv(.c) void;
extern fn Curl_expire(data: ?*anyopaque, ms: timediff_t, id: c_uint) callconv(.c) void;
extern fn Curl_attach_connection(data: ?*anyopaque, conn: ?*anyopaque, keep_existing: bool) callconv(.c) void;
extern fn Curl_conn_is_connected(conn: ?*anyopaque, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_cf_discard_all(data: ?*anyopaque, conn: ?*anyopaque, index: i8) callconv(.c) void;
extern fn Curl_multi_ev_conn_done(multi: ?*anyopaque, data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) void;
extern fn Curl_multi_ev_assess_conn(multi: ?*anyopaque, data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLMcode;
extern fn Curl_conn_free(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) void;
extern fn Curl_multi_connchanged(multi: ?*anyopaque) callconv(.c) void;
extern fn Curl_conn_adjust_pollset(data: ?*anyopaque, conn: ?*anyopaque, ps: *headers_sock.EasyPollset) callconv(.c) CURLcode;

extern fn Curl_cshutdn_conn_get_times(
    conn: ?*anyopaque,
    sockindex: i8,
    start_ms: *timediff_t,
    timeout_ms: *timediff_t,
    created: *Curltime,
) callconv(.c) void;
extern fn Curl_cshutdn_conn_set_times(
    conn: ?*anyopaque,
    sockindex: i8,
    start_ms: timediff_t,
    timeout_ms: timediff_t,
) callconv(.c) void;
extern fn Curl_cshutdn_conn_clear_start(conn: ?*anyopaque, sockindex: i8) callconv(.c) void;
extern fn Curl_cshutdn_conn_get_cfilter(conn: ?*anyopaque, sockindex: i8) callconv(.c) ?*vdns_cfilters.Curl_cfilter;
extern fn Curl_cshutdn_conn_get_dest(conn: ?*anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_cshutdn_conn_get_bits(
    conn: ?*anyopaque,
    shutdown_filters: *bool,
    connect_only: *bool,
) callconv(.c) void;
extern fn Curl_cshutdn_conn_set_shutdown_filters(conn: ?*anyopaque, val: bool) callconv(.c) void;
extern fn Curl_cshutdn_run_conn_handler_c(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) void;
extern fn Curl_cshutdn_data_get_info(
    data: ?*anyopaque,
    pconn: *?*anyopaque,
    shutdowntimeout: *timediff_t,
    mid: *u32,
    pmulti: *?*anyopaque,
) callconv(.c) void;
extern fn Curl_cshutdn_multi_get_info(
    multi: ?*anyopaque,
    padmin: *?*vdns_cfilters.Curl_easy,
    has_socket_cb: *bool,
) callconv(.c) void;
extern fn Curl_cshutdn_fdset_apply(
    sock: curl_socket_t,
    action: u8,
    read_fd_set: ?*anyopaque,
    write_fd_set: ?*anyopaque,
    maxfd: *c_int,
) callconv(.c) void;
extern fn Curl_cshutdn_sigpipe_init_c(ctx: *CurlSigpipeCtx) callconv(.c) void;
extern fn Curl_cshutdn_sigpipe_apply_c(data: ?*anyopaque, ctx: ?*CurlSigpipeCtx) callconv(.c) void;
extern fn Curl_cshutdn_sigpipe_restore_c(ctx: *CurlSigpipeCtx) callconv(.c) void;

pub export fn Curl_cshutdn_start_timer(
    data: ?*anyopaque,
    sockindex: i8,
    timeout_ms: c_int,
) callconv(.c) void {
    var conn: ?*anyopaque = null;
    var shutdowntimeout: timediff_t = 0;
    var mid: u32 = 0;
    var multi: ?*anyopaque = null;
    Curl_cshutdn_data_get_info(data, &conn, &shutdowntimeout, &mid, &multi);

    var old_start: timediff_t = 0;
    var old_timeout: timediff_t = 0;
    var created: Curltime = undefined;
    Curl_cshutdn_conn_get_times(conn, sockindex, &old_start, &old_timeout, &created);

    const pnow = Curl_pgrs_now(data);
    const start_ms = curlx_time_net.curlx_ptimediff_ms(pnow, &created);
    const eff_timeout: timediff_t = if (timeout_ms > 0)
        @intCast(timeout_ms)
    else if (shutdowntimeout > 0)
        shutdowntimeout
    else
        DEFAULT_SHUTDOWN_TIMEOUT_MS;

    Curl_cshutdn_conn_set_times(conn, sockindex, start_ms, eff_timeout);
    if (mid != 0) {
        Curl_expire_set(data, EXPIRE_SHUTDOWN, eff_timeout, pnow);
    }
}

pub export fn Curl_cshutdn_timeleft_ms(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    sockindex: i8,
) callconv(.c) timediff_t {
    var start_ms: timediff_t = -1;
    var timeout_ms: timediff_t = 0;
    var created: Curltime = undefined;
    Curl_cshutdn_conn_get_times(conn, sockindex, &start_ms, &timeout_ms, &created);

    if (start_ms < 0)
        return 0;

    const left_ms = timeout_ms - (curlx_time_net.curlx_ptimediff_ms(Curl_pgrs_now(data), &created) - start_ms);
    return if (left_ms != 0) left_ms else -1;
}

fn cshutdnConnTimeleft(data: ?*anyopaque, conn: ?*anyopaque) timediff_t {
    var left_ms: timediff_t = 0;
    var i: i8 = 0;
    while (i < 2) : (i += 1) {
        var start_ms: timediff_t = -1;
        var timeout_ms: timediff_t = 0;
        var created: Curltime = undefined;
        Curl_cshutdn_conn_get_times(conn, i, &start_ms, &timeout_ms, &created);
        if (timeout_ms == 0)
            break;
        if (start_ms < 0)
            continue;
        const ms = Curl_cshutdn_timeleft_ms(data, conn, i);
        if (ms != 0 and (left_ms == 0 or ms < left_ms))
            left_ms = ms;
    }
    return left_ms;
}

pub export fn Curl_cshutdn_clear_timer(
    data: ?*anyopaque,
    sockindex: i8,
) callconv(.c) void {
    var conn: ?*anyopaque = null;
    var shutdowntimeout: timediff_t = 0;
    var mid: u32 = 0;
    var multi: ?*anyopaque = null;
    Curl_cshutdn_data_get_info(data, &conn, &shutdowntimeout, &mid, &multi);
    Curl_cshutdn_conn_clear_start(conn, sockindex);
}

pub export fn Curl_cshutdn_try_once_idx(
    data: ?*vdns_cfilters.Curl_easy,
    sockindex: i8,
    done: *bool,
) callconv(.c) CURLcode {
    if (sockindex != FIRSTSOCKET and sockindex != SECONDARYSOCKET)
        return CURLE_BAD_FUNCTION_ARGUMENT;

    var conn: ?*anyopaque = null;
    var shutdowntimeout: timediff_t = 0;
    var mid: u32 = 0;
    var multi: ?*anyopaque = null;
    Curl_cshutdn_data_get_info(data, &conn, &shutdowntimeout, &mid, &multi);

    var cf_opt = Curl_cshutdn_conn_get_cfilter(conn, sockindex);
    while (cf_opt) |cf| {
        if (cf.isConnected() and !cf.isShutdown())
            break;
        cf_opt = cf.next;
    }

    if (cf_opt == null) {
        done.* = true;
        return CURLE_OK;
    }

    done.* = false;
    var start_ms: timediff_t = -1;
    var timeout_ms: timediff_t = 0;
    var created: Curltime = undefined;
    Curl_cshutdn_conn_get_times(conn, sockindex, &start_ms, &timeout_ms, &created);

    if (start_ms < 0) {
        Curl_cshutdn_start_timer(data, sockindex, 0);
    } else {
        const left = Curl_cshutdn_timeleft_ms(data, conn, sockindex);
        if (left < 0) {
            Curl_infof(data, "shutdown timeout");
            return CURLE_OPERATION_TIMEDOUT;
        }
    }

    var result: CURLcode = CURLE_OK;
    while (cf_opt) |cf| : (cf_opt = cf.next) {
        if (!cf.isShutdown()) {
            var cfdone: bool = false;
            result = cf.cft.do_shutdown(cf, data, &cfdone);
            if (result != CURLE_OK) {
                return result;
            } else if (!cfdone) {
                return CURLE_OK;
            }
            cf.setShutdown(true);
        }
    }
    done.* = (result == CURLE_OK);
    return result;
}

fn cshutdnRunOnce(data: ?*vdns_cfilters.Curl_easy, conn: ?*anyopaque, done: *bool) void {
    var start_ms: timediff_t = -1;
    var timeout_ms: timediff_t = 0;
    var created: Curltime = undefined;
    Curl_cshutdn_conn_get_times(conn, FIRSTSOCKET, &start_ms, &timeout_ms, &created);
    if (start_ms < 0) {
        Curl_cshutdn_start_timer(data, FIRSTSOCKET, 0);
    }

    Curl_cshutdn_run_conn_handler_c(data, conn);

    var shutdown_filters = false;
    var connect_only = false;
    Curl_cshutdn_conn_get_bits(conn, &shutdown_filters, &connect_only);

    if (shutdown_filters) {
        done.* = true;
        return;
    }

    var r1: CURLcode = CURLE_OK;
    var done1: bool = true;
    if (!connect_only and Curl_conn_is_connected(conn, FIRSTSOCKET)) {
        r1 = Curl_cshutdn_try_once_idx(data, FIRSTSOCKET, &done1);
    }

    var r2: CURLcode = CURLE_OK;
    var done2: bool = true;
    if (!connect_only and Curl_conn_is_connected(conn, SECONDARYSOCKET)) {
        r2 = Curl_cshutdn_try_once_idx(data, SECONDARYSOCKET, &done2);
    }

    done.* = (r1 != CURLE_OK or r2 != CURLE_OK or (done1 and done2));
    if (done.*) {
        Curl_cshutdn_conn_set_shutdown_filters(conn, true);
    }
}

pub export fn Curl_cshutdn_try_once(
    admin: ?*vdns_cfilters.Curl_easy,
    conn: ?*anyopaque,
    done: *bool,
) callconv(.c) void {
    Curl_attach_connection(admin, conn, false);
    cshutdnRunOnce(admin, conn, done);
    Curl_detach_connection(admin);
}

pub export fn Curl_cshutdn_terminate(
    admin: ?*vdns_cfilters.Curl_easy,
    conn: ?*anyopaque,
    do_shutdown: bool,
) callconv(.c) void {
    var done: bool = false;

    Curl_attach_connection(admin, conn, false);
    Curl_cshutdn_run_conn_handler_c(admin, conn);
    if (do_shutdown) {
        cshutdnRunOnce(admin, conn, &done);
    }

    Curl_conn_cf_discard_all(admin, conn, SECONDARYSOCKET);
    Curl_conn_cf_discard_all(admin, conn, FIRSTSOCKET);
    Curl_detach_connection(admin);

    var unused_conn: ?*anyopaque = null;
    var unused_to: timediff_t = 0;
    var unused_mid: u32 = 0;
    var multi: ?*anyopaque = null;
    Curl_cshutdn_data_get_info(admin, &unused_conn, &unused_to, &unused_mid, &multi);

    if (multi != null) {
        Curl_multi_ev_conn_done(multi, admin, conn);
    }
    Curl_conn_free(admin, conn);

    if (multi != null) {
        Curl_multi_connchanged(multi);
    }
}

fn cshutdnDestroyOldest(
    cs: *cshutdn,
    admin: ?*vdns_cfilters.Curl_easy,
    destination: ?[*:0]const u8,
    count: usize,
) usize {
    var sigpipe_ctx: CurlSigpipeCtx = .{};
    var removed: usize = 0;
    var i: u32 = 0;

    Curl_cshutdn_sigpipe_init_c(&sigpipe_ctx);
    while (removed < count and i < cs.conns.n) {
        const conn = cs.conns.data.?[i];
        var matches = true;
        if (destination) |dest| {
            const conn_dest = Curl_cshutdn_conn_get_dest(conn) orelse "";
            matches = std.mem.eql(u8, std.mem.span(dest), std.mem.span(conn_dest));
        }
        if (matches) {
            _ = Curl_ptrarray_remove(&cs.conns, i);
            Curl_cshutdn_sigpipe_apply_c(admin, &sigpipe_ctx);
            Curl_cshutdn_terminate(admin, conn, false);
            removed += 1;
        } else {
            i += 1;
        }
    }
    Curl_cshutdn_sigpipe_restore_c(&sigpipe_ctx);
    return removed;
}

pub export fn Curl_cshutdn_close_oldest(
    cs_opt: ?*cshutdn,
    admin: ?*vdns_cfilters.Curl_easy,
    destination: ?[*:0]const u8,
    count: usize,
) callconv(.c) usize {
    const cs = cs_opt orelse return 0;
    return cshutdnDestroyOldest(cs, admin, destination, count);
}

fn cshutdnWait(
    cs: *cshutdn,
    admin: ?*vdns_cfilters.Curl_easy,
    timeout_ms: c_int,
) CURLcode {
    var a_few_on_stack: [NUM_POLLS_ON_STACK]headers_sock.Pollfd = undefined;
    var cpfds: headers_sock.CurlPollfds = undefined;

    headers_sock.Curl_pollfds_init(&cpfds, &a_few_on_stack, NUM_POLLS_ON_STACK);
    defer headers_sock.Curl_pollfds_cleanup(&cpfds);

    const result = Curl_cshutdn_add_pollfds(cs, admin, &cpfds);
    if (result != CURLE_OK)
        return result;

    _ = headers_sock.Curl_poll(cpfds.pfds, cpfds.n, @min(timeout_ms, 1000));
    return CURLE_OK;
}

fn cshutdnPerform(
    cs: *cshutdn,
    admin: ?*vdns_cfilters.Curl_easy,
    sigpipe_ctx: ?*CurlSigpipeCtx,
) void {
    if (cs.conns.n == 0)
        return;

    Curl_cshutdn_sigpipe_apply_c(admin, sigpipe_ctx);
    var next_expire_ms: timediff_t = 0;
    var i: u32 = 0;
    while (i < cs.conns.n) {
        const conn = cs.conns.data.?[i];
        var done: bool = false;
        Curl_cshutdn_try_once(admin, conn, &done);
        if (done) {
            _ = Curl_ptrarray_remove(&cs.conns, i);
            Curl_cshutdn_terminate(admin, conn, false);
        } else {
            i += 1;
            const ms = cshutdnConnTimeleft(admin, conn);
            if (ms != 0 and (next_expire_ms == 0 or ms < next_expire_ms))
                next_expire_ms = ms;
        }
    }

    if (next_expire_ms != 0)
        Curl_expire(admin, next_expire_ms, EXPIRE_SHUTDOWN);
}

fn cshutdnTerminateAll(
    cs: *cshutdn,
    admin: ?*vdns_cfilters.Curl_easy,
    timeout_ms: c_int,
) void {
    const started = Curl_pgrs_now(admin).*;
    var sigpipe_ctx: CurlSigpipeCtx = .{};
    Curl_cshutdn_sigpipe_init_c(&sigpipe_ctx);

    while (cs.conns.n != 0) {
        cshutdnPerform(cs, admin, &sigpipe_ctx);
        if (cs.conns.n == 0)
            break;

        const spent_ms = curlx_time_net.curlx_ptimediff_ms(Curl_pgrs_now(admin), &started);
        if (spent_ms >= @as(timediff_t, timeout_ms))
            break;

        const remain_ms: c_int = timeout_ms - @as(c_int, @intCast(spent_ms));
        if (cshutdnWait(cs, admin, remain_ms) != CURLE_OK)
            break;
    }

    while (cs.conns.n != 0) {
        const conn = Curl_ptrarray_remove(&cs.conns, 0);
        Curl_cshutdn_terminate(admin, conn, false);
    }

    Curl_cshutdn_sigpipe_restore_c(&sigpipe_ctx);
}

pub export fn Curl_cshutdn_init(cs: *cshutdn) callconv(.c) void {
    Curl_ptrarray_init(&cs.conns);
}

pub export fn Curl_cshutdn_destroy(
    cs: *cshutdn,
    admin: ?*vdns_cfilters.Curl_easy,
) callconv(.c) void {
    if (admin != null) {
        if (cs.conns.n != 0) {
            cshutdnTerminateAll(cs, admin, 0);
        }
    }
    Curl_ptrarray_clear(&cs.conns);
}

pub export fn Curl_cshutdn_count(cs_opt: ?*cshutdn) callconv(.c) usize {
    const cs = cs_opt orelse return 0;
    return cs.conns.n;
}

pub export fn Curl_cshutdn_dest_count(
    cs_opt: ?*cshutdn,
    destination: [*:0]const u8,
) callconv(.c) usize {
    const cs = cs_opt orelse return 0;
    var n: usize = 0;
    const dest_slice = std.mem.span(destination);
    var i: u32 = 0;
    while (i < cs.conns.n) : (i += 1) {
        const conn = cs.conns.data.?[i];
        if (Curl_cshutdn_conn_get_dest(conn)) |conn_dest| {
            if (std.mem.eql(u8, dest_slice, std.mem.span(conn_dest)))
                n += 1;
        }
    }
    return n;
}

pub export fn Curl_cshutdn_add(
    cs: *cshutdn,
    multi: ?*anyopaque,
    conn: ?*anyopaque,
    max_shutdowns: usize,
) callconv(.c) void {
    var admin: ?*vdns_cfilters.Curl_easy = null;
    var has_socket_cb: bool = false;
    Curl_cshutdn_multi_get_info(multi, &admin, &has_socket_cb);

    if (max_shutdowns <= cs.conns.n) {
        _ = cshutdnDestroyOldest(cs, admin, null, 1);
    }

    if (has_socket_cb) {
        Curl_attach_connection(admin, conn, false);
        const mresult = Curl_multi_ev_assess_conn(multi, admin, conn);
        Curl_detach_connection(admin);
        if (mresult != CURLM_OK) {
            Curl_cshutdn_terminate(admin, conn, false);
            return;
        }
    }

    if (Curl_ptrarray_add(&cs.conns, conn) != CURLE_OK) {
        Curl_cshutdn_terminate(admin, conn, false);
        return;
    }
}

pub export fn Curl_cshutdn_perform(
    cs: *cshutdn,
    admin: ?*vdns_cfilters.Curl_easy,
    sigpipe_ctx: ?*CurlSigpipeCtx,
) callconv(.c) void {
    cshutdnPerform(cs, admin, sigpipe_ctx);
}

pub export fn Curl_cshutdn_setfds(
    cs: *cshutdn,
    admin: ?*anyopaque,
    read_fd_set: ?*anyopaque,
    write_fd_set: ?*anyopaque,
    maxfd: *c_int,
) callconv(.c) void {
    if (cs.conns.n != 0) {
        var ps: headers_sock.EasyPollset = undefined;
        headers_sock.Curl_pollset_init(&ps);
        defer headers_sock.Curl_pollset_cleanup(&ps);

        var i: u32 = 0;
        while (i < cs.conns.n) : (i += 1) {
            const conn = cs.conns.data.?[i];
            headers_sock.Curl_pollset_reset(&ps);
            Curl_attach_connection(admin, conn, false);
            const result = Curl_conn_adjust_pollset(admin, conn, &ps);
            Curl_detach_connection(admin);
            if (result != CURLE_OK)
                continue;

            const sockets = ps.sockets.?;
            const actions = ps.actions.?;
            for (0..ps.n) |j| {
                Curl_cshutdn_fdset_apply(sockets[j], actions[j], read_fd_set, write_fd_set, maxfd);
            }
        }
    }
}

pub export fn Curl_cshutdn_add_waitfds(
    cs: *cshutdn,
    admin: ?*anyopaque,
    cwfds: *headers_sock.CurlWaitfds,
) callconv(.c) c_uint {
    var need: c_uint = 0;
    if (cs.conns.n != 0) {
        var ps: headers_sock.EasyPollset = undefined;
        headers_sock.Curl_pollset_init(&ps);
        defer headers_sock.Curl_pollset_cleanup(&ps);

        var i: u32 = 0;
        while (i < cs.conns.n) : (i += 1) {
            const conn = cs.conns.data.?[i];
            headers_sock.Curl_pollset_reset(&ps);
            Curl_attach_connection(admin, conn, false);
            const result = Curl_conn_adjust_pollset(admin, conn, &ps);
            Curl_detach_connection(admin);
            if (result == CURLE_OK) {
                need += headers_sock.Curl_waitfds_add_ps(cwfds, &ps);
            }
        }
    }
    return need;
}

pub export fn Curl_cshutdn_add_pollfds(
    cs: *cshutdn,
    admin: ?*anyopaque,
    cpfds: *headers_sock.CurlPollfds,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (cs.conns.n != 0) {
        var ps: headers_sock.EasyPollset = undefined;
        headers_sock.Curl_pollset_init(&ps);
        defer headers_sock.Curl_pollset_cleanup(&ps);

        var i: u32 = 0;
        while (i < cs.conns.n) : (i += 1) {
            const conn = cs.conns.data.?[i];
            headers_sock.Curl_pollset_reset(&ps);
            Curl_attach_connection(admin, conn, false);
            result = Curl_conn_adjust_pollset(admin, conn, &ps);
            Curl_detach_connection(admin);
            if (result == CURLE_OK) {
                result = headers_sock.Curl_pollfds_add_ps(cpfds, &ps);
            }
            if (result != CURLE_OK) {
                headers_sock.Curl_pollfds_cleanup(cpfds);
                return result;
            }
        }
    }
    return result;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "AWS SigV4 canon_path and canon_query" {
    var path_buf: dynbuf = undefined;
    containers.curlx_dyn_init(&path_buf, 1024);
    defer containers.curlx_dyn_free(&path_buf);

    try std.testing.expectEqual(CURLE_OK, canon_path("", 0, &path_buf, true));
    try std.testing.expectEqualStrings("/", std.mem.span(containers.curlx_dyn_ptr(&path_buf).?));

    containers.curlx_dyn_reset(&path_buf);
    try std.testing.expectEqual(CURLE_OK, canon_path("/my path/file+name", 18, &path_buf, true));
    try std.testing.expectEqualStrings("/my%20path/file%2Bname", std.mem.span(containers.curlx_dyn_ptr(&path_buf).?));

    var query_buf: dynbuf = undefined;
    containers.curlx_dyn_init(&query_buf, 1024);
    defer containers.curlx_dyn_free(&query_buf);

    try std.testing.expectEqual(CURLE_OK, canon_query("b=2&a=1&a=0&empty&plus=a+b%2Bc", &query_buf));
    try std.testing.expectEqualStrings(
        "a=0&a=1&b=2&empty=&plus=a%20b%2Bc",
        std.mem.span(containers.curlx_dyn_ptr(&query_buf).?),
    );
}

test "Curl_headers_push and cleanup lifecycle" {
    var httphdrs: Curl_llist = undefined;
    containers.Curl_llist_init(&httphdrs, null);
    var headerout: [2]curl_header = undefined;
    var nh_origin: c_uint = 0;
    var nh_request: c_int = 0;
    var nh_count: usize = 0;
    var requests: c_int = 0;
    var dummy_easy: u64 = 0x1234;
    const easy_ptr: *anyopaque = &dummy_easy;

    Curl_headers_Register(easy_ptr, &httphdrs, &headerout, &nh_origin, &nh_request, &nh_count, &requests);
    defer _ = Curl_headers_cleanup(easy_ptr);

    const h1 = "Content-Type: text/plain\r\n";
    const h2 = "X-Custom:   hello world  \r\n";
    try std.testing.expectEqual(CURLE_OK, Curl_headers_push(easy_ptr, h1.ptr, h1.len, @intCast(CURLH_HEADER)));
    try std.testing.expectEqual(CURLE_OK, Curl_headers_push(easy_ptr, h2.ptr, h2.len, @intCast(CURLH_HEADER)));
    try std.testing.expectEqual(@as(usize, 2), containers.Curl_llist_count(&httphdrs));

    const first_node = containers.Curl_llist_head(&httphdrs).?;
    const first_hs = collections.llistElemTyped(Curl_header_store, first_node).?;
    try std.testing.expectEqualStrings("Content-Type", std.mem.span(first_hs.name.?));
    try std.testing.expectEqualStrings("text/plain", std.mem.span(first_hs.value.?));

    const second_node = containers.Curl_node_next(first_node).?;
    const second_hs = collections.llistElemTyped(Curl_header_store, second_node).?;
    try std.testing.expectEqualStrings("X-Custom", std.mem.span(second_hs.name.?));
    try std.testing.expectEqualStrings("hello world", std.mem.span(second_hs.value.?));

    try std.testing.expectEqual(CURLE_OK, Curl_headers_cleanup(easy_ptr));
    try std.testing.expectEqual(@as(usize, 0), containers.Curl_llist_count(&httphdrs));
}

test "Curl_share_lock_share and Curl_cshutdn_init" {
    const LockState = struct {
        var locked_count: usize = 0;
        var unlocked_count: usize = 0;

        fn lockCb(_: ?*anyopaque, _: c_uint, _: c_uint, _: ?*anyopaque) callconv(.c) void {
            locked_count += 1;
        }
        fn unlockCb(_: ?*anyopaque, _: c_uint, _: ?*anyopaque) callconv(.c) void {
            unlocked_count += 1;
        }
    };

    var share: Curl_share = std.mem.zeroes(Curl_share);
    share.magic = CURL_GOOD_SHARE;
    share.specifier = (@as(c_uint, 1) << CURL_LOCK_DATA_SHARE) | (@as(c_uint, 1) << CURL_LOCK_DATA_DNS);
    share.lockfunc = LockState.lockCb;
    share.unlockfunc = LockState.unlockCb;

    try std.testing.expectEqual(CURLSHE_OK, Curl_share_lock_share(&share, null, CURL_LOCK_DATA_DNS, CURL_LOCK_ACCESS_SINGLE));
    try std.testing.expectEqual(@as(usize, 1), LockState.locked_count);
    try std.testing.expectEqual(CURLSHE_OK, Curl_share_unlock_share(&share, null, CURL_LOCK_DATA_DNS));
    try std.testing.expectEqual(@as(usize, 1), LockState.unlocked_count);

    share.ref_count = 1;
    const psl_share_rc = shareSetoptImpl(&share, CURLSHOPT_SHARE, CURL_LOCK_DATA_PSL);
    if (comptime backend_options.psl) {
        try std.testing.expectEqual(CURLSHE_OK, psl_share_rc);
        try std.testing.expect((share.specifier & (@as(c_uint, 1) << CURL_LOCK_DATA_PSL)) != 0);
    } else {
        try std.testing.expectEqual(CURLSHE_NOT_BUILT_IN, psl_share_rc);
    }

    var cs: cshutdn = undefined;
    Curl_cshutdn_init(&cs);
    try std.testing.expectEqual(@as(usize, 0), Curl_cshutdn_count(&cs));
    Curl_cshutdn_destroy(&cs, null);
}
