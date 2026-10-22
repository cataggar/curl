const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");

const CURLE_OK: c_uint = 0;
const CURLE_FAILED_INIT: c_uint = 2;
const CURLE_READ_ERROR: c_uint = 26;

pub const Dynbuf = extern struct {
    bufr: ?[*]u8,
    leng: usize,
    allc: usize,
    toobig: usize,
};

extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_reset(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *Dynbuf, mem: *const anyopaque, len: usize) callconv(.c) c_uint;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;

pub const CurlFileinfoStrings = extern struct {
    time: ?[*:0]u8,
    perm: ?[*:0]u8,
    user: ?[*:0]u8,
    group: ?[*:0]u8,
    target: ?[*:0]u8,
};

pub const CurlFileinfo = extern struct {
    filename: ?[*:0]u8,
    filetype: c_uint,
    time: i64,
    perm: c_uint,
    uid: c_int,
    gid: c_int,
    size: i64,
    hardlinks: c_long,
    strings: CurlFileinfoStrings,
    flags: c_uint,
    b_data: ?[*]u8,
    b_size: usize,
    b_used: usize,
};

pub const CurlLlistNode = extern struct {
    _list: ?*anyopaque,
    _ptr: ?*anyopaque,
    _prev: ?*CurlLlistNode,
    _next: ?*CurlLlistNode,
};

pub const Fileinfo = extern struct {
    info: CurlFileinfo,
    list: CurlLlistNode,
    buf: Dynbuf,
};

const CurlTime = extern struct {
    tv_sec: i64,
    tv_usec: c_int,
};

extern fn fgets(s: [*]u8, n: c_int, stream: ?*anyopaque) callconv(.c) ?[*:0]u8;
extern fn ferror(stream: ?*anyopaque) callconv(.c) c_int;
extern fn feof(stream: ?*anyopaque) callconv(.c) c_int;

const posix_c = struct {
    extern fn getenv(name: [*:0]const u8) callconv(.c) ?[*:0]u8;
    extern fn gethostname(name: [*]u8, namelen: usize) callconv(.c) c_int;
    extern fn fseeko(stream: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) c_int;
};

