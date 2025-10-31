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
