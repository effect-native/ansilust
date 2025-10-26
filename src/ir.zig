//! Ansilust IR - Core intermediate representation
//!
//! Implements the Cell Grid IR (Approach 1) from IR-RESEARCH.md
//! Designed to be compatible with OpenTUI's OptimizedBuffer

const std = @import("std");

/// Main IR structure
pub const AnsilustIR = struct {
    allocator: std.mem.Allocator,

    // Canvas dimensions
    width: u32,
    height: u32,

    // Cell grid (flattened: width × height)
    cells: []Cell,

    // Reference-counted style table (Ghostty pattern)
    style_table: std.ArrayList(Style),

    // Multi-codepoint grapheme storage
    grapheme_map: std.AutoHashMap(u32, []u32),

    // Resources
    palette: PaletteType,
    font: FontInfo,

    // Metadata
    sauce: ?SauceRecord,
    source_format: SourceFormat,

    // Rendering hints
    ice_colors: bool,
    letter_spacing: u8, // 8 or 9
    aspect_ratio: ?f32, // 1.35 for DOS

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !AnsilustIR {
        const size = width * height;
        const cells = try allocator.alloc(Cell, size);

        // Initialize with default cells
        const default_cell = Cell{
            .char = ' ',
            .style_id = 0,
            .flags = CellFlags{},
        };

        for (cells) |*cell| {
            cell.* = default_cell;
        }

        var style_table: std.ArrayList(Style) = .empty;

        const default_style = Style{
            .fg = Color{ .palette = 7 }, // White
            .bg = Color{ .palette = 0 }, // Black
            .underline_color = null,
            .attributes = Attributes{},
            .hyperlink = null,
        };
        try style_table.append(allocator, default_style);

        return AnsilustIR{
            .allocator = allocator,
            .width = width,
            .height = height,
            .cells = cells,
            .style_table = style_table,
            .grapheme_map = std.AutoHashMap(u32, []u32).init(allocator),
            .palette = .ansi,
            .font = FontInfo{
                .id = "cp437",
                .width = 8,
                .height = 16,
                .embedded = null,
            },
            .sauce = null,
            .source_format = .ansi,
            .ice_colors = false,
            .letter_spacing = 8,
            .aspect_ratio = null,
        };
    }

    pub fn deinit(self: *AnsilustIR) void {
        self.allocator.free(self.cells);
        self.style_table.deinit(self.allocator);

        // Free grapheme map entries
        var it = self.grapheme_map.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.grapheme_map.deinit();

        if (self.sauce) |sauce| {
            sauce.deinit(self.allocator);
        }
    }

    pub fn getCell(self: *const AnsilustIR, x: u32, y: u32) ?*const Cell {
        if (x >= self.width or y >= self.height) return null;
        const index = y * self.width + x;
        return &self.cells[index];
    }

    pub fn setCell(self: *AnsilustIR, x: u32, y: u32, cell: Cell) bool {
        if (x >= self.width or y >= self.height) return false;
        const index = y * self.width + x;
        self.cells[index] = cell;
        return true;
    }

    pub fn getStyle(self: *const AnsilustIR, style_id: u16) ?*const Style {
        if (style_id >= self.style_table.items.len) return null;
        return &self.style_table.items[style_id];
    }

    pub fn addStyle(self: *AnsilustIR, style: Style) !u16 {
        // Check if style already exists (reference counting)
        for (self.style_table.items, 0..) |existing, id| {
            if (std.meta.eql(existing, style)) {
                return @intCast(id);
            }
        }

        // Add new style
        try self.style_table.append(self.allocator, style);
        return @intCast(self.style_table.items.len - 1);
    }
};

/// Individual cell in the grid
pub const Cell = packed struct {
    char: u32, // Unicode codepoint or CP437 code
    style_id: u16, // Index into style_table
    flags: CellFlags,
};

/// Cell flags (inspired by Ghostty)
pub const CellFlags = packed struct {
    wide_char: bool = false, // Double-width character
    spacer_tail: bool = false, // Second half of wide char
    spacer_head: bool = false, // Wrapped wide char marker
    soft_wrap: bool = false, // Line soft-wraps to next
    protected: bool = false, // Write-protected cell
    _padding: u3 = 0, // Padding to full byte
};

/// Style information (reference-counted)
pub const Style = struct {
    fg: Color,
    bg: Color,
    underline_color: ?Color,
    attributes: Attributes,
    hyperlink: ?u32,
};

