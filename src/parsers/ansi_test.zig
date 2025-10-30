const std = @import("std");
const ansilust = @import("ansilust");
const ir = ansilust.ir;
const sauce = ir.sauce;
const ansi = @import("ansi.zig");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
const expectApproxEqRel = std.testing.expectApproxEqRel;
const expectError = std.testing.expectError;

const SauceExpectError = error{
    MissingSauce,
    MissingSauceAspect,
};

fn initDocument() !ir.Document {
    return try ir.Document.init(std.testing.allocator, 80, 25);
}

fn parseIntoDoc(doc: *ir.Document, input: []const u8) !void {
    var parser = ansi.Parser.init(std.testing.allocator, input, doc);
    defer parser.deinit();
    try parser.parse();
}

fn appendCommentLine(list: *std.ArrayList(u8), allocator: std.mem.Allocator, text: []const u8) !void {
    var line: [sauce.SAUCE_COMMENT_LINE_SIZE]u8 = undefined;
    @memset(&line, 0);
    const copy_len = @min(text.len, line.len);
    @memcpy(line[0..copy_len], text[0..copy_len]);
    try list.appendSlice(allocator, &line);
}

fn requireSauce(doc: *const ir.Document) SauceExpectError!*const ir.SauceRecord {
    if (doc.sauce_record) |*record| return record;
    return SauceExpectError.MissingSauce;
}

fn sauceDamagedRecord() [sauce.SAUCE_RECORD_SIZE]u8 {
    var record = buildSauceRecord();
    record[0] = 'X';
    return record;
}

fn sauceFixtureBody() []const u8 {
    return "Hello with SAUCE!\r\n";
}

fn sauceFixtureComments() []const []const u8 {
    return &[_][]const u8{ "Rendered with ansilust", "Visit ansilust.dev" };
}

fn buildSauceFixture(allocator: std.mem.Allocator, record: [sauce.SAUCE_RECORD_SIZE]u8) ![]u8 {
    var data = try std.ArrayList(u8).initCapacity(allocator, 256);
    errdefer data.deinit(allocator);

    try data.appendSlice(allocator, sauceFixtureBody());

    // SAUCE comment block (COMNT + 2 lines)
    try data.appendSlice(allocator, sauce.COMNT_ID);
    for (sauceFixtureComments()) |line| {
        try appendCommentLine(&data, allocator, line);
    }

    try data.appendSlice(allocator, &record);

    return try data.toOwnedSlice(allocator);
}

fn buildSauceRecord() [sauce.SAUCE_RECORD_SIZE]u8 {
    var record: [sauce.SAUCE_RECORD_SIZE]u8 = undefined;
    @memset(&record, 0);

    // Magic "SAUCE"
    @memcpy(record[0..5], sauce.SAUCE_ID);
    // Version "00"
    @memcpy(record[5..7], sauce.SAUCE_VERSION);

    // Title "Demo ANSI"
    const title = "Demo ANSI";
    @memcpy(record[7 .. 7 + title.len], title);

    // Author "Tom"
    const author = "Tom";
    @memcpy(record[42 .. 42 + author.len], author);

    // Group "Ansilust"
    const group = "Ansilust";
    @memcpy(record[62 .. 62 + group.len], group);

    // Date "20251026"
    const date = "20251026";
    @memcpy(record[82 .. 82 + date.len], date);

    // File size (little-endian u32)
    std.mem.writeInt(u32, record[90..94], @as(u32, 1024), .little);

    // File type: character (1)
    record[94] = @intFromEnum(sauce.FileType.character);
    // Data type: ANSI (1)
    record[95] = @intFromEnum(sauce.CharacterDataType.ansi);

    // tinfo1 (columns) = 80, tinfo2 (lines) = 25
    std.mem.writeInt(u16, record[96..98], 80, .little);
    std.mem.writeInt(u16, record[98..100], 25, .little);
    std.mem.writeInt(u16, record[100..102], 0, .little);
    std.mem.writeInt(u16, record[102..104], 0, .little);

    // Comment lines count
    record[104] = 2;

    // Flags: ice_colors=true, letter_spacing=9-pixel, aspect_ratio=legacy
    var flags: sauce.SauceFlags = .{};
    flags.ice_colors = true;
    flags.letter_spacing = 1;
    flags.aspect_ratio = 1;
    record[105] = @bitCast(flags);

    // Font name "IBM VGA"
    const font_name = "IBM VGA";
    @memcpy(record[106 .. 106 + font_name.len], font_name);

    return record;
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

test "ansi: cursor positioning with CSI H" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "Hello\x1B[3;5H!\x1B[1;1H*");

    try expectEqual(@as(u21, '!'), (try doc.getCell(4, 2)).contents.scalar);
    try expectEqual(@as(u21, '*'), (try doc.getCell(0, 0)).contents.scalar);
}

