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

    // SGR 31 (Red) → DOS palette 4, bold converts to 12 (bright red)
    // SGR 44 (Blue bg) → DOS palette 1
    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 12 }, // Bright red (bold applied)
        ir.Color{ .palette = 1 }, // Blue background
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

    // SGR 31 (Red) → DOS palette 4
    // SGR 44 (Blue bg) → DOS palette 1
    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 4 }, // Red foreground
        ir.Color{ .palette = 1 }, // Blue background
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

    // SGR 93 (Bright yellow) → DOS palette 14
    // SGR 104 (Bright blue bg) → DOS palette 9
    try expectCellStyle(
        &doc,
        0,
        0,
        ir.Color{ .palette = 14 }, // Yellow foreground
        ir.Color{ .palette = 9 }, // Light blue background
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
        ir.Color{ .rgb = .{ .r = 0, .g = 255, .b = 215 } }, // xterm color 50 is RGB(0,255,215)
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

    // ESC[31;999XmY - non-digit 'X' in parameter position aborts CSI sequence
    // The 'X' is treated as a CSI command (unknown, so ignored), then "mY" are written
    // Since the CSI was aborted, SGR was never applied, so 'Y' gets default colors
    try parseIntoDoc(&doc, "\x1B[31;999XmY");

    // First char 'm' should be at (0,0) with default style
    try expectEqual(@as(u21, 'm'), (try doc.getCell(0, 0)).contents.scalar);

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

    try expectEqual(@as(u21, 0x2502), (try doc.getCell(0, 0)).contents.scalar); // │ light vertical
    try expectEqual(@as(u21, 0x2550), (try doc.getCell(1, 0)).contents.scalar); // ═ double horizontal (0xCD)
    try expectEqual(@as(u21, 0x2551), (try doc.getCell(2, 0)).contents.scalar); // ║ double vertical
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

test "ansi: SAUCE flags applied to document" {
    var doc = try initDocument();
    defer doc.deinit();

    // Minimal test: SAUCE with flags, no comments
    var sauce_record: [128]u8 = undefined;
    @memset(&sauce_record, 0);

    // SAUCE magic
    @memcpy(sauce_record[0..5], "SAUCE");
    @memcpy(sauce_record[5..7], "00");

    // Flags at offset 105: ice_colors=true, letter_spacing=9-pixel, aspect_ratio=legacy
    // Bit layout: [7:5]=reserved, [4:3]=aspect_ratio, [2:1]=letter_spacing, [0]=ice_colors
    sauce_record[105] = 0b00001011; // ice=1, spacing=1 (9px), aspect=1 (1.35)

    var input_buffer: [130]u8 = undefined;
    input_buffer[0] = 'X';
    input_buffer[1] = 0x1A;
    @memcpy(input_buffer[2..], &sauce_record);

    try parseIntoDoc(&doc, &input_buffer);

    // Verify SAUCE was detected and parsed
    try expect(doc.sauce_record != null);

    // Verify flags were applied
    try expectEqual(true, doc.ice_colors);
    try expectEqual(@as(u8, 9), doc.letter_spacing);
    try expectEqual(@as(f32, 1.35), doc.aspect_ratio);
}

test "ansi: invalid SAUCE record is ignored" {
    var doc = try initDocument();
    defer doc.deinit();

    // Corrupted SAUCE magic - should be "SAUCE" but we use "XAUCE"
    var bad_sauce: [128]u8 = undefined;
    @memset(&bad_sauce, 0);
    @memcpy(bad_sauce[0..5], "XAUCE"); // Bad magic
    @memcpy(bad_sauce[5..7], "00");

    var input_buffer: [130]u8 = undefined;
    input_buffer[0] = 'Y';
    input_buffer[1] = 0x1A;
    @memcpy(input_buffer[2..], &bad_sauce);

    try parseIntoDoc(&doc, &input_buffer);

    // Invalid SAUCE should be ignored - no sauce_record set
    try expect(doc.sauce_record == null);

    // Defaults remain unchanged
    try expectEqual(false, doc.ice_colors);
    try expectEqual(@as(u8, 8), doc.letter_spacing);
    try expectEqual(@as(?f32, null), doc.aspect_ratio);
}

test "ansi: SAUCE dimensions auto-resize document" {
    var doc = try initDocument();
    defer doc.deinit();

    // Verify initial dimensions
    const initial_dims = doc.getDimensions();
    try expectEqual(@as(u32, 80), initial_dims.width);
    try expectEqual(@as(u32, 25), initial_dims.height);

    // Create SAUCE with custom dimensions (100 cols × 50 lines)
    var sauce_record: [128]u8 = undefined;
    @memset(&sauce_record, 0);
    @memcpy(sauce_record[0..5], "SAUCE");
    @memcpy(sauce_record[5..7], "00");

    // File type: character (1), data type: ansi (1)
    sauce_record[94] = 1;
    sauce_record[95] = 1;

    // tinfo1 (columns) = 100, tinfo2 (lines) = 50 (little-endian u16)
    std.mem.writeInt(u16, sauce_record[96..98], 100, .little);
    std.mem.writeInt(u16, sauce_record[98..100], 50, .little);

    var input_buffer: [130]u8 = undefined;
    input_buffer[0] = 'A';
    input_buffer[1] = 0x1A;
    @memcpy(input_buffer[2..], &sauce_record);

    try parseIntoDoc(&doc, &input_buffer);

    // Verify SAUCE was detected
    try expect(doc.sauce_record != null);

    // Verify document was auto-resized to SAUCE dimensions
    const new_dims = doc.getDimensions();
    try expectEqual(@as(u32, 100), new_dims.width);
    try expectEqual(@as(u32, 50), new_dims.height);
}

test "ansi: grid auto-expands when content exceeds bounds" {
    var doc = try initDocument();
    defer doc.deinit();

    // Initial grid is 80x25
    const initial_dims = doc.getDimensions();
    try expectEqual(@as(u32, 80), initial_dims.width);
    try expectEqual(@as(u32, 25), initial_dims.height);

    // Write 30 lines of content (exceeds 25 line default)
    var input = std.ArrayList(u8).empty;
    defer input.deinit(std.testing.allocator);

    var line: usize = 1;
    while (line <= 30) : (line += 1) {
        try input.writer(std.testing.allocator).print("Line {d}\n", .{line});
    }

    try parseIntoDoc(&doc, input.items);

    // Grid should have auto-expanded to accommodate all 30 lines
    const new_dims = doc.getDimensions();
    try expectEqual(@as(u32, 80), new_dims.width); // Width unchanged
    try expect(new_dims.height >= 30); // Height expanded to fit content

    // Verify line 30 was written (at row 29, 0-indexed)
    const cell_29 = try doc.getCell(0, 29);
    try expect(cell_29.contents.scalar == 'L'); // "Line 30" starts with 'L'
}

// NUL Byte Handling Tests
// Inspired by: reference/sixteencolors/fire-43/US-JELLY.ANS (contains 5,723 NUL bytes as intentional spacing)
// Prior art: PabloDraw (Source/Pablo/Formats/Character/Types/Ansi.load.cs:481-483)
//   - PabloDraw treats NUL (0x00) as a printable character that advances the cursor
//   - Falls through to ReadChar() which writes character 0 to canvas and increments position
//   - Character 0 in CP437 is typically rendered as blank/invisible glyph
//
// Implementation note: NUL bytes should be written to the grid as scalar value 0,
// advancing the cursor position. They are NOT control characters to be ignored.

test "ANSI parser handles NUL byte as printable character" {
    var doc = try initDocument();
    defer doc.deinit();

    // Input: "A" + NUL + "B"
    const input = "A\x00B";
    try parseIntoDoc(&doc, input);

    // Cell 0: 'A'
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u21, 'A'), cell_0.contents.scalar);

    // Cell 1: NUL (scalar value 0)
    const cell_1 = try doc.getCell(1, 0);
    try expectEqual(@as(u21, 0), cell_1.contents.scalar);

    // Cell 2: 'B'
    const cell_2 = try doc.getCell(2, 0);
    try expectEqual(@as(u21, 'B'), cell_2.contents.scalar);
}

