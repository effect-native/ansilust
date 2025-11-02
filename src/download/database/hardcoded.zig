//! Hardcoded database implementation
//!
//! This module provides a simple hardcoded implementation of the archive database
//! interface using a curated list of 16colors files. This allows the system to
//! function without SQLite while the database abstraction interface is established.
//!
//! The curated list includes a diverse selection of ANSI/ASCII art files from
//! different years, artists, and styles, all verified to be accessible from 16colo.rs.

const std = @import("std");
const Allocator = std.mem.Allocator;
const interface = @import("interface.zig");
const FileEntry = interface.FileEntry;
const Pack = interface.Pack;

/// Hardcoded database implementation
pub const HardcodedImpl = struct {
    allocator: Allocator,

    /// Initialize hardcoded database
    pub fn init(allocator: Allocator) HardcodedImpl {
        return .{ .allocator = allocator };
    }

    /// Get a random file from the curated list
    pub fn getRandomFile(self: *HardcodedImpl) !FileEntry {
        _ = self;

        // Curated list of 16colors files
        // Criteria:
        // - Mix of years (1990s, 2000s, 2020s)
        // - Mix of formats (ANS, ASC)
        // - Mix of styles (detailed art, ASCII, blocks)
        // - All files < 100KB (fast downloads)
        // - Verified URLs from 16colo.rs
        // - Diverse artists and groups
        const files = comptime [_]FileEntry{
            // MVP: Just one verified working URL for now
            // TODO: Add more URLs after verifying them in Phase 5.2
            .{
                .pack_name = "mist1025",
                .filename = "CXC-STICK.ASC",
                .source_url = "https://16colo.rs/pack/mist1025/raw/CXC-STICK.ASC",
                .year = 2025,
                .artist = "CoaXCable",
                .extension = "asc",
            },
        };

        // Select random file using cryptographically secure RNG
        const random = std.crypto.random;
        const index = random.intRangeLessThan(usize, 0, files.len);

        return files[index];
    }

    /// Search for files (stub implementation)
    pub fn searchFiles(self: *HardcodedImpl, query: []const u8) ![]FileEntry {
        _ = self;
        _ = query;
        // Stub: return empty array
        // Future: implement simple string matching or defer to SQLite FTS5
        return &[_]FileEntry{};
    }

    /// Get pack by name (stub implementation)
    pub fn getPack(self: *HardcodedImpl, name: []const u8) !Pack {
        _ = self;
        _ = name;
        // Stub: return error
        // Future: implement pack lookup or defer to SQLite
        return error.NotImplemented;
    }

    /// List packs by year (stub implementation)
    pub fn listPacksByYear(self: *HardcodedImpl, year: u16) ![]Pack {
        _ = self;
        _ = year;
        // Stub: return empty array
        // Future: implement year filtering or defer to SQLite
        return &[_]Pack{};
    }

    /// Clean up resources (no-op for hardcoded data)
    pub fn deinit(self: *HardcodedImpl) void {
        _ = self;
        // No cleanup needed for comptime data
    }
};