pub const win32 = struct {
    const CP_UTF8: u32 = 65001;
    const MB_ERR_INVALID_CHARS: u32 = 0x00000008;
    const MAX_PATH: usize = 260;
    const O_CREAT: c_int = 0x0100;
    const SH_DENYNO: c_int = 0x0040;
    const EINVAL: c_int = 22;
    const MOVEFILE_REPLACE_EXISTING: u32 = 0x00000001;
    const FORMAT_MESSAGE_IGNORE_INSERTS: u32 = 0x00000200;
    const FORMAT_MESSAGE_FROM_SYSTEM: u32 = 0x00001000;
    const LANG_NEUTRAL: u32 = 0x00;
    const BCRYPT_USE_SYSTEM_PREFERRED_RNG: u32 = 0x00000002;
    const STATUS_SUCCESS: i32 = 0;

    const VER_MINORVERSION: u32 = 0x0000001;
    const VER_MAJORVERSION: u32 = 0x0000002;
    const VER_BUILDNUMBER: u32 = 0x0000004;
    const VER_PLATFORMID: u32 = 0x0000008;
    const VER_SERVICEPACKMINOR: u32 = 0x0000010;
    const VER_SERVICEPACKMAJOR: u32 = 0x0000020;

    const VER_EQUAL: u8 = 1;
    const VER_GREATER: u8 = 2;
    const VER_GREATER_EQUAL: u8 = 3;
    const VER_LESS: u8 = 4;
    const VER_LESS_EQUAL: u8 = 5;

    const VER_PLATFORM_WIN32_WINDOWS: u32 = 1;
    const VER_PLATFORM_WIN32_NT: u32 = 2;

    const PLATFORM_DONT_CARE: c_uint = 0;
    const PLATFORM_WINDOWS: c_uint = 1;
    const PLATFORM_WINNT: c_uint = 2;

    const VERSION_LESS_THAN: c_uint = 0;
    const VERSION_LESS_THAN_EQUAL: c_uint = 1;
    const VERSION_EQUAL: c_uint = 2;
    const VERSION_GREATER_THAN_EQUAL: c_uint = 3;
    const VERSION_GREATER_THAN: c_uint = 4;

    const OUR_OSVERSIONINFOEXW = extern struct {
        dwOSVersionInfoSize: u32,
        dwMajorVersion: u32,
        dwMinorVersion: u32,
        dwBuildNumber: u32,
        dwPlatformId: u32,
        szCSDVersion: [128]u16,
        wServicePackMajor: u16,
        wServicePackMinor: u16,
        wSuiteMask: u16,
        wProductType: u8,
        wReserved: u8,
    };

    const RtlVerifyVersionInfoFn = *const fn (*OUR_OSVERSIONINFOEXW, u32, u64) callconv(.winapi) c_long;
    var s_pRtlVerifyVersionInfo: ?RtlVerifyVersionInfoFn = null;

    extern "kernel32" fn MultiByteToWideChar(
        CodePage: u32,
        dwFlags: u32,
        lpMultiByteStr: [*:0]const u8,
        cbMultiByte: c_int,
        lpWideCharStr: ?[*]u16,
        cchWideChar: c_int,
    ) callconv(.winapi) c_int;

    extern "kernel32" fn WideCharToMultiByte(
        CodePage: u32,
        dwFlags: u32,
        lpWideCharStr: [*:0]const u16,
        cchWideChar: c_int,
        lpMultiByteStr: ?[*]u8,
        cbMultiByte: c_int,
        lpDefaultChar: ?[*:0]const u8,
        lpUsedDefaultChar: ?*c_int,
    ) callconv(.winapi) c_int;

    extern "kernel32" fn GetModuleHandleA(lpModuleName: ?[*:0]const u8) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn GetProcAddress(hModule: *anyopaque, lpProcName: [*:0]const u8) callconv(.winapi) ?RtlVerifyVersionInfoFn;
    extern "kernel32" fn VerSetConditionMask(ConditionMask: u64, TypeMask: u32, Condition: u8) callconv(.winapi) u64;
    extern "kernel32" fn VerifyVersionInfoW(lpVersionInformation: *OUR_OSVERSIONINFOEXW, dwTypeMask: u32, dwlConditionMask: u64) callconv(.winapi) c_int;
    extern "kernel32" fn GetFullPathNameW(lpFileName: [*:0]const u16, nBufferLength: u32, lpBuffer: ?[*]u16, lpFilePart: ?*?[*:0]u16) callconv(.winapi) u32;
    extern "kernel32" fn CreateFileA(
        lpFileName: [*:0]const u8,
        dwDesiredAccess: u32,
        dwShareMode: u32,
        lpSecurityAttributes: ?*anyopaque,
        dwCreationDisposition: u32,
        dwFlagsAndAttributes: u32,
        hTemplateFile: ?*anyopaque,
    ) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn FindFirstFileA(lpFileName: [*:0]const u8, lpFindFileData: ?*anyopaque) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn MoveFileExA(lpExistingFileName: [*:0]const u8, lpNewFileName: ?[*:0]const u8, dwFlags: u32) callconv(.winapi) c_int;
    extern "kernel32" fn Sleep(dwMilliseconds: u32) callconv(.winapi) void;
    extern "kernel32" fn FormatMessageA(
        dwFlags: u32,
        lpSource: ?*const anyopaque,
        dwMessageId: u32,
        dwLanguageId: u32,
        lpBuffer: [*]u8,
        nSize: u32,
        Arguments: ?*anyopaque,
    ) callconv(.winapi) u32;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn SetLastError(dwErrCode: u32) callconv(.winapi) void;
    extern "kernel32" fn GetEnvironmentVariableA(lpName: ?[*:0]const u8, lpBuffer: ?[*]u8, nSize: u32) callconv(.winapi) u32;

    extern "bcrypt" fn BCryptGenRandom(hAlgorithm: ?*anyopaque, pbBuffer: ?[*]u8, cbBuffer: u32, dwFlags: u32) callconv(.winapi) i32;
    extern "ws2_32" fn gethostname(name: [*]u8, namelen: c_int) callconv(.winapi) c_int;

    extern fn _fseeki64(stream: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) c_int;
    extern fn mbstowcs_s(pReturnValue: *usize, wcstr: ?[*]u16, sizeInWords: usize, mbstr: [*:0]const u8, count: usize) callconv(.c) c_int;
    extern fn wcstombs_s(pReturnValue: *usize, mbstr: ?[*]u8, sizeInBytes: usize, wcstr: [*:0]const u16, count: usize) callconv(.c) c_int;
    extern fn _sopen_s(pfh: *c_int, filename: [*:0]const u8, oflag: c_int, shflag: c_int, pmode: c_int) callconv(.c) c_int;
    extern fn _fsopen(filename: [*:0]const u8, mode: [*:0]const u8, shflag: c_int) callconv(.c) ?*anyopaque;
    extern fn freopen_s(stream: *?*anyopaque, fileName: [*:0]const u8, mode: [*:0]const u8, oldStream: ?*anyopaque) callconv(.c) c_int;
    extern fn _stati64(path: [*:0]const u8, buffer: ?*anyopaque) callconv(.c) c_int;
    extern fn _mkdir(dirname: [*:0]const u8) callconv(.c) c_int;
    extern fn _errno() callconv(.c) *c_int;

    extern fn curlx_pnow(pnow: *CurlTime) callconv(.c) void;
    extern fn curlx_ptimediff_ms(newer: *const CurlTime, older: *const CurlTime) callconv(.c) i64;

    fn invalidHandleValue() ?*anyopaque {
        return @ptrFromInt(std.math.maxInt(usize));
    }

    fn startsWithU8(s: [*:0]const u8, prefix: []const u8) bool {
        for (prefix, 0..) |ch, i| {
            if (s[i] != ch) return false;
        }
        return true;
    }

    fn startsWithU16(s: [*:0]const u16, prefix: []const u8) bool {
        for (prefix, 0..) |ch, i| {
            if (s[i] != @as(u16, ch)) return false;
        }
        return true;
    }

    fn fixExcessivePathInner(in: [*:0]const u8) error{Failed}![*:0]u8 {
        const max_path_len: usize = 32767;
        if (startsWithU8(in, "\\\\?\\"))
            return error.Failed;

        var needed: usize = 0;
        var count: usize = 0;
        if (mbstowcs_s(&needed, null, 0, in, 0) != 0)
            return error.Failed;
        if (needed == 0 or needed >= max_path_len)
            return error.Failed;
        const ibuf = mem.allocMany(u16, needed) orelse return error.Failed;
        defer mem.destroy(ibuf);
        if (mbstowcs_s(&count, ibuf, needed, in, needed - 1) != 0)
            return error.Failed;
        if (count != needed)
            return error.Failed;
        ibuf[needed - 1] = 0;
        const in_w: [*:0]const u16 = ibuf[0 .. needed - 1 :0].ptr;

        needed = @as(usize, GetFullPathNameW(in_w, 0, null, null));
        if (needed == 0 or needed > max_path_len)
            return error.Failed;
        if (needed <= MAX_PATH)
            return error.Failed;

        var fbuf_ptr: ?[*]u16 = mem.allocMany(u16, needed) orelse return error.Failed;
        defer mem.destroy(fbuf_ptr);
        count = @as(usize, GetFullPathNameW(in_w, @intCast(needed), fbuf_ptr.?, null));
        if (count == 0 or count >= needed)
            return error.Failed;
        fbuf_ptr.?[count] = 0;
        var fbuf: [*:0]u16 = fbuf_ptr.?[0..count :0].ptr;

        if (startsWithU16(fbuf, "\\\\?\\")) {
            // do nothing
        } else if (startsWithU16(fbuf, "\\\\.\\")) {
            fbuf[2] = '?';
        } else if (startsWithU16(fbuf, "\\\\.") or startsWithU16(fbuf, "\\\\?")) {
            return error.Failed;
        } else if (startsWithU16(fbuf, "\\\\")) {
            needed = 8 + (count - 2) + 1;
            if (needed > max_path_len)
                return error.Failed;
            const temp = mem.allocMany(u16, needed) orelse return error.Failed;
            const unc_prefix = [_]u16{ '\\', '\\', '?', '\\', 'U', 'N', 'C', '\\' };
            const unc_len = 8 + (count - 2);
            @memcpy(temp[0..8], &unc_prefix);
            @memcpy(temp[8..unc_len], fbuf[2..count]);
            temp[unc_len] = 0;
            mem.destroy(fbuf_ptr);
            fbuf_ptr = temp;
            fbuf = temp[0..unc_len :0].ptr;
        } else {
            needed = 4 + count + 1;
            if (needed > max_path_len)
                return error.Failed;
            const temp = mem.allocMany(u16, needed) orelse return error.Failed;
            const prefix = [_]u16{ '\\', '\\', '?', '\\' };
            const pref_len = 4 + count;
            @memcpy(temp[0..4], &prefix);
            @memcpy(temp[4..pref_len], fbuf[0..count]);
            temp[pref_len] = 0;
            mem.destroy(fbuf_ptr);
            fbuf_ptr = temp;
            fbuf = temp[0..pref_len :0].ptr;
        }

        if (wcstombs_s(&needed, null, 0, fbuf, 0) != 0)
            return error.Failed;
        if (needed == 0 or needed >= max_path_len)
            return error.Failed;
        const obuf = mem.allocMany(u8, needed) orelse return error.Failed;
        errdefer mem.destroy(obuf);
        if (wcstombs_s(&count, obuf, needed, fbuf, needed - 1) != 0 or count != needed) {
            return error.Failed;
        }
        obuf[needed - 1] = 0;
        return obuf[0 .. needed - 1 :0].ptr;
    }

    fn fix_excessive_path(in_opt: ?[*:0]const u8, out: *?[*:0]u8) bool {
        out.* = null;
        const in = in_opt orelse return false;
        out.* = fixExcessivePathInner(in) catch return false;
        return true;
    }

    fn convertUtf8ToWcharInner(s: [*:0]const u8) error{Failed}![*:0]u16 {
        const str_w_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s, -1, null, 0);
        if (str_w_len <= 0) return error.Failed;
        const len: usize = @intCast(str_w_len);
        const str_w = mem.allocMany(u16, len) orelse return error.Failed;
        errdefer mem.destroy(str_w);
        if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s, -1, str_w, str_w_len) == 0) {
            return error.Failed;
        }
        str_w[len - 1] = 0;
        return str_w[0 .. len - 1 :0].ptr;
    }

    pub fn curlx_convert_UTF8_to_wchar(str_utf8: ?[*:0]const u8) callconv(.c) ?[*:0]u16 {
        const s = str_utf8 orelse return null;
        return convertUtf8ToWcharInner(s) catch null;
    }

    fn convertWcharToUtf8Inner(s: [*:0]const u16) error{Failed}![*:0]u8 {
        const bytes = WideCharToMultiByte(CP_UTF8, 0, s, -1, null, 0, null, null);
        if (bytes <= 0) return error.Failed;
        const len: usize = @intCast(bytes);
        const str_utf8 = mem.allocMany(u8, len) orelse return error.Failed;
        errdefer mem.destroy(str_utf8);
        if (WideCharToMultiByte(CP_UTF8, 0, s, -1, str_utf8, bytes, null, null) == 0) {
            return error.Failed;
        }
        str_utf8[len - 1] = 0;
        return str_utf8[0 .. len - 1 :0].ptr;
    }

    pub fn curlx_convert_wchar_to_UTF8(str_w: ?[*:0]const u16) callconv(.c) ?[*:0]u8 {
        const s = str_w orelse return null;
        return convertWcharToUtf8Inner(s) catch null;
    }

    pub fn curlx_verify_windows_init() callconv(.c) void {
        if (GetModuleHandleA("ntdll")) |hmod| {
            s_pRtlVerifyVersionInfo = GetProcAddress(hmod, "RtlVerifyVersionInfo");
            return;
        }
        s_pRtlVerifyVersionInfo = null;
    }

    pub fn curlx_verify_windows_version(
        majorVersion: c_uint,
        minorVersion: c_uint,
        buildVersion: c_uint,
        platform: c_uint,
        condition: c_uint,
    ) callconv(.c) bool {
        var matched = false;
        var cm: u64 = 0;
        var osver: OUR_OSVERSIONINFOEXW = std.mem.zeroes(OUR_OSVERSIONINFOEXW);
        var majorCondition: u8 = 0;
        var minorCondition: u8 = 0;
        var buildCondition: u8 = 0;
        var spMajorCondition: u8 = 0;
        var spMinorCondition: u8 = 0;
        var dwTypeMask: u32 = VER_MAJORVERSION | VER_MINORVERSION |
            VER_SERVICEPACKMAJOR | VER_SERVICEPACKMINOR;

        switch (condition) {
            VERSION_LESS_THAN => {
                majorCondition = VER_LESS;
                minorCondition = VER_LESS;
                buildCondition = VER_LESS;
                spMajorCondition = VER_LESS_EQUAL;
                spMinorCondition = VER_LESS_EQUAL;
            },
            VERSION_LESS_THAN_EQUAL => {
                majorCondition = VER_LESS_EQUAL;
                minorCondition = VER_LESS_EQUAL;
                buildCondition = VER_LESS_EQUAL;
                spMajorCondition = VER_LESS_EQUAL;
                spMinorCondition = VER_LESS_EQUAL;
            },
            VERSION_EQUAL => {
                majorCondition = VER_EQUAL;
                minorCondition = VER_EQUAL;
                buildCondition = VER_EQUAL;
                spMajorCondition = VER_GREATER_EQUAL;
                spMinorCondition = VER_GREATER_EQUAL;
            },
            VERSION_GREATER_THAN_EQUAL => {
                majorCondition = VER_GREATER_EQUAL;
                minorCondition = VER_GREATER_EQUAL;
                buildCondition = VER_GREATER_EQUAL;
                spMajorCondition = VER_GREATER_EQUAL;
                spMinorCondition = VER_GREATER_EQUAL;
            },
            VERSION_GREATER_THAN => {
                majorCondition = VER_GREATER;
                minorCondition = VER_GREATER;
                buildCondition = VER_GREATER;
                spMajorCondition = VER_GREATER_EQUAL;
                spMinorCondition = VER_GREATER_EQUAL;
            },
            else => return false,
        }

        osver.dwOSVersionInfoSize = @sizeOf(OUR_OSVERSIONINFOEXW);
        osver.dwMajorVersion = majorVersion;
        osver.dwMinorVersion = minorVersion;
        osver.dwBuildNumber = buildVersion;
        if (platform == PLATFORM_WINDOWS) {
            osver.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS;
        } else if (platform == PLATFORM_WINNT) {
            osver.dwPlatformId = VER_PLATFORM_WIN32_NT;
        }

        cm = VerSetConditionMask(cm, VER_MAJORVERSION, majorCondition);
        cm = VerSetConditionMask(cm, VER_MINORVERSION, minorCondition);
        cm = VerSetConditionMask(cm, VER_SERVICEPACKMAJOR, spMajorCondition);
        cm = VerSetConditionMask(cm, VER_SERVICEPACKMINOR, spMinorCondition);

        if (platform != PLATFORM_DONT_CARE) {
            cm = VerSetConditionMask(cm, VER_PLATFORMID, VER_EQUAL);
            dwTypeMask |= VER_PLATFORMID;
        }

        if (s_pRtlVerifyVersionInfo) |rtlFn| {
            matched = (rtlFn(&osver, dwTypeMask, cm) == 0);
        } else {
            matched = (VerifyVersionInfoW(&osver, dwTypeMask, cm) != 0);
        }

        if (matched and buildVersion != 0 and
            (condition == VERSION_EQUAL or
                ((condition == VERSION_GREATER_THAN_EQUAL or
                    condition == VERSION_LESS_THAN_EQUAL) and
                    curlx_verify_windows_version(majorVersion, minorVersion, 0, platform, VERSION_EQUAL))))
        {
            cm = VerSetConditionMask(0, VER_BUILDNUMBER, buildCondition);
            dwTypeMask = VER_BUILDNUMBER;
            if (s_pRtlVerifyVersionInfo) |rtlFn| {
                matched = (rtlFn(&osver, dwTypeMask, cm) == 0);
            } else {
                matched = (VerifyVersionInfoW(&osver, dwTypeMask, cm) != 0);
            }
        }

        return matched;
    }

    pub fn curlx_CreateFile(
        filename: ?[*:0]const u8,
        dwDesiredAccess: u32,
        dwShareMode: u32,
        lpSecurityAttributes: ?*anyopaque,
        dwCreationDisposition: u32,
        dwFlagsAndAttributes: u32,
        hTemplateFile: ?*anyopaque,
    ) callconv(.c) ?*anyopaque {
        const fname = filename orelse return invalidHandleValue();
        var fixed: ?[*:0]u8 = null;
        const target: [*:0]const u8 = if (fix_excessive_path(fname, &fixed)) fixed.? else fname;
        defer mem.destroy(fixed);

        return CreateFileA(
            target,
            dwDesiredAccess,
            dwShareMode,
            lpSecurityAttributes,
            dwCreationDisposition,
            dwFlagsAndAttributes,
            hTemplateFile,
        );
    }

    pub fn curlx_FindFirstFile(
        filename: ?[*:0]const u8,
        find_data: ?*anyopaque,
    ) callconv(.c) ?*anyopaque {
        const fname = filename orelse return invalidHandleValue();
        var fixed: ?[*:0]u8 = null;
        const target: [*:0]const u8 = if (fix_excessive_path(fname, &fixed)) fixed.? else fname;
        defer mem.destroy(fixed);

        return FindFirstFileA(target, find_data);
    }

    pub fn curlx_win32_open(filename: ?[*:0]const u8, oflag: c_int, pmode_arg: c_int) callconv(.c) c_int {
        const pmode: c_int = if ((oflag & O_CREAT) != 0) pmode_arg else 0;
        var res: c_int = -1;

        const fname = filename orelse {
            _errno().* = EINVAL;
            return -1;
        };

        var fixed: ?[*:0]u8 = null;
        const target: [*:0]const u8 = if (fix_excessive_path(fname, &fixed)) fixed.? else fname;
        defer mem.destroy(fixed);

        _errno().* = _sopen_s(&res, target, oflag, SH_DENYNO, pmode);
        return res;
    }

    pub fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*anyopaque {
        const fname = filename orelse {
            _errno().* = EINVAL;
            return null;
        };
        const m = mode orelse {
            _errno().* = EINVAL;
            return null;
        };

        var fixed: ?[*:0]u8 = null;
        const target: [*:0]const u8 = if (fix_excessive_path(fname, &fixed)) fixed.? else fname;
        defer mem.destroy(fixed);

        return _fsopen(target, m, SH_DENYNO);
    }

    pub fn curlx_win32_freopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8, fp: ?*anyopaque) callconv(.c) ?*anyopaque {
        var file: ?*anyopaque = null;
        const fname = filename orelse {
            _errno().* = EINVAL;
            return null;
        };
        const m = mode orelse {
            _errno().* = EINVAL;
            return null;
        };

        var fixed: ?[*:0]u8 = null;
        const target: [*:0]const u8 = if (fix_excessive_path(fname, &fixed)) fixed.? else fname;
        defer mem.destroy(fixed);

        _errno().* = freopen_s(&file, target, m, fp);
        return file;
    }

    pub fn curlx_win32_stat(path: ?[*:0]const u8, buffer: ?*anyopaque) callconv(.c) c_int {
        const p = path orelse {
            _errno().* = EINVAL;
            return -1;
        };

        var fixed: ?[*:0]u8 = null;
        const target: [*:0]const u8 = if (fix_excessive_path(p, &fixed)) fixed.? else p;
        defer mem.destroy(fixed);

        return _stati64(target, buffer);
    }

    pub fn curlx_win32_mkdir(path: ?[*:0]const u8) callconv(.c) c_int {
        const p = path orelse {
            _errno().* = EINVAL;
            return -1;
        };

        var fixed: ?[*:0]u8 = null;
        const target: [*:0]const u8 = if (fix_excessive_path(p, &fixed)) fixed.? else p;
        defer mem.destroy(fixed);

        return _mkdir(target);
    }

    pub fn curlx_win32_rename(oldpath: ?[*:0]const u8, newpath: ?[*:0]const u8) callconv(.c) c_int {
        const old_p = oldpath orelse return -1;
        const new_p = newpath orelse return -1;

        var oldpath_fixed: ?[*:0]u8 = null;
        var newpath_fixed: ?[*:0]u8 = null;
        const target_oldpath: [*:0]const u8 = if (fix_excessive_path(old_p, &oldpath_fixed)) oldpath_fixed.? else old_p;
        const target_newpath: [*:0]const u8 = if (fix_excessive_path(new_p, &newpath_fixed)) newpath_fixed.? else new_p;
        defer {
            mem.destroy(oldpath_fixed);
            mem.destroy(newpath_fixed);
        }

        const max_wait_ms: i64 = 1000;
        var start: CurlTime = .{ .tv_sec = 0, .tv_usec = 0 };
        curlx_pnow(&start);

        while (true) {
            if (MoveFileExA(target_oldpath, target_newpath, MOVEFILE_REPLACE_EXISTING) != 0) {
                return 0;
            }
            var now: CurlTime = .{ .tv_sec = 0, .tv_usec = 0 };
            curlx_pnow(&now);
            const diff = curlx_ptimediff_ms(&now, &start);
            if (diff < 0 or diff > max_wait_ms) {
                break;
            }
            Sleep(1);
        }
        return -1;
    }

    pub fn curlx_get_winapi_error(err: u32, buf: ?[*]u8, buflen: usize) callconv(.c) ?[*:0]const u8 {
        const b = buf orelse return null;
        if (buflen == 0) return null;

        if (FormatMessageA(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            null,
            err,
            LANG_NEUTRAL,
            b,
            @truncate(buflen),
            null,
        ) == 0) {
            b[0] = 0;
            return null;
        }

        var i: usize = 0;
        while (i < buflen and b[i] != 0) : (i += 1) {
            if (b[i] == '\n') {
                if (i > 0 and b[i - 1] == '\r') {
                    i -= 1;
                }
                b[i] = 0;
                break;
            }
        }

        b[@min(i, buflen - 1)] = 0;
        return if (b[0] != 0) b[0..@min(i, buflen - 1) :0].ptr else null;
    }

    pub fn curlx_winapi_strerror(err: u32, buf: ?[*]u8, buflen: usize) callconv(.c) ?[*:0]const u8 {
        const old_win_err = GetLastError();
        const old_errno = _errno().*;

        const b = buf orelse return null;
        if (buflen == 0) return null;

        b[0] = 0;

        if (curlx_get_winapi_error(err, b, buflen) == null) {
            var tmp: [64]u8 = undefined;
            const formatted = std.fmt.bufPrint(&tmp, "Unknown error {d} (0x{x:0>8})", .{ err, err }) catch "Unknown error";
            const copy_len = @min(formatted.len, buflen - 1);
            @memcpy(b[0..copy_len], formatted[0..copy_len]);
            b[copy_len] = 0;
        }

        if (_errno().* != old_errno)
            _errno().* = old_errno;

        if (old_win_err != GetLastError())
            SetLastError(old_win_err);

        const len = std.mem.indexOfScalar(u8, b[0..buflen], 0) orelse 0;
        b[len] = 0;
        return b[0..len :0].ptr;
    }

    pub fn curlx_win32_random(entropy: ?[*]u8, length: usize) callconv(.c) c_uint {
        if (entropy) |e| {
            if (length > 0) {
                @memset(e[0..length], 0);
            }
        }
        if (BCryptGenRandom(null, entropy, @truncate(length), BCRYPT_USE_SYSTEM_PREFERRED_RNG) != STATUS_SUCCESS) {
            return CURLE_FAILED_INIT;
        }
        return CURLE_OK;
    }
};

