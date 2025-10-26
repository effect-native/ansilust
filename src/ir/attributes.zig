//! Ansilust IR - Attributes Module
//!
//! Defines text attribute bitflags for cell styling.
//! Supports classic ANSI attributes plus modern terminal extensions.
//!
//! Layout (32-bit):
//! - Lower 16 bits: Classic ANSI attributes + extensions
//! - Upper 16 bits: Modern attributes (underline style, reserved)
//!
//! Implements RQ-Attr-1, RQ-Attr-2, RQ-Attr-3.

const std = @import("std");
const Color = @import("color.zig").Color;

/// Text attribute bitflags (32-bit packed struct).
///
/// Provides efficient storage and manipulation of text styling attributes.
/// Compatible with both classic BBS art and modern terminal sequences.
pub const AttributeFlags = packed struct(u32) {
    // === Classic ANSI Attributes (Bits 0-10) ===

    /// Bold/bright text (SGR 1)
    bold: bool = false,

    /// Faint/dim text (SGR 2) - opposite of bold
    faint: bool = false,

    /// Italic text (SGR 3)
    italic: bool = false,

    /// Underline (SGR 4) - see underline_style for specifics
    underline: bool = false,

    /// Slow blink (SGR 5) - classic BBS blinking text
    /// In iCE colors mode, blink bit repurposed for high-intensity background
    blink: bool = false,

    /// Rapid blink (SGR 6) - rarely supported
    rapid_blink: bool = false,

    /// Reverse/inverse video (SGR 7) - swap fg/bg
    reverse: bool = false,

    /// Concealed/invisible text (SGR 8)
    invisible: bool = false,

    /// Strikethrough/crossed-out (SGR 9)
    strikethrough: bool = false,

    /// Overline (SGR 53) - line above text
    overline: bool = false,

    /// Protected text (prevents modification)
    protected: bool = false,

    // === Modern Extensions (Bits 11-15) ===

    /// Subscript (non-standard)
    subscript: bool = false,

    /// Superscript (non-standard)
    superscript: bool = false,

    /// Proportional spacing (SGR 26)
    proportional: bool = false,

    /// Reserved for future use
    _reserved1: bool = false,

    /// Reserved for future use
    _reserved2: bool = false,

    // === Upper 16 bits (Bits 16-31) ===

    /// Underline style (3 bits, 8 variants)
    underline_style: UnderlineStyle = .none,

    /// Has separate underline color (flag)
    has_underline_color: bool = false,

    /// Reserved for hyperlink marker expansion
    _reserved3: u4 = 0,

    /// Reserved for future attributes
    _reserved4: u8 = 0,

    /// Create attributes with no styling.
    pub fn none() AttributeFlags {
        return .{};
    }

    /// Create attributes with only bold set.
    pub fn withBold() AttributeFlags {
        return .{ .bold = true };
    }

    /// Create attributes with only italic set.
    pub fn withItalic() AttributeFlags {
        return .{ .italic = true };
    }

    /// Create attributes with underline style.
    pub fn withUnderline(style: UnderlineStyle) AttributeFlags {
        return .{
            .underline = style != .none,
            .underline_style = style,
        };
    }

    /// Fluent API: Set bold attribute.
    pub fn setBold(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.bold = value;
        return attrs;
    }

    /// Fluent API: Set faint attribute.
    pub fn setFaint(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.faint = value;
        return attrs;
    }

    /// Fluent API: Set italic attribute.
    pub fn setItalic(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.italic = value;
        return attrs;
    }

    /// Fluent API: Set underline with style.
    pub fn setUnderline(self: AttributeFlags, style: UnderlineStyle) AttributeFlags {
        var attrs = self;
        attrs.underline = style != .none;
        attrs.underline_style = style;
        return attrs;
    }

    /// Fluent API: Set blink attribute.
    pub fn setBlink(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.blink = value;
        return attrs;
    }

    /// Fluent API: Set reverse attribute.
    pub fn setReverse(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.reverse = value;
        return attrs;
    }

    /// Fluent API: Set invisible attribute.
    pub fn setInvisible(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.invisible = value;
        return attrs;
    }

    /// Fluent API: Set strikethrough attribute.
    pub fn setStrikethrough(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.strikethrough = value;
        return attrs;
    }

    /// Fluent API: Set overline attribute.
    pub fn setOverline(self: AttributeFlags, value: bool) AttributeFlags {
        var attrs = self;
        attrs.overline = value;
        return attrs;
    }

    /// Returns true if any attributes are set.
    pub fn hasAny(self: AttributeFlags) bool {
        return @as(u32, @bitCast(self)) != 0;
    }

    /// Returns true if no attributes are set.
    pub fn isEmpty(self: AttributeFlags) bool {
        return !self.hasAny();
    }

    /// Clear all attributes.
    pub fn clear() AttributeFlags {
        return .{};
    }

    /// Combine two attribute sets (bitwise OR).
    pub fn combine(self: AttributeFlags, other: AttributeFlags) AttributeFlags {
        const a: u32 = @bitCast(self);
        const b: u32 = @bitCast(other);
        return @bitCast(a | b);
    }

    /// Check if this attribute set contains all attributes from another.
    pub fn contains(self: AttributeFlags, other: AttributeFlags) bool {
        const a: u32 = @bitCast(self);
        const b: u32 = @bitCast(other);
        return (a & b) == b;
    }

    /// Convert to raw u32 value.
    pub fn toRaw(self: AttributeFlags) u32 {
        return @bitCast(self);
    }

    /// Create from raw u32 value.
    pub fn fromRaw(raw: u32) AttributeFlags {
        return @bitCast(raw);
    }
};

