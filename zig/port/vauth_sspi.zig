const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const primitives = @import("primitives.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_AUTH_ERROR: CURLcode = 94;

pub const Curl_easy = opaque {};
pub const connectdata = opaque {};
pub const bufref = containers.bufref;
pub const dynbuf = containers.dynbuf;

extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?containers.BufrefDtor) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8;
extern fn Curl_bufref_len(br: *const bufref) callconv(.c) usize;
extern fn Curl_bufref_memdup0(br: *bufref, ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_len(s: *const dynbuf) callconv(.c) usize;
extern fn curlx_dyn_ptr(s: *const dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_base64_decode(src: [*:0]const u8, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_base64_encode(inputbuff: ?[*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;

fn bufrefFreeCallback(ptr: ?*anyopaque) callconv(.c) void {
    mem.free(ptr);
}

pub const Curl_creds = extern struct {
    user: [*:0]const u8,
    passwd: [*:0]const u8,
    oauth_bearer: [*:0]const u8,
    sasl_authzid: [*:0]const u8,
    sasl_service: [*:0]const u8,
    refcount: u32,
    source: u8,
    bufsize: usize,
    buf: [1]u8,
};

pub const Curl_peer = extern struct {
    scheme: ?*const anyopaque,
    hostname: [*:0]u8,
    zoneid: ?[*:0]u8,
    refcount: u32,
    scopeid: u32,
    port: u16,
    flags: c_uint, // bit 0: unix_socket, bit 1: abstract_uds, bit 2: ipv6
    user_hostname: [1]u8,
};

pub const Curl_meta_dtor = *const fn (key: ?*const anyopaque, key_len: usize, meta_data: ?*anyopaque) callconv(.c) void;

const c_ext = struct {
    extern fn Curl_peer_equal(p1: ?*Curl_peer, p2: ?*Curl_peer) callconv(.c) bool;
    extern fn Curl_conn_meta_get(conn: ?*connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn Curl_conn_meta_set(conn: ?*connectdata, key: [*:0]const u8, meta_data: ?*anyopaque, meta_dtor: ?Curl_meta_dtor) callconv(.c) CURLcode;
    extern fn Curl_conn_meta_remove(conn: ?*connectdata, key: [*:0]const u8) callconv(.c) void;
    extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
    extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
    extern fn Curl_sspi_strerror(err: i32, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
};

inline fn failf0(data: ?*Curl_easy, msg: [*:0]const u8) void {
    if (!builtin.is_test) {
        c_ext.Curl_failf(data, "%s", msg);
    }
}

inline fn failf1Str(data: ?*Curl_easy, fmt: [*:0]const u8, s: [*:0]const u8) void {
    if (!builtin.is_test) {
        c_ext.Curl_failf(data, fmt, s);
    }
}

inline fn infof0(data: ?*Curl_easy, msg: [*:0]const u8) void {
    if (!builtin.is_test) {
        c_ext.Curl_infof(data, "%s", msg);
    }
}

inline fn infof1Ulong(data: ?*Curl_easy, fmt: [*:0]const u8, val: c_ulong) void {
    if (!builtin.is_test) {
        c_ext.Curl_infof(data, fmt, val);
    }
}

inline fn credsHasUser(creds: ?*const Curl_creds) bool {
    const c = creds orelse return false;
    return c.user[0] != 0;
}

inline fn credsHasSaslService(creds: ?*const Curl_creds) bool {
    const c = creds orelse return false;
    return c.sasl_service[0] != 0;
}

inline fn credsSaslService(creds: ?*const Curl_creds) [*:0]const u8 {
    if (creds) |c| return c.sasl_service;
    return "";
}

inline fn uztoul(val: usize) c_ulong {
    return @intCast(val);
}

// ============================================================================
// Windows SSPI types and definitions (lib/curl_sspi.h)
// ============================================================================

pub const SECURITY_STATUS = i32; // LONG on Windows

pub const SEC_E_OK: SECURITY_STATUS = 0x00000000;
pub const SEC_I_CONTINUE_NEEDED: SECURITY_STATUS = 0x00090312;
pub const SEC_I_COMPLETE_NEEDED: SECURITY_STATUS = 0x00090313;
pub const SEC_I_COMPLETE_AND_CONTINUE: SECURITY_STATUS = 0x00090314;
pub const SEC_E_INSUFFICIENT_MEMORY: SECURITY_STATUS = @bitCast(@as(u32, 0x80090300));

pub const SEC_WINNT_AUTH_IDENTITY_VERSION: c_ulong = 0x200;
pub const SEC_WINNT_AUTH_IDENTITY_ANSI: c_ulong = 0x1;
pub const CURL_SEC_WINNT_AUTH_IDENTITY: c_ulong = SEC_WINNT_AUTH_IDENTITY_ANSI;

pub const SECPKG_CRED_OUTBOUND: c_ulong = 0x00000002;

pub const SECBUFFER_VERSION: c_ulong = 0;
pub const SECBUFFER_DATA: c_ulong = 1;
pub const SECBUFFER_TOKEN: c_ulong = 2;
pub const SECBUFFER_PADDING: c_ulong = 9;
pub const SECBUFFER_STREAM: c_ulong = 10;
pub const SECBUFFER_CHANNEL_BINDINGS: c_ulong = 14;

pub const SECURITY_NATIVE_DREP: c_ulong = 0x00000010;
pub const SECURITY_NETWORK_DREP: c_ulong = 0x00000000;

pub const SECPKG_ATTR_SIZES: c_ulong = 0;
pub const SECPKG_ATTR_ENDPOINT_BINDINGS: c_ulong = 26;

pub const ISC_REQ_DELEGATE: c_ulong = 0x00000001;
pub const ISC_REQ_MUTUAL_AUTH: c_ulong = 0x00000002;
pub const ISC_REQ_CONFIDENTIALITY: c_ulong = 0x00000010;

pub const KERB_WRAP_NO_ENCRYPT: c_ulong = 0x80000001;
pub const CURLGSSAPI_DELEGATION_FLAG: u8 = 1 << 1;
pub const STRERROR_LEN: usize = 256;

pub const SP_NAME_DIGEST: [*:0]const u8 = "WDigest";
pub const SP_NAME_NTLM: [*:0]const u8 = "NTLM";
pub const SP_NAME_NEGOTIATE: [*:0]const u8 = "Negotiate";
pub const SP_NAME_KERBEROS: [*:0]const u8 = "Kerberos";

pub inline fn gssError(status: SECURITY_STATUS) bool {
    return (@as(u32, @bitCast(status)) & 0x80000000) != 0;
}

pub const SecHandle = extern struct {
    dwLower: usize,
    dwUpper: usize,
};
pub const CredHandle = SecHandle;
pub const CtxtHandle = SecHandle;

pub const TimeStamp = extern struct {
    LowPart: u32,
    HighPart: i32,
};

pub const SecBuffer = extern struct {
    cbBuffer: c_ulong,
    BufferType: c_ulong,
    pvBuffer: ?*anyopaque,
};

pub const SecBufferDesc = extern struct {
    ulVersion: c_ulong,
    cBuffers: c_ulong,
    pBuffers: ?[*]SecBuffer,
};

pub const SecPkgInfoA = extern struct {
    fCapabilities: c_ulong,
    wVersion: c_ushort,
    wRPCID: c_ushort,
    cbMaxToken: c_ulong,
    Name: ?[*:0]u8,
    Comment: ?[*:0]u8,
};

pub const SecPkgContext_Sizes = extern struct {
    cbMaxToken: c_ulong,
    cbMaxSignature: c_ulong,
    cbBlockSize: c_ulong,
    cbSecurityTrailer: c_ulong,
};

pub const SecPkgContext_Bindings = extern struct {
    BindingsLength: c_ulong,
    Bindings: ?*anyopaque,
};

pub const SEC_WINNT_AUTH_IDENTITY_EXA = extern struct {
    Version: c_ulong,
    Length: c_ulong,
    User: ?[*]u8,
    UserLength: c_ulong,
    Domain: ?[*]u8,
    DomainLength: c_ulong,
    Password: ?[*]u8,
    PasswordLength: c_ulong,
    Flags: c_ulong,
    PackageList: ?[*]u8,
    PackageListLength: c_ulong,
};

const sspi_cc: std.builtin.CallingConvention = if (builtin.os.tag == .windows) .winapi else .c;

pub const SecurityFunctionTableA = extern struct {
    dwVersion: c_ulong,
    EnumerateSecurityPackagesA: ?*const anyopaque,
    QueryCredentialsAttributesA: ?*const anyopaque,
    AcquireCredentialsHandleA: *const fn (
        pszPrincipal: ?[*:0]u8,
        pszPackage: ?[*:0]u8,
        fCredentialUse: c_ulong,
        pvLogonId: ?*anyopaque,
        pAuthData: ?*anyopaque,
        pGetKeyFn: ?*const anyopaque,
        pvGetKeyArgument: ?*anyopaque,
        phCredential: ?*CredHandle,
        ptsExpiry: ?*TimeStamp,
    ) callconv(sspi_cc) SECURITY_STATUS,
    FreeCredentialsHandle: *const fn (phCredential: ?*CredHandle) callconv(sspi_cc) SECURITY_STATUS,
    Reserved2: ?*anyopaque,
    InitializeSecurityContextA: *const fn (
        phCredential: ?*CredHandle,
        phContext: ?*CtxtHandle,
        pszTargetName: ?[*:0]u8,
        fContextReq: c_ulong,
        Reserved1: c_ulong,
        TargetDataRep: c_ulong,
        pInput: ?*SecBufferDesc,
        Reserved2: c_ulong,
        phNewContext: ?*CtxtHandle,
        pOutput: ?*SecBufferDesc,
        pfContextAttr: *c_ulong,
        ptsExpiry: ?*TimeStamp,
    ) callconv(sspi_cc) SECURITY_STATUS,
    AcceptSecurityContext: ?*const anyopaque,
    CompleteAuthToken: *const fn (phContext: ?*CtxtHandle, pToken: ?*SecBufferDesc) callconv(sspi_cc) SECURITY_STATUS,
    DeleteSecurityContext: *const fn (phContext: ?*CtxtHandle) callconv(sspi_cc) SECURITY_STATUS,
    ApplyControlToken: ?*const anyopaque,
    QueryContextAttributesA: *const fn (phContext: ?*CtxtHandle, ulAttribute: c_ulong, pBuffer: ?*anyopaque) callconv(sspi_cc) SECURITY_STATUS,
    ImpersonateSecurityContext: ?*const anyopaque,
    RevertSecurityContext: ?*const anyopaque,
    MakeSignature: ?*const anyopaque,
    VerifySignature: ?*const anyopaque,
    FreeContextBuffer: *const fn (pvContextBuffer: ?*anyopaque) callconv(sspi_cc) SECURITY_STATUS,
    QuerySecurityPackageInfoA: *const fn (pszPackageName: ?[*:0]u8, ppPackageInfo: *?*SecPkgInfoA) callconv(sspi_cc) SECURITY_STATUS,
    Reserved3: ?*anyopaque,
    Reserved4: ?*anyopaque,
    ExportSecurityContext: ?*const anyopaque,
    ImportSecurityContextA: ?*const anyopaque,
    AddCredentialsA: ?*const anyopaque,
    Reserved8: ?*anyopaque,
    QuerySecurityContextToken: ?*const anyopaque,
    EncryptMessage: *const fn (phContext: ?*CtxtHandle, fQOP: c_ulong, pMessage: ?*SecBufferDesc, MessageSeqNo: c_ulong) callconv(sspi_cc) SECURITY_STATUS,
    DecryptMessage: *const fn (phContext: ?*CtxtHandle, pMessage: ?*SecBufferDesc, MessageSeqNo: c_ulong, pfQOP: ?*c_ulong) callconv(sspi_cc) SECURITY_STATUS,
    SetContextAttributesA: ?*const anyopaque,
};

// ============================================================================
// Auth state structs (lib/vauth/vauth.h)
// ============================================================================

pub const ntlmdata = if (builtin.os.tag == .windows) extern struct {
    sslContext: ?*CtxtHandle,
    credentials: ?*CredHandle,
    context: ?*CtxtHandle,
    identity: SEC_WINNT_AUTH_IDENTITY_EXA,
    p_identity: ?*SEC_WINNT_AUTH_IDENTITY_EXA,
    token_max: usize,
    output_token: ?[*]u8,
    input_token: ?[*]u8,
    input_token_len: usize,
    spn: ?[*:0]u8,
} else extern struct {
    flags: c_uint,
    nonce: [8]u8,
    target_info_len: c_uint,
    target_info: ?*anyopaque,
};

pub const kerberos5data = if (builtin.os.tag == .windows) extern struct {
    credentials: ?*CredHandle,
    context: ?*CtxtHandle,
    spn: ?[*:0]u8,
    identity: SEC_WINNT_AUTH_IDENTITY_EXA,
    p_identity: ?*SEC_WINNT_AUTH_IDENTITY_EXA,
    token_max: usize,
    output_token: ?[*]u8,
} else extern struct {
    context: ?*anyopaque,
    spn: ?*anyopaque,
};

pub const gss_buffer_desc = extern struct {
    length: usize = 0,
    value: ?*anyopaque = null,
};

pub const negotiatedata = if (builtin.os.tag == .windows) extern struct {
    sslContext: ?*CtxtHandle,
    status: SECURITY_STATUS,
    credentials: ?*CredHandle,
    context: ?*CtxtHandle,
    identity: SEC_WINNT_AUTH_IDENTITY_EXA,
    p_identity: ?*SEC_WINNT_AUTH_IDENTITY_EXA,
    spn: ?[*:0]u8,
    token_max: usize,
    output_token: ?[*]u8,
    output_token_length: usize,
    flags: c_uint, // bit0: noauthpersist, bit1: havenoauthpersist, bit2: havenegdata, bit3: havemultiplerequests
} else extern struct {
    status: u32,
    context: ?*anyopaque,
    spn: ?*anyopaque,
    cred: ?*anyopaque,
    output_token: gss_buffer_desc,
    channel_binding_data: dynbuf,
    flags: c_uint,
};

pub const CURL_META_NTLM_CONN: [*:0]const u8 = "meta:auth:ntml:conn";
pub const CURL_META_NTLM_PROXY_CONN: [*:0]const u8 = "meta:auth:ntml-proxy:conn";
pub const CURL_META_KRB5_CONN: [*:0]const u8 = "meta:auth:krb5:conn";
pub const CURL_META_NEGO_CONN: [*:0]const u8 = "meta:auth:nego:conn";
pub const CURL_META_NEGO_PROXY_CONN: [*:0]const u8 = "meta:auth:nego-proxy:conn";

// ============================================================================
// 1. lib/curl_sspi.c + lib/curl_sspi.h (Windows SSPI)
// ============================================================================

const secur32 = struct {
    extern "secur32" fn InitSecurityInterfaceA() callconv(.winapi) ?*SecurityFunctionTableA;
};

pub var Curl_pSecFn: ?*SecurityFunctionTableA = null;

comptime {
    if (builtin.os.tag == .windows) {
        @export(&Curl_pSecFn, .{ .name = "Curl_pSecFn" });
        @export(&sspiGlobalInit, .{ .name = "Curl_sspi_global_init" });
        @export(&sspiGlobalCleanup, .{ .name = "Curl_sspi_global_cleanup" });
        @export(&createSspiIdentity, .{ .name = "Curl_create_sspi_identity" });
        @export(&sspiFreeIdentity, .{ .name = "Curl_sspi_free_identity" });
    }
}

pub fn sspiGlobalInit() callconv(.c) CURLcode {
    if (builtin.os.tag == .windows) {
        if (Curl_pSecFn == null) {
            Curl_pSecFn = secur32.InitSecurityInterfaceA();
            if (Curl_pSecFn == null)
                return CURLE_FAILED_INIT;
        }
    }
    return CURLE_OK;
}

pub fn sspiGlobalCleanup() callconv(.c) void {
    if (Curl_pSecFn != null) {
        Curl_pSecFn = null;
    }
}

pub fn createSspiIdentity(
    userp: ?[*:0]const u8,
    passwdp: ?[*:0]const u8,
    identity: *SEC_WINNT_AUTH_IDENTITY_EXA,
) callconv(.c) CURLcode {
    @memset(std.mem.asBytes(identity), 0);
    identity.Version = SEC_WINNT_AUTH_IDENTITY_VERSION;
    identity.Length = @sizeOf(SEC_WINNT_AUTH_IDENTITY_EXA);

    const user_in: [*:0]const u8 = userp orelse return CURLE_OUT_OF_MEMORY;
    const passwd_in: [*:0]const u8 = passwdp orelse return CURLE_OUT_OF_MEMORY;

    const useranddomain = mem.strdup(user_in) orelse return CURLE_OUT_OF_MEMORY;
    const uad_slice = std.mem.span(useranddomain);

    var user_ptr: [*:0]const u8 = useranddomain;
    var domain_ptr: [*]const u8 = "";
    var domlen: usize = 0;

    const sep_idx = std.mem.indexOfScalar(u8, uad_slice, '\\') orelse
        std.mem.indexOfScalar(u8, uad_slice, '/');
    if (sep_idx) |idx| {
        domain_ptr = useranddomain;
        domlen = idx;
        user_ptr = useranddomain + idx + 1;
    }

    const dup_user = mem.strdup(user_ptr) orelse {
        mem.free(useranddomain);
        return CURLE_OUT_OF_MEMORY;
    };

    const dup_domain = mem.malloc(domlen + 1) orelse {
        mem.free(dup_user);
        mem.free(useranddomain);
        return CURLE_OUT_OF_MEMORY;
    };
    if (domlen > 0) {
        @memcpy(dup_domain[0..domlen], domain_ptr[0..domlen]);
    }
    dup_domain[domlen] = 0;

    mem.free(useranddomain);

    const passwd_dup = mem.strdup(passwd_in) orelse {
        mem.free(dup_user);
        mem.free(dup_domain);
        return CURLE_OUT_OF_MEMORY;
    };
    const pwlen = std.mem.span(passwd_dup).len;
    const dup_passwd = mem.strdup(passwd_dup) orelse {
        mem.free(dup_user);
        mem.free(dup_domain);
        std.crypto.secureZero(u8, passwd_dup[0..pwlen]);
        mem.free(passwd_dup);
        return CURLE_OUT_OF_MEMORY;
    };

    identity.Password = dup_passwd;
    identity.PasswordLength = uztoul(pwlen);

    std.crypto.secureZero(u8, passwd_dup[0..pwlen]);
    mem.free(passwd_dup);

    identity.User = dup_user;
    identity.UserLength = uztoul(std.mem.span(dup_user).len);
    identity.Domain = dup_domain;
    identity.DomainLength = uztoul(domlen);
    identity.Flags = CURL_SEC_WINNT_AUTH_IDENTITY;

    return CURLE_OK;
}

pub fn sspiFreeIdentity(identity: ?*SEC_WINNT_AUTH_IDENTITY_EXA) callconv(.c) void {
    const id = identity orelse return;
    if (id.User) |u| {
        mem.free(u);
        id.User = null;
    }
    if (id.Password) |p| {
        std.crypto.secureZero(u8, p[0..id.PasswordLength]);
        mem.free(p);
        id.Password = null;
    }
    if (id.Domain) |d| {
        mem.free(d);
        id.Domain = null;
    }
}

// ============================================================================
// 2. lib/vauth/ntlm_sspi.c (Windows SSPI NTLM)
// ============================================================================

comptime {
    if (builtin.os.tag == .windows) {
        @export(&authIsNtlmSupportedSspi, .{ .name = "Curl_auth_is_ntlm_supported" });
        @export(&authCreateNtlmType1MessageSspi, .{ .name = "Curl_auth_create_ntlm_type1_message" });
        @export(&authDecodeNtlmType2MessageSspi, .{ .name = "Curl_auth_decode_ntlm_type2_message" });
        @export(&authCreateNtlmType3MessageSspi, .{ .name = "Curl_auth_create_ntlm_type3_message" });
        @export(&authCleanupNtlmSspi, .{ .name = "Curl_auth_cleanup_ntlm" });
    }
}

pub fn authIsNtlmSupportedSspi() callconv(.c) bool {
    const sec_fn = Curl_pSecFn orelse return false;
    var security_package: ?*SecPkgInfoA = null;
    const status = sec_fn.QuerySecurityPackageInfoA(@constCast(SP_NAME_NTLM), &security_package);
    if (status == SEC_E_OK) {
        _ = sec_fn.FreeContextBuffer(security_package);
    }
    return status == SEC_E_OK;
}

pub fn authCreateNtlmType1MessageSspi(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    ntlm: *ntlmdata,
    out: *bufref,
) callconv(.c) CURLcode {
    if (builtin.os.tag != .windows) return CURLE_NOT_BUILT_IN;
    const sec_fn = Curl_pSecFn orelse return CURLE_AUTH_ERROR;
    var security_package: ?*SecPkgInfoA = null;
    var type_1_buf: SecBuffer = undefined;
    var type_1_desc: SecBufferDesc = undefined;
    var attrs: c_ulong = 0;
    const service: ?[*:0]const u8 = if (credsHasSaslService(creds)) credsSaslService(creds) else default_service;

    authCleanupNtlmSspi(ntlm);

    var status = sec_fn.QuerySecurityPackageInfoA(@constCast(SP_NAME_NTLM), &security_package);
    if (status != SEC_E_OK) {
        failf0(data, "SSPI: could not get auth info");
        return CURLE_AUTH_ERROR;
    }

    ntlm.token_max = security_package.?.cbMaxToken;
    _ = sec_fn.FreeContextBuffer(security_package);

    ntlm.output_token = mem.malloc(ntlm.token_max) orelse return CURLE_OUT_OF_MEMORY;

    if (credsHasUser(creds)) {
        const result = createSspiIdentity(creds.?.user, creds.?.passwd, &ntlm.identity);
        if (result != CURLE_OK)
            return result;
        ntlm.p_identity = &ntlm.identity;
    } else {
        ntlm.p_identity = null;
    }

    ntlm.credentials = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(CredHandle)) orelse return CURLE_OUT_OF_MEMORY));

    status = sec_fn.AcquireCredentialsHandleA(
        null,
        @constCast(SP_NAME_NTLM),
        SECPKG_CRED_OUTBOUND,
        null,
        ntlm.p_identity,
        null,
        null,
        ntlm.credentials,
        null,
    );
    if (status != SEC_E_OK) {
        mem.free(ntlm.credentials);
        ntlm.credentials = null;
        return CURLE_LOGIN_DENIED;
    }

    ntlm.context = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(CtxtHandle)) orelse return CURLE_OUT_OF_MEMORY));

    ntlm.spn = Curl_auth_build_spn(service, host, null) orelse return CURLE_OUT_OF_MEMORY;

    type_1_desc.ulVersion = SECBUFFER_VERSION;
    type_1_desc.cBuffers = 1;
    type_1_desc.pBuffers = @ptrCast(&type_1_buf);
    type_1_buf.BufferType = SECBUFFER_TOKEN;
    type_1_buf.pvBuffer = ntlm.output_token;
    type_1_buf.cbBuffer = uztoul(ntlm.token_max);

    status = sec_fn.InitializeSecurityContextA(
        ntlm.credentials,
        null,
        ntlm.spn,
        0,
        0,
        SECURITY_NETWORK_DREP,
        null,
        0,
        ntlm.context,
        &type_1_desc,
        &attrs,
        null,
    );
    if (status == SEC_I_COMPLETE_NEEDED or status == SEC_I_COMPLETE_AND_CONTINUE) {
        _ = sec_fn.CompleteAuthToken(ntlm.context, &type_1_desc);
    } else if (status == SEC_E_INSUFFICIENT_MEMORY) {
        return CURLE_OUT_OF_MEMORY;
    } else if (status != SEC_E_OK and status != SEC_I_CONTINUE_NEEDED) {
        return CURLE_AUTH_ERROR;
    }

    Curl_bufref_set(out, ntlm.output_token, type_1_buf.cbBuffer, null);
    return CURLE_OK;
}

pub fn authDecodeNtlmType2MessageSspi(
    data: ?*Curl_easy,
    type2ref: *const bufref,
    ntlm: *ntlmdata,
) callconv(.c) CURLcode {
    if (builtin.os.tag != .windows) return CURLE_NOT_BUILT_IN;
    const len = Curl_bufref_len(type2ref);
    if (len == 0) {
        infof0(data, "NTLM handshake failure (empty type-2 message)");
        return CURLE_BAD_CONTENT_ENCODING;
    }

    const ptr = Curl_bufref_ptr(type2ref);
    const dup_bytes = mem.malloc(len + 1) orelse return CURLE_OUT_OF_MEMORY;
    if (ptr) |p| {
        @memcpy(dup_bytes[0..len], p[0..len]);
    }
    dup_bytes[len] = 0;

    ntlm.input_token = dup_bytes;
    ntlm.input_token_len = len;
    return CURLE_OK;
}

pub fn authCreateNtlmType3MessageSspi(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    ntlm: *ntlmdata,
    out: *bufref,
) callconv(.c) CURLcode {
    if (builtin.os.tag != .windows) return CURLE_NOT_BUILT_IN;
    _ = creds;
    const sec_fn = Curl_pSecFn orelse return CURLE_AUTH_ERROR;
    var type_2_bufs: [2]SecBuffer = undefined;
    var type_3_buf: SecBuffer = undefined;
    var type_2_desc: SecBufferDesc = undefined;
    var type_3_desc: SecBufferDesc = undefined;
    var attrs: c_ulong = 0;
    var pkg_bindings = SecPkgContext_Bindings{ .BindingsLength = 0, .Bindings = null };

    type_2_desc.ulVersion = SECBUFFER_VERSION;
    type_2_desc.cBuffers = 1;
    type_2_desc.pBuffers = &type_2_bufs;
    type_2_bufs[0].BufferType = SECBUFFER_TOKEN;
    type_2_bufs[0].pvBuffer = ntlm.input_token;
    type_2_bufs[0].cbBuffer = uztoul(ntlm.input_token_len);

    if (ntlm.sslContext) |ssl_ctx| {
        const status = sec_fn.QueryContextAttributesA(
            ssl_ctx,
            SECPKG_ATTR_ENDPOINT_BINDINGS,
            &pkg_bindings,
        );
        if (status == SEC_E_OK) {
            type_2_desc.cBuffers += 1;
            type_2_bufs[1].BufferType = SECBUFFER_CHANNEL_BINDINGS;
            type_2_bufs[1].cbBuffer = pkg_bindings.BindingsLength;
            type_2_bufs[1].pvBuffer = pkg_bindings.Bindings;
        }
    }

    type_3_desc.ulVersion = SECBUFFER_VERSION;
    type_3_desc.cBuffers = 1;
    type_3_desc.pBuffers = @ptrCast(&type_3_buf);
    type_3_buf.BufferType = SECBUFFER_TOKEN;
    type_3_buf.pvBuffer = ntlm.output_token;
    type_3_buf.cbBuffer = uztoul(ntlm.token_max);

    const status = sec_fn.InitializeSecurityContextA(
        ntlm.credentials,
        ntlm.context,
        ntlm.spn,
        0,
        0,
        SECURITY_NETWORK_DREP,
        &type_2_desc,
        0,
        ntlm.context,
        &type_3_desc,
        &attrs,
        null,
    );

    if (pkg_bindings.Bindings) |b| {
        _ = sec_fn.FreeContextBuffer(b);
    }

    if (status != SEC_E_OK) {
        infof1Ulong(data, "NTLM handshake failure (type-3 message): Status=0x%08lx", @bitCast(status));
        if (status == SEC_E_INSUFFICIENT_MEMORY)
            return CURLE_OUT_OF_MEMORY;
        return CURLE_AUTH_ERROR;
    }

    const result = Curl_bufref_memdup0(out, ntlm.output_token, type_3_buf.cbBuffer);
    authCleanupNtlmSspi(ntlm);
    return result;
}

pub fn authCleanupNtlmSspi(ntlm: *ntlmdata) callconv(.c) void {
    if (builtin.os.tag != .windows) return;
    if (ntlm.context) |ctx| {
        if (Curl_pSecFn) |sec_fn| {
            _ = sec_fn.DeleteSecurityContext(ctx);
        }
        mem.free(ctx);
        ntlm.context = null;
    }
    if (ntlm.credentials) |cred| {
        if (Curl_pSecFn) |sec_fn| {
            _ = sec_fn.FreeCredentialsHandle(cred);
        }
        mem.free(cred);
        ntlm.credentials = null;
    }
    sspiFreeIdentity(ntlm.p_identity);
    ntlm.p_identity = null;

    if (ntlm.input_token) |tok| {
        mem.free(tok);
        ntlm.input_token = null;
    }
    if (ntlm.output_token) |tok| {
        mem.free(tok);
        ntlm.output_token = null;
    }
    ntlm.token_max = 0;

    if (ntlm.spn) |spn| {
        mem.free(spn);
        ntlm.spn = null;
    }
}

// ============================================================================
// 3 & 4. lib/vauth/krb5_gssapi.c & lib/vauth/krb5_sspi.c
// ============================================================================

const use_gssapi = false; // HAVE_GSSAPI is disabled in Zig build

pub const OM_uint32 = u32;
pub const gss_qop_t = u32;
pub const gss_cred_usage_t = c_int;
pub const gss_ctx_id_t = ?*anyopaque;
pub const gss_name_t = ?*anyopaque;
pub const gss_cred_id_t = ?*anyopaque;
pub const gss_OID_desc = extern struct {
    length: u32,
    elements: ?*anyopaque,
};
pub const gss_OID = ?*gss_OID_desc;
pub const gss_OID_set_desc = extern struct {
    count: usize,
    elements: [*]gss_OID_desc,
};
pub const gss_OID_set = ?*gss_OID_set_desc;
pub const gss_channel_bindings_struct = extern struct {
    initiator_addrtype: u32 = 0,
    initiator_address: gss_buffer_desc = .{},
    acceptor_addrtype: u32 = 0,
    acceptor_address: gss_buffer_desc = .{},
    application_data: gss_buffer_desc = .{},
};
pub const gss_channel_bindings_t = ?*gss_channel_bindings_struct;

const GSS_S_COMPLETE: OM_uint32 = 0;
const GSS_C_QOP_DEFAULT: gss_qop_t = 0;
const GSSAUTH_P_NONE: u32 = 1;

const gss_ext = struct {
    extern var Curl_krb5_mech_oid: gss_OID_desc;
    extern var Curl_spnego_mech_oid: gss_OID_desc;
    extern var GSS_C_NT_HOSTBASED_SERVICE: gss_OID;
    extern fn gss_import_name(minor_status: *OM_uint32, input_name_buffer: *gss_buffer_desc, input_name_type: gss_OID, output_name: *gss_name_t) callconv(.c) OM_uint32;
    extern fn gss_release_buffer(minor_status: *OM_uint32, buffer: *gss_buffer_desc) callconv(.c) OM_uint32;
    extern fn gss_release_name(minor_status: *OM_uint32, input_name: *gss_name_t) callconv(.c) OM_uint32;
    extern fn gss_unwrap(minor_status: *OM_uint32, context_handle: gss_ctx_id_t, input_message_buffer: *gss_buffer_desc, output_message_buffer: *gss_buffer_desc, conf_state: ?*c_int, qop_state: *gss_qop_t) callconv(.c) OM_uint32;
    extern fn gss_wrap(minor_status: *OM_uint32, context_handle: gss_ctx_id_t, conf_req_flag: c_int, qop_req: gss_qop_t, input_message_buffer: *gss_buffer_desc, conf_state: ?*c_int, output_message_buffer: *gss_buffer_desc) callconv(.c) OM_uint32;
    extern fn Curl_gss_init_sec_context(
        data: ?*Curl_easy,
        minor_status: *OM_uint32,
        context: *gss_ctx_id_t,
        target_name: gss_name_t,
        mech_type: *gss_OID_desc,
        input_chan_bindings: gss_channel_bindings_t,
        input_token: *gss_buffer_desc,
        output_token: *gss_buffer_desc,
        mutual_auth: bool,
        ret_flags: ?*OM_uint32,
        cred_handle: gss_cred_id_t,
    ) callconv(.c) OM_uint32;
    extern fn Curl_gss_delete_sec_context(min: *OM_uint32, context: *gss_ctx_id_t, output_token: ?*gss_buffer_desc) callconv(.c) OM_uint32;
    extern fn Curl_gss_inquire_context(minor_status: *OM_uint32, context: gss_ctx_id_t, mech_type: *gss_OID) callconv(.c) OM_uint32;
    extern fn Curl_gss_release_cred(minor_status: *OM_uint32, cred_handle: *gss_cred_id_t) callconv(.c) OM_uint32;
    extern fn Curl_gss_log_error(data: ?*Curl_easy, prefix: [*:0]const u8, major: OM_uint32, minor: OM_uint32) callconv(.c) void;
};

comptime {
    if (builtin.os.tag == .windows) {
        @export(&authIsGssapiSupportedSspi, .{ .name = "Curl_auth_is_gssapi_supported" });
        @export(&authCreateGssapiUserMessageSspi, .{ .name = "Curl_auth_create_gssapi_user_message" });
        @export(&authCreateGssapiSecurityMessageSspi, .{ .name = "Curl_auth_create_gssapi_security_message" });
        @export(&authCleanupGssapiSspi, .{ .name = "Curl_auth_cleanup_gssapi" });
    } else if (use_gssapi) {
        @export(&authIsGssapiSupportedGss, .{ .name = "Curl_auth_is_gssapi_supported" });
        @export(&authCreateGssapiUserMessageGss, .{ .name = "Curl_auth_create_gssapi_user_message" });
        @export(&authCreateGssapiSecurityMessageGss, .{ .name = "Curl_auth_create_gssapi_security_message" });
        @export(&authCleanupGssapiGss, .{ .name = "Curl_auth_cleanup_gssapi" });
    }
}

pub fn authIsGssapiSupportedGss() callconv(.c) bool {
    return true;
}

pub fn authCreateGssapiUserMessageGss(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    mutual_auth: bool,
    chlg: ?*const bufref,
    krb5: *kerberos5data,
    out: *bufref,
) callconv(.c) CURLcode {
    if (builtin.os.tag == .windows or !use_gssapi) return CURLE_NOT_BUILT_IN;
    var result: CURLcode = CURLE_OK;
    var major_status: OM_uint32 = 0;
    var minor_status: OM_uint32 = 0;
    var unused_status: OM_uint32 = 0;
    var input_token: gss_buffer_desc = .{};
    var output_token: gss_buffer_desc = .{};
    const service: ?[*:0]const u8 = if (credsHasSaslService(creds)) credsSaslService(creds) else default_service;

    if (krb5.spn == null) {
        const spn = Curl_auth_build_spn(service, null, host) orelse return CURLE_OUT_OF_MEMORY;
        var spn_token = gss_buffer_desc{
            .value = spn,
            .length = std.mem.span(spn).len,
        };
        major_status = gss_ext.gss_import_name(&minor_status, &spn_token, gss_ext.GSS_C_NT_HOSTBASED_SERVICE, &krb5.spn);
        mem.free(spn);
        if ((major_status & 0x80000000) != 0) {
            gss_ext.Curl_gss_log_error(data, "gss_import_name() failed: ", major_status, minor_status);
            return CURLE_AUTH_ERROR;
        }
    }

    if (chlg) |c| {
        const len = Curl_bufref_len(c);
        if (len == 0) {
            infof0(data, "GSSAPI handshake failure (empty challenge message)");
            return CURLE_BAD_CONTENT_ENCODING;
        }
        input_token.value = @constCast(Curl_bufref_ptr(c));
        input_token.length = len;
    }

    major_status = gss_ext.Curl_gss_init_sec_context(
        data,
        &minor_status,
        &krb5.context,
        krb5.spn,
        &gss_ext.Curl_krb5_mech_oid,
        null,
        &input_token,
        &output_token,
        mutual_auth,
        null,
        null,
    );

    if ((major_status & 0x80000000) != 0) {
        if (output_token.value != null) {
            _ = gss_ext.gss_release_buffer(&unused_status, &output_token);
        }
        gss_ext.Curl_gss_log_error(data, "gss_init_sec_context() failed: ", major_status, minor_status);
        return CURLE_AUTH_ERROR;
    }

    if (output_token.value != null and output_token.length > 0) {
        result = Curl_bufref_memdup0(out, output_token.value, output_token.length);
        _ = gss_ext.gss_release_buffer(&unused_status, &output_token);
    } else {
        Curl_bufref_set(out, if (mutual_auth) "" else null, 0, null);
    }
    return result;
}

pub fn authCreateGssapiSecurityMessageGss(
    data: ?*Curl_easy,
    authzid: ?[*:0]const u8,
    chlg: ?*const bufref,
    krb5: *kerberos5data,
    out: *bufref,
) callconv(.c) CURLcode {
    if (builtin.os.tag == .windows or !use_gssapi) return CURLE_NOT_BUILT_IN;
    const chlg_ref = chlg orelse return CURLE_BAD_CONTENT_ENCODING;
    const chlg_len = Curl_bufref_len(chlg_ref);
    if (chlg_len == 0) {
        infof0(data, "GSSAPI handshake failure (empty security message)");
        return CURLE_BAD_CONTENT_ENCODING;
    }

    var minor_status: OM_uint32 = 0;
    var unused_status: OM_uint32 = 0;
    var input_token = gss_buffer_desc{
        .value = @constCast(Curl_bufref_ptr(chlg_ref)),
        .length = chlg_len,
    };
    var output_token: gss_buffer_desc = .{};
    var qop: gss_qop_t = GSS_C_QOP_DEFAULT;

    var major_status = gss_ext.gss_unwrap(&minor_status, krb5.context, &input_token, &output_token, null, &qop);
    if ((major_status & 0x80000000) != 0) {
        gss_ext.Curl_gss_log_error(data, "gss_unwrap() failed: ", major_status, minor_status);
        return CURLE_BAD_CONTENT_ENCODING;
    }

    if (output_token.length != 4 or output_token.value == null) {
        infof0(data, "GSSAPI handshake failure (invalid security data)");
        _ = gss_ext.gss_release_buffer(&unused_status, &output_token);
        return CURLE_BAD_CONTENT_ENCODING;
    }

    const indata: [*]const u8 = @ptrCast(output_token.value.?);
    var sec_layer: u32 = indata[0];
    var max_size: u32 = (@as(u32, indata[1]) << 16) | (@as(u32, indata[2]) << 8) | @as(u32, indata[3]);

    _ = gss_ext.gss_release_buffer(&unused_status, &output_token);

    if ((sec_layer & GSSAUTH_P_NONE) == 0) {
        infof0(data, "GSSAPI handshake failure (invalid security layer)");
        return CURLE_BAD_CONTENT_ENCODING;
    }
    sec_layer &= GSSAUTH_P_NONE;
    if (max_size > 0) {
        max_size = 0;
    }

    var messagelen: usize = 4;
    const authzid_slice = if (authzid) |az| std.mem.span(az) else "";
    if (authzid != null) {
        messagelen += authzid_slice.len;
    }

    const message = mem.malloc(messagelen) orelse return CURLE_OUT_OF_MEMORY;
    message[0] = @intCast(sec_layer & 0xFF);
    message[1] = @intCast((max_size >> 16) & 0xFF);
    message[2] = @intCast((max_size >> 8) & 0xFF);
    message[3] = @intCast(max_size & 0xFF);
    if (authzid_slice.len > 0) {
        @memcpy(message[4 .. 4 + authzid_slice.len], authzid_slice);
    }

    input_token.value = message;
    input_token.length = messagelen;

    major_status = gss_ext.gss_wrap(&minor_status, krb5.context, 0, GSS_C_QOP_DEFAULT, &input_token, null, &output_token);
    if ((major_status & 0x80000000) != 0) {
        gss_ext.Curl_gss_log_error(data, "gss_wrap() failed: ", major_status, minor_status);
        mem.free(message);
        return CURLE_AUTH_ERROR;
    }

    const result = Curl_bufref_memdup0(out, output_token.value, output_token.length);
    _ = gss_ext.gss_release_buffer(&unused_status, &output_token);
    mem.free(message);
    return result;
}

pub fn authCleanupGssapiGss(krb5: *kerberos5data) callconv(.c) void {
    if (builtin.os.tag == .windows or !use_gssapi) return;
    var minor_status: OM_uint32 = 0;
    if (krb5.context != null) {
        _ = gss_ext.Curl_gss_delete_sec_context(&minor_status, &krb5.context, null);
        krb5.context = null;
    }
    if (krb5.spn != null) {
        _ = gss_ext.gss_release_name(&minor_status, &krb5.spn);
        krb5.spn = null;
    }
}

pub fn authIsGssapiSupportedSspi() callconv(.c) bool {
    const sec_fn = Curl_pSecFn orelse return false;
    var security_package: ?*SecPkgInfoA = null;
    const status = sec_fn.QuerySecurityPackageInfoA(@constCast(SP_NAME_KERBEROS), &security_package);
    if (status == SEC_E_OK) {
        _ = sec_fn.FreeContextBuffer(security_package);
    }
    return status == SEC_E_OK;
}

pub fn authCreateGssapiUserMessageSspi(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    mutual_auth: bool,
    chlg: ?*const bufref,
    krb5: *kerberos5data,
    out: *bufref,
) callconv(.c) CURLcode {
    if (builtin.os.tag != .windows) return CURLE_NOT_BUILT_IN;
    const sec_fn = Curl_pSecFn orelse return CURLE_AUTH_ERROR;
    var result: CURLcode = CURLE_OK;
    var context: CtxtHandle = undefined;
    var security_package: ?*SecPkgInfoA = null;
    var chlg_buf: SecBuffer = undefined;
    var resp_buf: SecBuffer = undefined;
    var chlg_desc: SecBufferDesc = undefined;
    var resp_desc: SecBufferDesc = undefined;
    var status: SECURITY_STATUS = SEC_E_OK;
    var attrs: c_ulong = 0;
    const service: ?[*:0]const u8 = if (credsHasSaslService(creds)) credsSaslService(creds) else default_service;

    if (krb5.spn == null) {
        krb5.spn = Curl_auth_build_spn(service, host, null) orelse return CURLE_OUT_OF_MEMORY;
    }

    if (krb5.output_token == null) {
        status = sec_fn.QuerySecurityPackageInfoA(@constCast(SP_NAME_KERBEROS), &security_package);
        if (status != SEC_E_OK) {
            failf0(data, "SSPI: could not get auth info");
            return CURLE_AUTH_ERROR;
        }
        krb5.token_max = security_package.?.cbMaxToken;
        _ = sec_fn.FreeContextBuffer(security_package);

        krb5.output_token = mem.malloc(krb5.token_max) orelse return CURLE_OUT_OF_MEMORY;
    }

    if (krb5.credentials == null) {
        if (credsHasUser(creds)) {
            result = createSspiIdentity(creds.?.user, creds.?.passwd, &krb5.identity);
            if (result != CURLE_OK)
                return result;
            krb5.p_identity = &krb5.identity;
        } else {
            krb5.p_identity = null;
        }

        krb5.credentials = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(CredHandle)) orelse return CURLE_OUT_OF_MEMORY));

        status = sec_fn.AcquireCredentialsHandleA(
            null,
            @constCast(SP_NAME_KERBEROS),
            SECPKG_CRED_OUTBOUND,
            null,
            krb5.p_identity,
            null,
            null,
            krb5.credentials,
            null,
        );
        if (status != SEC_E_OK) {
            mem.free(krb5.credentials);
            krb5.credentials = null;
            return CURLE_LOGIN_DENIED;
        }

        krb5.context = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(CtxtHandle)) orelse return CURLE_OUT_OF_MEMORY));
    }

    if (chlg) |c| {
        const len = Curl_bufref_len(c);
        if (len == 0) {
            infof0(data, "GSSAPI handshake failure (empty challenge message)");
            return CURLE_BAD_CONTENT_ENCODING;
        }
        chlg_desc.ulVersion = SECBUFFER_VERSION;
        chlg_desc.cBuffers = 1;
        chlg_desc.pBuffers = @ptrCast(&chlg_buf);
        chlg_buf.BufferType = SECBUFFER_TOKEN;
        chlg_buf.pvBuffer = @constCast(Curl_bufref_ptr(c));
        chlg_buf.cbBuffer = uztoul(len);
    }

    resp_desc.ulVersion = SECBUFFER_VERSION;
    resp_desc.cBuffers = 1;
    resp_desc.pBuffers = @ptrCast(&resp_buf);
    resp_buf.BufferType = SECBUFFER_TOKEN;
    resp_buf.pvBuffer = krb5.output_token;
    resp_buf.cbBuffer = uztoul(krb5.token_max);

    status = sec_fn.InitializeSecurityContextA(
        krb5.credentials,
        if (chlg != null) krb5.context else null,
        krb5.spn,
        if (mutual_auth) ISC_REQ_MUTUAL_AUTH else 0,
        0,
        SECURITY_NATIVE_DREP,
        if (chlg != null) &chlg_desc else null,
        0,
        &context,
        &resp_desc,
        &attrs,
        null,
    );

    if (status == SEC_E_INSUFFICIENT_MEMORY)
        return CURLE_OUT_OF_MEMORY;

    if (status != SEC_E_OK and status != SEC_I_CONTINUE_NEEDED)
        return CURLE_AUTH_ERROR;

    if (krb5.context) |ctx| {
        if (!std.mem.eql(u8, std.mem.asBytes(&context), std.mem.asBytes(ctx))) {
            _ = sec_fn.DeleteSecurityContext(ctx);
            ctx.* = context;
        }
    }

    if (resp_buf.cbBuffer != 0) {
        result = Curl_bufref_memdup0(out, resp_buf.pvBuffer, resp_buf.cbBuffer);
    } else if (mutual_auth) {
        Curl_bufref_set(out, "", 0, null);
    } else {
        Curl_bufref_set(out, null, 0, null);
    }

    return result;
}

