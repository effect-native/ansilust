//! 16c CLI entry point
//!
//! Command-line interface for the 16colors archive downloader.
//! Currently supports: random, random-1

const std = @import("std");
const download = @import("download");
const random = download.commands.random;
const RandomPlaybackLoop = download.RandomPlaybackLoop;

fn ArrayList(comptime T: type) type {
    return std.array_list.AlignedManaged(T, null);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Need at least program name + command
    if (args.len < 2) {
        printUsage();
        return error.MissingCommand;
    }

    const command = args[1];

    // Execute command
    if (std.mem.eql(u8, command, "random")) {
        const playback = RandomPlaybackLoop{};
        try playback.run(allocator, null);
    } else if (std.mem.eql(u8, command, "random-1")) {
        try random.executeRandomOne(allocator);
    } else if (std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        printHelp();
    } else if (std.mem.eql(u8, command, "--version") or std.mem.eql(u8, command, "-v")) {
        printVersion();
    } else {
        std.debug.print("Error: Unknown command '{s}'\n\n", .{command});
        printUsage();
        return error.UnknownCommand;
    }
}

fn printUsage() void {
    var buffer: [256]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&buffer);
    writeUsage(&stderr_writer.interface) catch return;
    stderr_writer.interface.flush() catch return;
}

fn printHelp() void {
    var buffer: [256]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&buffer);
    writeHelp(&stderr_writer.interface) catch return;
    stderr_writer.interface.flush() catch return;
}

fn printVersion() void {
    var buffer: [256]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&buffer);
    writeVersion(&stderr_writer.interface) catch return;
    stderr_writer.interface.flush() catch return;
}

fn writeUsage(writer: anytype) !void {
    try writer.writeAll("Usage: 16c <command>\n\n");
    try writer.writeAll("Commands:\n");
    try writer.writeAll("  random      Download and continuously display random artwork\n");
    try writer.writeAll("  --help      Show this help message\n");
    try writer.writeAll("  --version   Show version information\n\n");
}

fn writeHelp(writer: anytype) !void {
    try writer.writeAll("16c - 16colors Archive Downloader\n\n");
    try writeUsage(writer);
    try writer.writeAll("Examples:\n");
    try writer.writeAll("  16c random    # Display random ANSI/ASCII art in a loop\n\n");
}

fn writeVersion(writer: anytype) !void {
    try writer.writeAll("16c version 0.1.0-alpha (Phase 5.1 MVP)\n");
}

test "16c help exposes random command surface" {
    var output = ArrayList(u8).init(std.testing.allocator);
    defer output.deinit();

    var writer = output.writer();
    try writeHelp(&writer);

    try std.testing.expect(std.mem.indexOf(u8, output.items, "16c random") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.items, "random-1") == null);
}
