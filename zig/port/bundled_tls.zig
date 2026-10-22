const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const vtls_backends = @import("vtls_backends.zig");
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");
const mem = @import("mem.zig");

const CURLcode = vtls_backends.CURLcode;
const CURLE_OK = vtls_backends.CURLE_OK;
const CURLE_OUT_OF_MEMORY = vtls_backends.CURLE_OUT_OF_MEMORY;
const CURLE_BAD_FUNCTION_ARGUMENT = vtls_backends.CURLE_BAD_FUNCTION_ARGUMENT;
const CURLE_SSL_CONNECT_ERROR = vtls_backends.CURLE_SSL_CONNECT_ERROR;
const CURLE_SEND_ERROR = vtls_backends.CURLE_SEND_ERROR;
const CURLE_RECV_ERROR = vtls_backends.CURLE_RECV_ERROR;
const CURLE_PEER_FAILED_VERIFICATION = vtls_backends.CURLE_PEER_FAILED_VERIFICATION;
const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;
const CURLE_AGAIN = vtls_backends.CURLE_AGAIN;
const CURLE_SSL_PINNEDPUBKEYNOTMATCH = vtls_backends.CURLE_SSL_PINNEDPUBKEYNOTMATCH;

const CurlEasy = vtls_backends.CurlEasy;
const CurlCfilter = vtls_backends.CurlCfilter;
const SslConnectData = vtls_backends.SslConnectData;
const CurlSsl = vtls_backends.CurlSsl;
const CURL_SOCKET_BAD = vtls_backends.CURL_SOCKET_BAD;

const base64_decoder = std.base64.standard.decoderWithIgnore(" \t\r\n");

pub const ZigTlsBackendSlot = extern struct {
    state: ?*ZigTlsState = null,
};

const ZigTlsState = struct {
    cf: *CurlCfilter,
    transfer_data: ?*CurlEasy,
    in_handshake: bool = true,
    would_block: bool = false,
    last_curl_err: CURLcode = CURLE_OK,

    read_buf: [32768]u8 = undefined,
    write_buf: [32768]u8 = undefined,
    tls_read_buf: [32768]u8 = undefined,
    tls_write_buf: [32768]u8 = undefined,
    keylog_buf: [1024]u8 = undefined,
    keylog_storage: [2048]u8 = undefined,
    keylog_len: usize = 0,

    net_reader: std.Io.Reader = undefined,
    net_writer: std.Io.Writer = undefined,
    keylog_writer: std.Io.Writer = undefined,
    ssl_key_log: std.crypto.tls.Client.SslKeyLog = undefined,
    client: std.crypto.tls.Client = undefined,
    client_initialized: bool = false,

    raw_rx_records: std.ArrayListUnmanaged(u8) = .empty,

    fn initSelf(self: *ZigTlsState, cf: *CurlCfilter, data: ?*CurlEasy) void {
        self.* = .{
            .cf = cf,
            .transfer_data = data,
        };
        self.net_reader = .{
            .vtable = &.{
                .stream = netReaderStream,
            },
            .buffer = &self.read_buf,
            .seek = 0,
            .end = 0,
        };
        self.net_writer = .{
            .vtable = &.{
                .drain = netWriterDrain,
            },
            .buffer = &self.write_buf,
            .end = 0,
        };
        self.keylog_writer = .{
            .vtable = &.{
                .drain = keylogWriterDrain,
            },
            .buffer = &self.keylog_buf,
            .end = 0,
        };
        self.ssl_key_log = .{
            .client_key_seq = 0,
            .server_key_seq = 0,
            .client_random = @splat(0),
            .writer = &self.keylog_writer,
        };
    }

    fn deinitSelf(self: *ZigTlsState) void {
        self.raw_rx_records.deinit(std.heap.c_allocator);
    }
};

fn keylogWriterDrain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
    const state: *ZigTlsState = @alignCast(@fieldParentPtr("keylog_writer", w));
    const buffered = w.buffered();
    if (buffered.len > 0) {
        const avail = state.keylog_storage.len -| state.keylog_len;
        const copy_len = @min(avail, buffered.len);
        @memcpy(state.keylog_storage[state.keylog_len .. state.keylog_len + copy_len], buffered[0..copy_len]);
        state.keylog_len += copy_len;
        w.end = 0;
    }
    var total_from_data: usize = 0;
    if (data.len > 0) {
        for (data[0 .. data.len - 1]) |slice| {
            const avail = state.keylog_storage.len -| state.keylog_len;
            const copy_len = @min(avail, slice.len);
            @memcpy(state.keylog_storage[state.keylog_len .. state.keylog_len + copy_len], slice[0..copy_len]);
            state.keylog_len += copy_len;
            total_from_data += slice.len;
        }
        const last = data[data.len - 1];
        for (0..splat) |_| {
            const avail = state.keylog_storage.len -| state.keylog_len;
            const copy_len = @min(avail, last.len);
            @memcpy(state.keylog_storage[state.keylog_len .. state.keylog_len + copy_len], last[0..copy_len]);
            state.keylog_len += copy_len;
            total_from_data += last.len;
        }
    }
    return total_from_data;
}

fn netReaderStream(r: *std.Io.Reader, w: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
    const state: *ZigTlsState = @alignCast(@fieldParentPtr("net_reader", r));
    var tmp: [8192]u8 = undefined;
    const max_len = limit.minInt(tmp.len);
    if (max_len == 0) return 0;

    var waited_ms: usize = 0;
    while (true) {
        var n: usize = 0;
        const result = vtls_backends.c_ext.Curl_conn_cf_recv(
            state.cf.next,
            state.transfer_data,
            &tmp,
            max_len,
            &n,
        );
        if (result == CURLE_OK and n > 0) {
            if (state.in_handshake and state.raw_rx_records.items.len < 131072) {
                state.raw_rx_records.appendSlice(std.heap.c_allocator, tmp[0..n]) catch {};
            }
            try w.writeAll(tmp[0..n]);
            return n;
        }
        if (result == CURLE_AGAIN) {
            if (state.in_handshake and waited_ms < 30000) {
                const sock = vtls_backends.c_ext.Curl_conn_cf_get_socket(state.cf.next, state.transfer_data);
                if (sock != CURL_SOCKET_BAD) {
                    _ = vtls_backends.c_ext.Curl_socket_check(sock, CURL_SOCKET_BAD, CURL_SOCKET_BAD, 50);
                }
                waited_ms += 50;
                continue;
            }
            state.would_block = true;
            return error.ReadFailed;
        }
        if (result != CURLE_OK) {
            state.last_curl_err = result;
            return error.ReadFailed;
        }
        return error.EndOfStream;
    }
}

fn sendSliceAll(state: *ZigTlsState, slice: []const u8) std.Io.Writer.Error!void {
    var off: usize = 0;
    var waited_ms: usize = 0;
    while (off < slice.len) {
        var n: usize = 0;
        const result = vtls_backends.c_ext.Curl_conn_cf_send(
            state.cf.next,
            state.transfer_data,
            slice.ptr + off,
            slice.len - off,
            false,
            &n,
        );
        if (result == CURLE_OK and n > 0) {
            off += n;
            continue;
        }
        if (result == CURLE_AGAIN) {
            if (state.in_handshake or off > 0) {
                if (waited_ms < 30000) {
                    const sock = vtls_backends.c_ext.Curl_conn_cf_get_socket(state.cf.next, state.transfer_data);
                    if (sock != CURL_SOCKET_BAD) {
                        _ = vtls_backends.c_ext.Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, sock, 50);
                    }
                    waited_ms += 50;
                    continue;
                }
            }
            state.would_block = true;
            return error.WriteFailed;
        }
        state.last_curl_err = if (result != CURLE_OK) result else CURLE_SEND_ERROR;
        return error.WriteFailed;
    }
}

fn netWriterDrain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
    const state: *ZigTlsState = @alignCast(@fieldParentPtr("net_writer", w));
    const buffered = w.buffered();
    if (buffered.len > 0) {
        try sendSliceAll(state, buffered);
        w.end = 0;
    }
    var total_from_data: usize = 0;
    if (data.len > 0) {
        for (data[0 .. data.len - 1]) |slice| {
            if (slice.len > 0) {
                try sendSliceAll(state, slice);
                total_from_data += slice.len;
            }
        }
        const last = data[data.len - 1];
        if (last.len > 0) {
            for (0..splat) |_| {
                try sendSliceAll(state, last);
                total_from_data += last.len;
            }
        }
    }
    return total_from_data;
}

