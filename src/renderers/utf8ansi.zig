const std = @import("std");

/// TerminalGuard manages terminal state setup and cleanup.
/// Emits DECAWM wrap control in both TTY and file modes.
/// Emits cursor hide/clear only in TTY mode.
pub const TerminalGuard = struct {
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    is_tty: bool,

    pub fn init(allocator: std.mem.Allocator, writer: std.io.AnyWriter, is_tty: bool) !TerminalGuard {
        const guard = TerminalGuard{
            .allocator = allocator,
            .writer = writer,
            .is_tty = is_tty,
        };

        // TODO: Emit prologue sequences
        return guard;
    }

    pub fn deinit(self: *TerminalGuard) void {
        // TODO: Emit epilogue sequences
        _ = self;
    }
};
