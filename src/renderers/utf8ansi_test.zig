const std = @import("std");
const testing = std.testing;
const Utf8Ansi = @import("utf8ansi.zig");

test "TerminalGuard emits DECAWM toggle in both modes" {
    const allocator = testing.allocator;

    // Test TTY mode
    {
        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), true);
        defer guard.deinit();

        const result = output.items;

        // Should contain DECAWM disable sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?7l") != null);
    }

    // Test file mode
    {
        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), false);
        defer guard.deinit();

        const result = output.items;

        // Should contain DECAWM disable sequence even in file mode
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?7l") != null);
    }
}

test "TerminalGuard emits cursor hide/clear only in TTY mode" {
    const allocator = testing.allocator;

    // Test TTY mode - should emit cursor hide and clear
    {
        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), true);
        defer guard.deinit();

        const result = output.items;

        // Should contain cursor hide sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?25l") != null);
        // Should contain clear screen sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[2J") != null);
    }

    // Test file mode - should NOT emit cursor hide or clear
    {
        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();

        var guard = try Utf8Ansi.TerminalGuard.init(allocator, output.writer().any(), false);
        defer guard.deinit();

        const result = output.items;

        // Should NOT contain cursor hide sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[?25l") == null);
        // Should NOT contain clear screen sequence
        try testing.expect(std.mem.indexOf(u8, result, "\x1b[2J") == null);
    }
}

test "TerminalGuard restores terminal state on deinit" {
    const allocator = testing.allocator;

    var output = std.ArrayList(u8).init(allocator);
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

const ir = @import("../ir.zig");

test "render emits cursor positioning for each row" {
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

    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    const options = Utf8Ansi.RenderOptions{ .is_tty = false };
    try Utf8Ansi.render(allocator, &doc, output.writer().any(), options);

    const result = output.items;

    // Should contain cursor positioning for row 1 (1-indexed)
    try testing.expect(std.mem.indexOf(u8, result, "\x1b[1;1H") != null);
    // Should contain cursor positioning for row 2
    try testing.expect(std.mem.indexOf(u8, result, "\x1b[2;1H") != null);
}

test "render handles empty document" {
    const allocator = testing.allocator;

    var doc = try ir.Document.init(allocator, 0, 0);
    defer doc.deinit();

    var output = std.ArrayList(u8).init(allocator);
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

    var output = std.ArrayList(u8).init(allocator);
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

    var output = std.ArrayList(u8).init(allocator);
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

    var output = std.ArrayList(u8).init(allocator);
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

    // Should contain 256-color SGR for red (DOS 4 → ANSI 256 code 196)
    try testing.expect(std.mem.indexOf(u8, buffer, "\x1b[38;5;196m") != null);
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
    const red_on_black = .{
        .fg_color = .{ .palette = 4 }, // DOS red
        .bg_color = .{ .palette = 0 }, // Black
    };

    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'A' }, .fg_color = red_on_black.fg_color, .bg_color = red_on_black.bg_color });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 'B' }, .fg_color = red_on_black.fg_color, .bg_color = red_on_black.bg_color });
    try doc.setCell(2, 0, .{ .contents = .{ .scalar = 'C' }, .fg_color = red_on_black.fg_color, .bg_color = red_on_black.bg_color });

    const buffer = try Utf8Ansi.renderToBuffer(allocator, &doc, false);
    defer allocator.free(buffer);

    // Count occurrences of the red foreground code
    var count: usize = 0;
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, buffer, pos, "\x1b[38;5;196m")) |found_pos| {
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
