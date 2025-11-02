//! Tests for database abstraction interface

const std = @import("std");
const testing = std.testing;
const interface = @import("interface.zig");
const ArchiveDatabase = interface.ArchiveDatabase;
const FileEntry = interface.FileEntry;

test "ArchiveDatabase.init creates hardcoded implementation" {
    var db = try ArchiveDatabase.init(testing.allocator);
    defer db.deinit();

    // Should have hardcoded implementation
    try testing.expect(db.impl == .hardcoded);
}

test "ArchiveDatabase.getRandomFile returns valid FileEntry" {
    var db = try ArchiveDatabase.init(testing.allocator);
    defer db.deinit();

    const file = try db.getRandomFile();

    // Verify required fields are present
    try testing.expect(file.pack_name.len > 0);
    try testing.expect(file.filename.len > 0);
    try testing.expect(file.source_url.len > 0);
    try testing.expect(file.extension.len > 0);
    try testing.expect(file.year > 1990);
    try testing.expect(file.year < 2030);

    // Verify URL format
    try testing.expect(std.mem.startsWith(u8, file.source_url, "https://16colo.rs/"));
}

test "ArchiveDatabase.getRandomFile returns different files" {
    var db = try ArchiveDatabase.init(testing.allocator);
    defer db.deinit();

    // Get multiple files and check for variety
    // (Probabilistic test: may occasionally fail if very unlucky with RNG)
    var files: [10]FileEntry = undefined;
    for (&files) |*file| {
        file.* = try db.getRandomFile();
    }

    // Check that we got at least 2 different files
    var unique_count: usize = 0;
    const first = files[0];
    for (files[1..]) |file| {
        if (!std.mem.eql(u8, file.filename, first.filename)) {
            unique_count += 1;
        }
    }

    // Expect at least some variety (probabilistic)
    try testing.expect(unique_count > 0);
}

test "ArchiveDatabase.searchFiles stub returns empty" {
    var db = try ArchiveDatabase.init(testing.allocator);
    defer db.deinit();

    const results = try db.searchFiles("test query");

    // Stub implementation should return empty
    try testing.expectEqual(@as(usize, 0), results.len);
}

test "ArchiveDatabase.getPack stub returns error" {
    var db = try ArchiveDatabase.init(testing.allocator);
    defer db.deinit();

    // Stub implementation should return error.NotImplemented
    try testing.expectError(error.NotImplemented, db.getPack("mist1025"));
}

test "ArchiveDatabase.listPacksByYear stub returns empty" {
    var db = try ArchiveDatabase.init(testing.allocator);
    defer db.deinit();

    const packs = try db.listPacksByYear(2025);

    // Stub implementation should return empty
    try testing.expectEqual(@as(usize, 0), packs.len);
}

test "FileEntry has expected structure" {
    const file = FileEntry{
        .pack_name = "test-pack",
        .filename = "test.ans",
        .source_url = "https://16colo.rs/pack/test-pack/test.ans",
        .year = 2025,
        .artist = "Test Artist",
        .extension = "ans",
    };

    try testing.expectEqualStrings("test-pack", file.pack_name);
    try testing.expectEqualStrings("test.ans", file.filename);
    try testing.expectEqualStrings("https://16colo.rs/pack/test-pack/test.ans", file.source_url);
    try testing.expectEqual(@as(u16, 2025), file.year);
    try testing.expectEqualStrings("Test Artist", file.artist.?);
    try testing.expectEqualStrings("ans", file.extension);
}

test "Pack has expected structure" {
    const pack = interface.Pack{
        .name = "test-pack",
        .year = 2025,
        .group_name = "test-group",
        .zip_url = "https://16colo.rs/archive/2025/test-pack.zip",
    };

    try testing.expectEqualStrings("test-pack", pack.name);
    try testing.expectEqual(@as(u16, 2025), pack.year);
    try testing.expectEqualStrings("test-group", pack.group_name.?);
    try testing.expectEqualStrings("https://16colo.rs/archive/2025/test-pack.zip", pack.zip_url);
}
