const std = @import("std");
const testing = std.testing;
const Utf8Ansi = @import("utf8ansi.zig");
const ir = @import("../ir/lib.zig");
const parsers = @import("parsers");

// Helper for managed ArrayList in Zig 0.15
fn ArrayList(comptime T: type) type {
    return std.array_list.AlignedManaged(T, null);
}

test "TerminalGuard emits DECAWM toggle in both modes" {
    const allocator = testing.allocator;

    // Test TTY mode
    {
        var output = ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), true);
        defer guard.deinit();

        const result = output.items;

        // Should contain DECAWM disable sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?7l") != null);
    }

    // Test file mode
    {
        var output = ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), false);
        defer guard.deinit();

        const result = output.items;

        // Should contain DECAWM disable sequence even in file mode
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?7l") != null);
    }
}

test "TerminalGuard emits cursor hide only in TTY mode" {
    const allocator = testing.allocator;

    // Test TTY mode - should emit cursor hide (but NOT clear screen)
    {
        var output = ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), true);
        defer guard.deinit();

        const result = output.items;

        // Should contain cursor hide sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?25l") != null);
    }

    // Test file mode - should NOT emit cursor hide
    {
        var output = ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), false);
        defer guard.deinit();

        const result = output.items;

        // Should NOT contain cursor hide sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?25l") == null);
    }
}

test "TerminalGuard restores terminal state on deinit" {
    const allocator = testing.allocator;

    var output = ArrayList(u8).init(allocator);
    defer output.deinit();

    {
        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), true);
        defer guard.deinit();
    }

    const result = output.items;

    // Should contain DECAWM restore sequence at the end
    try testing.expect(std.mem.lastIndexOf(u8, result, "\x1b[?7h") != null);
    // Should contain cursor show sequence at the end (TTY mode)
    try testing.expect(std.mem.lastIndexOf(u8, result, "\x1b[?25h") != null);
}

// === Cycle 2: Minimal Render Pipeline ===

test "render emits newlines for row separation" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 2);
    defer doc.deinit();

    // Set some simple ASCII cells
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 'B' } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 'C' } });
    try doc.setCell(0, 1, .{ .contents = .{ .scalar = 'X' } });
    try doc.setCell(1, 1, .{ .contents = .{ .scalar = 'Y' } });
    try doc.setCell(2, 1, .{ .contents = .{ .scalar = 'Z' } });

    var output = ArrayList(u8).init(allocator);
    defer output.deinit();

    const options = Utf8Ansi.RenderOptions{ .is_tty = false };
    try Utf8Ansi.render(allocator, &doc, output.writer().any(), options);

    const result = output.items;

    // Should contain the content from both rows
    try testing.expect(std.mem.indexOf(u8, result, "ABC") != null);
    try testing.expect(std.mem.indexOf(u8, result, "XYZ") != null);
    // Should contain newline for row separation
    try testing.expect(std.mem.indexOf(u8, result, "\n") != null);
}

test "render handles minimal document" {
    const allocator = testing.allocator;

    // Use 1x1 document (0x0 is rejected by CellGrid validation)
    var doc = try ir.Document.init(allocator, 1, 1);
    defer doc.deinit();

    var output = ArrayList(u8).init(allocator);
    defer output.deinit();

    const options = Utf8Ansi.RenderOptions{ .is_tty = false };
    try Utf8Ansi.render(allocator, &doc, output.writer().any(), options);

    const result = output.items;

    // Should still emit terminal guard sequences
    try testing.expect(std.mem.indexOf(u8, result, "\x1b[?7l") != null);
    try testing.expect(std.mem.indexOf(u8, result, "\x1b[?7h") != null);
}

// === Cycle 3: CP437 Glyph Mapping ===

