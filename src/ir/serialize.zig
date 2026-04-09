//! Ansilust IR - Serialization Module
//!
//! Binary serialization/deserialization for IR documents.
//! Format: "ANSILUSTIR\0" header + versioned sections.
//!
const std = @import("std");
const errors = @import("errors.zig");
const attributes = @import("attributes.zig");
const cell_grid = @import("cell_grid.zig");
const color = @import("color.zig");
const document = @import("document.zig");
const encoding = @import("encoding.zig");

/// Magic header for serialized IR files
pub const MAGIC_HEADER = "ANSILUSTIR\x00";

/// Current format version
pub const FORMAT_VERSION: u16 = 1;

/// Serialize document to writer.
pub fn serialize(doc: *const document.Document, writer: anytype) errors.Error!void {
    try writeAll(writer, MAGIC_HEADER);
    try writeInt(writer, u16, FORMAT_VERSION);

    const dims = doc.getDimensions();
    try writeInt(writer, u32, dims.width);
    try writeInt(writer, u32, dims.height);
    try writeInt(writer, u16, @intCast(@intFromEnum(doc.source_format)));
    try writeInt(writer, u16, doc.default_encoding.toMIBenum());
    try writeInt(writer, u8, doc.letter_spacing);
    try writeInt(writer, u8, @intFromBool(doc.aspect_ratio != null));
    if (doc.aspect_ratio) |aspect_ratio| {
        try writeInt(writer, u32, @bitCast(aspect_ratio));
    }
    try writeInt(writer, u8, @intFromBool(doc.ice_colors));

    try writeInt(writer, u32, @intCast(doc.grapheme_pool.graphemes.items.len));
    for (doc.grapheme_pool.graphemes.items) |grapheme| {
        try writeBytes(writer, grapheme);
    }

    try writeInt(writer, u32, @intCast(doc.hyperlink_table.hyperlinks.items.len));
    for (doc.hyperlink_table.hyperlinks.items) |link| {
        try writeInt(writer, u32, link.id);
        try writeBytes(writer, link.uri);
        try writeInt(writer, u8, @intFromBool(link.params != null));
        if (link.params) |params| {
            try writeBytes(writer, params);
        }
    }

    try writeInt(writer, u32, @intCast(doc.palette_table.palettes.items.len));
    for (doc.palette_table.palettes.items) |palette| {
        try writeInt(writer, u32, palette.id);
        try writeInt(writer, u32, @intCast(palette.colors.len));
        for (palette.colors) |rgb| {
            try writeInt(writer, u8, rgb.r);
            try writeInt(writer, u8, rgb.g);
            try writeInt(writer, u8, rgb.b);
        }
    }

    var iter = doc.grid.iterCells();
    while (iter.next()) |item| {
        const cell = item.cell;
        try writeInt(writer, u32, cell.source_offset);
        try writeInt(writer, u32, cell.source_len);
        try writeInt(writer, u16, cell.source_encoding.toMIBenum());
        try writeInt(writer, u8, switch (cell.contents) {
            .scalar => 0,
            .grapheme => 1,
        });
        switch (cell.contents) {
            .scalar => |scalar| try writeInt(writer, u32, scalar),
            .grapheme => |grapheme| try writeInt(writer, u32, grapheme),
        }
        try writeColor(writer, cell.fg_color);
        try writeColor(writer, cell.bg_color);
        try writeInt(writer, u32, cell.attr_flags.toRaw());
        try writeInt(writer, u8, @intFromEnum(cell.wide_flag));
        try writeInt(writer, u32, cell.hyperlink_id);
    }
}

