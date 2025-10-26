//! Ansilust IR - Color Module
//!
//! Defines color representation and palette management.
//! Supports three color modes:
//! - None: Terminal default (distinct from explicit black)
//! - Palette: Index into a palette table (0-255)
//! - RGB: True color (24-bit)
//!
//! Implements RQ-Palette-1 through RQ-Palette-5.

const std = @import("std");
const errors = @import("errors.zig");

/// Color representation with three variants.
///
/// The `none` variant represents the terminal's default color,
/// which is distinct from explicit black (Palette(0) or RGB(0,0,0)).
/// This distinction is critical for Ghostty alignment (RQ-Ghostty-1).
pub const Color = union(enum) {
    /// Terminal default color (not black!)
    /// Used when no explicit color is set; terminal decides rendering.
    none,

    /// Palette index (0-255)
    /// References an entry in a palette table.
    /// Classic BBS art uses 16-color ANSI palette (0-15).
    palette: u8,

    /// True color (24-bit RGB)
    /// Modern terminal support; no palette required.
    rgb: RGB,

    /// Returns true if this is the terminal default.
    pub fn isDefault(self: Color) bool {
        return switch (self) {
            .none => true,
            else => false,
        };
    }

    /// Returns true if this color is black (either palette 0 or RGB(0,0,0)).
    /// Does NOT return true for `none` - that's the terminal default.
    pub fn isBlack(self: Color) bool {
        return switch (self) {
            .none => false,
            .palette => |idx| idx == 0,
            .rgb => |c| c.r == 0 and c.g == 0 and c.b == 0,
        };
    }

    /// Convert to RGB using the provided palette.
    /// Returns error.InvalidEncoding if palette index out of bounds.
    pub fn toRGB(self: Color, palette: ?*const Palette) errors.Error!?RGB {
        return switch (self) {
            .none => null,
            .rgb => |c| c,
            .palette => |idx| {
                const pal = palette orelse return error.InvalidEncoding;
                if (idx >= pal.colors.len) return error.InvalidEncoding;
                return pal.colors[idx];
            },
        };
    }

    /// Equality comparison considering palette resolution.
    pub fn eql(self: Color, other: Color) bool {
        return switch (self) {
            .none => switch (other) {
                .none => true,
                else => false,
            },
            .palette => |idx| switch (other) {
                .palette => |other_idx| idx == other_idx,
                else => false,
            },
            .rgb => |c| switch (other) {
                .rgb => |other_c| c.r == other_c.r and c.g == other_c.g and c.b == other_c.b,
                else => false,
            },
        };
    }
};

/// 24-bit RGB color.
pub const RGB = struct {
    r: u8,
    g: u8,
    b: u8,

    /// Black (0, 0, 0)
    pub const black = RGB{ .r = 0, .g = 0, .b = 0 };

    /// White (255, 255, 255)
    pub const white = RGB{ .r = 255, .g = 255, .b = 255 };

    /// Create RGB from hex value (0xRRGGBB)
    pub fn fromHex(hex: u24) RGB {
        return RGB{
            .r = @intCast((hex >> 16) & 0xFF),
            .g = @intCast((hex >> 8) & 0xFF),
            .b = @intCast(hex & 0xFF),
        };
    }

    /// Convert to hex value (0xRRGGBB)
    pub fn toHex(self: RGB) u24 {
        return (@as(u24, self.r) << 16) | (@as(u24, self.g) << 8) | @as(u24, self.b);
    }

    /// Convert to normalized floats [0.0, 1.0] for OpenTUI compatibility
    pub fn toNormalized(self: RGB) struct { r: f32, g: f32, b: f32 } {
        return .{
            .r = @as(f32, @floatFromInt(self.r)) / 255.0,
            .g = @as(f32, @floatFromInt(self.g)) / 255.0,
            .b = @as(f32, @floatFromInt(self.b)) / 255.0,
        };
    }

    /// Create RGB from normalized floats
    pub fn fromNormalized(r: f32, g: f32, b: f32) RGB {
        return RGB{
            .r = @intFromFloat(@min(255.0, @max(0.0, r * 255.0))),
            .g = @intFromFloat(@min(255.0, @max(0.0, g * 255.0))),
            .b = @intFromFloat(@min(255.0, @max(0.0, b * 255.0))),
        };
    }
};

