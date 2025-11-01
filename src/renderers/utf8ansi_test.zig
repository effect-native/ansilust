const std = @import("std");
const testing = std.testing;
const Utf8Ansi = @import("utf8ansi.zig");

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

const ir = @import("../ir/lib.zig");

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

    // Set CP437 box-drawing characters
    // 0xDA = ┌ (box top-left)
    // 0xC4 = ─ (box horizontal)
    // 0xBF = ┐ (box top-right)
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 0xDA } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 0xC4 } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 0xBF } });

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

    // Set CP437 shading characters
    // 0xB0 = ░ (light shade)
    // 0xB1 = ▒ (medium shade)
    // 0xB2 = ▓ (dark shade)
    // 0xDB = █ (full block)
    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 0xB0 } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 0xB1 } });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 0xB2 } });
    try doc.setCell(3, 0, .{ .contents = .{ .scalar = 0xDB } });

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

test "ColorMapper emits SGR 38;5;N for DOS palette indices" {
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

    // Should contain 256-color SGR for red (DOS 4 → ANSI 256 code 124)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;5;124m") != null);
    // Should contain 256-color SGR for blue (DOS 1 → ANSI 256 code 19)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;5;19m") != null);
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

    // Count occurrences of the red foreground code (DOS 4 → ANSI 124)
    var count: usize = 0;
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, buffer, pos, "\x1b[38;5;124m")) |found_pos| {
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
