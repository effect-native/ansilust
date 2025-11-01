const std = @import("std");
const ir = @import("../ir/lib.zig");

// Terminal control escape sequences
const ESC_DECAWM_DISABLE = "\x1b[?7l"; // Disable auto-wrap mode
const ESC_DECAWM_ENABLE = "\x1b[?7h"; // Enable auto-wrap mode
const ESC_CURSOR_HIDE = "\x1b[?25l"; // Hide cursor (DECTCEM)
const ESC_CURSOR_SHOW = "\x1b[?25h"; // Show cursor (DECTCEM)

/// Render options for UTF8ANSI output.
pub const RenderOptions = struct {
    /// Is output going to a TTY (vs file)?
    is_tty: bool = true,
};

/// DOS/VGA palette RGB values (CGA/EGA standard, 16 colors).
///
/// These are the canonical RGB values for the classic DOS/VGA palette used in
/// BBS-era ANSI art. By emitting explicit RGB values as 24-bit truecolor
/// (SGR 38;2;R;G;B), we ensure consistent color rendering across all terminal
/// emulators, regardless of their 256-color palette configuration.
///
/// **Why 24-bit instead of 256-color?**
/// The ANSI 256-color palette indices (0-255) are not standardized - different
/// terminals map the same index to different RGB values. This causes color
/// inconsistencies when viewing artwork. By emitting explicit RGB values, we
/// guarantee the artist's intended colors are displayed correctly.
///
/// Reference: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
/// Spec: .specs/render-utf8ansi/requirements.md FR1.2.2
const DOS_PALETTE_RGB: [16]struct { r: u8, g: u8, b: u8 } = .{
    .{ .r = 0x00, .g = 0x00, .b = 0x00 }, // 0: Black
    .{ .r = 0x00, .g = 0x00, .b = 0xAA }, // 1: Blue
    .{ .r = 0x00, .g = 0xAA, .b = 0x00 }, // 2: Green
    .{ .r = 0x00, .g = 0xAA, .b = 0xAA }, // 3: Cyan
    .{ .r = 0xAA, .g = 0x00, .b = 0x00 }, // 4: Red
    .{ .r = 0xAA, .g = 0x00, .b = 0xAA }, // 5: Magenta
    .{ .r = 0xAA, .g = 0x55, .b = 0x00 }, // 6: Brown
    .{ .r = 0xAA, .g = 0xAA, .b = 0xAA }, // 7: Light Gray
    .{ .r = 0x55, .g = 0x55, .b = 0x55 }, // 8: Dark Gray
    .{ .r = 0x55, .g = 0x55, .b = 0xFF }, // 9: Light Blue
    .{ .r = 0x55, .g = 0xFF, .b = 0x55 }, // 10: Light Green
    .{ .r = 0x55, .g = 0xFF, .b = 0xFF }, // 11: Light Cyan
    .{ .r = 0xFF, .g = 0x55, .b = 0x55 }, // 12: Light Red
    .{ .r = 0xFF, .g = 0x55, .b = 0xFF }, // 13: Light Magenta
    .{ .r = 0xFF, .g = 0xFF, .b = 0x55 }, // 14: Yellow
    .{ .r = 0xFF, .g = 0xFF, .b = 0xFF }, // 15: White
};

