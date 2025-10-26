//! Ansilust IR - Cell Grid Module
//!
//! Structure-of-arrays cell grid implementation for efficient cache locality.
//! Stores 2D text art as flattened array with parallel slices for each cell property.
//!
//! Implements RQ-Cell-1, RQ-Cell-2, RQ-Cell-3, RQ-Grapheme-1, RQ-Grapheme-2, RQ-Grapheme-3.

const std = @import("std");
const errors = @import("errors.zig");
const encoding = @import("encoding.zig");
const color = @import("color.zig");
const attributes = @import("attributes.zig");

/// Cell contents discriminated union.
///
/// Stores either a Unicode scalar value or a reference to the grapheme pool.
/// Grapheme ID 0 is reserved (means "no grapheme", use scalar instead).
pub const CellContents = union(enum) {
    /// Single Unicode scalar (U+0000 to U+10FFFF)
    scalar: u21,

    /// Grapheme cluster ID (reference to grapheme pool)
    /// ID 0 is invalid; valid IDs start at 1
    grapheme: u32,

    /// Check if this is a scalar value.
    pub fn isScalar(self: CellContents) bool {
        return switch (self) {
            .scalar => true,
            .grapheme => false,
        };
    }

    /// Get scalar value (or null if grapheme).
    pub fn getScalar(self: CellContents) ?u21 {
        return switch (self) {
            .scalar => |s| s,
            .grapheme => null,
        };
    }

    /// Get grapheme ID (or null if scalar).
    pub fn getGrapheme(self: CellContents) ?u32 {
        return switch (self) {
            .grapheme => |g| g,
            .scalar => null,
        };
    }
};

/// Wide character flag indicating double-width character handling.
pub const WideFlag = enum(u8) {
    /// Normal single-width character
    none = 0,

    /// Head cell of wide character (actual character)
    head = 1,

    /// Tail cell of wide character (placeholder/spacer)
    tail = 2,

    /// Check if this represents a wide character (head or tail).
    pub fn isWide(self: WideFlag) bool {
        return self != .none;
    }
};