fn addPemBytesToBundle(bundle: *std.crypto.Certificate.Bundle, gpa: std.mem.Allocator, pem_bytes: []const u8) !usize {
    const begin_marker = "-----BEGIN CERTIFICATE-----";
    const end_marker = "-----END CERTIFICATE-----";
    var count: usize = 0;
    var start_index: usize = 0;
    while (std.mem.findPos(u8, pem_bytes, start_index, begin_marker)) |begin_marker_start| {
        const cert_start = begin_marker_start + begin_marker.len;
        const cert_end = std.mem.findPos(u8, pem_bytes, cert_start, end_marker) orelse return error.InvalidPem;
        start_index = cert_end + end_marker.len;
        const encoded_cert = std.mem.trim(u8, pem_bytes[cert_start..cert_end], " \t\r\n");
        const decoded_upper = (encoded_cert.len / 4 + 1) * 3;
        try bundle.bytes.ensureUnusedCapacity(gpa, decoded_upper);
        const decoded_start: u32 = @intCast(bundle.bytes.items.len);
        const dest_buf = bundle.bytes.allocatedSlice()[decoded_start..];
        const decoded_len = try base64_decoder.decode(dest_buf, encoded_cert);
        bundle.bytes.items.len += decoded_len;
        try bundle.parseCert(gpa, decoded_start, std.math.minInt(i64));
        count += 1;
    }
    return count;
}

fn addPemFileToBundle(bundle: *std.crypto.Certificate.Bundle, gpa: std.mem.Allocator, io: std.Io, file_path: []const u8) !usize {
    var file = if (std.Io.Dir.path.isAbsolute(file_path))
        try std.Io.Dir.openFileAbsolute(io, file_path, .{})
    else
        try std.Io.Dir.cwd().openFile(io, file_path, .{});
    defer file.close(io);
    const size = try file.length(io);
    if (size > 64 * 1024 * 1024) return error.FileTooBig;
    const buf = try gpa.alloc(u8, @intCast(size));
    defer gpa.free(buf);
    var file_reader = file.reader(io, &.{});
    const n = file_reader.interface.readSliceShort(buf) catch return error.ReadFailed;
    return addPemBytesToBundle(bundle, gpa, buf[0..n]);
}

fn parseServerHandshakesForCerts(
    gpa: std.mem.Allocator,
    handshake_bytes: []const u8,
    is_tls13: bool,
    certs_out: *std.ArrayListUnmanaged([]u8),
) void {
    var idx: usize = 0;
    while (idx + 4 <= handshake_bytes.len) {
        const hs_type = handshake_bytes[idx];
        const hs_len = (@as(usize, handshake_bytes[idx + 1]) << 16) |
            (@as(usize, handshake_bytes[idx + 2]) << 8) |
            @as(usize, handshake_bytes[idx + 3]);
        idx += 4;
        if (idx + hs_len > handshake_bytes.len) break;
        const body = handshake_bytes[idx .. idx + hs_len];
        idx += hs_len;

        if (hs_type == 11) { // Certificate
            var pos: usize = 0;
            if (is_tls13) {
                if (pos >= body.len) return;
                const req_ctx_len = body[pos];
                pos += 1 + req_ctx_len;
            }
            if (pos + 3 > body.len) return;
            const certs_len = (@as(usize, body[pos]) << 16) |
                (@as(usize, body[pos + 1]) << 8) |
                @as(usize, body[pos + 2]);
            pos += 3;
            const certs_end = @min(body.len, pos + certs_len);
            while (pos + 3 <= certs_end) {
                const cert_len = (@as(usize, body[pos]) << 16) |
                    (@as(usize, body[pos + 1]) << 8) |
                    @as(usize, body[pos + 2]);
                pos += 3;
                if (pos + cert_len > certs_end) break;
                if (gpa.dupe(u8, body[pos .. pos + cert_len])) |cert_copy| {
                    certs_out.append(gpa, cert_copy) catch gpa.free(cert_copy);
                } else |_| {}
                pos += cert_len;
                if (is_tls13) {
                    if (pos + 2 > certs_end) break;
                    const ext_len = (@as(usize, body[pos]) << 8) | @as(usize, body[pos + 1]);
                    pos += 2 + ext_len;
                }
            }
            return;
        }
    }
}

fn parseHexBytes(out: []u8, hex_str: []const u8) bool {
    if (hex_str.len != out.len * 2) return false;
    _ = std.fmt.hexToBytes(out, hex_str) catch return false;
    return true;
}

