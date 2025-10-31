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

    // Render to buffer
    const is_tty = std.posix.isatty(std.posix.STDOUT_FILENO);
    const buffer = try ansilust.renderToUtf8Ansi(allocator, &doc, is_tty);
    defer allocator.free(buffer);

    // Write to stdout
    const stdout_file = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
    try stdout_file.writeAll(buffer);
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
        try processFile(allocator, path);
        file_count += 1;
    }

    if (file_count == 0) {
        std.debug.print("usage: ansilust <file.ans> [<file2.ans> ...]\n", .{});
        return;
    }
}