test "GlyphMapper translates box-drawing chars" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 1);
    defer doc.deinit();

    // Set Unicode box-drawing characters (IR stores Unicode scalars)
    // U+250C = ┌ (top-left corner)
    // U+2500 = ─ (horizontal)
    // U+2510 = ┐ (top-right corner)
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 0x250C } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 0x2500 } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 0x2510 } });

    var output = ArrayList(u8).init(allocator);
    defer output.deinit();

    const options = Utf8Ansi.RenderOptions{ .is_tty = false };
    try Utf8Ansi.render(allocator, &doc, output.writer().any(), options);

    const result = output.items;

    // Should contain Unicode box-drawing characters
    try testing.expect(std.mem.indexOf(u8, result, "┌") != null);
    try testing.expect(std.mem.indexOf(u8, result, "─") != null);
    try testing.expect(std.mem.indexOf(u8, result, "┐") != null);
}

test "GlyphMapper translates shading chars" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 4, 1);
    defer doc.deinit();

    // Set Unicode shading characters (IR stores Unicode scalars)
    // U+2591 = ░ (light shade)
    // U+2592 = ▒ (medium shade)
    // U+2593 = ▓ (dark shade)
    // U+2588 = █ (full block)
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 0x2591 } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 0x2592 } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 0x2593 } });
    try doc.setCell(3, 0, .{ .contents = .{ .scalar = 0x2588 } });

    var output = ArrayList(u8).init(allocator);
    defer output.deinit();

    const options = Utf8Ansi.RenderOptions{ .is_tty = false };
    try Utf8Ansi.render(allocator, &doc, output.writer().any(), options);

    const result = output.items;

    // Should contain Unicode shading characters
    try testing.expect(std.mem.indexOf(u8, result, "░") != null);
    try testing.expect(std.mem.indexOf(u8, result, "▒") != null);
    try testing.expect(std.mem.indexOf(u8, result, "▓") != null);
    try testing.expect(std.mem.indexOf(u8, result, "█") != null);
}

test "GlyphMapper handles ASCII passthrough" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 5, 1);
    defer doc.deinit();

    // Set ASCII characters (0-127)
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'H' } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 'e' } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 'l' } });
    try doc.setCell(3, 0, .{ .contents = .{ .scalar = 'l' } });
    try doc.setCell(4, 0, .{ .contents = .{ .scalar = 'o' } });

    var output = ArrayList(u8).init(allocator);
    defer output.deinit();

    const options = Utf8Ansi.RenderOptions{ .is_tty = false };
    try Utf8Ansi.render(allocator, &doc, output.writer().any(), options);

    const result = output.items;

    // Should contain ASCII passthrough
    try testing.expect(std.mem.indexOf(u8, result, "Hello") != null);
}

// === CLI Integration Helper ===

test "renderToBuffer returns bytes suitable for stdout" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 1);
    defer doc.deinit();

    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 'B' } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 'C' } });

    // Render to buffer
    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should contain DECAWM sequences
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[?7l") != null);
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[?7h") != null);
    // Should contain content
    try testing.expect(std.mem.indexOf(u8, buffer, "ABC") != null);
}

// === Cycle 4: Color Emission ===

test "ColorMapper emits 24-bit RGB for DOS palette indices (default)" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 2, 1);
    defer doc.deinit();

    // Set cells with DOS palette colors (foreground)
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'R' },
        .fg_color = .{ .palette = 4 }, // DOS red (index 4)
    });
    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'B' },
        .fg_color = .{ .palette = 1 }, // DOS blue (index 1)
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should emit 24-bit RGB for red (DOS 4 → RGB 170,0,0)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;170;0;0m") != null);
    // Should emit 24-bit RGB for blue (DOS 1 → RGB 0,0,170)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;0;0;170m") != null);
}