comptime {
    if (builtin.os.tag == .windows) {
        @export(&win32.curlx_convert_UTF8_to_wchar, .{ .name = "curlx_convert_UTF8_to_wchar" });
        @export(&win32.curlx_convert_wchar_to_UTF8, .{ .name = "curlx_convert_wchar_to_UTF8" });
        @export(&win32.curlx_verify_windows_init, .{ .name = "curlx_verify_windows_init" });
        @export(&win32.curlx_verify_windows_version, .{ .name = "curlx_verify_windows_version" });
        @export(&win32.curlx_CreateFile, .{ .name = "curlx_CreateFile" });
        @export(&win32.curlx_FindFirstFile, .{ .name = "curlx_FindFirstFile" });
        @export(&win32.curlx_win32_open, .{ .name = "curlx_win32_open" });
        @export(&win32.curlx_win32_fopen, .{ .name = "curlx_win32_fopen" });
        @export(&win32.curlx_win32_freopen, .{ .name = "curlx_win32_freopen" });
        @export(&win32.curlx_win32_stat, .{ .name = "curlx_win32_stat" });
        @export(&win32.curlx_win32_mkdir, .{ .name = "curlx_win32_mkdir" });
        @export(&win32.curlx_win32_rename, .{ .name = "curlx_win32_rename" });
        @export(&win32.curlx_get_winapi_error, .{ .name = "curlx_get_winapi_error" });
        @export(&win32.curlx_winapi_strerror, .{ .name = "curlx_winapi_strerror" });
        @export(&win32.curlx_win32_random, .{ .name = "curlx_win32_random" });
    }
}

