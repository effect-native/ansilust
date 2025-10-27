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

test "ansi: newline (LF) advances row and resets column" {
    const allocator = std.testing.allocator;
    const input = "Line1\nLine2";

    var doc = try ansi.parse(allocator, input);
    defer doc.deinit();

    // '1' is at (4, 0)
    try expectEqual(@as(u21, '1'), (try doc.getCell(4, 0)).contents.scalar);

    // 'L' of Line2 is at (0, 1)
    try expectEqual(@as(u21, 'L'), (try doc.getCell(0, 1)).contents.scalar);
}

test "ansi: carriage return (CR) resets column to zero" {
    const allocator = std.testing.allocator;
    const input = "AB\rC"; // C should overwrite A

    var doc = try ansi.parse(allocator, input);
    defer doc.deinit();

    // A is written at (0,0), B at (1,0). CR moves cursor to (0,0). C overwrites A.
    try expectEqual(@as(u21, 'C'), (try doc.getCell(0, 0)).contents.scalar); // C overwrites A
    try expectEqual(@as(u21, 'B'), (try doc.getCell(1, 0)).contents.scalar); // B remains
    try expectEqual(@as(u21, ' '), (try doc.getCell(2, 0)).contents.scalar); // Nothing written at (2,0)
}

test "ansi: tab (HT) advances cursor to next multiple of 8" {
    const allocator = std.testing.allocator;
    const input = "A\tB\tC";

    var doc = try ansi.parse(allocator, input);
    defer doc.deinit();

    // 'A' at (0, 0)
    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);

    // 'B' should be at column 8 (next multiple of 8 after 1)
    try expectEqual(@as(u21, 'B'), (try doc.getCell(8, 0)).contents.scalar);

    // 'C' should be at column 16 (next multiple of 8 after 9)
    try expectEqual(@as(u21, 'C'), (try doc.getCell(16, 0)).contents.scalar);
}

test "ansi: SUB (0x1A) terminates parsing" {
    const allocator = std.testing.allocator;
    const input = "Before\x1AAfter";

    var doc = try ansi.parse(allocator, input);
    defer doc.deinit();

    // Should parse up to SUB
    try expectEqual(@as(u21, 'e'), (try doc.getCell(5, 0)).contents.scalar);

    // Should NOT parse after SUB. Cell (6, 0) should be default (space).
    try expectEqual(@as(u21, ' '), (try doc.getCell(6, 0)).contents.scalar);
}
