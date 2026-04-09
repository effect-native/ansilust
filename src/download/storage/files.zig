//! File storage management for downloaded artwork
//!
//! Handles saving files to standard 16colors directory structure with
//! timestamped filenames for the random cache.

const std = @import("std");
const Allocator = std.mem.Allocator;
const fs = std.fs;

/// File storage manager
pub const FileStorage = struct {
    allocator: Allocator,

    pub fn init(allocator: Allocator) FileStorage {
        return .{ .allocator = allocator };
    }

    /// Save a file to the random directory with timestamped filename
    ///
    /// Generates filename format: {timestamp}-{original_filename}
    /// Example: 20251101153042-CXC-STICK.ASC
    ///
    /// # Arguments
    /// - `source_path`: Path to source file
    /// - `original_filename`: Original filename to preserve
    /// - `random_dir`: Destination random directory path
    ///
    /// # Returns
    /// Full path to saved file (caller owns memory)
    ///
    /// # Errors
    /// - `OutOfMemory`: Allocation failed
    /// - `FileNotFound`: Source file doesn't exist
    /// - `PermissionDenied`: Cannot write to destination
    pub fn saveToRandom(
        self: *FileStorage,
        source_path: []const u8,
        original_filename: []const u8,
        random_dir: []const u8,
    ) ![]const u8 {
        // Generate timestamp
        const timestamp = std.time.timestamp();
        const tm = std.time.epoch.EpochSeconds{ .secs = @intCast(timestamp) };
        const day_seconds = tm.getDaySeconds();
        const epoch_day = tm.getEpochDay();
        const year_day = epoch_day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();

        // Format: YYYYMMDDHHmmss
        const timestamped_filename = try std.fmt.allocPrint(
            self.allocator,
            "{d:0>4}{d:0>2}{d:0>2}{d:0>2}{d:0>2}{d:0>2}-{s}",
            .{
                year_day.year,
                month_day.month.numeric(),
                month_day.day_index + 1,
                day_seconds.getHoursIntoDay(),
                day_seconds.getMinutesIntoHour(),
                day_seconds.getSecondsIntoMinute(),
                original_filename,
            },
        );
        defer self.allocator.free(timestamped_filename);

        // Construct full destination path
        const dest_path = try fs.path.join(
            self.allocator,
            &[_][]const u8{ random_dir, timestamped_filename },
        );
        errdefer self.allocator.free(dest_path);

        // Copy file to destination
        try fs.cwd().copyFile(source_path, fs.cwd(), dest_path, .{});

        return dest_path;
    }

    /// Clean up old files in random directory, keeping only the N newest
    ///
    /// # Arguments
    /// - `random_dir`: Random directory path
    /// - `keep_count`: Number of files to keep (default 10)
    ///
    /// # Errors
    /// - `PermissionDenied`: Cannot delete files
    pub fn cleanupRandom(self: *FileStorage, random_dir: []const u8, keep_count: usize) !void {
        var dir = try fs.openDirAbsolute(random_dir, .{ .iterate = true });
        defer dir.close();

        var files = std.ArrayList(FileInfo).empty;
        defer {
            for (files.items) |file_info| {
                self.allocator.free(file_info.name);
            }
            files.deinit(self.allocator);
        }

        var iterator = dir.iterate();
        while (try iterator.next()) |entry| {
            if (entry.kind != .file) continue;

            try files.append(self.allocator, .{
                .name = try self.allocator.dupe(u8, entry.name),
                .timestamp = parseTimestamp(entry.name),
            });
        }

        if (files.items.len <= keep_count) return;

        std.mem.sort(FileInfo, files.items, {}, FileInfo.lessThan);

        const delete_count = files.items.len - keep_count;
        for (files.items[0..delete_count]) |file_info| {
            try dir.deleteFile(file_info.name);
        }
    }
};

const FileInfo = struct {
    name: []const u8,
    timestamp: i64,

    fn lessThan(context: void, a: FileInfo, b: FileInfo) bool {
        _ = context;
        if (a.timestamp == b.timestamp) {
            return std.mem.lessThan(u8, a.name, b.name);
        }
        return a.timestamp < b.timestamp;
    }
};

fn parseTimestamp(name: []const u8) i64 {
    if (name.len < 14) return std.math.maxInt(i64);
    return std.fmt.parseInt(i64, name[0..14], 10) catch std.math.maxInt(i64);
}