pub export fn curlx_fseek(stream: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) c_int {
    if (builtin.os.tag == .windows) {
        return win32._fseeki64(stream, offset, whence);
    } else {
        return posix_c.fseeko(stream, offset, whence);
    }
}

fn getenvWin32(v: [*:0]const u8) error{Failed}![*:0]u8 {
    var buf: ?[*]u8 = null;
    errdefer mem.destroy(buf);
    var rc: u32 = 1;
    const max: u32 = 32768;

    while (true) {
        buf = mem.reallocMany(u8, buf, rc) orelse return error.Failed;
        const bufsize = rc;

        rc = win32.GetEnvironmentVariableA(v, buf, bufsize);
        if (rc == 0 or rc == bufsize or rc > max) {
            return error.Failed;
        }
        if (rc < bufsize) {
            buf.?[rc] = 0;
            return buf.?[0..rc :0].ptr;
        }
    }
}

pub export fn curl_getenv(variable: ?[*:0]const u8) callconv(.c) ?[*:0]u8 {
    const v = variable orelse return null;
    if (builtin.os.tag == .windows) {
        return getenvWin32(v) catch null;
    } else {
        const env = posix_c.getenv(v) orelse return null;
        if (env[0] == 0) return null;
        return mem.strdup(env);
    }
}

