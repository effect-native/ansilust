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
