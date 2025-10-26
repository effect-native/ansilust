//! Ansilust IR - Serialization Module
//!
//! Binary serialization/deserialization for IR documents.
//! Format: "ANSILUSTIR\0" header + versioned sections.
//!
//! STUB: To be implemented in Phase 5.

const std = @import("std");
const errors = @import("errors.zig");
const document = @import("document.zig");

/// Magic header for serialized IR files
pub const MAGIC_HEADER = "ANSILUSTIR\x00";

/// Current format version
pub const FORMAT_VERSION: u16 = 1;

/// Serialize document to writer.
pub fn serialize(doc: *const document.Document, writer: anytype) errors.Error!void {
    _ = doc;
    _ = writer;
    return error.SerializationFailed; // STUB
}

/// Deserialize document from reader.
pub fn deserialize(allocator: std.mem.Allocator, reader: anytype) errors.Error!document.Document {
    _ = allocator;
    _ = reader;
    return error.SerializationFailed; // STUB
}