pub export fn Curl_fileinfo_alloc() callconv(.c) ?*Fileinfo {
    return mem.create(Fileinfo);
}

pub export fn Curl_fileinfo_cleanup(finfo: ?*Fileinfo) callconv(.c) void {
    const f = finfo orelse return;
    curlx_dyn_free(&f.buf);
    mem.destroy(f);
}

pub export fn Curl_get_line(buf: *Dynbuf, input: ?*anyopaque, eof: *bool) callconv(.c) c_uint {
    var buffer: [128]u8 = undefined;
    curlx_dyn_reset(buf);
    while (true) {
        const b_opt = fgets(&buffer, @sizeOf(@TypeOf(buffer)), input);
        if (b_opt == null and ferror(input) != 0) {
            return CURLE_READ_ERROR;
        }

        eof.* = (feof(input) != 0);

        const rlen: usize = if (b_opt) |b| std.mem.len(b) else 0;
        if (rlen > 0) {
            const result = curlx_dyn_addn(buf, b_opt.?, rlen);
            if (result != CURLE_OK) {
                return result;
            }
        }

        const full_len = curlx_dyn_len(buf);
        const full_ptr = curlx_dyn_ptr(buf);
        if (full_len > 0 and full_ptr != null and full_ptr.?[full_len - 1] == '\n') {
            return CURLE_OK;
        }
        if (eof.*) {
            return curlx_dyn_addn(buf, "\n", 1);
        }
    }
}

