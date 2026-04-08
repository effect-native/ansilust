//! Ansilust IR - Serialization Module
//!
//! Binary serialization/deserialization for IR documents.
//! Format: "ANSILUSTIR\0" header + versioned sections.
//!
//! STUB: To be implemented in Phase 5.

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
    _ = doc;
    _ = writer;
    return error.SerializationFailed; // STUB
}

/// Deserialize document from reader.
pub fn deserialize(allocator: std.mem.Allocator, reader: anytype) errors.Error!document.Document {
    _ = allocator;
    _ = reader;
    return error.SerializationFailed; // STUB
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