/// Color representation
pub const Color = union(enum) {
    none, // Terminal default (not black!)
    palette: u8, // Index 0-255
    rgb: RGB, // 24-bit true color
};

/// RGB color
pub const RGB = struct {
    r: u8,
    g: u8,
    b: u8,
};

/// Text attributes (Ghostty-inspired with BBS extensions)
pub const Attributes = packed struct {
    bold: bool = false,
    faint: bool = false,
    italic: bool = false,
    underline: bool = false,
    underline_double: bool = false,
    underline_curly: bool = false,
    blink: bool = false,
    reverse: bool = false,
    invisible: bool = false,
    strikethrough: bool = false,
    overline: bool = false,
    _padding: u5 = 0, // Padding to 16 bits
};

/// Palette type
pub const PaletteType = union(enum) {
    ansi,
    vga,
    workbench,
    custom: Palette,
};

/// Custom palette definition
pub const Palette = struct {
    colors: []RGB,

    pub fn deinit(self: Palette, allocator: std.mem.Allocator) void {
        allocator.free(self.colors);
    }
};

/// Font information
pub const FontInfo = struct {
    id: []const u8,
    width: u8,
    height: u8,
    embedded: ?BitmapFont,
};

/// Bitmap font data
pub const BitmapFont = struct {
    width: u8,
    height: u8,
    char_count: u16,
    data: []u8,

    pub fn deinit(self: BitmapFont, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }
};

/// SAUCE metadata record
pub const SauceRecord = struct {
    title: []const u8,
    author: []const u8,
    group: []const u8,
    date: []const u8,
    columns: u16,
    rows: u16,
    flags: SauceFlags,
    font_name: []const u8,
    comments: [][]const u8,

    pub fn deinit(self: SauceRecord, allocator: std.mem.Allocator) void {
        allocator.free(self.title);
        allocator.free(self.author);
        allocator.free(self.group);
        allocator.free(self.date);
        allocator.free(self.font_name);
        for (self.comments) |comment| {
            allocator.free(comment);
        }
        allocator.free(self.comments);
    }
};

/// SAUCE flags
pub const SauceFlags = packed struct {
    ice_colors: bool = false,
    _reserved1: bool = false,
    letter_spacing_9bit: bool = false,
    aspect_ratio: bool = false,
    _padding: u4 = 0,
};

/// Source format type
pub const SourceFormat = enum {
    ansi,
    binary,
    pcboard,
    xbin,
    tundra,
    artworx,
    icedraw,
    utf8ansi,
};

// Tests
test "create IR" {
    const allocator = std.testing.allocator;

    var ir = try AnsilustIR.init(allocator, 80, 25);
    defer ir.deinit();

    try std.testing.expectEqual(@as(u32, 80), ir.width);
    try std.testing.expectEqual(@as(u32, 25), ir.height);
    try std.testing.expectEqual(@as(usize, 80 * 25), ir.cells.len);
}

test "cell access" {
    const allocator = std.testing.allocator;

    var ir = try AnsilustIR.init(allocator, 80, 25);
    defer ir.deinit();

    // Set cell
    const cell = Cell{
        .char = 'A',
        .style_id = 0,
        .flags = CellFlags{},
    };
    try std.testing.expect(ir.setCell(0, 0, cell));

    // Get cell
    const retrieved = ir.getCell(0, 0).?;
    try std.testing.expectEqual(@as(u32, 'A'), retrieved.char);

    // Out of bounds
    try std.testing.expectEqual(@as(?*const Cell, null), ir.getCell(100, 100));
    try std.testing.expect(!ir.setCell(100, 100, cell));
}

test "style table" {
    const allocator = std.testing.allocator;

    var ir = try AnsilustIR.init(allocator, 80, 25);
    defer ir.deinit();

    const style = Style{
        .fg = Color{ .rgb = RGB{ .r = 255, .g = 0, .b = 0 } },
        .bg = Color.none,
        .underline_color = null,
        .attributes = Attributes{ .bold = true },
        .hyperlink = null,
    };

    const id1 = try ir.addStyle(style);
    const id2 = try ir.addStyle(style); // Should reuse

    try std.testing.expectEqual(id1, id2); // Reference counting
    try std.testing.expectEqual(@as(usize, 2), ir.style_table.items.len); // Default + new
}

test "cell flags" {
    const flags = CellFlags{
        .wide_char = true,
        .soft_wrap = true,
    };
    try std.testing.expect(flags.wide_char);
    try std.testing.expect(flags.soft_wrap);
    try std.testing.expect(!flags.spacer_tail);
}
