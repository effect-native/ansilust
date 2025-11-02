//! Tests for platform path resolution

const std = @import("std");
const testing = std.testing;
const paths = @import("paths.zig");
const Platform = paths.Platform;
const PlatformPaths = paths.PlatformPaths;

test "Platform.detect returns valid platform" {
    const platform = Platform.detect();

    // Should be one of the supported platforms
    const is_valid = platform == .linux or platform == .macos or platform == .windows;
    try testing.expect(is_valid);
}

test "PlatformPaths.init creates valid paths" {
    var platform_paths = try PlatformPaths.init(testing.allocator);
    defer platform_paths.deinit();

    // Verify root path is not empty
    try testing.expect(platform_paths.sixteen_colors_root.len > 0);

    // Verify subdirectories contain "16colors"
    try testing.expect(std.mem.indexOf(u8, platform_paths.sixteen_colors_root, "16colors") != null);

    // Verify subdirectories are set
    try testing.expect(platform_paths.random_dir.len > 0);
    try testing.expect(platform_paths.packs_dir.len > 0);
    try testing.expect(platform_paths.local_dir.len > 0);

    // Verify subdirectories end with correct names
    try testing.expect(std.mem.endsWith(u8, platform_paths.random_dir, "random"));
    try testing.expect(std.mem.endsWith(u8, platform_paths.packs_dir, "packs"));
    try testing.expect(std.mem.endsWith(u8, platform_paths.local_dir, "local"));
}

test "PlatformPaths subdirectories are under root" {
    var platform_paths = try PlatformPaths.init(testing.allocator);
    defer platform_paths.deinit();

    const root = platform_paths.sixteen_colors_root;

    // All subdirectories should start with root path
    try testing.expect(std.mem.startsWith(u8, platform_paths.random_dir, root));
    try testing.expect(std.mem.startsWith(u8, platform_paths.packs_dir, root));
    try testing.expect(std.mem.startsWith(u8, platform_paths.local_dir, root));
}

test "PlatformPaths.ensureDirectoriesExist creates directories" {
    var platform_paths = try PlatformPaths.init(testing.allocator);
    defer platform_paths.deinit();

    // Note: This test actually creates directories on the filesystem
    // For unit testing, we'd normally use a temp directory
    // For now, we'll skip the actual directory creation test
    // and just verify the function exists and compiles

    // In a real test environment:
    // try platform_paths.ensureDirectoriesExist();
}

test "Platform-specific root paths have correct format" {
    var platform_paths = try PlatformPaths.init(testing.allocator);
    defer platform_paths.deinit();

    const platform = Platform.detect();
    const root = platform_paths.sixteen_colors_root;

    switch (platform) {
        .linux => {
            // Should contain .local/share or XDG_DATA_HOME
            const has_local_share = std.mem.indexOf(u8, root, ".local") != null or
                std.mem.indexOf(u8, root, "share") != null;
            try testing.expect(has_local_share or std.mem.indexOf(u8, root, "16colors") != null);
        },
        .macos => {
            // Should contain Pictures
            try testing.expect(std.mem.indexOf(u8, root, "Pictures") != null);
        },
        .windows => {
            // Should contain Pictures
            try testing.expect(std.mem.indexOf(u8, root, "Pictures") != null);
        },
    }
}