test "ANSI parser advances cursor on NUL byte" {
    var doc = try initDocument();
    defer doc.deinit();

    // Input: 3 consecutive NUL bytes followed by 'X'
    const input = "\x00\x00\x00X";
    try parseIntoDoc(&doc, input);

    // First 3 cells should be NUL
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u21, 0), cell_0.contents.scalar);

    const cell_1 = try doc.getCell(1, 0);
    try expectEqual(@as(u21, 0), cell_1.contents.scalar);

    const cell_2 = try doc.getCell(2, 0);
    try expectEqual(@as(u21, 0), cell_2.contents.scalar);

    // Fourth cell should be 'X' (cursor advanced 3 positions by NULs)
    const cell_3 = try doc.getCell(3, 0);
    try expectEqual(@as(u21, 'X'), cell_3.contents.scalar);
}

test "ANSI parser handles NUL bytes with ANSI escape sequences" {
    var doc = try initDocument();
    defer doc.deinit();

    // Input: Red foreground, NUL, 'A', reset
    const input = "\x1b[31m\x00A\x1b[0m";
    try parseIntoDoc(&doc, input);

    // Cell 0: NUL should be written (scalar value 0)
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u21, 0), cell_0.contents.scalar);

    // Cell 1: 'A' should be written after NUL
    const cell_1 = try doc.getCell(1, 0);
    try expectEqual(@as(u21, 'A'), cell_1.contents.scalar);
}

