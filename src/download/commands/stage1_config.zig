const std = @import("std");
const Allocator = std.mem.Allocator;

pub const SourceMode = enum {
    auto,
};

pub const PlaybackConfig = struct {
    dwell_seconds: u64 = 20,
};

pub const SourceConfig = struct {
    mode: SourceMode = .auto,
};

pub const Stage1Config = struct {
    playback: PlaybackConfig = .{},
    source: SourceConfig = .{},
};

const Section = enum {
    none,
    playback,
    source,
};

pub fn loadFromRoot(allocator: Allocator, root_path: []const u8, config_file_name: []const u8) !Stage1Config {
    const config_path = try std.fs.path.join(allocator, &[_][]const u8{ root_path, config_file_name });
    defer allocator.free(config_path);

    const contents = std.fs.cwd().readFileAlloc(allocator, config_path, 64 * 1024) catch |err| switch (err) {
        error.FileNotFound, error.PathNotFound => return .{},
        else => return err,
    };
    defer allocator.free(contents);

    return try parse(contents);
}

pub fn parse(contents: []const u8) !Stage1Config {
    var config = Stage1Config{};
    var section: Section = .none;

    var lines = std.mem.tokenizeScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const without_comment = stripComment(raw_line);
        const line = std.mem.trim(u8, without_comment, " \t\r");
        if (line.len == 0) continue;

        if (line[0] == '[' and line[line.len - 1] == ']') {
            const section_name = std.mem.trim(u8, line[1 .. line.len - 1], " \t");
            if (std.mem.eql(u8, section_name, "playback")) {
                section = .playback;
            } else if (std.mem.eql(u8, section_name, "source")) {
                section = .source;
            } else {
                section = .none;
            }
            continue;
        }

        const separator_index = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const key = std.mem.trim(u8, line[0..separator_index], " \t");
        const value = std.mem.trim(u8, line[separator_index + 1 ..], " \t");

        switch (section) {
            .playback => if (std.mem.eql(u8, key, "dwell_seconds")) {
                config.playback.dwell_seconds = try std.fmt.parseUnsigned(u64, value, 10);
            },
            .source => if (std.mem.eql(u8, key, "mode")) {
                const parsed = unquote(value);
                if (std.mem.eql(u8, parsed, "auto")) {
                    config.source.mode = .auto;
                } else {
                    return error.InvalidSourceMode;
                }
            },
            .none => {},
        }
    }

    return config;
}

fn stripComment(line: []const u8) []const u8 {
    const comment_index = std.mem.indexOfScalar(u8, line, '#') orelse return line;
    return line[0..comment_index];
}

fn unquote(value: []const u8) []const u8 {
    if (value.len >= 2 and value[0] == '"' and value[value.len - 1] == '"') {
        return value[1 .. value.len - 1];
    }

    return value;
}
