const std = @import("std");

pub const c = @import("curl_c");

pub fn globalInit(flags: c_long) !void {
    if (c.curl_global_init(flags) != c.CURLE_OK) {
        return error.CurlGlobalInitFailed;
    }
}

pub fn globalCleanup() void {
    c.curl_global_cleanup();
}

pub fn version() [:0]const u8 {
    return std.mem.span(c.curl_version());
}

test "curl_version_info metadata and protocols" {
    try globalInit(c.CURL_GLOBAL_DEFAULT);
    defer globalCleanup();

    const info_ptr = c.curl_version_info(c.CURLVERSION_NOW);
    try std.testing.expect(info_ptr != null);
    const info = info_ptr.*;

    try std.testing.expect(info.version != null);
    try std.testing.expectEqualStrings("8.23.1-DEV", std.mem.span(info.version));

    try std.testing.expect(info.protocols != null);
    var has_http = false;
    var has_ftp = false;
    var has_file = false;

    var i: usize = 0;
    while (info.protocols[i] != null) : (i += 1) {
        const proto = std.mem.span(info.protocols[i]);
        if (std.mem.eql(u8, proto, "http")) has_http = true;
        if (std.mem.eql(u8, proto, "ftp")) has_ftp = true;
        if (std.mem.eql(u8, proto, "file")) has_file = true;
    }

    try std.testing.expect(has_http);
    try std.testing.expect(has_ftp);
    try std.testing.expect(has_file);
}

test "CURLU url parsing" {
    const h = c.curl_url() orelse return error.CurlUrlInitFailed;
    defer c.curl_url_cleanup(h);

    const rc_set = c.curl_url_set(
        h,
        c.CURLUPART_URL,
        "https://example.com:8443/path/to/resource?query=1#frag",
        0,
    );
    try std.testing.expectEqual(@as(c.CURLUcode, c.CURLUE_OK), rc_set);

    const PartExpect = struct {
        part: c.CURLUPart,
        expected: []const u8,
    };
    const parts = [_]PartExpect{
        .{ .part = c.CURLUPART_SCHEME, .expected = "https" },
        .{ .part = c.CURLUPART_HOST, .expected = "example.com" },
        .{ .part = c.CURLUPART_PORT, .expected = "8443" },
        .{ .part = c.CURLUPART_PATH, .expected = "/path/to/resource" },
        .{ .part = c.CURLUPART_QUERY, .expected = "query=1" },
        .{ .part = c.CURLUPART_FRAGMENT, .expected = "frag" },
    };

    for (parts) |item| {
        var val: [*c]u8 = null;
        const rc_get = c.curl_url_get(h, item.part, &val, 0);
        try std.testing.expectEqual(@as(c.CURLUcode, c.CURLUE_OK), rc_get);
        defer c.curl_free(val);
        try std.testing.expect(val != null);
        try std.testing.expectEqualStrings(item.expected, std.mem.span(val));
    }
}
