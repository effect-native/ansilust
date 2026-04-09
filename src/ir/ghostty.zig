//! Ansilust IR - Ghostty Integration Module
//!
//! Renderer helper for Ghostty-compatible terminal output.
//! Generates ANSI escape sequences aligned with Ghostty semantics.
//!
const std = @import("std");
const testing = std.testing;
const color = @import("color.zig");
const document = @import("document.zig");

const wrap_disable = "\x1b[?7l";
const wrap_enable = "\x1b[?7h";
const hyperlink_close = "\x1b]8;;\x1b\\";
const default_fg = color.Color{ .palette = 7 };
const default_bg = color.Color{ .palette = 0 };

const RowState = struct {
    hyperlink_id: u32 = 0,
    fg: color.Color = default_fg,
    bg: color.Color = default_bg,
};

/// Generate Ghostty-compatible ANSI stream from document.
pub fn toGhosttyStream(doc: *const document.Document, writer: anytype) !void {
    const dims = doc.getDimensions();

    try writer.writeAll(wrap_disable);
    defer writer.writeAll(wrap_enable) catch {};

    const last_visible_row = try findLastVisibleRow(doc, dims.width, dims.height);
    if (last_visible_row == null) return;

    var y: u32 = 0;
    while (y <= last_visible_row.?) : (y += 1) {
        try writeRow(doc, writer, y, dims.width);
        if (y < last_visible_row.?) {
            try writer.writeByte('\n');
        }
    }
}

fn findLastVisibleRow(doc: *const document.Document, width: u32, height: u32) !?u32 {
    if (height == 0) return null;

    var y = height;
    while (y > 0) {
        y -= 1;
        if (try rowHasVisibleContent(doc, y, width)) {
            return y;
        }
    }

    return null;
}

fn rowHasVisibleContent(doc: *const document.Document, y: u32, width: u32) !bool {
    var x: u32 = 0;
    while (x < width) : (x += 1) {
        const cell = try doc.getCell(x, y);

        switch (cell.contents) {
            .scalar => |scalar| if (scalar != ' ') return true,
            .grapheme => return true,
        }

        if (!isDefaultForeground(cell.fg_color) or !isDefaultBackground(cell.bg_color) or cell.hyperlink_id != 0) {
            return true;
        }
    }

    return false;
}

fn writeRow(doc: *const document.Document, writer: anytype, y: u32, width: u32) !void {
    var state = RowState{};

    var x: u32 = 0;
    while (x < width) : (x += 1) {
        const cell = try doc.getCell(x, y);

        try transitionHyperlink(doc, writer, &state, cell.hyperlink_id);

        if (!colorsEqual(cell.fg_color, state.fg) or !colorsEqual(cell.bg_color, state.bg)) {
            try emitCellColors(writer, cell.fg_color, cell.bg_color);
            state.fg = cell.fg_color;
            state.bg = cell.bg_color;
        }
        try writeCellContents(doc, writer, cell.contents);
    }

    try closeHyperlink(writer, state.hyperlink_id);
}

fn transitionHyperlink(doc: *const document.Document, writer: anytype, state: *RowState, next_hyperlink_id: u32) !void {
    if (next_hyperlink_id == state.hyperlink_id) return;

    try closeHyperlink(writer, state.hyperlink_id);
    try openHyperlink(doc, writer, next_hyperlink_id);
    state.hyperlink_id = next_hyperlink_id;
}

fn closeHyperlink(writer: anytype, hyperlink_id: u32) !void {
    if (hyperlink_id == 0) return;
    try writer.writeAll(hyperlink_close);
}

fn openHyperlink(doc: *const document.Document, writer: anytype, hyperlink_id: u32) !void {
    if (hyperlink_id == 0) return;

    const link = doc.getHyperlink(hyperlink_id) orelse return error.ResourceNotFound;
    try writer.writeAll("\x1b]8;");
    if (link.params) |params| {
        try writer.writeAll(params);
    }
    try writer.writeAll(";");
    try writer.writeAll(link.uri);
    try writer.writeAll("\x1b\\");
}

fn colorsEqual(a: anytype, b: @TypeOf(a)) bool {
    return switch (a) {
        .none => switch (b) {
            .none => true,
            else => false,
        },
        .palette => |a_idx| switch (b) {
            .palette => |b_idx| a_idx == b_idx,
            else => false,
        },
        .rgb => |a_rgb| switch (b) {
            .rgb => |b_rgb| a_rgb.r == b_rgb.r and a_rgb.g == b_rgb.g and a_rgb.b == b_rgb.b,
            else => false,
        },
    };
}

fn emitCellColors(writer: anytype, fg: anytype, bg: anytype) !void {
    switch (fg) {
        .none => try writer.writeAll("\x1b[39m"),
        .palette => |idx| try writer.print("\x1b[38;5;{d}m", .{idx}),
        .rgb => |rgb| try writer.print("\x1b[38;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b }),
    }

    switch (bg) {
        .none => try writer.writeAll("\x1b[49m"),
        .palette => |idx| try writer.print("\x1b[48;5;{d}m", .{idx}),
        .rgb => |rgb| try writer.print("\x1b[48;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b }),
    }
}

fn writeCellContents(doc: *const document.Document, writer: anytype, contents: anytype) !void {
    switch (contents) {
        .scalar => |scalar| try writeScalar(writer, scalar),
        .grapheme => |id| {
            const grapheme = try doc.getGrapheme(id);
            try writer.writeAll(grapheme);
        },
    }
}

fn writeScalar(writer: anytype, scalar: u21) !void {
    var buf: [4]u8 = undefined;
    const codepoint: u21 = if (scalar == 0) ' ' else scalar;
    const len = std.unicode.utf8Encode(codepoint, &buf) catch {
        try writer.writeAll("�");
        return;
    };
    try writer.writeAll(buf[0..len]);
}

fn isDefaultForeground(value: anytype) bool {
    return switch (value) {
        .none => true,
        .palette => |idx| idx == 7,
        .rgb => false,
    };
}

fn isDefaultBackground(value: anytype) bool {
    return switch (value) {
        .none => true,
        .palette => |idx| idx == 0,
        .rgb => false,
    };
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