/// Structure-of-arrays cell grid.
///
/// Parallel slices store per-cell properties with excellent cache locality.
/// All slices have length = width × height.
pub const CellGrid = struct {
    allocator: std.mem.Allocator,

    /// Grid dimensions
    width: u32,
    height: u32,

    // === Parallel Slices (Structure-of-Arrays) ===

    /// Raw source byte offset in byte arena
    source_offset: []u32,

    /// Raw source byte length
    source_len: []u32,

    /// Source encoding for raw bytes
    source_encoding: []encoding.SourceEncoding,

    /// Normalized Unicode scalar or grapheme ID
    contents: []CellContents,

    /// Foreground color
    fg_color: []color.Color,

    /// Background color
    bg_color: []color.Color,

    /// Attribute bitflags
    attr_flags: []attributes.AttributeFlags,

    /// Wide character flags
    wide_flags: []WideFlag,

    /// Hyperlink ID reference (0 = no hyperlink)
    hyperlink_id: []u32,

    /// Dirty flag for diff-based rendering
    dirty: []bool,

    /// Initialize cell grid with given dimensions.
    ///
    /// All cells initialized to default state (space, white on black).
    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !CellGrid {
        const size = @as(usize, width) * @as(usize, height);

        // Check for overflow
        if (size == 0 or size > std.math.maxInt(u32)) {
            return error.DimensionOverflow;
        }

        const grid = CellGrid{
            .allocator = allocator,
            .width = width,
            .height = height,
            .source_offset = try allocator.alloc(u32, size),
            .source_len = try allocator.alloc(u32, size),
            .source_encoding = try allocator.alloc(encoding.SourceEncoding, size),
            .contents = try allocator.alloc(CellContents, size),
            .fg_color = try allocator.alloc(color.Color, size),
            .bg_color = try allocator.alloc(color.Color, size),
            .attr_flags = try allocator.alloc(attributes.AttributeFlags, size),
            .wide_flags = try allocator.alloc(WideFlag, size),
            .hyperlink_id = try allocator.alloc(u32, size),
            .dirty = try allocator.alloc(bool, size),
        };

        // Initialize to defaults
        @memset(grid.source_offset, 0);
        @memset(grid.source_len, 0);
        @memset(grid.source_encoding, .unknown);

        const default_contents = CellContents{ .scalar = ' ' };
        @memset(grid.contents, default_contents);

        const default_fg = color.Color{ .palette = 7 }; // White
        const default_bg = color.Color{ .palette = 0 }; // Black
        @memset(grid.fg_color, default_fg);
        @memset(grid.bg_color, default_bg);

        @memset(grid.attr_flags, attributes.AttributeFlags.none());
        @memset(grid.wide_flags, .none);
        @memset(grid.hyperlink_id, 0);
        @memset(grid.dirty, false);

        return grid;
    }

    /// Free all allocated memory.
    pub fn deinit(self: *CellGrid) void {
        self.allocator.free(self.source_offset);
        self.allocator.free(self.source_len);
        self.allocator.free(self.source_encoding);
        self.allocator.free(self.contents);
        self.allocator.free(self.fg_color);
        self.allocator.free(self.bg_color);
        self.allocator.free(self.attr_flags);
        self.allocator.free(self.wide_flags);
        self.allocator.free(self.hyperlink_id);
        self.allocator.free(self.dirty);
    }

    /// Convert 2D coordinates to linear index.
    fn coordToIndex(self: *const CellGrid, x: u32, y: u32) ?usize {
        if (x >= self.width or y >= self.height) return null;
        return @as(usize, y) * @as(usize, self.width) + @as(usize, x);
    }

    /// Get cell properties at coordinates (read-only view).
    pub fn getCell(self: *const CellGrid, x: u32, y: u32) errors.Error!CellView {
        const idx = self.coordToIndex(x, y) orelse return error.InvalidCoordinate;
        return CellView{
            .source_offset = self.source_offset[idx],
            .source_len = self.source_len[idx],
            .source_encoding = self.source_encoding[idx],
            .contents = self.contents[idx],
            .fg_color = self.fg_color[idx],
            .bg_color = self.bg_color[idx],
            .attr_flags = self.attr_flags[idx],
            .wide_flag = self.wide_flags[idx],
            .hyperlink_id = self.hyperlink_id[idx],
            .dirty = self.dirty[idx],
        };
    }

    /// Set cell properties at coordinates.
    pub fn setCell(self: *CellGrid, x: u32, y: u32, input: CellInput) errors.Error!void {
        const idx = self.coordToIndex(x, y) orelse return error.InvalidCoordinate;

        if (input.source_offset) |val| self.source_offset[idx] = val;
        if (input.source_len) |val| self.source_len[idx] = val;
        if (input.source_encoding) |val| self.source_encoding[idx] = val;
        if (input.contents) |val| self.contents[idx] = val;
        if (input.fg_color) |val| self.fg_color[idx] = val;
        if (input.bg_color) |val| self.bg_color[idx] = val;
        if (input.attr_flags) |val| self.attr_flags[idx] = val;
        if (input.wide_flag) |val| self.wide_flags[idx] = val;
        if (input.hyperlink_id) |val| self.hyperlink_id[idx] = val;

        // Always mark dirty on write
        self.dirty[idx] = true;
    }

    /// Clear dirty flags (e.g., after rendering).
    pub fn clearDirty(self: *CellGrid) void {
        @memset(self.dirty, false);
    }

    /// Mark all cells as dirty.
    pub fn markAllDirty(self: *CellGrid) void {
        @memset(self.dirty, true);
    }

    /// Resize grid (reallocates all slices).
    ///
    /// Preserves existing cell data where possible (up to min dimensions).
    /// New cells initialized to default state.
    pub fn resize(self: *CellGrid, new_width: u32, new_height: u32) !void {
        const new_size = @as(usize, new_width) * @as(usize, new_height);
        if (new_size == 0 or new_size > std.math.maxInt(u32)) {
            return error.DimensionOverflow;
        }

        // Create new grid
        var new_grid = try CellGrid.init(self.allocator, new_width, new_height);
        errdefer new_grid.deinit();

        // Copy existing cells
        const copy_height = @min(self.height, new_height);
        const copy_width = @min(self.width, new_width);

        var y: u32 = 0;
        while (y < copy_height) : (y += 1) {
            var x: u32 = 0;
            while (x < copy_width) : (x += 1) {
                const old_idx = self.coordToIndex(x, y).?;
                const new_idx = new_grid.coordToIndex(x, y).?;

                new_grid.source_offset[new_idx] = self.source_offset[old_idx];
                new_grid.source_len[new_idx] = self.source_len[old_idx];
                new_grid.source_encoding[new_idx] = self.source_encoding[old_idx];
                new_grid.contents[new_idx] = self.contents[old_idx];
                new_grid.fg_color[new_idx] = self.fg_color[old_idx];
                new_grid.bg_color[new_idx] = self.bg_color[old_idx];
                new_grid.attr_flags[new_idx] = self.attr_flags[old_idx];
                new_grid.wide_flags[new_idx] = self.wide_flags[old_idx];
                new_grid.hyperlink_id[new_idx] = self.hyperlink_id[old_idx];
                new_grid.dirty[new_idx] = true; // Mark dirty after resize
            }
        }

        // Replace self with new grid
        self.deinit();
        self.* = new_grid;
    }

    /// Iterator over all cells with coordinates.
    pub fn iterCells(self: *const CellGrid) CellIterator {
        return CellIterator{
            .grid = self,
            .x = 0,
            .y = 0,
        };
    }
};

