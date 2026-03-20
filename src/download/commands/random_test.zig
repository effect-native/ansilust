const std = @import("std");
const testing = std.testing;
const random = @import("random.zig");
const stage1_config = @import("stage1_config.zig");

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
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    const allocator = testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const config = try stage1_config.loadFromRoot(allocator, root, "config.toml");

    try testing.expectEqual(@as(u64, 20), config.playback.dwell_seconds);
    try testing.expectEqual(stage1_config.SourceMode.auto, config.source.mode);
}

test "16c stage1 config loads playback and source settings from config.toml" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(.{
        .sub_path = "config.toml",
        .data =
        \\[playback]
        \\dwell_seconds = 7
        \\[source]
        \\mode = "auto"
        ,
    });

    const allocator = testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const config = try stage1_config.loadFromRoot(allocator, root, "config.toml");

    try testing.expectEqual(@as(u64, 7), config.playback.dwell_seconds);
    try testing.expectEqual(stage1_config.SourceMode.auto, config.source.mode);
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

test "16c screensaver session writes terminal enter sequence" {
    var buffer: [64]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);

    try random.writeScreensaverEnter(stream.writer());

    try testing.expectEqualStrings("\x1b[?1049h\x1b[?25l", stream.getWritten());
}

test "16c screensaver session cleanup restores cursor and primary screen" {
    var buffer: [64]u8 = undefined;
    var stream = std.io.fixedBufferStream(&buffer);

    try random.writeScreensaverLeave(stream.writer());

    try testing.expectEqualStrings("\x1b[?25h\x1b[?1049l", stream.getWritten());
}

test "16c screensaver exits when user input arrives" {
    const source = @embedFile("random.zig");

    try testing.expect(std.mem.indexOf(u8, source, "STDIN_FILENO") != null);
    try testing.expect(
        std.mem.indexOf(u8, source, "poll") != null or
            std.mem.indexOf(u8, source, "read") != null,
    );
}
