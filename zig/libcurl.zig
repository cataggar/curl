const std = @import("std");

pub const Options = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.builtin.LinkMode = .static,
    config_header: ?*std.Build.Step.ConfigHeader = null,
};

pub const c_flags = [_][]const u8{
    "-std=gnu11",
    "-fno-sanitize=undefined",
    "-Wno-unused-parameter",
};

pub const c_sources = [_][]const u8{
    // LIB_CFILES
    "lib/altsvc.c",
    "lib/api.c",
    "lib/cf-h1-proxy.c",
    "lib/cf-h2-proxy.c",
    "lib/cf-haproxy.c",
    "lib/cf-https-connect.c",
    "lib/cf-ip-happy.c",
    "lib/cf-recvbuf.c",
    "lib/cf-setup.c",
    "lib/cf-socket.c",
    "lib/cfilters.c",
    "lib/conncache.c",
    "lib/connect.c",
    "lib/content_encoding.c",
    "lib/cookie.c",
    "lib/cshutdn.c",
    "lib/curl_gssapi.c",
    "lib/curl_range.c",
    "lib/curl_sasl.c",
    "lib/curl_share.c",
    "lib/curl_sspi.c",
    "lib/curl_trc.c",
    "lib/cw-out.c",
    "lib/cw-pause.c",
    "lib/dict.c",
    "lib/easy.c",
    "lib/file.c",
    "lib/ftp.c",
    "lib/ftplistparser.c",
    "lib/getinfo.c",
    "lib/gopher.c",
    "lib/headers.c",
    "lib/hsts.c",
    "lib/http.c",
    "lib/http2.c",
    "lib/http_aws_sigv4.c",
    "lib/http_httpsig.c",
    "lib/http_chunks.c",
    "lib/http_digest.c",
    "lib/http_negotiate.c",
    "lib/http_ntlm.c",
    "lib/http_proxy.c",
    "lib/imap.c",
    "lib/ldap.c",
    "lib/mime.c",
    "lib/mqtt.c",
    "lib/multi.c",
    "lib/multi_ev.c",
    "lib/multi_ntfy.c",
    "lib/openldap.c",
    "lib/peer.c",
    "lib/pingpong.c",
    "lib/pop3.c",
    "lib/progress.c",
    "lib/protocol.c",
    "lib/proxy.c",
    "lib/request.c",
    "lib/rtsp.c",
    "lib/sendf.c",
    "lib/setopt.c",
    "lib/smtp.c",
    "lib/socks.c",
    "lib/socks_gssapi.c",
    "lib/socks_sspi.c",
    "lib/telnet.c",
    "lib/tftp.c",
    "lib/transfer.c",
    "lib/url.c",
    "lib/version.c",
    "lib/ws.c",
    // LIB_VAUTH_CFILES
    "lib/vauth/digest.c",
    "lib/vauth/digest_sspi.c",
    "lib/vauth/krb5_gssapi.c",
    "lib/vauth/krb5_sspi.c",
    "lib/vauth/ntlm_sspi.c",
    "lib/vauth/spnego_gssapi.c",
    "lib/vauth/spnego_sspi.c",
    "lib/vauth/vauth.c",
    // LIB_VDNS_CFILES
    "lib/vdns/asyn-ares.c",
    "lib/vdns/asyn-base.c",
    "lib/vdns/asyn-thrdd.c",
    "lib/vdns/cf-dns.c",
    "lib/vdns/dnscache.c",
    "lib/vdns/doh.c",
    "lib/vdns/hostip.c",
    "lib/vdns/hostip4.c",
    "lib/vdns/hostip6.c",
    "lib/vdns/httpsrr.c",
    // LIB_VTLS_CFILES
    "lib/vtls/gtls.c",
    "lib/vtls/mbedtls.c",
    "lib/vtls/openssl.c",
    "lib/vtls/rustls.c",
    "lib/vtls/schannel.c",
    "lib/vtls/vtls.c",
    "lib/vtls/vtls_config.c",
    "lib/vtls/vtls_scache.c",
    "lib/vtls/wolfssl.c",
    "lib/vtls/x509asn1.c",
    // LIB_VQUIC_CFILES
    "lib/vquic/cf-capsule.c",
    "lib/vquic/cf-ngtcp2.c",
    "lib/vquic/cf-ngtcp2-cmn.c",
    "lib/vquic/cf-ngtcp2-proxy.c",
    "lib/vquic/cf-quiche.c",
    "lib/vquic/vquic.c",
    "lib/vquic/vquic-tls.c",
    // LIB_VSSH_CFILES
    "lib/vssh/libssh.c",
    "lib/vssh/libssh2.c",
    "lib/vssh/vssh.c",
};

