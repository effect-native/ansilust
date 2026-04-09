//! Ansilust IR - OpenTUI Integration Module
//!
//! Conversion bridge to OpenTUI's OptimizedBuffer format.
//! Enables direct integration with OpenTUI framework.
//!
const std = @import("std");
const attributes = @import("attributes.zig");
const cell_grid = @import("cell_grid.zig");
const color = @import("color.zig");
const errors = @import("errors.zig");
const document = @import("document.zig");

pub const NormalizedColor = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1.0,
    is_default: bool,
};

pub const AttributeBits = struct {
    pub const bold: u8 = 1 << 0;
    pub const faint: u8 = 1 << 1;
    pub const italic: u8 = 1 << 2;
    pub const underline: u8 = 1 << 3;
    pub const blink: u8 = 1 << 4;
    pub const reverse: u8 = 1 << 5;
    pub const invisible: u8 = 1 << 6;
    pub const strikethrough: u8 = 1 << 7;
};

pub const OptimizedBuffer = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    cell_count: usize,

    codepoints: []u21,
    grapheme_ids: []u32,
    fg_colors: []NormalizedColor,
    bg_colors: []NormalizedColor,
    attribute_bits: []u8,
    wide_flags: []cell_grid.WideFlag,
    hyperlink_ids: []u32,
    dirty: []bool,

    pub fn deinit(self: *OptimizedBuffer) void {
        self.allocator.free(self.codepoints);
        self.allocator.free(self.grapheme_ids);
        self.allocator.free(self.fg_colors);
        self.allocator.free(self.bg_colors);
        self.allocator.free(self.attribute_bits);
        self.allocator.free(self.wide_flags);
        self.allocator.free(self.hyperlink_ids);
        self.allocator.free(self.dirty);
    }
};

/// Convert document to OpenTUI OptimizedBuffer.
///
/// Maps IR cell grid to OpenTUI's structure-of-arrays format.
/// Colors converted to RGBA floats, attributes to u8 bitflags.
pub fn toOptimizedBuffer(doc: *const document.Document, allocator: std.mem.Allocator) errors.Error!OptimizedBuffer {
    const dimensions = doc.getDimensions();
    const cell_count = @as(usize, dimensions.width) * @as(usize, dimensions.height);

    const codepoints = try allocator.alloc(u21, cell_count);
    errdefer allocator.free(codepoints);
    const grapheme_ids = try allocator.alloc(u32, cell_count);
    errdefer allocator.free(grapheme_ids);
    const fg_colors = try allocator.alloc(NormalizedColor, cell_count);
    errdefer allocator.free(fg_colors);
    const bg_colors = try allocator.alloc(NormalizedColor, cell_count);
    errdefer allocator.free(bg_colors);
    const attribute_bits = try allocator.alloc(u8, cell_count);
    errdefer allocator.free(attribute_bits);
    const wide_flags = try allocator.alloc(cell_grid.WideFlag, cell_count);
    errdefer allocator.free(wide_flags);
    const hyperlink_ids = try allocator.alloc(u32, cell_count);
    errdefer allocator.free(hyperlink_ids);
    const dirty = try allocator.alloc(bool, cell_count);
    errdefer allocator.free(dirty);

    var iter = doc.grid.iterCells();
    var index: usize = 0;
    while (iter.next()) |item| : (index += 1) {
        switch (item.cell.contents) {
            .scalar => |scalar| {
                codepoints[index] = scalar;
                grapheme_ids[index] = 0;
            },
            .grapheme => |grapheme_id| {
                codepoints[index] = 0;
                grapheme_ids[index] = grapheme_id;
            },
        }

        fg_colors[index] = normalizeColor(doc, item.cell.fg_color);
        bg_colors[index] = normalizeColor(doc, item.cell.bg_color);
        attribute_bits[index] = projectAttributes(item.cell.attr_flags);
        wide_flags[index] = item.cell.wide_flag;
        hyperlink_ids[index] = item.cell.hyperlink_id;
        dirty[index] = item.cell.dirty;
    }

    return .{
        .allocator = allocator,
        .width = dimensions.width,
        .height = dimensions.height,
        .cell_count = cell_count,
        .codepoints = codepoints,
        .grapheme_ids = grapheme_ids,
        .fg_colors = fg_colors,
        .bg_colors = bg_colors,
        .attribute_bits = attribute_bits,
        .wide_flags = wide_flags,
        .hyperlink_ids = hyperlink_ids,
        .dirty = dirty,
    };
}

fn normalizeColor(doc: *const document.Document, value: color.Color) NormalizedColor {
    return switch (value) {
        .none => .{ .r = 0.0, .g = 0.0, .b = 0.0, .is_default = true },
        .rgb => |rgb| {
            const normalized = rgb.toNormalized();
            return .{
                .r = normalized.r,
                .g = normalized.g,
                .b = normalized.b,
                .is_default = false,
            };
        },
        .palette => |index| {
            const rgb = resolvePaletteColor(doc, index);
            const normalized = rgb.toNormalized();
            return .{
                .r = normalized.r,
                .g = normalized.g,
                .b = normalized.b,
                .is_default = false,
            };
        },
    };
}

