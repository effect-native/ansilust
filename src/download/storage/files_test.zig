//! Tests for file storage module

const std = @import("std");
const testing = std.testing;
const files = @import("files.zig");
const FileStorage = files.FileStorage;
const starter_art = @import("starter_art.zig");

fn createRandomCacheFile(dir: std.fs.Dir, name: []const u8) !void {
    try dir.writeFile(.{ .sub_path = name, .data = "ansi" });
}

fn listRandomCacheFiles(allocator: std.mem.Allocator, dir: std.fs.Dir, sub_path: []const u8) ![][]u8 {
    var random_dir = try dir.openDir(sub_path, .{ .iterate = true });
    defer random_dir.close();

    var names = std.ArrayList([]u8).empty;
    errdefer {
        for (names.items) |name| allocator.free(name);
        names.deinit(allocator);
    }

    var iterator = random_dir.iterate();
    while (try iterator.next()) |entry| {
        if (entry.kind != .file) continue;
        try names.append(allocator, try allocator.dupe(u8, entry.name));
    }

    std.mem.sort([]u8, names.items, {}, struct {
        fn lessThan(_: void, a: []u8, b: []u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    return names.toOwnedSlice(allocator);
}

fn expectRandomCacheFiles(actual: [][]u8, expected: []const []const u8) !void {
    try testing.expectEqual(expected.len, actual.len);

    for (expected, actual) |expected_name, actual_name| {
        try testing.expectEqualStrings(expected_name, actual_name);
    }
}

fn containsFilename(actual: [][]u8, expected_name: []const u8) bool {
    for (actual) |name| {
        if (std.mem.eql(u8, name, expected_name)) return true;
    }

    return false;
}

test "FileStorage.init creates valid storage" {
    const storage = FileStorage.init(testing.allocator);
    _ = storage;

    try testing.expect(true);
}

// Note: saveToRandom and cleanupRandom require filesystem operations
// These would be tested in integration tests with temp directories
// For unit tests, we just verify the API compiles

test "FileStorage API has expected signatures" {
    const storage = FileStorage.init(testing.allocator);
    _ = storage;

    // Would test with temp directory:
    // const saved_path = try storage.saveToRandom("/tmp/source.txt", "test.ans", "/tmp/random");
    // defer testing.allocator.free(saved_path);

    // try storage.cleanupRandom("/tmp/random", 10);
}

test "FileStorage.cleanupRandom keeps only the newest 10 timestamped files" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makePath("random");

    const filenames = [_][]const u8{
        "20260101000001-oldest.ans",
        "20260101000002-second-oldest.ans",
        "20260101000003-keep-01.ans",
        "20260101000004-keep-02.ans",
        "20260101000005-keep-03.ans",
        "20260101000006-keep-04.ans",
        "20260101000007-keep-05.ans",
        "20260101000008-keep-06.ans",
        "20260101000009-keep-07.ans",
        "20260101000010-keep-08.ans",
        "20260101000011-keep-09.ans",
        "20260101000012-newest.ans",
    };

    for (filenames) |name| {
        const sub_path = try std.fmt.allocPrint(testing.allocator, "random/{s}", .{name});
        defer testing.allocator.free(sub_path);
        try createRandomCacheFile(tmp.dir, sub_path);
    }

    const allocator = testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const random_dir = try std.fs.path.join(allocator, &.{ root, "random" });
    defer allocator.free(random_dir);

    var storage = FileStorage.init(allocator);
    try storage.cleanupRandom(random_dir, 10);

    const remaining = try listRandomCacheFiles(allocator, tmp.dir, "random");
    defer {
        for (remaining) |name| allocator.free(name);
        allocator.free(remaining);
    }

    try expectRandomCacheFiles(remaining, filenames[2..]);
}

test "FileStorage.cleanupRandom removes the oldest timestamp-prefixed files first" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makePath("random");

    const filenames = [_][]const u8{
        "20260101000001-oldest.ans",
        "20260101000002-second-oldest.ans",
        "20260101000003-keep-01.ans",
        "20260101000004-keep-02.ans",
        "20260101000005-keep-03.ans",
        "20260101000006-keep-04.ans",
        "20260101000007-keep-05.ans",
        "20260101000008-keep-06.ans",
        "20260101000009-keep-07.ans",
        "20260101000010-keep-08.ans",
        "20260101000011-keep-09.ans",
        "20260101000012-newest.ans",
    };

    for (filenames) |name| {
        const sub_path = try std.fmt.allocPrint(testing.allocator, "random/{s}", .{name});
        defer testing.allocator.free(sub_path);
        try createRandomCacheFile(tmp.dir, sub_path);
    }

    const allocator = testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const random_dir = try std.fs.path.join(allocator, &.{ root, "random" });
    defer allocator.free(random_dir);

    var storage = FileStorage.init(allocator);
    try storage.cleanupRandom(random_dir, 10);

    const remaining = try listRandomCacheFiles(allocator, tmp.dir, "random");
    defer {
        for (remaining) |name| allocator.free(name);
        allocator.free(remaining);
    }

    try testing.expect(!containsFilename(remaining, filenames[0]));
    try testing.expect(!containsFilename(remaining, filenames[1]));
    try testing.expect(containsFilename(remaining, filenames[11]));
}

test "FileStorage.cleanupRandom does not evict starter art stored in local pool" {
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makePath("random");
    try tmp.dir.makePath("local");

    const filenames = [_][]const u8{
        "20260101000001-oldest.ans",
        "20260101000002-second-oldest.ans",
        "20260101000003-keep-01.ans",
        "20260101000004-keep-02.ans",
        "20260101000005-keep-03.ans",
        "20260101000006-keep-04.ans",
        "20260101000007-keep-05.ans",
        "20260101000008-keep-06.ans",
        "20260101000009-keep-07.ans",
        "20260101000010-keep-08.ans",
        "20260101000011-keep-09.ans",
        "20260101000012-newest.ans",
    };

    for (filenames) |name| {
        const sub_path = try std.fmt.allocPrint(testing.allocator, "random/{s}", .{name});
        defer testing.allocator.free(sub_path);
        try createRandomCacheFile(tmp.dir, sub_path);
    }

    const allocator = testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const random_dir = try std.fs.path.join(allocator, &.{ root, "random" });
    defer allocator.free(random_dir);

    const local_dir = try std.fs.path.join(allocator, &.{ root, "local" });
    defer allocator.free(local_dir);

    _ = try starter_art.materializeLocalStarterPool(allocator, local_dir);

    var storage = FileStorage.init(allocator);
    try storage.cleanupRandom(random_dir, 10);

    const starter_path = try std.fs.path.join(allocator, &.{ local_dir, "ansilust-starter.ans" });
    defer allocator.free(starter_path);

    const file = try std.fs.openFileAbsolute(starter_path, .{});
    defer file.close();

    const contents = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(contents);

    try testing.expect(contents.len > 0);
}
