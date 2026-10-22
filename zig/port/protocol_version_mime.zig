const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const os_leaf = @import("os_leaf.zig");
const io_buffers = @import("io_buffers.zig");
const small_protocols = @import("small_protocols.zig");
const imap_ws = @import("imap_ws.zig");
const pop3_smtp = @import("pop3_smtp.zig");
const ftp = @import("ftp.zig");
const http_mod = @import("http.zig");
const ldap = @import("ldap.zig");
const vquic_core = @import("vquic_core.zig");
const vssh = @import("vssh.zig");
const containers = @import("containers.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_FAIL_REWIND: CURLcode = 65;
pub const CURLE_AGAIN: CURLcode = 81;

pub const curl_off_t = i64;
pub const curl_prot_t = curl_off_t;
pub const bufq = io_buffers.bufq;

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

extern fn curl_strnequal(s1: [*:0]const u8, s2: [*:0]const u8, n: usize) callconv(.c) c_int;
extern fn curl_strequal(s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) c_int;
extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;
extern fn Curl_slist_duplicate(inlist: ?*curl_slist) callconv(.c) ?*curl_slist;
extern fn Curl_slist_append_nodup(list: ?*curl_slist, data: [*:0]u8) callconv(.c) ?*curl_slist;
extern fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;

const is_windows = builtin.os.tag == .windows;
const use_ssl = backend_options.ssl != .none;
const use_ares = if (@hasDecl(backend_options, "ares")) backend_options.ares else false;
const use_httpsrr = if (@hasDecl(backend_options, "httpsrr")) backend_options.httpsrr else false;
const use_resolv_ares = if (@hasDecl(backend_options, "use_resolv_ares")) backend_options.use_resolv_ares else false;
const use_resolv_threaded = if (@hasDecl(backend_options, "use_resolv_threaded")) backend_options.use_resolv_threaded else true;
const use_apple_sectrust = backend_options.apple_sectrust orelse (backend_options.ssl == .openssl and builtin.os.tag.isDarwin());
const use_ssh = if (@hasDecl(backend_options, "ssh")) backend_options.ssh != .none else false;
const has_ldap = if (@hasDecl(backend_options, "has_ldap")) backend_options.has_ldap else false;
const has_ldaps = if (@hasDecl(backend_options, "has_ldaps")) backend_options.has_ldaps else false;

// ============================================================================
// 1. lib/protocol.c + lib/protocol.h
// ============================================================================

pub const CURLPROTO_HTTP: curl_prot_t = 1 << 0;
pub const CURLPROTO_HTTPS: curl_prot_t = 1 << 1;
pub const CURLPROTO_FTP: curl_prot_t = 1 << 2;
pub const CURLPROTO_FTPS: curl_prot_t = 1 << 3;
pub const CURLPROTO_SCP: curl_prot_t = 1 << 4;
pub const CURLPROTO_SFTP: curl_prot_t = 1 << 5;
pub const CURLPROTO_TELNET: curl_prot_t = 1 << 6;
pub const CURLPROTO_LDAP: curl_prot_t = 1 << 7;
pub const CURLPROTO_LDAPS: curl_prot_t = 1 << 8;
pub const CURLPROTO_DICT: curl_prot_t = 1 << 9;
pub const CURLPROTO_FILE: curl_prot_t = 1 << 10;
pub const CURLPROTO_TFTP: curl_prot_t = 1 << 11;
pub const CURLPROTO_IMAP: curl_prot_t = 1 << 12;
pub const CURLPROTO_IMAPS: curl_prot_t = 1 << 13;
pub const CURLPROTO_POP3: curl_prot_t = 1 << 14;
pub const CURLPROTO_POP3S: curl_prot_t = 1 << 15;
pub const CURLPROTO_SMTP: curl_prot_t = 1 << 16;
pub const CURLPROTO_SMTPS: curl_prot_t = 1 << 17;
pub const CURLPROTO_RTSP: curl_prot_t = 1 << 18;
pub const CURLPROTO_GOPHER: curl_prot_t = 1 << 25;
pub const CURLPROTO_MQTT: curl_prot_t = 1 << 28;
pub const CURLPROTO_GOPHERS: curl_prot_t = 1 << 29;
pub const CURLPROTO_WS: curl_prot_t = 1 << 30;
pub const CURLPROTO_WSS: curl_prot_t = 1 << 31;
pub const CURLPROTO_MQTTS: curl_prot_t = 1 << 32;
pub const CURLPROTO_SOCKS: curl_prot_t = 1 << 33;

pub const PORT_FTP: u16 = 21;
pub const PORT_FTPS: u16 = 990;
pub const PORT_TELNET: u16 = 23;
pub const PORT_HTTP: u16 = 80;
pub const PORT_HTTPS: u16 = 443;
pub const PORT_DICT: u16 = 2628;
pub const PORT_LDAP: u16 = 389;
pub const PORT_LDAPS: u16 = 636;
pub const PORT_TFTP: u16 = 69;
pub const PORT_SSH: u16 = 22;
pub const PORT_IMAP: u16 = 143;
pub const PORT_IMAPS: u16 = 993;
pub const PORT_POP3: u16 = 110;
pub const PORT_POP3S: u16 = 995;
pub const PORT_SMTP: u16 = 25;
pub const PORT_SMTPS: u16 = 465;
pub const PORT_RTSP: u16 = 554;
pub const PORT_GOPHER: u16 = 70;
pub const PORT_SOCKS: u16 = 1080;
pub const PORT_MQTT: u16 = 1883;
pub const PORT_MQTTS: u16 = 8883;

pub const PROTOPT_NONE: u32 = 0;
pub const PROTOPT_SSL: u32 = 1 << 0;
pub const PROTOPT_DUAL: u32 = 1 << 1;
pub const PROTOPT_CLOSEACTION: u32 = 1 << 2;
pub const PROTOPT_DIRLOCK: u32 = 1 << 3;
pub const PROTOPT_NONETWORK: u32 = 1 << 4;
pub const PROTOPT_NEEDSPWD: u32 = 1 << 5;
pub const PROTOPT_NOURLQUERY: u32 = 1 << 6;
pub const PROTOPT_CREDSPERREQUEST: u32 = 1 << 7;
pub const PROTOPT_ALPN: u32 = 1 << 8;
pub const PROTOPT_URLOPTIONS: u32 = 1 << 10;
pub const PROTOPT_PROXY_AS_HTTP: u32 = 1 << 11;
pub const PROTOPT_WILDCARD: u32 = 1 << 12;
pub const PROTOPT_USERPWDCTRL: u32 = 1 << 13;
pub const PROTOPT_NOTCPPROXY: u32 = 1 << 14;
pub const PROTOPT_SSL_REUSE: u32 = 1 << 15;
pub const PROTOPT_CONN_REUSE: u32 = 1 << 16;
pub const PROTOPT_NO_TRANSFER: u32 = 1 << 17;
pub const PROTOPT_HTTP_PROXY_TUNNEL: u32 = 1 << 18;

pub const Curl_scheme = extern struct {
    name: [*:0]const u8,
    run: ?*const anyopaque,
    protocol: curl_prot_t,
    family: curl_prot_t,
    flags: u32,
    defport: u16,
};

const Curl_protocol_opaque = extern struct {
    _opaque: usize,
};

const Curl_protocol_dict = small_protocols.Curl_protocol_dict;
const Curl_protocol_file = small_protocols.Curl_protocol_file;
const Curl_protocol_ftp = ftp.Curl_protocol_ftp;
const Curl_protocol_gopher = small_protocols.Curl_protocol_gopher;
const Curl_protocol_gophers = small_protocols.Curl_protocol_gophers;
const Curl_protocol_http = http_mod.Curl_protocol_http;
const Curl_protocol_mqtt = small_protocols.Curl_protocol_mqtt;
const Curl_protocol_mqtts = small_protocols.Curl_protocol_mqtts;
extern const Curl_protocol_rtsp: Curl_protocol_opaque;
extern const Curl_protocol_telnet: Curl_protocol_opaque;
extern const Curl_protocol_tftp: Curl_protocol_opaque;

pub export const Curl_scheme_dict: Curl_scheme = .{
    .name = "dict",
    .run = @ptrCast(&Curl_protocol_dict),
    .protocol = CURLPROTO_DICT,
    .family = CURLPROTO_DICT,
    .flags = PROTOPT_NONE | PROTOPT_NOURLQUERY,
    .defport = PORT_DICT,
};

pub export const Curl_scheme_file: Curl_scheme = .{
    .name = "file",
    .run = @ptrCast(&Curl_protocol_file),
    .protocol = CURLPROTO_FILE,
    .family = CURLPROTO_FILE,
    .flags = PROTOPT_NONETWORK | PROTOPT_NOURLQUERY,
    .defport = 0,
};

pub export const Curl_scheme_ftp: Curl_scheme = .{
    .name = "ftp",
    .run = @ptrCast(&Curl_protocol_ftp),
    .protocol = CURLPROTO_FTP,
    .family = CURLPROTO_FTP,
    .flags = PROTOPT_DUAL | PROTOPT_CLOSEACTION | PROTOPT_NEEDSPWD |
        PROTOPT_NOURLQUERY | PROTOPT_PROXY_AS_HTTP |
        PROTOPT_WILDCARD | PROTOPT_SSL_REUSE |
        PROTOPT_CONN_REUSE,
    .defport = PORT_FTP,
};

pub export const Curl_scheme_ftps: Curl_scheme = .{
    .name = "ftps",
    .run = if (use_ssl) @ptrCast(&Curl_protocol_ftp) else null,
    .protocol = CURLPROTO_FTPS,
    .family = CURLPROTO_FTP,
    .flags = PROTOPT_SSL | PROTOPT_DUAL | PROTOPT_CLOSEACTION |
        PROTOPT_NEEDSPWD | PROTOPT_NOURLQUERY | PROTOPT_WILDCARD |
        PROTOPT_CONN_REUSE,
    .defport = PORT_FTPS,
};

pub export const Curl_scheme_gopher: Curl_scheme = .{
    .name = "gopher",
    .run = @ptrCast(&Curl_protocol_gopher),
    .protocol = CURLPROTO_GOPHER,
    .family = CURLPROTO_GOPHER,
    .flags = PROTOPT_NONE,
    .defport = PORT_GOPHER,
};

pub export const Curl_scheme_gophers: Curl_scheme = .{
    .name = "gophers",
    .run = if (use_ssl) @ptrCast(&Curl_protocol_gophers) else null,
    .protocol = CURLPROTO_GOPHERS,
    .family = CURLPROTO_GOPHER,
    .flags = PROTOPT_SSL,
    .defport = PORT_GOPHER,
};

pub export const Curl_scheme_http: Curl_scheme = .{
    .name = "http",
    .run = @ptrCast(&Curl_protocol_http),
    .protocol = CURLPROTO_HTTP,
    .family = CURLPROTO_HTTP,
    .flags = PROTOPT_CREDSPERREQUEST |
        PROTOPT_USERPWDCTRL | PROTOPT_CONN_REUSE,
    .defport = PORT_HTTP,
};

pub export const Curl_scheme_https: Curl_scheme = .{
    .name = "https",
    .run = if (use_ssl) @ptrCast(&Curl_protocol_http) else null,
    .protocol = CURLPROTO_HTTPS,
    .family = CURLPROTO_HTTP,
    .flags = PROTOPT_SSL | PROTOPT_CREDSPERREQUEST | PROTOPT_ALPN |
        PROTOPT_USERPWDCTRL | PROTOPT_CONN_REUSE |
        PROTOPT_HTTP_PROXY_TUNNEL,
    .defport = PORT_HTTPS,
};

pub export const Curl_scheme_imap: Curl_scheme = .{
    .name = "imap",
    .run = @ptrCast(&imap_ws.Curl_protocol_imap),
    .protocol = CURLPROTO_IMAP,
    .family = CURLPROTO_IMAP,
    .flags = PROTOPT_CLOSEACTION |
        PROTOPT_URLOPTIONS | PROTOPT_SSL_REUSE |
        PROTOPT_CONN_REUSE,
    .defport = PORT_IMAP,
};

pub export const Curl_scheme_imaps: Curl_scheme = .{
    .name = "imaps",
    .run = if (use_ssl) @ptrCast(&imap_ws.Curl_protocol_imap) else null,
    .protocol = CURLPROTO_IMAPS,
    .family = CURLPROTO_IMAP,
    .flags = PROTOPT_CLOSEACTION | PROTOPT_SSL |
        PROTOPT_URLOPTIONS | PROTOPT_CONN_REUSE,
    .defport = PORT_IMAPS,
};

pub export const Curl_scheme_ldap: Curl_scheme = .{
    .name = "ldap",
    .run = if (has_ldap) @ptrCast(&ldap.Curl_protocol_ldap) else null,
    .protocol = CURLPROTO_LDAP,
    .family = CURLPROTO_LDAP,
    .flags = PROTOPT_SSL_REUSE,
    .defport = PORT_LDAP,
};

pub export const Curl_scheme_ldaps: Curl_scheme = .{
    .name = "ldaps",
    .run = if (has_ldaps) @ptrCast(&ldap.Curl_protocol_ldap) else null,
    .protocol = CURLPROTO_LDAPS,
    .family = CURLPROTO_LDAP,
    .flags = PROTOPT_SSL,
    .defport = PORT_LDAPS,
};

pub export const Curl_scheme_mqtt: Curl_scheme = .{
    .name = "mqtt",
    .run = @ptrCast(&Curl_protocol_mqtt),
    .protocol = CURLPROTO_MQTT,
    .family = CURLPROTO_MQTT,
    .flags = PROTOPT_NONE,
    .defport = PORT_MQTT,
};

pub export const Curl_scheme_mqtts: Curl_scheme = .{
    .name = "mqtts",
    .run = if (use_ssl) @ptrCast(&Curl_protocol_mqtts) else null,
    .protocol = CURLPROTO_MQTTS,
    .family = CURLPROTO_MQTT,
    .flags = PROTOPT_SSL,
    .defport = PORT_MQTTS,
};

pub export const Curl_scheme_pop3: Curl_scheme = .{
    .name = "pop3",
    .run = @ptrCast(&pop3_smtp.Curl_protocol_pop3),
    .protocol = CURLPROTO_POP3,
    .family = CURLPROTO_POP3,
    .flags = PROTOPT_CLOSEACTION | PROTOPT_NOURLQUERY |
        PROTOPT_URLOPTIONS | PROTOPT_SSL_REUSE | PROTOPT_CONN_REUSE,
    .defport = PORT_POP3,
};

pub export const Curl_scheme_pop3s: Curl_scheme = .{
    .name = "pop3s",
    .run = if (use_ssl) @ptrCast(&pop3_smtp.Curl_protocol_pop3) else null,
    .protocol = CURLPROTO_POP3S,
    .family = CURLPROTO_POP3,
    .flags = PROTOPT_CLOSEACTION | PROTOPT_SSL |
        PROTOPT_NOURLQUERY | PROTOPT_URLOPTIONS | PROTOPT_CONN_REUSE,
    .defport = PORT_POP3S,
};

pub export const Curl_scheme_rtsp: Curl_scheme = .{
    .name = "rtsp",
    .run = @ptrCast(&Curl_protocol_rtsp),
    .protocol = CURLPROTO_RTSP,
    .family = CURLPROTO_RTSP,
    .flags = PROTOPT_CONN_REUSE,
    .defport = PORT_RTSP,
};

pub export const Curl_scheme_sftp: Curl_scheme = .{
    .name = "sftp",
    .run = if (use_ssh) @ptrCast(&vssh.Curl_protocol_sftp) else null,
    .protocol = CURLPROTO_SFTP,
    .family = CURLPROTO_SFTP,
    .flags = PROTOPT_DIRLOCK | PROTOPT_CLOSEACTION |
        PROTOPT_NOURLQUERY | PROTOPT_CONN_REUSE,
    .defport = PORT_SSH,
};

pub export const Curl_scheme_scp: Curl_scheme = .{
    .name = "scp",
    .run = if (use_ssh) @ptrCast(&vssh.Curl_protocol_scp) else null,
    .protocol = CURLPROTO_SCP,
    .family = CURLPROTO_SCP,
    .flags = PROTOPT_DIRLOCK | PROTOPT_CLOSEACTION |
        PROTOPT_NOURLQUERY | PROTOPT_CONN_REUSE,
    .defport = PORT_SSH,
};

pub export const Curl_scheme_smtp: Curl_scheme = .{
    .name = "smtp",
    .run = @ptrCast(&pop3_smtp.Curl_protocol_smtp),
    .protocol = CURLPROTO_SMTP,
    .family = CURLPROTO_SMTP,
    .flags = PROTOPT_CLOSEACTION | PROTOPT_NOURLQUERY |
        PROTOPT_URLOPTIONS | PROTOPT_SSL_REUSE | PROTOPT_CONN_REUSE,
    .defport = PORT_SMTP,
};

pub export const Curl_scheme_smtps: Curl_scheme = .{
    .name = "smtps",
    .run = if (use_ssl) @ptrCast(&pop3_smtp.Curl_protocol_smtp) else null,
    .protocol = CURLPROTO_SMTPS,
    .family = CURLPROTO_SMTP,
    .flags = PROTOPT_CLOSEACTION | PROTOPT_SSL |
        PROTOPT_NOURLQUERY | PROTOPT_URLOPTIONS | PROTOPT_CONN_REUSE,
    .defport = PORT_SMTPS,
};

pub export const Curl_scheme_socks: Curl_scheme = .{
    .name = "socks",
    .run = null,
    .protocol = CURLPROTO_SOCKS,
    .family = CURLPROTO_SOCKS,
    .flags = PROTOPT_NO_TRANSFER,
    .defport = PORT_SOCKS,
};

pub export const Curl_scheme_socks4: Curl_scheme = .{
    .name = "socks4",
    .run = null,
    .protocol = CURLPROTO_SOCKS,
    .family = CURLPROTO_SOCKS,
    .flags = PROTOPT_NO_TRANSFER,
    .defport = PORT_SOCKS,
};

pub export const Curl_scheme_socks4a: Curl_scheme = .{
    .name = "socks4a",
    .run = null,
    .protocol = CURLPROTO_SOCKS,
    .family = CURLPROTO_SOCKS,
    .flags = PROTOPT_NO_TRANSFER,
    .defport = PORT_SOCKS,
};

pub export const Curl_scheme_socks5: Curl_scheme = .{
    .name = "socks5",
    .run = null,
    .protocol = CURLPROTO_SOCKS,
    .family = CURLPROTO_SOCKS,
    .flags = PROTOPT_NO_TRANSFER,
    .defport = PORT_SOCKS,
};

pub export const Curl_scheme_socks5h: Curl_scheme = .{
    .name = "socks5h",
    .run = null,
    .protocol = CURLPROTO_SOCKS,
    .family = CURLPROTO_SOCKS,
    .flags = PROTOPT_NO_TRANSFER,
    .defport = PORT_SOCKS,
};

pub export const Curl_scheme_telnet: Curl_scheme = .{
    .name = "telnet",
    .run = @ptrCast(&Curl_protocol_telnet),
    .protocol = CURLPROTO_TELNET,
    .family = CURLPROTO_TELNET,
    .flags = PROTOPT_NONE | PROTOPT_NOURLQUERY,
    .defport = PORT_TELNET,
};

pub export const Curl_scheme_tftp: Curl_scheme = .{
    .name = "tftp",
    .run = @ptrCast(&Curl_protocol_tftp),
    .protocol = CURLPROTO_TFTP,
    .family = CURLPROTO_TFTP,
    .flags = PROTOPT_NOTCPPROXY | PROTOPT_NOURLQUERY,
    .defport = PORT_TFTP,
};

pub export const Curl_scheme_ws: Curl_scheme = .{
    .name = "ws",
    .run = @ptrCast(&imap_ws.Curl_protocol_ws),
    .protocol = CURLPROTO_WS,
    .family = CURLPROTO_HTTP,
    .flags = PROTOPT_CREDSPERREQUEST |
        PROTOPT_USERPWDCTRL | PROTOPT_HTTP_PROXY_TUNNEL,
    .defport = PORT_HTTP,
};

pub export const Curl_scheme_wss: Curl_scheme = .{
    .name = "wss",
    .run = if (use_ssl) @ptrCast(&imap_ws.Curl_protocol_ws) else null,
    .protocol = CURLPROTO_WSS,
    .family = CURLPROTO_HTTP,
    .flags = PROTOPT_SSL | PROTOPT_CREDSPERREQUEST |
        PROTOPT_USERPWDCTRL | PROTOPT_HTTP_PROXY_TUNNEL,
    .defport = PORT_HTTPS,
};

fn two_letter_scheme(scheme: [*]const u8) ?*const Curl_scheme {
    if (primitives.rawTolower(scheme[0]) == 'w' and
        primitives.rawTolower(scheme[1]) == 's')
        return &Curl_scheme_ws;
    return null;
}

fn three_letter_scheme(scheme: [*]const u8) ?*const Curl_scheme {
    const s0 = primitives.rawTolower(scheme[0]);
    const s1 = primitives.rawTolower(scheme[1]);
    const s2 = primitives.rawTolower(scheme[2]);
    if (s0 == 'f') {
        if (s1 == 't' and s2 == 'p')
            return &Curl_scheme_ftp;
    } else if (s0 == 'w') {
        if (s1 == 's' and s2 == 's')
            return &Curl_scheme_wss;
    } else if (s0 == 's') {
        if (s1 == 'c' and s2 == 'p')
            return &Curl_scheme_scp;
    }
    return null;
}

fn four_letter_scheme(scheme: [*]const u8) ?*const Curl_scheme {
    const s0 = primitives.rawTolower(scheme[0]);
    const s1 = primitives.rawTolower(scheme[1]);
    const s2 = primitives.rawTolower(scheme[2]);
    const s3 = primitives.rawTolower(scheme[3]);
    if (s3 == 'p') {
        if (s0 == 'h') {
            if (s1 == 't' and s2 == 't')
                return &Curl_scheme_http;
        } else if (s0 == 'i') {
            if (s1 == 'm' and s2 == 'a')
                return &Curl_scheme_imap;
        } else if (s0 == 'l') {
            if (s1 == 'd' and s2 == 'a')
                return &Curl_scheme_ldap;
        } else if (s0 == 'r') {
            if (s1 == 't' and s2 == 's')
                return &Curl_scheme_rtsp;
        } else if (s0 == 't') {
            if (s1 == 'f' and s2 == 't')
                return &Curl_scheme_tftp;
        } else if (s0 == 's') {
            if (s1 == 'f' and s2 == 't')
                return &Curl_scheme_sftp;
            if (s1 == 'm' and s2 == 't')
                return &Curl_scheme_smtp;
        }
    } else if (s0 == 'f') {
        if (s1 == 't' and s2 == 'p' and s3 == 's')
            return &Curl_scheme_ftps;
        if (s1 == 'i' and s2 == 'l' and s3 == 'e')
            return &Curl_scheme_file;
    } else if (s0 == 'm') {
        if (s1 == 'q' and s2 == 't' and s3 == 't')
            return &Curl_scheme_mqtt;
    } else if (s0 == 'p') {
        if (s1 == 'o' and s2 == 'p' and s3 == '3')
            return &Curl_scheme_pop3;
    } else if (s0 == 'd') {
        if (s1 == 'i' and s2 == 'c' and s3 == 't')
            return &Curl_scheme_dict;
    }
    return null;
}

fn five_letter_scheme(scheme: [*]const u8) ?*const Curl_scheme {
    const s4 = primitives.rawTolower(scheme[4]);
    if (s4 == 's') {
        const s0 = primitives.rawTolower(scheme[0]);
        const s1 = primitives.rawTolower(scheme[1]);
        const s2 = primitives.rawTolower(scheme[2]);
        const s3 = primitives.rawTolower(scheme[3]);
        if (s3 == 'p') {
            switch (s0) {
                'h' => {
                    if (s1 == 't' and s2 == 't')
                        return &Curl_scheme_https;
                },
                'l' => {
                    if (s1 == 'd' and s2 == 'a')
                        return &Curl_scheme_ldaps;
                },
                'i' => {
                    if (s1 == 'm' and s2 == 'a')
                        return &Curl_scheme_imaps;
                },
                's' => {
                    if (s1 == 'm' and s2 == 't')
                        return &Curl_scheme_smtps;
                },
                else => {},
            }
        } else if (s0 == 'p') {
            if (s1 == 'o' and s2 == 'p' and s3 == '3')
                return &Curl_scheme_pop3s;
        } else if (s0 == 'm') {
            if (s1 == 'q' and s2 == 't' and s3 == 't')
                return &Curl_scheme_mqtts;
        } else if (s0 == 's') {
            if (s1 == 'o' and s2 == 'c' and s3 == 'k')
                return &Curl_scheme_socks;
        }
    }
    return null;
}

fn six_letter_scheme(scheme: [*]const u8) ?*const Curl_scheme {
    const s0 = primitives.rawTolower(scheme[0]);
    switch (s0) {
        's' => {
            if (curl_strnequal("ocks4", @ptrCast(scheme + 1), 5) != 0)
                return &Curl_scheme_socks4;
            if (curl_strnequal("ocks5", @ptrCast(scheme + 1), 5) != 0)
                return &Curl_scheme_socks5;
        },
        'g' => {
            if (curl_strnequal("opher", @ptrCast(scheme + 1), 5) != 0)
                return &Curl_scheme_gopher;
        },
        't' => {
            if (curl_strnequal("elnet", @ptrCast(scheme + 1), 5) != 0)
                return &Curl_scheme_telnet;
        },
        else => {},
    }
    return null;
}

fn seven_letter_scheme(scheme: [*]const u8) ?*const Curl_scheme {
    const s0 = primitives.rawTolower(scheme[0]);
    if (s0 == 's') {
        if (curl_strnequal("ocks4a", @ptrCast(scheme + 1), 6) != 0)
            return &Curl_scheme_socks4a;
        if (curl_strnequal("ocks5h", @ptrCast(scheme + 1), 6) != 0)
            return &Curl_scheme_socks5h;
    } else if (s0 == 'g') {
        if (curl_strnequal("ophers", @ptrCast(scheme + 1), 6) != 0)
            return &Curl_scheme_gophers;
    }
    return null;
}

pub export fn Curl_getn_scheme(scheme: [*]const u8, len: usize) callconv(.c) ?*const Curl_scheme {
    return switch (len) {
        2 => two_letter_scheme(scheme),
        3 => three_letter_scheme(scheme),
        4 => four_letter_scheme(scheme),
        5 => five_letter_scheme(scheme),
        6 => six_letter_scheme(scheme),
        7 => seven_letter_scheme(scheme),
        else => null,
    };
}

pub export fn Curl_get_scheme(scheme: [*:0]const u8) callconv(.c) ?*const Curl_scheme {
    return Curl_getn_scheme(scheme, std.mem.len(scheme));
}

// ============================================================================
// 2. lib/version.c
// ============================================================================

const LIBCURL_VERSION: [:0]const u8 = backend_options.version ++ "";
const LIBCURL_VERSION_NUM: c_uint = backend_options.version_num;
const CURLVERSION_NOW: c_uint = 11; // CURLVERSION_TWELFTH

const CURL_OS: [*:0]const u8 = @tagName(builtin.cpu.arch) ++ "-" ++ @tagName(builtin.os.tag) ++ "-" ++ @tagName(builtin.abi);

const CURL_VERSION_IPV6: c_int = 1 << 0;
const CURL_VERSION_SSL: c_int = 1 << 2;
const CURL_VERSION_LIBZ: c_int = 1 << 3;
const CURL_VERSION_ASYNCHDNS: c_int = 1 << 7;
const CURL_VERSION_SPNEGO: c_int = 1 << 8;
const CURL_VERSION_LARGEFILE: c_int = 1 << 9;
const CURL_VERSION_IDN: c_int = 1 << 10;
const CURL_VERSION_SSPI: c_int = 1 << 11;
const CURL_VERSION_HTTP2: c_int = 1 << 16;
const CURL_VERSION_GSSAPI: c_int = 1 << 17;
const CURL_VERSION_KERBEROS5: c_int = 1 << 18;
const CURL_VERSION_UNIX_SOCKETS: c_int = 1 << 19;
const CURL_VERSION_PSL: c_int = 1 << 20;
const CURL_VERSION_HTTPS_PROXY: c_int = 1 << 21;
const CURL_VERSION_BROTLI: c_int = 1 << 23;
const CURL_VERSION_ALTSVC: c_int = 1 << 24;
const CURL_VERSION_HTTP3: c_int = 1 << 25;
const CURL_VERSION_ZSTD: c_int = 1 << 26;

const use_http3 = if (@hasDecl(backend_options, "http3")) backend_options.http3 else false;
const use_proxy_http3 = if (@hasDecl(backend_options, "proxy_http3")) backend_options.proxy_http3 else false;
const use_gssapi = if (@hasDecl(backend_options, "gssapi")) backend_options.gssapi else false;
const use_sspi = is_windows and (if (@hasDecl(backend_options, "sspi")) (backend_options.sspi orelse (backend_options.ssl == .schannel)) else (backend_options.ssl == .schannel));
const CURL_VERSION_UNICODE: c_int = 1 << 27;
const CURL_VERSION_HSTS: c_int = 1 << 28;
const CURL_VERSION_THREADSAFE: c_int = 1 << 30;

const SSLSUPP_HTTPS_PROXY: c_uint = 1 << 4;

extern fn Curl_ssl_version(buffer: [*]u8, size: usize) callconv(.c) void;
extern fn Curl_ssl_supports(data: ?*anyopaque, ssl_option: c_uint) callconv(.c) bool;
extern fn zlibVersion() callconv(.c) ?[*:0]const u8;
extern fn ZSTD_versionNumber() callconv(.c) c_uint;
extern fn BrotliDecoderVersion() callconv(.c) u32;
extern fn psl_check_version_number(version: c_int) callconv(.c) c_int;
extern fn idn2_check_version(req_version: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;
extern fn Curl_http2_ver(p: [*]u8, len: usize) callconv(.c) void;
extern fn ares_version(version: ?*c_int) callconv(.c) ?[*:0]const u8;

const nghttp2_info = extern struct {
    age: c_int,
    version_num: c_int,
    version_str: ?[*:0]const u8,
    proto_str: ?[*:0]const u8,
};
extern fn nghttp2_version(least_version: c_int) callconv(.c) *nghttp2_info;

pub const curl_version_info_data = extern struct {
    age: c_uint,
    version: ?[*:0]const u8,
    version_num: c_uint,
    host: ?[*:0]const u8,
    features: c_int,
    ssl_version: ?[*:0]const u8,
    ssl_version_num: c_long,
    libz_version: ?[*:0]const u8,
    protocols: [*]const ?[*:0]const u8,
    ares: ?[*:0]const u8,
    ares_num: c_int,
    libidn: ?[*:0]const u8,
    iconv_ver_num: c_int,
    libssh_version: ?[*:0]const u8,
    brotli_ver_num: c_uint,
    brotli_version: ?[*:0]const u8,
    nghttp2_ver_num: c_uint,
    nghttp2_version: ?[*:0]const u8,
    quic_version: ?[*:0]const u8,
    cainfo: ?[*:0]const u8,
    capath: ?[*:0]const u8,
    zstd_ver_num: c_uint,
    zstd_version: ?[*:0]const u8,
    hyper_version: ?[*:0]const u8,
    gsasl_version: ?[*:0]const u8,
    feature_names: ?[*]const ?[*:0]const u8,
    rtmp_version: ?[*:0]const u8,
};

fn zstd_version_fmt(buf: []u8) void {
    const zstd_ver: c_ulong = @intCast(ZSTD_versionNumber());
    const major: c_uint = @intCast(zstd_ver / (100 * 100));
    const minor: c_uint = @intCast((zstd_ver - (@as(c_ulong, major) * 100 * 100)) / 100);
    const patch: c_uint = @intCast(zstd_ver - (@as(c_ulong, major) * 100 * 100) - (@as(c_ulong, minor) * 100));
    const s = std.fmt.bufPrint(buf[0 .. buf.len - 1], "{d}.{d}.{d}", .{ major, minor, patch }) catch {
        buf[0] = 0;
        return;
    };
    buf[s.len] = 0;
}

fn brotli_version_fmt(buf: []u8) void {
    const br_ver = BrotliDecoderVersion();
    const major: c_uint = br_ver >> 24;
    const minor: c_uint = (br_ver & 0x00FFFFFF) >> 12;
    const patch: c_uint = br_ver & 0x00000FFF;
    const s = std.fmt.bufPrint(buf[0 .. buf.len - 1], "{d}.{d}.{d}", .{ major, minor, patch }) catch {
        buf[0] = 0;
        return;
    };
    buf[s.len] = 0;
}

var version_out_buf: [300]u8 = undefined;
var version_ssl_buf: [80]u8 = undefined;
var version_z_buf: [30]u8 = undefined;
var version_brotli_buf: [30]u8 = undefined;
var version_zstd_buf: [30]u8 = undefined;
var version_cares_buf: [30]u8 = undefined;
var version_idn_buf: [30]u8 = undefined;
var version_psl_buf: [30]u8 = undefined;
var version_ssh_buf: [30]u8 = undefined;
var version_h2_buf: [30]u8 = undefined;
var version_h3_buf: [30]u8 = undefined;
var version_ldap_buf: [30]u8 = undefined;

pub export fn curl_version() callconv(.c) [*:0]u8 {
    var src: [16][*:0]const u8 = undefined;
    var i: usize = 0;

    src[i] = "libcurl/" ++ LIBCURL_VERSION;
    i += 1;

    if (comptime use_ssl) {
        Curl_ssl_version(&version_ssl_buf, version_ssl_buf.len);
        src[i] = @ptrCast(&version_ssl_buf);
        i += 1;
    }

    if (comptime backend_options.zlib) {
        const zv = if (zlibVersion()) |p| std.mem.span(p) else "";
        const s = std.fmt.bufPrint(version_z_buf[0 .. version_z_buf.len - 1], "zlib/{s}", .{zv}) catch "";
        version_z_buf[s.len] = 0;
        src[i] = @ptrCast(&version_z_buf);
        i += 1;
    }

    if (comptime backend_options.brotli) {
        var br_ver: [30]u8 = undefined;
        brotli_version_fmt(&br_ver);
        const bv = std.mem.sliceTo(&br_ver, 0);
        const s = std.fmt.bufPrint(version_brotli_buf[0 .. version_brotli_buf.len - 1], "brotli/{s}", .{bv}) catch "";
        version_brotli_buf[s.len] = 0;
        src[i] = @ptrCast(&version_brotli_buf);
        i += 1;
    }

    if (comptime backend_options.zstd) {
        var zstd_ver: [40]u8 = undefined;
        zstd_version_fmt(&zstd_ver);
        const zv = std.mem.sliceTo(&zstd_ver, 0);
        const s = std.fmt.bufPrint(version_zstd_buf[0 .. version_zstd_buf.len - 1], "zstd/{s}", .{zv}) catch "";
        version_zstd_buf[s.len] = 0;
        src[i] = @ptrCast(&version_zstd_buf);
        i += 1;
    }

    if (comptime use_ares) {
        const av = if (ares_version(null)) |p| std.mem.span(p) else "";
        const s = std.fmt.bufPrint(version_cares_buf[0 .. version_cares_buf.len - 1], "c-ares/{s}", .{av}) catch "";
        version_cares_buf[s.len] = 0;
        src[i] = @ptrCast(&version_cares_buf);
        i += 1;
    }

    if (comptime (backend_options.idn != .none)) {
        switch (comptime backend_options.idn) {
            .libidn2 => {
                const iv = if (idn2_check_version(null)) |p| std.mem.span(p) else "";
                const s = std.fmt.bufPrint(version_idn_buf[0 .. version_idn_buf.len - 1], "libidn2/{s}", .{iv}) catch "";
                version_idn_buf[s.len] = 0;
                src[i] = @ptrCast(&version_idn_buf);
                i += 1;
            },
            .winidn => {
                src[i] = "WinIDN";
                i += 1;
            },
            .appleidn => {
                src[i] = "AppleIDN";
                i += 1;
            },
            .none => unreachable,
        }
    }

    if (comptime backend_options.psl) {
        const num = psl_check_version_number(0);
        const s = std.fmt.bufPrint(
            version_psl_buf[0 .. version_psl_buf.len - 1],
            "libpsl/{d}.{d}.{d}",
            .{ num >> 16, (num >> 8) & 0xff, num & 0xff },
        ) catch "";
        version_psl_buf[s.len] = 0;
        src[i] = @ptrCast(&version_psl_buf);
        i += 1;
    }

    if (comptime use_ssh) {
        vssh.Curl_ssh_version(&version_ssh_buf, version_ssh_buf.len);
        src[i] = @ptrCast(&version_ssh_buf);
        i += 1;
    }

    if (comptime backend_options.nghttp2) {
        Curl_http2_ver(&version_h2_buf, version_h2_buf.len);
        src[i] = @ptrCast(&version_h2_buf);
        i += 1;
    }

    if (comptime use_http3) {
        vquic_core.Curl_quic_ver(&version_h3_buf, version_h3_buf.len);
        src[i] = @ptrCast(&version_h3_buf);
        i += 1;
    }

    if (comptime has_ldap) {
        ldap.Curl_ldap_version(&version_ldap_buf, version_ldap_buf.len);
        src[i] = @ptrCast(&version_ldap_buf);
        i += 1;
    }

    var outp: usize = 0;
    for (0..i) |j| {
        const s = std.mem.span(src[j]);
        if (s.len + outp + 2 >= version_out_buf.len)
            break;
        if (j > 0) {
            version_out_buf[outp] = ' ';
            outp += 1;
        }
        @memcpy(version_out_buf[outp .. outp + s.len], s);
        outp += s.len;
    }
    version_out_buf[outp] = 0;

    return @ptrCast(&version_out_buf);
}

const supported_protocols = blk: {
    var list: [32]?[*:0]const u8 = undefined;
    var n: usize = 0;
    list[n] = "dict";
    n += 1;
    list[n] = "file";
    n += 1;
    list[n] = "ftp";
    n += 1;
    if (use_ssl) {
        list[n] = "ftps";
        n += 1;
    }
    list[n] = "gopher";
    n += 1;
    if (use_ssl) {
        list[n] = "gophers";
        n += 1;
    }
    list[n] = "http";
    n += 1;
    if (use_ssl) {
        list[n] = "https";
        n += 1;
    }
    list[n] = "imap";
    n += 1;
    if (use_ssl) {
        list[n] = "imaps";
        n += 1;
    }
    if (has_ldap) {
        list[n] = "ldap";
        n += 1;
        if (has_ldaps) {
            list[n] = "ldaps";
            n += 1;
        }
    }
    list[n] = "mqtt";
    n += 1;
    if (use_ssl) {
        list[n] = "mqtts";
        n += 1;
    }
    list[n] = "pop3";
    n += 1;
    if (use_ssl) {
        list[n] = "pop3s";
        n += 1;
    }
    list[n] = "rtsp";
    n += 1;
    if (use_ssh) {
        list[n] = "scp";
        n += 1;
        list[n] = "sftp";
        n += 1;
    }
    list[n] = "smtp";
    n += 1;
    if (use_ssl) {
        list[n] = "smtps";
        n += 1;
    }
    list[n] = "telnet";
    n += 1;
    list[n] = "tftp";
    n += 1;
    list[n] = "ws";
    n += 1;
    if (use_ssl) {
        list[n] = "wss";
        n += 1;
    }
    list[n] = null;
    n += 1;
    var final: [n]?[*:0]const u8 = undefined;
    for (0..n) |idx| {
        final[idx] = list[idx];
    }
    break :blk final;
};

const FeatEntry = struct {
    name: [*:0]const u8,
    present: ?*const fn (*curl_version_info_data) bool = null,
    bitmask: c_int,
};

fn https_proxy_present(info: *curl_version_info_data) bool {
    _ = info;
    if (comptime use_ssl) {
        return Curl_ssl_supports(null, SSLSUPP_HTTPS_PROXY);
    }
    return false;
}

fn idn_present(info: *curl_version_info_data) bool {
    if (comptime (backend_options.idn == .winidn or backend_options.idn == .appleidn)) {
        return true;
    }
    return info.libidn != null;
}

const features_table = blk: {
    var list: [32]FeatEntry = undefined;
    var n: usize = 0;

    list[n] = .{ .name = "alt-svc", .bitmask = CURL_VERSION_ALTSVC };
    n += 1;
    if (use_ares and use_resolv_threaded and use_httpsrr) {
        list[n] = .{ .name = "asyn-rr", .bitmask = 0 };
        n += 1;
    }
    if (use_resolv_ares or use_resolv_threaded) {
        list[n] = .{ .name = "AsynchDNS", .bitmask = CURL_VERSION_ASYNCHDNS };
        n += 1;
    }
    if (backend_options.brotli) {
        list[n] = .{ .name = "brotli", .bitmask = CURL_VERSION_BROTLI };
        n += 1;
    }
    if (use_gssapi) {
        list[n] = .{ .name = "GSS-API", .bitmask = CURL_VERSION_GSSAPI };
        n += 1;
    }
    if (backend_options.ssl != .none) {
        list[n] = .{ .name = "HSTS", .bitmask = CURL_VERSION_HSTS };
        n += 1;
    }
    if (backend_options.nghttp2) {
        list[n] = .{ .name = "HTTP2", .bitmask = CURL_VERSION_HTTP2 };
        n += 1;
    }
    if (use_http3) {
        list[n] = .{ .name = "HTTP3", .bitmask = CURL_VERSION_HTTP3 };
        n += 1;
    }
    if (use_ssl) {
        list[n] = .{ .name = "HTTPS-proxy", .present = https_proxy_present, .bitmask = CURL_VERSION_HTTPS_PROXY };
        n += 1;
    }
    list[n] = .{ .name = "HTTPSIG", .bitmask = 0 };
    n += 1;
    if (use_httpsrr) {
        list[n] = .{ .name = "HTTPSRR", .bitmask = 0 };
        n += 1;
    }
    if (backend_options.idn != .none) {
        list[n] = .{ .name = "IDN", .present = idn_present, .bitmask = CURL_VERSION_IDN };
        n += 1;
    }
    list[n] = .{ .name = "IPv6", .bitmask = CURL_VERSION_IPV6 };
    n += 1;
    if (use_gssapi or use_sspi) {
        list[n] = .{ .name = "Kerberos", .bitmask = CURL_VERSION_KERBEROS5 };
        n += 1;
    }
    list[n] = .{ .name = "Largefile", .bitmask = CURL_VERSION_LARGEFILE };
    n += 1;
    if (backend_options.zlib) {
        list[n] = .{ .name = "libz", .bitmask = CURL_VERSION_LIBZ };
        n += 1;
    }
    if (use_proxy_http3) {
        list[n] = .{ .name = "proxy-HTTP3", .bitmask = 0 };
        n += 1;
    }
    if (backend_options.psl) {
        list[n] = .{ .name = "PSL", .bitmask = CURL_VERSION_PSL };
        n += 1;
    }
    if (use_ssl and use_apple_sectrust) {
        list[n] = .{ .name = "AppleSecTrust", .bitmask = 0 };
        n += 1;
    }
    if (use_gssapi or use_sspi) {
        list[n] = .{ .name = "SPNEGO", .bitmask = CURL_VERSION_SPNEGO };
        n += 1;
    }
    if (use_ssl) {
        list[n] = .{ .name = "SSL", .bitmask = CURL_VERSION_SSL };
        n += 1;
    }
    if (use_sspi) {
        list[n] = .{ .name = "SSPI", .bitmask = CURL_VERSION_SSPI };
        n += 1;
    }
    list[n] = .{ .name = "threadsafe", .bitmask = CURL_VERSION_THREADSAFE };
    n += 1;
    if (is_windows) {
        list[n] = .{ .name = "Unicode", .bitmask = CURL_VERSION_UNICODE };
        n += 1;
    }
    list[n] = .{ .name = "UnixSockets", .bitmask = CURL_VERSION_UNIX_SOCKETS };
    n += 1;
    if (backend_options.zstd) {
        list[n] = .{ .name = "zstd", .bitmask = CURL_VERSION_ZSTD };
        n += 1;
    }

    var final: [n]FeatEntry = undefined;
    for (0..n) |idx| {
        final[idx] = list[idx];
    }
    break :blk final;
};

var feature_names_buf: [features_table.len + 1]?[*:0]const u8 = @splat(null);
var info_ssl_buffer: [80]u8 = undefined;
var info_ssh_buffer: [80]u8 = undefined;
var info_brotli_buffer: [30]u8 = undefined;
var info_zstd_buffer: [30]u8 = undefined;
var info_quic_buffer: [80]u8 = undefined;

const effective_ca_bundle: ?[*:0]const u8 = blk: {
    if (backend_options.ca_bundle) |bundle| {
        break :blk (bundle ++ "\x00")[0..bundle.len :0].ptr;
    }
    if (switch (backend_options.ssl) {
        .openssl, .mbedtls, .gnutls, .rustls, .wolfssl => true,
        .none, .schannel => false,
    } and !backend_options.ca_fallback and builtin.os.tag == .linux) {
        break :blk "/etc/ssl/certs/ca-certificates.crt";
    }
    break :blk null;
};

var version_info: curl_version_info_data = .{
    .age = CURLVERSION_NOW,
    .version = LIBCURL_VERSION,
    .version_num = LIBCURL_VERSION_NUM,
    .host = CURL_OS,
    .features = 0,
    .ssl_version = null,
    .ssl_version_num = 0,
    .libz_version = null,
    .protocols = &supported_protocols,
    .ares = null,
    .ares_num = 0,
    .libidn = null,
    .iconv_ver_num = 0,
    .libssh_version = null,
    .brotli_ver_num = 0,
    .brotli_version = null,
    .nghttp2_ver_num = 0,
    .nghttp2_version = null,
    .quic_version = null,
    .cainfo = effective_ca_bundle,
    .capath = null,
    .zstd_ver_num = 0,
    .zstd_version = null,
    .hyper_version = null,
    .gsasl_version = null,
    .feature_names = &feature_names_buf,
    .rtmp_version = null,
};

pub export fn curl_version_info(stamp: c_uint) callconv(.c) *curl_version_info_data {
    _ = stamp;

    if (comptime use_ssl) {
        Curl_ssl_version(&info_ssl_buffer, info_ssl_buffer.len);
        version_info.ssl_version = @ptrCast(&info_ssl_buffer);
    }

    if (comptime backend_options.zlib) {
        version_info.libz_version = zlibVersion();
    }

    if (comptime use_ares) {
        var aresnum: c_int = 0;
        version_info.ares = ares_version(&aresnum);
        version_info.ares_num = aresnum;
    }

    if (comptime (backend_options.idn == .libidn2)) {
        version_info.libidn = idn2_check_version(null);
    }

    if (comptime use_ssh) {
        vssh.Curl_ssh_version(&info_ssh_buffer, info_ssh_buffer.len);
        version_info.libssh_version = @ptrCast(&info_ssh_buffer);
    }

    if (comptime backend_options.brotli) {
        version_info.brotli_ver_num = BrotliDecoderVersion();
        brotli_version_fmt(&info_brotli_buffer);
        version_info.brotli_version = @ptrCast(&info_brotli_buffer);
    }

    if (comptime backend_options.nghttp2) {
        const h2 = nghttp2_version(0);
        version_info.nghttp2_ver_num = @intCast(h2.version_num);
        version_info.nghttp2_version = h2.version_str;
    }

    if (comptime use_http3) {
        vquic_core.Curl_quic_ver(&info_quic_buffer, info_quic_buffer.len);
        version_info.quic_version = @ptrCast(&info_quic_buffer);
    }

    if (comptime backend_options.zstd) {
        version_info.zstd_ver_num = ZSTD_versionNumber();
        zstd_version_fmt(&info_zstd_buffer);
        version_info.zstd_version = @ptrCast(&info_zstd_buffer);
    }

    var features: c_int = 0;
    var n: usize = 0;
    for (features_table) |feat| {
        if (feat.present == null or feat.present.?(&version_info)) {
            features |= feat.bitmask;
            feature_names_buf[n] = feat.name;
            n += 1;
        }
    }
    feature_names_buf[n] = null;
    version_info.features = features;

    return &version_info;
}

// ============================================================================
// 3. lib/mime.c + lib/mime.h
// ============================================================================

pub const MIME_BOUNDARY_DASHES: usize = 24;
pub const MIME_RAND_BOUNDARY_CHARS: usize = 22;
pub const MAX_ENCODED_LINE_LENGTH: usize = 76;
pub const ENCODING_BUFFER_SIZE: usize = 256;

pub const MIME_USERHEADERS_OWNER: c_uint = 1 << 0;
pub const MIME_BODY_ONLY: c_uint = 1 << 1;
pub const MIME_FAST_CONV: c_uint = 1 << 2;

pub const MIME_FILE_TRIED: c_uint = 1 << 0;

pub const MIMESTRATEGY_MAIL: c_uint = 0;
pub const MIMESTRATEGY_FORM: c_uint = 1;
pub const MIMESTRATEGY_LAST: c_uint = 2;

pub const MIMEKIND_NONE: c_uint = 0;
pub const MIMEKIND_DATA: c_uint = 1;
pub const MIMEKIND_FILE: c_uint = 2;
pub const MIMEKIND_CALLBACK: c_uint = 3;
pub const MIMEKIND_MULTIPART: c_uint = 4;
pub const MIMEKIND_LAST: c_uint = 5;

pub const MIMESTATE_BEGIN: c_uint = 0;
pub const MIMESTATE_CURL: c_uint = 1;
pub const MIMESTATE_USER: c_uint = 2;
pub const MIMESTATE_EOH: c_uint = 3;
pub const MIMESTATE_BODY: c_uint = 4;
pub const MIMESTATE_BOUNDARY1: c_uint = 5;
pub const MIMESTATE_BOUNDARY2: c_uint = 6;
pub const MIMESTATE_CONTENT: c_uint = 7;
pub const MIMESTATE_END: c_uint = 8;
pub const MIMESTATE_LAST: c_uint = 9;

pub const MIME_BOUNDARY_LEN: usize = MIME_BOUNDARY_DASHES + MIME_RAND_BOUNDARY_CHARS;

const READ_ERROR: usize = std.math.maxInt(usize);
const STOP_FILLING: usize = std.math.maxInt(usize) - 1;
const CURL_READFUNC_ABORT: usize = 0x10000000;
const CURL_READFUNC_PAUSE: usize = 0x10000001;
const CURL_SEEKFUNC_OK: c_int = 0;
const CURL_SEEKFUNC_FAIL: c_int = 1;
const CURL_SEEKFUNC_CANTSEEK: c_int = 2;
const CURL_MAX_HTTP_HEADER: usize = 100 * 1024;
const CURL_ZERO_TERMINATED: usize = std.math.maxInt(usize);
const SEEK_SET: c_int = 0;

const MATCH_STATEDATA: c_uint = 1 << 0;

const QP_OK: u8 = 1;
const QP_SP: u8 = 2;
const QP_CR: u8 = 3;
const QP_LF: u8 = 4;

const qp_class = [256]u8{
    0, 0, 0, 0, 0, 0, 0, 0, // 00 - 07
    0, QP_SP, QP_LF, 0, 0, QP_CR, 0, 0, // 08 - 0f
    0, 0, 0, 0, 0, 0, 0, 0, // 10 - 17
    0, 0, 0, 0, 0, 0, 0, 0, // 18 - 1f
    QP_SP, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 20 - 27
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 28 - 2f
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 30 - 37
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, 0, QP_OK, QP_OK, // 38 - 3f
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 40 - 47
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 48 - 4f
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 50 - 57
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 58 - 5f
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 60 - 67
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 68 - 6f
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, // 70 - 77
    QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, QP_OK, 0, // 78 - 7f
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 80 - 8f
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 90 - 9f
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // a0 - af
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // b0 - bf
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // c0 - cf
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // d0 - df
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // e0 - ef
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // f0 - ff
};

const base64enc = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
const aschex = "0123456789ABCDEF";

pub const mime_encoder_state = extern struct {
    pos: usize,
    bufbeg: usize,
    bufend: usize,
    buf: [ENCODING_BUFFER_SIZE]u8,
};

pub const mime_encoder = extern struct {
    name: [*:0]const u8,
    encodefunc: *const fn (buffer: [*]u8, size: usize, ateof: bool, part: *curl_mimepart) callconv(.c) usize,
    sizefunc: *const fn (part: *curl_mimepart) callconv(.c) curl_off_t,
};

pub const mime_state = extern struct {
    state: c_uint,
    ptr: ?*anyopaque,
    offset: curl_off_t,
};

pub const curl_mime = extern struct {
    parent: ?*curl_mimepart,
    firstpart: ?*curl_mimepart,
    lastpart: ?*curl_mimepart,
    boundary: [MIME_BOUNDARY_LEN + 1]u8,
    state: mime_state,
};

pub const curl_read_callback = *const fn (buffer: [*]u8, size: usize, nitems: usize, instream: ?*anyopaque) callconv(.c) usize;
pub const curl_seek_callback = *const fn (instream: ?*anyopaque, offset: curl_off_t, origin: c_int) callconv(.c) c_int;
pub const curl_free_callback = *const fn (arg: ?*anyopaque) callconv(.c) void;

pub const curl_mimepart = extern struct {
    parent: ?*curl_mime,
    nextpart: ?*curl_mimepart,
    kind: c_uint,
    flags: c_uint,
    data: ?[*:0]u8,
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
    datasize: curl_off_t,
    state: mime_state,
    encoder: ?*const mime_encoder,
    encstate: mime_encoder_state,
    lastreadstatus: usize,
};

extern fn Curl_rand_alnum(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_mvaprintf(format: [*:0]const u8, args: containers.CVaListParam) callconv(.c) ?[*:0]u8;
extern fn fread(ptr: [*]u8, size: usize, nmemb: usize, stream: ?*anyopaque) callconv(.c) usize;
extern fn ferror(stream: ?*anyopaque) callconv(.c) c_int;
extern fn fclose(stream: ?*anyopaque) callconv(.c) c_int;
extern fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*anyopaque;
extern fn curlx_win32_stat(path: ?[*:0]const u8, buffer: ?*anyopaque) callconv(.c) c_int;
extern fn _access(path: [*:0]const u8, mode: c_int) callconv(.c) c_int;
extern fn _errno() callconv(.c) *c_int;

const Win32Stati64 = extern struct {
    st_dev: u32,
    st_ino: u16,
    st_mode: u16,
    st_nlink: i16,
    st_uid: i16,
    st_gid: i16,
    st_rdev: u32,
    st_size: i64,
    st_atime: i64,
    st_mtime: i64,
    st_ctime: i64,
};

fn mimeOpenFile(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque {
    if (comptime is_windows) {
        return curlx_win32_fopen(filename, mode);
    } else {
        return fopen(filename, mode);
    }
}

fn mimeStatFile(filename: [*:0]const u8, out_filesize: *curl_off_t) bool {
    if (comptime is_windows) {
        var sbuf: Win32Stati64 = undefined;
        if (curlx_win32_stat(filename, &sbuf) != 0)
            return false;
        if ((sbuf.st_mode & 0xf000) == 0x4000)
            return false;
        out_filesize.* = -1;
        if (_access(filename, 4) == 0) {
            out_filesize.* = sbuf.st_size;
        }
        return true;
    } else if (comptime builtin.os.tag == .linux) {
        var sbuf: std.os.linux.Statx = undefined;
        if (std.os.linux.errno(std.os.linux.statx(std.os.linux.AT.FDCWD, filename, 0, std.os.linux.STATX.BASIC_STATS, &sbuf)) != .SUCCESS)
            return false;
        if ((sbuf.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFDIR)
            return false;
        out_filesize.* = -1;
        if (std.c.access(filename, std.c.R_OK) == 0) {
            out_filesize.* = @intCast(sbuf.size);
        }
        return true;
    } else {
        var sbuf: std.c.Stat = undefined;
        if (std.c.stat(filename, &sbuf) != 0)
            return false;
        if ((sbuf.mode & std.c.S.IFMT) == std.c.S.IFDIR)
            return false;
        out_filesize.* = -1;
        if (std.c.access(filename, std.c.R_OK) == 0) {
            out_filesize.* = @intCast(sbuf.size);
        }
        return true;
    }
}

fn getErrno() c_int {
    if (comptime is_windows) {
        return _errno().*;
    } else {
        return std.c._errno().*;
    }
}

fn mimesetstate(state: *mime_state, tok: c_uint, ptr: ?*anyopaque) void {
    state.state = tok;
    state.ptr = ptr;
    state.offset = 0;
}

fn escape_string(mime_formescape: bool, src: [*:0]const u8, strategy: c_uint) ?[*:0]u8 {
    const use_backslash = (strategy == MIMESTRATEGY_MAIL) or mime_formescape;
    var s: [*:0]const u8 = src;
    var bytecount: usize = 0;
    while (s[0] != 0) : (s += 1) {
        if (use_backslash) {
            if (s[0] == '"' or s[0] == '\\') {
                bytecount += 1;
            }
        } else {
            if (s[0] == '"' or s[0] == '\r' or s[0] == '\n') {
                bytecount += 2;
            }
        }
    }
    bytecount += @intFromPtr(s) - @intFromPtr(src);

    const raw = mem.malloc(bytecount + 1) orelse return null;
    const dst: [*]u8 = @ptrCast(raw);
    var d: usize = 0;
    var i: usize = 0;
    while (src[i] != 0) : (i += 1) {
        const c = src[i];
        if (use_backslash) {
            if (c == '"' or c == '\\') {
                dst[d] = '\\';
                d += 1;
            }
            dst[d] = c;
            d += 1;
        } else {
            switch (c) {
                '"' => {
                    @memcpy(dst[d .. d + 3], "%22");
                    d += 3;
                },
                '\r' => {
                    @memcpy(dst[d .. d + 3], "%0D");
                    d += 3;
                },
                '\n' => {
                    @memcpy(dst[d .. d + 3], "%0A");
                    d += 3;
                },
                else => {
                    dst[d] = c;
                    d += 1;
                },
            }
        }
    }
    dst[d] = 0;
    return @ptrCast(dst);
}

fn match_header(hdr: *curl_slist, lbl: [*:0]const u8, len: usize) ?[*:0]u8 {
    const hdata = hdr.data orelse return null;
    if (curl_strnequal(hdata, lbl, len) != 0 and hdata[len] == ':') {
        var value: [*:0]u8 = hdata + len + 1;
        while (value[0] == ' ') : (value += 1) {}
        return value;
    }
    return null;
}

fn search_header(hdrlist: ?*curl_slist, hdr: [*:0]const u8, len: usize) ?[*:0]u8 {
    var cur = hdrlist;
    while (cur) |node| : (cur = node.next) {
        if (match_header(node, hdr, len)) |value| {
            return value;
        }
    }
    return null;
}

fn strippath(fullfile: ?[*:0]const u8) ?[*:0]u8 {
    const ff = fullfile orelse return null;
    const filename = mem.strdup(ff) orelse return null;
    defer mem.free(filename);

    const span = std.mem.span(filename);
    var base_idx: usize = 0;
    if (comptime is_windows) {
        for (span, 0..) |ch, idx| {
            if (ch == '/' or ch == '\\') {
                base_idx = idx + 1;
            }
        }
    } else {
        if (std.mem.lastIndexOfScalar(u8, span, '/')) |pos| {
            base_idx = pos + 1;
        }
    }
    const base_ptr: [*:0]const u8 = filename + base_idx;
    return mem.strdup(base_ptr);
}

fn cleanup_encoder_state(p: *mime_encoder_state) void {
    p.pos = 0;
    p.bufbeg = 0;
    p.bufend = 0;
}

fn encoder_nop_read(buffer: [*]u8, size: usize, ateof: bool, part: *curl_mimepart) callconv(.c) usize {
    _ = ateof;
    const st = &part.encstate;
    const insize = st.bufend - st.bufbeg;

    if (size == 0)
        return STOP_FILLING;
    const n = if (size > insize) insize else size;
    if (n != 0)
        @memcpy(buffer[0..n], st.buf[st.bufbeg .. st.bufbeg + n]);
    st.bufbeg += n;
    return n;
}

fn encoder_nop_size(part: *curl_mimepart) callconv(.c) curl_off_t {
    return part.datasize;
}

fn encoder_7bit_read(buffer: [*]u8, size: usize, ateof: bool, part: *curl_mimepart) callconv(.c) usize {
    _ = ateof;
    const st = &part.encstate;
    var cursize = st.bufend - st.bufbeg;

    if (size < 2)
        return if (size != 0) STOP_FILLING else 0;

    const sz = size;
    if (cursize > sz)
        cursize = sz;

    var buf_idx: usize = 0;
    while (st.bufbeg < st.bufend) : (st.bufbeg += 1) {
        const c = st.buf[st.bufbeg];
        if ((c & 0x80) != 0)
            return READ_ERROR;

        if (c == '\r') {
            if (st.bufbeg + 1 >= st.bufend)
                break;
            if (st.buf[st.bufbeg + 1] != '\n')
                return READ_ERROR;
            if (cursize < 2)
                break;
            buffer[buf_idx] = '\r';
            buffer[buf_idx + 1] = '\n';
            buf_idx += 2;
            cursize -= 2;
            st.pos = 0;
            st.bufbeg += 1;
        } else if (c == '\n') {
            if (cursize < 2)
                break;
            buffer[buf_idx] = '\r';
            buffer[buf_idx + 1] = '\n';
            buf_idx += 2;
            cursize -= 2;
            st.pos = 0;
        } else {
            if (cursize == 0)
                break;
            buffer[buf_idx] = c;
            buf_idx += 1;
            cursize -= 1;
            st.pos += 1;
            if (st.pos > MAX_ENCODED_LINE_LENGTH)
                return READ_ERROR;
        }
    }

    return buf_idx;
}

fn encoder_base64_read(buffer: [*]u8, size: usize, ateof: bool, part: *curl_mimepart) callconv(.c) usize {
    const st = &part.encstate;
    var cursize: usize = 0;
    var ptr: usize = 0;

    while (st.bufbeg < st.bufend) {
        if (st.pos > MAX_ENCODED_LINE_LENGTH - 4) {
            if (size - cursize < 2)
                break;
            buffer[ptr] = '\r';
            buffer[ptr + 1] = '\n';
            ptr += 2;
            cursize += 2;
            st.pos = 0;
        }

        if (size - cursize < 4)
            break;
        if (st.bufend - st.bufbeg < 3)
            break;

        var i: c_int = @intCast(st.buf[st.bufbeg] & 0xFF);
        st.bufbeg += 1;
        i = (i << 8) | @as(c_int, @intCast(st.buf[st.bufbeg] & 0xFF));
        st.bufbeg += 1;
        i = (i << 8) | @as(c_int, @intCast(st.buf[st.bufbeg] & 0xFF));
        st.bufbeg += 1;
        buffer[ptr] = base64enc[@intCast((i >> 18) & 0x3F)];
        buffer[ptr + 1] = base64enc[@intCast((i >> 12) & 0x3F)];
        buffer[ptr + 2] = base64enc[@intCast((i >> 6) & 0x3F)];
        buffer[ptr + 3] = base64enc[@intCast(i & 0x3F)];
        ptr += 4;
        cursize += 4;
        st.pos += 4;
    }

    if (ateof) {
        if (size - cursize >= 4) {
            buffer[ptr + 2] = '=';
            buffer[ptr + 3] = '=';
            var i: c_int = 0;
            switch (st.bufend - st.bufbeg) {
                2 => {
                    i = @intCast(st.buf[st.bufbeg + 1] & 0xFF);
                    buffer[ptr + 2] = base64enc[@intCast((i << 2) & 0x3F)];
                    i = (i << 8) | @as(c_int, @intCast(st.buf[st.bufbeg] & 0xFF));
                    buffer[ptr + 1] = base64enc[@intCast((i >> 4) & 0x3F)];
                    buffer[ptr] = base64enc[@intCast((i >> 10) & 0x3F)];
                    st.bufbeg = st.bufend;
                    st.pos += 4;
                    cursize += 4;
                },
                1 => {
                    i = @intCast(st.buf[st.bufbeg] & 0xFF);
                    i = i << 8;
                    buffer[ptr + 1] = base64enc[@intCast((i >> 4) & 0x3F)];
                    buffer[ptr] = base64enc[@intCast((i >> 10) & 0x3F)];
                    st.bufbeg = st.bufend;
                    st.pos += 4;
                    cursize += 4;
                },
                else => {},
            }
        }
    }

    return cursize;
}

fn encoder_base64_size(part: *curl_mimepart) callconv(.c) curl_off_t {
    var size = part.datasize;

    if (size <= 0)
        return size;

    const d = @divTrunc(size, 3);
    const r = @rem(size, 3);
    if (d > @divTrunc(std.math.maxInt(curl_off_t) - 4, 4))
        return -1;
    size = 4 * (d + @as(curl_off_t, if (r != 0) 1 else 0));

    return std.math.add(curl_off_t, size, 2 * @divTrunc(size - 1, MAX_ENCODED_LINE_LENGTH)) catch -1;
}

fn qp_lookahead_eol(st: *mime_encoder_state, ateof: bool, n: usize) c_int {
    const pos = st.bufbeg + n;
    if (pos >= st.bufend)
        return if (ateof) 1 else -1;
    if (qp_class[st.buf[pos]] == QP_LF)
        return 1;
    if (qp_class[st.buf[pos]] == QP_CR) {
        if (pos + 1 >= st.bufend)
            return if (ateof) 0 else -1;
        if (qp_class[st.buf[pos + 1]] == QP_LF)
            return 1;
    }
    return 0;
}

fn encoder_qp_read(buffer: [*]u8, size: usize, ateof: bool, part: *curl_mimepart) callconv(.c) usize {
    const st = &part.encstate;
    var cursize: usize = 0;
    var ptr: usize = 0;

    while (st.bufbeg < st.bufend) {
        var len: usize = 1;
        var consumed: usize = 1;
        const i: c_int = st.buf[st.bufbeg];
        var buf: [4]u8 = undefined;
        buf[0] = @intCast(i);
        buf[1] = aschex[@intCast((i >> 4) & 0xF)];
        buf[2] = aschex[@intCast(i & 0xF)];

        switch (qp_class[st.buf[st.bufbeg]]) {
            QP_OK => {},
            QP_SP => {
                switch (qp_lookahead_eol(st, ateof, 1)) {
                    -1 => return cursize,
                    0 => {},
                    else => {
                        buf[0] = '=';
                        len = 3;
                    },
                }
            },
            QP_CR => {
                switch (qp_lookahead_eol(st, ateof, 0)) {
                    -1 => return cursize,
                    1 => {
                        buf[len] = '\n';
                        len += 1;
                        consumed = 2;
                    },
                    else => {
                        buf[0] = '=';
                        len = 3;
                    },
                }
            },
            QP_LF => {
                buf[0] = '\r';
                buf[1] = '\n';
                len = 2;
            },
            else => {
                buf[0] = '=';
                len = 3;
            },
        }

        if (buf[len - 1] != '\n') {
            var softlinebreak = st.pos + len > MAX_ENCODED_LINE_LENGTH;
            if (!softlinebreak and st.pos + len == MAX_ENCODED_LINE_LENGTH) {
                switch (qp_lookahead_eol(st, ateof, consumed)) {
                    -1 => return cursize,
                    0 => softlinebreak = true,
                    else => {},
                }
            }
            if (softlinebreak) {
                buf[0] = '=';
                buf[1] = '\r';
                buf[2] = '\n';
                len = 3;
                consumed = 0;
            }
        }

        if (len > size - cursize) {
            if (cursize == 0)
                return STOP_FILLING;
            break;
        }

        @memcpy(buffer[ptr .. ptr + len], buf[0..len]);
        cursize += len;
        ptr += len;
        st.pos += len;
        if (buf[len - 1] == '\n')
            st.pos = 0;
        st.bufbeg += consumed;
    }

    return cursize;
}

fn encoder_qp_size(part: *curl_mimepart) callconv(.c) curl_off_t {
    return if (part.datasize != 0) -1 else 0;
}

const encoders = [_]mime_encoder{
    .{ .name = "binary", .encodefunc = encoder_nop_read, .sizefunc = encoder_nop_size },
    .{ .name = "8bit", .encodefunc = encoder_nop_read, .sizefunc = encoder_nop_size },
    .{ .name = "7bit", .encodefunc = encoder_7bit_read, .sizefunc = encoder_nop_size },
    .{ .name = "base64", .encodefunc = encoder_base64_read, .sizefunc = encoder_base64_size },
    .{ .name = "quoted-printable", .encodefunc = encoder_qp_read, .sizefunc = encoder_qp_size },
};

fn mime_mem_read(buffer: [*]u8, size: usize, nitems: usize, instream: ?*anyopaque) callconv(.c) usize {
    const part: *curl_mimepart = @ptrCast(@alignCast(instream.?));
    _ = size;
    if (nitems == 0)
        return STOP_FILLING;
    const rem: usize = @intCast(part.datasize - part.state.offset);
    const sz = @min(rem, nitems);
    if (sz != 0) {
        const src: [*]const u8 = @ptrCast(part.data.?);
        const off: usize = @intCast(part.state.offset);
        @memcpy(buffer[0..sz], src[off .. off + sz]);
    }
    return sz;
}

fn mime_mem_seek(instream: ?*anyopaque, offset: curl_off_t, origin: c_int) callconv(.c) c_int {
    const part: *curl_mimepart = @ptrCast(@alignCast(instream.?));
    var new_off = offset;
    switch (origin) {
        1 => new_off += part.state.offset, // SEEK_CUR
        2 => new_off += part.datasize, // SEEK_END
        else => {},
    }
    if (new_off < 0 or new_off > part.datasize)
        return CURL_SEEKFUNC_FAIL;
    part.state.offset = new_off;
    return CURL_SEEKFUNC_OK;
}

fn mime_mem_free(ptr: ?*anyopaque) callconv(.c) void {
    const part: *curl_mimepart = @ptrCast(@alignCast(ptr.?));
    if (part.data) |d| {
        mem.free(@ptrCast(d));
        part.data = null;
    }
}

fn mime_open_file(part: *curl_mimepart) c_int {
    if (part.fp != null)
        return 0;
    const fopen_mode: [*:0]const u8 = if ((part.flags & MIME_FAST_CONV) != 0)
        (if (is_windows) "rt" else "r")
    else
        "rb";
    part.fp = if (part.data) |d| mimeOpenFile(d, fopen_mode) else null;
    return if (part.fp != null) 0 else -1;
}

fn mime_file_read(buffer: [*]u8, size: usize, nitems: usize, instream: ?*anyopaque) callconv(.c) usize {
    const part: *curl_mimepart = @ptrCast(@alignCast(instream.?));
    if (nitems == 0)
        return STOP_FILLING;
    if (mime_open_file(part) != 0)
        return READ_ERROR;
    const n = fread(buffer, size, nitems, part.fp);
    if (n == 0 and ferror(part.fp) != 0) {
        _ = fclose(part.fp);
        part.fp = null;
        return READ_ERROR;
    }
    return n;
}

fn mime_file_seek(instream: ?*anyopaque, offset: curl_off_t, whence: c_int) callconv(.c) c_int {
    const part: *curl_mimepart = @ptrCast(@alignCast(instream.?));
    if (whence == SEEK_SET and offset == 0 and part.fp == null)
        return CURL_SEEKFUNC_OK;
    if (mime_open_file(part) != 0)
        return CURL_SEEKFUNC_FAIL;
    return if (os_leaf.curlx_fseek(part.fp, offset, whence) != 0)
        CURL_SEEKFUNC_CANTSEEK
    else
        CURL_SEEKFUNC_OK;
}

fn mime_file_free(ptr: ?*anyopaque) callconv(.c) void {
    const part: *curl_mimepart = @ptrCast(@alignCast(ptr.?));
    if (part.fp) |fp| {
        _ = fclose(fp);
        part.fp = null;
    }
    if (part.data) |d| {
        mem.free(@ptrCast(d));
        part.data = null;
    }
}

fn readback_bytes(state: *mime_state, buffer: [*]u8, bufsize: usize, bytes: [*]const u8, numbytes: usize, trail: []const u8) usize {
    const offset: usize = @intCast(state.offset);
    var sz: usize = 0;
    if (numbytes > offset) {
        sz = numbytes - offset;
        if (sz > bufsize)
            sz = bufsize;
        @memcpy(buffer[0..sz], bytes[offset .. offset + sz]);
    }
    if (bufsize > sz) {
        var tsz: usize = offset + sz - numbytes;
        if (trail.len > tsz) {
            tsz = trail.len - tsz;
            if (tsz > bufsize - sz)
                tsz = bufsize - sz;
            const trail_off = offset + sz - numbytes;
            @memcpy(buffer[sz .. sz + tsz], trail[trail_off .. trail_off + tsz]);
            sz += tsz;
        }
    }
    state.offset += @intCast(sz);
    return sz;
}

fn read_encoded_part_content(part: *curl_mimepart, buffer: [*]u8, bufsize: usize, hasread: *bool) usize {
    const st = &part.encstate;
    var cursize: usize = 0;
    var buf_ptr = buffer;
    var rem_size = bufsize;

    for (0..1024) |_| {
        if (st.bufbeg < st.bufend or part.lastreadstatus == 0) {
            const sz = part.encoder.?.encodefunc(buf_ptr, rem_size, part.lastreadstatus == 0, part);
            switch (sz) {
                0 => {
                    if (part.lastreadstatus == 0)
                        return cursize;
                },
                READ_ERROR, CURL_READFUNC_ABORT, CURL_READFUNC_PAUSE => {
                    return if (cursize != 0) cursize else sz;
                },
                STOP_FILLING => {
                    return cursize;
                },
                else => {
                    cursize += sz;
                    buf_ptr += sz;
                    rem_size -= sz;
                    continue;
                },
            }
        }

        if (st.bufbeg != 0) {
            const len = st.bufend - st.bufbeg;
            if (len != 0)
                std.mem.copyForwards(u8, st.buf[0..len], st.buf[st.bufbeg .. st.bufbeg + len]);
            st.bufbeg = 0;
            st.bufend = len;
        }
        if (st.bufend >= st.buf.len)
            return if (cursize != 0) cursize else READ_ERROR;
        const sz = read_part_content(part, st.buf[st.bufend..].ptr, st.buf.len - st.bufend, hasread);
        switch (sz) {
            0 => {
                part.lastreadstatus = 0;
            },
            READ_ERROR, CURL_READFUNC_ABORT, CURL_READFUNC_PAUSE => {
                part.lastreadstatus = sz;
                return if (cursize != 0) cursize else sz;
            },
            STOP_FILLING => {
                return cursize;
            },
            else => {
                part.lastreadstatus = sz;
                st.bufend += sz;
            },
        }
    }
    return READ_ERROR;
}

fn read_part_content(part: *curl_mimepart, buffer: [*]u8, bufsize: usize, hasread: *bool) usize {
    var sz: usize = 0;
    switch (part.lastreadstatus) {
        0, READ_ERROR, CURL_READFUNC_ABORT, CURL_READFUNC_PAUSE => return part.lastreadstatus,
        else => {},
    }

    if (part.datasize != @as(curl_off_t, -1) and part.encoder == null) {
        std.debug.assert(part.state.offset <= part.datasize);
        const rem: usize = @intCast(part.datasize - part.state.offset);
        if (bufsize > rem) {
            return read_part_content_inner(part, buffer, rem, hasread);
        }
    }
    sz = read_part_content_inner(part, buffer, bufsize, hasread);
    return sz;
}

fn read_part_content_inner(part: *curl_mimepart, buffer: [*]u8, bufsize: usize, hasread: *bool) usize {
    var sz: usize = 0;
    switch (part.kind) {
        MIMEKIND_MULTIPART => {
            sz = mime_subparts_read(buffer, 1, bufsize, part.arg, hasread);
        },
        MIMEKIND_FILE => {
            if (part.fp != null and (part.flags & MIME_FILE_TRIED) != 0 and ferror(part.fp) != 0)
                return READ_ERROR;
            part.flags |= MIME_FILE_TRIED;
            if (part.readfunc) |rf| {
                if ((part.flags & MATCH_STATEDATA) == 0) {
                    if (hasread.*)
                        return STOP_FILLING;
                    hasread.* = true;
                }
                sz = rf(buffer, 1, bufsize, part.arg);
            }
        },
        else => {
            if (part.readfunc) |rf| {
                if ((part.flags & MATCH_STATEDATA) == 0) {
                    if (hasread.*)
                        return STOP_FILLING;
                    hasread.* = true;
                }
                sz = rf(buffer, 1, bufsize, part.arg);
            }
        },
    }

    switch (sz) {
        0 => {},
        READ_ERROR, CURL_READFUNC_ABORT, CURL_READFUNC_PAUSE, STOP_FILLING => return sz,
        else => {
            part.state.offset += @intCast(sz);
            part.lastreadstatus = sz;
        },
    }
    return sz;
}

fn readback_part(part: *curl_mimepart, buffer: [*]u8, bufsize: usize, hasread: *bool) usize {
    var cursize: usize = 0;
    var buf_ptr = buffer;
    var rem_size = bufsize;

    while (rem_size != 0) {
        var sz: usize = 0;
        const hdr: ?*curl_slist = @ptrCast(@alignCast(part.state.ptr));
        switch (part.state.state) {
            MIMESTATE_BEGIN => {
                mimesetstate(
                    &part.state,
                    if ((part.flags & MIME_BODY_ONLY) != 0) MIMESTATE_BODY else MIMESTATE_CURL,
                    part.curlheaders,
                );
            },
            MIMESTATE_USER => {
                if (hdr == null) {
                    mimesetstate(&part.state, MIMESTATE_EOH, null);
                    break;
                }
                if (match_header(hdr.?, "Content-Type", 12) != null) {
                    mimesetstate(&part.state, MIMESTATE_USER, hdr.?.next);
                    break;
                }
                const hdata = hdr.?.data.?;
                sz = readback_bytes(&part.state, buf_ptr, rem_size, hdata, std.mem.len(hdata), "\r\n");
                if (sz == 0)
                    mimesetstate(&part.state, MIMESTATE_USER, hdr.?.next);
            },
            MIMESTATE_CURL => {
                if (hdr == null) {
                    mimesetstate(&part.state, MIMESTATE_USER, part.userheaders);
                } else {
                    const hdata = hdr.?.data.?;
                    sz = readback_bytes(&part.state, buf_ptr, rem_size, hdata, std.mem.len(hdata), "\r\n");
                    if (sz == 0)
                        mimesetstate(&part.state, MIMESTATE_CURL, hdr.?.next);
                }
            },
            MIMESTATE_EOH => {
                sz = readback_bytes(&part.state, buf_ptr, rem_size, "\r\n", 2, "");
                if (sz == 0)
                    mimesetstate(&part.state, MIMESTATE_BODY, null);
            },
            MIMESTATE_BODY => {
                cleanup_encoder_state(&part.encstate);
                part.lastreadstatus = 1;
                mimesetstate(&part.state, MIMESTATE_CONTENT, null);
            },
            MIMESTATE_CONTENT => {
                if (part.encoder != null) {
                    sz = read_encoded_part_content(part, buf_ptr, rem_size, hasread);
                } else {
                    sz = read_part_content(part, buf_ptr, rem_size, hasread);
                }
                switch (sz) {
                    0 => {
                        mimesetstate(&part.state, MIMESTATE_END, null);
                        if (part.kind == MIMEKIND_FILE and part.fp != null) {
                            _ = fclose(part.fp);
                            part.fp = null;
                        }
                        if (cursize != 0)
                            return cursize;
                    },
                    READ_ERROR, CURL_READFUNC_ABORT, CURL_READFUNC_PAUSE => {
                        return if (cursize != 0) cursize else sz;
                    },
                    STOP_FILLING => {
                        return cursize;
                    },
                    else => {},
                }
            },
            MIMESTATE_END => {
                return cursize;
            },
            else => {
                unreachable;
            },
        }

        cursize += sz;
        buf_ptr += sz;
        rem_size -= sz;
    }

    return cursize;
}

fn mime_subparts_read(buffer: [*]u8, size: usize, nitems: usize, instream: ?*anyopaque, hasread: *bool) usize {
    const mime: *curl_mime = @ptrCast(@alignCast(instream.?));
    _ = size;
    var cursize: usize = 0;
    var buf_ptr = buffer;
    var rem_size = nitems;

    while (rem_size != 0) {
        var sz: usize = 0;
        const part: ?*curl_mimepart = @ptrCast(@alignCast(mime.state.ptr));
        switch (mime.state.state) {
            MIMESTATE_BEGIN, MIMESTATE_BODY => {
                hasread.* = true;
                mimesetstate(&mime.state, MIMESTATE_BOUNDARY1, mime.firstpart);
                mime.state.offset += 2;
            },
            MIMESTATE_BOUNDARY1 => {
                sz = readback_bytes(&mime.state, buf_ptr, rem_size, "\r\n--", 4, "");
                if (sz == 0)
                    mimesetstate(&mime.state, MIMESTATE_BOUNDARY2, part);
            },
            MIMESTATE_BOUNDARY2 => {
                const blen = std.mem.len(@as([*:0]const u8, @ptrCast(&mime.boundary)));
                if (part != null) {
                    sz = readback_bytes(&mime.state, buf_ptr, rem_size, &mime.boundary, blen, "\r\n");
                } else {
                    sz = readback_bytes(&mime.state, buf_ptr, rem_size, &mime.boundary, blen, "--\r\n");
                }
                if (sz == 0) {
                    mimesetstate(&mime.state, MIMESTATE_CONTENT, part);
                }
            },
            MIMESTATE_CONTENT => {
                if (part == null) {
                    mimesetstate(&mime.state, MIMESTATE_END, null);
                    break;
                }
                sz = readback_part(part.?, buf_ptr, rem_size, hasread);
                switch (sz) {
                    READ_ERROR, CURL_READFUNC_ABORT, CURL_READFUNC_PAUSE => {
                        return if (cursize != 0) cursize else sz;
                    },
                    0 => {
                        mimesetstate(&mime.state, MIMESTATE_BOUNDARY1, part.?.nextpart);
                    },
                    else => {},
                }
            },
            MIMESTATE_END => {
                return cursize;
            },
            else => {
                unreachable;
            },
        }

        cursize += sz;
        buf_ptr += sz;
        rem_size -= sz;
    }

    return cursize;
}

fn mime_part_rewind(part: *curl_mimepart) c_int {
    var res: c_int = CURL_SEEKFUNC_OK;
    var targetstate: c_uint = MIMESTATE_BEGIN;

    if ((part.flags & MIME_BODY_ONLY) != 0)
        targetstate = MIMESTATE_BODY;
    cleanup_encoder_state(&part.encstate);
    if (part.state.state > targetstate) {
        res = CURL_SEEKFUNC_CANTSEEK;
        if (part.seekfunc) |sf| {
            res = sf(part.arg, 0, SEEK_SET);
            switch (res) {
                CURL_SEEKFUNC_OK, CURL_SEEKFUNC_FAIL, CURL_SEEKFUNC_CANTSEEK => {},
                -1 => res = CURL_SEEKFUNC_CANTSEEK,
                else => res = CURL_SEEKFUNC_FAIL,
            }
        }
    }

    if (res == CURL_SEEKFUNC_OK)
        mimesetstate(&part.state, targetstate, null);

    part.lastreadstatus = 1;
    return res;
}

fn mime_subparts_seek(instream: ?*anyopaque, offset: curl_off_t, whence: c_int) callconv(.c) c_int {
    const mime: *curl_mime = @ptrCast(@alignCast(instream.?));
    var result: c_int = CURL_SEEKFUNC_OK;

    if (whence != SEEK_SET or offset != 0)
        return CURL_SEEKFUNC_CANTSEEK;

    if (mime.state.state == MIMESTATE_BEGIN)
        return CURL_SEEKFUNC_OK;

    var part = mime.firstpart;
    while (part) |p| : (part = p.nextpart) {
        const res = mime_part_rewind(p);
        if (res != CURL_SEEKFUNC_OK)
            result = res;
    }

    if (result == CURL_SEEKFUNC_OK)
        mimesetstate(&mime.state, MIMESTATE_BEGIN, null);

    return result;
}

fn cleanup_part_content(part: *curl_mimepart) void {
    if (part.freefunc) |ff| {
        ff(part.arg);
    }

    part.readfunc = null;
    part.seekfunc = null;
    part.freefunc = null;
    part.arg = @ptrCast(part);
    part.data = null;
    part.fp = null;
    part.datasize = 0;
    cleanup_encoder_state(&part.encstate);
    part.kind = MIMEKIND_NONE;
    part.flags &= ~MIME_FAST_CONV;
    part.flags &= ~MIME_FILE_TRIED;
    part.lastreadstatus = 1;
    part.state.state = MIMESTATE_BEGIN;
}

fn mime_subparts_free(ptr: ?*anyopaque) callconv(.c) void {
    const mime_opt: ?*curl_mime = @ptrCast(@alignCast(ptr));
    if (mime_opt) |mime| {
        if (mime.parent) |parent| {
            parent.freefunc = null;
            cleanup_part_content(parent);
        }
        while (mime.firstpart) |part| {
            mime.firstpart = part.nextpart;
            Curl_mime_cleanpart(part);
            mem.free(part);
        }
        mem.free(mime);
    }
}

fn mime_subparts_unbind(ptr: ?*anyopaque) callconv(.c) void {
    const mime_opt: ?*curl_mime = @ptrCast(@alignCast(ptr));
    if (mime_opt) |mime| {
        if (mime.parent) |parent| {
            parent.freefunc = null;
            cleanup_part_content(parent);
            mime.parent = null;
        }
    }
}

pub export fn Curl_mime_cleanpart(part_opt: ?*curl_mimepart) callconv(.c) void {
    const part = part_opt orelse return;
    cleanup_part_content(part);
    curl_slist_free_all(part.curlheaders);
    if ((part.flags & MIME_USERHEADERS_OWNER) != 0)
        curl_slist_free_all(part.userheaders);
    if (part.mimetype) |p| {
        mem.free(@ptrCast(p));
        part.mimetype = null;
    }
    if (part.name) |p| {
        mem.free(@ptrCast(p));
        part.name = null;
    }
    if (part.filename) |p| {
        mem.free(@ptrCast(p));
        part.filename = null;
    }
    Curl_mime_initpart(part);
}

pub export fn curl_mime_free(mime_opt: ?*curl_mime) callconv(.c) void {
    if (mime_opt) |mime| {
        mime_subparts_unbind(mime);
        mime_subparts_free(mime);
    }
}

pub export fn Curl_mime_duppart(data: ?*anyopaque, dst: *curl_mimepart, src: *const curl_mimepart) callconv(.c) CURLcode {
    var res: CURLcode = CURLE_OK;

    switch (src.kind) {
        MIMEKIND_NONE => {},
        MIMEKIND_DATA => {
            res = curl_mime_data(dst, src.data, @intCast(src.datasize));
        },
        MIMEKIND_FILE => {
            res = curl_mime_filedata(dst, src.data);
            if (res == CURLE_READ_ERROR)
                res = CURLE_OK;
        },
        MIMEKIND_CALLBACK => {
            res = curl_mime_data_cb(dst, src.datasize, src.readfunc, src.seekfunc, src.freefunc, src.arg);
        },
        MIMEKIND_MULTIPART => {
            const m = curl_mime_init(data);
            res = if (m != null) curl_mime_subparts(dst, m) else CURLE_OUT_OF_MEMORY;

            var s = if (src.arg) |a| @as(*curl_mime, @ptrCast(@alignCast(a))).firstpart else null;
            while (res == CURLE_OK and s != null) : (s = s.?.nextpart) {
                const d = curl_mime_addpart(m);
                res = if (d != null) Curl_mime_duppart(data, d.?, s.?) else CURLE_OUT_OF_MEMORY;
            }
        },
        else => {
            res = CURLE_BAD_FUNCTION_ARGUMENT;
        },
    }

    if (res == CURLE_OK and src.userheaders != null) {
        const duphdrs = Curl_slist_duplicate(src.userheaders);
        if (duphdrs == null) {
            res = CURLE_OUT_OF_MEMORY;
        } else {
            res = curl_mime_headers(dst, duphdrs, 1);
            if (res != CURLE_OK)
                curl_slist_free_all(duphdrs);
        }
    }

    if (res == CURLE_OK) {
        dst.encoder = src.encoder;
        res = curl_mime_type(dst, src.mimetype);
    }
    if (res == CURLE_OK)
        res = curl_mime_name(dst, src.name);
    if (res == CURLE_OK)
        res = curl_mime_filename(dst, src.filename);

    if (res != CURLE_OK)
        Curl_mime_cleanpart(dst);

    return res;
}

pub export fn curl_mime_init(easy: ?*anyopaque) callconv(.c) ?*curl_mime {
    const raw = mem.malloc(@sizeOf(curl_mime)) orelse return null;
    const mime: *curl_mime = @ptrCast(@alignCast(raw));

    mime.parent = null;
    mime.firstpart = null;
    mime.lastpart = null;

    @memset(mime.boundary[0..24], '-');
    if (Curl_rand_alnum(easy, mime.boundary[24..].ptr, MIME_RAND_BOUNDARY_CHARS + 1) != CURLE_OK) {
        mem.free(mime);
        return null;
    }
    mimesetstate(&mime.state, MIMESTATE_BEGIN, null);
    return mime;
}

pub export fn Curl_mime_initpart(part: *curl_mimepart) callconv(.c) void {
    @memset(@as([*]u8, @ptrCast(part))[0..@sizeOf(curl_mimepart)], 0);
    part.lastreadstatus = 1;
    mimesetstate(&part.state, MIMESTATE_BEGIN, null);
}

pub export fn curl_mime_addpart(mime_opt: ?*curl_mime) callconv(.c) ?*curl_mimepart {
    const mime = mime_opt orelse return null;
    const raw = mem.malloc(@sizeOf(curl_mimepart)) orelse return null;
    const part: *curl_mimepart = @ptrCast(@alignCast(raw));

    Curl_mime_initpart(part);
    part.parent = mime;

    if (mime.lastpart) |last| {
        last.nextpart = part;
    } else {
        mime.firstpart = part;
    }
    mime.lastpart = part;

    return part;
}

pub export fn curl_mime_name(part_opt: ?*curl_mimepart, name_opt: ?[*:0]const u8) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (part.name) |p| {
        mem.free(@ptrCast(p));
        part.name = null;
    }
    if (name_opt) |name| {
        part.name = mem.strdup(name) orelse return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

pub export fn curl_mime_filename(part_opt: ?*curl_mimepart, filename_opt: ?[*:0]const u8) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (part.filename) |p| {
        mem.free(@ptrCast(p));
        part.filename = null;
    }
    if (filename_opt) |filename| {
        part.filename = mem.strdup(filename) orelse return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

pub export fn curl_mime_data(part_opt: ?*curl_mimepart, ptr_opt: ?[*]const u8, datasize_in: usize) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    cleanup_part_content(part);

    if (ptr_opt) |ptr| {
        var datasize = datasize_in;
        if (datasize == CURL_ZERO_TERMINATED)
            datasize = std.mem.len(@as([*:0]const u8, @ptrCast(ptr)));

        if (datasize >= @as(usize, @intCast(std.math.maxInt(curl_off_t))))
            return CURLE_OUT_OF_MEMORY;

        const raw = mem.malloc(datasize + 1) orelse return CURLE_OUT_OF_MEMORY;
        const data_buf: [*]u8 = @ptrCast(raw);
        part.data = @ptrCast(data_buf);
        if (datasize != 0)
            @memcpy(data_buf[0..datasize], ptr[0..datasize]);
        data_buf[datasize] = 0;
        part.datasize = @intCast(datasize);
        part.readfunc = mime_mem_read;
        part.seekfunc = mime_mem_seek;
        part.freefunc = mime_mem_free;
        part.flags |= MATCH_STATEDATA;
        part.kind = MIMEKIND_DATA;
    }

    return CURLE_OK;
}

pub export fn curl_mime_filedata(part_opt: ?*curl_mimepart, filename_opt: ?[*:0]const u8) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var result: CURLcode = CURLE_OK;

    cleanup_part_content(part);

    if (filename_opt) |filename| {
        var filesize: curl_off_t = -1;
        if (!mimeStatFile(filename, &filesize))
            return CURLE_READ_ERROR;
        part.datasize = filesize;

        const d = mem.strdup(filename) orelse return CURLE_OUT_OF_MEMORY;
        part.data = d;
        part.readfunc = mime_file_read;
        part.seekfunc = mime_file_seek;
        part.freefunc = mime_file_free;
        part.kind = MIMEKIND_FILE;

        const base = strippath(filename) orelse {
            cleanup_part_content(part);
            return CURLE_OUT_OF_MEMORY;
        };
        result = curl_mime_filename(part, base);
        mem.free(@ptrCast(base));
        if (result != CURLE_OK)
            cleanup_part_content(part);
    }
    return result;
}

pub export fn curl_mime_type(part_opt: ?*curl_mimepart, mimetype_opt: ?[*:0]const u8) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (part.mimetype) |p| {
        mem.free(@ptrCast(p));
        part.mimetype = null;
    }
    if (mimetype_opt) |mimetype| {
        part.mimetype = mem.strdup(mimetype) orelse return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

pub export fn curl_mime_encoder(part_opt: ?*curl_mimepart, encoding_opt: ?[*:0]const u8) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    part.encoder = null;

    const encoding = encoding_opt orelse return CURLE_OK;

    for (&encoders) |*enc| {
        if (curl_strequal(encoding, enc.name) != 0) {
            part.encoder = enc;
            return CURLE_OK;
        }
    }

    return CURLE_BAD_FUNCTION_ARGUMENT;
}

pub export fn curl_mime_headers(part_opt: ?*curl_mimepart, headers: ?*curl_slist, take_ownership: c_int) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if ((part.flags & MIME_USERHEADERS_OWNER) != 0) {
        if (part.userheaders != headers)
            curl_slist_free_all(part.userheaders);
        part.flags &= ~MIME_USERHEADERS_OWNER;
    }
    part.userheaders = headers;
    if (headers != null and take_ownership != 0)
        part.flags |= MIME_USERHEADERS_OWNER;
    return CURLE_OK;
}

pub export fn curl_mime_data_cb(
    part_opt: ?*curl_mimepart,
    datasize: curl_off_t,
    readfunc: ?curl_read_callback,
    seekfunc: ?curl_seek_callback,
    freefunc: ?curl_free_callback,
    arg: ?*anyopaque,
) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    cleanup_part_content(part);

    if (readfunc != null) {
        part.readfunc = readfunc;
        part.seekfunc = seekfunc;
        part.freefunc = freefunc;
        part.arg = arg;
        part.datasize = datasize;
        part.kind = MIMEKIND_CALLBACK;
    }

    return CURLE_OK;
}

pub export fn Curl_mime_set_subparts(part_opt: ?*curl_mimepart, subparts_opt: ?*curl_mime, take_ownership: bool) callconv(.c) CURLcode {
    const part = part_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if (part.kind == MIMEKIND_MULTIPART and part.arg == @as(?*anyopaque, @ptrCast(subparts_opt)))
        return CURLE_OK;

    cleanup_part_content(part);

    if (subparts_opt) |subparts| {
        if (subparts.parent != null)
            return CURLE_BAD_FUNCTION_ARGUMENT;

        var root = part.parent;
        if (root != null) {
            while (root.?.parent != null and root.?.parent.?.parent != null)
                root = root.?.parent.?.parent;
            if (subparts == root.?) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
        }

        subparts.parent = part;
        part.seekfunc = mime_subparts_seek;
        part.freefunc = if (take_ownership) mime_subparts_free else mime_subparts_unbind;
        part.arg = subparts;
        part.datasize = -1;
        part.kind = MIMEKIND_MULTIPART;
    }

    return CURLE_OK;
}

pub export fn curl_mime_subparts(part: ?*curl_mimepart, subparts: ?*curl_mime) callconv(.c) CURLcode {
    return Curl_mime_set_subparts(part, subparts, true);
}

pub export fn Curl_mime_read(buffer: [*]u8, size: usize, nitems: usize, instream: ?*anyopaque) callconv(.c) usize {
    const part: *curl_mimepart = @ptrCast(@alignCast(instream.?));
    var hasread: bool = false;
    _ = size;

    if (nitems <= 4)
        return READ_ERROR;

    return readback_part(part, buffer, nitems, &hasread);
}

fn mime_size(part: *curl_mimepart) curl_off_t {
    var size = part.datasize;

    if (part.encoder) |enc|
        size = enc.sizefunc(part);

    if (size >= 0 and (part.flags & MIME_BODY_ONLY) == 0) {
        var slist = part.curlheaders;
        while (slist) |node| : (slist = node.next) {
            if (node.data) |d|
                size += @intCast(std.mem.len(d) + 2);
        }

        slist = part.userheaders;
        while (slist) |node| : (slist = node.next) {
            if (match_header(node, "Content-Type", 12) == null) {
                if (node.data) |d|
                    size += @intCast(std.mem.len(d) + 2);
            }
        }

        size += 2;
    }
    return size;
}

fn multipart_size(mime: *curl_mime) curl_off_t {
    const blen = std.mem.len(@as([*:0]const u8, @ptrCast(&mime.boundary)));
    const boundarysize: curl_off_t = @intCast(4 + blen + 2);
    var size: curl_off_t = boundarysize;

    var part = mime.firstpart;
    while (part) |p| : (part = p.nextpart) {
        const sz = mime_size(p);
        if (sz < 0) {
            size = sz;
            break;
        }
        size += boundarysize + sz;
    }

    return size;
}

fn mime_add_header_str(slp: *?*curl_slist, hdr: ?[*:0]u8) CURLcode {
    const h = hdr orelse return CURLE_OUT_OF_MEMORY;
    const slist = Curl_slist_append_nodup(slp.*, h);
    if (slist) |s| {
        slp.* = s;
        return CURLE_OK;
    }
    mem.free(@ptrCast(h));
    return CURLE_OUT_OF_MEMORY;
}

pub export fn Curl_mime_vadd_header(slp: *?*curl_slist, fmt: [*:0]const u8, ap: containers.CVaListParam) callconv(.c) CURLcode {
    const hdr = curl_mvaprintf(fmt, ap);
    return mime_add_header_str(slp, hdr);
}

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin() or builtin.os.tag == .windows,
    else => false,
};

const add_header_impl = if (use_c_vastart) struct {
    pub fn Curl_mime_add_header(slp: *?*curl_slist, fmt: [*:0]const u8, ...) callconv(.c) CURLcode {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        if (builtin.cpu.arch == .x86_64) {
            return Curl_mime_vadd_header(slp, fmt, &ap);
        } else {
            return Curl_mime_vadd_header(slp, fmt, @ptrCast(ap));
        }
    }
} else if (builtin.cpu.arch == .x86_64 and builtin.os.tag == .windows) struct {
    pub fn Curl_mime_add_header() callconv(.naked) void {
        asm volatile (
            \\movq %%r8, 24(%%rsp)
            \\movq %%r9, 32(%%rsp)
            \\leaq 24(%%rsp), %%r8
            \\jmp Curl_mime_vadd_header
        );
    }
} else if (builtin.cpu.arch == .aarch64) struct {
    pub fn Curl_mime_add_header() callconv(.naked) void {
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
            \\bl Curl_mime_vadd_header
            \\ldp x29, x30, [sp, #240]
            \\add sp, sp, #256
            \\ret
        );
    }
} else struct {};

comptime {
    @export(&add_header_impl.Curl_mime_add_header, .{ .name = "Curl_mime_add_header", .linkage = .strong });
}

fn add_content_type(slp: *?*curl_slist, type_str: [*:0]const u8, boundary_opt: ?[*:0]const u8) CURLcode {
    const b_prefix: [*:0]const u8 = if (boundary_opt != null) "; boundary=" else "";
    const b_val: [*:0]const u8 = boundary_opt orelse "";
    return mime_add_header_str(slp, curl_maprintf("Content-Type: %s%s%s", type_str, b_prefix, b_val));
}

pub export fn Curl_mime_contenttype(filename_opt: ?[*:0]const u8) callconv(.c) ?[*:0]const u8 {
    const ContentTypeEntry = struct {
        extension: [*:0]const u8,
        type_str: [*:0]const u8,
    };
    const ctts = [_]ContentTypeEntry{
        .{ .extension = ".gif", .type_str = "image/gif" },
        .{ .extension = ".jpg", .type_str = "image/jpeg" },
        .{ .extension = ".jpeg", .type_str = "image/jpeg" },
        .{ .extension = ".png", .type_str = "image/png" },
        .{ .extension = ".svg", .type_str = "image/svg+xml" },
        .{ .extension = ".txt", .type_str = "text/plain" },
        .{ .extension = ".htm", .type_str = "text/html" },
        .{ .extension = ".html", .type_str = "text/html" },
        .{ .extension = ".pdf", .type_str = "application/pdf" },
        .{ .extension = ".xml", .type_str = "application/xml" },
        .{ .extension = ".json", .type_str = "application/json" },
        .{ .extension = ".js", .type_str = "text/javascript" },
        .{ .extension = ".bin", .type_str = "application/octet-stream" },
    };

    const filename = filename_opt orelse return null;
    const flen = std.mem.len(filename);
    if (flen == 0)
        return null;

    var ext_idx = flen;
    while (ext_idx > 0) {
        ext_idx -= 1;
        const ch = filename[ext_idx];
        if (ch == '/' or ch == '\\')
            return null;
        if (ch == '.') {
            const ext_ptr: [*:0]const u8 = filename + ext_idx;
            for (ctts) |entry| {
                if (curl_strequal(ext_ptr, entry.extension) != 0)
                    return entry.type_str;
            }
            return null;
        }
    }
    return null;
}

fn content_type_match(contenttype_opt: ?[*:0]const u8, target: [*:0]const u8, len: usize) bool {
    const contenttype = contenttype_opt orelse return false;
    if (curl_strnequal(contenttype, target, len) != 0) {
        switch (contenttype[len]) {
            0, '\t', '\r', '\n', ' ', ';' => return true,
            else => {},
        }
    }
    return false;
}

pub export fn Curl_mime_prepare_headers_ex(
    mime_formescape: bool,
    part: *curl_mimepart,
    contenttype_in: ?[*:0]const u8,
    disposition_in: ?[*:0]const u8,
    strategy: c_uint,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var boundary: ?[*:0]const u8 = null;
    var customct: ?[*:0]const u8 = null;
    var encoding: ?[*:0]const u8 = null;
    var state: c_uint = MIMESTATE_BEGIN;
    var contenttype = contenttype_in;
    var disposition = disposition_in;

    curl_slist_free_all(part.curlheaders);
    part.curlheaders = null;

    if (part.state.state != MIMESTATE_BEGIN)
        return CURLE_BAD_FUNCTION_ARGUMENT;

    customct = part.mimetype;
    if (customct == null)
        customct = search_header(part.userheaders, "Content-Type", 12);
    if (customct != null)
        contenttype = customct;

    if (contenttype == null) {
        switch (part.kind) {
            MIMEKIND_MULTIPART => {
                contenttype = "multipart/mixed";
            },
            MIMEKIND_FILE => {
                contenttype = Curl_mime_contenttype(part.filename);
                if (contenttype == null) {
                    contenttype = Curl_mime_contenttype(part.data);
                    if (contenttype == null and part.filename != null)
                        contenttype = "application/octet-stream";
                }
            },
            else => {
                contenttype = Curl_mime_contenttype(part.filename);
            },
        }
    }

    if (part.kind == MIMEKIND_MULTIPART) {
        var subparts = @as(*curl_mime, @ptrCast(@alignCast(part.arg.?))).firstpart;
        while (subparts) |sp| : (subparts = sp.nextpart) {
            var subdisp: ?[*:0]const u8 = null;
            if (sp.filename != null or sp.name != null)
                subdisp = if (strategy == MIMESTRATEGY_FORM) "form-data" else "attachment";
            result = Curl_mime_prepare_headers_ex(mime_formescape, sp, null, subdisp, strategy);
            if (result != CURLE_OK)
                return result;
        }
        boundary = @ptrCast(&@as(*curl_mime, @ptrCast(@alignCast(part.arg.?))).boundary);
    } else if (contenttype != null and customct == null and
        content_type_match(contenttype, "text/plain", 10) and
        (strategy == MIMESTRATEGY_MAIL or part.filename == null))
    {
        contenttype = null;
    }

    if (search_header(part.userheaders, "Content-Disposition", 19) == null) {
        if (disposition == null and
            (part.filename != null or part.name != null or
                (contenttype != null and curl_strnequal(contenttype.?, "multipart/", 10) == 0)))
        {
            disposition = "attachment";
        }
        if (disposition != null and curl_strequal(disposition.?, "attachment") != 0 and
            part.name == null and part.filename == null)
        {
            disposition = null;
        }
        if (disposition != null) {
            const backslash = (strategy == MIMESTRATEGY_MAIL) or mime_formescape;
            if (backslash) {
                if (part.name) |pname| {
                    if (std.mem.indexOfAny(u8, std.mem.span(pname), "\r\n") != null)
                        return CURLE_BAD_FUNCTION_ARGUMENT;
                }
                if (part.filename) |pfn| {
                    if (std.mem.indexOfAny(u8, std.mem.span(pfn), "\r\n") != null)
                        return CURLE_BAD_FUNCTION_ARGUMENT;
                }
            }
            var name: ?[*:0]u8 = null;
            var filename: ?[*:0]u8 = null;
            if (part.name) |pname| {
                name = escape_string(mime_formescape, pname, strategy) orelse return CURLE_OUT_OF_MEMORY;
            }
            if (part.filename) |pfn| {
                filename = escape_string(mime_formescape, pfn, strategy) orelse {
                    if (name) |n| mem.free(@ptrCast(n));
                    return CURLE_OUT_OF_MEMORY;
                };
            }
            const name_pre: [*:0]const u8 = if (name != null) "; name=\"" else "";
            const name_val: [*:0]const u8 = name orelse "";
            const name_suf: [*:0]const u8 = if (name != null) "\"" else "";
            const fn_pre: [*:0]const u8 = if (filename != null) "; filename=\"" else "";
            const fn_val: [*:0]const u8 = filename orelse "";
            const fn_suf: [*:0]const u8 = if (filename != null) "\"" else "";

            result = mime_add_header_str(
                &part.curlheaders,
                curl_maprintf("Content-Disposition: %s%s%s%s%s%s%s", disposition.?, name_pre, name_val, name_suf, fn_pre, fn_val, fn_suf),
            );
            if (name) |n| mem.free(@ptrCast(n));
            if (filename) |f| mem.free(@ptrCast(f));
            if (result != CURLE_OK)
                return result;
        }
    }

    if (contenttype) |ct| {
        result = add_content_type(&part.curlheaders, ct, boundary);
        if (result != CURLE_OK)
            return result;
    }

    if (search_header(part.userheaders, "Content-Transfer-Encoding", 25) == null) {
        if (part.encoder) |enc| {
            encoding = enc.name;
        } else if (contenttype != null and strategy == MIMESTRATEGY_MAIL and part.kind != MIMEKIND_MULTIPART) {
            encoding = "8bit";
        }
        if (encoding) |enc_str| {
            result = mime_add_header_str(&part.curlheaders, curl_maprintf("Content-Transfer-Encoding: %s", enc_str));
            if (result != CURLE_OK)
                return result;
        }
    }

    if (part.state.state == MIMESTATE_CURL) {
        mimesetstate(&part.state, MIMESTATE_CURL, part.curlheaders);
    }

    part.flags &= ~MIME_FAST_CONV;
    if (part.lastreadstatus == 1 and part.kind == MIMEKIND_FILE and part.fp == null and part.encoder != null) {
        if (curl_strequal(part.encoder.?.name, "7bit") != 0 or
            curl_strequal(part.encoder.?.name, "8bit") != 0)
        {
            part.flags |= MIME_FAST_CONV;
        }
    }

    switch (part.kind) {
        MIMEKIND_MULTIPART => {
            part.datasize = multipart_size(@ptrCast(@alignCast(part.arg.?)));
        },
        MIMEKIND_FILE => {
            if ((part.flags & MIME_FAST_CONV) != 0)
                part.datasize = -1;
        },
        else => {},
    }

    if (strategy == MIMESTRATEGY_MAIL and content_type_match(contenttype, "message/rfc822", 14))
        state = MIMESTATE_BODY;

    if (part.state.state != MIMESTATE_BEGIN and part.state.state < state)
        mimesetstate(&part.state, state, null);

    return result;
}

pub export fn Curl_mime_prepare_headers(
    data: ?*anyopaque,
    part: *curl_mimepart,
    contenttype: ?[*:0]const u8,
    disposition: ?[*:0]const u8,
    strategy: c_uint,
) callconv(.c) CURLcode {
    _ = data;
    return Curl_mime_prepare_headers_ex(false, part, contenttype, disposition, strategy);
}

// ============================================================================
// Client Reader `cr-mime` (`Curl_creader_set_mime`)
// ============================================================================

const CURL_CRCNTRL_REWIND: c_uint = 0;
const CURL_CRCNTRL_UNPAUSE: c_uint = 1;
const CURL_CRCNTRL_CLEAR_EOS: c_uint = 2;

const CURL_CR_CLIENT: c_uint = 4;

pub const Curl_crtype = extern struct {
    name: [*:0]const u8,
    do_init: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) CURLcode,
    do_read: *const fn (data: ?*anyopaque, reader: *Curl_creader, buf: [*]u8, blen: usize, nread: *usize, eos: *bool) callconv(.c) CURLcode,
    do_close: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) void,
    needs_rewind: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool,
    total_length: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) curl_off_t,
    resume_from: *const fn (data: ?*anyopaque, reader: *Curl_creader, offset: curl_off_t) callconv(.c) CURLcode,
    cntrl: *const fn (data: ?*anyopaque, reader: *Curl_creader, opcode: c_uint) callconv(.c) CURLcode,
    is_paused: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool,
    done: *const fn (data: ?*anyopaque, reader: *Curl_creader, premature: c_int) callconv(.c) void,
    creader_size: usize,
};