/// Underline style variants (3-bit encoding).
///
/// Supports multiple underline types as specified in modern terminal
/// protocols (Kitty, VTE). Implements RQ-Attr-2.
pub const UnderlineStyle = enum(u3) {
    /// No underline
    none = 0,

    /// Single underline (SGR 4)
    single = 1,

    /// Double underline (SGR 21)
    double = 2,

    /// Curly/wavy underline (SGR 4:3)
    curly = 3,

    /// Dotted underline (SGR 4:4)
    dotted = 4,

    /// Dashed underline (SGR 4:5)
    dashed = 5,

    /// Reserved for future styles
    _reserved1 = 6,

    /// Reserved for future styles
    _reserved2 = 7,

    /// Returns SGR parameter for this style (if applicable).
    pub fn toSGR(self: UnderlineStyle) ?u8 {
        return switch (self) {
            .none => 24, // SGR 24: underline off
            .single => 4, // SGR 4: underline on
            .double => 21, // SGR 21: double underline
            .curly, .dotted, .dashed => 4, // Use SGR 4, then subparameter
            else => null,
        };
    }

    /// Returns true if this is an underline style.
    pub fn isUnderline(self: UnderlineStyle) bool {
        return self != .none;
    }
};

/// Style record combining attributes and optional underline color.
///
/// Used in style tables for reference-counted style management.
/// Implements RQ-Attr-3.
pub const Style = struct {
    /// Foreground color
    fg: Color,

    /// Background color
    bg: Color,

    /// Attribute bitflags
    attributes: AttributeFlags,

    /// Separate underline color (optional, RQ-Attr-3)
    underline_color: ?Color,

    /// Optional hyperlink ID reference
    hyperlink_id: ?u32,

    /// Create default style (white on black, no attributes).
    pub fn default() Style {
        return Style{
            .fg = Color{ .palette = 7 }, // White
            .bg = Color{ .palette = 0 }, // Black
            .attributes = AttributeFlags.none(),
            .underline_color = null,
            .hyperlink_id = null,
        };
    }

    /// Create style with colors and attributes.
    pub fn init(fg: Color, bg: Color, attributes: AttributeFlags) Style {
        return Style{
            .fg = fg,
            .bg = bg,
            .attributes = attributes,
            .underline_color = null,
            .hyperlink_id = null,
        };
    }

    /// Set underline color (enables separate underline color flag).
    pub fn setUnderlineColor(self: Style, color: Color) Style {
        var style = self;
        style.underline_color = color;
        style.attributes.has_underline_color = true;
        return style;
    }

    /// Check if two styles are equal.
    pub fn eql(self: Style, other: Style) bool {
        if (!self.fg.eql(other.fg)) return false;
        if (!self.bg.eql(other.bg)) return false;
        if (self.attributes.toRaw() != other.attributes.toRaw()) return false;

        // Compare underline colors
        if (self.underline_color == null and other.underline_color == null) {
            // Both null, OK
        } else if (self.underline_color != null and other.underline_color != null) {
            if (!self.underline_color.?.eql(other.underline_color.?)) return false;
        } else {
            return false; // One null, one not
        }

        // Compare hyperlink IDs
        if (self.hyperlink_id != other.hyperlink_id) return false;

        return true;
    }

    /// Create style with reversed fg/bg (for reverse attribute rendering).
    pub fn reversed(self: Style) Style {
        var style = self;
        const tmp = style.fg;
        style.fg = style.bg;
        style.bg = tmp;
        return style;
    }
};

