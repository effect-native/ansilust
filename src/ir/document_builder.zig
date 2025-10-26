//! Ansilust IR - Document Builder Module
//!
//! Safe construction facade for parsers with arena/slab migration.
//! Provides builder pattern for incremental document construction.
//!
//! STUB: To be implemented in Phase 4.

const std = @import("std");
const errors = @import("errors.zig");
const document = @import("document.zig");

/// Document builder for safe incremental construction.
///
/// Manages arena allocators during construction, then migrates
/// to slab allocators on finalization for optimal runtime performance.
pub const DocumentBuilder = struct {
    allocator: std.mem.Allocator,
    doc: ?document.Document,

    pub fn init(allocator: std.mem.Allocator) DocumentBuilder {
        return DocumentBuilder{
            .allocator = allocator,
            .doc = null,
        };
    }

    pub fn deinit(self: *DocumentBuilder) void {
        if (self.doc) |*d| {
            d.deinit(self.allocator);
        }
    }

    /// Finalize construction and return document.
    pub fn finalize(self: *DocumentBuilder) errors.Error!document.Document {
        _ = self; // STUB
        return error.InvalidState; // STUB
    }
};