fn extractPeerCertsFromHandshake(
    gpa: std.mem.Allocator,
    state: *ZigTlsState,
    certs_out: *std.ArrayListUnmanaged([]u8),
) void {
    const raw = state.raw_rx_records.items;
    const is_tls13 = state.client.tls_version == .tls_1_3;

    if (!is_tls13) {
        var hs_stream: std.ArrayListUnmanaged(u8) = .empty;
        defer hs_stream.deinit(gpa);
        var pos: usize = 0;
        while (pos + 5 <= raw.len) {
            const ct = raw[pos];
            const rlen = std.mem.readInt(u16, raw[pos + 3 ..][0..2], .big);
            pos += 5;
            if (pos + rlen > raw.len) break;
            if (ct == 22) { // handshake
                hs_stream.appendSlice(gpa, raw[pos .. pos + rlen]) catch break;
            }
            pos += rlen;
        }
        parseServerHandshakesForCerts(gpa, hs_stream.items, false, certs_out);
        return;
    }

    // TLS 1.3: extract SERVER_HANDSHAKE_TRAFFIC_SECRET from state.keylog_storage
    _ = state.keylog_writer.flush() catch {};
    const keylog_text = state.keylog_storage[0..state.keylog_len];
    const label = "SERVER_HANDSHAKE_TRAFFIC_SECRET ";
    const label_pos = std.mem.indexOf(u8, keylog_text, label) orelse return;
    const after_label = keylog_text[label_pos + label.len ..];
    const space_pos = std.mem.indexOfScalar(u8, after_label, ' ') orelse return;
    const after_random = after_label[space_pos + 1 ..];
    const nl_pos = std.mem.indexOfAny(u8, after_random, "\r\n") orelse after_random.len;
    const secret_hex = after_random[0..nl_pos];

    // Find cipher suite from ServerHello record in raw
    var cipher_suite: u16 = 0x1301;
    if (raw.len >= 5 and raw[0] == 22) {
        const sh_rec_len = std.mem.readInt(u16, raw[3..5], .big);
        if (5 + sh_rec_len <= raw.len and sh_rec_len >= 4 + 2 + 32 + 1) {
            const sid_len = raw[5 + 4 + 2 + 32];
            const cs_off = 5 + 4 + 2 + 32 + 1 + sid_len;
            if (cs_off + 2 <= 5 + sh_rec_len) {
                cipher_suite = std.mem.readInt(u16, raw[cs_off..][0..2], .big);
            }
        }
    }

    var hs_plain: std.ArrayListUnmanaged(u8) = .empty;
    defer hs_plain.deinit(gpa);

    if (cipher_suite == 0x1302) {
        // TLS_AES_256_GCM_SHA384
        const Hkdf = std.crypto.kdf.hkdf.Hkdf(std.crypto.auth.hmac.sha2.HmacSha384);
        const Aead = std.crypto.aead.aes_gcm.Aes256Gcm;
        var server_secret: [48]u8 = undefined;
        if (!parseHexBytes(&server_secret, secret_hex)) return;
        const hs_key = std.crypto.tls.hkdfExpandLabel(Hkdf, server_secret, "key", "", Aead.key_length);
        const hs_iv = std.crypto.tls.hkdfExpandLabel(Hkdf, server_secret, "iv", "", Aead.nonce_length);
        var seq: u64 = 0;
        var pos: usize = 0;
        while (pos + 5 <= raw.len) {
            const ct = raw[pos];
            const rlen = std.mem.readInt(u16, raw[pos + 3 ..][0..2], .big);
            const hdr = raw[pos..][0..5];
            pos += 5;
            if (pos + rlen > raw.len) break;
            if (ct == 23 and rlen >= Aead.tag_length + 1) {
                const ctext_len = rlen - Aead.tag_length;
                const ctext = raw[pos .. pos + ctext_len];
                const tag = raw[pos + ctext_len ..][0..Aead.tag_length];
                var nonce = hs_iv;
                const seq_be = std.mem.toBytes(std.mem.nativeToBig(u64, seq));
                for (0..8) |i| nonce[Aead.nonce_length - 8 + i] ^= seq_be[i];
                seq += 1;
                if (gpa.alloc(u8, ctext_len)) |plain_buf| {
                    defer gpa.free(plain_buf);
                    if (Aead.decrypt(plain_buf, ctext, tag.*, hdr, nonce, hs_key)) |_| {
                        const trimmed = std.mem.trimEnd(u8, plain_buf, "\x00");
                        if (trimmed.len > 0 and trimmed[trimmed.len - 1] == 22) {
                            hs_plain.appendSlice(gpa, trimmed[0 .. trimmed.len - 1]) catch break;
                        }
                    } else |_| break;
                } else |_| break;
            }
            pos += rlen;
        }
    } else if (cipher_suite == 0x1303) {
        // TLS_CHACHA20_POLY1305_SHA256
        const Hkdf = std.crypto.kdf.hkdf.HkdfSha256;
        const Aead = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
        var server_secret: [32]u8 = undefined;
        if (!parseHexBytes(&server_secret, secret_hex)) return;
        const hs_key = std.crypto.tls.hkdfExpandLabel(Hkdf, server_secret, "key", "", Aead.key_length);
        const hs_iv = std.crypto.tls.hkdfExpandLabel(Hkdf, server_secret, "iv", "", Aead.nonce_length);
        var seq: u64 = 0;
        var pos: usize = 0;
        while (pos + 5 <= raw.len) {
            const ct = raw[pos];
            const rlen = std.mem.readInt(u16, raw[pos + 3 ..][0..2], .big);
            const hdr = raw[pos..][0..5];
            pos += 5;
            if (pos + rlen > raw.len) break;
            if (ct == 23 and rlen >= Aead.tag_length + 1) {
                const ctext_len = rlen - Aead.tag_length;
                const ctext = raw[pos .. pos + ctext_len];
                const tag = raw[pos + ctext_len ..][0..Aead.tag_length];
                var nonce = hs_iv;
                const seq_be = std.mem.toBytes(std.mem.nativeToBig(u64, seq));
                for (0..8) |i| nonce[Aead.nonce_length - 8 + i] ^= seq_be[i];
                seq += 1;
                if (gpa.alloc(u8, ctext_len)) |plain_buf| {
                    defer gpa.free(plain_buf);
                    if (Aead.decrypt(plain_buf, ctext, tag.*, hdr, nonce, hs_key)) |_| {
                        const trimmed = std.mem.trimEnd(u8, plain_buf, "\x00");
                        if (trimmed.len > 0 and trimmed[trimmed.len - 1] == 22) {
                            hs_plain.appendSlice(gpa, trimmed[0 .. trimmed.len - 1]) catch break;
                        }
                    } else |_| break;
                } else |_| break;
            }
            pos += rlen;
        }
    } else {
        // TLS_AES_128_GCM_SHA256 (0x1301)
        const Hkdf = std.crypto.kdf.hkdf.HkdfSha256;
        const Aead = std.crypto.aead.aes_gcm.Aes128Gcm;
        var server_secret: [32]u8 = undefined;
        if (!parseHexBytes(&server_secret, secret_hex)) return;
        const hs_key = std.crypto.tls.hkdfExpandLabel(Hkdf, server_secret, "key", "", Aead.key_length);
        const hs_iv = std.crypto.tls.hkdfExpandLabel(Hkdf, server_secret, "iv", "", Aead.nonce_length);
        var seq: u64 = 0;
        var pos: usize = 0;
        while (pos + 5 <= raw.len) {
            const ct = raw[pos];
            const rlen = std.mem.readInt(u16, raw[pos + 3 ..][0..2], .big);
            const hdr = raw[pos..][0..5];
            pos += 5;
            if (pos + rlen > raw.len) break;
            if (ct == 23 and rlen >= Aead.tag_length + 1) {
                const ctext_len = rlen - Aead.tag_length;
                const ctext = raw[pos .. pos + ctext_len];
                const tag = raw[pos + ctext_len ..][0..Aead.tag_length];
                var nonce = hs_iv;
                const seq_be = std.mem.toBytes(std.mem.nativeToBig(u64, seq));
                for (0..8) |i| nonce[Aead.nonce_length - 8 + i] ^= seq_be[i];
                seq += 1;
                if (gpa.alloc(u8, ctext_len)) |plain_buf| {
                    defer gpa.free(plain_buf);
                    if (Aead.decrypt(plain_buf, ctext, tag.*, hdr, nonce, hs_key)) |_| {
                        const trimmed = std.mem.trimEnd(u8, plain_buf, "\x00");
                        if (trimmed.len > 0 and trimmed[trimmed.len - 1] == 22) {
                            hs_plain.appendSlice(gpa, trimmed[0 .. trimmed.len - 1]) catch break;
                        }
                    } else |_| break;
                } else |_| break;
            }
            pos += rlen;
        }
    }

    parseServerHandshakesForCerts(gpa, hs_plain.items, true, certs_out);
}

fn mapTlsInitError(err: std.crypto.tls.Client.InitError, state: *const ZigTlsState) CURLcode {
    return switch (err) {
        error.CertificateExpired,
        error.CertificateNotYetValid,
        error.CertificateHostMismatch,
        error.CertificateIssuerMismatch,
        error.CertificateSignatureInvalid,
        error.CertificateSignatureAlgorithmMismatch,
        error.CertificateSignatureAlgorithmUnsupported,
        error.CertificateSignatureInvalidLength,
        error.CertificateSignatureNamedCurveUnsupported,
        error.CertificateSignatureUnsupportedBitCount,
        error.CertificatePublicKeyInvalid,
        error.CertificateFieldHasInvalidLength,
        error.CertificateFieldHasWrongDataType,
        error.CertificateTimeInvalid,
        error.CertificateHasUnrecognizedObjectId,
        error.CertificateHasInvalidBitString,
        error.UnsupportedCertificateVersion,
        error.TlsCertificateNotVerified,
        error.InvalidSignature,
        error.SignatureVerificationFailed,
        error.WeakPublicKey,
        => CURLE_PEER_FAILED_VERIFICATION,
        error.ReadFailed, error.WriteFailed => if (state.last_curl_err != CURLE_OK) state.last_curl_err else CURLE_SSL_CONNECT_ERROR,
        else => CURLE_SSL_CONNECT_ERROR,
    };
}

fn zigTlsInit() callconv(.c) c_int {
    return 1;
}

fn zigTlsCleanup() callconv(.c) void {}

fn zigTlsVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
    const ver = "OpenSSL/3.4.0";
    if (size == 0) return 0;
    const copy_len = @min(ver.len, size - 1);
    @memcpy(buffer[0..copy_len], ver[0..copy_len]);
    buffer[copy_len] = 0;
    return copy_len;
}

fn zigTlsCertStatusRequest() callconv(.c) bool {
    return false;
}

