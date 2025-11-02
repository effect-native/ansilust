//! Random artwork display command
//!
//! Implements the `16c random-1` command: picks a random file from the archive,
//! downloads it, saves it to the random cache, and displays it.

const std = @import("std");
const Allocator = std.mem.Allocator;
const interface = @import("../database/interface.zig");
const HttpClient = @import("../protocols/http.zig").HttpClient;
const FileStorage = @import("../storage/files.zig").FileStorage;
const PlatformPaths = @import("../storage/paths.zig").PlatformPaths;
const ArchiveDatabase = interface.ArchiveDatabase;

/// Execute the random-1 command
///
/// Flow:
/// 1. Initialize platform paths and create directories
/// 2. Initialize database (hardcoded)
/// 3. Get random file entry
/// 4. Download file to temp location
/// 5. Save to random/ directory with timestamp
/// 6. Clean up old files (keep last 10)
/// 7. Display with ansilust renderer (stubbed for now)
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

    // 7. Display artwork (stubbed for now - will integrate renderer in Task 5.1.8)
    try displayArtwork(saved_path);

    std.debug.print("\n✓ Done!\n", .{});
}

/// Display artwork
///
/// For MVP, exec cat to display file. Full ansilust renderer integration in Phase 5.2.
fn displayArtwork(file_path: []const u8) !void {
    std.debug.print("\n", .{});

    // Simple MVP: exec cat with inherit stdout
    var child = std.process.Child.init(
        &[_][]const u8{ "cat", file_path },
        std.heap.page_allocator,
    );
    _ = try child.spawnAndWait();

    std.debug.print("\n", .{});
}