/// Read-only cell view (returned by getCell).
pub const CellView = struct {
    source_offset: u32,
    source_len: u32,
    source_encoding: encoding.SourceEncoding,
    contents: CellContents,
    fg_color: color.Color,
    bg_color: color.Color,
    attr_flags: attributes.AttributeFlags,
    wide_flag: WideFlag,
    hyperlink_id: u32,
    dirty: bool,
};

/// Cell input (for setCell, optional fields only update non-null values).
pub const CellInput = struct {
    source_offset: ?u32 = null,
    source_len: ?u32 = null,
    source_encoding: ?encoding.SourceEncoding = null,
    contents: ?CellContents = null,
    fg_color: ?color.Color = null,
    bg_color: ?color.Color = null,
    attr_flags: ?attributes.AttributeFlags = null,
    wide_flag: ?WideFlag = null,
    hyperlink_id: ?u32 = null,
};

/// Cell iterator item containing coordinates and cell view.
pub const CellIteratorItem = struct {
    x: u32,
    y: u32,
    cell: CellView,
};

/// Iterator over cell grid coordinates and views.
pub const CellIterator = struct {
    grid: *const CellGrid,
    x: u32,
    y: u32,

    pub fn next(self: *CellIterator) ?CellIteratorItem {
        if (self.y >= self.grid.height) return null;

        const result = CellIteratorItem{
            .x = self.x,
            .y = self.y,
            .cell = self.grid.getCell(self.x, self.y) catch unreachable, // Valid coords
        };

        // Advance to next position
        self.x += 1;
        if (self.x >= self.grid.width) {
            self.x = 0;
            self.y += 1;
        }

        return result;
    }
};

/// Grapheme pool for multi-codepoint character storage.
///
/// Stores UTF-8 encoded grapheme clusters with arena allocation.
/// Cells reference graphemes by ID (1-based index).
pub const GraphemePool = struct {
    allocator: std.mem.Allocator,
    graphemes: std.ArrayList([]const u8),
    next_id: u32,

    pub fn init(allocator: std.mem.Allocator) GraphemePool {
        return GraphemePool{
            .allocator = allocator,
            .graphemes = std.ArrayList([]const u8).empty,
            .next_id = 1, // ID 0 reserved
        };
    }

    pub fn deinit(self: *GraphemePool) void {
        for (self.graphemes.items) |grapheme| {
            self.allocator.free(grapheme);
        }
        self.graphemes.deinit(self.allocator);
    }

    /// Intern grapheme cluster, returning unique ID.
    ///
    /// Deduplicates identical graphemes (same byte sequence).
    pub fn intern(self: *GraphemePool, utf8_bytes: []const u8) !u32 {
        // Check for existing match
        for (self.graphemes.items, 0..) |existing, i| {
            if (std.mem.eql(u8, existing, utf8_bytes)) {
                return @as(u32, @intCast(i + 1)); // 1-based ID
            }
        }

        // Add new grapheme
        const copy = try self.allocator.dupe(u8, utf8_bytes);
        errdefer self.allocator.free(copy);

        try self.graphemes.append(self.allocator, copy);
        const id = self.next_id;
        self.next_id += 1;

        return id;
    }

    /// Get grapheme by ID.
    pub fn get(self: *const GraphemePool, id: u32) errors.Error![]const u8 {
        if (id == 0 or id > self.graphemes.items.len) {
            return error.InvalidGrapheme;
        }
        return self.graphemes.items[id - 1]; // Convert 1-based to 0-based
    }
};