pub const Curl_creader = extern struct {
    crt: *const Curl_crtype,
    next: ?*Curl_creader,
    ctx: ?*anyopaque,
    phase: c_uint,
};

const cr_mime_ctx = extern struct {
    super: Curl_creader,
    part: *curl_mimepart,
    tempbuf: bufq,
    total_len: curl_off_t,
    read_status: CURLcode,
    seen_eos: bool,
    errored: bool,
};

extern fn Curl_creader_create(
    preader: *?*Curl_creader,
    data: ?*anyopaque,
    crt: *const Curl_crtype,
    phase: c_uint,
) callconv(.c) CURLcode;
extern fn Curl_creader_set(data: ?*anyopaque, r: *Curl_creader) callconv(.c) CURLcode;
extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_read(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_xfer_pause_send(data: ?*anyopaque, enable: bool) callconv(.c) CURLcode;

fn cr_mime_init(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) CURLcode {
    _ = data;
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(reader.ctx.?));
    io_buffers.Curl_bufq_init2(&ctx.tempbuf, 1024, 1, io_buffers.BUFQ_OPT_NO_SPARES);
    return CURLE_OK;
}

fn cr_mime_close(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) void {
    _ = data;
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(reader.ctx.?));
    io_buffers.Curl_bufq_free(&ctx.tempbuf);
}