pub fn authCreateGssapiSecurityMessageSspi(
    data: ?*Curl_easy,
    authzid: ?[*:0]const u8,
    chlg: ?*const bufref,
    krb5: *kerberos5data,
    out: *bufref,
) callconv(.c) CURLcode {
    if (builtin.os.tag != .windows) return CURLE_NOT_BUILT_IN;
    const sec_fn = Curl_pSecFn orelse return CURLE_AUTH_ERROR;
    const chlg_ref = chlg orelse return CURLE_BAD_CONTENT_ENCODING;
    const chlg_len = Curl_bufref_len(chlg_ref);
    if (chlg_len == 0) {
        infof0(data, "GSSAPI handshake failure (empty security message)");
        return CURLE_BAD_CONTENT_ENCODING;
    }

    var sizes: SecPkgContext_Sizes = undefined;
    var status = sec_fn.QueryContextAttributesA(krb5.context, SECPKG_ATTR_SIZES, &sizes);
    if (status == SEC_E_INSUFFICIENT_MEMORY)
        return CURLE_OUT_OF_MEMORY;
    if (status != SEC_E_OK)
        return CURLE_AUTH_ERROR;

    var input_buf: [2]SecBuffer = undefined;
    var input_desc = SecBufferDesc{
        .ulVersion = SECBUFFER_VERSION,
        .cBuffers = 2,
        .pBuffers = &input_buf,
    };
    input_buf[0] = .{
        .BufferType = SECBUFFER_STREAM,
        .pvBuffer = @constCast(Curl_bufref_ptr(chlg_ref)),
        .cbBuffer = uztoul(chlg_len),
    };
    input_buf[1] = .{
        .BufferType = SECBUFFER_DATA,
        .pvBuffer = null,
        .cbBuffer = 0,
    };

    var qop: c_ulong = 0;
    status = sec_fn.DecryptMessage(krb5.context, &input_desc, 0, &qop);
    if (status != SEC_E_OK) {
        infof0(data, "GSSAPI handshake failure (decryption failed)");
        return CURLE_BAD_CONTENT_ENCODING;
    }

    if (input_buf[1].cbBuffer != 4 or input_buf[1].pvBuffer == null) {
        infof0(data, "GSSAPI handshake failure (invalid security data)");
        return CURLE_BAD_CONTENT_ENCODING;
    }

    const indata: [*]const u8 = @ptrCast(input_buf[1].pvBuffer.?);
    var sec_layer: c_ulong = indata[0];
    var max_size: c_ulong = (@as(c_ulong, indata[1]) << 16) | (@as(c_ulong, indata[2]) << 8) | @as(c_ulong, indata[3]);

    if ((sec_layer & KERB_WRAP_NO_ENCRYPT) == 0) {
        infof0(data, "GSSAPI handshake failure (invalid security layer)");
        return CURLE_BAD_CONTENT_ENCODING;
    }
    sec_layer &= KERB_WRAP_NO_ENCRYPT;

    if (max_size > 0) {
        max_size = 0;
    }

    const trailer: ?[*]u8 = mem.malloc(sizes.cbSecurityTrailer) orelse return CURLE_OUT_OF_MEMORY;
    var message: ?[*]u8 = null;
    var padding: ?[*]u8 = null;
    var appdata: ?[*]u8 = null;
    var appdatalen: usize = 0;
    var result: CURLcode = CURLE_OK;

    var messagelen: usize = 4;
    const authzid_slice = if (authzid) |az| std.mem.span(az) else "";
    if (authzid != null) {
        messagelen += authzid_slice.len;
    }

    blk: {
        message = mem.malloc(messagelen) orelse {
            result = CURLE_OUT_OF_MEMORY;
            break :blk;
        };
        const msg = message.?;
        msg[0] = @intCast(sec_layer & 0xFF);
        msg[1] = @intCast((max_size >> 16) & 0xFF);
        msg[2] = @intCast((max_size >> 8) & 0xFF);
        msg[3] = @intCast(max_size & 0xFF);
        if (authzid_slice.len > 0) {
            @memcpy(msg[4 .. 4 + authzid_slice.len], authzid_slice);
        }

        padding = mem.malloc(sizes.cbBlockSize) orelse {
            result = CURLE_OUT_OF_MEMORY;
            break :blk;
        };

        var wrap_buf: [3]SecBuffer = .{
            .{ .BufferType = SECBUFFER_TOKEN, .pvBuffer = trailer, .cbBuffer = sizes.cbSecurityTrailer },
            .{ .BufferType = SECBUFFER_DATA, .pvBuffer = msg, .cbBuffer = uztoul(messagelen) },
            .{ .BufferType = SECBUFFER_PADDING, .pvBuffer = padding, .cbBuffer = sizes.cbBlockSize },
        };
        var wrap_desc = SecBufferDesc{
            .ulVersion = SECBUFFER_VERSION,
            .cBuffers = 3,
            .pBuffers = &wrap_buf,
        };

        status = sec_fn.EncryptMessage(krb5.context, KERB_WRAP_NO_ENCRYPT, &wrap_desc, 0);
        if (status != SEC_E_OK) {
            result = if (status == SEC_E_INSUFFICIENT_MEMORY) CURLE_OUT_OF_MEMORY else CURLE_AUTH_ERROR;
            break :blk;
        }

        const len0: usize = wrap_buf[0].cbBuffer;
        const len1: usize = wrap_buf[1].cbBuffer;
        const len2: usize = wrap_buf[2].cbBuffer;
        appdatalen = len0 + len1 + len2;
        appdata = mem.malloc(appdatalen) orelse {
            result = CURLE_OUT_OF_MEMORY;
            break :blk;
        };
        const dst = appdata.?;
        if (len0 > 0 and wrap_buf[0].pvBuffer != null) {
            const p0: [*]const u8 = @ptrCast(wrap_buf[0].pvBuffer.?);
            @memcpy(dst[0..len0], p0[0..len0]);
        }
        if (len1 > 0 and wrap_buf[1].pvBuffer != null) {
            const p1: [*]const u8 = @ptrCast(wrap_buf[1].pvBuffer.?);
            @memcpy(dst[len0 .. len0 + len1], p1[0..len1]);
        }
        if (len2 > 0 and wrap_buf[2].pvBuffer != null) {
            const p2: [*]const u8 = @ptrCast(wrap_buf[2].pvBuffer.?);
            @memcpy(dst[len0 + len1 .. appdatalen], p2[0..len2]);
        }
    }

    mem.free(padding);
    mem.free(message);
    mem.free(trailer);

    if (result != CURLE_OK)
        return result;

    Curl_bufref_set(out, appdata, appdatalen, &bufrefFreeCallback);
    return CURLE_OK;
}