test "ColorMapper emits SGR 39/49 for Color None" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 1, 1);
    defer doc.deinit();

    // Set cell with default/none colors
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'X' },
        .fg_color = .none,
        .bg_color = .none,
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should contain SGR 39 (default foreground) and SGR 49 (default background)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[39m") != null);
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[49m") != null);
}

// === Cycle 5: Style Batching ===

test "RenderState batches consecutive cells with same style" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 5, 1);
    defer doc.deinit();

    // Set multiple cells with the SAME color
    const fg_color: ir.Color = .{ .palette = 4 }; // DOS red
    const bg_color: ir.Color = .{ .palette = 0 }; // Black

    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' }, .fg_color = fg_color, .bg_color = bg_color });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 'B' }, .fg_color = fg_color, .bg_color = bg_color });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 'C' }, .fg_color = fg_color, .bg_color = bg_color });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Count occurrences of the red foreground code (DOS 4 → RGB 170,0,0)
    var count: usize = 0;
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, buffer, pos, "\x1b[38;2;170;0;0m")) |found_pos| {
        count += 1;
        pos = found_pos + 1;
    }

    // Should emit color code only ONCE for consecutive cells (not 3 times)
    try testing.expectEqual(@as(usize, 1), count);
}

test "RenderState emits SGR 0 when style changes" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 1);
    defer doc.deinit();

    // Set cells with DIFFERENT colors
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'R' },
        .fg_color = .{ .palette = 4 }, // Red
    });
    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'G' },
        .fg_color = .{ .palette = 2 }, // Green
    });
    try doc.setCell(2, 0, .{
        .contents = .{ .scalar = 'B' },
        .fg_color = .{ .palette = 1 }, // Blue
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should contain SGR 0 (reset) before style changes
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[0m") != null);
}

// === Cycle 7: Truecolor Support ===

test "ColorMapper emits SGR 38;2;R;G;B in truecolor mode" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 2, 1);
    defer doc.deinit();

    // Set cells with RGB colors
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'R' },
        .fg_color = .{ .rgb = .{ .r = 255, .g = 0, .b = 0 } }, // Pure red
    });
    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'B' },
        .bg_color = .{ .rgb = .{ .r = 0, .g = 0, .b = 255 } }, // Pure blue background
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should contain 24-bit truecolor SGR for foreground
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;255;0;0m") != null);
    // Should contain 24-bit truecolor SGR for background
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[48;2;0;0;255m") != null);
}

// === NEW: 24-bit Truecolor by Default (2025-11-01) ===
// Following spec update: FR1.2.2 - emit 24-bit RGB for palette colors by default
// Rationale: 8-bit 256-color indices can't be trusted across terminals

test "ColorMapper emits 24-bit RGB for DOS palette colors by default" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 1);
    defer doc.deinit();

    // Set cells with DOS palette indices (not RGB)
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'R' },
        .fg_color = .{ .palette = 4 }, // DOS red (palette index 4)
    });
    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'G' },
        .fg_color = .{ .palette = 2 }, // DOS green (palette index 2)
    });
    try doc.setCell(2, 0, .{
        .contents = .{ .scalar = 'B' },
        .bg_color = .{ .palette = 1 }, // DOS blue background (palette index 1)
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should emit 24-bit RGB for DOS red (0xAA0000 = 170,0,0)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;170;0;0m") != null);

    // Should emit 24-bit RGB for DOS green (0x00AA00 = 0,170,0)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;0;170;0m") != null);

    // Should emit 24-bit RGB for DOS blue background (0x0000AA = 0,0,170)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[48;2;0;0;170m") != null);

    // Should NOT contain 256-color SGR sequences for palette colors
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;5;") == null);
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[48;5;") == null);
}

test "DOS palette high-intensity colors emit correct RGB values" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 1);
    defer doc.deinit();

    // Test high-intensity colors (8-15)
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'Y' },
        .fg_color = .{ .palette = 14 }, // Yellow (0xFFFF55)
    });
    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'W' },
        .fg_color = .{ .palette = 15 }, // White (0xFFFFFF)
    });
    try doc.setCell(2, 0, .{
        .contents = .{ .scalar = 'D' },
        .fg_color = .{ .palette = 8 }, // Dark Gray (0x555555)
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Yellow: 0xFFFF55 = 255,255,85
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;255;255;85m") != null);

    // White: 0xFFFFFF = 255,255,255
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;255;255;255m") != null);

    // Dark Gray: 0x555555 = 85,85,85
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;2;85;85;85m") != null);
}

// === Cycle 8: File Mode Validation ===

test "render in file mode omits cursor hide/clear" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 1);
    defer doc.deinit();

    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' } });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false); // is_tty = false
    defer allocator.free(buffer);

    // Should NOT contain cursor hide
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[?25l") == null);
    // Should NOT contain clear screen
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[2J") == null);
}

test "render in file mode still emits DECAWM toggles" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 1);
    defer doc.deinit();

    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' } });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false); // is_tty = false
    defer allocator.free(buffer);

    // Should contain DECAWM disable
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[?7l") != null);
    // Should contain DECAWM restore
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[?7h") != null);
}

// === Bramwell Feedback: Scrollback Issue ===

test "TTY mode uses relative positioning (no absolute CSI row;col H)" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 3, 2);
    defer doc.deinit();

    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' } });
    try doc.setCell(0, 1, .{ .contents = .{ .scalar = 'B' } });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, true); // is_tty = true
    defer allocator.free(buffer);

    // Should NOT contain absolute cursor positioning (CSI row;col H)
    // This ensures output appends where cursor is, not overwrites screen top
    try testing.expect(std.mem.indexOf(u8, buffer, ";1H") == null);

    // Should contain newlines for row separation
    try testing.expect(std.mem.indexOf(u8, buffer, "\n") != null);
}

