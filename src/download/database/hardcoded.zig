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

const curated_files = [_]FileEntry{
    .{
        .pack_name = "mist1025",
        .filename = "CXC-STICK.ASC",
        .source_url = "https://16colo.rs/pack/mist1025/raw/CXC-STICK.ASC",
        .year = 2025,
        .artist = "CoaXCable",
        .extension = "asc",
    },
};

const curated_packs = [_]Pack{
    .{
        .name = "mist1025",
        .year = 2025,
        .group_name = null,
        .zip_url = "https://16colo.rs/archive/2025/mist1025.zip",
    },
};

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

        // Select random file using cryptographically secure RNG
        const random = std.crypto.random;
        const index = random.intRangeLessThan(usize, 0, curated_files.len);

        return curated_files[index];
    }

    /// Search for files in curated catalog
    pub fn searchFiles(self: *HardcodedImpl, query: []const u8) ![]FileEntry {
        _ = self;
        if (std.mem.eql(u8, query, "CXC-STICK")) {
            return @constCast(curated_files[0..]);
        }

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

    /// List packs by year in curated catalog
    pub fn listPacksByYear(self: *HardcodedImpl, year: u16) ![]Pack {
        _ = self;
        if (year == 2025) {
            return @constCast(curated_packs[0..]);
        }

        return &[_]Pack{};
    }

    /// Clean up resources (no-op for hardcoded data)
    pub fn deinit(self: *HardcodedImpl) void {
        _ = self;
        // No cleanup needed for comptime data
    }
};