pub fn authCleanupGssapiSspi(krb5: *kerberos5data) callconv(.c) void {
    if (builtin.os.tag != .windows) return;
    if (krb5.context) |ctx| {
        if (Curl_pSecFn) |sec_fn| {
            _ = sec_fn.DeleteSecurityContext(ctx);
        }
        mem.free(ctx);
        krb5.context = null;
    }
    if (krb5.credentials) |cred| {
        if (Curl_pSecFn) |sec_fn| {
            _ = sec_fn.FreeCredentialsHandle(cred);
        }
        mem.free(cred);
        krb5.credentials = null;
    }
    sspiFreeIdentity(krb5.p_identity);
    krb5.p_identity = null;

    if (krb5.spn) |spn| {
        mem.free(spn);
        krb5.spn = null;
    }
    if (krb5.output_token) |tok| {
        mem.free(tok);
        krb5.output_token = null;
    }
    krb5.token_max = 0;
}

// ============================================================================
// 5 & 6. lib/vauth/spnego_gssapi.c & lib/vauth/spnego_sspi.c
// ============================================================================

comptime {
    if (builtin.os.tag == .windows) {
        @export(&authIsSpnegoSupportedSspi, .{ .name = "Curl_auth_is_spnego_supported" });
        @export(&authDecodeSpnegoMessageExSspi, .{ .name = "Curl_auth_decode_spnego_message_ex" });
        @export(&authDecodeSpnegoMessageSspi, .{ .name = "Curl_auth_decode_spnego_message" });
        @export(&authCreateSpnegoMessageSspi, .{ .name = "Curl_auth_create_spnego_message" });
        @export(&authCleanupSpnegoSspi, .{ .name = "Curl_auth_cleanup_spnego" });
    } else if (use_gssapi) {
        @export(&authIsSpnegoSupportedGss, .{ .name = "Curl_auth_is_spnego_supported" });
        @export(&authDecodeSpnegoMessageExGss, .{ .name = "Curl_auth_decode_spnego_message_ex" });
        @export(&authDecodeSpnegoMessageGss, .{ .name = "Curl_auth_decode_spnego_message" });
        @export(&authCreateSpnegoMessageGss, .{ .name = "Curl_auth_create_spnego_message" });
        @export(&authCleanupSpnegoGss, .{ .name = "Curl_auth_cleanup_spnego" });
    }
}