const cr_mime_slurp_ctx = struct {
    data: ?*anyopaque,
    reader: *Curl_creader,
};

fn cr_mime_read_cb(reader_ctx: ?*anyopaque, buf: [*]u8, blen: usize, pnread: *usize) callconv(.c) CURLcode {
    const sctx: *cr_mime_slurp_ctx = @ptrCast(@alignCast(reader_ctx.?));
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(sctx.reader.ctx.?));
    const data = sctx.data;
    pnread.* = 0;

    const nread = Curl_mime_read(buf, 1, blen, ctx.part);
    Curl_trc_read(data, "cr_mime_read(len=%zu) -> %zd", blen, nread);
    switch (nread) {
        0 => {
            ctx.seen_eos = true;
            return CURLE_OK;
        },
        CURL_READFUNC_ABORT => {
            Curl_failf(data, "operation aborted by callback");
            ctx.errored = true;
            return CURLE_ABORTED_BY_CALLBACK;
        },
        CURL_READFUNC_PAUSE => {
            Curl_trc_read(data, "cr_mime_read, paused by callback");
            ctx.read_status = Curl_xfer_pause_send(data, true);
            return CURLE_OK;
        },
        READ_ERROR => {
            var errbuf: [256]u8 = undefined;
            const err = getErrno();
            if ((ctx.part.flags & MIME_FILE_TRIED) != 0 and err != 0) {
                Curl_failf(
                    data,
                    "Pause/read of file failed: %s",
                    curlx_strerror(err, &errbuf, errbuf.len),
                );
            }
            ctx.errored = true;
            return CURLE_READ_ERROR;
        },
        else => {
            pnread.* = nread;
            return CURLE_OK;
        },
    }
}