test "ANSI parser handles mixed NUL and space characters" {
    var doc = try initDocument();
    defer doc.deinit();

    // Input: space, NUL, space
    const input = " \x00 ";
    try parseIntoDoc(&doc, input);

    // Cell 0: space (0x20)
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u21, 0x20), cell_0.contents.scalar);

    // Cell 1: NUL (0x00)
    const cell_1 = try doc.getCell(1, 0);
    try expectEqual(@as(u21, 0x00), cell_1.contents.scalar);

    // Cell 2: space (0x20)
    const cell_2 = try doc.getCell(2, 0);
    try expectEqual(@as(u21, 0x20), cell_2.contents.scalar);
}

// OSC 8 Hyperlink Tests
// Reference: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
// Format: ESC ] 8 ; params ; URI ST
// where ST = ESC \ or BEL (0x07)

test "OSC 8: simple hyperlink without parameters" {
    var doc = try initDocument();
    defer doc.deinit();

    // Input: ESC ] 8 ; ; http://example.com ESC \ link text ESC ] 8 ; ; ESC \
    const input = "\x1b]8;;http://example.com\x1b\\Link\x1b]8;;\x1b\\";
    try parseIntoDoc(&doc, input);

    // Verify hyperlink was added to document
    try expectEqual(@as(usize, 1), doc.hyperlink_table.count());

    // Verify first hyperlink
    const link = doc.hyperlink_table.get(1);
    try expect(link != null);
    try expectEqualStrings("http://example.com", link.?.uri);
    try expect(link.?.params == null);

    // Verify cells have hyperlink ID set
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u21, 'L'), cell_0.contents.scalar);
    try expectEqual(@as(u32, 1), cell_0.hyperlink_id);

    const cell_3 = try doc.getCell(3, 0);
    try expectEqual(@as(u21, 'k'), cell_3.contents.scalar);
    try expectEqual(@as(u32, 1), cell_3.hyperlink_id);
}

