const std = @import("std");
const ansilust = @import("ansilust");
const build_options = @import("build_options");

const version = build_options.version;

fn printVersion() void {
    const stdout_file = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
    stdout_file.writeAll("ansilust " ++ version ++ "\n") catch {};
}

fn printHelp(file: std.fs.File) void {
    file.writeAll(
        \\ansilust - Next-generation text art processing system
        \\
        \\USAGE:
        \\    ansilust [OPTIONS] <file.ans> [<file2.ans> ...]
        \\
        \\OPTIONS:
        \\    -h, --help       Print this help message
        \\    -V, --version    Print version information
        \\
        \\EXAMPLES:
        \\    ansilust artwork.ans           Render ANSI art to terminal
        \\    ansilust file1.ans file2.ans   Render multiple files
        \\
    ) catch {};
}

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

    const stdout_file = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
    const stderr_file = std.fs.File{ .handle = std.posix.STDERR_FILENO };

    var file_count: usize = 0;
    var show_help = false;
    var show_version = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            show_help = true;
        } else if (std.mem.eql(u8, arg, "-V") or std.mem.eql(u8, arg, "--version")) {
            show_version = true;
        } else if (std.mem.startsWith(u8, arg, "-")) {
            std.debug.print("error: unknown option '{s}'\n", .{arg});
            stderr_file.writeAll("Try 'ansilust --help' for more information.\n") catch {};
            std.process.exit(1);
        } else {
            try processFile(allocator, arg);
            file_count += 1;
        }
    }

    if (show_version) {
        printVersion();
        return;
    }

    if (show_help) {
        printHelp(stdout_file);
        return;
    }

    if (file_count == 0) {
        printHelp(stderr_file);
        std.process.exit(1);
    }
}
