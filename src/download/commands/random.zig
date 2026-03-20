//! Random artwork display command
//!
//! Implements the `16c random-1` command: picks a random file from the archive,
//! downloads it, saves it to the random cache, and displays it.

const std = @import("std");
const Allocator = std.mem.Allocator;
const ansilust = @import("ansilust");
const interface = @import("../database/interface.zig");
const HttpClient = @import("../protocols/http.zig").HttpClient;
const FileStorage = @import("../storage/files.zig").FileStorage;
const PlatformPaths = @import("../storage/paths.zig").PlatformPaths;
const ArchiveDatabase = interface.ArchiveDatabase;

pub const RandomPlaybackLoop = struct {
    delay_ns: u64 = 0,

    pub fn playOnce(self: RandomPlaybackLoop, allocator: Allocator) !void {
        _ = self;
        try executeRandomOne(allocator);
    }

    pub fn run(self: RandomPlaybackLoop, allocator: Allocator, iterations: ?usize) !void {
        var remaining = iterations;

        while (remaining == null or remaining.? > 0) {
            try self.playOnce(allocator);

            if (remaining) |*count| {
                count.* -= 1;
                if (count.* == 0) break;
            }

            if (self.delay_ns > 0) {
                std.Thread.sleep(self.delay_ns);
            }
        }
    }
};

/// Execute the random-1 command
///
/// Flow:
/// 1. Initialize platform paths and create directories
/// 2. Initialize database (hardcoded)
/// 3. Get random file entry
/// 4. Download file to temp location
/// 5. Save to random/ directory with timestamp
/// 6. Clean up old files (keep last 10)
/// 7. Display with ansilust parser + UTF8ANSI renderer
/// 8. Clean up temp file
///
/// # Arguments
/// - `allocator`: Memory allocator
///
/// # Errors
/// - Various errors from download, storage, or renderer operations
pub fn executeRandomOne(allocator: Allocator) !void {
    std.debug.print("16c random-1: Fetching random artwork...\n", .{});

    // 1. Initialize platform paths
    var paths = try PlatformPaths.init(allocator);
    defer paths.deinit();

    // Create directories if needed
    try paths.ensureDirectoriesExist();

    if (try selectLocalArtwork(allocator, paths.random_dir, paths.local_dir)) |local_path| {
        defer allocator.free(local_path);

        std.debug.print("Selected local artwork: {s}\n", .{local_path});
        try displayArtwork(local_path);
        std.debug.print("\n✓ Done!\n", .{});
        return;
    }

    // 2. Initialize database
    var db = try ArchiveDatabase.init(allocator);
    defer db.deinit();

    // 3. Get random file
    const file = try db.getRandomFile();
    std.debug.print("Selected: {s} from {s} ({d})\n", .{
        file.filename,
        file.pack_name,
        file.year,
    });

    // 4. Download file to temp location
    const temp_path = try std.fmt.allocPrint(
        allocator,
        "/tmp/16c-random-{d}.tmp",
        .{std.time.timestamp()},
    );
    defer allocator.free(temp_path);

    std.debug.print("Downloading from {s}...\n", .{file.source_url});
    var http_client = HttpClient.init(allocator);
    defer http_client.deinit();

    try http_client.download(file.source_url, temp_path);
    defer std.fs.cwd().deleteFile(temp_path) catch {};

    std.debug.print("Download complete!\n", .{});

    // 5. Save to random/ directory
    var storage = FileStorage.init(allocator);
    const saved_path = try storage.saveToRandom(temp_path, file.filename, paths.random_dir);
    defer allocator.free(saved_path);

    std.debug.print("Saved to: {s}\n", .{saved_path});

    // 6. Clean up old files
    try storage.cleanupRandom(paths.random_dir, 10);

    // 7. Display artwork through ansilust
    try displayArtwork(saved_path);

    std.debug.print("\n✓ Done!\n", .{});
}

/// Display artwork
///
/// Parse and render artwork to stdout using ansilust.
fn displayArtwork(file_path: []const u8) !void {
    const file_data = try std.fs.cwd().readFileAlloc(
        std.heap.page_allocator,
        file_path,
        100 * 1024 * 1024,
    );
    defer std.heap.page_allocator.free(file_data);

    var doc = try ansilust.parsers.ansi.parse(std.heap.page_allocator, file_data);
    defer doc.deinit();

    const is_tty = std.posix.isatty(std.posix.STDOUT_FILENO);
    const buffer = try ansilust.renderToUtf8Ansi(std.heap.page_allocator, &doc, is_tty);
    defer std.heap.page_allocator.free(buffer);

    const stdout_file = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
    try stdout_file.writeAll(buffer);
}

fn selectLocalArtwork(
    allocator: Allocator,
    random_dir: []const u8,
    local_dir: []const u8,
) !?[]const u8 {
    var candidates = std.ArrayList([]const u8).init(allocator);
    defer candidates.deinit();

    try appendPlayableFilesFromDir(allocator, &candidates, random_dir);
    try appendPlayableFilesFromDir(allocator, &candidates, local_dir);

    if (candidates.items.len == 0) {
        return null;
    }

    var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.nanoTimestamp())));
    const selected_index = prng.random().uintLessThan(usize, candidates.items.len);
    const selected_path = try allocator.dupe(u8, candidates.items[selected_index]);

    for (candidates.items) |candidate| {
        allocator.free(candidate);
    }

    return selected_path;
}

fn appendPlayableFilesFromDir(
    allocator: Allocator,
    candidates: *std.ArrayList([]const u8),
    dir_path: []const u8,
) !void {
    var dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true });
    defer dir.close();

    var iterator = dir.iterate();
    while (try iterator.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!isPlayableAnsiFile(entry.name)) continue;

        const full_path = try std.fs.path.join(allocator, &[_][]const u8{ dir_path, entry.name });
        errdefer allocator.free(full_path);
        try candidates.append(full_path);
    }
}

fn isPlayableAnsiFile(file_name: []const u8) bool {
    const extension = std.fs.path.extension(file_name);
    return std.ascii.eqlIgnoreCase(extension, ".ans") or
        std.ascii.eqlIgnoreCase(extension, ".asc");
}
