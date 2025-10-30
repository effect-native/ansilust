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

fn expectCellStyle(
    doc: *const ir.Document,
    x: u32,
    y: u32,
    expected_fg: ir.Color,
    expected_bg: ir.Color,
    expected_attrs: ir.AttributeFlags,
) !void {
    const cell = try doc.getCell(x, y);
    try expectEqual(expected_fg, cell.fg_color);
    try expectEqual(expected_bg, cell.bg_color);
    try expectEqual(expected_attrs.toRaw(), cell.attr_flags.toRaw());
}
test "ansi: SGR resets attributes and colors" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[31;44;1mA\x1B[0mB");

    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'B'), (try doc.getCell(1, 0)).contents.scalar);

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 1 },
        ir.Color{ .palette = 4 },
        ir.AttributeFlags.withBold(),
    );
    try expectCellStyle(
        &doc,
        1,
        0,
        ir.Color{ .palette = 7 },
        ir.Color{ .palette = 0 },
        ir.AttributeFlags.none(),
    );
}

test "ansi: SGR explicit defaults clear colors" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[31;44mA\x1B[39;49mB");

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 1 },
        ir.Color{ .palette = 4 },
        ir.AttributeFlags.none(),
    );
    try expectCellStyle(
        &doc,
        1,
        0,
        ir.Color{ .palette = 7 },
        ir.Color{ .palette = 0 },
        ir.AttributeFlags.none(),
    );
}

test "ansi: SGR bright colors map to high palettes" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[93;104mX");

    try expectEqual(@as(u21, 'X'), (try doc.getCell(0, 0)).contents.scalar);

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 11 },
        ir.Color{ .palette = 12 },
        ir.AttributeFlags.none(),
    );
}

test "ansi: SGR 256-color foreground consumes full sequence" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[38;5;196mR");

    try expectEqual(@as(u21, 'R'), (try doc.getCell(0, 0)).contents.scalar);

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },
        ir.Color{ .palette = 0 },
        ir.AttributeFlags.none(),
    );
}

test "ansi: SGR 256-color background consumes full sequence" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[48;5;50mG");

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 7 },
        ir.Color{ .rgb = .{ .r = 0, .g = 255, .b = 95 } },
        ir.AttributeFlags.none(),
    );
}

test "ansi: SGR truecolor foreground applies RGB" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[38;2;12;34;56mC");

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .rgb = .{ .r = 12, .g = 34, .b = 56 } },
        ir.Color{ .palette = 0 },
        ir.AttributeFlags.none(),
    );
}

test "ansi: SGR truecolor background applies RGB" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[48;2;200;150;100mD");

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 7 },
        ir.Color{ .rgb = .{ .r = 200, .g = 150, .b = 100 } },
        ir.AttributeFlags.none(),
    );
}

test "ansi: malformed SGR parameters leave style unchanged" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[31;BOOPSX");

    try expectEqual(@as(u21, 'X'), (try doc.getCell(0, 0)).contents.scalar);

    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 7 },
        ir.Color{ .palette = 0 },
        ir.AttributeFlags.none(),
    );
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
