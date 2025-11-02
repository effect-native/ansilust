//! 16c CLI entry point
//!
//! Command-line interface for the 16colors archive downloader.
//! Currently supports: random-1

const std = @import("std");
const download = @import("download");
const random = download.commands.random;

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
    std.debug.print("Usage: 16c <command>\n\n", .{});
    std.debug.print("Commands:\n", .{});
    std.debug.print("  random-1    Download and display random artwork\n", .{});
    std.debug.print("  --help      Show this help message\n", .{});
    std.debug.print("  --version   Show version information\n", .{});
    std.debug.print("\n", .{});
}

fn printHelp() void {
    std.debug.print("16c - 16colors Archive Downloader\n\n", .{});
    printUsage();
    std.debug.print("Examples:\n", .{});
    std.debug.print("  16c random-1    # Display random ANSI/ASCII art\n", .{});
    std.debug.print("\n", .{});
}

fn printVersion() void {
    std.debug.print("16c version 0.1.0-alpha (Phase 5.1 MVP)\n", .{});
}