fn expectSauceDocDefaults(doc: *const ir.Document) !void {
    const record = try requireSauce(doc);
    try expectEqualStrings("Demo ANSI", record.title);
    try expectEqualStrings("Tom", record.author);
    try expectEqualStrings("Ansilust", record.group);
    try expectEqualStrings("20251026", record.date);
    try expectEqual(@as(u16, 80), record.tinfo1);
    try expectEqual(@as(u16, 25), record.tinfo2);
    try expectEqual(@as(u32, 1024), record.file_size);
    try expectEqual(@intFromEnum(sauce.FileType.character), @intFromEnum(record.file_type));
    try expectEqual(@as(u8, @intFromEnum(sauce.CharacterDataType.ansi)), record.data_type);

    try expect(record.flags.ice_colors);
    try expectEqual(@as(u8, 9), record.flags.getLetterSpacing());
    try expectApproxEqRel(@as(f32, 1.35), record.flags.getAspectRatio().?, 0.0001);
    try expectEqualStrings("IBM VGA", record.font_name);

    try expectEqual(@as(u8, 2), record.comment_lines);
    try expectEqual(@as(usize, 2), record.comments.len);

    const comments = sauceFixtureComments();
    var i: usize = 0;
    while (i < comments.len) : (i += 1) {
        try expectEqualStrings(comments[i], record.comments[i]);
    }

    try expectEqual(ir.SourceFormat.ansi, doc.source_format);
    try expectEqual(@as(u8, 9), doc.letter_spacing);
    try expectApproxEqRel(@as(f32, 1.35), doc.aspect_ratio orelse return SauceExpectError.MissingSauceAspect, 0.0001);
    try expect(doc.ice_colors);
}

test "ansi: tab (HT) advances cursor to next multiple of 8" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "A\tB\tC");

    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'B'), (try doc.getCell(8, 0)).contents.scalar);
    try expectEqual(@as(u21, 'C'), (try doc.getCell(16, 0)).contents.scalar);
}

test "ansi: CSI H positions cursor using 1-based coordinates" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "Hello\x1B[3;5H!\x1B[1;1H*");

    try expectEqual(@as(u21, '*'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'e'), (try doc.getCell(1, 0)).contents.scalar);
    try expectEqual(@as(u21, '!'), (try doc.getCell(4, 2)).contents.scalar);
}

test "ansi: CSI C and D move cursor horizontally" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[10C?\x1B[5D!");

    try expectEqual(@as(u21, '?'), (try doc.getCell(10, 0)).contents.scalar);
    try expectEqual(@as(u21, '!'), (try doc.getCell(6, 0)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(0, 0)).contents.scalar);
}

test "ansi: CSI s and u save and restore cursor" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "AB\x1B[sC\x1B[4;4H!\x1B[uD");

    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'B'), (try doc.getCell(1, 0)).contents.scalar);
    try expectEqual(@as(u21, 'D'), (try doc.getCell(2, 0)).contents.scalar);
    try expectEqual(@as(u21, '!'), (try doc.getCell(3, 3)).contents.scalar);
}

test "ansi: cursor movement clamps within document bounds" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "\x1B[999;999H*\x1B[0;0H!");

    try expectEqual(@as(u21, '*'), (try doc.getCell(doc.grid.width - 1, doc.grid.height - 1)).contents.scalar);
    try expectEqual(@as(u21, '!'), (try doc.getCell(0, 0)).contents.scalar);
}

test "ansi: CSI J clears from cursor to end of display" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "AAAA\nBBBB\nCCCC\x1B[2;2H\x1B[J");

    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'B'), (try doc.getCell(0, 1)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(2, 1)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(0, 2)).contents.scalar);
}

test "ansi: CSI 2J clears entire display" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "AAAA\nBBBB\nCCCC\x1B[2J");

    try expectEqual(@as(u21, ' '), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(0, 1)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(0, 2)).contents.scalar);
}

test "ansi: CSI K clears from cursor to end of line" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "ABCDEFG\x1B[1;4H\x1B[KX");

    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'B'), (try doc.getCell(1, 0)).contents.scalar);
    try expectEqual(@as(u21, 'C'), (try doc.getCell(2, 0)).contents.scalar);
    try expectEqual(@as(u21, 'X'), (try doc.getCell(3, 0)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(4, 0)).contents.scalar);
}

test "ansi: SUB (0x1A) terminates parsing" {
    var doc = try initDocument();
    defer doc.deinit();

    try parseIntoDoc(&doc, "Before\x1AAfter");

    try expectEqual(@as(u21, 'e'), (try doc.getCell(5, 0)).contents.scalar);
    try expectEqual(@as(u21, ' '), (try doc.getCell(6, 0)).contents.scalar);
}

test "ansi: SAUCE metadata is parsed and applied" {
    var doc = try initDocument();
    defer doc.deinit();

    const record = buildSauceRecord();
    const data = try buildSauceFixture(std.testing.allocator, record);
    defer std.testing.allocator.free(data);

    try parseIntoDoc(&doc, data);

    try expectSauceDocDefaults(&doc);
}

test "ansi: invalid SAUCE record is ignored" {
    var doc = try initDocument();
    defer doc.deinit();

    const record = sauceDamagedRecord();
    const data = try buildSauceFixture(std.testing.allocator, record);
    defer std.testing.allocator.free(data);

    try parseIntoDoc(&doc, data);

    try expectError(SauceExpectError.MissingSauce, expectSauceDocDefaults(&doc));
}