pub fn authIsSpnegoSupportedGss() callconv(.c) bool {
    return true;
}

pub fn authDecodeSpnegoMessageExGss(
    data: ?*Curl_easy,
    gssapi_delegation: u8,
    creds: ?*Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    chlg64: ?[*:0]const u8,
    nego: *negotiatedata,
) callconv(.c) CURLcode {
    _ = gssapi_delegation;
    return authDecodeSpnegoMessageGss(data, creds, default_service, host, chlg64, nego);
}

pub fn authDecodeSpnegoMessageGss(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    chlg64: ?[*:0]const u8,
    nego: *negotiatedata,
) callconv(.c) CURLcode {
    if (builtin.os.tag == .windows or !use_gssapi) return CURLE_NOT_BUILT_IN;
    var result: CURLcode = CURLE_OK;
    var chlglen: usize = 0;
    var chlg: ?[*]u8 = null;
    var major_status: OM_uint32 = 0;
    var minor_status: OM_uint32 = 0;
    var unused_status: OM_uint32 = 0;
    var input_token: gss_buffer_desc = .{};
    var output_token: gss_buffer_desc = .{};
    var chan = gss_channel_bindings_struct{};
    var chan_bindings: gss_channel_bindings_t = null;

    if (nego.context != null and nego.status == GSS_S_COMPLETE) {
        authCleanupSpnegoGss(nego);
        return CURLE_LOGIN_DENIED;
    }

    if (nego.spn == null) {
        const service: ?[*:0]const u8 = if (credsHasSaslService(creds)) credsSaslService(creds) else default_service;
        const spn = Curl_auth_build_spn(service, null, host) orelse return CURLE_OUT_OF_MEMORY;
        var spn_token = gss_buffer_desc{
            .value = spn,
            .length = std.mem.span(spn).len,
        };
        major_status = gss_ext.gss_import_name(&minor_status, &spn_token, gss_ext.GSS_C_NT_HOSTBASED_SERVICE, &nego.spn);
        mem.free(spn);
        if ((major_status & 0x80000000) != 0) {
            gss_ext.Curl_gss_log_error(data, "gss_import_name() failed: ", major_status, minor_status);
            return CURLE_AUTH_ERROR;
        }
    }

    if (chlg64) |c64| {
        if (c64[0] != 0) {
            if (c64[0] != '=') {
                result = curlx_base64_decode(c64, &chlg, &chlglen);
                if (result != CURLE_OK)
                    return result;
            }
            if (chlg == null) {
                infof0(data, "SPNEGO handshake failure (empty challenge message)");
                return CURLE_BAD_CONTENT_ENCODING;
            }
            input_token.value = chlg;
            input_token.length = chlglen;
        }
    }

    const cb_len = curlx_dyn_len(&nego.channel_binding_data);
    if (cb_len > 0) {
        chan.application_data.length = cb_len;
        chan.application_data.value = curlx_dyn_ptr(&nego.channel_binding_data);
        chan_bindings = &chan;
    }

    major_status = gss_ext.Curl_gss_init_sec_context(
        data,
        &minor_status,
        &nego.context,
        nego.spn,
        &gss_ext.Curl_spnego_mech_oid,
        chan_bindings,
        &input_token,
        &output_token,
        true,
        null,
        nego.cred,
    );

    if (input_token.value) |v| {
        mem.free(v);
        input_token.value = null;
    }

    nego.status = major_status;
    if ((major_status & 0x80000000) != 0) {
        if (output_token.value != null) {
            _ = gss_ext.gss_release_buffer(&unused_status, &output_token);
        }
        gss_ext.Curl_gss_log_error(data, "gss_init_sec_context() failed: ", major_status, minor_status);
        return CURLE_AUTH_ERROR;
    }

    if (output_token.value == null or output_token.length == 0) {
        if (output_token.value != null) {
            _ = gss_ext.gss_release_buffer(&unused_status, &output_token);
        }
        return CURLE_AUTH_ERROR;
    }

    if (nego.context != null) {
        const ntlmssp_oid = "\x2b\x06\x01\x04\x01\x82\x37\x02\x02\x0a";
        var inquire_minor: OM_uint32 = 0;
        var mech_type: gss_OID = null;
        const inquire_major = gss_ext.Curl_gss_inquire_context(&inquire_minor, nego.context, &mech_type);
        if ((inquire_major & 0x80000000) == 0) {
            if (mech_type) |mt| {
                if (mt.length == ntlmssp_oid.len and mt.elements != null) {
                    const elems: [*]const u8 = @ptrCast(mt.elements.?);
                    if (std.mem.eql(u8, elems[0..ntlmssp_oid.len], ntlmssp_oid)) {
                        infof0(data, "SPNEGO chose NTLM, but NTLM is not allowed");
                        _ = gss_ext.gss_release_buffer(&unused_status, &output_token);
                        authCleanupSpnegoGss(nego);
                        return CURLE_AUTH_ERROR;
                    }
                }
            }
        }
    }

    if (nego.output_token.length != 0 and nego.output_token.value != null) {
        _ = gss_ext.gss_release_buffer(&unused_status, &nego.output_token);
    }
    nego.output_token = output_token;
    return CURLE_OK;
}