fn cr_mime_read(
    data: ?*anyopaque,
    reader: *Curl_creader,
    buf: [*]u8,
    blen: usize,
    nread: *usize,
    eos: *bool,
) callconv(.c) CURLcode {
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(reader.ctx.?));
    nread.* = 0;
    eos.* = false;

    if (ctx.errored)
        return CURLE_READ_ERROR;
    if (ctx.seen_eos and io_buffers.Curl_bufq_is_empty(&ctx.tempbuf)) {
        eos.* = true;
        return CURLE_OK;
    }
    if (ctx.read_status != CURLE_OK)
        return ctx.read_status;

    if (!io_buffers.Curl_bufq_is_empty(&ctx.tempbuf) or blen <= 4) {
        if (io_buffers.Curl_bufq_is_empty(&ctx.tempbuf)) {
            var sctx: cr_mime_slurp_ctx = .{ .data = data, .reader = reader };
            var n: usize = 0;
            const result = io_buffers.Curl_bufq_slurp(&ctx.tempbuf, cr_mime_read_cb, &sctx, &n);
            if (result != CURLE_OK)
                return result;
        }
        const result = io_buffers.Curl_bufq_cread(&ctx.tempbuf, buf, blen, nread);
        if (result != CURLE_OK and result != CURLE_AGAIN)
            return result;
    } else {
        var sctx: cr_mime_slurp_ctx = .{ .data = data, .reader = reader };
        const result = cr_mime_read_cb(&sctx, buf, blen, nread);
        if (result != CURLE_OK)
            return result;
    }

    Curl_trc_read(data, "cr_mime_read(len=%zu, total=%" ++ "lld" ++ ") -> %d, %zu, %d", blen, ctx.total_len, @as(c_int, 0), nread.*, @as(c_int, @intFromBool(ctx.seen_eos)));

    if (ctx.seen_eos and io_buffers.Curl_bufq_is_empty(&ctx.tempbuf))
        eos.* = true;
    if (nread.* > 0 and ctx.total_len >= 0) {
        if (@as(curl_off_t, @intCast(nread.*)) <= ctx.total_len) {
            ctx.total_len -= @intCast(nread.*);
        } else {
            ctx.total_len = 0;
        }
        if (ctx.total_len == 0)
            eos.* = true;
    }
    return ctx.read_status;
}

