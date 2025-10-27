const std = @import("std");
const ansilust = @import("ansilust");
const ir = ansilust.ir;
const ansi = ansilust.parsers.ansi;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "ansi: plain text rendering writes sequential characters" {
    const allocator = std.testing.allocator;
    const input = "Hello, World!";

    var doc = try ansi.parse(allocator, input);
    defer doc.deinit();

    try expectEqual(@as(u32, 80), doc.grid.width);
    try expectEqual(@as(u32, 25), doc.grid.height);

    try expectEqual(@as(u21, 'H'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'W'), (try doc.getCell(7, 0)).contents.scalar);
    try expectEqual(@as(u21, '!'), (try doc.getCell(12, 0)).contents.scalar);
}

test "ansi: document source format flagged as ansi" {
    const allocator = std.testing.allocator;
    const input = "plain text should mark source format";

    var doc = try ansi.parse(allocator, input);
    defer doc.deinit();

    try expectEqual(ir.SourceFormat.ansi, doc.source_format);
}

test "ansi: cp437 bytes translated to unicode scalars" {
    const allocator = std.testing.allocator;

    var buffer = [_]u8{ 0xB3, 0xCD, 0xBA }; // │ ─ ║ in CP437
    var doc = try ansi.parse(allocator, buffer[0..]);
    defer doc.deinit();

    // Expect Unicode equivalents of CP437 box drawing characters
    try expectEqual(@as(u21, 0x2502), (try doc.getCell(0, 0)).contents.scalar); // │
    try expectEqual(@as(u21, 0x2500), (try doc.getCell(1, 0)).contents.scalar); // ─
    try expectEqual(@as(u21, 0x2551), (try doc.getCell(2, 0)).contents.scalar); // ║
}