pub fn authCreateSpnegoMessageGss(
    nego: *negotiatedata,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode {
    if (builtin.os.tag == .windows or !use_gssapi) return CURLE_NOT_BUILT_IN;
    var minor_status: OM_uint32 = 0;
    const tok_ptr: ?[*]const u8 = if (nego.output_token.value) |v| @ptrCast(v) else null;
    const result = curlx_base64_encode(tok_ptr, nego.output_token.length, outptr, outlen);
    if (result != CURLE_OK) {
        _ = gss_ext.gss_release_buffer(&minor_status, &nego.output_token);
        nego.output_token.value = null;
        nego.output_token.length = 0;
        return result;
    }
    if (outptr.* == null or outlen.* == 0) {
        _ = gss_ext.gss_release_buffer(&minor_status, &nego.output_token);
        nego.output_token.value = null;
        nego.output_token.length = 0;
        return CURLE_REMOTE_ACCESS_DENIED;
    }
    return CURLE_OK;
}

pub fn authCleanupSpnegoGss(nego: *negotiatedata) callconv(.c) void {
    if (builtin.os.tag == .windows or !use_gssapi) return;
    var minor_status: OM_uint32 = 0;
    if (nego.context != null) {
        _ = gss_ext.Curl_gss_delete_sec_context(&minor_status, &nego.context, null);
        nego.context = null;
    }
    if (nego.output_token.value != null) {
        _ = gss_ext.gss_release_buffer(&minor_status, &nego.output_token);
        nego.output_token.value = null;
        nego.output_token.length = 0;
    }
    if (nego.spn != null) {
        _ = gss_ext.gss_release_name(&minor_status, &nego.spn);
        nego.spn = null;
    }
    if (nego.cred != null) {
        _ = gss_ext.Curl_gss_release_cred(&minor_status, &nego.cred);
        nego.cred = null;
    }
    nego.status = 0;
    nego.flags &= ~@as(c_uint, 0x0f);
}

pub fn authIsSpnegoSupportedSspi() callconv(.c) bool {
    const sec_fn = Curl_pSecFn orelse return false;
    var security_package: ?*SecPkgInfoA = null;
    const status = sec_fn.QuerySecurityPackageInfoA(@constCast(SP_NAME_NEGOTIATE), &security_package);
    if (status == SEC_E_OK) {
        _ = sec_fn.FreeContextBuffer(security_package);
    }
    return status == SEC_E_OK;
}

pub fn authDecodeSpnegoMessageSspi(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    chlg64: ?[*:0]const u8,
    nego: *negotiatedata,
) callconv(.c) CURLcode {
    return authDecodeSpnegoMessageExSspi(data, 0, creds, default_service, host, chlg64, nego);
}

pub fn authDecodeSpnegoMessageExSspi(
    data: ?*Curl_easy,
    gssapi_delegation: u8,
    creds: ?*Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    chlg64: ?[*:0]const u8,
    nego: *negotiatedata,
) callconv(.c) CURLcode {
    if (builtin.os.tag != .windows) return CURLE_NOT_BUILT_IN;
    const sec_fn = Curl_pSecFn orelse return CURLE_AUTH_ERROR;
    var result: CURLcode = CURLE_OK;
    var chlglen: usize = 0;
    var chlg: ?[*]u8 = null;
    var security_package: ?*SecPkgInfoA = null;
    var chlg_buf: [2]SecBuffer = undefined;
    var resp_buf: SecBuffer = undefined;
    var chlg_desc: SecBufferDesc = undefined;
    var resp_desc: SecBufferDesc = undefined;
    var attrs: c_ulong = 0;
    var pkg_bindings = SecPkgContext_Bindings{ .BindingsLength = 0, .Bindings = null };

    if (nego.context != null and nego.status == SEC_E_OK) {
        authCleanupSpnegoSspi(nego);
        return CURLE_LOGIN_DENIED;
    }

    if (nego.spn == null) {
        const service: ?[*:0]const u8 = if (credsHasSaslService(creds)) credsSaslService(creds) else default_service;
        nego.spn = Curl_auth_build_spn(service, host, null) orelse return CURLE_OUT_OF_MEMORY;
    }

    if (nego.output_token == null) {
        nego.status = sec_fn.QuerySecurityPackageInfoA(@constCast(SP_NAME_NEGOTIATE), &security_package);
        if (nego.status != SEC_E_OK) {
            failf0(data, "SSPI: could not get auth info");
            return CURLE_AUTH_ERROR;
        }
        nego.token_max = security_package.?.cbMaxToken;
        _ = sec_fn.FreeContextBuffer(security_package);

        nego.output_token = mem.malloc(nego.token_max) orelse return CURLE_OUT_OF_MEMORY;
    }

    if (nego.credentials == null) {
        if (credsHasUser(creds)) {
            result = createSspiIdentity(creds.?.user, creds.?.passwd, &nego.identity);
            if (result != CURLE_OK)
                return result;
            nego.p_identity = &nego.identity;
        } else {
            nego.p_identity = null;
        }

        if (nego.p_identity == null) {
            @memset(std.mem.asBytes(&nego.identity), 0);
            nego.identity.Version = SEC_WINNT_AUTH_IDENTITY_VERSION;
            nego.identity.Length = @sizeOf(SEC_WINNT_AUTH_IDENTITY_EXA);
            nego.identity.Flags = CURL_SEC_WINNT_AUTH_IDENTITY;
            nego.p_identity = &nego.identity;
        }

        nego.identity.PackageList = @constCast("!ntlm");
        nego.identity.PackageListLength = 5;

        nego.credentials = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(CredHandle)) orelse return CURLE_OUT_OF_MEMORY));

        nego.status = sec_fn.AcquireCredentialsHandleA(
            null,
            @constCast(SP_NAME_NEGOTIATE),
            SECPKG_CRED_OUTBOUND,
            null,
            nego.p_identity,
            null,
            null,
            nego.credentials,
            null,
        );
        if (nego.status != SEC_E_OK) {
            mem.free(nego.credentials);
            nego.credentials = null;
            return CURLE_AUTH_ERROR;
        }

        nego.context = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(CtxtHandle)) orelse return CURLE_OUT_OF_MEMORY));
    }

    chlg_desc.ulVersion = SECBUFFER_VERSION;
    chlg_desc.cBuffers = 0;
    chlg_desc.pBuffers = &chlg_buf;

    if (chlg64) |c64| {
        if (c64[0] != 0) {
            if (c64[0] != '=') {
                result = curlx_base64_decode(c64, &chlg, &chlglen);
                if (result != CURLE_OK)
                    return result;
            }
            if (chlg == null) {
                infof0(data, "SPNEGO handshake failure (empty challenge message)");
                return CURLE_BAD_CONTENT_ENCODING;
            }
            chlg_desc.cBuffers = 1;
            chlg_buf[0].BufferType = SECBUFFER_TOKEN;
            chlg_buf[0].pvBuffer = chlg;
            chlg_buf[0].cbBuffer = uztoul(chlglen);
        }
    }

    if (nego.sslContext) |ssl_ctx| {
        nego.status = sec_fn.QueryContextAttributesA(
            ssl_ctx,
            SECPKG_ATTR_ENDPOINT_BINDINGS,
            &pkg_bindings,
        );
        if (nego.status == SEC_E_OK) {
            const idx: usize = chlg_desc.cBuffers;
            chlg_desc.cBuffers += 1;
            chlg_buf[idx].BufferType = SECBUFFER_CHANNEL_BINDINGS;
            chlg_buf[idx].cbBuffer = pkg_bindings.BindingsLength;
            chlg_buf[idx].pvBuffer = pkg_bindings.Bindings;
        }
    }

    resp_desc.ulVersion = SECBUFFER_VERSION;
    resp_desc.cBuffers = 1;
    resp_desc.pBuffers = @ptrCast(&resp_buf);
    resp_buf.BufferType = SECBUFFER_TOKEN;
    resp_buf.pvBuffer = nego.output_token;
    resp_buf.cbBuffer = uztoul(nego.token_max);

    var sspi_flags: c_ulong = ISC_REQ_CONFIDENTIALITY;
    if ((gssapi_delegation & CURLGSSAPI_DELEGATION_FLAG) != 0) {
        sspi_flags |= ISC_REQ_DELEGATE | ISC_REQ_MUTUAL_AUTH;
    }

    nego.status = sec_fn.InitializeSecurityContextA(
        nego.credentials,
        if (chlg != null) nego.context else null,
        nego.spn,
        sspi_flags,
        0,
        SECURITY_NATIVE_DREP,
        if (chlg_desc.cBuffers != 0) &chlg_desc else null,
        0,
        nego.context,
        &resp_desc,
        &attrs,
        null,
    );

    if (pkg_bindings.Bindings) |b| {
        _ = sec_fn.FreeContextBuffer(b);
    }

    mem.free(chlg);

    if (gssError(nego.status)) {
        var buffer: [STRERROR_LEN]u8 = undefined;
        if (!builtin.is_test) {
            const err_str = c_ext.Curl_sspi_strerror(nego.status, &buffer, buffer.len);
            failf1Str(data, "InitializeSecurityContext failed: %s", err_str);
        }
        if (nego.status == SEC_E_INSUFFICIENT_MEMORY)
            return CURLE_OUT_OF_MEMORY;
        return CURLE_AUTH_ERROR;
    }

    if (nego.status == SEC_I_COMPLETE_NEEDED or nego.status == SEC_I_COMPLETE_AND_CONTINUE) {
        nego.status = sec_fn.CompleteAuthToken(nego.context, &resp_desc);
        if (gssError(nego.status)) {
            var buffer: [STRERROR_LEN]u8 = undefined;
            if (!builtin.is_test) {
                const err_str = c_ext.Curl_sspi_strerror(nego.status, &buffer, buffer.len);
                failf1Str(data, "CompleteAuthToken failed: %s", err_str);
            }
            if (nego.status == SEC_E_INSUFFICIENT_MEMORY)
                return CURLE_OUT_OF_MEMORY;
            return CURLE_AUTH_ERROR;
        }
    }

    nego.output_token_length = resp_buf.cbBuffer;
    return result;
}

