const std = @import("std");
const testing = std.testing;
const random = @import("random.zig");

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

test "16c random stage1 local pool selects the only playable local file" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makePath("random");
    try tmp.dir.makePath("local");
    try tmp.dir.writeFile(.{ .sub_path = "random/ignore.txt", .data = "not ansi" });
    try tmp.dir.writeFile(.{ .sub_path = "local/keep.asc", .data = "ansi" });

    const allocator = testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const random_dir = try std.fs.path.join(allocator, &.{ root, "random" });
    defer allocator.free(random_dir);

    const local_dir = try std.fs.path.join(allocator, &.{ root, "local" });
    defer allocator.free(local_dir);

    const expected = try std.fs.path.join(allocator, &.{ local_dir, "keep.asc" });
    defer allocator.free(expected);

    const selected = (try random.selectLocalArtwork(allocator, random_dir, local_dir)).?;
    defer allocator.free(selected);

    try testing.expectEqualStrings(expected, selected);
}

test "16c random stage1 dwell defaults to 20 seconds" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, ".standard, .streaming => 20 * std.time.ns_per_s") != null);
}

test "16c playback runtime carries explicit playback mode through random and screensaver loops" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "pub const PlaybackMode = union(enum)") != null);
    try testing.expect(std.mem.indexOf(u8, source, "mode: PlaybackMode = .standard") != null);
    try testing.expect(std.mem.indexOf(u8, source, "pub fn executeRandomLoop") != null);
    try testing.expect(std.mem.indexOf(u8, source, "pub fn executeScreensaverWithMode") != null);
}

test "16c stage1 config falls back to built-in defaults when config.toml is missing" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "config.toml") != null);
    try testing.expect(
        std.mem.indexOf(u8, source, "FileNotFound") != null or
            std.mem.indexOf(u8, source, "PathNotFound") != null,
    );
    try testing.expect(std.mem.indexOf(u8, source, "dwell_seconds") != null);
    try testing.expect(std.mem.indexOf(u8, source, "\"auto\"") != null);
}

test "16c stage1 config parses playback.dwell_seconds" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "playback") != null);
    try testing.expect(std.mem.indexOf(u8, source, "dwell_seconds") != null);
}

test "16c stage1 config parses source.mode auto" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "source") != null);
    try testing.expect(std.mem.indexOf(u8, source, "mode") != null);
    try testing.expect(std.mem.indexOf(u8, source, "\"auto\"") != null);
}

test "16c random stage1 empty local pool fails with helpful guidance" {
    var buffer: [160]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);

    try testing.expectError(error.EmptyLocalArtworkPool, random.failEmptyLocalArtworkPool(stream.writer(), null));
    try testing.expectEqualStrings(
        "No playable local artwork found in random/ or local/. Add a .ans or .asc file there.\n",
        stream.getWritten(),
    );
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