// === Tests ===

test "CellGrid: initialization and dimensions" {
    const allocator = std.testing.allocator;

    var grid = try CellGrid.init(allocator, 80, 25);
    defer grid.deinit();

    try std.testing.expectEqual(@as(u32, 80), grid.width);
    try std.testing.expectEqual(@as(u32, 25), grid.height);
    try std.testing.expectEqual(@as(usize, 80 * 25), grid.contents.len);
}

test "CellGrid: get and set cell" {
    const allocator = std.testing.allocator;

    var grid = try CellGrid.init(allocator, 80, 25);
    defer grid.deinit();

    // Set cell
    const input = CellInput{
        .contents = CellContents{ .scalar = 'A' },
        .fg_color = color.Color{ .rgb = .{ .r = 255, .g = 0, .b = 0 } },
    };
    try grid.setCell(10, 5, input);

    // Get cell
    const cell = try grid.getCell(10, 5);
    try std.testing.expectEqual(@as(u21, 'A'), cell.contents.scalar);
    try std.testing.expect(cell.dirty); // Should be marked dirty
}

test "CellGrid: bounds checking" {
    const allocator = std.testing.allocator;

    var grid = try CellGrid.init(allocator, 80, 25);
    defer grid.deinit();

    // Out of bounds access should error
    try std.testing.expectError(error.InvalidCoordinate, grid.getCell(100, 100));

    const input = CellInput{ .contents = CellContents{ .scalar = 'X' } };
    try std.testing.expectError(error.InvalidCoordinate, grid.setCell(100, 100, input));
}

test "CellGrid: resize preserves data" {
    const allocator = std.testing.allocator;

    var grid = try CellGrid.init(allocator, 10, 10);
    defer grid.deinit();

    // Set some cells
    const input = CellInput{ .contents = CellContents{ .scalar = 'X' } };
    try grid.setCell(5, 5, input);

    // Resize larger
    try grid.resize(20, 20);

    // Original cell should be preserved
    const cell = try grid.getCell(5, 5);
    try std.testing.expectEqual(@as(u21, 'X'), cell.contents.scalar);

    // New cells should have defaults
    const new_cell = try grid.getCell(15, 15);
    try std.testing.expectEqual(@as(u21, ' '), new_cell.contents.scalar);
}

test "CellGrid: iterator" {
    const allocator = std.testing.allocator;

    var grid = try CellGrid.init(allocator, 3, 2);
    defer grid.deinit();

    var iter = grid.iterCells();
    var count: usize = 0;

    while (iter.next()) |_| {
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 6), count);
}

test "GraphemePool: intern and retrieve" {
    const allocator = std.testing.allocator;

    var pool = GraphemePool.init(allocator);
    defer pool.deinit();

    const emoji = "👍";
    const id1 = try pool.intern(emoji);
    const id2 = try pool.intern(emoji); // Should deduplicate

    try std.testing.expectEqual(id1, id2);

    const retrieved = try pool.get(id1);
    try std.testing.expectEqualStrings(emoji, retrieved);
}

test "GraphemePool: invalid ID" {
    const allocator = std.testing.allocator;

    var pool = GraphemePool.init(allocator);
    defer pool.deinit();

    try std.testing.expectError(error.InvalidGrapheme, pool.get(0));
    try std.testing.expectError(error.InvalidGrapheme, pool.get(999));
}
