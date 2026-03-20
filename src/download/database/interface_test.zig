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

test "ArchiveDatabase.getRandomFile matches current hardcoded catalog contract" {
    var db = try ArchiveDatabase.init(testing.allocator);
    defer db.deinit();

    const first = try db.getRandomFile();
    const second = try db.getRandomFile();

    try testing.expectEqualStrings("mist1025", first.pack_name);
    try testing.expectEqualStrings("CXC-STICK.ASC", first.filename);
    try testing.expectEqualStrings("https://16colo.rs/pack/mist1025/raw/CXC-STICK.ASC", first.source_url);
    try testing.expectEqual(@as(u16, 2025), first.year);
    try testing.expectEqualStrings("CoaXCable", first.artist.?);
    try testing.expectEqualStrings("asc", first.extension);

    try testing.expectEqualStrings(first.pack_name, second.pack_name);
    try testing.expectEqualStrings(first.filename, second.filename);
    try testing.expectEqualStrings(first.source_url, second.source_url);
    try testing.expectEqual(first.year, second.year);
    try testing.expectEqualStrings(first.artist.?, second.artist.?);
    try testing.expectEqualStrings(first.extension, second.extension);
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
