//! Archive database abstraction layer
//!
//! This module provides an abstract interface for querying the 16colors archive.
//! The implementation can be either hardcoded data (Phase 5.1) or SQLite (Phase 5.4+).
//!
//! This abstraction allows the codebase to be built against a stable interface
//! while the underlying implementation evolves over time.

const std = @import("std");
const Allocator = std.mem.Allocator;

/// File entry from the archive database
pub const FileEntry = struct {
    /// Pack name (e.g., "mist1025")
    pack_name: []const u8,

    /// Filename (e.g., "CXC-STICK.ASC")
    filename: []const u8,

    /// Full source URL for downloading
    source_url: []const u8,

    /// Year the pack was released
    year: u16,

    /// Artist name (optional)
    artist: ?[]const u8,

    /// File extension (e.g., "ans", "asc")
    extension: []const u8,
};

/// Pack metadata from the archive database
pub const Pack = struct {
    /// Pack name (e.g., "mist1025")
    name: []const u8,

    /// Year the pack was released
    year: u16,

    /// Group name (optional, e.g., "mistigris")
    group_name: ?[]const u8,

    /// URL to download the pack ZIP file
    zip_url: []const u8,
};

/// Database implementation types
pub const Implementation = union(enum) {
    /// Hardcoded implementation (Phase 5.1)
    hardcoded: HardcodedImpl,

    /// SQLite implementation (Phase 5.4+, future)
    sqlite: SqliteImpl,
};

/// Hardcoded database implementation (forward declaration)
pub const HardcodedImpl = @import("hardcoded.zig").HardcodedImpl;

/// SQLite database implementation (forward declaration, future)
pub const SqliteImpl = struct {
    // Placeholder for future SQLite implementation
    allocator: Allocator,

    pub fn getRandomFile(self: *SqliteImpl) !FileEntry {
        _ = self;
        return error.NotImplemented;
    }

    pub fn searchFiles(self: *SqliteImpl, query: []const u8) ![]FileEntry {
        _ = self;
        _ = query;
        return error.NotImplemented;
    }

    pub fn getPack(self: *SqliteImpl, name: []const u8) !Pack {
        _ = self;
        _ = name;
        return error.NotImplemented;
    }

    pub fn listPacksByYear(self: *SqliteImpl, year: u16) ![]Pack {
        _ = self;
        _ = year;
        return error.NotImplemented;
    }

    pub fn deinit(self: *SqliteImpl) void {
        _ = self;
    }
};

/// Archive database abstraction
pub const ArchiveDatabase = struct {
    impl: Implementation,
    allocator: Allocator,

    /// Initialize the archive database
    ///
    /// Currently creates a hardcoded implementation.
    /// Future versions will support SQLite.
    ///
    /// # Arguments
    /// - `allocator`: Memory allocator for database operations
    ///
    /// # Returns
    /// Initialized ArchiveDatabase instance
    pub fn init(allocator: Allocator) !ArchiveDatabase {
        const hardcoded = HardcodedImpl.init(allocator);
        return ArchiveDatabase{
            .impl = .{ .hardcoded = hardcoded },
            .allocator = allocator,
        };
    }

    /// Get a random file from the archive
    ///
    /// Selects a random ANSI/ASCII file from the available entries.
    ///
    /// # Returns
    /// A FileEntry with metadata and download URL
    ///
    /// # Errors
    /// - `OutOfMemory`: Allocation failed
    pub fn getRandomFile(self: *ArchiveDatabase) !FileEntry {
        return switch (self.impl) {
            .hardcoded => |*h| h.getRandomFile(),
            .sqlite => |*s| s.getRandomFile(),
        };
    }

    /// Search for files by name or content
    ///
    /// **Currently stubbed** - returns empty array.
    /// Future implementations will use FTS5 for full-text search.
    ///
    /// # Arguments
    /// - `query`: Search query string
    ///
    /// # Returns
    /// Array of matching FileEntry results (caller owns memory)
    ///
    /// # Errors
    /// - `OutOfMemory`: Allocation failed
    pub fn searchFiles(self: *ArchiveDatabase, query: []const u8) ![]FileEntry {
        return switch (self.impl) {
            .hardcoded => |*h| h.searchFiles(query),
            .sqlite => |*s| s.searchFiles(query),
        };
    }

    /// Get pack metadata by name
    ///
    /// **Currently stubbed** - returns error.NotImplemented.
    /// Future implementations will query database for pack info.
    ///
    /// # Arguments
    /// - `name`: Pack name (e.g., "mist1025")
    ///
    /// # Returns
    /// Pack metadata including download URL
    ///
    /// # Errors
    /// - `NotImplemented`: Feature not yet implemented
    /// - `PackNotFound`: Pack does not exist in database
    pub fn getPack(self: *ArchiveDatabase, name: []const u8) !Pack {
        return switch (self.impl) {
            .hardcoded => |*h| h.getPack(name),
            .sqlite => |*s| s.getPack(name),
        };
    }

    /// List all packs from a specific year
    ///
    /// **Currently stubbed** - returns empty array.
    /// Future implementations will query database for packs.
    ///
    /// # Arguments
    /// - `year`: Year to query (e.g., 2025)
    ///
    /// # Returns
    /// Array of Pack entries for that year (caller owns memory)
    ///
    /// # Errors
    /// - `OutOfMemory`: Allocation failed
    pub fn listPacksByYear(self: *ArchiveDatabase, year: u16) ![]Pack {
        return switch (self.impl) {
            .hardcoded => |*h| h.listPacksByYear(year),
            .sqlite => |*s| s.listPacksByYear(year),
        };
    }

    /// Clean up database resources
    pub fn deinit(self: *ArchiveDatabase) void {
        switch (self.impl) {
            .hardcoded => |*h| h.deinit(),
            .sqlite => |*s| s.deinit(),
        }
    }
};