fn resolvePaletteColor(doc: *const document.Document, index: u8) color.RGB {
    if (doc.palette_table.getByIndex(0)) |palette| {
        if (index < palette.colors.len) {
            return palette.colors[index];
        }
    }

    if (index < color.ANSI_PALETTE.len) {
        return color.ANSI_PALETTE[index];
    }

    return color.RGB.black;
}

fn projectAttributes(value: attributes.AttributeFlags) u8 {
    var bits: u8 = 0;

    if (value.bold) bits |= AttributeBits.bold;
    if (value.faint) bits |= AttributeBits.faint;
    if (value.italic) bits |= AttributeBits.italic;
    if (value.underline) bits |= AttributeBits.underline;
    if (value.blink) bits |= AttributeBits.blink;
    if (value.reverse) bits |= AttributeBits.reverse;
    if (value.invisible) bits |= AttributeBits.invisible;
    if (value.strikethrough) bits |= AttributeBits.strikethrough;

    return bits;
}

test "OpenTUI bridge exports a concrete buffer surface" {
    try std.testing.expect(@hasDecl(@This(), "OptimizedBuffer"));
}

test "toOptimizedBuffer returns a buffer payload instead of void" {
    const fn_info = @typeInfo(@TypeOf(toOptimizedBuffer)).@"fn";
    const return_type = fn_info.return_type orelse unreachable;
    const error_union = @typeInfo(return_type).error_union;

    try std.testing.expect(error_union.payload != void);
}

test "toOptimizedBuffer projects cells into OpenTUI-style parallel slices" {
    const allocator = std.testing.allocator;

    var doc = try document.Document.init(allocator, 2, 1);
    defer doc.deinit();

    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'A' },
        .fg_color = .{ .rgb = .{ .r = 255, .g = 128, .b = 0 } },
        .bg_color = .none,
        .attr_flags = attributes.AttributeFlags.none().setBold(true).setUnderline(.single),
        .hyperlink_id = 42,
    });

    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'B' },
        .fg_color = .{ .palette = 4 },
        .bg_color = .{ .palette = 1 },
        .attr_flags = attributes.AttributeFlags.withItalic(),
        .wide_flag = .tail,
    });

    var buffer = try toOptimizedBuffer(&doc, allocator);
    defer buffer.deinit();

    try std.testing.expectEqual(@as(u32, 2), buffer.width);
    try std.testing.expectEqual(@as(usize, 2), buffer.cell_count);
    try std.testing.expectEqual(@as(u21, 'A'), buffer.codepoints[0]);
    try std.testing.expectEqual(@as(u32, 0), buffer.grapheme_ids[0]);
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), buffer.fg_colors[0].r, 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 128.0 / 255.0), buffer.fg_colors[0].g, 0.0001);
    try std.testing.expect(buffer.bg_colors[0].is_default);
    try std.testing.expectEqual(AttributeBits.bold | AttributeBits.underline, buffer.attribute_bits[0]);
    try std.testing.expectEqual(@as(u32, 42), buffer.hyperlink_ids[0]);
    try std.testing.expect(buffer.dirty[0]);

    try std.testing.expectEqual(@as(u21, 'B'), buffer.codepoints[1]);
    try std.testing.expectEqual(@as(u32, 0), buffer.grapheme_ids[1]);
    try std.testing.expectApproxEqAbs(@as(f32, 170.0 / 255.0), buffer.bg_colors[1].r, 0.0001);
    try std.testing.expectEqual(AttributeBits.italic, buffer.attribute_bits[1]);
    try std.testing.expectEqual(cell_grid.WideFlag.tail, buffer.wide_flags[1]);
}

test "toOptimizedBuffer reuses grapheme ids and honors document palette overrides" {
    const allocator = std.testing.allocator;

    var doc = try document.Document.init(allocator, 1, 1);
    defer doc.deinit();

    const grapheme_id = try doc.internGrapheme("👾");

    var palette = try color.Palette.init(allocator, 77, 16);
    try palette.setColor(3, color.RGB.fromHex(0x123456));
    _ = try doc.addPalette(palette);

    try doc.setCell(0, 0, .{
        .contents = .{ .grapheme = grapheme_id },
        .fg_color = .{ .palette = 3 },
    });

    var buffer = try toOptimizedBuffer(&doc, allocator);
    defer buffer.deinit();

    try std.testing.expectEqual(@as(u21, 0), buffer.codepoints[0]);
    try std.testing.expectEqual(grapheme_id, buffer.grapheme_ids[0]);
    try std.testing.expectApproxEqAbs(@as(f32, 0x12) / 255.0, buffer.fg_colors[0].r, 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 0x34) / 255.0, buffer.fg_colors[0].g, 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 0x56) / 255.0, buffer.fg_colors[0].b, 0.0001);
}