// === Tests ===

test "AttributeFlags: basic operations" {
    const none = AttributeFlags.none();
    try std.testing.expect(none.isEmpty());
    try std.testing.expect(!none.hasAny());

    const bold_attrs = AttributeFlags.withBold();
    try std.testing.expect(bold_attrs.bold);
    try std.testing.expect(!bold_attrs.italic);
    try std.testing.expect(bold_attrs.hasAny());
}

test "AttributeFlags: fluent API" {
    const attrs = AttributeFlags.none()
        .setBold(true)
        .setItalic(true)
        .setUnderline(.single);

    try std.testing.expect(attrs.bold);
    try std.testing.expect(attrs.italic);
    try std.testing.expect(attrs.underline);
    try std.testing.expectEqual(UnderlineStyle.single, attrs.underline_style);
}

test "AttributeFlags: combine and contains" {
    const bold_attrs = AttributeFlags.withBold();
    const italic_attrs = AttributeFlags.withItalic();
    const combined = bold_attrs.combine(italic_attrs);

    try std.testing.expect(combined.bold);
    try std.testing.expect(combined.italic);
    try std.testing.expect(combined.contains(bold_attrs));
    try std.testing.expect(combined.contains(italic_attrs));
    try std.testing.expect(!bold_attrs.contains(italic_attrs));
}

test "AttributeFlags: size constraint" {
    try std.testing.expectEqual(@as(usize, 4), @sizeOf(AttributeFlags));
}

test "UnderlineStyle: SGR conversion" {
    try std.testing.expectEqual(@as(?u8, 24), UnderlineStyle.none.toSGR());
    try std.testing.expectEqual(@as(?u8, 4), UnderlineStyle.single.toSGR());
    try std.testing.expectEqual(@as(?u8, 21), UnderlineStyle.double.toSGR());
}

test "Style: default and equality" {
    const style1 = Style.default();
    const style2 = Style.default();

    try std.testing.expect(style1.eql(style2));
    try std.testing.expect(style1.attributes.isEmpty());
}

test "Style: underline color" {
    const style = Style.default()
        .setUnderlineColor(Color{ .rgb = .{ .r = 255, .g = 0, .b = 0 } });

    try std.testing.expect(style.underline_color != null);
    try std.testing.expect(style.attributes.has_underline_color);
}

test "Style: reversed colors" {
    const original = Style.init(
        Color{ .palette = 7 }, // White fg
        Color{ .palette = 0 }, // Black bg
        AttributeFlags.none(),
    );

    const rev = original.reversed();
    try std.testing.expect(rev.fg.eql(Color{ .palette = 0 }));
    try std.testing.expect(rev.bg.eql(Color{ .palette = 7 }));
}