pub fn authCreateSpnegoMessageSspi(
    nego: *negotiatedata,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode {
    if (builtin.os.tag != .windows) return CURLE_NOT_BUILT_IN;
    var result = curlx_base64_encode(nego.output_token, nego.output_token_length, outptr, outlen);
    if (result == CURLE_OK and (outptr.* == null or outlen.* == 0)) {
        mem.free(outptr.*);
        outptr.* = null;
        result = CURLE_REMOTE_ACCESS_DENIED;
    }
    return result;
}

pub fn authCleanupSpnegoSspi(nego: *negotiatedata) callconv(.c) void {
    if (builtin.os.tag != .windows) return;
    if (nego.context) |ctx| {
        if (Curl_pSecFn) |sec_fn| {
            _ = sec_fn.DeleteSecurityContext(ctx);
        }
        mem.free(ctx);
        nego.context = null;
    }
    if (nego.credentials) |cred| {
        if (Curl_pSecFn) |sec_fn| {
            _ = sec_fn.FreeCredentialsHandle(cred);
        }
        mem.free(cred);
        nego.credentials = null;
    }
    sspiFreeIdentity(nego.p_identity);
    nego.p_identity = null;

    if (nego.spn) |spn| {
        mem.free(spn);
        nego.spn = null;
    }
    if (nego.output_token) |tok| {
        mem.free(tok);
        nego.output_token = null;
    }
    nego.status = 0;
    nego.token_max = 0;
    nego.flags &= ~@as(c_uint, 0x0f);
}

// ============================================================================
// 7. lib/vauth/vauth.c + lib/vauth/vauth.h
// ============================================================================

fn allocSpn2(s1: []const u8, sep: u8, s2: []const u8) ?[*:0]u8 {
    const total = s1.len + 1 + s2.len;
    const buf = mem.malloc(total + 1) orelse return null;
    @memcpy(buf[0..s1.len], s1);
    buf[s1.len] = sep;
    @memcpy(buf[s1.len + 1 ..][0..s2.len], s2);
    buf[total] = 0;
    return @ptrCast(buf);
}

pub export fn Curl_auth_build_spn(
    service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    realm: ?[*:0]const u8,
) callconv(.c) ?[*:0]u8 {
    const s = if (service) |sv| std.mem.span(sv) else "(nil)";
    if (builtin.os.tag == .windows) {
        const h = if (host) |hv| std.mem.span(hv) else "(nil)";
        return allocSpn2(s, '/', h);
    }
    if (host != null and realm != null) {
        const h = std.mem.span(host.?);
        const r = std.mem.span(realm.?);
        const total = s.len + 1 + h.len + 1 + r.len;
        const buf = mem.malloc(total + 1) orelse return null;
        @memcpy(buf[0..s.len], s);
        buf[s.len] = '/';
        @memcpy(buf[s.len + 1 ..][0..h.len], h);
        buf[s.len + 1 + h.len] = '@';
        @memcpy(buf[s.len + 1 + h.len + 1 ..][0..r.len], r);
        buf[total] = 0;
        return @ptrCast(buf);
    } else if (host) |hv| {
        return allocSpn2(s, '/', std.mem.span(hv));
    } else if (realm) |rv| {
        return allocSpn2(s, '@', std.mem.span(rv));
    }
    return null;
}

pub export fn Curl_auth_user_contains_domain(creds: ?*Curl_creds) callconv(.c) bool {
    if (credsHasUser(creds)) {
        const user_slice = std.mem.span(creds.?.user);
        if (std.mem.indexOfAny(u8, user_slice, "\\/@")) |idx| {
            return idx > 0 and idx + 1 < user_slice.len;
        }
        return false;
    }
    if (builtin.os.tag == .windows or use_gssapi) {
        return true;
    }
    return false;
}

fn testPeerSameZoneid(z1: ?[*:0]const u8, z2: ?[*:0]const u8) bool {
    if (z1 == z2) return true;
    if (z1 != null and z2 != null) {
        return std.mem.eql(u8, std.mem.span(z1.?), std.mem.span(z2.?));
    }
    return false;
}

fn testPeerSameHostname(p1: *const Curl_peer, p2: *const Curl_peer) bool {
    if ((p1.flags & 0x7) != (p2.flags & 0x7)) return false;
    const h1 = std.mem.span(p1.hostname);
    const h2 = std.mem.span(p2.hostname);
    if (std.mem.eql(u8, h1, h2)) return true;
    const is_unix_socket = (p1.flags & 0x1) != 0;
    if (!is_unix_socket) {
        return primitives.curl_strequal(p1.hostname, p2.hostname) != 0;
    }
    return false;
}

fn testPeerEqual(p1_opt: ?*Curl_peer, p2_opt: ?*Curl_peer) bool {
    if (p1_opt == p2_opt) return true;
    const p1 = p1_opt orelse return false;
    const p2 = p2_opt orelse return false;
    if (p1.scheme != p2.scheme) return false;
    if (p1.port != p2.port) return false;
    if (!testPeerSameHostname(p1, p2)) return false;
    if (p1.scopeid != p2.scopeid) return false;
    if (p1.scopeid == 0 and !testPeerSameZoneid(p1.zoneid, p2.zoneid)) return false;
    return true;
}

pub export fn Curl_auth_allowed_to_origin_ex(
    allow_auth_to_other_hosts: bool,
    initial_origin: ?*Curl_peer,
    origin: ?*Curl_peer,
) callconv(.c) bool {
    if (allow_auth_to_other_hosts) return true;
    if (builtin.is_test) {
        return testPeerEqual(initial_origin, origin);
    }
    return c_ext.Curl_peer_equal(initial_origin, origin);
}

comptime {
    if (builtin.os.tag == .windows) {
        @export(&authNtlmGet, .{ .name = "Curl_auth_ntlm_get" });
        @export(&authNtlmRemove, .{ .name = "Curl_auth_ntlm_remove" });
        @export(&authKrb5Get, .{ .name = "Curl_auth_krb5_get" });
        @export(&authNegoGet, .{ .name = "Curl_auth_nego_get" });
    } else if (use_gssapi) {
        @export(&authKrb5Get, .{ .name = "Curl_auth_krb5_get" });
        @export(&authNegoGet, .{ .name = "Curl_auth_nego_get" });
    }
}

fn ntlmConnDtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const ntlm: *ntlmdata = @ptrCast(@alignCast(entry orelse return));
    authCleanupNtlmSspi(ntlm);
    mem.free(ntlm);
}

