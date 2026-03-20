const std = @import("std");
const testing = std.testing;

test "16c playback no longer shells out through raw cat" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "\"cat\"") == null);
}

test "16c playback routes artwork through parser and UTF8ANSI renderer" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "parsers") != null);
    try testing.expect(std.mem.indexOf(u8, source, "renderToUtf8Ansi") != null);
    try testing.expect(std.mem.indexOf(u8, source, "isatty") != null);
}

test "16c random stage1 local pool scans random and local directories" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "paths.random_dir") != null);
    try testing.expect(std.mem.indexOf(u8, source, "paths.local_dir") != null);
}

test "16c random stage1 local pool filters to playable ansi files" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, ".ans") != null);
    try testing.expect(std.mem.indexOf(u8, source, ".asc") != null);
}

test "16c random stage1 local pool is selected before remote fallback" {
    const source = @embedFile("random.zig");
    const remote_index = std.mem.indexOf(u8, source, "db.getRandomFile()") orelse return error.TestUnexpectedResult;
    const local_scan_index = std.mem.indexOf(u8, source, "paths.local_dir") orelse return error.TestUnexpectedResult;

    try testing.expect(local_scan_index < remote_index);
}
