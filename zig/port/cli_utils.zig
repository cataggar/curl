const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;

pub const CURLUcode = c_uint;
pub const CURLUE_OK: CURLUcode = 0;
pub const CURLUE_OUT_OF_MEMORY: CURLUcode = 7;

pub const CURLUPart = c_uint;
pub const CURLUPART_URL: CURLUPart = 0;
pub const CURLUPART_USER: CURLUPart = 2;
pub const CURLUPART_PASSWORD: CURLUPart = 3;

pub const CURLU_GUESS_SCHEME: c_uint = 1 << 9;

pub const CURLINFO = c_uint;
pub const CURLINFO_STRING: CURLINFO = 0x100000;
pub const CURLINFO_CONTENT_TYPE: CURLINFO = CURLINFO_STRING + 18;
pub const CURLINFO_REFERER: CURLINFO = CURLINFO_STRING + 60;

pub const ParameterError = c_uint;
pub const PARAM_OK: ParameterError = 0;
pub const PARAM_OPTION_UNKNOWN: ParameterError = 1;
pub const PARAM_CONFIG_OPTION_UNKNOWN: ParameterError = 2;
pub const PARAM_REQUIRES_PARAMETER: ParameterError = 3;
pub const PARAM_BAD_USE: ParameterError = 4;
pub const PARAM_HELP_REQUESTED: ParameterError = 5;
pub const PARAM_MANUAL_REQUESTED: ParameterError = 6;
pub const PARAM_VERSION_INFO_REQUESTED: ParameterError = 7;
pub const PARAM_ENGINES_REQUESTED: ParameterError = 8;
pub const PARAM_CA_EMBED_REQUESTED: ParameterError = 9;
pub const PARAM_GOT_EXTRA_PARAMETER: ParameterError = 10;
pub const PARAM_NO_MEM: ParameterError = 15;
pub const PARAM_NEXT_OPERATION: ParameterError = 16;
pub const PARAM_READ_ERROR: ParameterError = 20;
pub const PARAM_EXPAND_ERROR: ParameterError = 21;
pub const PARAM_VAR_SYNTAX: ParameterError = 23;

pub const SANITIZEcode = c_uint;
pub const SANITIZE_ERR_OK: SANITIZEcode = 0;
pub const SANITIZE_ERR_INVALID_PATH: SANITIZEcode = 1;
pub const SANITIZE_ERR_BAD_ARGUMENT: SANITIZEcode = 2;
pub const SANITIZE_ERR_OUT_OF_MEMORY: SANITIZEcode = 3;

pub const SANITIZE_ALLOW_PATH: c_int = 1 << 1;
pub const SANITIZE_ALLOW_RESERVED: c_int = 1 << 2;

pub const CURL_OFF_T_MAX: i64 = std.math.maxInt(i64);
pub const MAX_CONFIG_LINE_LENGTH: usize = 10 * 1024 * 1024;
pub const MAX_EXPAND_CONTENT: usize = 10000000;
pub const MAX_VAR_LEN: usize = 128;
pub const STRERROR_LEN: usize = 256;

pub const Timeval = std.c.timeval;
pub const time_t = if (builtin.os.tag == .windows) i64 else std.c.time_t;
pub const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
pub const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows) std.math.maxInt(usize) else -1;

pub const OperationConfig = opaque {};
pub const CURLU = opaque {};

pub const Dynbuf = extern struct {
    bufr: ?[*]u8,
    leng: usize,
    allc: usize,
    toobig: usize,
};

pub const Curl_str = extern struct {
    str: ?[*]const u8,
    len: usize,
};

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

pub const slist_wc = extern struct {
    first: ?*curl_slist,
    last: ?*curl_slist,
};

pub const tool_var = extern struct {
    next: ?*tool_var,
    content: ?[*:0]const u8,
    clen: usize,
    name: [MAX_VAR_LEN - 1:0]u8,
};

pub const globtype = c_uint;
pub const GLOB_SET: globtype = 1;
pub const GLOB_ASCII: globtype = 2;
pub const GLOB_NUM: globtype = 3;

pub const URLPattern = extern struct {
    type: globtype,
    name: ?[*:0]u8,
    globindex: c_int,
    c: extern union {
        set: extern struct {
            elem: ?[*]?[*:0]u8,
            size: i64,
            idx: i64,
            palloc: usize,
        },
        ascii: extern struct {
            min: c_int,
            max: c_int,
            letter: c_int,
            step: u8,
        },
        num: extern struct {
            min: i64,
            max: i64,
            idx: i64,
            step: i64,
            npad: c_int,
        },
    },
};

pub const URLGlob = extern struct {
    buf: Dynbuf,
    pattern: ?[*]URLPattern,
    literal: bool,
    palloc: usize,
    pnum: usize,
    beenhere: u8,
    err: ?[*:0]const u8,
    pos: usize,
};

// ============================================================================
// Extern declarations from libc, libcurl, and src/tool_*.c
// ============================================================================

const c = struct {
    extern "c" fn malloc(size: usize) ?*anyopaque;
    extern "c" fn calloc(nmemb: usize, size: usize) ?*anyopaque;
    extern "c" fn realloc(ptr: ?*anyopaque, size: usize) ?*anyopaque;
    extern "c" fn free(ptr: ?*anyopaque) void;
    extern "c" fn getenv(name: [*:0]const u8) ?[*:0]u8;
    extern "c" fn fgets(s: [*]u8, n: c_int, stream: ?*anyopaque) ?[*:0]u8;
    extern "c" fn feof(stream: ?*anyopaque) c_int;
    extern "c" fn fputs(s: [*:0]const u8, stream: ?*anyopaque) c_int;
    extern "c" fn fclose(stream: ?*anyopaque) c_int;
    extern "c" fn atexit(func: *const fn () callconv(.c) void) c_int;
};

const posix_c = struct {
    extern "c" fn localtime_r(time: *const time_t, tm: ?*anyopaque) ?*anyopaque;
    extern "c" fn strcasecmp(s1: [*:0]const u8, s2: [*:0]const u8) c_int;
    extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
    extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
    extern "c" fn close(fd: c_int) c_int;
    extern "c" fn mkdir(path: [*:0]const u8, mode: std.c.mode_t) c_int;
    extern "c" fn utimes(path: [*:0]const u8, times: *const [2]Timeval) c_int;
    extern "c" fn fsetxattr(fd: c_int, name: [*:0]const u8, value: *const anyopaque, size: usize, flags: c_int) c_int;
};

