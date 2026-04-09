//! Ansilust IR - Ghostty Integration Module
//!
//! Renderer helper for Ghostty-compatible terminal output.
//! Generates ANSI escape sequences aligned with Ghostty semantics.
//!
//! STUB: To be implemented in Phase 5.

const std = @import("std");
const testing = std.testing;
const errors = @import("errors.zig");
const document = @import("document.zig");

/// Generate Ghostty-compatible ANSI stream from document.
pub fn toGhosttyStream(doc: *const document.Document, writer: anytype) errors.Error!void {
    _ = doc;
    _ = writer;
    return error.InvalidState; // STUB
}

test "toGhosttyStream emits minimum visible Ghostty VT surface" {
    const allocator = testing.allocator;

    var doc = try document.Document.init(allocator, 2, 2);
    defer doc.deinit();

    doc.source_format = .utf8ansi;

    try doc.setCell(0, 0, .{ .contents = .{ .scalar = 'H' } });
    try doc.setCell(1, 0, .{ .contents = .{ .scalar = 'i' } });
    try doc.setCell(0, 1, .{ .contents = .{ .scalar = '!' } });

    var output = std.ArrayListUnmanaged(u8){};
    defer output.deinit(allocator);

    if (toGhosttyStream(&doc, output.writer(allocator).any())) |_| {} else |err| {
        std.debug.print("unexpected toGhosttyStream error: {}\n", .{err});
        try testing.expect(false);
    }

    try testing.expect(std.mem.indexOf(u8, output.items, "\x1b[?7l") != null);
    try testing.expect(std.mem.indexOf(u8, output.items, "Hi\n!") != null);
    try testing.expect(std.mem.indexOf(u8, output.items, "\x1b[?7h") != null);
}

test "toGhosttyStream preserves Ghostty-critical color none and hyperlink metadata" {
    const allocator = testing.allocator;

    var doc = try document.Document.init(allocator, 1, 1);
    defer doc.deinit();

    const hyperlink_id = try doc.addHyperlink("https://example.com/ghostty", "id=bridge");
    try doc.setCell(0, 0, .{
        .contents = .{ .scalar = 'L' },
        .fg_color = .none,
        .bg_color = .none,
        .hyperlink_id = hyperlink_id,
    });

    var output = std.ArrayListUnmanaged(u8){};
    defer output.deinit(allocator);

    if (toGhosttyStream(&doc, output.writer(allocator).any())) |_| {} else |err| {
        std.debug.print("unexpected toGhosttyStream error: {}\n", .{err});
        try testing.expect(false);
    }

    try testing.expect(std.mem.indexOf(u8, output.items, "\x1b[39m") != null);
    try testing.expect(std.mem.indexOf(u8, output.items, "\x1b[49m") != null);
    try testing.expect(std.mem.indexOf(u8, output.items, "\x1b]8;id=bridge;https://example.com/ghostty\x1b\\") != null);
    try testing.expect(std.mem.indexOf(u8, output.items, "\x1b]8;;\x1b\\") != null);
}
