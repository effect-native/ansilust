//! Ansilust - Text art IR library
//! Root module exposing the public API

const std = @import("std");

pub const ir = @import("ir.zig");

// Re-export commonly used types
pub const AnsilustIR = ir.AnsilustIR;
pub const Cell = ir.Cell;
pub const Style = ir.Style;
pub const Color = ir.Color;
pub const Attributes = ir.Attributes;
pub const SauceRecord = ir.SauceRecord;

test {
    // Run all tests from imported modules
    std.testing.refAllDecls(@This());
}