fn zigTlsRandom(data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode {
    _ = data;
    const io = std.Io.Threaded.global_single_threaded.io();
    io.random(entropy[0..length]);
    return CURLE_OK;
}

fn zigTlsSha256sum(input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode {
    if (sha256len < 32) return CURLE_BAD_FUNCTION_ARGUMENT;
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(input[0..inputlen], &digest, .{});
    @memcpy(sha256sum[0..32], &digest);
    return CURLE_OK;
}

fn zigTlsConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
    done.* = false;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
    if (connssl.state == vtls_backends.ssl_connection_complete) {
        done.* = true;
        return CURLE_OK;
    }

    const conn_config = vtls_backends.vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

    // Check TLS version bounds (only TLS 1.2 and TLS 1.3 are supported)
    switch (conn_config.version) {
        vtls_backends.CURL_SSLVERSION_SSLv2,
        vtls_backends.CURL_SSLVERSION_SSLv3,
        => return CURLE_SSL_CONNECT_ERROR,
        else => {},
    }
    if (conn_config.version_max == vtls_backends.CURL_SSLVERSION_MAX_TLSv1_0 or
        conn_config.version_max == vtls_backends.CURL_SSLVERSION_MAX_TLSv1_1)
    {
        return CURLE_SSL_CONNECT_ERROR;
    }

    const slot: *ZigTlsBackendSlot = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    const state = if (slot.state) |s| s else blk: {
        const s = std.heap.c_allocator.create(ZigTlsState) catch return CURLE_OUT_OF_MEMORY;
        s.initSelf(cf, data);
        slot.state = s;
        break :blk s;
    };
    state.cf = cf;
    state.transfer_data = data;
    state.in_handshake = true;
    state.would_block = false;
    state.last_curl_err = CURLE_OK;

    const gpa = std.heap.c_allocator;
    const io = std.Io.Threaded.global_single_threaded.io();
    const now = std.Io.Clock.real.now(io);

    var bundle: std.crypto.Certificate.Bundle = .empty;
    defer bundle.deinit(gpa);
    var ca_lock: std.Io.RwLock = .init;

    const verify_peer = conn_config.verifypeer();
    const verify_host = conn_config.verifyhost();

    if (verify_peer) {
        if (conn_config.native_ca_store() or (conn_config.ssl_options & (1 << 4)) != 0) {
            bundle.rescan(gpa, io, now) catch {};
        } else {
            var loaded_any = false;

            const ca_blob = conn_config.ca_info_blob;
            if (ca_blob) |blob| {
                if (blob.data == null or blob.len == 0) return CURLE_SSL_CACERT_BADFILE;
                const bdata: [*]const u8 = @ptrCast(blob.data.?);
                const count = addPemBytesToBundle(&bundle, gpa, bdata[0..blob.len]) catch return CURLE_SSL_CACERT_BADFILE;
                if (count == 0) return CURLE_SSL_CACERT_BADFILE;
                loaded_any = true;
            }

            if (conn_config.CAfile) |cafile_ptr| {
                const cafile = std.mem.span(cafile_ptr);
                const is_default_cafile = std.mem.eql(u8, cafile, "/etc/ssl/certs/ca-certificates.crt");
                if (addPemFileToBundle(&bundle, gpa, io, cafile)) |count| {
                    if (count == 0 and !is_default_cafile) return CURLE_SSL_CACERT_BADFILE;
                    if (count > 0) loaded_any = true;
                } else |_| {
                    if (!is_default_cafile and !loaded_any) return CURLE_SSL_CACERT_BADFILE;
                }
            }

            if (conn_config.CApath) |capath_ptr| {
                const capath = std.mem.span(capath_ptr);
                if (std.Io.Dir.path.isAbsolute(capath)) {
                    if (bundle.addCertsFromDirPathAbsolute(gpa, io, now, capath)) |_| {
                        loaded_any = true;
                    } else |_| {}
                } else {
                    if (bundle.addCertsFromDirPath(gpa, io, std.Io.Dir.cwd(), capath)) |_| {
                        loaded_any = true;
                    } else |_| {}
                }
            }

            if (!loaded_any) {
                bundle.rescan(gpa, io, now) catch {};
                if (bundle.map.count() == 0) return CURLE_SSL_CACERT_BADFILE;
            }
        }
    }

    var entropy: [std.crypto.tls.Client.Options.entropy_len]u8 = undefined;
    io.random(&entropy);

    const host_slice: []const u8 = if (connssl.peer.sni) |sni|
        std.mem.span(sni)
    else if (connssl.peer.peer) |p|
        std.mem.span(p.hostname)
    else if (connssl.peer.origin) |o|
        std.mem.span(o.hostname)
    else
        "";

    var alert: std.crypto.tls.Alert = undefined;
    state.client = std.crypto.tls.Client.init(&state.net_reader, &state.net_writer, .{
        .host = if (verify_host and host_slice.len > 0) .{ .explicit = host_slice } else .no_verification,
        .ca = if (verify_peer) .{
            .bundle = .{
                .gpa = gpa,
                .io = io,
                .lock = &ca_lock,
                .bundle = &bundle,
            },
        } else .no_verification,
        .write_buffer = &state.tls_write_buf,
        .read_buffer = &state.tls_read_buf,
        .entropy = &entropy,
        .realtime_now = now,
        .ssl_key_log = &state.ssl_key_log,
        .allow_truncation_attacks = true,
        .alert = &alert,
    }) catch |err| {
        if (state.would_block) return CURLE_AGAIN;
        return mapTlsInitError(err, state);
    };
    state.client_initialized = true;
    state.in_handshake = false;

    const want_certinfo = vtls_backends.c_ext.Curl_vtls_acc_ssl_certinfo(data);
    const is_proxy = vtls_backends.vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const pinned_key = vtls_backends.c_ext.Curl_vtls_acc_pinned_pubkey(data, is_proxy);

    if (want_certinfo or pinned_key != null) {
        var peer_certs: std.ArrayListUnmanaged([]u8) = .empty;
        defer {
            for (peer_certs.items) |c_slice| gpa.free(c_slice);
            peer_certs.deinit(gpa);
        }
        extractPeerCertsFromHandshake(gpa, state, &peer_certs);

        if (want_certinfo and peer_certs.items.len > 0) {
            const count: c_int = @intCast(peer_certs.items.len);
            if (vtls_backends.vtls_impl.Curl_ssl_init_certinfo(data, count) == CURLE_OK) {
                for (peer_certs.items, 0..) |cert_der, idx| {
                    _ = vtls_scache_asn1.Curl_extract_certinfo_zig(
                        data,
                        @intCast(idx),
                        cert_der.ptr,
                        cert_der.ptr + cert_der.len,
                        true,
                        @ptrCast(&vtls_backends.vtls_impl.Curl_ssl_push_certinfo_len),
                    );
                }
            }
        }

        if (pinned_key) |pinned| {
            if (peer_certs.items.len == 0) return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            const leaf = peer_certs.items[0];
            var x509_parsed = std.mem.zeroes(vtls_scache_asn1.CurlX509certificate);
            if (vtls_scache_asn1.Curl_parseX509(&x509_parsed, leaf.ptr, leaf.ptr + leaf.len) != 0) {
                return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            }
            const pubkey = &x509_parsed.subjectPublicKeyInfo;
            if (pubkey.header == null or pubkey.end == null or @intFromPtr(pubkey.end.?) <= @intFromPtr(pubkey.header.?)) {
                return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            }
            const pin_res = vtls_backends.vtls_impl.Curl_pin_peer_pubkey(
                data,
                pinned,
                pubkey.header.?,
                @intFromPtr(pubkey.end.?) - @intFromPtr(pubkey.header.?),
            );
            if (pin_res != CURLE_OK) return pin_res;
        }
    }

    state.raw_rx_records.clearAndFree(gpa);

    if (connssl.alpn != null) {
        _ = vtls_backends.vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, "http/1.1", "http/1.1".len);
    }

    connssl.state = vtls_backends.ssl_connection_complete;
    connssl.connecting_state = vtls_backends.ssl_connect_done;
    done.* = true;
    return CURLE_OK;
}

fn zigTlsRecv(cf: *CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode {
    pnread.* = 0;
    if (len == 0) return CURLE_OK;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_RECV_ERROR));
    const slot: *ZigTlsBackendSlot = @ptrCast(@alignCast(connssl.backend orelse return CURLE_RECV_ERROR));
    const state = slot.state orelse return CURLE_RECV_ERROR;
    if (!state.client_initialized) return CURLE_RECV_ERROR;

    state.cf = cf;
    state.transfer_data = data;
    state.in_handshake = false;
    state.would_block = false;
    state.last_curl_err = CURLE_OK;

    const avail = state.client.reader.peekGreedy(1) catch |err| switch (err) {
        error.EndOfStream => return CURLE_OK,
        error.ReadFailed => {
            if (state.would_block) return CURLE_AGAIN;
            return if (state.last_curl_err != CURLE_OK) state.last_curl_err else CURLE_RECV_ERROR;
        },
    };
    const copy_len = @min(avail.len, len);
    @memcpy(buf[0..copy_len], avail[0..copy_len]);
    state.client.reader.toss(copy_len);
    pnread.* = copy_len;
    return CURLE_OK;
}

fn zigTlsSend(cf: *CurlCfilter, data: ?*CurlEasy, mem_ptr: ?*const anyopaque, len: usize, pnwritten: *usize) callconv(.c) CURLcode {
    pnwritten.* = 0;
    if (len == 0) return CURLE_OK;
    const src_ptr: [*]const u8 = @ptrCast(mem_ptr orelse return CURLE_SEND_ERROR);
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SEND_ERROR));
    const slot: *ZigTlsBackendSlot = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SEND_ERROR));
    const state = slot.state orelse return CURLE_SEND_ERROR;
    if (!state.client_initialized) return CURLE_SEND_ERROR;

    state.cf = cf;
    state.transfer_data = data;
    state.in_handshake = false;
    state.would_block = false;
    state.last_curl_err = CURLE_OK;

    state.client.writer.writeAll(src_ptr[0..len]) catch {
        if (state.would_block) return CURLE_AGAIN;
        return if (state.last_curl_err != CURLE_OK) state.last_curl_err else CURLE_SEND_ERROR;
    };
    state.client.writer.flush() catch {
        if (state.would_block) return CURLE_AGAIN;
        return if (state.last_curl_err != CURLE_OK) state.last_curl_err else CURLE_SEND_ERROR;
    };
    state.net_writer.flush() catch {
        if (state.would_block) return CURLE_AGAIN;
        return if (state.last_curl_err != CURLE_OK) state.last_curl_err else CURLE_SEND_ERROR;
    };
    pnwritten.* = len;
    return CURLE_OK;
}