fn cr_mime_needs_rewind(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool {
    _ = data;
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(reader.ctx.?));
    return ctx.part.state.state != MIMESTATE_BEGIN;
}

fn cr_mime_total_length(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) curl_off_t {
    _ = data;
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(reader.ctx.?));
    return ctx.total_len;
}

fn cr_mime_resume_from(data: ?*anyopaque, reader: *Curl_creader, offset: curl_off_t) callconv(.c) CURLcode {
    _ = data;
    _ = reader;
    _ = offset;
    return CURLE_READ_ERROR;
}

fn cr_mime_cntrl(data: ?*anyopaque, reader: *Curl_creader, opcode: c_uint) callconv(.c) CURLcode {
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(reader.ctx.?));
    switch (opcode) {
        CURL_CRCNTRL_REWIND => {
            const res = mime_part_rewind(ctx.part);
            if (res != CURL_SEEKFUNC_OK) {
                Curl_failf(data, "Cannot rewind mime/post data");
                return CURLE_SEND_FAIL_REWIND;
            }
            ctx.seen_eos = false;
            ctx.errored = false;
            io_buffers.Curl_bufq_reset(&ctx.tempbuf);
            ctx.total_len = mime_size(ctx.part);
            return CURLE_OK;
        },
        CURL_CRCNTRL_UNPAUSE => {
            return CURLE_OK;
        },
        CURL_CRCNTRL_CLEAR_EOS => {
            ctx.seen_eos = false;
            return CURLE_OK;
        },
        else => return CURLE_READ_ERROR,
    }
}