/// Deserialize document from reader.
pub fn deserialize(allocator: std.mem.Allocator, reader: anytype) errors.Error!document.Document {
    var magic: [MAGIC_HEADER.len]u8 = undefined;
    readNoEof(reader, &magic) catch |err| return mapReadError(err);
    if (!std.mem.eql(u8, &magic, MAGIC_HEADER)) {
        return error.SerializationFailed;
    }

    const version = try readInt(reader, u16);
    if (version != FORMAT_VERSION) return error.SerializationFailed;

    const width = try readInt(reader, u32);
    const height = try readInt(reader, u32);
    var doc = try document.Document.init(allocator, width, height);
    errdefer doc.deinit();

    const source_format_raw = try readInt(reader, u16);
    doc.source_format = std.meta.intToEnum(document.SourceFormat, source_format_raw) catch {
        return error.SerializationFailed;
    };
    doc.default_encoding = encoding.SourceEncoding.fromMIBenum(try readInt(reader, u16)) catch {
        return error.SerializationFailed;
    };
    doc.letter_spacing = try readInt(reader, u8);
    const has_aspect_ratio = try readInt(reader, u8) != 0;
    doc.aspect_ratio = if (has_aspect_ratio)
        @as(f32, @bitCast(try readInt(reader, u32)))
    else
        null;
    doc.ice_colors = try readInt(reader, u8) != 0;

    const grapheme_count = try readInt(reader, u32);
    var grapheme_index: u32 = 0;
    while (grapheme_index < grapheme_count) : (grapheme_index += 1) {
        const grapheme = try readBytesAlloc(allocator, reader);
        defer allocator.free(grapheme);
        _ = try doc.internGrapheme(grapheme);
    }

    const hyperlink_count = try readInt(reader, u32);
    var hyperlink_index: u32 = 0;
    while (hyperlink_index < hyperlink_count) : (hyperlink_index += 1) {
        const id = try readInt(reader, u32);
        const uri = try readBytesAlloc(allocator, reader);
        defer allocator.free(uri);
        const has_params = try readInt(reader, u8) != 0;
        if (has_params) {
            const params = try readBytesAlloc(allocator, reader);
            defer allocator.free(params);
            doc.hyperlink_table.addWithId(id, uri, params) catch return error.SerializationFailed;
        } else {
            doc.hyperlink_table.addWithId(id, uri, null) catch return error.SerializationFailed;
        }
    }

    const palette_count = try readInt(reader, u32);
    var palette_index: u32 = 0;
    while (palette_index < palette_count) : (palette_index += 1) {
        const palette_id = try readInt(reader, u32);
        const color_count = try readInt(reader, u32);
        var palette = try color.Palette.init(allocator, palette_id, color_count);
        errdefer palette.deinit();

        var color_index: u32 = 0;
        while (color_index < color_count) : (color_index += 1) {
            palette.colors[color_index] = .{
                .r = try readInt(reader, u8),
                .g = try readInt(reader, u8),
                .b = try readInt(reader, u8),
            };
        }

        _ = doc.addPalette(palette) catch return error.SerializationFailed;
    }

    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const source_offset = try readInt(reader, u32);
            const source_len = try readInt(reader, u32);
            const source_encoding = encoding.SourceEncoding.fromMIBenum(try readInt(reader, u16)) catch {
                return error.SerializationFailed;
            };
            const contents_tag = try readInt(reader, u8);
            const contents_value = try readInt(reader, u32);
            const fg_color = try readColor(reader);
            const bg_color = try readColor(reader);
            const attr_flags = attributes.AttributeFlags.fromRaw(try readInt(reader, u32));
            const wide_flag_raw = try readInt(reader, u8);
            const wide_flag = std.meta.intToEnum(cell_grid.WideFlag, wide_flag_raw) catch {
                return error.SerializationFailed;
            };
            const hyperlink_id = try readInt(reader, u32);

            const contents = switch (contents_tag) {
                0 => cell_grid.CellContents{ .scalar = @truncate(contents_value) },
                1 => cell_grid.CellContents{ .grapheme = contents_value },
                else => return error.SerializationFailed,
            };

            try doc.setCell(x, y, .{
                .source_offset = source_offset,
                .source_len = source_len,
                .source_encoding = source_encoding,
                .contents = contents,
                .fg_color = fg_color,
                .bg_color = bg_color,
                .attr_flags = attr_flags,
                .wide_flag = wide_flag,
                .hyperlink_id = hyperlink_id,
            });
        }
    }

    doc.grid.clearDirty();
    return doc;
}

fn writeAll(writer: anytype, bytes: []const u8) errors.Error!void {
    writer.writeAll(bytes) catch |err| return mapWriteError(err);
}