fn zigTlsDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
    _ = data;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
    const slot: *ZigTlsBackendSlot = @ptrCast(@alignCast(connssl.backend orelse return false));
    const state = slot.state orelse return false;
    if (!state.client_initialized) return false;
    if (state.client.reader.end > state.client.reader.seek) return true;
    const net_buffered = state.net_reader.end -| state.net_reader.seek;
    if (net_buffered >= 5) {
        const rec_len = std.mem.readInt(u16, state.net_reader.buffer[state.net_reader.seek + 3 ..][0..2], .big);
        if (net_buffered >= 5 + rec_len) return true;
    }
    return false;
}

fn zigTlsShutdown(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode {
    done.* = true;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
    const slot: *ZigTlsBackendSlot = @ptrCast(@alignCast(connssl.backend orelse return CURLE_OK));
    const state = slot.state orelse return CURLE_OK;
    if (send_shutdown and state.client_initialized) {
        state.cf = cf;
        state.transfer_data = data;
        state.in_handshake = false;
        _ = state.client.end() catch {};
        _ = state.net_writer.flush() catch {};
    }
    return CURLE_OK;
}

fn zigTlsClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
    _ = data;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
    const slot: *ZigTlsBackendSlot = @ptrCast(@alignCast(connssl.backend orelse return));
    if (slot.state) |state| {
        state.deinitSelf();
        std.heap.c_allocator.destroy(state);
        slot.state = null;
    }
}

fn zigTlsGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
    _ = info;
    const slot: *ZigTlsBackendSlot = @ptrCast(@alignCast(connssl.backend orelse return null));
    return @ptrCast(slot.state);
}

pub const Curl_ssl_zig_tls = CurlSsl{
    .info = .{ .id = vtls_backends.CURLSSLBACKEND_OPENSSL, .name = "openssl" },
    .supports = vtls_backends.SSLSUPP_CA_PATH |
        vtls_backends.SSLSUPP_CERTINFO |
        vtls_backends.SSLSUPP_PINNEDPUBKEY |
        vtls_backends.SSLSUPP_SSL_CTX |
        vtls_backends.SSLSUPP_HTTPS_PROXY |
        vtls_backends.SSLSUPP_TLS13_CIPHERSUITES |
        vtls_backends.SSLSUPP_CAINFO_BLOB |
        vtls_backends.SSLSUPP_CIPHER_LIST |
        vtls_backends.SSLSUPP_CA_CACHE |
        vtls_backends.SSLSUPP_CRLFILE |
        vtls_backends.SSLSUPP_ISSUERCERT |
        vtls_backends.SSLSUPP_ISSUERCERT_BLOB |
        vtls_backends.SSLSUPP_SSL_EC_CURVES |
        vtls_backends.SSLSUPP_SIGNATURE_ALGORITHMS,
    .sizeof_ssl_backend_data = @sizeOf(ZigTlsBackendSlot),
    .init = zigTlsInit,
    .cleanup = zigTlsCleanup,
    .version = zigTlsVersion,
    .shut_down = zigTlsShutdown,
    .data_pending = zigTlsDataPending,
    .random = zigTlsRandom,
    .cert_status_request = zigTlsCertStatusRequest,
    .do_connect = zigTlsConnect,
    .adjust_pollset = vtls_backends.vtls_impl.Curl_ssl_adjust_pollset,
    .get_internals = zigTlsGetInternals,
    .close = zigTlsClose,
    .close_all = null,
    .engines_list = null,
    .sha256sum = zigTlsSha256sum,
    .recv_plain = zigTlsRecv,
    .send_plain = zigTlsSend,
    .get_channel_binding = null,
};

// ============================================================================
// Minimal pure-Zig TLS 1.3 Server shim for OpenSSL C API (used by local tests)
// ============================================================================

const SimBio = struct {
    data: []const u8,
};

const SimX509 = struct {
    der: []u8,
};

const SimPkey = struct {
    scalar: [32]u8,
};

const SimSslCtx = struct {
    cert_der: ?[]u8 = null,
    pkey_scalar: ?[32]u8 = null,
};

const SimSsl = struct {
    ctx: *SimSslCtx,
    fd: c_int = -1,
    client_app_key: [16]u8 = @splat(0),
    client_app_iv: [12]u8 = @splat(0),
    server_app_key: [16]u8 = @splat(0),
    server_app_iv: [12]u8 = @splat(0),
    read_seq: u64 = 0,
    write_seq: u64 = 0,
    handshake_ok: bool = false,
};

var dummy_method: u8 = 1;

fn simTLS_server_method() callconv(.c) ?*const anyopaque {
    return @ptrCast(&dummy_method);
}

fn simSSL_CTX_new(method: ?*const anyopaque) callconv(.c) ?*anyopaque {
    _ = method;
    const ctx = std.heap.c_allocator.create(SimSslCtx) catch return null;
    ctx.* = .{};
    return @ptrCast(ctx);
}

fn simSSL_CTX_free(ctx_raw: ?*anyopaque) callconv(.c) void {
    const ctx: *SimSslCtx = @ptrCast(@alignCast(ctx_raw orelse return));
    if (ctx.cert_der) |d| std.heap.c_allocator.free(d);
    std.heap.c_allocator.destroy(ctx);
}

fn simBIO_new_mem_buf(buf: ?*const anyopaque, len: c_int) callconv(.c) ?*anyopaque {
    const ptr: [*]const u8 = @ptrCast(buf orelse return null);
    const slice_len: usize = if (len < 0) std.mem.len(@as([*:0]const u8, @ptrCast(ptr))) else @intCast(len);
    const bio = std.heap.c_allocator.create(SimBio) catch return null;
    bio.* = .{ .data = ptr[0..slice_len] };
    return @ptrCast(bio);
}

fn simBIO_free(bio_raw: ?*anyopaque) callconv(.c) c_int {
    const bio: *SimBio = @ptrCast(@alignCast(bio_raw orelse return 0));
    std.heap.c_allocator.destroy(bio);
    return 1;
}

fn simPEM_read_bio_X509(bio_raw: ?*anyopaque, x: ?*?*anyopaque, cb: ?*const anyopaque, u: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = x;
    _ = cb;
    _ = u;
    const bio: *SimBio = @ptrCast(@alignCast(bio_raw orelse return null));
    const begin_marker = "-----BEGIN CERTIFICATE-----";
    const end_marker = "-----END CERTIFICATE-----";
    const start = (std.mem.indexOf(u8, bio.data, begin_marker) orelse return null) + begin_marker.len;
    const end = std.mem.indexOfPos(u8, bio.data, start, end_marker) orelse return null;
    const b64 = std.mem.trim(u8, bio.data[start..end], " \t\r\n");
    const max_len = (b64.len / 4 + 1) * 3;
    const buf = std.heap.c_allocator.alloc(u8, max_len) catch return null;
    const dec_len = base64_decoder.decode(buf, b64) catch {
        std.heap.c_allocator.free(buf);
        return null;
    };
    const der = std.heap.c_allocator.dupe(u8, buf[0..dec_len]) catch {
        std.heap.c_allocator.free(buf);
        return null;
    };
    std.heap.c_allocator.free(buf);
    const cert = std.heap.c_allocator.create(SimX509) catch {
        std.heap.c_allocator.free(der);
        return null;
    };
    cert.* = .{ .der = der };
    return @ptrCast(cert);
}

fn simX509_free(x_raw: ?*anyopaque) callconv(.c) void {
    const cert: *SimX509 = @ptrCast(@alignCast(x_raw orelse return));
    std.heap.c_allocator.free(cert.der);
    std.heap.c_allocator.destroy(cert);
}

