const std = @import("std");
const ansilust = @import("ansilust");

fn processFile(allocator: std.mem.Allocator, path: []const u8) !void {
    const file_data = std.fs.cwd().readFileAlloc(allocator, path, 100 * 1024 * 1024) catch |e| {
        std.debug.print("error reading file: {s}\n", .{@errorName(e)});
        return;
    };
    defer allocator.free(file_data);

    var doc = ansilust.parsers.ansi.parse(allocator, file_data) catch |e| {
        std.debug.print("parse error: {s}\n", .{@errorName(e)});
        return;
    };
    defer doc.deinit();

    const dims = doc.getDimensions();

    std.debug.print("File: {s}\n", .{path});
    std.debug.print("Size: {d} bytes\n", .{file_data.len});
    std.debug.print("Source: {any}\n", .{doc.source_format});
    std.debug.print("Grid: {}x{}\n", .{ dims.width, dims.height });
    std.debug.print("Hints: ice_colors={}, letter_spacing={}px, aspect_ratio={any}\n", .{ doc.ice_colors, doc.letter_spacing, doc.aspect_ratio });

    // Count non-space cells
    var non_space: usize = 0;
    var iter = doc.grid.iterCells();
    while (iter.next()) |itc| {
        if (itc.cell.contents.getScalar()) |s| {
            if (s != ' ') non_space += 1;
        } else {
            non_space += 1;
        }
    }
    std.debug.print("Cells (non-space): {d}\n", .{non_space});

    if (doc.sauce_record) |*s| {
        std.debug.print("--- SAUCE ---\n", .{});
        std.debug.print("Title: {s}\n", .{s.title});
        std.debug.print("Author: {s}\n", .{s.author});
        std.debug.print("Group: {s}\n", .{s.group});
        std.debug.print("Date: {s}\n", .{s.date});
        std.debug.print("Columns: {any}, Lines: {any}\n", .{ s.getColumns(), s.getLines() });
        std.debug.print("Font: {s}\n", .{s.font_name});
        std.debug.print("Flags: ice_colors={}, letter_spacing={}px, aspect_ratio={any}\n", .{ s.flags.ice_colors, s.flags.getLetterSpacing(), s.flags.getAspectRatio() });
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // skip argv0

    var file_count: usize = 0;
    while (args.next()) |path| {
        if (file_count > 0) {
            std.debug.print("\n{s}\n\n", .{"=" ** 80});
        }
        try processFile(allocator, path);
        file_count += 1;
    }

    if (file_count == 0) {
        std.debug.print("usage: ansilust <file.ans> [<file2.ans> ...]\n", .{});
        return;
    }
}