fn readNoEof(reader: anytype, bytes: []u8) anyerror!void {
    try reader.readNoEof(bytes);
}

fn writeInt(writer: anytype, comptime T: type, value: T) errors.Error!void {
    var buf: [@sizeOf(T)]u8 = undefined;
    std.mem.writeInt(T, &buf, value, .little);
    try writeAll(writer, &buf);
}

fn readInt(reader: anytype, comptime T: type) errors.Error!T {
    var buf: [@sizeOf(T)]u8 = undefined;
    readNoEof(reader, &buf) catch |err| return mapReadError(err);
    return std.mem.readInt(T, &buf, .little);
}

fn writeBytes(writer: anytype, bytes: []const u8) errors.Error!void {
    try writeInt(writer, u32, @intCast(bytes.len));
    try writeAll(writer, bytes);
}

fn readBytesAlloc(allocator: std.mem.Allocator, reader: anytype) errors.Error![]u8 {
    const len = try readInt(reader, u32);
    const bytes = try allocator.alloc(u8, len);
    errdefer allocator.free(bytes);
    readNoEof(reader, bytes) catch |err| return mapReadError(err);
    return bytes;
}

fn writeColor(writer: anytype, value: color.Color) errors.Error!void {
    switch (value) {
        .none => try writeInt(writer, u8, 0),
        .palette => |index| {
            try writeInt(writer, u8, 1);
            try writeInt(writer, u8, index);
        },
        .rgb => |rgb| {
            try writeInt(writer, u8, 2);
            try writeInt(writer, u8, rgb.r);
            try writeInt(writer, u8, rgb.g);
            try writeInt(writer, u8, rgb.b);
        },
    }
}

fn readColor(reader: anytype) errors.Error!color.Color {
    return switch (try readInt(reader, u8)) {
        0 => .{ .none = {} },
        1 => .{ .palette = try readInt(reader, u8) },
        2 => .{ .rgb = .{
            .r = try readInt(reader, u8),
            .g = try readInt(reader, u8),
            .b = try readInt(reader, u8),
        } },
        else => error.SerializationFailed,
    };
}

fn mapWriteError(err: anyerror) errors.Error {
    return switch (err) {
        error.OutOfMemory => error.OutOfMemory,
        else => error.SerializationFailed,
    };
}

fn mapReadError(err: anyerror) errors.Error {
    return switch (err) {
        error.OutOfMemory => error.OutOfMemory,
        else => error.SerializationFailed,
    };
}

fn roundtripDocument(allocator: std.mem.Allocator, doc: *const document.Document) !document.Document {
    var bytes = std.ArrayListUnmanaged(u8){};
    defer bytes.deinit(allocator);

    try serialize(doc, bytes.writer(allocator));

    var stream = std.io.fixedBufferStream(bytes.items);
    return try deserialize(allocator, stream.reader());
}

fn expectCellEqual(expected: cell_grid.CellView, actual: cell_grid.CellView) !void {
    try std.testing.expectEqual(expected.source_offset, actual.source_offset);
    try std.testing.expectEqual(expected.source_len, actual.source_len);
    try std.testing.expectEqual(expected.source_encoding, actual.source_encoding);
    try std.testing.expectEqual(expected.hyperlink_id, actual.hyperlink_id);
    try std.testing.expectEqual(expected.wide_flag, actual.wide_flag);
    try std.testing.expectEqual(expected.attr_flags.toRaw(), actual.attr_flags.toRaw());
    try std.testing.expect(expected.fg_color.eql(actual.fg_color));
    try std.testing.expect(expected.bg_color.eql(actual.bg_color));

    switch (expected.contents) {
        .scalar => |scalar| {
            try std.testing.expectEqual(scalar, actual.contents.scalar);
        },
        .grapheme => |grapheme| {
            try std.testing.expectEqual(grapheme, actual.contents.grapheme);
        },
    }
}

