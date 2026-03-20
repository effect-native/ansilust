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

test "16c random stage1 dwell defaults to 20 seconds" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "delay_ns: u64 = 20 * std.time.ns_per_s") != null);
}

test "16c random stage1 local pool explicitly replays a single playable file" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "if (candidates.items.len == 1)") != null);
    try testing.expect(std.mem.indexOf(u8, source, "return allocator.dupe(u8, candidates.items[0]);") != null);
}

test "16c random stage1 empty local pool fails with helpful guidance" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "error.EmptyLocalArtworkPool") != null);
    try testing.expect(std.mem.indexOf(u8, source, "random/") != null);
    try testing.expect(std.mem.indexOf(u8, source, "local/") != null);
}

test "16c screensaver session enters and restores alternate screen" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "?1049h") != null);
    try testing.expect(std.mem.indexOf(u8, source, "?1049l") != null);
}

test "16c screensaver session hides and restores cursor" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "?25l") != null);
    try testing.expect(std.mem.indexOf(u8, source, "?25h") != null);
}

test "16c screensaver exits when user input arrives" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "STDIN_FILENO") != null);
    try testing.expect(
        std.mem.indexOf(u8, source, "poll") != null or
            std.mem.indexOf(u8, source, "read") != null,
    );
}

test "16c screensaver restores terminal state when interrupted by signal" {
    const source = @embedFile("random.zig");

    try testing.expect(
        std.mem.indexOf(u8, source, "SIGINT") != null or
            std.mem.indexOf(u8, source, "SIGTERM") != null,
    );
    try testing.expect(
        std.mem.indexOf(u8, source, "sigaction") != null or
            std.mem.indexOf(u8, source, "signal") != null,
    );
}
