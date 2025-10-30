const std = @import("std");
const ir = @import("../ir/lib.zig");
const ansi = @import("ansi.zig");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

fn initDocument() !ir.Document {
    return try ir.Document.init(std.testing.allocator, 80, 25);
}

fn parseIntoDoc(doc: *ir.Document, input: []const u8) !void {
    var parser = ansi.Parser.init(std.testing.allocator, input, doc);
    defer parser.deinit();
    try parser.parse();
}

test "ansi: plain text rendering writes sequential characters" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "Hello, World!");

    try expectEqual(@as(u32, 80), doc.grid.width);
    try expectEqual(@as(u32, 25), doc.grid.height);

    try expectEqual(@as(u21, 'H'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'W'), (try doc.getCell(7, 0)).contents.scalar);
    try expectEqual(@as(u21, '!'), (try doc.getCell(12, 0)).contents.scalar);
}

test "ansi: document source format flagged as ansi" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "plain text should mark source format");

    try expectEqual(ir.SourceFormat.ansi, doc.source_format);
}

test "ansi: cp437 bytes translated to unicode scalars" {
    var doc = try initDocument();
    defer doc.deinit();

    const buffer = [_]u8{ 0xB3, 0xCD, 0xBA };
    try parseIntoDoc(&doc, &buffer);

    try expectEqual(@as(u21, 0x2502), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 0x2500), (try doc.getCell(1, 0)).contents.scalar);
    try expectEqual(@as(u21, 0x2551), (try doc.getCell(2, 0)).contents.scalar);
}

test "ansi: newline (LF) advances row and resets column" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "Line1\nLine2");

    try expectEqual(@as(u21, '1'), (try doc.getCell(4, 0)).contents.scalar);
    try expectEqual(@as(u21, 'L'), (try doc.getCell(0, 1)).contents.scalar);
}

test "ansi: carriage return (CR) resets column to zero" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "AB\rC");

    try expectEqual(@as(u21, 'C'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'B'), (try doc.getCell(1, 0)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(2, 0)).contents.scalar);
}

test "ansi: tab (HT) advances cursor to next multiple of 8" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "A\tB\tC");

    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'B'), (try doc.getCell(8, 0)).contents.scalar);
    try expectEqual(@as(u21, 'C'), (try doc.getCell(16, 0)).contents.scalar);
}

test "ansi: SUB (0x1A) terminates parsing" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "Before\x1AAfter");

    try expectEqual(@as(u21, 'e'), (try doc.getCell(5, 0)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(6, 0)).contents.scalar);
}