/// DOS/VGA palette (16 colors) to ANSI 256-color mapping.
///
/// **DEPRECATED**: This mapping is kept for optional `--256color` compatibility mode.
/// By default, the renderer uses 24-bit truecolor (DOS_PALETTE_RGB) for maximum
/// color fidelity across terminals.
///
/// The DOS palette uses indices 0-15, but these don't map directly to
/// ANSI 256-color indices 0-15. Instead, we map to the "xterm 256-color"
/// palette which provides better visual fidelity.
///
/// Reference: https://github.com/effect-native/libansilove/blob/utf8ansi-terminal/src/dos_colors.h
const DOS_TO_ANSI_256: [16]u8 = .{
    16, // 0: Black       #000000 → ANSI 16
    19, // 1: Blue        #0000AA → ANSI 19
    34, // 2: Green       #00AA00 → ANSI 34
    37, // 3: Cyan        #00AAAA → ANSI 37
    124, // 4: Red         #AA0000 → ANSI 124
    127, // 5: Magenta     #AA00AA → ANSI 127
    136, // 6: Brown       #AA5500 → ANSI 136
    248, // 7: Light Gray  #AAAAAA → ANSI 248
    240, // 8: Dark Gray   #555555 → ANSI 240
    105, // 9: Light Blue  #5555FF → ANSI 105
    120, // 10: Light Green #55FF55 → ANSI 120
    123, // 11: Light Cyan #55FFFF → ANSI 123
    210, // 12: Light Red  #FF5555 → ANSI 210
    213, // 13: Light Mag. #FF55FF → ANSI 213
    228, // 14: Yellow     #FFFF55 → ANSI 228
    231, // 15: White      #FFFFFF → ANSI 231
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
            // Note: We don't clear the screen automatically. Users can run 'clear' themselves.
            // Auto-clearing erases previous output (like separators in loops), which is unexpected.
        }

        return guard;
    }

    /// Restore terminal state and emit epilogue sequences.
    ///
    /// Epilogue sequences:
    /// - Cursor show (TTY only): Make cursor visible again
    /// - DECAWM enable: Restore normal wrap behavior
    /// - Newline (TTY only): Ensures scrollback captures output correctly
    ///
    /// Errors are ignored during cleanup to ensure deinit always succeeds.
    pub fn deinit(self: *TerminalGuard) void {
        // TTY-only sequences
        if (self.is_tty) {
            self.writer.writeAll(ESC_CURSOR_SHOW) catch {};
        }

        // DECAWM restore - return terminal to normal wrap behavior
        self.writer.writeAll(ESC_DECAWM_ENABLE) catch {};

        // TTY-only: emit newlines to "commit" output to scrollback buffer
        // This prevents Ghostty/Alacritty from truncating lines in scrollback
        // when wrap was disabled during rendering
        if (self.is_tty) {
            self.writer.writeAll("\n\n") catch {};
        }
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

    // Find the last row with actual content to avoid rendering trailing blank rows.
    // BBS art files often initialize documents with large heights (e.g., 25 rows),
    // but the actual art may only use the first 10-20 rows. Rendering all blank rows
    // creates large gaps in the output.
    //
    // Search backwards from the end for efficiency - stops at first non-blank row.
    var last_content_row: u32 = 0;
    if (dims.height > 0) {
        var search_y: u32 = dims.height - 1;
        while (true) {
            if (try rowHasContent(doc, search_y, dims.width)) {
                last_content_row = search_y;
                break;
            }
            if (search_y == 0) break;
            search_y -= 1;
        }
    }

    // Render rows up to the last row with content
    var y: u32 = 0;
    while (y <= last_content_row) : (y += 1) {
        try renderRow(doc, writer, y, dims.width);

        // Emit newline after each row
        if (y < last_content_row) {
            try writer.writeAll("\n");
        }
    }
}

/// Render IR document to an owned buffer.
///
/// This is a convenience wrapper around `render()` that allocates and returns
/// an owned byte slice. Caller must free the returned buffer.
///
/// Useful for CLI integration where you need to write to stdout after rendering.
pub fn renderToBuffer(
    allocator: std.mem.Allocator,
    doc: *const ir.Document,
    is_tty: bool,
) ![]u8 {
    var output = std.ArrayListUnmanaged(u8){};
    errdefer output.deinit(allocator);

    const options = RenderOptions{ .is_tty = is_tty };
    try render(allocator, doc, output.writer(allocator).any(), options);

    return output.toOwnedSlice(allocator);
}

/// Render state for tracking current style and optimizing SGR emissions.
const RenderState = struct {
    current_fg: ?ir.Color,
    current_bg: ?ir.Color,

    fn init() RenderState {
        return .{
            .current_fg = null,
            .current_bg = null,
        };
    }

    /// Apply style for a cell, emitting SGR codes only if style changed.
    fn applyStyle(self: *RenderState, writer: std.io.AnyWriter, fg: ir.Color, bg: ir.Color) !void {
        const fg_changed = if (self.current_fg) |current| !colorsEqual(current, fg) else true;
        const bg_changed = if (self.current_bg) |current| !colorsEqual(current, bg) else true;

        if (fg_changed or bg_changed) {
            // Style changed - emit reset first, then new colors
            try writer.writeAll("\x1b[0m");
            try emitColors(writer, fg, bg);
            self.current_fg = fg;
            self.current_bg = bg;
        }
        // else: style unchanged, no SGR emission needed
    }
};