pub fn authNtlmGet(conn: ?*connectdata, proxy: bool) callconv(.c) ?*ntlmdata {
    const key = if (proxy) CURL_META_NTLM_PROXY_CONN else CURL_META_NTLM_CONN;
    var ntlm: ?*ntlmdata = @ptrCast(@alignCast(c_ext.Curl_conn_meta_get(conn, key)));
    if (ntlm == null) {
        ntlm = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(ntlmdata))));
        if (ntlm == null or c_ext.Curl_conn_meta_set(conn, key, ntlm, &ntlmConnDtor) != CURLE_OK) {
            return null;
        }
    }
    return ntlm;
}

pub fn authNtlmRemove(conn: ?*connectdata, proxy: bool) callconv(.c) void {
    c_ext.Curl_conn_meta_remove(conn, if (proxy) CURL_META_NTLM_PROXY_CONN else CURL_META_NTLM_CONN);
}

fn krb5ConnDtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const krb5: *kerberos5data = @ptrCast(@alignCast(entry orelse return));
    if (builtin.os.tag == .windows) {
        authCleanupGssapiSspi(krb5);
    } else if (use_gssapi) {
        authCleanupGssapiGss(krb5);
    }
    mem.free(krb5);
}

pub fn authKrb5Get(conn: ?*connectdata) callconv(.c) ?*kerberos5data {
    var krb5: ?*kerberos5data = @ptrCast(@alignCast(c_ext.Curl_conn_meta_get(conn, CURL_META_KRB5_CONN)));
    if (krb5 == null) {
        krb5 = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(kerberos5data))));
        if (krb5 == null or c_ext.Curl_conn_meta_set(conn, CURL_META_KRB5_CONN, krb5, &krb5ConnDtor) != CURLE_OK) {
            return null;
        }
    }
    return krb5;
}