test "OSC 8: hyperlink with id parameter" {
    var doc = try initDocument();
    defer doc.deinit();

    // Input: ESC ] 8 ; id=test123 ; http://example.com ESC \ text ESC ] 8 ; ; ESC \
    const input = "\x1b]8;id=test123;http://example.com\x1b\\text\x1b]8;;\x1b\\";
    try parseIntoDoc(&doc, input);

    // Verify hyperlink with params
    const link = doc.hyperlink_table.get(1);
    try expect(link != null);
    try expectEqualStrings("http://example.com", link.?.uri);
    try expect(link.?.params != null);
    try expectEqualStrings("id=test123", link.?.params.?);

    // Verify cells have hyperlink ID
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u32, 1), cell_0.hyperlink_id);
}

test "OSC 8: hyperlink end clears hyperlink ID" {
    var doc = try initDocument();
    defer doc.deinit();

    // Input: link, text1, end link, text2
    const input = "\x1b]8;;http://example.com\x1b\\A\x1b]8;;\x1b\\B";
    try parseIntoDoc(&doc, input);

    // Cell 0: 'A' with hyperlink
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u21, 'A'), cell_0.contents.scalar);
    try expectEqual(@as(u32, 1), cell_0.hyperlink_id);

    // Cell 1: 'B' without hyperlink
    const cell_1 = try doc.getCell(1, 0);
    try expectEqual(@as(u21, 'B'), cell_1.contents.scalar);
    try expectEqual(@as(u32, 0), cell_1.hyperlink_id);
}

test "OSC 8: multiple hyperlinks in document" {
    var doc = try initDocument();
    defer doc.deinit();

    // Two different hyperlinks
    const input = "\x1b]8;;http://first.com\x1b\\A\x1b]8;;\x1b\\B\x1b]8;;http://second.com\x1b\\C\x1b]8;;\x1b\\";
    try parseIntoDoc(&doc, input);

    // Should have 2 hyperlinks
    try expectEqual(@as(usize, 2), doc.hyperlink_table.count());

    // Cell 0: 'A' with first hyperlink
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u32, 1), cell_0.hyperlink_id);

    // Cell 1: 'B' with no hyperlink
    const cell_1 = try doc.getCell(1, 0);
    try expectEqual(@as(u32, 0), cell_1.hyperlink_id);

    // Cell 2: 'C' with second hyperlink
    const cell_2 = try doc.getCell(2, 0);
    try expectEqual(@as(u32, 2), cell_2.hyperlink_id);
}

test "OSC 8: hyperlink deduplication with same URI" {
    var doc = try initDocument();
    defer doc.deinit();

    // Same URL used twice
    const input = "\x1b]8;;http://example.com\x1b\\A\x1b]8;;\x1b\\\x1b]8;;http://example.com\x1b\\B\x1b]8;;\x1b\\";
    try parseIntoDoc(&doc, input);

    // Should only have 1 hyperlink (deduplicated)
    try expectEqual(@as(usize, 1), doc.hyperlink_table.count());

    // Both cells reference same hyperlink ID
    const cell_0 = try doc.getCell(0, 0);
    const cell_1 = try doc.getCell(1, 0);
    try expectEqual(@as(u32, 1), cell_0.hyperlink_id);
    try expectEqual(@as(u32, 1), cell_1.hyperlink_id);
}

test "OSC 8: hyperlink with BEL terminator" {
    var doc = try initDocument();
    defer doc.deinit();

    // Using BEL (0x07) instead of ESC \ as terminator
    const input = "\x1b]8;;http://example.com\x07Link\x1b]8;;\x07";
    try parseIntoDoc(&doc, input);

    // Verify hyperlink was parsed
    try expectEqual(@as(usize, 1), doc.hyperlink_table.count());

    const link = doc.hyperlink_table.get(1);
    try expect(link != null);
    try expectEqualStrings("http://example.com", link.?.uri);
}