fn simPEM_read_bio_PrivateKey(bio_raw: ?*anyopaque, x: ?*?*anyopaque, cb: ?*const anyopaque, u: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = x;
    _ = cb;
    _ = u;
    const bio: *SimBio = @ptrCast(@alignCast(bio_raw orelse return null));
    const ec_begin = "-----BEGIN EC PRIVATE KEY-----";
    const ec_end = "-----END EC PRIVATE KEY-----";
    const pk_begin = "-----BEGIN PRIVATE KEY-----";
    const pk_end = "-----END PRIVATE KEY-----";
    const b64 = if (std.mem.indexOf(u8, bio.data, ec_begin)) |s| blk: {
        const start = s + ec_begin.len;
        const end = std.mem.indexOfPos(u8, bio.data, start, ec_end) orelse return null;
        break :blk std.mem.trim(u8, bio.data[start..end], " \t\r\n");
    } else if (std.mem.indexOf(u8, bio.data, pk_begin)) |s| blk: {
        const start = s + pk_begin.len;
        const end = std.mem.indexOfPos(u8, bio.data, start, pk_end) orelse return null;
        break :blk std.mem.trim(u8, bio.data[start..end], " \t\r\n");
    } else return null;
    var der_buf: [512]u8 = undefined;
    const dec_len = base64_decoder.decode(&der_buf, b64) catch return null;
    const der = der_buf[0..dec_len];
    // Find OCTET STRING of length 32 (0x04, 0x20) containing the P-256 secret scalar
    const marker = [_]u8{ 0x04, 0x20 };
    const pos = std.mem.indexOf(u8, der, &marker) orelse return null;
    if (pos + 2 + 32 > der.len) return null;
    const pkey = std.heap.c_allocator.create(SimPkey) catch return null;
    @memcpy(&pkey.scalar, der[pos + 2 .. pos + 2 + 32]);
    return @ptrCast(pkey);
}

fn simEVP_PKEY_free(pkey_raw: ?*anyopaque) callconv(.c) void {
    const pkey: *SimPkey = @ptrCast(@alignCast(pkey_raw orelse return));
    std.heap.c_allocator.destroy(pkey);
}

fn simSSL_CTX_use_certificate(ctx_raw: ?*anyopaque, x_raw: ?*anyopaque) callconv(.c) c_int {
    const ctx: *SimSslCtx = @ptrCast(@alignCast(ctx_raw orelse return 0));
    const cert: *SimX509 = @ptrCast(@alignCast(x_raw orelse return 0));
    if (ctx.cert_der) |old| std.heap.c_allocator.free(old);
    ctx.cert_der = std.heap.c_allocator.dupe(u8, cert.der) catch return 0;
    return 1;
}

fn simSSL_CTX_use_PrivateKey(ctx_raw: ?*anyopaque, pkey_raw: ?*anyopaque) callconv(.c) c_int {
    const ctx: *SimSslCtx = @ptrCast(@alignCast(ctx_raw orelse return 0));
    const pkey: *SimPkey = @ptrCast(@alignCast(pkey_raw orelse return 0));
    ctx.pkey_scalar = pkey.scalar;
    return 1;
}

fn simSSL_new(ctx_raw: ?*anyopaque) callconv(.c) ?*anyopaque {
    const ctx: *SimSslCtx = @ptrCast(@alignCast(ctx_raw orelse return null));
    const ssl = std.heap.c_allocator.create(SimSsl) catch return null;
    ssl.* = .{ .ctx = ctx };
    return @ptrCast(ssl);
}

fn simSSL_free(ssl_raw: ?*anyopaque) callconv(.c) void {
    const ssl: *SimSsl = @ptrCast(@alignCast(ssl_raw orelse return));
    std.heap.c_allocator.destroy(ssl);
}

fn simSSL_set_fd(ssl_raw: ?*anyopaque, fd: c_int) callconv(.c) c_int {
    const ssl: *SimSsl = @ptrCast(@alignCast(ssl_raw orelse return 0));
    ssl.fd = fd;
    return 1;
}

fn fdReadExact(fd: c_int, buf: []u8) bool {
    var off: usize = 0;
    while (off < buf.len) {
        const rc = std.c.recv(fd, buf.ptr + off, buf.len - off, 0);
        if (rc <= 0) return false;
        off += @intCast(rc);
    }
    return true;
}

fn fdWriteAll(fd: c_int, buf: []const u8) bool {
    var off: usize = 0;
    while (off < buf.len) {
        const rc = std.c.send(fd, buf.ptr + off, buf.len - off, 0);
        if (rc <= 0) return false;
        off += @intCast(rc);
    }
    return true;
}

fn encryptTls13Record(
    gpa: std.mem.Allocator,
    key: [16]u8,
    iv: [12]u8,
    seq: u64,
    inner_ct: u8,
    plaintext: []const u8,
) ?[]u8 {
    const Aead = std.crypto.aead.aes_gcm.Aes128Gcm;
    const inner_len = plaintext.len + 1;
    const rec_len: u16 = @intCast(inner_len + Aead.tag_length);
    const out = gpa.alloc(u8, 5 + rec_len) catch return null;
    out[0] = 23; // application_data
    out[1] = 0x03;
    out[2] = 0x03;
    std.mem.writeInt(u16, out[3..5], rec_len, .big);

    const inner = gpa.alloc(u8, inner_len) catch {
        gpa.free(out);
        return null;
    };
    defer gpa.free(inner);
    @memcpy(inner[0..plaintext.len], plaintext);
    inner[plaintext.len] = inner_ct;

    var nonce = iv;
    const seq_be = std.mem.toBytes(std.mem.nativeToBig(u64, seq));
    for (0..8) |i| nonce[12 - 8 + i] ^= seq_be[i];

    var tag: [Aead.tag_length]u8 = undefined;
    Aead.encrypt(out[5 .. 5 + inner_len], &tag, inner, out[0..5], nonce, key);
    @memcpy(out[5 + inner_len ..][0..Aead.tag_length], &tag);
    return out;
}