/// Compare two colors for equality.
fn colorsEqual(a: ir.Color, b: ir.Color) bool {
    return switch (a) {
        .none => switch (b) {
            .none => true,
            else => false,
        },
        .palette => |a_idx| switch (b) {
            .palette => |b_idx| a_idx == b_idx,
            else => false,
        },
        .rgb => |a_rgb| switch (b) {
            .rgb => |b_rgb| a_rgb.r == b_rgb.r and a_rgb.g == b_rgb.g and a_rgb.b == b_rgb.b,
            else => false,
        },
    };
}

/// Check if a row has any content (non-space characters or non-default colors).
fn rowHasContent(doc: *const ir.Document, y: u32, width: u32) !bool {
    var x: u32 = 0;
    while (x < width) : (x += 1) {
        const cell = try doc.getCell(x, y);

        // Check if cell has visible content
        if (cell.contents.scalar != ' ') {
            return true;
        }

        // Check if cell has non-default colors (colored backgrounds count as content)
        const has_colored_fg = switch (cell.fg_color) {
            .none => false,
            .palette => |idx| idx != 7, // 7 is default light gray
            .rgb => true,
        };
        const has_colored_bg = switch (cell.bg_color) {
            .none => false,
            .palette => |idx| idx != 0, // 0 is default black
            .rgb => true,
        };

        if (has_colored_fg or has_colored_bg) {
            return true;
        }
    }

    return false; // Row is entirely blank
}

/// Render a single row at the given y coordinate.
fn renderRow(doc: *const ir.Document, writer: std.io.AnyWriter, y: u32, width: u32) !void {
    var state = RenderState.init();
    var current_hyperlink_id: u32 = 0;
    var prev_prev_scalar: u21 = 0; // Track 2 characters back for contextual rendering
    var prev_scalar: u21 = 0; // Track previous character for contextual rendering

    // Render all cells across the full width of the artboard.
    // BBS ANSI art uses fixed-width canvases (typically 80 columns),
    // and background colors must extend to the edge even for trailing spaces.
    var x: u32 = 0;
    while (x < width) : (x += 1) {
        const cell = try doc.getCell(x, y);

        // Handle hyperlink state changes
        if (cell.hyperlink_id != current_hyperlink_id) {
            // End current hyperlink if active
            if (current_hyperlink_id > 0) {
                try writer.writeAll("\x1b]8;;\x1b\\");
            }

            // Start new hyperlink if present
            if (cell.hyperlink_id > 0) {
                const link = doc.getHyperlink(cell.hyperlink_id);
                if (link) |l| {
                    try writer.writeAll("\x1b]8;");
                    if (l.params) |params| {
                        try writer.writeAll(params);
                    }
                    try writer.writeAll(";");
                    try writer.writeAll(l.uri);
                    try writer.writeAll("\x1b\\");
                }
            }

            current_hyperlink_id = cell.hyperlink_id;
        }

        // Apply style (batches if unchanged)
        try state.applyStyle(writer, cell.fg_color, cell.bg_color);

        // Emit the glyph (with contextual rendering based on previous characters)
        try encodeGlyphContextual(writer, cell.contents.scalar, prev_scalar, prev_prev_scalar);

        prev_prev_scalar = prev_scalar;
        prev_scalar = cell.contents.scalar;
    }

    // End hyperlink if still active at row end
    if (current_hyperlink_id > 0) {
        try writer.writeAll("\x1b]8;;\x1b\\");
    }

    // Reset SGR to clear background color at right edge
    try writer.writeAll("\x1b[0m");
}