const win32 = struct {
    const FILE_READ_ATTRIBUTES: u32 = 0x0080;
    const FILE_WRITE_ATTRIBUTES: u32 = 0x0100;
    const FILE_SHARE_READ: u32 = 0x00000001;
    const FILE_SHARE_WRITE: u32 = 0x00000002;
    const FILE_SHARE_DELETE: u32 = 0x00000004;
    const OPEN_EXISTING: u32 = 3;
    const ERROR_FILE_NOT_FOUND: u32 = 2;
    const MAX_PATH: usize = 260;

    const STD_INPUT_HANDLE: u32 = @bitCast(@as(i32, -10));
    const STD_OUTPUT_HANDLE: u32 = @bitCast(@as(i32, -11));
    const ENABLE_VIRTUAL_TERMINAL_PROCESSING: u32 = 0x0004;
    const CTRL_C_EVENT: u32 = 0;
    const CTRL_BREAK_EVENT: u32 = 1;
    const DUPLICATE_SAME_ACCESS: u32 = 0x00000002;

    const PLATFORM_WINNT: c_uint = 2;
    const VERSION_GREATER_THAN_EQUAL: c_uint = 3;

    const AF_INET: c_int = 2;
    const SOCK_STREAM: c_int = 1;
    const IPPROTO_TCP: c_int = 6;
    const SOL_SOCKET: c_int = 0xffff;
    const SO_ERROR: c_int = 0x1007;
    const SHUT_WR: c_int = 1;
    const WSAEWOULDBLOCK: c_int = 10035;

    const FILETIME = extern struct {
        dwLowDateTime: u32,
        dwHighDateTime: u32,
    };

    const SYSTEMTIME = extern struct {
        wYear: u16,
        wMonth: u16,
        wDayOfWeek: u16,
        wDay: u16,
        wHour: u16,
        wMinute: u16,
        wSecond: u16,
        wMilliseconds: u16,
    };

    const CRITICAL_SECTION = extern struct {
        DebugInfo: ?*anyopaque,
        LockCount: c_long,
        RecursionCount: c_long,
        OwningThread: ?*anyopaque,
        LockSemaphore: ?*anyopaque,
        SpinCount: usize,
    };

    const sockaddr_in = extern struct {
        sin_family: i16,
        sin_port: u16,
        sin_addr: u32,
        sin_zero: [8]u8,
    };

    const fd_set = extern struct {
        fd_count: c_uint,
        fd_array: [64]curl_socket_t,
    };

    fn invalidHandleValue() ?*anyopaque {
        return @ptrFromInt(std.math.maxInt(usize));
    }

    extern "c" fn _localtime64_s(tm: ?*anyopaque, time: *const time_t) c_int;
    extern "c" fn _stricmp(s1: [*:0]const u8, s2: [*:0]const u8) c_int;
    extern "c" fn _fullpath(absPath: ?[*]u8, relPath: [*:0]const u8, maxLength: usize) ?[*:0]u8;
    extern "c" fn _close(fd: c_int) c_int;
    extern "c" fn _get_osfhandle(fd: c_int) isize;
    extern "c" fn _lseeki64(fd: c_int, offset: i64, origin: c_int) i64;

    extern "kernel32" fn GetFileTime(
        hFile: ?*anyopaque,
        lpCreationTime: ?*FILETIME,
        lpLastAccessTime: ?*FILETIME,
        lpLastWriteTime: *FILETIME,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn SetFileTime(
        hFile: ?*anyopaque,
        lpCreationTime: ?*const FILETIME,
        lpLastAccessTime: ?*const FILETIME,
        lpLastWriteTime: *const FILETIME,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn CloseHandle(hObject: ?*anyopaque) callconv(.winapi) c_int;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn GetSystemTime(lpSystemTime: *SYSTEMTIME) callconv(.winapi) void;
    extern "kernel32" fn SystemTimeToFileTime(lpSystemTime: *const SYSTEMTIME, lpFileTime: *FILETIME) callconv(.winapi) c_int;
    extern "kernel32" fn GetModuleFileNameA(hModule: ?*anyopaque, lpFilename: [*]u8, nSize: u32) callconv(.winapi) u32;
    extern "kernel32" fn SetEndOfFile(hFile: ?*anyopaque) callconv(.winapi) c_int;
    extern "kernel32" fn SearchPathA(
        lpPath: ?[*:0]const u8,
        lpFileName: [*:0]const u8,
        lpExtension: ?[*:0]const u8,
        nBufferLength: u32,
        lpBuffer: [*]u8,
        lpFilePart: *?[*:0]u8,
    ) callconv(.winapi) u32;
    extern "kernel32" fn GetStdHandle(nStdHandle: u32) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn SetStdHandle(nStdHandle: u32, hHandle: ?*anyopaque) callconv(.winapi) c_int;
    extern "kernel32" fn GetConsoleMode(hConsoleHandle: ?*anyopaque, lpMode: *u32) callconv(.winapi) c_int;
    extern "kernel32" fn SetConsoleMode(hConsoleHandle: ?*anyopaque, dwMode: u32) callconv(.winapi) c_int;
    extern "kernel32" fn SetConsoleCtrlHandler(
        HandlerRoutine: *const fn (u32) callconv(.winapi) c_int,
        Add: c_int,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn InitializeCriticalSection(lpCriticalSection: *CRITICAL_SECTION) callconv(.winapi) void;
    extern "kernel32" fn EnterCriticalSection(lpCriticalSection: *CRITICAL_SECTION) callconv(.winapi) void;
    extern "kernel32" fn LeaveCriticalSection(lpCriticalSection: *CRITICAL_SECTION) callconv(.winapi) void;
    extern "kernel32" fn DeleteCriticalSection(lpCriticalSection: *CRITICAL_SECTION) callconv(.winapi) void;
    extern "kernel32" fn ReadFile(
        hFile: ?*anyopaque,
        lpBuffer: [*]u8,
        nNumberOfBytesToRead: u32,
        lpNumberOfBytesRead: *u32,
        lpOverlapped: ?*anyopaque,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn GetCurrentProcess() callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn DuplicateHandle(
        hSourceProcessHandle: ?*anyopaque,
        hSourceHandle: ?*anyopaque,
        hTargetProcessHandle: ?*anyopaque,
        lpTargetHandle: *?*anyopaque,
        dwDesiredAccess: u32,
        bInheritHandle: c_int,
        dwOptions: u32,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn CreateThread(
        lpThreadAttributes: ?*anyopaque,
        dwStackSize: usize,
        lpStartAddress: *const fn (?*anyopaque) callconv(.winapi) u32,
        lpParameter: ?*anyopaque,
        dwCreationFlags: u32,
        lpThreadId: ?*u32,
    ) callconv(.winapi) ?*anyopaque;

    extern "ws2_32" fn socket(af: c_int, sock_type: c_int, protocol: c_int) callconv(.winapi) curl_socket_t;
    extern "ws2_32" fn bind(s: curl_socket_t, name: *const anyopaque, namelen: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn getsockname(s: curl_socket_t, name: *anyopaque, namelen: *c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn listen(s: curl_socket_t, backlog: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn connect(s: curl_socket_t, name: *const anyopaque, namelen: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn accept(s: curl_socket_t, addr: ?*anyopaque, addrlen: ?*c_int) callconv(.winapi) curl_socket_t;
    extern "ws2_32" fn closesocket(s: curl_socket_t) callconv(.winapi) c_int;
    extern "ws2_32" fn shutdown(s: curl_socket_t, how: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn recv(s: curl_socket_t, buf: [*]u8, len: c_int, flags: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn send(s: curl_socket_t, buf: [*]const u8, len: c_int, flags: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn select(nfds: c_int, readfds: ?*fd_set, writefds: ?*fd_set, exceptfds: ?*fd_set, timeout: ?*const Timeval) callconv(.winapi) c_int;
    extern "ws2_32" fn getsockopt(s: curl_socket_t, level: c_int, optname: c_int, optval: [*]u8, optlen: *c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn WSAGetLastError() callconv(.winapi) c_int;

    extern fn curlx_CreateFile(
        filename: ?[*:0]const u8,
        dwDesiredAccess: u32,
        dwShareMode: u32,
        lpSecurityAttributes: ?*anyopaque,
        dwCreationDisposition: u32,
        dwFlagsAndAttributes: u32,
        hTemplateFile: ?*anyopaque,
    ) callconv(.c) ?*anyopaque;
    extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn curlx_win32_open(filename: ?[*:0]const u8, oflag: c_int, pmode: c_int) callconv(.c) c_int;
    extern fn curlx_win32_mkdir(path: ?[*:0]const u8) callconv(.c) c_int;
    extern fn curlx_verify_windows_init() callconv(.c) void;
    extern fn curlx_verify_windows_version(
        majorVersion: c_uint,
        minorVersion: c_uint,
        buildVersion: c_uint,
        platform: c_uint,
        condition: c_uint,
    ) callconv(.c) bool;
    extern fn curlx_now_init() callconv(.c) void;
    extern fn curlx_nonblock(sockfd: curl_socket_t, nonblock: bool) callconv(.c) c_int;
    extern fn curlx_win32_random(entropy: [*]u8, length: usize) callconv(.c) CURLcode;
    extern fn tool_zig_set_config_cacert(config: *OperationConfig, cacert: ?[*:0]u8) callconv(.c) void;
};

// libcurl / curlx externs
extern fn curl_slist_append(list: ?*curl_slist, data: [*:0]const u8) callconv(.c) ?*curl_slist;
extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;
extern fn curl_easy_escape(handle: ?*anyopaque, string: [*]const u8, length: c_int) callconv(.c) ?[*:0]u8;
extern fn curl_easy_getinfo(curl: ?*anyopaque, info: CURLINFO, ...) callconv(.c) CURLcode;
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
extern fn curl_getenv(variable: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn curl_strnequal(s1: [*:0]const u8, s2: [*:0]const u8, max: usize) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_mfprintf(fd: ?*anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_url() callconv(.c) ?*CURLU;
extern fn curl_url_cleanup(handle: ?*CURLU) callconv(.c) void;
extern fn curl_url_set(handle: ?*CURLU, what: CURLUPart, part: ?[*:0]const u8, flags: c_uint) callconv(.c) CURLUcode;
extern fn curl_url_get(handle: ?*const CURLU, what: CURLUPart, part: *?[*:0]u8, flags: c_uint) callconv(.c) CURLUcode;

extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_reset(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *Dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_add(s: *Dynbuf, str: [*:0]const u8) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;
extern fn curlx_dyn_setlen(s: *Dynbuf, set: usize) callconv(.c) CURLcode;

extern fn curlx_base64_encode(inputbuff: [*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_base64_decode(src: [*:0]const u8, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
extern fn curlx_basename(path: [*:0]u8) callconv(.c) [*:0]u8;

extern fn curlx_str_init(out: *Curl_str) callconv(.c) void;
extern fn curlx_str_until(linep: *[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_passblanks(linep: *[*:0]const u8) callconv(.c) void;
extern fn curlx_str_cmp(str: *const Curl_str, compare: [*:0]const u8) callconv(.c) bool;

// CLI C helpers in src/tool_*.c
extern fn jsonquoted(in: [*]const u8, len: usize, out: *Dynbuf, lowercase: bool) callconv(.c) c_int;
extern fn file2memory_range(bufp: *?[*:0]u8, size: *usize, file: ?*anyopaque, starto: i64, endo: i64) callconv(.c) ParameterError;
extern fn getparameter(flag: [*:0]const u8, nextarg: ?[*:0]const u8, usedarg: *bool, config: ?*OperationConfig, max_recursive: c_int) callconv(.c) ParameterError;
extern fn param2text(err: ParameterError) callconv(.c) [*:0]const u8;

extern fn tool_zig_get_variables() callconv(.c) ?*tool_var;
extern fn tool_zig_set_variables(v: ?*tool_var) callconv(.c) void;
extern fn tool_zig_get_global_last() callconv(.c) ?*OperationConfig;
extern fn tool_zig_next_operation(configp: *?*OperationConfig) callconv(.c) bool;
extern fn tool_zig_stdin() callconv(.c) ?*anyopaque;
extern fn tool_zig_get_errno() callconv(.c) c_int;
extern fn tool_zig_errno_is_acces_or_exist() callconv(.c) bool;
extern fn tool_zig_show_dir_errno(name: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_stat_mtime(filename: [*:0]const u8, stamp: *i64) callconv(.c) c_int;
extern fn tool_zig_get_pw_dir() callconv(.c) ?[*:0]const u8;

extern fn tool_zig_errorf_0(msg: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_errorf_s(fmt: [*:0]const u8, s: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_errorf_ss(fmt: [*:0]const u8, s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_errorf_ns(fmt: [*:0]const u8, n: c_int, s: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_errorf_d(fmt: [*:0]const u8, d: c_int) callconv(.c) void;
extern fn tool_zig_errorf_lx(fmt: [*:0]const u8, lx: c_ulong) callconv(.c) void;
extern fn tool_zig_errorf_cfg(display: [*:0]const u8, lineno: c_int, option: [*:0]const u8, reason: [*:0]const u8) callconv(.c) void;

extern fn tool_zig_warnf_0(msg: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_warnf_s(fmt: [*:0]const u8, s: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_warnf_zu(fmt: [*:0]const u8, n: usize) callconv(.c) void;
extern fn tool_zig_warnf_lx(fmt: [*:0]const u8, lx: c_ulong) callconv(.c) void;
extern fn tool_zig_warnf_off_lx(fmt: [*:0]const u8, off: i64, lx: c_ulong) callconv(.c) void;
extern fn tool_zig_warnf_off_ss(fmt: [*:0]const u8, off: i64, s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) void;
extern fn tool_zig_warnf_cfg(fmt: [*:0]const u8, filename: [*:0]const u8, lineno: c_int, option: [*:0]const u8) callconv(.c) void;

extern fn tool_zig_notef_s(fmt: [*:0]const u8, s: [*:0]const u8) callconv(.c) void;

// ============================================================================
// Internal memory / ctype / file helpers
// ============================================================================

inline fn isBlank(ch: u8) bool {
    return ch == ' ' or ch == '\t';
}

inline fn isSpace(ch: u8) bool {
    return isBlank(ch) or (ch >= 0x0a and ch <= 0x0d);
}

inline fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

inline fn isAlpha(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z');
}

inline fn isAlnum(ch: u8) bool {
    return isDigit(ch) or isAlpha(ch);
}

fn cDup0(src: ?[*]const u8, length: usize) ?[*:0]u8 {
    return mem.memdup0(src orelse "", length);
}

fn cStrdup(s: [*:0]const u8) ?[*:0]u8 {
    return mem.strdup(s);
}

inline fn toolFopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque {
    if (builtin.os.tag == .windows) {
        return win32.curlx_win32_fopen(filename, mode);
    } else {
        return posix_c.fopen(filename, mode);
    }
}

inline fn toolFclose(file: ?*anyopaque) void {
    _ = c.fclose(file);
}

inline fn toolOpenReadOnly(filename: [*:0]const u8) c_int {
    if (builtin.os.tag == .windows) {
        return win32.curlx_win32_open(filename, 0, 0);
    } else {
        return posix_c.open(filename, 0);
    }
}

inline fn toolClose(fd: c_int) void {
    if (builtin.os.tag == .windows) {
        _ = win32._close(fd);
    } else {
        _ = posix_c.close(fd);
    }
}

inline fn toolMkdir(path: [*:0]const u8) c_int {
    if (builtin.os.tag == .windows) {
        return win32.curlx_win32_mkdir(path);
    } else {
        return posix_c.mkdir(path, 0o0750);
    }
}

// ============================================================================
// 1. src/toolx/tool_time.c
// ============================================================================

pub export fn toolx_localtime(intime: time_t, store: ?*anyopaque) callconv(.c) CURLcode {
    var t = intime;
    if (builtin.os.tag == .windows) {
        if (win32._localtime64_s(store, &t) != 0) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    } else {
        if (posix_c.localtime_r(&t, store) == null) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    }
    return CURLE_OK;
}

pub export fn toolx_tvnow() callconv(.c) Timeval {
    return tvrealnow();
}

// ============================================================================
// 2. src/slist_wc.c
// ============================================================================

fn slistWcAppendInner(list_in: ?*slist_wc, data: [*:0]const u8) error{OutOfMemory}!*slist_wc {
    const new_item = curl_slist_append(null, data) orelse return error.OutOfMemory;
    errdefer curl_slist_free_all(new_item);

    if (list_in == null) {
        const list = mem.alloc(slist_wc) orelse return error.OutOfMemory;
        list.first = new_item;
        list.last = new_item;
        return list;
    }

    const list = list_in.?;
    list.last.?.next = new_item;
    list.last = list.last.?.next;
    return list;
}

pub export fn slist_wc_append(list_in: ?*slist_wc, data: [*:0]const u8) callconv(.c) ?*slist_wc {
    return slistWcAppendInner(list_in, data) catch null;
}

pub export fn slist_wc_free_all(list_opt: ?*slist_wc) callconv(.c) void {
    const list = list_opt orelse return;
    curl_slist_free_all(list.first);
    mem.destroy(list);
}

// ============================================================================
// 3. src/var.c
// ============================================================================

pub export fn varcleanup() callconv(.c) void {
    var list = tool_zig_get_variables();
    while (list) |t| {
        list = t.next;
        mem.freeTyped(t.content);
        mem.destroy(t);
    }
}

fn varcontent(name: [*]const u8, nlen: usize) ?*const tool_var {
    var list = tool_zig_get_variables();
    while (list) |t| : (list = t.next) {
        const t_name: [*:0]const u8 = &t.name;
        if (std.mem.len(t_name) == nlen and std.mem.eql(u8, name[0..nlen], t_name[0..nlen])) {
            return t;
        }
    }
    return null;
}

inline fn endOfFunc(x: u8) bool {
    return x == '}' or x == ':';
}

fn funcMatch(ptr: [*:0]const u8, comptime name: []const u8) bool {
    for (name, 0..) |ch, i| {
        if (ptr[i] != ch) return false;
    }
    return endOfFunc(ptr[name.len]);
}

fn varfuncInner(
    c_in: ?[*:0]const u8,
    clen_in: usize,
    f_in: [*:0]const u8,
    flen: usize,
    out: *Dynbuf,
) error{ OutOfMemory, ExpandError }!void {
    errdefer curlx_dyn_free(out);
    var cur_c: ?[*:0]const u8 = c_in;
    var clen: usize = clen_in;
    var f: [*:0]const u8 = f_in;
    var allocptr: ?[*:0]u8 = null;
    defer mem.free(allocptr);
    const finput = f_in;

    while (f[0] != 0) {
        if (f[0] == '}') break;
        f += 1;

        if (funcMatch(f, "trim")) {
            var len = clen;
            f += "trim".len;
            if (clen > 0) {
                var p = cur_c.?;
                while (len > 0 and isSpace(p[0])) {
                    p += 1;
                    len -= 1;
                }
                while (len > 0 and isSpace(p[len - 1])) {
                    len -= 1;
                }
                cur_c = p;
            }
            curlx_dyn_reset(out);
            if (curlx_dyn_addn(out, cur_c, len) != CURLE_OK) return error.OutOfMemory;
        } else if (funcMatch(f, "json")) {
            f += "json".len;
            curlx_dyn_reset(out);
            if (clen > 0 and jsonquoted(cur_c.?, clen, out, false) != 0) return error.OutOfMemory;
        } else if (funcMatch(f, "url")) {
            f += "url".len;
            curlx_dyn_reset(out);
            if (clen > 0) {
                const enc = curl_easy_escape(null, cur_c.?, @intCast(clen)) orelse return error.OutOfMemory;
                defer curl_free(enc);
                if (curlx_dyn_add(out, enc) != CURLE_OK) return error.OutOfMemory;
            }
        } else if (funcMatch(f, "b64")) {
            f += "b64".len;
            curlx_dyn_reset(out);
            if (clen > 0) {
                var enc: ?[*:0]u8 = null;
                var elen: usize = 0;
                const result = curlx_base64_encode(cur_c.?, clen, &enc, &elen);
                if (result != CURLE_OK) return error.OutOfMemory;
                defer mem.free(enc);
                if (curlx_dyn_addn(out, enc, elen) != CURLE_OK) return error.OutOfMemory;
            }
        } else if (funcMatch(f, "64dec")) {
            f += "64dec".len;
            curlx_dyn_reset(out);
            if (clen > 0) {
                var enc: ?[*]u8 = null;
                var elen: usize = 0;
                const result = curlx_base64_decode(cur_c.?, &enc, &elen);
                if (result != CURLE_OK) {
                    if (curlx_dyn_add(out, "[64dec-fail]") != CURLE_OK) return error.OutOfMemory;
                } else {
                    defer mem.free(enc);
                    if (curlx_dyn_addn(out, enc, elen) != CURLE_OK) return error.OutOfMemory;
                }
            }
        } else {
            tool_zig_errorf_ns("unknown variable function in '%.*s'", @intCast(flen), finput);
            return error.ExpandError;
        }

        mem.free(allocptr);
        clen = curlx_dyn_len(out);
        allocptr = cDup0(curlx_dyn_ptr(out), clen) orelse return error.OutOfMemory;
        cur_c = allocptr.?;
    }
}

fn varfunc(
    c_in: ?[*:0]const u8,
    clen_in: usize,
    f_in: [*:0]const u8,
    flen: usize,
    out: *Dynbuf,
) ParameterError {
    varfuncInner(c_in, clen_in, f_in, flen, out) catch |err| return switch (err) {
        error.OutOfMemory => PARAM_NO_MEM,
        error.ExpandError => PARAM_EXPAND_ERROR,
    };
    return PARAM_OK;
}

fn findSubstrZ(haystack: [*:0]const u8, comptime needle: []const u8) ?[*:0]const u8 {
    const slice = std.mem.span(haystack);
    const idx = std.mem.indexOf(u8, slice, needle) orelse return null;
    return haystack + idx;
}

fn varexpandInner(
    line_in: [*:0]const u8,
    out: *Dynbuf,
    replaced: *bool,
) error{ OutOfMemory, ExpandError }!void {
    var line = line_in;
    var added = false;
    const input = line_in;
    replaced.* = false;
    curlx_dyn_init(out, MAX_EXPAND_CONTENT);
    errdefer curlx_dyn_free(out);

    while (true) {
        var envp = findSubstrZ(line, "{{") orelse break;
        if (@intFromPtr(envp) > @intFromPtr(line) and (envp - 1)[0] == '\\') {
            const prefix_len = (@intFromPtr(envp) - @intFromPtr(line)) - 1;
            if (curlx_dyn_addn(out, line, prefix_len) != CURLE_OK) return error.OutOfMemory;
            if (curlx_dyn_addn(out, "{{", 2) != CURLE_OK) return error.OutOfMemory;
            line = envp + 2;
        } else {
            var name: [MAX_VAR_LEN - 1:0]u8 = undefined;
            const clp = findSubstrZ(envp, "}}") orelse {
                tool_zig_warnf_s("missing close '}}' in '%s'", input);
                break;
            };

            const prefix: usize = 2;
            envp += 2;

            const span_len = @intFromPtr(clp) - @intFromPtr(envp);
            const colon_idx = std.mem.indexOfScalar(u8, envp[0..span_len], ':');
            const funcp: ?[*:0]const u8 = if (colon_idx) |idx| envp + idx else null;
            const nlen: usize = if (colon_idx) |idx| idx else span_len;

            if (nlen == 0 or nlen >= MAX_VAR_LEN) {
                tool_zig_warnf_s("bad variable name length '%s'", input);
                const raw_len = (@intFromPtr(clp) - @intFromPtr(line)) + prefix;
                if (curlx_dyn_addn(out, line, raw_len) != CURLE_OK) return error.OutOfMemory;
            } else {
                const text_before_len = (@intFromPtr(envp) - prefix) - @intFromPtr(line);
                if (curlx_dyn_addn(out, line, text_before_len) != CURLE_OK) return error.OutOfMemory;

                @memcpy(name[0..nlen], envp[0..nlen]);
                name[nlen] = 0;

                var valid_len: usize = 0;
                while (valid_len < nlen and (isAlnum(name[valid_len]) or name[valid_len] == '_')) : (valid_len += 1) {}

                if (valid_len != nlen) {
                    tool_zig_warnf_s("bad variable name: %s", &name);
                    const verbatim_len = (@intFromPtr(clp) - @intFromPtr(envp)) + prefix + 2;
                    if (curlx_dyn_addn(out, envp - prefix, verbatim_len) != CURLE_OK) return error.OutOfMemory;
                } else {
                    var value: ?[*:0]const u8 = null;
                    var vlen: usize = 0;
                    var buf: Dynbuf = undefined;
                    if (varcontent(&name, nlen)) |v| {
                        value = v.content;
                        vlen = v.clen;
                    }

                    curlx_dyn_init(&buf, MAX_EXPAND_CONTENT);
                    defer curlx_dyn_free(&buf);
                    if (funcp) |fp| {
                        const flen = @intFromPtr(clp) - @intFromPtr(fp);
                        try varfuncInner(value, vlen, fp, flen, &buf);
                        value = curlx_dyn_ptr(&buf);
                        vlen = curlx_dyn_len(&buf);
                    }

                    if (value != null and vlen > 0) {
                        if (std.mem.indexOfScalar(u8, value.?[0..vlen], 0) != null) {
                            tool_zig_errorf_0("variable contains NUL byte");
                            return error.ExpandError;
                        }
                    }

                    if (curlx_dyn_addn(out, value, vlen) != CURLE_OK) return error.OutOfMemory;
                    added = true;
                }
            }
            line = clp + 2;
        }
    }

    if (added and line[0] != 0) {
        if (curlx_dyn_add(out, line) != CURLE_OK) return error.OutOfMemory;
    }
    replaced.* = added;
    if (!added) {
        curlx_dyn_free(out);
    }
}

pub export fn varexpand(line_in: [*:0]const u8, out: *Dynbuf, replaced: *bool) callconv(.c) ParameterError {
    varexpandInner(line_in, out, replaced) catch |err| return switch (err) {
        error.OutOfMemory => PARAM_NO_MEM,
        error.ExpandError => PARAM_EXPAND_ERROR,
    };
    return PARAM_OK;
}

fn addvariableInner(
    name: [*]const u8,
    nlen: usize,
    content: ?[*:0]const u8,
    clen: usize,
    contalloc: bool,
) error{OutOfMemory}!void {
    if (varcontent(name, nlen)) |check| {
        tool_zig_notef_s("Overwriting variable '%s'", &check.name);
    }

    const p = mem.create(tool_var) orelse return error.OutOfMemory;
    errdefer mem.destroy(p);
    @memcpy(p.name[0..nlen], name[0..nlen]);
    p.name[nlen] = 0;

    p.content = (if (contalloc) content else cDup0(content, clen)) orelse return error.OutOfMemory;
    p.clen = clen;
    p.next = tool_zig_get_variables();
    tool_zig_set_variables(p);
}

pub export fn addvariable(
    name: [*]const u8,
    nlen: usize,
    content: ?[*:0]const u8,
    clen: usize,
    contalloc: bool,
) callconv(.c) ParameterError {
    addvariableInner(name, nlen, content, clen, contalloc) catch return PARAM_NO_MEM;
    return PARAM_OK;
}

fn setvariableInner(input: [*:0]const u8) error{ OutOfMemory, ExpandError, VarSyntax, ReadError }!void {
    var name: [*:0]const u8 = undefined;
    var nlen: usize = 0;
    var content: ?[*:0]const u8 = null;
    var clen: usize = 0;
    var contalloc = false;
    errdefer if (contalloc) mem.freeTyped(content);
    var line: [*:0]const u8 = input;
    var import = false;
    var ge: ?[*:0]u8 = null;
    var buf: [MAX_VAR_LEN - 1:0]u8 = undefined;
    var startoffset: i64 = 0;
    var endoffset: i64 = CURL_OFF_T_MAX;

    if (input[0] == '%') {
        import = true;
        line += 1;
    }
    name = line;
    while (line[0] != 0 and (isAlnum(line[0]) or line[0] == '_')) {
        line += 1;
    }
    nlen = @intFromPtr(line) - @intFromPtr(name);
    if (nlen == 0 or nlen >= MAX_VAR_LEN) {
        tool_zig_warnf_zu("Bad variable name length (%zu), skipping", nlen);
        return;
    }
    if (import) {
        if (line[0] != 0) {
            @memcpy(buf[0..nlen], name[0..nlen]);
            buf[nlen] = 0;
            name = &buf;
        }
        ge = c.getenv(name);
        if (line[0] == 0 and ge == null) {
            tool_zig_errorf_s("Variable '%s' import fail, not set", name);
            return error.ExpandError;
        } else if (ge) |g| {
            content = g;
            clen = std.mem.len(g);
        }
    }
    if (line[0] == '[' and isDigit(line[1])) {
        line += 1;
        if (curlx_str_number(&line, &startoffset, CURL_OFF_T_MAX) != 0 or
            curlx_str_single(&line, '-') != 0)
        {
            return error.VarSyntax;
        }
        if (curlx_str_single(&line, ']') != 0 and
            (curlx_str_number(&line, &endoffset, CURL_OFF_T_MAX) != 0 or
                curlx_str_single(&line, ']') != 0))
        {
            return error.VarSyntax;
        }
        if (startoffset > endoffset) {
            return error.VarSyntax;
        }
    }
    if (content != null) {
        // already populated from environment
    } else if (line[0] == '@') {
        var file: ?*anyopaque = null;
        line += 1;
        const use_stdin = std.mem.eql(u8, std.mem.span(line), "-");
        if (use_stdin) {
            file = tool_zig_stdin();
        } else {
            file = toolFopen(line, "rb");
            if (file == null) {
                var errbuf: [STRERROR_LEN]u8 = undefined;
                tool_zig_errorf_ss(
                    "Failed to open %s: %s",
                    line,
                    curlx_strerror(tool_zig_get_errno(), &errbuf, errbuf.len),
                );
                return error.ReadError;
            }
        }
        defer if (!use_stdin and file != null) toolFclose(file);
        var file_buf: ?[*:0]u8 = null;
        const range_err = file2memory_range(&file_buf, &clen, file, startoffset, endoffset);
        content = file_buf;
        if (clen != 0) {
            contalloc = true;
        }
        if (range_err != PARAM_OK) {
            return if (range_err == PARAM_NO_MEM) error.OutOfMemory else error.ReadError;
        }
    } else if (line[0] == '=') {
        line += 1;
        clen = std.mem.len(line);
        content = line;
        if (startoffset != 0 or endoffset != CURL_OFF_T_MAX) {
            if (startoffset >= @as(i64, @intCast(clen))) {
                clen = 0;
            } else {
                if (endoffset >= @as(i64, @intCast(clen))) {
                    endoffset = @as(i64, @intCast(clen)) - 1;
                }
                clen = @as(usize, @intCast(endoffset - startoffset)) + 1;
                content = content.? + @as(usize, @intCast(startoffset));
            }
        }
    } else {
        tool_zig_warnf_s("Bad --variable syntax, skipping: %s", input);
        return;
    }

    try addvariableInner(name, nlen, content, clen, contalloc);
}

pub export fn setvariable(input: [*:0]const u8) callconv(.c) ParameterError {
    setvariableInner(input) catch |err| return switch (err) {
        error.OutOfMemory => PARAM_NO_MEM,
        error.ExpandError => PARAM_EXPAND_ERROR,
        error.VarSyntax => PARAM_VAR_SYNTAX,
        error.ReadError => PARAM_READ_ERROR,
    };
    return PARAM_OK;
}

// ============================================================================
// 4. src/tool_xattr.c
// ============================================================================

pub export fn stripcredentials(url: [*:0]const u8) callconv(.c) ?[*:0]u8 {
    const u = curl_url() orelse return null;
    defer curl_url_cleanup(u);

    if (curl_url_set(u, CURLUPART_URL, url, CURLU_GUESS_SCHEME) != CURLUE_OK) return null;
    if (curl_url_set(u, CURLUPART_USER, null, 0) != CURLUE_OK) return null;
    if (curl_url_set(u, CURLUPART_PASSWORD, null, 0) != CURLUE_OK) return null;

    var nurl: ?[*:0]u8 = null;
    if (curl_url_get(u, CURLUPART_URL, &nurl, 0) != CURLUE_OK) return null;
    return nurl;
}

fn xattrSet(fd: c_int, attr: [*:0]const u8, value_opt: ?[*:0]const u8) c_int {
    const value = value_opt orelse return 0;
    if (builtin.os.tag == .linux) {
        return posix_c.fsetxattr(fd, attr, value, std.mem.len(value), 0);
    }
    return 0;
}

fn win32FileStream(curl: ?*anyopaque, fs: ?*anyopaque, url: [*:0]const u8) c_int {
    var err: c_int = 1;
    var value: ?[*:0]const u8 = null;
    const nurl = stripcredentials(url);
    const result = curl_easy_getinfo(curl, CURLINFO_REFERER, &value);

    if (nurl != null and result == CURLE_OK) {
        err = 0;
        if (c.fputs("[ZoneTransfer]\n", fs) < 0) err |= 1;
        if (value) |v| {
            if (c.fputs("ReferrerUrl=", fs) < 0) err |= 1;
            if (c.fputs(v, fs) < 0) err |= 1;
            if (c.fputs("\n", fs) < 0) err |= 1;
        }
        if (c.fputs("HostUrl=", fs) < 0) err |= 1;
        if (c.fputs(nurl.?, fs) < 0) err |= 1;
        if (c.fputs("\n", fs) < 0) err |= 1;
    }
    curl_free(nurl);
    return err;
}

pub export fn fwrite_xattr(
    curl: ?*anyopaque,
    url: [*:0]const u8,
    fd: c_int,
    filename: [*:0]const u8,
) callconv(.c) c_int {
    if (builtin.os.tag == .windows) {
        const fn_abs = win32._fullpath(null, filename, 0) orelse return 1;
        const fn_stream = curl_maprintf("%s:%s", fn_abs, "Zone.Identifier");
        c.free(fn_abs);
        if (fn_stream == null) return 1;

        const fs = win32.curlx_win32_fopen(fn_stream, "wt");
        curl_free(fn_stream);
        if (fs == null) return 1;

        const err = win32FileStream(curl, fs, url);
        toolFclose(fs);
        return err;
    } else if (builtin.os.tag == .linux) {
        var err = xattrSet(fd, "user.creator", "curl");
        const Mapping = struct {
            attr: [*:0]const u8,
            info: CURLINFO,
        };
        const mappings = [_]Mapping{
            .{ .attr = "user.xdg.referrer.url", .info = CURLINFO_REFERER },
            .{ .attr = "user.mime_type", .info = CURLINFO_CONTENT_TYPE },
        };
        for (mappings) |m| {
            if (err != 0) break;
            var value: ?[*:0]const u8 = null;
            const result = curl_easy_getinfo(curl, m.info, &value);
            if (result == CURLE_OK and value != null) {
                err = xattrSet(fd, m.attr, value);
            }
        }
        if (err == 0) {
            const nurl = stripcredentials(url) orelse return 1;
            err = xattrSet(fd, "user.xdg.origin.url", nurl);
            curl_free(nurl);
        }
        return err;
    } else {
        return 0;
    }
}

// ============================================================================
// 5. src/tool_filetime.c
// ============================================================================

pub export fn getfiletime(filename: [*:0]const u8, stamp: *i64) callconv(.c) c_int {
    var rc: c_int = 1;
    if (builtin.os.tag == .windows) {
        const hfile = win32.curlx_CreateFile(
            filename,
            win32.FILE_READ_ATTRIBUTES,
            win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
            null,
            win32.OPEN_EXISTING,
            0,
            null,
        );
        if (hfile != win32.invalidHandleValue()) {
            var ft: win32.FILETIME = undefined;
            if (win32.GetFileTime(hfile, null, null, &ft) != 0) {
                const converted: i64 = @as(i64, ft.dwLowDateTime) | (@as(i64, ft.dwHighDateTime) << 32);
                if (converted < 116444736000000000) {
                    tool_zig_warnf_0("Failed to get filetime: underflow");
                } else {
                    stamp.* = @divTrunc(converted - 116444736000000000, 10000000);
                    rc = 0;
                }
            } else {
                tool_zig_warnf_lx(
                    "Failed to get filetime: GetFileTime failed: GetLastError 0x%08lx",
                    @intCast(win32.GetLastError()),
                );
            }
            _ = win32.CloseHandle(hfile);
        } else if (win32.GetLastError() != win32.ERROR_FILE_NOT_FOUND) {
            tool_zig_warnf_lx(
                "Failed to get filetime: CreateFile failed: GetLastError 0x%08lx",
                @intCast(win32.GetLastError()),
            );
        }
    } else {
        if (tool_zig_stat_mtime(filename, stamp) == 0) {
            rc = 0;
        } else {
            var errbuf: [STRERROR_LEN]u8 = undefined;
            tool_zig_warnf_s(
                "Failed to get filetime: %s",
                curlx_strerror(tool_zig_get_errno(), &errbuf, errbuf.len),
            );
        }
    }
    return rc;
}

pub export fn setfiletime(filetime_in: i64, filename: [*:0]const u8) callconv(.c) void {
    var filetime = filetime_in;
    if (builtin.os.tag == .windows) {
        if (filetime > 910670515199) {
            filetime = 910670515199;
            tool_zig_warnf_0("Capping set filetime to max to avoid overflow");
        } else if (filetime < -6857222400) {
            filetime = -6857222400;
            tool_zig_warnf_0("Capping set filetime to minimum to avoid overflow");
        }

        const hfile = win32.curlx_CreateFile(
            filename,
            win32.FILE_WRITE_ATTRIBUTES,
            win32.FILE_SHARE_READ | win32.FILE_SHARE_WRITE | win32.FILE_SHARE_DELETE,
            null,
            win32.OPEN_EXISTING,
            0,
            null,
        );
        if (hfile != win32.invalidHandleValue()) {
            const converted: i64 = (filetime * 10000000) + 116444736000000000;
            const uconv: u64 = @bitCast(converted);
            const ft = win32.FILETIME{
                .dwLowDateTime = @truncate(uconv),
                .dwHighDateTime = @truncate(uconv >> 32),
            };
            if (win32.SetFileTime(hfile, null, &ft, &ft) == 0) {
                tool_zig_warnf_off_lx(
                    "Failed to set filetime %lld on outfile: SetFileTime failed: GetLastError 0x%08lx",
                    filetime,
                    @intCast(win32.GetLastError()),
                );
            }
            _ = win32.CloseHandle(hfile);
        } else {
            tool_zig_warnf_off_lx(
                "Failed to set filetime %lld on outfile: CreateFile failed: GetLastError 0x%08lx",
                filetime,
                @intCast(win32.GetLastError()),
            );
        }
    } else {
        const times = [2]Timeval{
            .{ .sec = @intCast(filetime), .usec = 0 },
            .{ .sec = @intCast(filetime), .usec = 0 },
        };
        if (posix_c.utimes(filename, &times) != 0) {
            var errbuf: [STRERROR_LEN]u8 = undefined;
            const fmt = if (@sizeOf(c_long) == 8)
                "Failed to set filetime %ld on '%s': %s"
            else
                "Failed to set filetime %lld on '%s': %s";
            tool_zig_warnf_off_ss(
                fmt,
                filetime,
                filename,
                curlx_strerror(tool_zig_get_errno(), &errbuf, errbuf.len),
            );
        }
    }
}

// ============================================================================
// 6. src/tool_urlglob.c
// ============================================================================

fn globerror(glob: *URLGlob, err: ?[*:0]const u8, pos: usize, code: CURLcode) CURLcode {
    glob.err = err;
    glob.pos = pos;
    return code;
}

fn globFixedInner(glob: *URLGlob, fixed: [*]const u8, len: usize) error{OutOfMemory}!void {
    const pat = &glob.pattern.?[glob.pnum];
    pat.type = GLOB_SET;
    pat.globindex = -1;
    pat.c.set.size = 0;
    pat.c.set.idx = 0;
    const elem = mem.allocMany(?[*:0]u8, 1) orelse return error.OutOfMemory;
    errdefer {
        mem.freeTyped(elem);
        pat.c.set.elem = null;
    }
    pat.c.set.elem = elem;
    elem[0] = cDup0(fixed, len) orelse return error.OutOfMemory;

    pat.c.set.palloc = 1;
    pat.c.set.size = 1;
    pat.name = null;
}

fn globFixed(glob: *URLGlob, fixed: [*]const u8, len: usize) CURLcode {
    globFixedInner(glob, fixed, len) catch
        return globerror(glob, null, 0, CURLE_OUT_OF_MEMORY);
    return CURLE_OK;
}

fn multiply(amount: *i64, with: i64) bool {
    if (with <= 0 or amount.* <= 0) {
        amount.* = 0;
        return false;
    }
    const res = @mulWithOverflow(amount.*, with);
    if (res[1] != 0) return true;
    amount.* = res[0];
    return false;
}

fn freeSetElems(elem_opt: ?[*]?[*:0]u8, size: usize) void {
    if (elem_opt) |elem| {
        for (0..size) |i| {
            mem.free(elem[i]);
            elem[i] = null;
        }
        mem.freeTyped(elem);
    }
}

fn globSetInner(
    glob: *URLGlob,
    patternp: *[*:0]const u8,
    posp: *usize,
    amount: *i64,
    globindex: c_int,
    name: *const Curl_str,
) error{ OutOfMemory, UrlMalformat }!void {
    var done = false;
    var pattern = patternp.*;
    const opattern = pattern;
    var size: usize = 0;
    var elem: ?[*]?[*:0]u8 = null;
    var palloc: usize = 0;
    errdefer freeSetElems(elem, size);

    while (!done) {
        switch (pattern[0]) {
            0 => {
                _ = globerror(glob, "unmatched brace", posp.*, CURLE_URL_MALFORMAT);
                return error.UrlMalformat;
            },
            '{', '[' => {
                _ = globerror(glob, "nested brace", posp.*, CURLE_URL_MALFORMAT);
                return error.UrlMalformat;
            },
            '}', ',' => {
                if (pattern[0] == '}') {
                    if (@intFromPtr(opattern) == @intFromPtr(pattern)) {
                        _ = globerror(glob, "empty string within braces", posp.*, CURLE_URL_MALFORMAT);
                        return error.UrlMalformat;
                    }
                    if (multiply(amount, @as(i64, @intCast(size)) + 1)) {
                        _ = globerror(glob, "range overflow", 0, CURLE_URL_MALFORMAT);
                        return error.UrlMalformat;
                    }
                    done = true;
                }

                if (size >= 100000) {
                    _ = globerror(glob, "range overflow", 0, CURLE_URL_MALFORMAT);
                    return error.UrlMalformat;
                }

                if (palloc == 0) {
                    palloc = 5;
                    elem = mem.allocMany(?[*:0]u8, palloc);
                } else if (size >= palloc) {
                    elem = mem.reallocMany(?[*:0]u8, elem, palloc * 2) orelse {
                        _ = globerror(glob, null, 0, CURLE_OUT_OF_MEMORY);
                        return error.OutOfMemory;
                    };
                    palloc *= 2;
                }

                if (elem == null) {
                    _ = globerror(glob, null, 0, CURLE_OUT_OF_MEMORY);
                    return error.OutOfMemory;
                }

                const ptr = curlx_dyn_ptr(&glob.buf) orelse "";
                elem.?[size] = cStrdup(ptr) orelse {
                    _ = globerror(glob, null, 0, CURLE_OUT_OF_MEMORY);
                    return error.OutOfMemory;
                };
                size += 1;
                curlx_dyn_reset(&glob.buf);

                pattern += 1;
                if (!done) {
                    posp.* += 1;
                }
            },
            ']' => {
                _ = globerror(glob, "unexpected close bracket", posp.*, CURLE_URL_MALFORMAT);
                return error.UrlMalformat;
            },
            else => {
                if (pattern[0] == '\\' and pattern[1] != 0) {
                    pattern += 1;
                    posp.* += 1;
                }
                if (curlx_dyn_addn(&glob.buf, pattern, 1) != CURLE_OK) {
                    return error.OutOfMemory;
                }
                pattern += 1;
                posp.* += 1;
            },
        }
    }

    patternp.* = pattern;

    const pat = &glob.pattern.?[glob.pnum];
    pat.type = GLOB_SET;
    pat.globindex = globindex;
    pat.c.set.elem = elem;
    pat.c.set.size = @intCast(size);
    pat.c.set.idx = 0;
    pat.c.set.palloc = palloc;
    errdefer pat.c.set.elem = null;
    if (name.len > 0) {
        pat.name = cDup0(name.str, name.len) orelse return error.OutOfMemory;
    } else {
        pat.name = null;
    }
}

fn globSet(
    glob: *URLGlob,
    patternp: *[*:0]const u8,
    posp: *usize,
    amount: *i64,
    globindex: c_int,
    name: *const Curl_str,
) CURLcode {
    globSetInner(glob, patternp, posp, amount, globindex, name) catch |err| return switch (err) {
        error.OutOfMemory => CURLE_OUT_OF_MEMORY,
        error.UrlMalformat => CURLE_URL_MALFORMAT,
    };
    return CURLE_OK;
}

fn globRange(
    glob: *URLGlob,
    patternp: *[*:0]const u8,
    posp: *usize,
    amount: *i64,
    globindex: c_int,
    name: *const Curl_str,
) CURLcode {
    var pattern = patternp.*;
    const pat = &glob.pattern.?[glob.pnum];
    pat.globindex = globindex;
    pat.name = null;

    if (isAlpha(pattern[0])) {
        var pmatch = false;
        var min_c: u8 = 0;
        var max_c: u8 = 0;
        var end_c: u8 = 0;
        var step: u8 = 1;

        pat.type = GLOB_ASCII;

        if (pattern[1] == '-' and pattern[2] != 0 and pattern[3] != 0) {
            min_c = pattern[0];
            max_c = pattern[2];
            end_c = pattern[3];
            pmatch = true;

            if (end_c == ':') {
                var num: i64 = 0;
                var p: [*:0]const u8 = pattern + 4;
                if (curlx_str_number(&p, &num, 256) != 0 or curlx_str_single(&p, ']') != 0) {
                    step = 0;
                } else {
                    step = @truncate(@as(u64, @intCast(num)));
                }
                pattern = p;
            } else if (end_c != ']') {
                pmatch = false;
            } else {
                pattern += 4;
            }
        }

        posp.* += @intFromPtr(pattern) - @intFromPtr(patternp.*);

        if (!pmatch or step == 0 or
            (min_c == max_c and step != 1) or
            (min_c != max_c and (min_c > max_c or step > (max_c - min_c) or (max_c - min_c) > ('z' - 'a'))))
        {
            return globerror(glob, "bad range", posp.*, CURLE_URL_MALFORMAT);
        }

        pat.c.ascii.step = step;
        pat.c.ascii.min = min_c;
        pat.c.ascii.letter = min_c;
        pat.c.ascii.max = max_c;

        const count: i64 = @divTrunc(@as(i64, pat.c.ascii.max - pat.c.ascii.min), @as(i64, pat.c.ascii.step)) + 1;
        if (multiply(amount, count)) {
            return globerror(glob, "range overflow", posp.*, CURLE_URL_MALFORMAT);
        }
    } else if (isDigit(pattern[0])) {
        var min_n: i64 = 0;
        var max_n: i64 = 0;
        var step_n: i64 = 0;
        var num: i64 = 0;

        pat.type = GLOB_NUM;
        pat.c.num.npad = 0;

        if (pattern[0] == '0') {
            var p = pattern;
            while (isDigit(p[0])) : (p += 1) {
                pat.c.num.npad += 1;
            }
        }

        if (curlx_str_number(&pattern, &num, CURL_OFF_T_MAX) == 0) {
            min_n = num;
            if (curlx_str_single(&pattern, '-') == 0) {
                curlx_str_passblanks(&pattern);
                if (curlx_str_number(&pattern, &num, CURL_OFF_T_MAX) == 0) {
                    max_n = num;
                    if (curlx_str_single(&pattern, ']') == 0) {
                        step_n = 1;
                    } else if (curlx_str_single(&pattern, ':') == 0 and
                        curlx_str_number(&pattern, &num, CURL_OFF_T_MAX) == 0 and
                        curlx_str_single(&pattern, ']') == 0)
                    {
                        step_n = num;
                    }
                }
            }
        }

        posp.* += @intFromPtr(pattern) - @intFromPtr(patternp.*);

        if (step_n <= 0 or
            (min_n == max_n and step_n != 1) or
            (min_n != max_n and (min_n > max_n or step_n > (max_n - min_n))))
        {
            return globerror(glob, "bad range", posp.*, CURLE_URL_MALFORMAT);
        }

        if ((CURL_OFF_T_MAX - step_n) < max_n) {
            return globerror(glob, "range end/step overflow", posp.*, CURLE_URL_MALFORMAT);
        }

        pat.c.num.idx = min_n;
        pat.c.num.min = min_n;
        pat.c.num.max = max_n;
        pat.c.num.step = step_n;

        const count: i64 = @divTrunc(pat.c.num.max - pat.c.num.min, pat.c.num.step) + 1;
        if (multiply(amount, count)) {
            return globerror(glob, "range overflow", posp.*, CURLE_URL_MALFORMAT);
        }
    } else {
        return globerror(glob, "bad range specification", posp.*, CURLE_URL_MALFORMAT);
    }

    if (name.len > 0) {
        pat.name = cDup0(name.str, name.len);
        if (pat.name == null) return CURLE_OUT_OF_MEMORY;
    }
    patternp.* = pattern;
    return CURLE_OK;
}

const MAX_IP6LEN: usize = 128;

fn peekIpv6(str: [*:0]const u8, skip: *usize, ipv6p: *bool) CURLcode {
    var hostname: [MAX_IP6LEN - 1:0]u8 = undefined;
    ipv6p.* = false;
    skip.* = 0;

    const slice = std.mem.span(str);
    const endbr_idx = std.mem.indexOfScalar(u8, slice, ']') orelse return CURLE_OK;
    const hlen = endbr_idx + 1;
    if (hlen >= MAX_IP6LEN) return CURLE_OK;

    const u = curl_url() orelse return CURLE_OUT_OF_MEMORY;
    defer curl_url_cleanup(u);

    @memcpy(hostname[0..hlen], str[0..hlen]);
    hostname[hlen] = 0;

    const rc = curl_url_set(u, CURLUPART_URL, &hostname, CURLU_GUESS_SCHEME);
    if (rc == CURLUE_OUT_OF_MEMORY) return CURLE_OUT_OF_MEMORY;
    if (rc == CURLUE_OK) {
        skip.* = hlen;
        ipv6p.* = true;
    }
    return CURLE_OK;
}

fn addGlob(glob: *URLGlob, pos: usize) CURLcode {
    glob.pnum += 1;
    if (glob.pnum >= glob.palloc) {
        glob.palloc *= 2;
        if (glob.pnum < 255) {
            glob.pattern = mem.reallocMany(URLPattern, glob.pattern, glob.palloc) orelse
                return globerror(glob, null, pos, CURLE_OUT_OF_MEMORY);
        } else {
            return globerror(glob, "too many {} sets", pos, CURLE_URL_MALFORMAT);
        }
    }
    return CURLE_OK;
}

fn globFindName(glob: *URLGlob, name: *const Curl_str) ?*URLPattern {
    const patterns = glob.pattern orelse return null;
    for (0..glob.pnum) |i| {
        if (patterns[i].name) |pname| {
            if (curlx_str_cmp(name, pname)) {
                return &patterns[i];
            }
        }
    }
    return null;
}

const MAX_GLOBNAME_LEN: usize = 64;

fn globParse(glob: *URLGlob, pattern_in: [*:0]const u8, pos_in: usize, amount: *i64) CURLcode {
    var pattern = pattern_in;
    const ipattern = pattern_in;
    var pos = pos_in;
    var result: CURLcode = CURLE_OK;
    var globindex: c_int = 0;

    amount.* = 1;

    while (pattern[0] != 0 and result == CURLE_OK) {
        while (pattern[0] != 0 and pattern[0] != '{') {
            if (pattern[0] == '[') {
                var skip: usize = 0;
                var ipv6 = false;
                result = peekIpv6(pattern, &skip, &ipv6);
                if (result != CURLE_OK) return result;
                if (!ipv6 and pattern[1] == ']') {
                    skip = 2;
                }
                if (skip > 0) {
                    if (curlx_dyn_addn(&glob.buf, pattern, skip) != CURLE_OK) {
                        return CURLE_OUT_OF_MEMORY;
                    }
                    pattern += skip;
                    continue;
                }
                break;
            }
            if (pattern[0] == '}' or pattern[0] == ']') {
                return globerror(glob, "unmatched close brace/bracket", pos, CURLE_URL_MALFORMAT);
            }
            if (pattern[0] == '\\' and
                (pattern[1] == '{' or pattern[1] == '[' or pattern[1] == '}' or pattern[1] == ']'))
            {
                pattern += 1;
                pos += 1;
            }
            if (curlx_dyn_addn(&glob.buf, pattern, 1) != CURLE_OK) {
                return CURLE_OUT_OF_MEMORY;
            }
            pattern += 1;
            pos += 1;
        }

        if (curlx_dyn_len(&glob.buf) > 0) {
            result = globFixed(glob, curlx_dyn_ptr(&glob.buf).?, curlx_dyn_len(&glob.buf));
            if (result == CURLE_OK) {
                result = addGlob(glob, pos);
            }
            curlx_dyn_reset(&glob.buf);
        } else {
            var name: Curl_str = undefined;
            if (pattern[0] == 0) break;
            if (pattern[0] == '{' or pattern[0] == '[') {
                const is_set = (pattern[0] == '{');
                pattern += 1;
                pos += 1;
                const start = pattern;
                if (curlx_str_single(&pattern, '<') != 0 or
                    curlx_str_until(&pattern, &name, MAX_GLOBNAME_LEN, '>') != 0 or
                    curlx_str_single(&pattern, '>') != 0)
                {
                    curlx_str_init(&name);
                    pattern = start;
                } else {
                    if (globFindName(glob, &name) != null) {
                        return globerror(
                            glob,
                            "Duplicate glob name",
                            @intFromPtr(pattern) - @intFromPtr(ipattern),
                            CURLE_URL_MALFORMAT,
                        );
                    }
                    pos += @intFromPtr(pattern) - @intFromPtr(start);
                }

                if (is_set) {
                    result = globSet(glob, &pattern, &pos, amount, globindex, &name);
                } else {
                    result = globRange(glob, &pattern, &pos, amount, globindex, &name);
                }
                globindex += 1;

                if (result == CURLE_OK) {
                    result = addGlob(glob, pos);
                }
            }
        }
    }
    return result;
}

pub export fn glob_inuse(glob: *URLGlob) callconv(.c) bool {
    return glob.palloc != 0 or glob.literal;
}

pub export fn glob_is_literal(glob: *const URLGlob) callconv(.c) bool {
    return glob.literal;
}

pub export fn glob_show_error(
    glob: *URLGlob,
    url: [*:0]const u8,
    error_stream: ?*anyopaque,
    result: CURLcode,
) callconv(.c) void {
    var text: [511:0]u8 = undefined;
    var t: [*:0]const u8 = undefined;
    if (glob.pos != 0) {
        _ = curl_msnprintf(
            &text,
            text.len + 1,
            "%s in position %zu:\n%s\n%*s^",
            glob.err orelse "",
            glob.pos,
            url,
            @as(c_int, @intCast(glob.pos)) - 1,
            " ",
        );
        t = &text;
    } else {
        t = glob.err orelse "";
    }
    _ = curl_mfprintf(error_stream, "curl: (%d) %s\n", @as(c_int, @intCast(result)), t);
}

pub export fn glob_url(
    glob: *URLGlob,
    url: [*:0]const u8,
    urlnum: *i64,
    error_stream: ?*anyopaque,
) callconv(.c) CURLcode {
    var amount: i64 = 0;

    glob.* = std.mem.zeroes(URLGlob);
    curlx_dyn_init(&glob.buf, MAX_CONFIG_LINE_LENGTH);
    if (std.mem.indexOfAny(u8, std.mem.span(url), "{}[]") == null) {
        glob.literal = true;
        urlnum.* = 1;
        return CURLE_OK;
    }

    glob.pattern = mem.allocMany(URLPattern, 2) orelse return CURLE_OUT_OF_MEMORY;
    glob.palloc = 2;

    const result = globParse(glob, url, 1, &amount);
    if (result != CURLE_OK) {
        if (error_stream != null and glob.err != null) {
            glob_show_error(glob, url, error_stream, result);
        }
        urlnum.* = 1;
        return result;
    }
    urlnum.* = amount;
    return CURLE_OK;
}

pub export fn glob_cleanup(glob: *URLGlob) callconv(.c) void {
    glob.literal = false;
    glob.beenhere = 0;
    if (glob.pattern) |patterns| {
        for (0..glob.pnum) |i| {
            if (patterns[i].type == GLOB_SET) {
                if (patterns[i].c.set.elem) |elems| {
                    const count: usize = @intCast(patterns[i].c.set.size);
                    freeSetElems(elems, count);
                    patterns[i].c.set.elem = null;
                }
            }
            mem.free(patterns[i].name);
            patterns[i].name = null;
        }
        mem.free(patterns);
        glob.pattern = null;
        glob.palloc = 0;
        curlx_dyn_free(&glob.buf);
    }
}

fn formatPaddedNum(buf: *[64]u8, npad: c_int, idx: i64) []const u8 {
    var tmp: [32]u8 = undefined;
    const digits = std.fmt.bufPrint(&tmp, "{d}", .{idx}) catch unreachable;
    const pad_width: usize = if (npad > 0) @min(@as(usize, @intCast(npad)), 63) else 0;
    if (pad_width > digits.len) {
        const zeros = pad_width - digits.len;
        @memset(buf[0..zeros], '0');
        @memcpy(buf[zeros .. zeros + digits.len], digits);
        return buf[0..pad_width];
    } else {
        @memcpy(buf[0..digits.len], digits);
        return buf[0..digits.len];
    }
}

pub export fn glob_next_url(globbed: *?[*:0]u8, glob: *URLGlob) callconv(.c) CURLcode {
    globbed.* = null;
    curlx_dyn_reset(&glob.buf);

    const patterns = glob.pattern.?;
    if (glob.beenhere == 0) {
        glob.beenhere = 1;
    } else {
        var carry = true;
        var i: usize = 0;
        while (carry and i < glob.pnum) : (i += 1) {
            carry = false;
            const pat = &patterns[glob.pnum - 1 - i];
            switch (pat.type) {
                GLOB_SET => {
                    if (pat.c.set.elem != null) {
                        pat.c.set.idx += 1;
                        if (pat.c.set.idx == pat.c.set.size) {
                            pat.c.set.idx = 0;
                            carry = true;
                        }
                    }
                },
                GLOB_ASCII => {
                    pat.c.ascii.letter += pat.c.ascii.step;
                    if (pat.c.ascii.letter > pat.c.ascii.max) {
                        pat.c.ascii.letter = pat.c.ascii.min;
                        carry = true;
                    }
                },
                GLOB_NUM => {
                    pat.c.num.idx += pat.c.num.step;
                    if (pat.c.num.idx > pat.c.num.max) {
                        pat.c.num.idx = pat.c.num.min;
                        carry = true;
                    }
                },
                else => return CURLE_FAILED_INIT,
            }
        }
        if (carry) {
            return CURLE_OK;
        }
    }

    for (0..glob.pnum) |i| {
        const pat = &patterns[i];
        switch (pat.type) {
            GLOB_SET => {
                if (pat.c.set.elem) |elems| {
                    const idx: usize = @intCast(pat.c.set.idx);
                    if (curlx_dyn_add(&glob.buf, elems[idx].?) != CURLE_OK) {
                        return CURLE_OUT_OF_MEMORY;
                    }
                }
            },
            GLOB_ASCII => {
                const letter: u8 = @intCast(pat.c.ascii.letter);
                if (curlx_dyn_addn(&glob.buf, &letter, 1) != CURLE_OK) {
                    return CURLE_OUT_OF_MEMORY;
                }
            },
            GLOB_NUM => {
                var num_buf: [64]u8 = undefined;
                const formatted = formatPaddedNum(&num_buf, pat.c.num.npad, pat.c.num.idx);
                if (curlx_dyn_addn(&glob.buf, formatted.ptr, formatted.len) != CURLE_OK) {
                    return CURLE_OUT_OF_MEMORY;
                }
            },
            else => return CURLE_FAILED_INIT,
        }
    }

    const ptr = curlx_dyn_ptr(&glob.buf) orelse "";
    globbed.* = cStrdup(ptr);
    if (globbed.* == null) return CURLE_OUT_OF_MEMORY;
    return CURLE_OK;
}

const MAX_OUTPUT_GLOB_LENGTH: usize = 1024 * 1024;

fn globMatchUrlInner(
    output: *?[*:0]u8,
    filename_in: [*:0]const u8,
    glob: *URLGlob,
    glob2: ?*URLGlob,
    sc: *SANITIZEcode,
) error{ OutOfMemory, BadFunctionArgument, FailedInit }!void {
    var dyn: Dynbuf = undefined;
    var filename = filename_in;
    const ifilename = filename_in;
    output.* = null;
    sc.* = SANITIZE_ERR_OK;

    curlx_dyn_init(&dyn, MAX_OUTPUT_GLOB_LENGTH);
    errdefer curlx_dyn_free(&dyn);

    while (filename[0] != 0) {
        var result: CURLcode = CURLE_OK;
        var pat: ?*URLPattern = null;
        if (glob_inuse(glob) and filename[0] == '#' and isDigit(filename[1])) {
            const ptr = filename;
            filename += 1;
            var num: i64 = 0;
            if (curlx_str_number(&filename, &num, @intCast(glob.pnum)) == 0 and num > 0) {
                num -= 1;
                if (glob.pattern) |patterns| {
                    for (0..glob.pnum) |i| {
                        if (patterns[i].globindex == @as(c_int, @intCast(num))) {
                            pat = &patterns[i];
                            break;
                        }
                    }
                }
            }
            if (pat == null) {
                filename = ptr;
            }
        } else if (filename[0] == '#' and filename[1] == '<') {
            var name: Curl_str = undefined;
            const ptr = filename;
            filename += 2;
            if (curlx_str_until(&filename, &name, MAX_GLOBNAME_LEN, '>') == 0 and
                curlx_str_single(&filename, '>') == 0)
            {
                if (glob_inuse(glob)) {
                    pat = globFindName(glob, &name);
                }
                if (pat == null) {
                    if (glob2) |g2| {
                        if (glob_inuse(g2)) {
                            pat = globFindName(g2, &name);
                        }
                    }
                }
                if (pat == null) {
                    _ = globerror(
                        glob,
                        "no glob exists with this name",
                        @intFromPtr(filename) - @intFromPtr(ifilename),
                        CURLE_BAD_FUNCTION_ARGUMENT,
                    );
                    return error.BadFunctionArgument;
                }
            }
            if (pat == null) {
                filename = ptr;
            }
        }

        if (pat) |p| {
            switch (p.type) {
                GLOB_SET => {
                    if (p.c.set.elem) |elems| {
                        const idx: usize = @intCast(p.c.set.idx);
                        result = curlx_dyn_add(&dyn, elems[idx].?);
                    }
                },
                GLOB_ASCII => {
                    const letter: u8 = @intCast(p.c.ascii.letter);
                    result = curlx_dyn_addn(&dyn, &letter, 1);
                },
                GLOB_NUM => {
                    var num_buf: [64]u8 = undefined;
                    const formatted = formatPaddedNum(&num_buf, p.c.num.npad, p.c.num.idx);
                    result = curlx_dyn_addn(&dyn, formatted.ptr, formatted.len);
                },
                else => return error.FailedInit,
            }
        } else {
            result = curlx_dyn_addn(&dyn, filename, 1);
            filename += 1;
        }
        if (result != CURLE_OK) {
            return error.OutOfMemory;
        }
    }

    if (curlx_dyn_addn(&dyn, "", 0) != CURLE_OK) {
        return error.OutOfMemory;
    }

    if (builtin.os.tag == .windows) {
        var sanitized: ?[*:0]u8 = null;
        sc.* = sanitize_file_name(&sanitized, curlx_dyn_ptr(&dyn), SANITIZE_ALLOW_PATH | SANITIZE_ALLOW_RESERVED);
        if (sc.* != SANITIZE_ERR_OK) {
            return error.BadFunctionArgument;
        }
        curlx_dyn_free(&dyn);
        output.* = sanitized;
    } else {
        output.* = curlx_dyn_ptr(&dyn);
    }
}

pub export fn glob_match_url(
    output: *?[*:0]u8,
    filename_in: [*:0]const u8,
    glob: *URLGlob,
    glob2: ?*URLGlob,
    sc: *SANITIZEcode,
) callconv(.c) CURLcode {
    globMatchUrlInner(output, filename_in, glob, glob2, sc) catch |err| return switch (err) {
        error.OutOfMemory => CURLE_OUT_OF_MEMORY,
        error.BadFunctionArgument => CURLE_BAD_FUNCTION_ARGUMENT,
        error.FailedInit => CURLE_FAILED_INIT,
    };
    return CURLE_OK;
}

// ============================================================================
// 7. src/tool_parsecfg.c
// ============================================================================

inline fn isSep(x: u8, dash: bool) bool {
    return !dash and (x == '=' or x == ':');
}

fn unslashquote(line_in: [*:0]const u8, param: *Dynbuf) c_int {
    var line = line_in;
    curlx_dyn_reset(param);

    while (line[0] != 0 and line[0] != '\"') {
        if (line[0] == '\\') {
            line += 1;
            const ch = line[0];
            if (ch == 0) continue;
            const out: u8 = switch (ch) {
                't' => '\t',
                'n' => '\n',
                'r' => '\r',
                'v' => 0x0b,
                else => ch,
            };
            if (curlx_dyn_addn(param, &out, 1) != CURLE_OK) return 1;
            line += 1;
        } else {
            if (curlx_dyn_addn(param, line, 1) != CURLE_OK) return 1;
            line += 1;
        }
    }
    return 0;
}

fn openConfigFile(
    filename_opt: ?[*:0]const u8,
    namep: *?[*:0]const u8,
    pathalloc: *?[*:0]u8,
) ?*anyopaque {
    var file: ?*anyopaque = null;
    pathalloc.* = null;

    if (filename_opt == null) {
        const dotscore: c_int = if (builtin.os.tag == .windows) 2 else 1;
        if (findfile(".curlrc", dotscore)) |curlrc| {
            const read_mode = if (builtin.os.tag == .windows) "rt" else "r";
            file = toolFopen(curlrc, read_mode);
            if (file == null) {
                c.free(curlrc);
                return null;
            }
            pathalloc.* = curlrc;
            namep.* = curlrc;
        } else if (builtin.os.tag == .windows) {
            var fullp: ?[*:0]u8 = null;
            file = tool_execpath(".curlrc", &fullp);
            if (file == null) {
                file = tool_execpath("_curlrc", &fullp);
            }
            if (file != null) {
                namep.* = fullp;
            }
        }
    } else {
        const filename = filename_opt.?;
        if (!std.mem.eql(u8, std.mem.span(filename), "-")) {
            const read_mode = if (builtin.os.tag == .windows) "rt" else "r";
            file = toolFopen(filename, read_mode);
        } else {
            file = tool_zig_stdin();
            namep.* = "<stdin>";
        }
    }
    return file;
}

fn extractParam(
    line_in: [*:0]u8,
    dashed_option: bool,
    pbuf: *Dynbuf,
    filename: [*:0]const u8,
    lineno: c_int,
    option: [*:0]const u8,
    param_out: *?[*:0]u8,
) ParameterError {
    var line = line_in;
    while (isBlank(line[0]) or isSep(line[0], dashed_option)) {
        line += 1;
    }

    if (line[0] == '\"') {
        line += 1;
        if (unslashquote(line, pbuf) != 0) {
            return PARAM_BAD_USE;
        }
        param_out.* = if (curlx_dyn_len(pbuf) != 0) curlx_dyn_ptr(pbuf) else @constCast("");
    } else {
        if (line[0] == '\'') {
            tool_zig_warnf_cfg(
                "%s:%d Option '%s' uses argument with leading single quote. It is probably a mistake. Consider double quotes.",
                filename,
                lineno,
                option,
            );
        }
        param_out.* = line;
        while (line[0] != 0 and !isSpace(line[0])) {
            line += 1;
        }

        if (line[0] != 0) {
            line[0] = 0;
            line += 1;
            while (isBlank(line[0])) {
                line += 1;
            }
            switch (line[0]) {
                0, '\r', '\n', '#' => {},
                else => {
                    tool_zig_warnf_cfg(
                        "%s:%d Option '%s' uses argument with unquoted whitespace. This may cause side-effects. Consider double quotes.",
                        filename,
                        lineno,
                        option,
                    );
                },
            }
        }
        if (param_out.*.?[0] == 0) {
            param_out.* = null;
        }
    }
    return PARAM_OK;
}

fn processConfigResult(
    res_in: ParameterError,
    configp: *?*OperationConfig,
    param: ?[*:0]const u8,
    usedarg: bool,
    filename: [*:0]const u8,
    lineno: c_int,
    option: [*:0]const u8,
) ParameterError {
    var res = res_in;
    if (res == PARAM_OK and param != null and param.?[0] != 0 and !usedarg) {
        res = PARAM_GOT_EXTRA_PARAMETER;
    }

    if (res == PARAM_NEXT_OPERATION) {
        if (!tool_zig_next_operation(configp)) {
            res = PARAM_NO_MEM;
        }
    }

    if (res != PARAM_OK and res != PARAM_NEXT_OPERATION) {
        var display = filename;
        if (std.mem.eql(u8, std.mem.span(filename), "-")) {
            display = "<stdin>";
        }
        if (res != PARAM_HELP_REQUESTED and
            res != PARAM_MANUAL_REQUESTED and
            res != PARAM_VERSION_INFO_REQUESTED and
            res != PARAM_ENGINES_REQUESTED and
            res != PARAM_CA_EMBED_REQUESTED)
        {
            const reason = param2text(res);
            tool_zig_errorf_cfg(display, lineno, option, reason);
            if (res == PARAM_OPTION_UNKNOWN) {
                res = PARAM_CONFIG_OPTION_UNKNOWN;
            }
            return res;
        }
    }
    return PARAM_OK;
}

pub export fn parseconfig(
    filename_in: ?[*:0]const u8,
    max_recursive: c_int,
    resolved: ?*?[*:0]u8,
) callconv(.c) ParameterError {
    var filename = filename_in;
    var usedarg = false;
    var err: ParameterError = PARAM_OK;
    var config = tool_zig_get_global_last();
    var pathalloc: ?[*:0]u8 = null;

    const file = openConfigFile(filename, &filename, &pathalloc);

    if (file != null) {
        var lineno: c_int = 0;
        var buf: Dynbuf = undefined;
        var pbuf: Dynbuf = undefined;
        var fileerror = false;
        curlx_dyn_init(&buf, MAX_CONFIG_LINE_LENGTH);
        curlx_dyn_init(&pbuf, MAX_CONFIG_LINE_LENGTH);
        const fname = filename.?;

        while (err == PARAM_OK and my_get_line(file, &buf, &fileerror)) {
            lineno += 1;
            var line = curlx_dyn_ptr(&buf) orelse {
                err = PARAM_NO_MEM;
                break;
            };

            const option = line;
            const dashed_option = (option[0] == '-');

            while (line[0] != 0 and !isBlank(line[0]) and !isSep(line[0], dashed_option)) {
                line += 1;
            }

            if (line[0] != 0) {
                line[0] = 0;
                line += 1;
            }

            var param: ?[*:0]u8 = null;
            err = extractParam(line, dashed_option, &pbuf, fname, lineno, option, &param);
            if (err != PARAM_OK) break;

            const res = getparameter(option, param, &usedarg, config, max_recursive);
            config = tool_zig_get_global_last();
            err = processConfigResult(res, &config, param, usedarg, fname, lineno, option);
        }
        curlx_dyn_free(&buf);
        curlx_dyn_free(&pbuf);
        if (file != tool_zig_stdin()) {
            toolFclose(file);
        }
        if (fileerror) {
            err = PARAM_READ_ERROR;
        }
    } else {
        err = PARAM_READ_ERROR;
    }

    if (err == PARAM_READ_ERROR) {
        if (filename) |fname| {
            tool_zig_errorf_s("cannot read config from '%s'", fname);
        }
    }

    if (err == PARAM_OK) {
        if (resolved) |res_out| {
            res_out.* = cStrdup(filename.?);
            if (res_out.* == null) {
                err = PARAM_NO_MEM;
            }
        }
    }
    c.free(pathalloc);
    return err;
}

fn getLine(input: ?*anyopaque, buf: *Dynbuf, err_out: *bool) bool {
    var buffer: [128]u8 = undefined;
    curlx_dyn_reset(buf);
    while (true) {
        const b = c.fgets(&buffer, buffer.len, input);
        if (b) |ptr| {
            const rlen = std.mem.len(ptr);
            if (rlen == 0) break;

            if (curlx_dyn_addn(buf, ptr, rlen) != CURLE_OK) {
                err_out.* = true;
                return false;
            } else if (ptr[rlen - 1] == '\n') {
                const len = curlx_dyn_len(buf);
                if (len > 0) {
                    _ = curlx_dyn_setlen(buf, len - 1);
                }
                return true;
            } else if (c.feof(input) != 0) {
                return true;
            }
        } else if (curlx_dyn_len(buf) > 0) {
            return true;
        } else {
            break;
        }
    }
    return false;
}

pub export fn my_get_line(input: ?*anyopaque, buf: *Dynbuf, err_out: *bool) callconv(.c) bool {
    var retcode = false;
    while (true) {
        retcode = getLine(input, buf, err_out);
        if (!err_out.* and retcode) {
            const len = curlx_dyn_len(buf);
            if (len > 0) {
                var line = curlx_dyn_ptr(buf).?;
                while (isBlank(line[0])) {
                    line += 1;
                }
                if (line[0] == '#' or line[0] == 0) {
                    continue;
                }
            } else {
                continue;
            }
        }
        break;
    }
    return retcode;
}

// ============================================================================
// 8. src/tool_util.c
// ============================================================================

pub export fn tvrealnow() callconv(.c) Timeval {
    var now: Timeval = .{ .sec = 0, .usec = 0 };
    if (builtin.os.tag == .windows) {
        const EPOCH: u64 = 116444736000000000;
        var systime: win32.SYSTEMTIME = undefined;
        var ftime: win32.FILETIME = undefined;
        win32.GetSystemTime(&systime);
        _ = win32.SystemTimeToFileTime(&systime, &ftime);
        const t: u64 = @as(u64, ftime.dwLowDateTime) + (@as(u64, ftime.dwHighDateTime) << 32);
        now.sec = @intCast((t - EPOCH) / 10000000);
        now.usec = @intCast(@as(u32, systime.wMilliseconds) * 1000);
    } else {
        _ = std.c.gettimeofday(&now, null);
    }
    return now;
}

pub export fn struplocompare(p1: ?[*:0]const u8, p2: ?[*:0]const u8) callconv(.c) c_int {
    if (p1 == null) return if (p2 != null) -1 else 0;
    if (p2 == null) return 1;
    if (builtin.os.tag == .windows) {
        return win32._stricmp(p1.?, p2.?);
    } else {
        return posix_c.strcasecmp(p1.?, p2.?);
    }
}

pub export fn struplocompare4sort(p1: *const ?[*:0]const u8, p2: *const ?[*:0]const u8) callconv(.c) c_int {
    return struplocompare(p1.*, p2.*);
}

var execpath_filebuffer: [511:0]u8 = @splat(0);

pub fn tool_execpath(filename: [*:0]const u8, pathp: *?[*:0]u8) callconv(.c) ?*anyopaque {
    if (builtin.os.tag == .windows) {
        const len = win32.GetModuleFileNameA(null, &execpath_filebuffer, execpath_filebuffer.len + 1);
        if (len > 0 and len < execpath_filebuffer.len + 1) {
            if (std.mem.lastIndexOfScalar(u8, execpath_filebuffer[0..len], '\\')) |last_idx| {
                execpath_filebuffer[last_idx] = 0;
                const remaining = execpath_filebuffer.len + 1 - last_idx;
                const fn_len = std.mem.len(filename);
                if (fn_len < remaining - 1) {
                    _ = curl_msnprintf(
                        execpath_filebuffer[last_idx..].ptr,
                        remaining,
                        "\\%s",
                        filename,
                    );
                    pathp.* = &execpath_filebuffer;
                    return win32.curlx_win32_fopen(&execpath_filebuffer, "rt");
                }
            }
        }
    }
    return null;
}

pub fn toolx_ftruncate_win32(fd: c_int, where: i64) callconv(.c) c_int {
    if (builtin.os.tag == .windows) {
        const handle = win32._get_osfhandle(fd);
        if (win32._lseeki64(fd, where, 0) == -1) return -1;
        if (win32.SetEndOfFile(@ptrFromInt(@as(usize, @bitCast(handle)))) == 0) return -1;
        return 0;
    }
    return -1;
}

// ============================================================================
// 9. src/tool_dirhie.c
// ============================================================================

inline fn isPathDelim(ch: u8) bool {
    if (builtin.os.tag == .windows) {
        return ch == '\\' or ch == '/';
    } else {
        return ch == '/';
    }
}

fn strspnDelim(s: [*:0]const u8) usize {
    var i: usize = 0;
    while (s[i] != 0 and isPathDelim(s[i])) : (i += 1) {}
    return i;
}

fn strcspnDelim(s: [*:0]const u8) usize {
    var i: usize = 0;
    while (s[i] != 0 and !isPathDelim(s[i])) : (i += 1) {}
    return i;
}

var mkdir_results: Dynbuf = .{ .bufr = null, .leng = 0, .allc = 0, .toobig = 0 };
var mkdir_trace_enabled: bool = false;

pub export fn create_dir_hierarchy_trace_dynres() callconv(.c) *Dynbuf {
    mkdir_trace_enabled = true;
    return &mkdir_results;
}

fn create_dir_hierarchy_trace_mkdir(dir: [*:0]const u8) c_int {
    if (curlx_dyn_add(&mkdir_results, dir) != CURLE_OK or
        curlx_dyn_add(&mkdir_results, "|") != CURLE_OK)
    {
        return -1;
    }
    return 0;
}

pub export fn create_dir_hierarchy(outfile_in: [*:0]const u8) callconv(.c) CURLcode {
    var outfile = outfile_in;
    var result: CURLcode = CURLE_OK;
    const outlen = std.mem.len(outfile);
    var dirbuf: Dynbuf = undefined;

    curlx_dyn_init(&dirbuf, outlen + 1);

    while (outfile[0] != 0) {
        var skip = false;
        const seplen = strspnDelim(outfile);
        const len = strcspnDelim(outfile + seplen);

        if (outfile[len + seplen] == 0) {
            break;
        }

        if (builtin.os.tag == .windows) {
            if (curlx_dyn_len(&dirbuf) == 0) {
                if (len == 2 and outfile[1] == ':') {
                    skip = true;
                }
            }
        }

        result = curlx_dyn_addn(&dirbuf, outfile, seplen + len);
        if (result != CURLE_OK) {
            return result;
        }

        const dir_ptr = curlx_dyn_ptr(&dirbuf).?;
        const mkdir_rc = if (mkdir_trace_enabled)
            create_dir_hierarchy_trace_mkdir(dir_ptr)
        else
            toolMkdir(dir_ptr);
        if (!skip and mkdir_rc == -1 and !tool_zig_errno_is_acces_or_exist()) {
            tool_zig_show_dir_errno(dir_ptr);
            result = CURLE_WRITE_ERROR;
            break;
        }
        outfile += len + seplen;
    }

    curlx_dyn_free(&dirbuf);
    return result;
}

// ============================================================================
// 10. src/tool_findfile.c
// ============================================================================

const Finder = struct {
    env: [*:0]const u8,
    append: ?[*:0]const u8,
    withoutdot: bool,
};

const conf_list = if (builtin.os.tag == .windows)
    [_]Finder{
        .{ .env = "CURL_HOME", .append = null, .withoutdot = false },
        .{ .env = "XDG_CONFIG_HOME", .append = null, .withoutdot = true },
        .{ .env = "HOME", .append = null, .withoutdot = false },
        .{ .env = "USERPROFILE", .append = null, .withoutdot = false },
        .{ .env = "APPDATA", .append = null, .withoutdot = false },
        .{ .env = "USERPROFILE", .append = "\\Application Data", .withoutdot = false },
        .{ .env = "CURL_HOME", .append = "/.config", .withoutdot = true },
        .{ .env = "HOME", .append = "/.config", .withoutdot = true },
    }
else
    [_]Finder{
        .{ .env = "CURL_HOME", .append = null, .withoutdot = false },
        .{ .env = "XDG_CONFIG_HOME", .append = null, .withoutdot = true },
        .{ .env = "HOME", .append = null, .withoutdot = false },
        .{ .env = "CURL_HOME", .append = "/.config", .withoutdot = true },
        .{ .env = "HOME", .append = "/.config", .withoutdot = true },
    };

fn checkhome(home: [*:0]const u8, fname: [*:0]const u8, dotscore: bool) ?[*:0]u8 {
    const pref = [2]u8{ '.', '_' };
    const dir_char = if (builtin.os.tag == .windows) "\\" else "/";
    const count: usize = if (dotscore) 2 else 1;
    for (0..count) |i| {
        const c_path: ?[*:0]u8 = if (dotscore)
            curl_maprintf("%s" ++ dir_char ++ "%c%s", home, @as(c_int, pref[i]), fname + 1)
        else
            curl_maprintf("%s" ++ dir_char ++ "%s", home, fname);
        if (c_path) |cp| {
            const fd = toolOpenReadOnly(cp);
            if (fd >= 0) {
                const path = cStrdup(cp);
                toolClose(fd);
                curl_free(cp);
                return path;
            }
            curl_free(cp);
        }
    }
    return null;
}

pub export fn findfile(fname: [*:0]const u8, dotscore_in: c_int) callconv(.c) ?[*:0]u8 {
    var dotscore = dotscore_in;
    if (fname[0] == 0) return null;

    for (conf_list) |entry| {
        if (curl_getenv(entry.env)) |home_initial| {
            var home = home_initial;
            var filename = fname;
            if (home[0] == 0) {
                curl_free(home);
                continue;
            }
            if (entry.append) |app| {
                const combined = curl_maprintf("%s%s", home, app);
                curl_free(home);
                if (combined == null) return null;
                home = combined.?;
            }
            if (entry.withoutdot) {
                if (dotscore == 0) {
                    curl_free(home);
                    continue;
                }
                filename += 1;
                dotscore = 0;
            }
            const path = checkhome(home, filename, if (dotscore != 0) (dotscore - 1) != 0 else false);
            curl_free(home);
            if (path != null) return path;
        }
    }

    if (builtin.os.tag != .windows) {
        if (tool_zig_get_pw_dir()) |home| {
            if (home[0] != 0) {
                return checkhome(home, fname, false);
            }
        }
    }
    return null;
}

// ============================================================================
// 11. src/tool_doswin.c
// ============================================================================

fn prefixReserved(p: [*:0]const u8) usize {
    if (curl_strnequal(p, "COM", 3) != 0 or curl_strnequal(p, "LPT", 3) != 0) {
        if (p[3] >= '1' and p[3] <= '9') {
            return 4;
        }
        const len: usize = if (p[3] == 0xc2) 4 else 3;
        const super = p[len];
        switch (super) {
            0xb9, 0xb2, 0xb3 => return len + 1,
            else => return 0,
        }
    } else if (curl_strnequal(p, "CON", 3) != 0 or
        curl_strnequal(p, "PRN", 3) != 0 or
        curl_strnequal(p, "AUX", 3) != 0 or
        curl_strnequal(p, "NUL", 3) != 0)
    {
        return 3;
    } else if (curl_strnequal(p, "CLOCK$", 6) != 0) {
        return 6;
    }
    return 0;
}

pub fn rename_if_reserved_dos(
    sanitized_opt: ?*?[*:0]u8,
    file_name_opt: ?[*:0]const u8,
    flags: c_int,
) callconv(.c) SANITIZEcode {
    const sanitized = sanitized_opt orelse return SANITIZE_ERR_BAD_ARGUMENT;
    const file_name = file_name_opt orelse {
        sanitized.* = null;
        return SANITIZE_ERR_BAD_ARGUMENT;
    };
    sanitized.* = null;

    if ((flags & SANITIZE_ALLOW_PATH) != 0 and file_name[0] == '\\' and file_name[1] == '\\') {
        sanitized.* = cStrdup(file_name);
        return if (sanitized.* != null) SANITIZE_ERR_OK else SANITIZE_ERR_OUT_OF_MEMORY;
    }

    var len = std.mem.len(file_name);
    const bufsize = len + 2 + 1;
    const raw = mem.callocMany(u8, bufsize) orelse return SANITIZE_ERR_OUT_OF_MEMORY;
    @memcpy(raw[0 .. len + 1], file_name[0 .. len + 1]);
    const buffer: [*:0]u8 = raw[0 .. len + 2 :0].ptr;

    var base = curlx_basename(buffer);

    var p_opt: ?[*:0]u8 = buffer;
    while (p_opt) |p| : (p_opt = if (@intFromPtr(p) == @intFromPtr(buffer) and @intFromPtr(buffer) != @intFromPtr(base)) base else null) {
        var x = prefixReserved(p);
        if (x == 0) continue;

        while (p[x] == ' ') : (x += 1) {}

        if (p[x] == '.') {
            p[x] = '_';
            continue;
        } else if (p[x] == ':') {
            if ((flags & SANITIZE_ALLOW_PATH) == 0) {
                p[x] = '_';
                continue;
            }
            x += 1;
        } else if (p[x] != 0) {
            continue;
        }

        const p_len = std.mem.len(p);
        std.mem.copyBackwards(u8, p[1 .. p_len + 2], p[0 .. p_len + 1]);
        p[0] = '_';
        len += 1;

        if (@intFromPtr(p) == @intFromPtr(buffer)) {
            base = curlx_basename(buffer);
        }
    }

    sanitized.* = buffer;
    return SANITIZE_ERR_OK;
}

pub export fn sanitize_file_name(
    sanitized_opt: ?*?[*:0]u8,
    file_name_opt: ?[*:0]const u8,
    flags: c_int,
) callconv(.c) SANITIZEcode {
    const sanitized = sanitized_opt orelse return SANITIZE_ERR_BAD_ARGUMENT;
    sanitized.* = null;
    const file_name = file_name_opt orelse return SANITIZE_ERR_BAD_ARGUMENT;

    const len = std.mem.len(file_name);
    var target = cStrdup(file_name) orelse return SANITIZE_ERR_OUT_OF_MEMORY;

    var p: [*:0]u8 = if ((flags & SANITIZE_ALLOW_PATH) != 0 and
        len >= 4 and std.mem.eql(u8, target[0..4], "\\\\?\\"))
        target + 4
    else
        target;

    while (p[0] != 0) : (p += 1) {
        const ch = p[0];
        if ((ch >= 1 and ch <= 31) or
            ((flags & SANITIZE_ALLOW_PATH) == 0 and ch == ':') or
            ((flags & SANITIZE_ALLOW_PATH) == 0 and (ch == '/' or ch == '\\')))
        {
            p[0] = '_';
            continue;
        }

        if (std.mem.indexOfScalar(u8, "|<>\"?*", ch) != null) {
            p[0] = '_';
        }
    }

    if ((flags & SANITIZE_ALLOW_PATH) == 0 and len > 0) {
        var clip: ?[*]u8 = null;
        var scan: [*]u8 = target + len;
        while (true) {
            scan -= 1;
            if (scan[0] != ' ' and scan[0] != '.') break;
            clip = scan;
            if (@intFromPtr(scan) == @intFromPtr(target)) break;
        }
        if (clip) |cl| {
            cl[0] = 0;
        }
    }

    if ((flags & SANITIZE_ALLOW_RESERVED) == 0) {
        var renamed: ?[*:0]u8 = null;
        const sc = rename_if_reserved_dos(&renamed, target, flags);
        c.free(target);
        if (sc != SANITIZE_ERR_OK) return sc;
        target = renamed.?;
    }

    sanitized.* = target;
    return SANITIZE_ERR_OK;
}

pub var tool_term_has_bold: bool = false;

const TerminalSettingsState = struct {
    hStdOut: ?*anyopaque = null,
    dwOutputMode: u32 = 0,
    valid: i32 = 0,
};

var terminal_settings: TerminalSettingsState = .{};

fn restoreTerminal() callconv(.c) void {
    if (builtin.os.tag == .windows) {
        if (@atomicRmw(i32, &terminal_settings.valid, .Xchg, 0, .seq_cst) != 0) {
            _ = win32.SetConsoleMode(terminal_settings.hStdOut, terminal_settings.dwOutputMode);
        }
    }
}

fn signalHandler(ctrl_type: u32) callconv(.winapi) c_int {
    if (builtin.os.tag == .windows) {
        if (ctrl_type == win32.CTRL_C_EVENT or ctrl_type == win32.CTRL_BREAK_EVENT) {
            restoreTerminal();
        }
    }
    return 0;
}

fn initTerminal() void {
    if (builtin.os.tag == .windows) {
        terminal_settings.hStdOut = win32.GetStdHandle(win32.STD_OUTPUT_HANDLE);
        if (terminal_settings.hStdOut == win32.invalidHandleValue() or
            win32.GetConsoleMode(terminal_settings.hStdOut, &terminal_settings.dwOutputMode) == 0 or
            !win32.curlx_verify_windows_version(
                10,
                0,
                16299,
                win32.PLATFORM_WINNT,
                win32.VERSION_GREATER_THAN_EQUAL,
            ))
        {
            return;
        }

        if ((terminal_settings.dwOutputMode & win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0) {
            tool_term_has_bold = true;
        } else {
            _ = @atomicRmw(i32, &terminal_settings.valid, .Xchg, 1, .seq_cst);
            if (win32.SetConsoleCtrlHandler(&signalHandler, 1) != 0) {
                if (win32.SetConsoleMode(
                    terminal_settings.hStdOut,
                    terminal_settings.dwOutputMode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING,
                ) != 0) {
                    tool_term_has_bold = true;
                    _ = c.atexit(&restoreTerminal);
                } else {
                    _ = win32.SetConsoleCtrlHandler(&signalHandler, 0);
                    _ = @atomicRmw(i32, &terminal_settings.valid, .Xchg, 0, .seq_cst);
                }
            }
        }
    }
}

pub fn FindWin32CACert(config: *OperationConfig, bundle_file: [*:0]const u8) callconv(.c) CURLcode {
    if (builtin.os.tag == .windows) {
        var result: CURLcode = CURLE_OK;
        var buf: [win32.MAX_PATH - 1:0]u8 = undefined;
        buf[0] = 0;
        var ptr: ?[*:0]u8 = null;

        const res_len = win32.SearchPathA(null, bundle_file, null, win32.MAX_PATH, &buf, &ptr);
        if (res_len > 0) {
            const dup = cStrdup(&buf);
            win32.tool_zig_set_config_cacert(config, dup);
            if (dup == null) {
                result = CURLE_OUT_OF_MEMORY;
            }
        }
        return result;
    }
    return CURLE_OK;
}

pub fn win32_init() callconv(.c) CURLcode {
    if (builtin.os.tag == .windows) {
        win32.curlx_verify_windows_init();
        win32.curlx_now_init();
        initTerminal();
    }
    return CURLE_OK;
}

const WinThreadData = struct {
    stdin_handle: ?*anyopaque = null,
    socket_w: curl_socket_t = CURL_SOCKET_BAD,
    crit_sect: win32.CRITICAL_SECTION = std.mem.zeroes(win32.CRITICAL_SECTION),
};

var tdata: WinThreadData = .{};
var stdin_socket_r: curl_socket_t = CURL_SOCKET_BAD;

fn cleanupTdataSync() callconv(.c) void {
    if (builtin.os.tag == .windows) {
        win32.EnterCriticalSection(&tdata.crit_sect);
        if (tdata.stdin_handle) |h| {
            _ = win32.CloseHandle(h);
            tdata.stdin_handle = null;
        }
        if (tdata.socket_w != CURL_SOCKET_BAD) {
            _ = win32.closesocket(tdata.socket_w);
            tdata.socket_w = CURL_SOCKET_BAD;
        }
        win32.LeaveCriticalSection(&tdata.crit_sect);
    }
}

fn winStdinThreadFunc(thread_data: ?*anyopaque) callconv(.winapi) u32 {
    _ = thread_data;
    if (builtin.os.tag == .windows) {
        while (true) {
            var n: u32 = 0;
            var buffer: [8192]u8 = undefined;

            if (win32.ReadFile(tdata.stdin_handle, &buffer, buffer.len, &n, null) == 0)
                break;
            if (n == 0)
                break;
            const nwritten = win32.send(tdata.socket_w, &buffer, @intCast(n), 0);
            if (nwritten == -1)
                break;
            if (@as(u32, @intCast(nwritten)) != n)
                break;
        }

        if (win32.shutdown(tdata.socket_w, win32.SHUT_WR) == 0) {
            var buf: [1024]u8 = undefined;
            while (win32.recv(tdata.socket_w, &buf, buf.len, 0) > 0) {}
        }

        cleanupTdataSync();
    }
    return 0;
}

fn swriteBlockingOnNonblock(nonblock_sock: curl_socket_t, data: [*]const u8, nbytes: usize) c_int {
    if (builtin.os.tag == .windows) {
        var fdwrite: win32.fd_set = std.mem.zeroes(win32.fd_set);
        var fdexcep: win32.fd_set = std.mem.zeroes(win32.fd_set);
        var nwritten: usize = 0;

        fdwrite.fd_count = 1;
        fdwrite.fd_array[0] = nonblock_sock;

        while (nwritten < nbytes) {
            fdexcep.fd_count = 1;
            fdexcep.fd_array[0] = nonblock_sock;

            if (win32.select(0, null, &fdwrite, &fdexcep, null) <= 0) {
                tool_zig_errorf_d("select error: %d", win32.WSAGetLastError());
                return -1;
            }

            if (fdexcep.fd_count > 0 and fdexcep.fd_array[0] == nonblock_sock) {
                var sock_err: c_int = 0;
                var sock_err_size: c_int = @sizeOf(c_int);
                _ = win32.getsockopt(
                    nonblock_sock,
                    win32.SOL_SOCKET,
                    win32.SO_ERROR,
                    std.mem.asBytes(&sock_err).ptr,
                    &sock_err_size,
                );
                tool_zig_errorf_d("connect failure: %d", sock_err);
                return -1;
            }

            const ret = win32.send(nonblock_sock, data + nwritten, @intCast(nbytes - nwritten), 0);
            if (ret <= 0) {
                const err = win32.WSAGetLastError();
                if (err == win32.WSAEWOULDBLOCK) continue;
                tool_zig_errorf_d("socket write error: %d", err);
                return -1;
            }
            nwritten += @intCast(ret);
        }
    }
    return 0;
}

fn readAuthVal(sock: curl_socket_t, auth_val_ptr: *u64) c_int {
    if (builtin.os.tag == .windows) {
        var nread: usize = 0;
        const dst: [*]u8 = std.mem.asBytes(auth_val_ptr).ptr;
        while (nread < @sizeOf(u64)) {
            const ret = win32.recv(sock, dst + nread, @intCast(@sizeOf(u64) - nread), 0);
            if (ret <= 0) {
                if (ret == 0) {
                    tool_zig_errorf_0("stdin relay peer disconnected");
                } else {
                    tool_zig_errorf_d("read error: %d", win32.WSAGetLastError());
                }
                return -1;
            }
            nread += @intCast(ret);
        }
    }
    return 0;
}

pub fn win32_stdin_read_thread() callconv(.c) curl_socket_t {
    if (builtin.os.tag == .windows) {
        var rc: c_int = 0;
        var socket_l: curl_socket_t = CURL_SOCKET_BAD;
        var auth_rnd: u64 = 0;
        var recvd_val: u64 = 1;

        if (stdin_socket_r != CURL_SOCKET_BAD) {
            return stdin_socket_r;
        }

        blk: {
            var socksize: c_int = @sizeOf(win32.sockaddr_in);
            var selfaddr: win32.sockaddr_in = std.mem.zeroes(win32.sockaddr_in);

            win32.InitializeCriticalSection(&tdata.crit_sect);

            socket_l = win32.socket(win32.AF_INET, win32.SOCK_STREAM, win32.IPPROTO_TCP);
            if (socket_l == CURL_SOCKET_BAD) {
                tool_zig_errorf_d("socket() error: %d", win32.WSAGetLastError());
                break :blk;
            }

            selfaddr.sin_family = @intCast(win32.AF_INET);
            selfaddr.sin_addr = std.mem.nativeToBig(u32, 0x7f000001);
            if (win32.bind(socket_l, &selfaddr, socksize) != 0) {
                tool_zig_errorf_d("bind error: %d", win32.WSAGetLastError());
                break :blk;
            }

            if (win32.getsockname(socket_l, &selfaddr, &socksize) != 0) {
                tool_zig_errorf_d("getsockname error: %d", win32.WSAGetLastError());
                break :blk;
            }

            if (win32.listen(socket_l, 1) != 0) {
                tool_zig_errorf_d("listen error: %d", win32.WSAGetLastError());
                break :blk;
            }

            stdin_socket_r = win32.socket(win32.AF_INET, win32.SOCK_STREAM, win32.IPPROTO_TCP);
            if (stdin_socket_r == CURL_SOCKET_BAD) {
                tool_zig_errorf_d("socket error: %d", win32.WSAGetLastError());
                break :blk;
            }

            if (win32.curlx_nonblock(stdin_socket_r, true) != 0) {
                tool_zig_errorf_0("curlx_nonblock() error");
                break :blk;
            }

            if (win32.connect(stdin_socket_r, &selfaddr, socksize) != 0) {
                const sockerr = win32.WSAGetLastError();
                if (sockerr != win32.WSAEWOULDBLOCK) {
                    tool_zig_errorf_d("connect error: %d", sockerr);
                    break :blk;
                }
            }

            tdata.socket_w = win32.accept(socket_l, null, null);
            if (tdata.socket_w == CURL_SOCKET_BAD) {
                tool_zig_errorf_d("accept error: %d", win32.WSAGetLastError());
                break :blk;
            }

            _ = win32.closesocket(socket_l);
            socket_l = CURL_SOCKET_BAD;

            if (win32.curlx_win32_random(std.mem.asBytes(&auth_rnd).ptr, @sizeOf(u64)) != CURLE_OK) {
                tool_zig_errorf_0("curlx_win32_random() error");
                break :blk;
            }

            if (swriteBlockingOnNonblock(stdin_socket_r, std.mem.asBytes(&auth_rnd).ptr, @sizeOf(u64)) != 0)
                break :blk;

            if (readAuthVal(tdata.socket_w, &recvd_val) != 0)
                break :blk;

            if (recvd_val != auth_rnd) {
                tool_zig_errorf_0("relay peer auth failed");
                break :blk;
            }

            if (win32.DuplicateHandle(
                win32.GetCurrentProcess(),
                win32.GetStdHandle(win32.STD_INPUT_HANDLE),
                win32.GetCurrentProcess(),
                &tdata.stdin_handle,
                0,
                0,
                win32.DUPLICATE_SAME_ACCESS,
            ) == 0) {
                tool_zig_errorf_lx("DuplicateHandle error: 0x%08lx", @intCast(win32.GetLastError()));
                break :blk;
            }

            if (win32.SetStdHandle(win32.STD_INPUT_HANDLE, @ptrFromInt(stdin_socket_r)) == 0) {
                tool_zig_errorf_lx("SetStdHandle error: 0x%08lx", @intCast(win32.GetLastError()));
                break :blk;
            }

            const stdin_thread = win32.CreateThread(null, 0, &winStdinThreadFunc, null, 0, null);
            if (stdin_thread == null) {
                tool_zig_errorf_lx("CreateThread error: 0x%08lx", @intCast(win32.GetLastError()));
                break :blk;
            }
            _ = win32.CloseHandle(stdin_thread);
            rc = 1;
        }

        if (rc != 1) {
            if (stdin_socket_r != CURL_SOCKET_BAD) {
                if (win32.GetStdHandle(win32.STD_INPUT_HANDLE) == @as(?*anyopaque, @ptrFromInt(stdin_socket_r)) and
                    tdata.stdin_handle != null)
                {
                    _ = win32.SetStdHandle(win32.STD_INPUT_HANDLE, tdata.stdin_handle);
                    tdata.stdin_handle = null;
                }
                _ = win32.closesocket(stdin_socket_r);
                stdin_socket_r = CURL_SOCKET_BAD;
            }
            if (socket_l != CURL_SOCKET_BAD) {
                _ = win32.closesocket(socket_l);
            }
            cleanupTdataSync();
            win32.DeleteCriticalSection(&tdata.crit_sect);
            return CURL_SOCKET_BAD;
        }

        _ = c.atexit(&cleanupTdataSync);
        return stdin_socket_r;
    }
    return CURL_SOCKET_BAD;
}

comptime {
    if (builtin.os.tag == .windows) {
        @export(&tool_term_has_bold, .{ .name = "tool_term_has_bold" });
        @export(&tool_execpath, .{ .name = "tool_execpath" });
        @export(&toolx_ftruncate_win32, .{ .name = "toolx_ftruncate_win32" });
        @export(&FindWin32CACert, .{ .name = "FindWin32CACert" });
        @export(&win32_init, .{ .name = "win32_init" });
        @export(&win32_stdin_read_thread, .{ .name = "win32_stdin_read_thread" });
        @export(&rename_if_reserved_dos, .{ .name = "rename_if_reserved_dos" });
    }
}