// === NUL Byte Rendering ===
// Inspired by: reference/sixteencolors/fire-43/US-JELLY.ANS (5,723 NUL bytes used as spacing)
// Prior art: PabloDraw treats NUL (scalar 0) as blank/invisible character
//
// CP437 byte 0x00 when used for DISPLAY should render as SPACE (0x20), not NULL control char.
// Emitting literal NULL bytes (0x00) in UTF-8 output is problematic - terminals may:
//   - Ignore them entirely (no cursor advance)
//   - Interpret them as string terminators
//   - Display them as replacement characters
//
// Solution: Render scalar 0 as SPACE (0x20) to ensure cursor advances and layout is preserved.

test "Renderer emits space for NUL byte (scalar 0)" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 5, 1);
    defer doc.deinit();

    // Set cells: 'A', NUL, 'B'
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 0 } }); // NUL
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 'B' } });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Output should NOT contain literal NULL byte (0x00)
    for (buffer) |byte| {
        try testing.expect(byte != 0x00);
    }

    // Should contain 'A' and 'B'
    try testing.expect(std.mem.indexOf(u8, buffer, "A") != null);
    try testing.expect(std.mem.indexOf(u8, buffer, "B") != null);

    // The character between A and B should be a space (0x20), not NULL
    // Find the sequence "A B" (with space between)
    const needle = "A B";
    try testing.expect(std.mem.indexOf(u8, buffer, needle) != null);
}

test "Renderer handles multiple consecutive NUL bytes as spaces" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 6, 1);
    defer doc.deinit();

    // Set cells: 'X', NUL, NUL, NUL, 'Y'
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'X' } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 0 } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 0 } });
    try doc.setCell(3, 0, .{ .contents = .{ .scalar = 0 } });
    try doc.setCell(4, 0, .{ .contents = .{ .scalar = 'Y' } });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should NOT contain any NULL bytes
    for (buffer) |byte| {
        try testing.expect(byte != 0x00);
    }

    // Should contain "X   Y" (3 spaces between X and Y)
    const needle = "X   Y";
    try testing.expect(std.mem.indexOf(u8, buffer, needle) != null);
}

// OSC 8 Hyperlink Rendering Tests

