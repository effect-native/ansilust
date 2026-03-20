//! 16c CLI entry point
//!
//! Command-line interface for the 16colors archive downloader.
//! Currently supports: random-1

const std = @import("std");
const download = @import("download");
const random = download.commands.random;

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
    if (std.mem.eql(u8, command, "random-1")) {
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
    writeUsage(std.io.getStdErr().writer().any()) catch return;
}

fn printHelp() void {
    writeHelp(std.io.getStdErr().writer().any()) catch return;
}

fn printVersion() void {
    writeVersion(std.io.getStdErr().writer().any()) catch return;
}

fn writeUsage(writer: std.io.AnyWriter) !void {
    try writer.writeAll("Usage: 16c <command>\n\n");
    try writer.writeAll("Commands:\n");
    try writer.writeAll("  random-1    Download and display random artwork\n");
    try writer.writeAll("  --help      Show this help message\n");
    try writer.writeAll("  --version   Show version information\n\n");
}

fn writeHelp(writer: std.io.AnyWriter) !void {
    try writer.writeAll("16c - 16colors Archive Downloader\n\n");
    try writeUsage(writer);
    try writer.writeAll("Examples:\n");
    try writer.writeAll("  16c random-1    # Display random ANSI/ASCII art\n\n");
}

fn writeVersion(writer: std.io.AnyWriter) !void {
    try writer.writeAll("16c version 0.1.0-alpha (Phase 5.1 MVP)\n");
}

test "16c help exposes random command surface" {
    var output = ArrayList(u8).init(std.testing.allocator);
    defer output.deinit();

    try writeHelp(output.writer().any());

    try std.testing.expect(std.mem.indexOf(u8, output.items, "16c random") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.items, "random-1") == null);
}