test "OSC 8: hyperlink with colors and attributes" {
    var doc = try initDocument();
    defer doc.deinit();

    // Hyperlink + SGR color
    const input = "\x1b[31m\x1b]8;;http://example.com\x1b\\Red Link\x1b]8;;\x1b\\\x1b[0m";
    try parseIntoDoc(&doc, input);

    // Verify cell has both hyperlink and red color
    const cell_0 = try doc.getCell(0, 0);
    try expectEqual(@as(u21, 'R'), cell_0.contents.scalar);
    try expectEqual(@as(u32, 1), cell_0.hyperlink_id);
    // Red (ANSI 1) maps to DOS palette 4
    try expectEqual(@as(u8, 4), cell_0.fg_color.palette);
}

test "UTF8ANSI roundtrip: basic ASCII text" {
    // Test that UTF8-encoded ANSI (our renderer output) can be parsed back correctly
    var doc = try initDocument();
    defer doc.deinit();

    // This is UTF8ANSI with escape sequences (not CP437)
    const utf8ansi_input = "Hello\x1b[31mRed\x1b[0m";
    try parseIntoDoc(&doc, utf8ansi_input);

    // Check ASCII characters decoded correctly
    try expectEqual(@as(u21, 'H'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'e'), (try doc.getCell(1, 0)).contents.scalar);
    try expectEqual(@as(u21, 'l'), (try doc.getCell(2, 0)).contents.scalar);
    try expectEqual(@as(u21, 'l'), (try doc.getCell(3, 0)).contents.scalar);
    try expectEqual(@as(u21, 'o'), (try doc.getCell(4, 0)).contents.scalar);

    // Check color applied to "Red"
    const cell_r = try doc.getCell(5, 0);
    try expectEqual(@as(u21, 'R'), cell_r.contents.scalar);
    try expectEqual(@as(u8, 4), cell_r.fg_color.palette); // DOS Red
}

test "UTF8ANSI roundtrip: multi-byte UTF-8 characters" {
    // Test that multi-byte UTF-8 sequences are decoded correctly
    var doc = try initDocument();
    defer doc.deinit();

    // UTF-8 encoded emoji and symbols: "A" (1-byte) + "→" (3-byte U+2192) + "B" (1-byte)
    const utf8ansi_input = "A\xe2\x86\x92B";
    try parseIntoDoc(&doc, utf8ansi_input);

    // Check that we got 3 characters, not 5 bytes
    try expectEqual(@as(u21, 'A'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 0x2192), (try doc.getCell(1, 0)).contents.scalar); // → (rightwards arrow)
    try expectEqual(@as(u21, 'B'), (try doc.getCell(2, 0)).contents.scalar);

    // Verify source encoding is UTF-8, not CP437
    try expectEqual(ir.SourceEncoding.utf_8, (try doc.getCell(1, 0)).source_encoding);
}

test "UTF8ANSI roundtrip: mixed UTF-8 and ANSI escapes" {
    // Real-world case: UTF8ANSI output from our renderer
    var doc = try initDocument();
    defer doc.deinit();

    // Mix of UTF-8 text and SGR color codes
    const utf8ansi_input = "\x1b[32mTest\xe2\x9c\x93\x1b[0m"; // Green "Test✓" (U+2713 checkmark)
    try parseIntoDoc(&doc, utf8ansi_input);

    // All 5 chars should be green
    const cell_t = try doc.getCell(0, 0);
    const cell_checkmark = try doc.getCell(4, 0);

    try expectEqual(@as(u21, 'T'), cell_t.contents.scalar);
    try expectEqual(@as(u21, 0x2713), cell_checkmark.contents.scalar); // ✓
    try expectEqual(@as(u8, 2), cell_t.fg_color.palette); // DOS Green
    try expectEqual(@as(u8, 2), cell_checkmark.fg_color.palette); // DOS Green
}

