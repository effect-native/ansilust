//! Ansilust IR - Shared Error Set
//!
//! Defines all error types used throughout the IR module.
//! Consolidates error handling for memory allocation, validation,
//! serialization, and resource management.

const std = @import("std");

/// Core error set used across all IR modules.
///
/// Parsers, renderers, and IR manipulation functions return error unions
/// with this error set. All errors are documented with their typical causes
/// and recovery strategies.
pub const Error = error{
    /// Memory allocation failed. Typically unrecoverable; caller should
    /// propagate to top-level handler and abort gracefully.
    OutOfMemory,

    /// Cell coordinate out of bounds. Indicates invalid x/y access beyond
    /// grid dimensions. Callers should validate coordinates before access.
    InvalidCoordinate,

    /// Encoding identifier invalid or unsupported. May occur when:
    /// - Unknown IANA MIBenum encountered
    /// - Vendor range value not recognized
    /// - Encoding conversion fails
    InvalidEncoding,

    /// Animation frame data malformed or unsupported. Causes include:
    /// - Delta references non-existent frame
    /// - Timing values invalid (e.g., duration overflow)
    /// - Frame dimensions mismatch base grid
    UnsupportedAnimation,

    /// Serialization or deserialization failed. Typical causes:
    /// - Magic header mismatch
    /// - Version incompatibility
    /// - Corrupted section data
    /// - Checksum validation failure
    SerializationFailed,

    /// Attempted to register hyperlink with duplicate ID.
    /// Hyperlink IDs must be unique within a document.
    DuplicateHyperlinkId,

    /// Attempted to register palette with duplicate ID.
    /// Palette IDs must be unique within a document.
    DuplicatePaletteId,

    /// Attempted to add animation frame with duplicate ID.
    /// Frame IDs must be unique within an animation sequence.
    DuplicateFrameId,

    /// Invalid grapheme cluster data. Occurs when:
    /// - Grapheme ID references non-existent pool entry
    /// - UTF-8 sequence invalid
    /// - Grapheme exceeds maximum supported length
    InvalidGrapheme,

    /// SAUCE record parsing or validation failed. Causes include:
    /// - Missing required fields
    /// - Invalid field format
    /// - Checksum mismatch
    InvalidSauce,

    /// Attempted resize would overflow maximum supported dimensions.
    /// Current limits: u32::MAX for width/height (implementation may impose
    /// practical limits based on available memory).
    DimensionOverflow,

    /// Resource ID not found in lookup table. Generic error for missing
    /// references (fonts, palettes, styles, etc.).
    ResourceNotFound,

    /// Operation invalid in current state. For example:
    /// - Finalize called on already-finalized builder
    /// - Mutation attempted on immutable document
    InvalidState,
};

/// Helper to check if an error is recoverable through user action.
///
/// Returns true for validation errors (caller can retry with corrected input),
/// false for systemic errors (OutOfMemory, corrupted data).
pub fn isRecoverable(err: Error) bool {
    return switch (err) {
        error.OutOfMemory,
        error.SerializationFailed,
        error.InvalidGrapheme,
        error.InvalidSauce,
        => false,

        error.InvalidCoordinate,
        error.InvalidEncoding,
        error.UnsupportedAnimation,
        error.DuplicateHyperlinkId,
        error.DuplicatePaletteId,
        error.DuplicateFrameId,
        error.DimensionOverflow,
        error.ResourceNotFound,
        error.InvalidState,
        => true,
    };
}

/// Common result type aliases for IR operations.
pub fn Result(comptime T: type) type {
    return Error!T;
}

test "error recoverability classification" {
    try std.testing.expect(!isRecoverable(error.OutOfMemory));
    try std.testing.expect(isRecoverable(error.InvalidCoordinate));
    try std.testing.expect(isRecoverable(error.DuplicatePaletteId));
    try std.testing.expect(!isRecoverable(error.SerializationFailed));
}