fn negoConnDtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const nego: *negotiatedata = @ptrCast(@alignCast(entry orelse return));
    if (builtin.os.tag == .windows) {
        authCleanupSpnegoSspi(nego);
    } else if (use_gssapi) {
        authCleanupSpnegoGss(nego);
    }
    mem.free(nego);
}

pub fn authNegoGet(conn: ?*connectdata, proxy: bool) callconv(.c) ?*negotiatedata {
    const key = if (proxy) CURL_META_NEGO_PROXY_CONN else CURL_META_NEGO_CONN;
    var nego: ?*negotiatedata = @ptrCast(@alignCast(c_ext.Curl_conn_meta_get(conn, key)));
    if (nego == null) {
        nego = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(negotiatedata))));
        if (nego == null or c_ext.Curl_conn_meta_set(conn, key, nego, &negoConnDtor) != CURLE_OK) {
            return null;
        }
    }
    return nego;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_auth_build_spn builds expected SPN formats" {
    if (builtin.os.tag == .windows) {
        const spn = Curl_auth_build_spn("HTTP", "example.com", null);
        try std.testing.expect(spn != null);
        defer mem.free(spn.?);
        try std.testing.expectEqualStrings("HTTP/example.com", std.mem.span(spn.?));
    } else {
        const spn1 = Curl_auth_build_spn("HTTP", "example.com", "EXAMPLE.COM");
        try std.testing.expect(spn1 != null);
        defer mem.free(spn1.?);
        try std.testing.expectEqualStrings("HTTP/example.com@EXAMPLE.COM", std.mem.span(spn1.?));

        const spn2 = Curl_auth_build_spn("HTTP", "example.com", null);
        try std.testing.expect(spn2 != null);
        defer mem.free(spn2.?);
        try std.testing.expectEqualStrings("HTTP/example.com", std.mem.span(spn2.?));

        const spn3 = Curl_auth_build_spn("HTTP", null, "example.com");
        try std.testing.expect(spn3 != null);
        defer mem.free(spn3.?);
        try std.testing.expectEqualStrings("HTTP@example.com", std.mem.span(spn3.?));

        const spn4 = Curl_auth_build_spn("HTTP", null, null);
        try std.testing.expect(spn4 == null);
    }
}

test "Curl_auth_user_contains_domain validates domain and UPN formats" {
    var creds = Curl_creds{
        .user = "DOMAIN\\alice",
        .passwd = "secret",
        .oauth_bearer = "",
        .sasl_authzid = "",
        .sasl_service = "",
        .refcount = 1,
        .source = 0,
        .bufsize = 0,
        .buf = .{0},
    };
    try std.testing.expect(Curl_auth_user_contains_domain(&creds));

    creds.user = "DOMAIN/alice";
    try std.testing.expect(Curl_auth_user_contains_domain(&creds));

    creds.user = "alice@EXAMPLE.COM";
    try std.testing.expect(Curl_auth_user_contains_domain(&creds));

    creds.user = "alice";
    try std.testing.expect(!Curl_auth_user_contains_domain(&creds));

    creds.user = "\\alice";
    try std.testing.expect(!Curl_auth_user_contains_domain(&creds));

    creds.user = "DOMAIN\\";
    try std.testing.expect(!Curl_auth_user_contains_domain(&creds));

    creds.user = "";
    try std.testing.expectEqual(builtin.os.tag == .windows or use_gssapi, Curl_auth_user_contains_domain(&creds));
    try std.testing.expectEqual(builtin.os.tag == .windows or use_gssapi, Curl_auth_user_contains_domain(null));
}

test "Curl_auth_allowed_to_origin_ex checks origin equality and override flag" {
    var host1 = "example.com".*;
    var host1_upper = "EXAMPLE.COM".*;
    var host2 = "other.example.com".*;
    var scheme_http: u8 = 1;
    var scheme_https: u8 = 2;

    var peer1 = Curl_peer{
        .scheme = &scheme_http,
        .hostname = &host1,
        .zoneid = null,
        .refcount = 1,
        .scopeid = 0,
        .port = 80,
        .flags = 0,
        .user_hostname = .{0},
    };
    var peer1_same = Curl_peer{
        .scheme = &scheme_http,
        .hostname = &host1_upper,
        .zoneid = null,
        .refcount = 1,
        .scopeid = 0,
        .port = 80,
        .flags = 0,
        .user_hostname = .{0},
    };
    var peer2_diff_host = Curl_peer{
        .scheme = &scheme_http,
        .hostname = &host2,
        .zoneid = null,
        .refcount = 1,
        .scopeid = 0,
        .port = 80,
        .flags = 0,
        .user_hostname = .{0},
    };
    var peer3_diff_port = Curl_peer{
        .scheme = &scheme_http,
        .hostname = &host1,
        .zoneid = null,
        .refcount = 1,
        .scopeid = 0,
        .port = 8080,
        .flags = 0,
        .user_hostname = .{0},
    };
    var peer4_diff_scheme = Curl_peer{
        .scheme = &scheme_https,
        .hostname = &host1,
        .zoneid = null,
        .refcount = 1,
        .scopeid = 0,
        .port = 80,
        .flags = 0,
        .user_hostname = .{0},
    };

    try std.testing.expect(Curl_auth_allowed_to_origin_ex(false, &peer1, &peer1));
    try std.testing.expect(Curl_auth_allowed_to_origin_ex(false, &peer1, &peer1_same));
    try std.testing.expect(!Curl_auth_allowed_to_origin_ex(false, &peer1, &peer2_diff_host));
    try std.testing.expect(!Curl_auth_allowed_to_origin_ex(false, &peer1, &peer3_diff_port));
    try std.testing.expect(!Curl_auth_allowed_to_origin_ex(false, &peer1, &peer4_diff_scheme));
    try std.testing.expect(Curl_auth_allowed_to_origin_ex(true, &peer1, &peer2_diff_host));
    try std.testing.expect(Curl_auth_allowed_to_origin_ex(true, &peer1, null));
}

test "Curl_create_sspi_identity and Curl_sspi_free_identity populate and free identity" {
    var identity: SEC_WINNT_AUTH_IDENTITY_EXA = undefined;
    const rc = createSspiIdentity("CORP\\jdoe", "s3cr3t", &identity);
    try std.testing.expectEqual(CURLE_OK, rc);
    defer sspiFreeIdentity(&identity);

    try std.testing.expectEqual(SEC_WINNT_AUTH_IDENTITY_VERSION, identity.Version);
    try std.testing.expectEqual(@as(c_ulong, @sizeOf(SEC_WINNT_AUTH_IDENTITY_EXA)), identity.Length);
    try std.testing.expectEqual(CURL_SEC_WINNT_AUTH_IDENTITY, identity.Flags);
    try std.testing.expectEqualStrings("CORP", identity.Domain.?[0..identity.DomainLength]);
    try std.testing.expectEqualStrings("jdoe", identity.User.?[0..identity.UserLength]);
    try std.testing.expectEqualStrings("s3cr3t", identity.Password.?[0..identity.PasswordLength]);
}
