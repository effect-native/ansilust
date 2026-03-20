//! 16c CLI entry point
//!
//! Command-line interface for the 16colors archive downloader.
//! Currently supports: random, screensaver, random-1

const std = @import("std");
const download = @import("download");
const random = download.commands.random;
const PlaybackMode = random.PlaybackMode;
const StreamingSpeed = random.StreamingSpeed;

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
        const mode = try parsePlaybackMode(args[2..]);
        try random.executeRandomLoop(allocator, mode);
    } else if (std.mem.eql(u8, command, "screensaver")) {
        const mode = try parsePlaybackMode(args[2..]);
        try random.executeScreensaverWithMode(allocator, mode);
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

fn parsePlaybackMode(args: []const []const u8) !PlaybackMode {
    var instant = false;
    var streaming_speed: ?StreamingSpeed = null;

    var index: usize = 0;
    while (index < args.len) : (index += 1) {
        const arg = args[index];

        if (std.mem.eql(u8, arg, "--instant")) {
            instant = true;
            continue;
        }

        if (std.mem.eql(u8, arg, "--streaming-speed")) {
            index += 1;
            if (index >= args.len) {
                std.debug.print("Error: --streaming-speed requires a preset (slow, normal, fast)\n", .{});
                return error.MissingStreamingSpeedPreset;
            }

            streaming_speed = try parseStreamingSpeed(args[index]);
            continue;
        }

        std.debug.print("Error: Unknown flag '{s}'\n", .{arg});
        return error.UnknownFlag;
    }

    if (instant and streaming_speed != null) {
        std.debug.print("Error: --instant and --streaming-speed cannot be used together\n", .{});
        return error.ConflictingPlaybackFlags;
    }

    if (instant) return .instant;
    if (streaming_speed) |preset| return .{ .streaming = preset };
    return .standard;
}

fn parseStreamingSpeed(value: []const u8) !StreamingSpeed {
    if (std.mem.eql(u8, value, "slow")) return .slow;
    if (std.mem.eql(u8, value, "normal")) return .normal;
    if (std.mem.eql(u8, value, "fast")) return .fast;

    std.debug.print(
        "Error: Invalid streaming speed preset '{s}'. Supported presets: slow, normal, fast\n",
        .{value},
    );
    return error.InvalidStreamingSpeedPreset;
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
    try writer.writeAll("Usage: 16c <command> [options]\n\n");
    try writer.writeAll("Commands:\n");
    try writer.writeAll("  random      Download and continuously display random artwork\n");
    try writer.writeAll("  screensaver Run the dedicated screensaver session entrypoint\n");
    try writer.writeAll("\nPlayback options (random, screensaver):\n");
    try writer.writeAll("  --instant                   Skip dwell delay between artworks\n");
    try writer.writeAll("  --streaming-speed <preset>  Preserve selected playback mode: slow, normal, fast\n");
    try writer.writeAll("  --help      Show this help message\n");
    try writer.writeAll("  --version   Show version information\n\n");
}

fn writeHelp(writer: anytype) !void {
    try writer.writeAll("16c - 16colors Archive Downloader\n\n");
    try writeUsage(writer);
    try writer.writeAll("Examples:\n");
    try writer.writeAll("  16c random                             # Display random ANSI/ASCII art in a loop\n");
    try writer.writeAll("  16c random --instant                   # Replay local/random artwork without dwell\n");
    try writer.writeAll("  16c screensaver                        # Start the dedicated screensaver session mode\n");
    try writer.writeAll("  16c screensaver --streaming-speed fast # Preserve the selected streaming preset\n\n");
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

test "16c usage and help expose screensaver command surface" {
    var usage_output = ArrayList(u8).init(std.testing.allocator);
    defer usage_output.deinit();

    var usage_writer = usage_output.writer();
    try writeUsage(&usage_writer);

    try std.testing.expect(std.mem.indexOf(u8, usage_output.items, "screensaver") != null);

    var help_output = ArrayList(u8).init(std.testing.allocator);
    defer help_output.deinit();

    var help_writer = help_output.writer();
    try writeHelp(&help_writer);

    try std.testing.expect(std.mem.indexOf(u8, help_output.items, "16c screensaver") != null);
}

test "16c includes distinct screensaver command dispatch path" {
    const source = try std.fs.cwd().readFileAlloc(std.testing.allocator, "src/cli/sixteenc.zig", 64 * 1024);
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "std.mem.eql(u8, command, \"screensaver\")") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "std.mem.eql(u8, command, \"random\") and std.mem.eql(u8, command, \"screensaver\")") == null);
}

test "16c help documents instant and streaming speed flags for random and screensaver" {
    var output = ArrayList(u8).init(std.testing.allocator);
    defer output.deinit();

    var writer = output.writer();
    try writeHelp(&writer);

    try std.testing.expect(std.mem.indexOf(u8, output.items, "--instant") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.items, "--streaming-speed <preset>") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.items, "16c random --instant") != null);
    try std.testing.expect(std.mem.indexOf(u8, output.items, "16c screensaver --streaming-speed") != null);
}

test "16c validates supported streaming speed presets" {
    const source = try std.fs.cwd().readFileAlloc(std.testing.allocator, "src/cli/sixteenc.zig", 64 * 1024);
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "--streaming-speed") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "slow") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "normal") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "fast") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "Invalid streaming speed preset") != null);
}

test "16c rejects mutually exclusive instant and streaming speed flags for random and screensaver" {
    const source = try std.fs.cwd().readFileAlloc(std.testing.allocator, "src/cli/sixteenc.zig", 64 * 1024);
    defer std.testing.allocator.free(source);

    try std.testing.expect(std.mem.indexOf(u8, source, "random") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "screensaver") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "--instant") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "--streaming-speed") != null);
    try std.testing.expect(std.mem.indexOf(u8, source, "cannot be used together") != null);
}