test "Renderer emits OSC 8 sequences for hyperlinks" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 10, 1);
    defer doc.deinit();

    // Add hyperlink to document
    const link_id = try doc.addHyperlink("http://example.com", null);

    // Set cells with hyperlink
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'L' },
        .hyperlink_id = link_id,
    });
    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'i' },
        .hyperlink_id = link_id,
    });
    try doc.setCell(2, 0, .{
        .contents = .{ .scalar = 'n' },
        .hyperlink_id = link_id,
    });
    try doc.setCell(3, 0, .{
        .contents = .{ .scalar = 'k' },
        .hyperlink_id = link_id,
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should contain OSC 8 start sequence
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b]8;;http://example.com\x1b\\") != null);

    // Should contain "Link" text
    try testing.expect(std.mem.indexOf(u8, buffer, "Link") != null);

    // Should contain OSC 8 end sequence
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b]8;;\x1b\\") != null);
}

test "Renderer emits OSC 8 with parameters" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 10, 1);
    defer doc.deinit();

    // Add hyperlink with id parameter
    const link_id = try doc.addHyperlink("http://example.com", "id=test123");

    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'A' },
        .hyperlink_id = link_id,
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should contain OSC 8 with params
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b]8;id=test123;http://example.com\x1b\\") != null);
}

test "Renderer handles hyperlink end correctly" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 10, 1);
    defer doc.deinit();

    const link_id = try doc.addHyperlink("http://example.com", null);

    // Cell 0: with hyperlink
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'A' },
        .hyperlink_id = link_id,
    });

    // Cell 1: without hyperlink
    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'B' },
        .hyperlink_id = null,
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should start hyperlink before 'A'
    const start_seq = "\x1b]8;;http://example.com\x1b\\";
    const start_idx = std.mem.indexOf(u8, buffer, start_seq);
    try testing.expect(start_idx != null);

    // Should end hyperlink after 'A' and before 'B'
    const end_seq = "\x1b]8;;\x1b\\";
    const end_idx = std.mem.indexOf(u8, buffer, end_seq);
    try testing.expect(end_idx != null);
    try testing.expect(end_idx.? > start_idx.?);
}

test "Renderer handles multiple hyperlinks in sequence" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 10, 1);
    defer doc.deinit();

    const link1 = try doc.addHyperlink("http://first.com", null);
    const link2 = try doc.addHyperlink("http://second.com", null);

    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'A' },
        .hyperlink_id = link1,
    });

    try doc.setCell(1, 0, .{
        .contents = .{ .scalar = 'B' },
        .hyperlink_id = link2,
    });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should contain both hyperlinks
    try testing.expect(std.mem.indexOf(u8, buffer, "http://first.com") != null);
    try testing.expect(std.mem.indexOf(u8, buffer, "http://second.com") != null);

    // Should have two hyperlink end sequences (one after each link)
    var count: usize = 0;
    var search_offset: usize = 0;
    while (std.mem.indexOfPos(u8, buffer, search_offset, "\x1b]8;;\x1b\\")) |idx| {
        count += 1;
        search_offset = idx + 1;
    }
    try testing.expect(count >= 2);
}

test "Renderer skips hyperlinks for cells without hyperlink_id" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 10, 1);
    defer doc.deinit();

    // All cells without hyperlinks
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 'B' } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 'C' } });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Should NOT contain any OSC 8 sequences
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b]8;") == null);
}

// Integration: Round-trip test for hyperlinks (parse ANSI → render UTF8ANSI)