fn cr_mime_is_paused(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool {
    _ = data;
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(reader.ctx.?));
    return ctx.read_status == CURLE_AGAIN;
}

fn cr_mime_done(data: ?*anyopaque, reader: *Curl_creader, premature: c_int) callconv(.c) void {
    _ = data;
    _ = reader;
    _ = premature;
}

const cr_mime: Curl_crtype = .{
    .name = "cr-mime",
    .do_init = cr_mime_init,
    .do_read = cr_mime_read,
    .do_close = cr_mime_close,
    .needs_rewind = cr_mime_needs_rewind,
    .total_length = cr_mime_total_length,
    .resume_from = cr_mime_resume_from,
    .cntrl = cr_mime_cntrl,
    .is_paused = cr_mime_is_paused,
    .done = cr_mime_done,
    .creader_size = @sizeOf(cr_mime_ctx),
};

pub export fn Curl_creader_set_mime(data: ?*anyopaque, part: *curl_mimepart) callconv(.c) CURLcode {
    var r: ?*Curl_creader = null;
    var result = Curl_creader_create(&r, data, &cr_mime, CURL_CR_CLIENT);
    if (result != CURLE_OK)
        return result;
    const ctx: *cr_mime_ctx = @ptrCast(@alignCast(r.?.ctx.?));
    if (part.state.state == MIMESTATE_BEGIN and (part.flags & MIME_BODY_ONLY) != 0)
        mimesetstate(&part.state, MIMESTATE_BODY, null);
    ctx.part = part;
    ctx.total_len = mime_size(ctx.part);

    result = Curl_creader_set(data, r.?);
    return result;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_get_scheme and Curl_getn_scheme" {
    const http = Curl_get_scheme("http") orelse return error.SchemeNotFound;
    try std.testing.expectEqualStrings("http", std.mem.span(http.name));
    try std.testing.expectEqual(PORT_HTTP, http.defport);
    try std.testing.expectEqual(CURLPROTO_HTTP, http.protocol);
    try std.testing.expect(http.run != null);

    const https_upper = Curl_getn_scheme("HTTPS", 5) orelse return error.SchemeNotFound;
    try std.testing.expectEqualStrings("https", std.mem.span(https_upper.name));
    try std.testing.expectEqual(PORT_HTTPS, https_upper.defport);
    try std.testing.expectEqual(CURLPROTO_HTTPS, https_upper.protocol);

    const ws = Curl_getn_scheme("ws", 2) orelse return error.SchemeNotFound;
    try std.testing.expectEqualStrings("ws", std.mem.span(ws.name));

    const gophers = Curl_getn_scheme("gophers", 7) orelse return error.SchemeNotFound;
    try std.testing.expectEqualStrings("gophers", std.mem.span(gophers.name));

    try std.testing.expect(Curl_get_scheme("unknown") == null);
    try std.testing.expect(Curl_getn_scheme("h", 1) == null);
    try std.testing.expect(Curl_getn_scheme("toolongscheme", 13) == null);
}