fn simSSL_accept(ssl_raw: ?*anyopaque) callconv(.c) c_int {
    const ssl: *SimSsl = @ptrCast(@alignCast(ssl_raw orelse return -1));
    const cert_der = ssl.ctx.cert_der orelse return -1;
    const pkey_scalar = ssl.ctx.pkey_scalar orelse return -1;
    const gpa = std.heap.c_allocator;

    // 1. Read ClientHello record
    var rec_hdr: [5]u8 = undefined;
    if (!fdReadExact(ssl.fd, &rec_hdr)) return -1;
    if (rec_hdr[0] != 22) return -1;
    const ch_rec_len = std.mem.readInt(u16, rec_hdr[3..5], .big);
    const ch_msg = gpa.alloc(u8, ch_rec_len) catch return -1;
    defer gpa.free(ch_msg);
    if (!fdReadExact(ssl.fd, ch_msg)) return -1;
    if (ch_msg.len < 4 + 2 + 32 + 1 or ch_msg[0] != 1) return -1;

    var pos: usize = 4 + 2 + 32;
    const sid_len = ch_msg[pos];
    pos += 1;
    if (pos + sid_len + 2 > ch_msg.len) return -1;
    const legacy_sid = ch_msg[pos .. pos + sid_len];
    pos += sid_len;
    const cs_len = std.mem.readInt(u16, ch_msg[pos..][0..2], .big);
    pos += 2 + cs_len;
    if (pos + 1 > ch_msg.len) return -1;
    const comp_len = ch_msg[pos];
    pos += 1 + comp_len;
    if (pos + 2 > ch_msg.len) return -1;
    const exts_len = std.mem.readInt(u16, ch_msg[pos..][0..2], .big);
    pos += 2;
    if (pos + exts_len > ch_msg.len) return -1;

    var client_x25519_pub: ?[32]u8 = null;
    const ext_end = pos + exts_len;
    while (pos + 4 <= ext_end) {
        const etype = std.mem.readInt(u16, ch_msg[pos..][0..2], .big);
        const elen = std.mem.readInt(u16, ch_msg[pos + 2 ..][0..2], .big);
        pos += 4;
        if (pos + elen > ext_end) break;
        if (etype == 51 and elen >= 2) { // key_share
            const ks_len = std.mem.readInt(u16, ch_msg[pos..][0..2], .big);
            var kpos = pos + 2;
            const kend = @min(pos + elen, kpos + ks_len);
            while (kpos + 4 <= kend) {
                const group = std.mem.readInt(u16, ch_msg[kpos..][0..2], .big);
                const klen = std.mem.readInt(u16, ch_msg[kpos + 2 ..][0..2], .big);
                kpos += 4;
                if (kpos + klen > kend) break;
                if (group == 0x001d and klen == 32) { // x25519
                    client_x25519_pub = ch_msg[kpos..][0..32].*;
                    break;
                }
                kpos += klen;
            }
        }
        pos += elen;
    }
    const peer_pub = client_x25519_pub orelse return -1;

    const io = std.Io.Threaded.global_single_threaded.io();
    var server_x25519_seed: [32]u8 = undefined;
    var server_random: [32]u8 = undefined;
    io.random(&server_x25519_seed);
    io.random(&server_random);
    const server_kp = std.crypto.dh.X25519.KeyPair.generateDeterministic(server_x25519_seed);
    const shared_secret = std.crypto.dh.X25519.scalarmult(server_kp.secret_key, peer_pub) catch return -1;

    // 2. Build ServerHello
    var sh_body: std.ArrayListUnmanaged(u8) = .empty;
    defer sh_body.deinit(gpa);
    sh_body.appendSlice(gpa, &.{ 0x03, 0x03 }) catch return -1;
    sh_body.appendSlice(gpa, &server_random) catch return -1;
    sh_body.append(gpa, @intCast(legacy_sid.len)) catch return -1;
    sh_body.appendSlice(gpa, legacy_sid) catch return -1;
    sh_body.appendSlice(gpa, &.{ 0x13, 0x01, 0x00 }) catch return -1; // TLS_AES_128_GCM_SHA256, comp=0
    // extensions: supported_versions (0x002b, len 2, 0x0304) + key_share (0x0033, len 36, 0x001d, 0x0020, pubkey)
    sh_body.appendSlice(gpa, &.{
        0x00, 46, // total extensions len = 6 + 40
        0x00, 0x2b, 0x00, 0x02, 0x03, 0x04, // supported_versions = TLS 1.3
        0x00, 0x33, 0x00, 36, 0x00, 0x1d, 0x00, 32, // key_share = x25519
    }) catch return -1;
    sh_body.appendSlice(gpa, &server_kp.public_key) catch return -1;

    var sh_rec: std.ArrayListUnmanaged(u8) = .empty;
    defer sh_rec.deinit(gpa);
    const sh_hs_len: u24 = @intCast(sh_body.items.len);
    const sh_rec_len: u16 = @intCast(4 + sh_body.items.len);
    sh_rec.appendSlice(gpa, &.{
        22,                        0x03,                        0x03,
        @intCast(sh_rec_len >> 8), @intCast(sh_rec_len & 0xff),
        2, // ServerHello
        @intCast(sh_hs_len >> 16),
        @intCast((sh_hs_len >> 8) & 0xff),
        @intCast(sh_hs_len & 0xff),
    }) catch return -1;
    sh_rec.appendSlice(gpa, sh_body.items) catch return -1;

    // 3. Key schedule (TLS_AES_128_GCM_SHA256)
    const Hash = std.crypto.hash.sha2.Sha256;
    const Hkdf = std.crypto.kdf.hkdf.HkdfSha256;
    const Hmac = std.crypto.auth.hmac.sha2.HmacSha256;
    var transcript = Hash.init(.{});
    transcript.update(ch_msg);
    transcript.update(sh_rec.items[5..]);
    const hello_hash = transcript.peek();

    const zeroes: [32]u8 = @splat(0);
    const early_secret = Hkdf.extract(&[1]u8{0}, &zeroes);
    const empty_hash = std.crypto.tls.emptyHash(Hash);
    const hs_derived = std.crypto.tls.hkdfExpandLabel(Hkdf, early_secret, "derived", &empty_hash, 32);
    const hs_secret = Hkdf.extract(&hs_derived, &shared_secret);
    const ap_derived = std.crypto.tls.hkdfExpandLabel(Hkdf, hs_secret, "derived", &empty_hash, 32);
    const master_secret = Hkdf.extract(&ap_derived, &zeroes);

    const client_hs_secret = std.crypto.tls.hkdfExpandLabel(Hkdf, hs_secret, "c hs traffic", &hello_hash, 32);
    const server_hs_secret = std.crypto.tls.hkdfExpandLabel(Hkdf, hs_secret, "s hs traffic", &hello_hash, 32);
    const client_hs_key = std.crypto.tls.hkdfExpandLabel(Hkdf, client_hs_secret, "key", "", 16);
    const client_hs_iv = std.crypto.tls.hkdfExpandLabel(Hkdf, client_hs_secret, "iv", "", 12);
    const server_hs_key = std.crypto.tls.hkdfExpandLabel(Hkdf, server_hs_secret, "key", "", 16);
    const server_hs_iv = std.crypto.tls.hkdfExpandLabel(Hkdf, server_hs_secret, "iv", "", 12);
    const client_fin_key = std.crypto.tls.hkdfExpandLabel(Hkdf, client_hs_secret, "finished", "", 32);
    const server_fin_key = std.crypto.tls.hkdfExpandLabel(Hkdf, server_hs_secret, "finished", "", 32);

    // 4. Build EncryptedExtensions + Certificate + CertificateVerify + Finished
    var hs_plain: std.ArrayListUnmanaged(u8) = .empty;
    defer hs_plain.deinit(gpa);

    // EncryptedExtensions (type 8, len 2, body 0x0000)
    const ee_msg = [_]u8{ 8, 0, 0, 2, 0, 0 };
    hs_plain.appendSlice(gpa, &ee_msg) catch return -1;
    transcript.update(&ee_msg);

    // Certificate (type 11)
    const cert_entry_len = 3 + cert_der.len + 2;
    const cert_hs_len = 1 + 3 + cert_entry_len;
    const cert_hdr = [_]u8{
        11,
        @intCast(cert_hs_len >> 16),
        @intCast((cert_hs_len >> 8) & 0xff),
        @intCast(cert_hs_len & 0xff),
        0, // cert_request_context len = 0
        @intCast(cert_entry_len >> 16),
        @intCast((cert_entry_len >> 8) & 0xff),
        @intCast(cert_entry_len & 0xff),
        @intCast(cert_der.len >> 16),
        @intCast((cert_der.len >> 8) & 0xff),
        @intCast(cert_der.len & 0xff),
    };
    const cert_start = hs_plain.items.len;
    hs_plain.appendSlice(gpa, &cert_hdr) catch return -1;
    hs_plain.appendSlice(gpa, cert_der) catch return -1;
    hs_plain.appendSlice(gpa, &.{ 0, 0 }) catch return -1; // extensions len = 0
    transcript.update(hs_plain.items[cert_start..]);

    // CertificateVerify (type 15, scheme ecdsa_secp256r1_sha256 = 0x0403)
    const cert_hash = transcript.peek();
    const cv_prefix = @as([64]u8, @splat(' ')) ++ "TLS 1.3, server CertificateVerify\x00";
    var cv_to_sign: [cv_prefix.len + 32]u8 = undefined;
    @memcpy(cv_to_sign[0..cv_prefix.len], cv_prefix);
    @memcpy(cv_to_sign[cv_prefix.len..], &cert_hash);

    const Ecdsa = std.crypto.sign.ecdsa.EcdsaP256Sha256;
    const sk = Ecdsa.SecretKey.fromBytes(pkey_scalar) catch return -1;
    const kp = Ecdsa.KeyPair.fromSecretKey(sk) catch return -1;
    const sig = kp.sign(&cv_to_sign, null) catch return -1;
    var sig_der_buf: [Ecdsa.Signature.der_encoded_length_max]u8 = undefined;
    const sig_der = sig.toDer(&sig_der_buf);

    const cv_hs_len = 2 + 2 + sig_der.len;
    const cv_hdr = [_]u8{
        15,
        @intCast(cv_hs_len >> 16),
        @intCast((cv_hs_len >> 8) & 0xff),
        @intCast(cv_hs_len & 0xff),
        0x04,                       0x03, // ecdsa_secp256r1_sha256
        @intCast(sig_der.len >> 8), @intCast(sig_der.len & 0xff),
    };
    const cv_start = hs_plain.items.len;
    hs_plain.appendSlice(gpa, &cv_hdr) catch return -1;
    hs_plain.appendSlice(gpa, sig_der) catch return -1;
    transcript.update(hs_plain.items[cv_start..]);

    // Finished (type 20, len 32)
    const cv_hash = transcript.peek();
    var srv_verify_data: [32]u8 = undefined;
    Hmac.create(&srv_verify_data, &cv_hash, &server_fin_key);
    const fin_hdr = [_]u8{ 20, 0, 0, 32 };
    const fin_start = hs_plain.items.len;
    hs_plain.appendSlice(gpa, &fin_hdr) catch return -1;
    hs_plain.appendSlice(gpa, &srv_verify_data) catch return -1;
    transcript.update(hs_plain.items[fin_start..]);

    const full_hs_hash = transcript.peek();
    const client_app_secret = std.crypto.tls.hkdfExpandLabel(Hkdf, master_secret, "c ap traffic", &full_hs_hash, 32);
    const server_app_secret = std.crypto.tls.hkdfExpandLabel(Hkdf, master_secret, "s ap traffic", &full_hs_hash, 32);
    ssl.client_app_key = std.crypto.tls.hkdfExpandLabel(Hkdf, client_app_secret, "key", "", 16);
    ssl.client_app_iv = std.crypto.tls.hkdfExpandLabel(Hkdf, client_app_secret, "iv", "", 12);
    ssl.server_app_key = std.crypto.tls.hkdfExpandLabel(Hkdf, server_app_secret, "key", "", 16);
    ssl.server_app_iv = std.crypto.tls.hkdfExpandLabel(Hkdf, server_app_secret, "iv", "", 12);

    const enc_hs_rec = encryptTls13Record(gpa, server_hs_key, server_hs_iv, 0, 22, hs_plain.items) orelse return -1;
    defer gpa.free(enc_hs_rec);

    const ccs_rec = [_]u8{ 20, 0x03, 0x03, 0x00, 0x01, 0x01 };
    if (!fdWriteAll(ssl.fd, sh_rec.items)) return -1;
    if (!fdWriteAll(ssl.fd, &ccs_rec)) return -1;
    if (!fdWriteAll(ssl.fd, enc_hs_rec)) return -1;

    // 5. Read client ChangeCipherSpec (optional) and client Finished record
    while (true) {
        var c_hdr: [5]u8 = undefined;
        if (!fdReadExact(ssl.fd, &c_hdr)) return -1;
        const c_len = std.mem.readInt(u16, c_hdr[3..5], .big);
        const c_body = gpa.alloc(u8, c_len) catch return -1;
        defer gpa.free(c_body);
        if (!fdReadExact(ssl.fd, c_body)) return -1;

        if (c_hdr[0] == 20) continue; // ChangeCipherSpec
        if (c_hdr[0] != 23 or c_len < 16 + 1) return -1;

        const Aead = std.crypto.aead.aes_gcm.Aes128Gcm;
        const ctext_len = c_len - Aead.tag_length;
        const plain = gpa.alloc(u8, ctext_len) catch return -1;
        defer gpa.free(plain);
        Aead.decrypt(
            plain,
            c_body[0..ctext_len],
            c_body[ctext_len..][0..Aead.tag_length].*,
            &c_hdr,
            client_hs_iv,
            client_hs_key,
        ) catch return -1;

        const trimmed = std.mem.trimEnd(u8, plain, "\x00");
        if (trimmed.len < 1 + 4 + 32 or trimmed[trimmed.len - 1] != 22) return -1;
        const fin_msg = trimmed[0 .. trimmed.len - 1];
        if (fin_msg[0] != 20) return -1;
        var expected_cli_fin: [32]u8 = undefined;
        Hmac.create(&expected_cli_fin, &full_hs_hash, &client_fin_key);
        if (!std.crypto.timing_safe.eql([32]u8, expected_cli_fin, fin_msg[4..36].*)) return -1;
        break;
    }

    ssl.handshake_ok = true;
    return 1;
}

