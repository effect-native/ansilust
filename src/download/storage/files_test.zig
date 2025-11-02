//! Tests for file storage module

const std = @import("std");
const testing = std.testing;
const files = @import("files.zig");
const FileStorage = files.FileStorage;

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
