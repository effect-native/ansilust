//! Platform-specific path resolution for 16colors directory structure
//!
//! This module handles cross-platform detection and path resolution for the
//! community-standard 16colors directory layout. Paths follow OS conventions:
//!
//! - Linux: ~/.local/share/16colors/ (or $XDG_DATA_HOME/16colors/)
//! - macOS: ~/Pictures/16colors/
//! - Windows: %USERPROFILE%\Pictures\16colors\
//!
//! The directory structure is designed to be shared across multiple tools
//! (ansilust, screensavers, viewers, editors) following a community standard.

const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const fs = std.fs;

/// Supported platforms
pub const Platform = enum {
    linux,
    macos,
    windows,

    /// Detect the current platform
    pub fn detect() Platform {
        return switch (builtin.os.tag) {
            .linux => .linux,
            .macos => .macos,
            .windows => .windows,
            else => .linux, // Default to Linux conventions for unknown platforms
        };
    }
};

/// Platform-specific directory paths
pub const PlatformPaths = struct {
    /// Root 16colors directory (e.g., ~/Pictures/16colors/)
    sixteen_colors_root: []const u8,

    /// Random artwork cache directory
    random_dir: []const u8,

    /// Packs directory (official 16colo.rs archive)
    packs_dir: []const u8,

    /// Local directory (user's own artwork)
    local_dir: []const u8,

    allocator: Allocator,

    /// Get platform-specific paths
    ///
    /// Resolves home directory and constructs full paths based on OS conventions.
    /// Caller must call deinit() to free allocated memory.
    ///
    /// # Arguments
    /// - `allocator`: Memory allocator for path strings
    ///
    /// # Returns
    /// PlatformPaths with all directory paths resolved
    ///
    /// # Errors
    /// - `OutOfMemory`: Allocation failed
    /// - `FileNotFound`: Home directory not found
    pub fn init(allocator: Allocator) !PlatformPaths {
        const platform = Platform.detect();

        // Get home directory
        const home_dir = try getHomeDirectory(allocator);
        defer allocator.free(home_dir);

        // Construct 16colors root based on platform
        const root = try switch (platform) {
            .linux => getLinuxRoot(allocator, home_dir),
            .macos => getMacOSRoot(allocator, home_dir),
            .windows => getWindowsRoot(allocator, home_dir),
        };
        errdefer allocator.free(root);

        // Construct subdirectories
        const random_dir = try fs.path.join(allocator, &[_][]const u8{ root, "random" });
        errdefer allocator.free(random_dir);

        const packs_dir = try fs.path.join(allocator, &[_][]const u8{ root, "packs" });
        errdefer allocator.free(packs_dir);

        const local_dir = try fs.path.join(allocator, &[_][]const u8{ root, "local" });
        errdefer allocator.free(local_dir);

        return PlatformPaths{
            .sixteen_colors_root = root,
            .random_dir = random_dir,
            .packs_dir = packs_dir,
            .local_dir = local_dir,
            .allocator = allocator,
        };
    }

    /// Create all directories if they don't exist
    ///
    /// # Errors
    /// - `PermissionDenied`: Cannot create directories
    /// - `DiskFull`: No space available
    pub fn ensureDirectoriesExist(self: *const PlatformPaths) !void {
        // Create root directory
        try fs.cwd().makePath(self.sixteen_colors_root);

        // Create subdirectories
        try fs.cwd().makePath(self.random_dir);
        try fs.cwd().makePath(self.packs_dir);
        try fs.cwd().makePath(self.local_dir);
    }

    /// Free allocated memory
    pub fn deinit(self: *PlatformPaths) void {
        self.allocator.free(self.sixteen_colors_root);
        self.allocator.free(self.random_dir);
        self.allocator.free(self.packs_dir);
        self.allocator.free(self.local_dir);
    }
};

/// Get home directory path
fn getHomeDirectory(allocator: Allocator) ![]const u8 {
    const home = std.posix.getenv("HOME") orelse
        std.posix.getenv("USERPROFILE") orelse
        return error.HomeDirectoryNotFound;

    return try allocator.dupe(u8, home);
}

/// Get Linux 16colors root directory
fn getLinuxRoot(allocator: Allocator, home: []const u8) ![]const u8 {
    // Check for XDG_DATA_HOME environment variable
    if (std.posix.getenv("XDG_DATA_HOME")) |xdg_data| {
        return try fs.path.join(allocator, &[_][]const u8{ xdg_data, "16colors" });
    }

    // Default: ~/.local/share/16colors
    return try fs.path.join(allocator, &[_][]const u8{ home, ".local", "share", "16colors" });
}

/// Get macOS 16colors root directory
fn getMacOSRoot(allocator: Allocator, home: []const u8) ![]const u8 {
    // macOS: ~/Pictures/16colors
    return try fs.path.join(allocator, &[_][]const u8{ home, "Pictures", "16colors" });
}

/// Get Windows 16colors root directory
fn getWindowsRoot(allocator: Allocator, home: []const u8) ![]const u8 {
    // Windows: %USERPROFILE%\Pictures\16colors
    return try fs.path.join(allocator, &[_][]const u8{ home, "Pictures", "16colors" });
}