/// Encode a scalar value to UTF-8 and write to output, with contextual rendering.
///
/// ## Glyph Adjustments for ANSI Art
///
/// Some characters require visual adjustments for proper baseline alignment in modern
/// terminal fonts. These adjustments preserve the artist's intent from original CRT displays.
///
/// **Tilde (~ → ˜):**
/// - Standard: U+007E ~ (TILDE) sits too low in modern fonts
/// - Adjusted: U+02DC ˜ (SMALL TILDE) provides better baseline alignment
/// - Rationale: In ANSI art, tildes are used decoratively (e.g., ╚ª"`~, .·:·. ~│) and
///   should align smoothly with surrounding characters. The standard tilde breaks visual
///   continuity by sitting too low.
/// - Note: This is a global replacement. If specific contexts need the standard tilde
///   (e.g., ~strike~ markdown), those can be blacklisted as exceptions in the future.
///
/// ## Other Special Cases
///
/// - **U+0000 (NUL)**: Emitted as space (U+0020) to avoid NULL bytes in output.
///
/// ## Error Handling
///
/// If UTF-8 encoding fails (invalid codepoint), emits Unicode replacement character (�).
fn encodeGlyphContextual(writer: std.io.AnyWriter, scalar: u21, prev_scalar: u21, prev_prev_scalar: u21) !void {
    _ = prev_scalar;
    _ = prev_prev_scalar;

    var codepoint = scalar;

    // Special case: NUL (U+0000) → space (U+0020)
    if (scalar == 0) {
        codepoint = 0x0020;
    }
    // Global adjustment: tilde → SMALL TILDE for baseline alignment in ANSI art
    else if (scalar == '~') {
        codepoint = 0x02DC; // U+02DC ˜ SMALL TILDE
    }

    // Encode as UTF-8
    var buf: [4]u8 = undefined;
    const len = std.unicode.utf8Encode(codepoint, &buf) catch {
        // Invalid codepoint - emit replacement character to avoid output corruption
        try writer.writeAll("�");
        return;
    };
    try writer.writeAll(buf[0..len]);
}

/// Emit SGR color codes for foreground and background.
///
/// **Default behavior (24-bit truecolor)**:
/// - Palette indices 0-15: Convert to RGB via DOS_PALETTE_RGB, emit as 24-bit
/// - RGB colors: Emit directly as 24-bit (SGR 38;2;R;G;B / 48;2;R;G;B)
/// - Color::None: Emit SGR 39/49 (terminal default)
///
/// **Rationale for 24-bit default**:
/// ANSI 256-color palette indices can't be trusted across terminals - the same
/// index may map to different RGB values in different terminal emulators, causing
/// color inconsistencies. By emitting explicit RGB values, we ensure the artist's
/// intended colors display correctly regardless of terminal configuration.
///
/// Spec: .specs/render-utf8ansi/requirements.md FR1.2.2
fn emitColors(writer: std.io.AnyWriter, fg: ir.Color, bg: ir.Color) !void {
    // Emit foreground color
    switch (fg) {
        .none => try writer.writeAll("\x1b[39m"), // Default foreground
        .palette => |idx| {
            // Convert DOS palette index to RGB and emit as 24-bit truecolor
            if (idx < 16) {
                const rgb = DOS_PALETTE_RGB[idx];
                try writer.print("\x1b[38;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
            } else {
                // Extended palette indices (16-255): fall back to 256-color mode
                // (These are rare in classic BBS art but may appear in modern files)
                try writer.print("\x1b[38;5;{d}m", .{idx});
            }
        },
        .rgb => |rgb| {
            // Truecolor (24-bit RGB) - SGR 38;2;R;G;B
            try writer.print("\x1b[38;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
        },
    }

    // Emit background color
    switch (bg) {
        .none => try writer.writeAll("\x1b[49m"), // Default background
        .palette => |idx| {
            // Convert DOS palette index to RGB and emit as 24-bit truecolor
            if (idx < 16) {
                const rgb = DOS_PALETTE_RGB[idx];
                try writer.print("\x1b[48;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
            } else {
                // Extended palette indices (16-255): fall back to 256-color mode
                try writer.print("\x1b[48;5;{d}m", .{idx});
            }
        },
        .rgb => |rgb| {
            // Truecolor (24-bit RGB) - SGR 48;2;R;G;B
            try writer.print("\x1b[48;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
        },
    }
}
