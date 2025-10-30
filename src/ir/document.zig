//! Ansilust IR - Document Module
//!
//! Root document container for the intermediate representation.
//! Contains all metadata, cell grid, animations, and resources.
//!
//! This is the primary API entry point for parsers and renderers.
//! Implements RQ-API-1, RQ-API-2, RQ-Meta-1.

const std = @import("std");
const errors = @import("errors.zig");
const cell_grid = @import("cell_grid.zig");
const encoding = @import("encoding.zig");
const color = @import("color.zig");
const attributes = @import("attributes.zig");
const sauce = @import("sauce.zig");
const animation = @import("animation.zig");
const hyperlink = @import("hyperlink.zig");
const event_log = @import("event_log.zig");

/// Source format identifier for optimization hints.
pub const SourceFormat = enum {
    unknown,
    ansi,
    binary,
    pcboard,
    xbin,
    tundra,
    artworx,
    icedraw,
    utf8ansi,
    ansimation,
};

/// Font information and embedded data.
pub const FontInfo = struct {
    /// Font identifier (e.g., "cp437", "topaz")
    id: []const u8,

    /// Character width in pixels
    width: u8,

    /// Character height in pixels
    height: u8,

    /// Optional embedded bitmap font data
    embedded: ?BitmapFont,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, id: []const u8, width: u8, height: u8) !FontInfo {
        const id_copy = try allocator.dupe(u8, id);
        return FontInfo{
            .id = id_copy,
            .width = width,
            .height = height,
            .embedded = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *FontInfo) void {
        self.allocator.free(self.id);
        if (self.embedded) |*font| {
            font.deinit();
        }
    }
};

/// Embedded bitmap font data.
pub const BitmapFont = struct {
    /// Glyph width in pixels
    width: u8,

    /// Glyph height in pixels
    height: u8,

    /// Number of glyphs
    char_count: u16,

    /// Raw bitmap data (owned)
    data: []const u8,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: u8, height: u8, char_count: u16, data: []const u8) !BitmapFont {
        const data_copy = try allocator.dupe(u8, data);
        return BitmapFont{
            .width = width,
            .height = height,
            .char_count = char_count,
            .data = data_copy,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *BitmapFont) void {
        self.allocator.free(self.data);
    }
};

