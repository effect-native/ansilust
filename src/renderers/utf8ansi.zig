const std = @import("std");
const ir = @import("../ir.zig");

// Terminal control escape sequences
const ESC_DECAWM_DISABLE = "\x1b[?7l"; // Disable auto-wrap mode
const ESC_DECAWM_ENABLE = "\x1b[?7h"; // Enable auto-wrap mode
const ESC_CURSOR_HIDE = "\x1b[?25l"; // Hide cursor (DECTCEM)
const ESC_CURSOR_SHOW = "\x1b[?25h"; // Show cursor (DECTCEM)
const ESC_CLEAR_SCREEN = "\x1b[2J"; // Clear entire screen (ED)

/// Render options for UTF8ANSI output.
pub const RenderOptions = struct {
    /// Is output going to a TTY (vs file)?
    is_tty: bool = true,
};

/// TerminalGuard manages terminal state setup and cleanup for rendering.
///
/// This guard establishes a safe rendering environment by:
/// 1. Disabling auto-wrap (DECAWM) to prevent terminal-induced line breaks
/// 2. Optionally hiding cursor and clearing screen in TTY mode
///
/// On deinit, it restores the terminal to its original state.
///
/// ## TTY vs File Mode
///
/// - **TTY mode** (is_tty=true): Emits cursor hide/clear for interactive display.
///   Used when rendering directly to a terminal for viewing.
///
/// - **File mode** (is_tty=false): Omits cursor/clear sequences for replayable output.
///   Used when piping output to a file (e.g., `ansilust art.ans > art.utf8ansi`).
///
/// Both modes emit DECAWM control to ensure layout preservation.
pub const TerminalGuard = struct {
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    is_tty: bool,

    /// Initialize the terminal guard and emit prologue sequences.
    ///
    /// Prologue sequences:
    /// - DECAWM disable: Prevents terminal from wrapping lines automatically
    /// - Cursor hide (TTY only): Cleaner visual during rendering
    /// - Clear screen (TTY only): Remove previous output
    pub fn init(allocator: std.mem.Allocator, writer: std.io.AnyWriter, is_tty: bool) !TerminalGuard {
        const guard = TerminalGuard{
            .allocator = allocator,
            .writer = writer,
            .is_tty = is_tty,
        };

        // DECAWM disable - critical for layout preservation in both modes
        try writer.writeAll(ESC_DECAWM_DISABLE);

        // TTY-only sequences for interactive display
        if (is_tty) {
            try writer.writeAll(ESC_CURSOR_HIDE);
            try writer.writeAll(ESC_CLEAR_SCREEN);
        }

        return guard;
    }

    /// Restore terminal state and emit epilogue sequences.
    ///
    /// Epilogue sequences:
    /// - Cursor show (TTY only): Make cursor visible again
    /// - DECAWM enable: Restore normal wrap behavior
    ///
    /// Errors are ignored during cleanup to ensure deinit always succeeds.
    pub fn deinit(self: *TerminalGuard) void {
        // TTY-only sequences
        if (self.is_tty) {
            self.writer.writeAll(ESC_CURSOR_SHOW) catch {};
        }

        // DECAWM restore - return terminal to normal wrap behavior
        self.writer.writeAll(ESC_DECAWM_ENABLE) catch {};
    }
};

/// Render IR document to UTF8ANSI terminal output.
///
/// Converts an ansilust IR document to modern terminal-compatible ANSI sequences.
/// Output is suitable for direct terminal display or saving to .utf8ansi files.
pub fn render(
    allocator: std.mem.Allocator,
    doc: *const ir.Document,
    writer: std.io.AnyWriter,
    options: RenderOptions,
) !void {
    var guard = try TerminalGuard.init(allocator, writer, options.is_tty);
    defer guard.deinit();

    const dims = doc.getDimensions();

    var y: u32 = 0;
    while (y < dims.height) : (y += 1) {
        try renderRow(doc, writer, y, dims.width);
    }
}

/// Render a single row at the given y coordinate.
fn renderRow(doc: *const ir.Document, writer: std.io.AnyWriter, y: u32, width: u32) !void {
    try writer.print("\x1b[{d};1H", .{y + 1});

    var x: u32 = 0;
    while (x < width) : (x += 1) {
        const cell = try doc.getCell(x, y);
        const scalar = cell.contents.scalar;

        if (scalar < 128) {
            try writer.writeByte(@intCast(scalar));
        } else {
            try writer.writeByte('?');
        }
    }
}