// Ansimation Tests
// Ansimation files contain multiple frames separated by ESC[2J (clear screen) and ESC[1;1H (cursor home).
// We should detect ansimation and stop after parsing the first frame to avoid:
// 1. Excessive memory usage (grid expansion for each frame)
// 2. Parser hanging/freezing on large multi-frame files
//
// Detection heuristic: ESC[2J followed by content, then ESC[1;1H = frame boundary

test "Ansimation: detect and stop after first frame" {
    var doc = try initDocument();
    defer doc.deinit();

    // Simulated ansimation: clear screen, frame 1 content, cursor home, frame 2 content
    // ESC[2J = clear screen
    // ESC[1;1H = cursor home
    // Frame 1: "ABC" at (0,0)
    // ESC[1;1H = NEW FRAME marker
    // Frame 2: "XYZ" at (0,0) - should NOT be parsed
    const ansimation_input = "\x1b[2J\x1b[1;1HABC\x1b[1;1HXYZ";
    try parseIntoDoc(&doc, ansimation_input);

    // Should only have frame 1 content
    const cell_0 = try doc.getCell(0, 0);
    const cell_1 = try doc.getCell(1, 0);
    const cell_2 = try doc.getCell(2, 0);

    try expectEqual(@as(u21, 'A'), cell_0.contents.scalar);
    try expectEqual(@as(u21, 'B'), cell_1.contents.scalar);
    try expectEqual(@as(u21, 'C'), cell_2.contents.scalar);

    // Cell 3 should be empty (not 'X' from frame 2)
    const cell_3 = try doc.getCell(3, 0);
    try expectEqual(@as(u21, ' '), cell_3.contents.scalar);
}

test "Ansimation: multiple cursor homes without clear screen should continue parsing" {
    var doc = try initDocument();
    defer doc.deinit();

    // NOT ansimation - just cursor movement within a single frame
    // No ESC[2J, so multiple ESC[1;1H commands should be treated as normal cursor positioning
    const input = "ABC\x1b[1;1HXYZ";
    try parseIntoDoc(&doc, input);

    // Should overwrite: X at (0,0), Y at (1,0), Z at (2,0)
    const cell_0 = try doc.getCell(0, 0);
    const cell_1 = try doc.getCell(1, 0);
    const cell_2 = try doc.getCell(2, 0);

    try expectEqual(@as(u21, 'X'), cell_0.contents.scalar);
    try expectEqual(@as(u21, 'Y'), cell_1.contents.scalar);
    try expectEqual(@as(u21, 'Z'), cell_2.contents.scalar);
}

test "Ansimation: clear screen alone should not stop parsing" {
    var doc = try initDocument();
    defer doc.deinit();

    // ESC[2J clears screen but preserves cursor position
    // Write "ABC" (cursor at 3,0), clear screen, write "XYZ" (at cursor position 3,0)
    const input = "ABC\x1b[2JXYZ";
    try parseIntoDoc(&doc, input);

    // After clear, first 3 cells should be cleared (spaces)
    const cell_0 = try doc.getCell(0, 0);
    const cell_1 = try doc.getCell(1, 0);
    const cell_2 = try doc.getCell(2, 0);

    try expectEqual(@as(u21, ' '), cell_0.contents.scalar);
    try expectEqual(@as(u21, ' '), cell_1.contents.scalar);
    try expectEqual(@as(u21, ' '), cell_2.contents.scalar);

    // XYZ should be written starting at cursor position (3,0)
    const cell_3 = try doc.getCell(3, 0);
    const cell_4 = try doc.getCell(4, 0);
    const cell_5 = try doc.getCell(5, 0);

    try expectEqual(@as(u21, 'X'), cell_3.contents.scalar);
    try expectEqual(@as(u21, 'Y'), cell_4.contents.scalar);
    try expectEqual(@as(u21, 'Z'), cell_5.contents.scalar);
}