pub fn createConfigHeader(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Step.ConfigHeader {
    const t = target.result;
    const os_tag = t.os.tag;
    const abi = t.abi;
    const ptr_bytes: i64 = @divExact(@as(i64, t.ptrBitWidth()), 8);
    const is_windows = os_tag == .windows;
    const long_bytes: i64 = if (is_windows or ptr_bytes == 4) 4 else 8;
    const socket_bytes: i64 = if (is_windows and ptr_bytes == 8) 8 else 4;
    const off_t_bytes: i64 = if (is_windows and abi == .msvc) 4 else 8;
    const os_str = b.fmt("{s}-{s}-{s}", .{ @tagName(t.cpu.arch), @tagName(os_tag), @tagName(abi) });

    const ch = b.addConfigHeader(.{
        .style = .blank,
        .include_path = "curl_config.h",
    }, .{
        .CURL_OS = os_str,
        .CURL_DISABLE_LDAP = 1,
        .CURL_DISABLE_LDAPS = 1,
        .USE_IPV6 = 1,
        .USE_UNIX_SOCKETS = 1,
        .USE_RESOLV_THREADED = 1,
        .SIZEOF_INT = 4,
        .SIZEOF_LONG = long_bytes,
        .SIZEOF_OFF_T = off_t_bytes,
        .SIZEOF_CURL_OFF_T = 8,
        .SIZEOF_CURL_SOCKET_T = socket_bytes,
        .SIZEOF_SIZE_T = ptr_bytes,
        .SIZEOF_TIME_T = 8,
    });

    if (is_windows) {
        ch.addValues(.{
            .HAVE_CLOSESOCKET = 1,
            .HAVE_IOCTLSOCKET = 1,
            .HAVE_IOCTLSOCKET_FIONBIO = 1,
            .HAVE_GETADDRINFO = 1,
            .HAVE_FREEADDRINFO = 1,
            .HAVE_GETADDRINFO_THREADSAFE = 1,
            .HAVE_GETHOSTNAME = 1,
            .HAVE_GETPEERNAME = 1,
            .HAVE_GETSOCKNAME = 1,
            .HAVE_SOCKET = 1,
            .HAVE_RECV = 1,
            .HAVE_SEND = 1,
            .HAVE_SIGNAL = 1,
            .HAVE_SETLOCALE = 1,
            .HAVE_UTIME = 1,
            .HAVE_FCNTL_H = 1,
            .HAVE_IO_H = 1,
            .HAVE_LOCALE_H = 1,
            .HAVE_STDBOOL_H = 1,
            .HAVE_BOOL_T = 1,
            .HAVE_STDATOMIC_H = 1,
            .HAVE_ATOMIC = 1,
            .HAVE_SYS_TYPES_H = 1,
            .HAVE_SYS_UTIME_H = 1,
            .HAVE_STRUCT_SOCKADDR_STORAGE = 1,
            .HAVE_STRUCT_TIMEVAL = 1,
            .HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID = 1,
            .USE_WIN32_CRYPTO = 1,
        });
        if (abi != .msvc) {
            ch.addValues(.{
                .HAVE_UNISTD_H = 1,
                .HAVE_UTIME_H = 1,
                .HAVE_STRINGS_H = 1,
                .HAVE_SYS_PARAM_H = 1,
                .HAVE_LIBGEN_H = 1,
                .HAVE_BASENAME = 1,
                ._FILE_OFFSET_BITS = 64,
            });
        } else {
            ch.addIdent("ssize_t", if (ptr_bytes == 8) "__int64" else "int");
        }
    } else {
        ch.addValues(.{
            .HAVE_THREADS_POSIX = 1,
            .HAVE_SOCKET = 1,
            .HAVE_SOCKETPAIR = 1,
            .HAVE_SELECT = 1,
            .HAVE_POLL = 1,
            .HAVE_POLL_H = 1,
            .HAVE_FCNTL = 1,
            .HAVE_FCNTL_H = 1,
            .HAVE_FCNTL_O_NONBLOCK = 1,
            .HAVE_GETADDRINFO = 1,
            .HAVE_GETADDRINFO_THREADSAFE = 1,
            .HAVE_FREEADDRINFO = 1,
            .HAVE_ARPA_INET_H = 1,
            .HAVE_NETDB_H = 1,
            .HAVE_NETINET_IN_H = 1,
            .HAVE_NETINET_TCP_H = 1,
            .HAVE_NETINET_UDP_H = 1,
            .HAVE_NET_IF_H = 1,
            .HAVE_IFADDRS_H = 1,
            .HAVE_GETIFADDRS = 1,
            .HAVE_IF_NAMETOINDEX = 1,
            .HAVE_SYS_IOCTL_H = 1,
            .HAVE_SYS_PARAM_H = 1,
            .HAVE_SYS_POLL_H = 1,
            .HAVE_SYS_RESOURCE_H = 1,
            .HAVE_SYS_SELECT_H = 1,
            .HAVE_SYS_SOCKET_H = 1,
            .HAVE_SYS_STAT_H = 1,
            .HAVE_SYS_TIME_H = 1,
            .HAVE_SYS_TYPES_H = 1,
            .HAVE_SYS_UN_H = 1,
            .HAVE_UNISTD_H = 1,
            .HAVE_UTIME_H = 1,
            .HAVE_DIRENT_H = 1,
            .HAVE_OPENDIR = 1,
            .HAVE_LOCALE_H = 1,
            .HAVE_SETLOCALE = 1,
            .HAVE_PWD_H = 1,
            .HAVE_GETPWUID = 1,
            .HAVE_GETPWUID_R = 1,
            .HAVE_GETEUID = 1,
            .HAVE_GETPPID = 1,
            .HAVE_GMTIME_R = 1,
            .HAVE_LOCALTIME_R = 1,
            .HAVE_GETTIMEOFDAY = 1,
            .HAVE_CLOCK_GETTIME_MONOTONIC = 1,
            .HAVE_STRUCT_TIMEVAL = 1,
            .HAVE_STRUCT_SOCKADDR_STORAGE = 1,
            .HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID = 1,
            .HAVE_SA_FAMILY_T = 1,
            .HAVE_RECV = 1,
            .HAVE_SEND = 1,
            .HAVE_SENDMSG = 1,
            .HAVE_PIPE = 1,
            .HAVE_FNMATCH = 1,
            .HAVE_BASENAME = 1,
            .HAVE_LIBGEN_H = 1,
            .HAVE_SIGNAL = 1,
            .HAVE_SIGACTION = 1,
            .HAVE_SIGSETJMP = 1,
            .HAVE_STRCASECMP = 1,
            .HAVE_STRINGS_H = 1,
            .HAVE_STRERROR_R = 1,
            .HAVE_FSEEKO = 1,
            .HAVE_DECL_FSEEKO = 1,
            .HAVE_FCHMOD = 1,
            .HAVE_UTIME = 1,
            .HAVE_UTIMES = 1,
            .HAVE_REALPATH = 1,
            .HAVE_SCHED_YIELD = 1,
            .HAVE_GETHOSTNAME = 1,
            .HAVE_GETPEERNAME = 1,
            .HAVE_GETSOCKNAME = 1,
            .HAVE_GETRLIMIT = 1,
            .HAVE_SETRLIMIT = 1,
            .HAVE_STDATOMIC_H = 1,
            .HAVE_ATOMIC = 1,
            .HAVE_STDBOOL_H = 1,
            .HAVE_BOOL_T = 1,
            ._FILE_OFFSET_BITS = 64,
        });

        switch (os_tag) {
            .linux => {
                ch.addValues(.{
                    .HAVE_EVENTFD = 1,
                    .HAVE_SYS_EVENTFD_H = 1,
                    .HAVE_ACCEPT4 = 1,
                    .HAVE_PIPE2 = 1,
                    .HAVE_SENDMMSG = 1,
                    .HAVE_MEMRCHR = 1,
                    .HAVE_LINUX_TCP_H = 1,
                    .HAVE_TERMIO_H = 1,
                    .HAVE_TERMIOS_H = 1,
                    .HAVE_FSETXATTR = 1,
                    .HAVE_FSETXATTR_5 = 1,
                });
                if (abi.isGnu()) {
                    ch.addValues(.{ .HAVE_GLIBC_STRERROR_R = 1 });
                } else {
                    ch.addValues(.{ .HAVE_POSIX_STRERROR_R = 1 });
                }
            },
            .macos => {
                ch.addValues(.{
                    .HAVE_MACH_ABSOLUTE_TIME = 1,
                    .HAVE_TERMIOS_H = 1,
                    .HAVE_POSIX_STRERROR_R = 1,
                });
                if (b.graph.host.result.os.tag == .macos) {
                    ch.addValues(.{
                        .HAVE_FSETXATTR = 1,
                        .HAVE_FSETXATTR_6 = 1,
                    });
                }
            },
            else => {
                ch.addValues(.{
                    .HAVE_TERMIOS_H = 1,
                    .HAVE_POSIX_STRERROR_R = 1,
                });
            },
        }
    }

    return ch;
}

pub fn addLibcurl(b: *std.Build, options: Options) *std.Build.Step.Compile {
    const config_header = options.config_header orelse createConfigHeader(b, options.target);
    const os_tag = options.target.result.os.tag;

    const mod = b.createModule(.{
        .root_source_file = b.path("zig/port/root.zig"),
        .target = options.target,
        .optimize = options.optimize,
        .link_libc = true,
    });

    mod.addConfigHeader(config_header);
    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("lib"));

    mod.addCMacro("BUILDING_LIBCURL", "1");
    mod.addCMacro("HAVE_CONFIG_H", "1");
    if (options.linkage == .static) {
        mod.addCMacro("CURL_STATICLIB", "1");
    }

    switch (os_tag) {
        .linux => {
            mod.addCMacro("_GNU_SOURCE", "1");
            mod.linkSystemLibrary("pthread", .{});
        },
        .macos => {
            mod.linkSystemLibrary("pthread", .{});
            if (b.graph.host.result.os.tag == .macos) {
                mod.linkFramework("CoreFoundation", .{});
                mod.linkFramework("CoreServices", .{});
                mod.linkFramework("SystemConfiguration", .{});
            } else {
                const macos_stubs = b.addWriteFiles();
                _ = macos_stubs.add("SystemConfiguration/SCDynamicStoreCopySpecific.h",
                    \\#ifndef SCDYNAMICSTORECOPYSPECIFIC_H
                    \\#define SCDYNAMICSTORECOPYSPECIFIC_H
                    \\typedef const void *CFTypeRef;
                    \\typedef const struct __CFDictionary *CFDictionaryRef;
                    \\typedef const struct __SCDynamicStore *SCDynamicStoreRef;
                    \\static inline CFDictionaryRef SCDynamicStoreCopyProxies(SCDynamicStoreRef store) {
                    \\  (void)store;
                    \\  return (CFDictionaryRef)0;
                    \\}
                    \\static inline void CFRelease(CFTypeRef cf) {
                    \\  (void)cf;
                    \\}
                    \\#endif
                    \\
                );
                mod.addIncludePath(macos_stubs.getDirectory());
            }
        },
        .windows => {
            mod.addCMacro("WIN32_LEAN_AND_MEAN", "1");
            mod.addCMacro("_WIN32_WINNT", "0x0600");
            mod.linkSystemLibrary("ws2_32", .{});
            mod.linkSystemLibrary("iphlpapi", .{});
            mod.linkSystemLibrary("bcrypt", .{});
            mod.linkSystemLibrary("advapi32", .{});
            mod.linkSystemLibrary("crypt32", .{});
        },
        else => {
            mod.linkSystemLibrary("pthread", .{});
        },
    }

    mod.addCSourceFiles(.{
        .files = &c_sources,
        .flags = &c_flags,
    });

    const lib = b.addLibrary(.{
        .name = "curl",
        .linkage = options.linkage,
        .root_module = mod,
    });

    lib.installHeadersDirectory(b.path("include/curl"), "curl", .{});

    return lib;
}
