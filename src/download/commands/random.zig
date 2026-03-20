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

var screensaver_exit_requested = std.atomic.Value(bool).init(false);

fn handleScreensaverSignal(_: c_int) callconv(.c) void {
    screensaver_exit_requested.store(true, .seq_cst);
}

pub const RandomPlaybackLoop = struct {
    delay_ns: u64 = 20 * std.time.ns_per_s,

    pub fn playOnce(self: RandomPlaybackLoop, allocator: Allocator) !void {
        _ = self;
        try executeRandom(allocator, false);
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

pub const ScreensaverPlaybackLoop = struct {
    playback: RandomPlaybackLoop = .{},

    pub fn run(self: ScreensaverPlaybackLoop, allocator: Allocator, iterations: ?usize) !void {
        var session = try ScreensaverSession.enter();
        defer session.leave();

        var remaining = iterations;

        while (remaining == null or remaining.? > 0) {
            if (screensaver_exit_requested.load(.seq_cst)) break;

            try self.playback.playOnce(allocator);

            if (remaining) |*count| {
                count.* -= 1;
                if (count.* == 0) break;
            }

            if (try screensaverShouldExit(self.playback.delay_ns)) break;
        }
    }
};

const ScreensaverSession = struct {
    manage_terminal: bool,
    previous_sigint: std.posix.Sigaction,
    previous_sigterm: std.posix.Sigaction,
    signals_installed: bool,

    fn enter() !ScreensaverSession {
        screensaver_exit_requested.store(false, .seq_cst);

        var session = ScreensaverSession{
            .manage_terminal = std.posix.isatty(std.posix.STDOUT_FILENO),
            .previous_sigint = undefined,
            .previous_sigterm = undefined,
            .signals_installed = false,
        };

        try session.enterAlternateScreen();
        session.installSignalHandlers();
        return session;
    }

    fn leave(self: *ScreensaverSession) void {
        self.restoreSignalHandlers();
        self.restoreTerminal();
    }

    fn enterAlternateScreen(self: *ScreensaverSession) !void {
        if (!self.manage_terminal) return;

        const stdout_file = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
        try stdout_file.writeAll("\x1b[?1049h\x1b[?25l");
    }

    fn restoreTerminal(self: *ScreensaverSession) void {
        if (!self.manage_terminal) return;

        const stdout_file = std.fs.File{ .handle = std.posix.STDOUT_FILENO };
        stdout_file.writeAll("\x1b[?25h\x1b[?1049l") catch {};
    }

    fn installSignalHandlers(self: *ScreensaverSession) void {
        // Best-effort Stage 1 cleanup hooks for SIGINT and SIGTERM.
        const action = std.posix.Sigaction{
            .handler = .{ .handler = handleScreensaverSignal },
            .mask = std.posix.sigemptyset(),
            .flags = 0,
        };

        std.posix.sigaction(std.posix.SIG.INT, &action, &self.previous_sigint);
        std.posix.sigaction(std.posix.SIG.TERM, &action, &self.previous_sigterm);
        self.signals_installed = true;
    }

    fn restoreSignalHandlers(self: *ScreensaverSession) void {
        if (!self.signals_installed) return;

        std.posix.sigaction(std.posix.SIG.INT, &self.previous_sigint, null);
        std.posix.sigaction(std.posix.SIG.TERM, &self.previous_sigterm, null);
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
    try executeRandom(allocator, true);
}

pub fn executeScreensaver(allocator: Allocator) !void {
    const screensaver = ScreensaverPlaybackLoop{};
    try screensaver.run(allocator, null);
}

fn executeRandom(allocator: Allocator, allow_remote_fallback: bool) !void {
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

    if (!allow_remote_fallback) {
        std.debug.print(
            "No playable local artwork found in random/ or local/. Add a .ans or .asc file there, or run 16c random-1 to seed random/.\n",
            .{},
        );
        return error.EmptyLocalArtworkPool;
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

fn screensaverShouldExit(delay_ns: u64) !bool {
    if (screensaver_exit_requested.load(.seq_cst)) return true;

    var remaining_ns = delay_ns;
    while (remaining_ns > 0) {
        const slice_ns = @min(remaining_ns, 100 * std.time.ns_per_ms);
        const timeout_ms: i32 = @intCast(slice_ns / std.time.ns_per_ms);

        if (try stdinReady(timeout_ms)) {
            var discard_buffer: [16]u8 = undefined;
            _ = std.posix.read(std.posix.STDIN_FILENO, discard_buffer[0..]) catch 0;
            screensaver_exit_requested.store(true, .seq_cst);
            return true;
        }

        if (screensaver_exit_requested.load(.seq_cst)) return true;
        remaining_ns -= slice_ns;
    }

    return screensaver_exit_requested.load(.seq_cst);
}

fn stdinReady(timeout_ms: i32) !bool {
    if (!std.posix.isatty(std.posix.STDIN_FILENO)) {
        if (timeout_ms > 0) {
            std.Thread.sleep(@as(u64, @intCast(timeout_ms)) * std.time.ns_per_ms);
        }
        return false;
    }

    var fds = [_]std.posix.pollfd{.{
        .fd = std.posix.STDIN_FILENO,
        .events = std.posix.POLL.IN,
        .revents = 0,
    }};

    return (try std.posix.poll(fds[0..], timeout_ms)) > 0;
}

fn selectLocalArtwork(
    allocator: Allocator,
    random_dir: []const u8,
    local_dir: []const u8,
) !?[]const u8 {
    var candidates = std.ArrayList([]const u8).init(allocator);
    defer {
        for (candidates.items) |candidate| {
            allocator.free(candidate);
        }
        candidates.deinit();
    }

    try appendPlayableFilesFromDir(allocator, &candidates, random_dir);
    try appendPlayableFilesFromDir(allocator, &candidates, local_dir);

    if (candidates.items.len == 0) {
        return null;
    }

    if (candidates.items.len == 1) {
        return allocator.dupe(u8, candidates.items[0]);
    }

    var prng = std.Random.DefaultPrng.init(@as(u64, @intCast(std.time.nanoTimestamp())));
    const selected_index = prng.random().uintLessThan(usize, candidates.items.len);
    return allocator.dupe(u8, candidates.items[selected_index]);
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
