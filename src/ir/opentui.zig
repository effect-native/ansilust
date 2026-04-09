//! Ansilust IR - OpenTUI Integration Module
//!
//! Conversion bridge to OpenTUI's OptimizedBuffer format.
//! Enables direct integration with OpenTUI framework.
//!
//! STUB: To be implemented in Phase 5.

const std = @import("std");
const errors = @import("errors.zig");
const document = @import("document.zig");

pub const OptimizedBuffer = struct {
    width: u32,
    height: u32,
    cell_count: usize,
};

/// Convert document to OpenTUI OptimizedBuffer.
///
/// Maps IR cell grid to OpenTUI's structure-of-arrays format.
/// Colors converted to RGBA floats, attributes to u8 bitflags.
pub fn toOptimizedBuffer(doc: *const document.Document, allocator: std.mem.Allocator) errors.Error!OptimizedBuffer {
    _ = allocator;

    const dimensions = doc.getDimensions();
    return .{
        .width = dimensions.width,
        .height = dimensions.height,
        .cell_count = @as(usize, dimensions.width) * @as(usize, dimensions.height),
    };
}

test "OpenTUI bridge exports a concrete buffer surface" {
    try std.testing.expect(@hasDecl(@This(), "OptimizedBuffer"));
}

test "toOptimizedBuffer returns a buffer payload instead of void" {
    const fn_info = @typeInfo(@TypeOf(toOptimizedBuffer)).@"fn";
    const return_type = fn_info.return_type orelse unreachable;
    const error_union = @typeInfo(return_type).error_union;

    try std.testing.expect(error_union.payload != void);
}
