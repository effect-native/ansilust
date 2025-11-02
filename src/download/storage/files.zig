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
        _ = self;
        _ = random_dir;
        _ = keep_count;

        // TODO: Implement cleanup logic
        // For MVP, skip cleanup - will implement in Phase 5.2
    }
};

const FileInfo = struct {
    name: []const u8,
    timestamp: i64,

    fn lessThan(context: void, a: FileInfo, b: FileInfo) bool {
        _ = context;
        return a.timestamp < b.timestamp;
    }
};