pub const GethostnameArg2 = if (builtin.os.tag == .windows) c_int else usize;

pub export fn Curl_gethostname(name: ?[*]u8, namelen: GethostnameArg2) callconv(.c) c_int {
    const buf = name orelse return -1;
    if (namelen <= 0) return -1;
    const len_usize: usize = @intCast(namelen);

    buf[0] = 0;
    const err = if (builtin.os.tag == .windows)
        win32.gethostname(buf, namelen)
    else
        posix_c.gethostname(buf, namelen);

    buf[len_usize - 1] = 0;
    if (err != 0) return err;

    var i: usize = 0;
    while (i < len_usize and buf[i] != 0) : (i += 1) {
        if (buf[i] == '.') {
            buf[i] = 0;
            break;
        }
    }

    return 0;
}

extern fn fopen(pathname: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn fclose(stream: ?*anyopaque) callconv(.c) c_int;
extern fn ftell(stream: ?*anyopaque) callconv(.c) c_long;
extern fn fmemopen(buf: *const anyopaque, size: usize, mode: [*:0]const u8) callconv(.c) ?*anyopaque;

test "curl_getenv existing and missing variables" {
    try std.testing.expect(curl_getenv(null) == null);

    const path_val = curl_getenv("PATH");
    if (path_val) |p| {
        defer mem.free(p);
        try std.testing.expect(std.mem.len(p) > 0);
    }

    const missing = curl_getenv("CURL_ZIG_NONEXISTENT_VAR_99887766");
    try std.testing.expect(missing == null);
}

test "Curl_gethostname returns unqualified hostname" {
    try std.testing.expectEqual(@as(c_int, -1), Curl_gethostname(null, 64));

    var hostbuf: [1024]u8 = undefined;
    @memset(&hostbuf, 0xAA);
    const rc = Curl_gethostname(&hostbuf, @intCast(hostbuf.len));
    try std.testing.expectEqual(@as(c_int, 0), rc);

    const host_slice = std.mem.sliceTo(&hostbuf, 0);
    try std.testing.expect(std.mem.indexOfScalar(u8, host_slice, '.') == null);
}

test "Curl_fileinfo_alloc and Curl_fileinfo_cleanup" {
    Curl_fileinfo_cleanup(null);

    const finfo = Curl_fileinfo_alloc() orelse return error.OutOfMemory;
    try std.testing.expect(finfo.info.filename == null);
    try std.testing.expectEqual(@as(c_uint, 0), finfo.info.filetype);
    try std.testing.expect(finfo.buf.bufr == null);
    try std.testing.expectEqual(@as(usize, 0), finfo.buf.leng);

    curlx_dyn_init(&finfo.buf, 1024);
    try std.testing.expectEqual(CURLE_OK, curlx_dyn_addn(&finfo.buf, "test-entry", 10));
    try std.testing.expectEqual(@as(usize, 10), curlx_dyn_len(&finfo.buf));

    Curl_fileinfo_cleanup(finfo);
}

test "Curl_get_line and curlx_fseek on build.zig.zon" {
    const fp = fopen("build.zig.zon", "rb") orelse return error.FileOpenFailed;
    defer _ = fclose(fp);

    var dyn: Dynbuf = undefined;
    curlx_dyn_init(&dyn, 4096);
    defer curlx_dyn_free(&dyn);

    var eof = false;
    const rc = Curl_get_line(&dyn, fp, &eof);
    try std.testing.expectEqual(CURLE_OK, rc);
    const line_len = curlx_dyn_len(&dyn);
    try std.testing.expect(line_len > 0);
    const line_ptr = curlx_dyn_ptr(&dyn).?;
    try std.testing.expectEqual(@as(u8, '\n'), line_ptr[line_len - 1]);
    try std.testing.expectEqualStrings(".{\n", line_ptr[0..line_len]);

    try std.testing.expectEqual(@as(c_int, 0), curlx_fseek(fp, 0, 2)); // SEEK_END
    try std.testing.expect(ftell(fp) > 0);
    try std.testing.expectEqual(@as(c_int, 0), curlx_fseek(fp, 0, 0)); // SEEK_SET
    try std.testing.expectEqual(@as(c_long, 0), ftell(fp));
}

test "Curl_get_line long line and EOF without trailing newline" {
    if (builtin.os.tag == .windows) return;

    const a200: [200]u8 = @splat('a');
    const long_line = a200 ++ "\n" ++ "tail-without-newline";
    const fp = fmemopen(long_line.ptr, long_line.len, "r") orelse return error.FmemopenFailed;
    defer _ = fclose(fp);

    var dyn: Dynbuf = undefined;
    curlx_dyn_init(&dyn, 4096);
    defer curlx_dyn_free(&dyn);

    var eof = false;
    try std.testing.expectEqual(CURLE_OK, Curl_get_line(&dyn, fp, &eof));
    try std.testing.expect(!eof);
    try std.testing.expectEqual(@as(usize, 201), curlx_dyn_len(&dyn));
    try std.testing.expectEqualStrings(&(a200 ++ "\n".*), curlx_dyn_ptr(&dyn).?[0..201]);

    try std.testing.expectEqual(CURLE_OK, Curl_get_line(&dyn, fp, &eof));
    try std.testing.expect(eof);
    const tail_len = curlx_dyn_len(&dyn);
    try std.testing.expectEqualStrings("tail-without-newline\n", curlx_dyn_ptr(&dyn).?[0..tail_len]);
}