/// Palette definition with color lookup table.
pub const Palette = struct {
    /// Palette identifier (for de-duplication)
    id: u32,

    /// Color entries (typically 16 or 256)
    colors: []RGB,

    allocator: std.mem.Allocator,

    /// Create palette with specified number of colors (initialized to black)
    pub fn init(allocator: std.mem.Allocator, id: u32, size: usize) !Palette {
        const colors = try allocator.alloc(RGB, size);
        @memset(colors, RGB.black);
        return Palette{
            .id = id,
            .colors = colors,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Palette) void {
        self.allocator.free(self.colors);
    }

    /// Set color at index
    pub fn setColor(self: *Palette, index: u8, color: RGB) errors.Error!void {
        if (index >= self.colors.len) return error.InvalidEncoding;
        self.colors[index] = color;
    }

    /// Get color at index
    pub fn getColor(self: *const Palette, index: u8) errors.Error!RGB {
        if (index >= self.colors.len) return error.InvalidEncoding;
        return self.colors[index];
    }

    /// Clone palette with new allocator
    pub fn clone(self: *const Palette, allocator: std.mem.Allocator, new_id: u32) !Palette {
        const pal = try Palette.init(allocator, new_id, self.colors.len);
        @memcpy(pal.colors, self.colors);
        return pal;
    }
};

/// Standard 16-color ANSI palette (CGA/EGA compatible)
pub const ANSI_PALETTE: [16]RGB = .{
    RGB.fromHex(0x000000), // 0: Black
    RGB.fromHex(0xAA0000), // 1: Red
    RGB.fromHex(0x00AA00), // 2: Green
    RGB.fromHex(0xAA5500), // 3: Yellow/Brown
    RGB.fromHex(0x0000AA), // 4: Blue
    RGB.fromHex(0xAA00AA), // 5: Magenta
    RGB.fromHex(0x00AAAA), // 6: Cyan
    RGB.fromHex(0xAAAAAA), // 7: White/Light Gray
    RGB.fromHex(0x555555), // 8: Bright Black/Dark Gray
    RGB.fromHex(0xFF5555), // 9: Bright Red
    RGB.fromHex(0x55FF55), // 10: Bright Green
    RGB.fromHex(0xFFFF55), // 11: Bright Yellow
    RGB.fromHex(0x5555FF), // 12: Bright Blue
    RGB.fromHex(0xFF55FF), // 13: Bright Magenta
    RGB.fromHex(0x55FFFF), // 14: Bright Cyan
    RGB.fromHex(0xFFFFFF), // 15: Bright White
};

/// VGA 256-color palette (includes ANSI 16 + extended colors)
pub fn createVGAPalette(allocator: std.mem.Allocator, id: u32) !Palette {
    var pal = try Palette.init(allocator, id, 256);

    // First 16 colors: ANSI palette
    @memcpy(pal.colors[0..16], &ANSI_PALETTE);

    // Colors 16-231: 6x6x6 RGB cube
    var i: usize = 16;
    var r: u8 = 0;
    while (r < 6) : (r += 1) {
        var g: u8 = 0;
        while (g < 6) : (g += 1) {
            var b: u8 = 0;
            while (b < 6) : (b += 1) {
                const rv = if (r > 0) (r * 40 + 55) else 0;
                const gv = if (g > 0) (g * 40 + 55) else 0;
                const bv = if (b > 0) (b * 40 + 55) else 0;
                pal.colors[i] = RGB{ .r = rv, .g = gv, .b = bv };
                i += 1;
            }
        }
    }

    // Colors 232-255: Grayscale ramp
    var gray: u8 = 0;
    while (gray < 24) : (gray += 1) {
        const val = gray * 10 + 8;
        pal.colors[232 + gray] = RGB{ .r = val, .g = val, .b = val };
    }

    return pal;
}

/// Amiga Workbench 16-color palette
pub const WORKBENCH_PALETTE: [16]RGB = .{
    RGB.fromHex(0xAAAAAA), // 0: Light Gray
    RGB.fromHex(0x000000), // 1: Black
    RGB.fromHex(0xFFFFFF), // 2: White
    RGB.fromHex(0x6688BB), // 3: Blue
    RGB.fromHex(0xFF8800), // 4: Orange
    RGB.fromHex(0x000088), // 5: Dark Blue
    RGB.fromHex(0xFFFFFF), // 6: White
    RGB.fromHex(0xCCCCCC), // 7: Light Gray
    RGB.fromHex(0xDD9955), // 8: Tan
    RGB.fromHex(0x8899AA), // 9: Light Blue
    RGB.fromHex(0x000088), // 10: Dark Blue
    RGB.fromHex(0x333333), // 11: Dark Gray
    RGB.fromHex(0x66AAEE), // 12: Sky Blue
    RGB.fromHex(0x88CCFF), // 13: Light Cyan
    RGB.fromHex(0xBBBBBB), // 14: Light Gray
    RGB.fromHex(0x333333), // 15: Dark Gray
};

/// Palette type identifier
pub const PaletteType = enum {
    ansi, // Standard 16-color ANSI
    vga, // VGA 256-color
    workbench, // Amiga Workbench
    custom, // User-defined palette
};

/// Palette table managing multiple palettes per document
pub const PaletteTable = struct {
    palettes: std.ArrayList(Palette),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) PaletteTable {
        return PaletteTable{
            .palettes = std.ArrayList(Palette).empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PaletteTable) void {
        for (self.palettes.items) |*pal| {
            pal.deinit();
        }
        self.palettes.deinit(self.allocator);
    }

    /// Add a palette to the table
    pub fn add(self: *PaletteTable, palette: Palette) errors.Error!u32 {
        // Check for duplicate ID
        for (self.palettes.items) |*existing| {
            if (existing.id == palette.id) {
                return error.DuplicatePaletteId;
            }
        }

        try self.palettes.append(self.allocator, palette);
        return palette.id;
    }

    /// Get palette by ID
    pub fn get(self: *const PaletteTable, id: u32) ?*const Palette {
        for (self.palettes.items) |*pal| {
            if (pal.id == id) return pal;
        }
        return null;
    }

    /// Get palette by index in table
    pub fn getByIndex(self: *const PaletteTable, index: usize) ?*const Palette {
        if (index >= self.palettes.items.len) return null;
        return &self.palettes.items[index];
    }
};

// === Tests ===

test "Color: terminal default vs black distinction" {
    const default_color = Color{ .none = {} };
    const palette_black = Color{ .palette = 0 };
    const rgb_black = Color{ .rgb = RGB.black };

    try std.testing.expect(default_color.isDefault());
    try std.testing.expect(!palette_black.isDefault());
    try std.testing.expect(!rgb_black.isDefault());

    try std.testing.expect(!default_color.isBlack());
    try std.testing.expect(palette_black.isBlack());
    try std.testing.expect(rgb_black.isBlack());
}

test "Color: RGB hex conversion" {
    const red = RGB.fromHex(0xFF0000);
    try std.testing.expectEqual(@as(u8, 255), red.r);
    try std.testing.expectEqual(@as(u8, 0), red.g);
    try std.testing.expectEqual(@as(u8, 0), red.b);
    try std.testing.expectEqual(@as(u24, 0xFF0000), red.toHex());
}

test "Color: RGB normalized conversion" {
    const color = RGB{ .r = 128, .g = 64, .b = 192 };
    const norm = color.toNormalized();
    try std.testing.expect(norm.r > 0.5 and norm.r < 0.51);
    try std.testing.expect(norm.g > 0.25 and norm.g < 0.26);
    try std.testing.expect(norm.b > 0.75 and norm.b < 0.76);
}

test "Palette: create and access" {
    const allocator = std.testing.allocator;
    var pal = try Palette.init(allocator, 1, 16);
    defer pal.deinit();

    try pal.setColor(7, RGB.white);
    const retrieved = try pal.getColor(7);
    try std.testing.expectEqual(RGB.white.r, retrieved.r);
    try std.testing.expectEqual(RGB.white.g, retrieved.g);
    try std.testing.expectEqual(RGB.white.b, retrieved.b);
}

test "PaletteTable: add and retrieve" {
    const allocator = std.testing.allocator;
    var table = PaletteTable.init(allocator);
    defer table.deinit();

    const pal1 = try Palette.init(allocator, 1, 16);
    const pal2 = try Palette.init(allocator, 2, 256);

    _ = try table.add(pal1);
    _ = try table.add(pal2);

    const retrieved = table.get(1);
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqual(@as(u32, 1), retrieved.?.id);

    // Duplicate ID should fail
    var pal_dup = try Palette.init(allocator, 1, 16);
    defer pal_dup.deinit();
    try std.testing.expectError(error.DuplicatePaletteId, table.add(pal_dup));
}

test "Standard palettes: ANSI palette sanity" {
    try std.testing.expectEqual(@as(u24, 0x000000), ANSI_PALETTE[0].toHex()); // Black
    try std.testing.expectEqual(@as(u24, 0xAAAAAA), ANSI_PALETTE[7].toHex()); // White/Gray
    try std.testing.expectEqual(@as(u24, 0xFFFFFF), ANSI_PALETTE[15].toHex()); // Bright White
}

test "VGA palette: generation" {
    const allocator = std.testing.allocator;
    var vga = try createVGAPalette(allocator, 0);
    defer vga.deinit();

    // First 16 should match ANSI
    try std.testing.expectEqual(ANSI_PALETTE[0].toHex(), vga.colors[0].toHex());
    try std.testing.expectEqual(ANSI_PALETTE[15].toHex(), vga.colors[15].toHex());

    // Grayscale ramp at end
    const gray_start = vga.colors[232];
    const gray_end = vga.colors[255];
    try std.testing.expect(gray_start.r < gray_end.r);
    try std.testing.expect(gray_start.r == gray_start.g and gray_start.g == gray_start.b);
}