test "curl_version and curl_version_info" {
    const ver_str = std.mem.span(curl_version());
    try std.testing.expect(std.mem.startsWith(u8, ver_str, "libcurl/" ++ LIBCURL_VERSION));

    const info = curl_version_info(CURLVERSION_NOW);
    try std.testing.expectEqual(LIBCURL_VERSION_NUM, info.version_num);
    try std.testing.expectEqualStrings(LIBCURL_VERSION, std.mem.span(info.version.?));
    try std.testing.expect((info.features & CURL_VERSION_IPV6) != 0);
    try std.testing.expect((info.features & CURL_VERSION_LARGEFILE) != 0);
}

test "curl_mime_init, curl_mime_addpart, curl_mime_name, curl_mime_data, Curl_mime_read, curl_mime_free" {
    const mime = curl_mime_init(null) orelse return error.MimeInitFailed;
    defer curl_mime_free(mime);

    const part = curl_mime_addpart(mime) orelse return error.MimeAddpartFailed;
    try std.testing.expectEqual(CURLE_OK, curl_mime_name(part, "field1"));
    try std.testing.expectEqual(CURLE_OK, curl_mime_data(part, "hello world", CURL_ZERO_TERMINATED));
    try std.testing.expectEqual(CURLE_OK, curl_mime_type(part, "text/plain"));

    var top: curl_mimepart = undefined;
    Curl_mime_initpart(&top);
    defer {
        _ = Curl_mime_set_subparts(&top, null, false);
        Curl_mime_cleanpart(&top);
    }
    try std.testing.expectEqual(CURLE_OK, Curl_mime_set_subparts(&top, mime, false));
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_mime_prepare_headers_ex(false, &top, "multipart/form-data", null, MIMESTRATEGY_FORM),
    );

    var out: [512]u8 = undefined;
    var total: usize = 0;
    while (true) {
        const n = Curl_mime_read(out[total..].ptr, 1, out.len - total, &top);
        if (n == 0) break;
        try std.testing.expect(n != READ_ERROR);
        total += n;
    }

    const rendered = out[0..total];
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Content-Disposition: form-data; name=\"field1\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "Content-Type: text/plain") != null);
    try std.testing.expect(std.mem.indexOf(u8, rendered, "hello world") != null);
}