test "Integration: Round-trip hyperlinks through parser and renderer" {
    const allocator = testing.allocator;
    const ansi_parser = parsers.ansi;

    // Input ANSI with hyperlink
    const input = "\x1b]8;;https://ansilust.dev\x1b\\Ansilust\x1b]8;;\x1b\\ is great!";

    // Parse to IR
    var doc = try ansi_parser.parse(allocator, input);
    defer doc.deinit();

    // Verify hyperlink in document
    try testing.expectEqual(@as(usize, 1), doc.hyperlink_table.count());
    const link = doc.hyperlink_table.get(1);
    try testing.expect(link != null);
    try testing.expectEqualStrings("https://ansilust.dev", link.?.uri);

    // Verify cells have correct hyperlink IDs
    var x: u32 = 0;
    while (x < 8) : (x += 1) { // "Ansilust" = 8 chars
        const cell = try doc.getCell(x, 0);
        try testing.expectEqual(@as(u32, 1), cell.hyperlink_id);
    }

    // Verify cells after hyperlink have no hyperlink
    const cell_after = try doc.getCell(8, 0); // space after "Ansilust"
    try testing.expectEqual(@as(u32, 0), cell_after.hyperlink_id);

    // Render to UTF8ANSI
    const output = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(output);

    // Verify output contains hyperlink sequences
    try testing.expect(std.mem.indexOf(u8, output, "\x1b]8;;https://ansilust.dev\x1b\\") != null);
    try testing.expect(std.mem.indexOf(u8, output, "Ansilust") != null);
    try testing.expect(std.mem.indexOf(u8, output, "\x1b]8;;\x1b\\") != null);
}

// Contextual Glyph Rendering Tests

test "Renderer: tilde after quote-backtick renders as SMALL TILDE" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 10, 1);
    defer doc.deinit();

    // Create the sequence: "`~ (quote, backtick, tilde)
    // This should render tilde as U+02DC (˜ SMALL TILDE) for better baseline alignment
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = '"' } }); // U+0022 QUOTATION MARK
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = '`' } }); // U+0060 GRAVE ACCENT
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = '~' } }); // U+007E TILDE → should render as U+02DC

    const output = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(output);

    // Check that U+02DC (˜ SMALL TILDE) appears in output (UTF-8: CB 9C)
    const has_small_tilde = std.mem.indexOf(u8, output, "\xCB\x9C") != null;
    try testing.expect(has_small_tilde);

    // Verify the regular tilde (U+007E) does NOT appear where the small tilde should be
    // Strip ANSI codes to check the actual character sequence
    var cleaned = ArrayList(u8).init(allocator);
    defer cleaned.deinit();

    var i: usize = 0;
    while (i < output.len) {
        if (output[i] == 0x1B and i + 1 < output.len and output[i + 1] == '[') {
            // Skip ANSI sequence
            while (i < output.len and output[i] != 'm') : (i += 1) {}
            i += 1;
        } else {
            try cleaned.append(output[i]);
            i += 1;
        }
    }

    // The cleaned output should contain "`˜ not "`~
    const has_quote_backtick_small_tilde = std.mem.indexOf(u8, cleaned.items, "\"`˜") != null;
    try testing.expect(has_quote_backtick_small_tilde);
}

test "Renderer: tilde globally renders as SMALL TILDE for ANSI art" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 20, 1);
    defer doc.deinit();

    // Create text with tildes: ~strike~
    // ALL tildes now render as U+02DC (SMALL TILDE) for better baseline alignment in art
    const text = "~strike~";
    for (text, 0..) |char, i| {
        try doc.setCell(@intCast(i), 0, .{ .contents = .{ .scalar = char } });
    }

    const output = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(output);

    // Strip ANSI codes
    var cleaned = ArrayList(u8).init(allocator);
    defer cleaned.deinit();

    var i: usize = 0;
    while (i < output.len) {
        if (output[i] == 0x1B and i + 1 < output.len and output[i + 1] == '[') {
            // Skip ANSI sequence
            while (i < output.len and output[i] != 'm') : (i += 1) {}
            i += 1;
        } else {
            try cleaned.append(output[i]);
            i += 1;
        }
    }

    // Should contain SMALL TILDE (U+02DC = CB 9C in UTF-8)
    const has_small_tilde = std.mem.indexOf(u8, cleaned.items, "\xCB\x9C") != null;
    try testing.expect(has_small_tilde);

    // Verify it renders as ˜strike˜ not ~strike~
    const has_small_tilde_text = std.mem.indexOf(u8, cleaned.items, "˜strike˜") != null;
    try testing.expect(has_small_tilde_text);
}