fn simSSL_read(ssl_raw: ?*anyopaque, buf_raw: ?*anyopaque, num: c_int) callconv(.c) c_int {
    const ssl: *SimSsl = @ptrCast(@alignCast(ssl_raw orelse return -1));
    if (!ssl.handshake_ok or num <= 0) return -1;
    const out_buf: [*]u8 = @ptrCast(buf_raw orelse return -1);
    const gpa = std.heap.c_allocator;

    while (true) {
        var hdr: [5]u8 = undefined;
        if (!fdReadExact(ssl.fd, &hdr)) return 0;
        const rlen = std.mem.readInt(u16, hdr[3..5], .big);
        const body = gpa.alloc(u8, rlen) catch return -1;
        defer gpa.free(body);
        if (!fdReadExact(ssl.fd, body)) return 0;

        if (hdr[0] != 23 or rlen < 17) return -1;
        const Aead = std.crypto.aead.aes_gcm.Aes128Gcm;
        const ctext_len = rlen - Aead.tag_length;
        const plain = gpa.alloc(u8, ctext_len) catch return -1;
        defer gpa.free(plain);

        var nonce = ssl.client_app_iv;
        const seq_be = std.mem.toBytes(std.mem.nativeToBig(u64, ssl.read_seq));
        for (0..8) |i| nonce[12 - 8 + i] ^= seq_be[i];
        ssl.read_seq += 1;

        Aead.decrypt(
            plain,
            body[0..ctext_len],
            body[ctext_len..][0..Aead.tag_length].*,
            &hdr,
            nonce,
            ssl.client_app_key,
        ) catch return -1;

        const trimmed = std.mem.trimEnd(u8, plain, "\x00");
        if (trimmed.len == 0) return -1;
        const inner_ct = trimmed[trimmed.len - 1];
        const content = trimmed[0 .. trimmed.len - 1];
        if (inner_ct == 21) return 0; // alert (close_notify)
        if (inner_ct != 23) continue;
        if (content.len == 0) continue;
        const copy_len = @min(content.len, @as(usize, @intCast(num)));
        @memcpy(out_buf[0..copy_len], content[0..copy_len]);
        return @intCast(copy_len);
    }
}

fn simSSL_write(ssl_raw: ?*anyopaque, buf_raw: ?*const anyopaque, num: c_int) callconv(.c) c_int {
    const ssl: *SimSsl = @ptrCast(@alignCast(ssl_raw orelse return -1));
    if (!ssl.handshake_ok or num <= 0) return -1;
    const in_buf: [*]const u8 = @ptrCast(buf_raw orelse return -1);
    const len: usize = @intCast(num);
    const gpa = std.heap.c_allocator;

    const rec = encryptTls13Record(gpa, ssl.server_app_key, ssl.server_app_iv, ssl.write_seq, 23, in_buf[0..len]) orelse return -1;
    defer gpa.free(rec);
    ssl.write_seq += 1;
    if (!fdWriteAll(ssl.fd, rec)) return -1;
    return num;
}

fn simSSL_shutdown(ssl_raw: ?*anyopaque) callconv(.c) c_int {
    const ssl: *SimSsl = @ptrCast(@alignCast(ssl_raw orelse return 0));
    if (!ssl.handshake_ok) return 1;
    const gpa = std.heap.c_allocator;
    const alert = [_]u8{ 1, 0 }; // warning, close_notify
    if (encryptTls13Record(gpa, ssl.server_app_key, ssl.server_app_iv, ssl.write_seq, 21, &alert)) |rec| {
        defer gpa.free(rec);
        ssl.write_seq += 1;
        _ = fdWriteAll(ssl.fd, rec);
    }
    return 1;
}

comptime {
    if (backend_options.bundled and backend_options.ssl == .openssl) {
        @export(&simTLS_server_method, .{ .name = "TLS_server_method" });
        @export(&simSSL_CTX_new, .{ .name = "SSL_CTX_new" });
        @export(&simSSL_CTX_free, .{ .name = "SSL_CTX_free" });
        @export(&simBIO_new_mem_buf, .{ .name = "BIO_new_mem_buf" });
        @export(&simBIO_free, .{ .name = "BIO_free" });
        @export(&simPEM_read_bio_X509, .{ .name = "PEM_read_bio_X509" });
        @export(&simX509_free, .{ .name = "X509_free" });
        @export(&simPEM_read_bio_PrivateKey, .{ .name = "PEM_read_bio_PrivateKey" });
        @export(&simEVP_PKEY_free, .{ .name = "EVP_PKEY_free" });
        @export(&simSSL_CTX_use_certificate, .{ .name = "SSL_CTX_use_certificate" });
        @export(&simSSL_CTX_use_PrivateKey, .{ .name = "SSL_CTX_use_PrivateKey" });
        @export(&simSSL_new, .{ .name = "SSL_new" });
        @export(&simSSL_free, .{ .name = "SSL_free" });
        @export(&simSSL_set_fd, .{ .name = "SSL_set_fd" });
        @export(&simSSL_accept, .{ .name = "SSL_accept" });
        @export(&simSSL_read, .{ .name = "SSL_read" });
        @export(&simSSL_write, .{ .name = "SSL_write" });
        @export(&simSSL_shutdown, .{ .name = "SSL_shutdown" });
    }
}