// ============================================================================
// C-Zig ABI & Struct Layout Verification
// ============================================================================

pub const Curl_protocol = small_protocols.Curl_protocol;

comptime {
    std.debug.assert(@sizeOf(Curl_scheme) == 40);
    std.debug.assert(@alignOf(Curl_scheme) == 8);
    std.debug.assert(@offsetOf(Curl_scheme, "name") == 0);
    std.debug.assert(@offsetOf(Curl_scheme, "run") == 8);
    std.debug.assert(@offsetOf(Curl_scheme, "protocol") == 16);
    std.debug.assert(@offsetOf(Curl_scheme, "family") == 24);
    std.debug.assert(@offsetOf(Curl_scheme, "flags") == 32);
    std.debug.assert(@offsetOf(Curl_scheme, "defport") == 36);

    std.debug.assert(@sizeOf(Curl_protocol) == 136);
    std.debug.assert(@alignOf(Curl_protocol) == 8);
    std.debug.assert(@offsetOf(Curl_protocol, "setup_connection") == 0);
    std.debug.assert(@offsetOf(Curl_protocol, "do_it") == 8);
    std.debug.assert(@offsetOf(Curl_protocol, "done") == 16);
    std.debug.assert(@offsetOf(Curl_protocol, "do_more") == 24);
    std.debug.assert(@offsetOf(Curl_protocol, "connect_it") == 32);
    std.debug.assert(@offsetOf(Curl_protocol, "connecting") == 40);
    std.debug.assert(@offsetOf(Curl_protocol, "doing") == 48);
    std.debug.assert(@offsetOf(Curl_protocol, "proto_pollset") == 56);
    std.debug.assert(@offsetOf(Curl_protocol, "doing_pollset") == 64);
    std.debug.assert(@offsetOf(Curl_protocol, "domore_pollset") == 72);
    std.debug.assert(@offsetOf(Curl_protocol, "perform_pollset") == 80);
    std.debug.assert(@offsetOf(Curl_protocol, "disconnect") == 88);
    std.debug.assert(@offsetOf(Curl_protocol, "write_resp") == 96);
    std.debug.assert(@offsetOf(Curl_protocol, "write_resp_hd") == 104);
    std.debug.assert(@offsetOf(Curl_protocol, "connection_is_dead") == 112);
    std.debug.assert(@offsetOf(Curl_protocol, "attach") == 120);
    std.debug.assert(@offsetOf(Curl_protocol, "follow") == 128);

    std.debug.assert(@sizeOf(Curl_crtype) == 88);
    std.debug.assert(@alignOf(Curl_crtype) == 8);
    std.debug.assert(@offsetOf(Curl_crtype, "name") == 0);
    std.debug.assert(@offsetOf(Curl_crtype, "do_init") == 8);
    std.debug.assert(@offsetOf(Curl_crtype, "do_read") == 16);
    std.debug.assert(@offsetOf(Curl_crtype, "do_close") == 24);
    std.debug.assert(@offsetOf(Curl_crtype, "needs_rewind") == 32);
    std.debug.assert(@offsetOf(Curl_crtype, "total_length") == 40);
    std.debug.assert(@offsetOf(Curl_crtype, "resume_from") == 48);
    std.debug.assert(@offsetOf(Curl_crtype, "cntrl") == 56);
    std.debug.assert(@offsetOf(Curl_crtype, "is_paused") == 64);
    std.debug.assert(@offsetOf(Curl_crtype, "done") == 72);
    std.debug.assert(@offsetOf(Curl_crtype, "creader_size") == 80);

    std.debug.assert(@sizeOf(Curl_creader) == 32);
    std.debug.assert(@alignOf(Curl_creader) == 8);
    std.debug.assert(@offsetOf(Curl_creader, "crt") == 0);
    std.debug.assert(@offsetOf(Curl_creader, "next") == 8);
    std.debug.assert(@offsetOf(Curl_creader, "ctx") == 16);
    std.debug.assert(@offsetOf(Curl_creader, "phase") == 24);

    std.debug.assert(@sizeOf(mime_encoder) == 24);
    std.debug.assert(@offsetOf(mime_encoder, "name") == 0);
    std.debug.assert(@offsetOf(mime_encoder, "encodefunc") == 8);
    std.debug.assert(@offsetOf(mime_encoder, "sizefunc") == 16);

    std.debug.assert(@sizeOf(mime_encoder_state) == 280);
    std.debug.assert(@offsetOf(mime_encoder_state, "pos") == 0);
    std.debug.assert(@offsetOf(mime_encoder_state, "bufbeg") == 8);
    std.debug.assert(@offsetOf(mime_encoder_state, "bufend") == 16);
    std.debug.assert(@offsetOf(mime_encoder_state, "buf") == 24);

    std.debug.assert(@sizeOf(mime_state) == 24);
    std.debug.assert(@offsetOf(mime_state, "state") == 0);
    std.debug.assert(@offsetOf(mime_state, "ptr") == 8);
    std.debug.assert(@offsetOf(mime_state, "offset") == 16);

    std.debug.assert(@sizeOf(curl_mime) == 96);
    std.debug.assert(@alignOf(curl_mime) == 8);
    std.debug.assert(@offsetOf(curl_mime, "parent") == 0);
    std.debug.assert(@offsetOf(curl_mime, "firstpart") == 8);
    std.debug.assert(@offsetOf(curl_mime, "lastpart") == 16);
    std.debug.assert(@offsetOf(curl_mime, "boundary") == 24);
    std.debug.assert(@offsetOf(curl_mime, "state") == 72);

    std.debug.assert(@sizeOf(curl_mimepart) == 440);
    std.debug.assert(@alignOf(curl_mimepart) == 8);
    std.debug.assert(@offsetOf(curl_mimepart, "parent") == 0);
    std.debug.assert(@offsetOf(curl_mimepart, "nextpart") == 8);
    std.debug.assert(@offsetOf(curl_mimepart, "kind") == 16);
    std.debug.assert(@offsetOf(curl_mimepart, "flags") == 20);
    std.debug.assert(@offsetOf(curl_mimepart, "data") == 24);
    std.debug.assert(@offsetOf(curl_mimepart, "readfunc") == 32);
    std.debug.assert(@offsetOf(curl_mimepart, "seekfunc") == 40);
    std.debug.assert(@offsetOf(curl_mimepart, "freefunc") == 48);
    std.debug.assert(@offsetOf(curl_mimepart, "arg") == 56);
    std.debug.assert(@offsetOf(curl_mimepart, "fp") == 64);
    std.debug.assert(@offsetOf(curl_mimepart, "curlheaders") == 72);
    std.debug.assert(@offsetOf(curl_mimepart, "userheaders") == 80);
    std.debug.assert(@offsetOf(curl_mimepart, "mimetype") == 88);
    std.debug.assert(@offsetOf(curl_mimepart, "filename") == 96);
    std.debug.assert(@offsetOf(curl_mimepart, "name") == 104);
    std.debug.assert(@offsetOf(curl_mimepart, "datasize") == 112);
    std.debug.assert(@offsetOf(curl_mimepart, "state") == 120);
    std.debug.assert(@offsetOf(curl_mimepart, "encoder") == 144);
    std.debug.assert(@offsetOf(curl_mimepart, "encstate") == 152);
    std.debug.assert(@offsetOf(curl_mimepart, "lastreadstatus") == 432);
}

extern fn Curl_zig_abi_sizeof_scheme() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_protocol() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_crtype() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_creader() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_mime() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_mimepart() callconv(.c) usize;

test "C-Zig ABI struct sizes in protocol_version_mime" {
    try std.testing.expectEqual(@sizeOf(Curl_scheme), Curl_zig_abi_sizeof_scheme());
    try std.testing.expectEqual(@sizeOf(Curl_protocol), Curl_zig_abi_sizeof_protocol());
    try std.testing.expectEqual(@sizeOf(Curl_crtype), Curl_zig_abi_sizeof_crtype());
    try std.testing.expectEqual(@sizeOf(Curl_creader), Curl_zig_abi_sizeof_creader());
    try std.testing.expectEqual(@sizeOf(curl_mime), Curl_zig_abi_sizeof_mime());
    try std.testing.expectEqual(@sizeOf(curl_mimepart), Curl_zig_abi_sizeof_mimepart());
}