/// Main IR document structure.
///
/// Contains all data for a text art document including cells, metadata,
/// animations, and resources. This is the root object for parsers/renderers.
pub const Document = struct {
    allocator: std.mem.Allocator,

    // === Core Grid ===

    /// Primary cell grid
    grid: cell_grid.CellGrid,

    /// Grapheme pool for multi-codepoint characters
    grapheme_pool: cell_grid.GraphemePool,

    // === Metadata ===

    /// Source format identification
    source_format: SourceFormat,

    /// Default encoding hint
    default_encoding: encoding.SourceEncoding,

    /// SAUCE metadata (optional)
    sauce_record: ?sauce.SauceRecord,

    /// Font information
    font_info: FontInfo,

    // === Resources ===

    /// Palette table
    palette_table: color.PaletteTable,

    /// Hyperlink table (OSC 8 support)
    hyperlink_table: hyperlink.HyperlinkTable,

    // === Animation ===

    /// Animation sequence (null for static documents)
    animation_data: ?animation.Animation,

    // === Event Log ===

    /// Terminal event log
    event_log: event_log.EventLog,

    // === Rendering Hints ===

    /// Letter spacing (8 or 9 pixels)
    letter_spacing: u8,

    /// Aspect ratio hint (e.g., 1.35 for DOS)
    aspect_ratio: ?f32,

    /// iCE colors mode (blink -> high intensity background)
    ice_colors: bool,

    /// Initialize document with given dimensions.
    ///
    /// Creates empty cell grid with default styling (white on black).
    /// All metadata initialized to defaults.
    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !Document {
        var grid = try cell_grid.CellGrid.init(allocator, width, height);
        errdefer grid.deinit();

        var grapheme_pool = cell_grid.GraphemePool.init(allocator);
        errdefer grapheme_pool.deinit();

        var font_info = try FontInfo.init(allocator, "cp437", 8, 16);
        errdefer font_info.deinit();

        return Document{
            .allocator = allocator,
            .grid = grid,
            .grapheme_pool = grapheme_pool,
            .source_format = .unknown,
            .default_encoding = .cp437,
            .sauce_record = null,
            .font_info = font_info,
            .palette_table = color.PaletteTable.init(allocator),
            .hyperlink_table = hyperlink.HyperlinkTable.init(allocator),
            .animation_data = null,
            .event_log = event_log.EventLog.init(allocator),
            .letter_spacing = 8,
            .aspect_ratio = null,
            .ice_colors = false,
        };
    }

    /// Free all allocated resources.
    pub fn deinit(self: *Document) void {
        self.grid.deinit();
        self.grapheme_pool.deinit();

        if (self.sauce_record) |*rec| {
            rec.deinit();
        }

        self.font_info.deinit();
        self.palette_table.deinit();
        self.hyperlink_table.deinit();

        if (self.animation_data) |*anim| {
            anim.deinit();
        }

        self.event_log.deinit();
    }

    /// Get cell at coordinates (convenience wrapper).
    pub fn getCell(self: *const Document, x: u32, y: u32) errors.Error!cell_grid.CellView {
        return self.grid.getCell(x, y);
    }

    /// Set cell at coordinates (convenience wrapper).
    pub fn setCell(self: *Document, x: u32, y: u32, input: cell_grid.CellInput) errors.Error!void {
        try self.grid.setCell(x, y, input);
    }

    /// Resize document grid.
    pub fn resize(self: *Document, new_width: u32, new_height: u32) !void {
        try self.grid.resize(new_width, new_height);
    }

    /// Get document dimensions.
    pub fn getDimensions(self: *const Document) struct { width: u32, height: u32 } {
        return .{ .width = self.grid.width, .height = self.grid.height };
    }

    /// Check if document has animation.
    pub fn isAnimated(self: *const Document) bool {
        return self.animation_data != null;
    }

    /// Add SAUCE metadata.
    pub fn setSauce(self: *Document, sauce_record: sauce.SauceRecord) void {
        if (self.sauce_record) |*old| {
            old.deinit();
        }
        self.sauce_record = sauce_record;
    }

    /// Apply rendering hints from SAUCE record.
    pub fn applySauceHints(self: *Document) void {
        const sauce_rec = self.sauce_record orelse return;

        // Apply flags
        self.ice_colors = sauce_rec.flags.ice_colors;
        self.letter_spacing = sauce_rec.flags.getLetterSpacing();
        self.aspect_ratio = sauce_rec.flags.getAspectRatio();
    }

    /// Intern grapheme cluster into pool.
    pub fn internGrapheme(self: *Document, utf8_bytes: []const u8) !u32 {
        return self.grapheme_pool.intern(utf8_bytes);
    }

    /// Get grapheme from pool by ID.
    pub fn getGrapheme(self: *const Document, id: u32) errors.Error![]const u8 {
        return self.grapheme_pool.get(id);
    }

    /// Add palette to document.
    pub fn addPalette(self: *Document, palette: color.Palette) errors.Error!u32 {
        return self.palette_table.add(palette);
    }

    /// Get palette by ID.
    pub fn getPalette(self: *const Document, id: u32) ?*const color.Palette {
        return self.palette_table.get(id);
    }

    /// Add hyperlink to document.
    pub fn addHyperlink(self: *Document, uri: []const u8, params: ?[]const u8) !u32 {
        return self.hyperlink_table.add(uri, params);
    }

    /// Get hyperlink by ID.
    pub fn getHyperlink(self: *const Document, id: u32) ?*const hyperlink.Hyperlink {
        return self.hyperlink_table.get(id);
    }

    /// Add event to log.
    pub fn logEvent(self: *Document, frame_index: u32, event_type: event_log.EventType, data: event_log.EventData) !void {
        try self.event_log.addEvent(frame_index, event_type, data);
    }
};

// === Tests ===

test "Document: initialization and cleanup" {
    const allocator = std.testing.allocator;

    var doc = try Document.init(allocator, 80, 25);
    defer doc.deinit();

    const dims = doc.getDimensions();
    try std.testing.expectEqual(@as(u32, 80), dims.width);
    try std.testing.expectEqual(@as(u32, 25), dims.height);
    try std.testing.expect(!doc.isAnimated());
}

test "Document: cell operations" {
    const allocator = std.testing.allocator;

    var doc = try Document.init(allocator, 80, 25);
    defer doc.deinit();

    const input = cell_grid.CellInput{
        .contents = cell_grid.CellContents{ .scalar = 'X' },
        .fg_color = color.Color{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },
    };

    try doc.setCell(10, 10, input);

    const cell = try doc.getCell(10, 10);
    try std.testing.expectEqual(@as(u21, 'X'), cell.contents.scalar);
}

test "Document: grapheme pool integration" {
    const allocator = std.testing.allocator;

    var doc = try Document.init(allocator, 80, 25);
    defer doc.deinit();

    const emoji = "👍";
    const id = try doc.internGrapheme(emoji);
    const retrieved = try doc.getGrapheme(id);

    try std.testing.expectEqualStrings(emoji, retrieved);
}

test "Document: resize" {
    const allocator = std.testing.allocator;

    var doc = try Document.init(allocator, 10, 10);
    defer doc.deinit();

    try doc.resize(20, 20);

    const dims = doc.getDimensions();
    try std.testing.expectEqual(@as(u32, 20), dims.width);
    try std.testing.expectEqual(@as(u32, 20), dims.height);
}
