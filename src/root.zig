//! Ansilust - Next-generation text art processing system
//!
//! Unified intermediate representation for classic BBS art (ANSI, Binary, PCBoard, XBin)
//! and modern terminal capabilities (UTF-8, true color, Unicode).
//!
//! ## Usage
//!
//! ```zig
//! const ansilust = @import("ansilust");
//! const allocator = std.heap.page_allocator;
//!
//! // Create a document
//! var doc = try ansilust.ir.Document.init(allocator, 80, 25);
//! defer doc.deinit();
//!
//! // Set a cell
//! try doc.setCell(0, 0, .{
//!     .contents = .{ .scalar = 'A' },
//!     .fg_color = .{ .palette = 7 },
//! });
//!
//! // Get a cell
//! const cell = try doc.getCell(0, 0);
//! ```

const std = @import("std");

// === Core IR Module ===

/// Intermediate representation module
pub const ir = @import("ir/lib.zig");

// === Convenience Re-exports ===

/// Main document type
pub const Document = ir.Document;

/// Cell grid type
pub const CellGrid = ir.CellGrid;

/// Cell contents (scalar or grapheme)
pub const CellContents = ir.CellContents;

/// Cell input for setCell operations
pub const CellInput = ir.CellInput;

/// Color representation
pub const Color = ir.Color;

/// RGB color
pub const RGB = ir.RGB;

/// Attribute flags
pub const AttributeFlags = ir.AttributeFlags;

/// SAUCE metadata record
pub const SauceRecord = ir.SauceRecord;

/// Source encoding
pub const SourceEncoding = ir.SourceEncoding;

/// Error type
pub const Error = ir.Error;

// === Tests ===

test {
    // Run all tests from IR module
    std.testing.refAllDecls(@This());
}
