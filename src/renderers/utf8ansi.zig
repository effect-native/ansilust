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

        // Emit prologue sequences
        // DECAWM disable (wrap control) - always emit in both modes
        try writer.writeAll("\x1b[?7l");

        // TTY-only sequences
        if (is_tty) {
            // Hide cursor
            try writer.writeAll("\x1b[?25l");
            // Clear screen
            try writer.writeAll("\x1b[2J");
        }

        return guard;
    }

    pub fn deinit(self: *TerminalGuard) void {
        // Emit epilogue sequences (ignoring errors since we're in cleanup)

        // TTY-only sequences
        if (self.is_tty) {
            // Show cursor
            self.writer.writeAll("\x1b[?25h") catch {};
        }

        // DECAWM restore (wrap control) - always emit in both modes
        self.writer.writeAll("\x1b[?7h") catch {};
    }
};