test "serialize: roundtrip preserves default document contract" {
    const allocator = std.testing.allocator;

    var doc = try document.Document.init(allocator, 3, 2);
    defer doc.deinit();

    var restored = try roundtripDocument(allocator, &doc);
    defer restored.deinit();

    const dims = restored.getDimensions();
    try std.testing.expectEqual(@as(u32, 3), dims.width);
    try std.testing.expectEqual(@as(u32, 2), dims.height);
    try std.testing.expectEqual(document.SourceFormat.unknown, restored.source_format);
    try std.testing.expectEqual(encoding.SourceEncoding.cp437, restored.default_encoding);
    try std.testing.expectEqual(@as(u8, 8), restored.letter_spacing);
    try std.testing.expectEqual(@as(?f32, null), restored.aspect_ratio);
    try std.testing.expect(!restored.ice_colors);

    try expectCellEqual(try doc.getCell(0, 0), try restored.getCell(0, 0));
    try expectCellEqual(try doc.getCell(2, 1), try restored.getCell(2, 1));
}

test "serialize: roundtrip preserves populated cells and resources" {
    const allocator = std.testing.allocator;

    var doc = try document.Document.init(allocator, 2, 1);
    defer doc.deinit();

    doc.source_format = .utf8ansi;
    doc.default_encoding = .utf_8;
    doc.letter_spacing = 9;
    doc.aspect_ratio = 1.35;
    doc.ice_colors = true;

    const grapheme_id = try doc.internGrapheme("👩‍💻");
    const hyperlink_id = try doc.addHyperlink("https://example.com/art", "id=hero");

    var palette = try color.Palette.init(allocator, 7, 2);
    try palette.setColor(0, color.RGB.fromHex(0x112233));
    try palette.setColor(1, color.RGB.fromHex(0x445566));
    _ = try doc.addPalette(palette);

    const styled_attrs = attributes.AttributeFlags.none()
        .setBold(true)
        .setUnderline(.double)
        .setBlink(true);

    try doc.setCell(0, 0, .{
        .source_offset = 12,
        .source_len = 4,
        .source_encoding = .utf_8,
        .contents = .{ .grapheme = grapheme_id },
        .fg_color = .{ .rgb = .{ .r = 1, .g = 2, .b = 3 } },
        .bg_color = .{ .palette = 4 },
        .attr_flags = styled_attrs,
        .wide_flag = .head,
        .hyperlink_id = hyperlink_id,
    });

    try doc.setCell(1, 0, .{
        .source_offset = 16,
        .source_len = 1,
        .source_encoding = .cp437,
        .contents = .{ .scalar = 'Z' },
        .fg_color = .{ .none = {} },
        .bg_color = .{ .rgb = color.RGB.fromHex(0xAABBCC) },
        .attr_flags = attributes.AttributeFlags.withItalic(),
        .wide_flag = .tail,
    });

    var restored = try roundtripDocument(allocator, &doc);
    defer restored.deinit();

    const dims = restored.getDimensions();
    try std.testing.expectEqual(@as(u32, 2), dims.width);
    try std.testing.expectEqual(@as(u32, 1), dims.height);
    try std.testing.expectEqual(document.SourceFormat.utf8ansi, restored.source_format);
    try std.testing.expectEqual(encoding.SourceEncoding.utf_8, restored.default_encoding);
    try std.testing.expectEqual(@as(u8, 9), restored.letter_spacing);
    try std.testing.expect(restored.aspect_ratio != null);
    try std.testing.expectApproxEqAbs(@as(f32, 1.35), restored.aspect_ratio.?, 0.0001);
    try std.testing.expect(restored.ice_colors);

    try expectCellEqual(try doc.getCell(0, 0), try restored.getCell(0, 0));
    try expectCellEqual(try doc.getCell(1, 0), try restored.getCell(1, 0));
    try std.testing.expectEqualStrings("👩‍💻", try restored.getGrapheme(grapheme_id));

    const restored_link = restored.getHyperlink(hyperlink_id);
    try std.testing.expect(restored_link != null);
    try std.testing.expectEqualStrings("https://example.com/art", restored_link.?.uri);
    try std.testing.expectEqualStrings("id=hero", restored_link.?.params.?);

    const restored_palette = restored.getPalette(7);
    try std.testing.expect(restored_palette != null);
    try std.testing.expectEqual(@as(u24, 0x112233), restored_palette.?.colors[0].toHex());
    try std.testing.expectEqual(@as(u24, 0x445566), restored_palette.?.colors[1].toHex());
}
