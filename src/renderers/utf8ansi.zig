const std = @import("std");
const ir = @import("../ir/lib.zig");

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

/// DOS/VGA palette (16 colors) to ANSI 256-color mapping.
///
/// The DOS palette uses indices 0-15, but these don't map directly to
/// ANSI 256-color indices 0-15. Instead, we map to the "xterm 256-color"
/// palette which provides better visual fidelity.
///
/// Reference: libansilove/src/output.c dos_to_ansi_256_map
const DOS_TO_ANSI_256: [16]u8 = .{
    16, // 0: Black       → ANSI 16
    19, // 1: Blue        → ANSI 19
    34, // 2: Green       → ANSI 34
    37, // 3: Cyan        → ANSI 37
    124, // 4: Red         → ANSI 124
    127, // 5: Magenta     → ANSI 127
    130, // 6: Brown       → ANSI 130
    250, // 7: Light Gray  → ANSI 250
    240, // 8: Dark Gray   → ANSI 240
    63, // 9: Light Blue  → ANSI 63
    83, // 10: Light Green → ANSI 83
    87, // 11: Light Cyan  → ANSI 87
    196, // 12: Light Red   → ANSI 196
    201, // 13: Light Magenta → ANSI 201
    227, // 14: Yellow      → ANSI 227
    231, // 15: White       → ANSI 231
};

/// CP437 (DOS) to Unicode codepoint mapping table (256 entries).
///
/// This table maps IBM Code Page 437 bytes (0-255) to Unicode codepoints.
/// CP437 was the original character set for IBM PC and MS-DOS, used extensively
/// in BBS-era ANSI art (1980s-1990s).
///
/// ## Mapping Strategy
///
/// - **0x00-0x1F**: Control characters mapped to visible glyphs (smileys, suits, arrows)
/// - **0x20-0x7E**: Standard ASCII (passthrough)
/// - **0x7F**: House symbol (⌂) instead of DEL control character
/// - **0x80-0xFF**: Extended characters (box drawing, accents, Greek letters, math symbols)
///
/// ## Box Drawing Characters (Critical for ANSI Art)
///
/// CP437 includes extensive box-drawing characters used for borders, frames, and UI elements:
/// - Single-line: ─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼
/// - Double-line: ═ ║ ╔ ╗ ╚ ╝ ╠ ╣ ╦ ╩ ╬
/// - Mixed combinations for complex borders
///
/// ## Shading Characters (Used for Gradients/Textures)
///
/// - 0xB0 (░): Light shade (25% fill)
/// - 0xB1 (▒): Medium shade (50% fill)
/// - 0xB2 (▓): Dark shade (75% fill)
/// - 0xDB (█): Full block (100% fill)
///
/// ## Visual Alignment Note
///
/// This mapping prioritizes visual fidelity over strict encoding equivalence.
/// Some glyphs may appear slightly different from original CRT displays, but
/// modern terminal fonts (e.g., IBM Plex Mono, Cascadia Code) render them well.
///
/// Reference: https://en.wikipedia.org/wiki/Code_page_437
const CP437_TO_UNICODE = [256]u21{
    // 0x00-0x1F: Control characters / special glyphs
    0x0000, 0x263A, 0x263B, 0x2665, 0x2666, 0x2663, 0x2660, 0x2022,
    0x25D8, 0x25CB, 0x25D9, 0x2642, 0x2640, 0x266A, 0x266B, 0x263C,
    0x25BA, 0x25C4, 0x2195, 0x203C, 0x00B6, 0x00A7, 0x25AC, 0x21A8,
    0x2191, 0x2193, 0x2192, 0x2190, 0x221F, 0x2194, 0x25B2, 0x25BC,

    // 0x20-0x7F: ASCII printable characters (passthrough)
    0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
    0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
    0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047,
    0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
    0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057,
    0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
    0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
    0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
    0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
    0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x2302,

    // 0x80-0xFF: Extended characters (box drawing, accents, symbols)
    0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7,
    0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
    0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9,
    0x00FF, 0x00D6, 0x00DC, 0x00A2, 0x00A3, 0x00A5, 0x20A7, 0x0192,
    0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA,
    0x00BF, 0x2310, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
    0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556,
    0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
    0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F,
    0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
    0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B,
    0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
    0x03B1, 0x00DF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0x00B5, 0x03C4,
    0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x03B5, 0x2229,
    0x2261, 0x00B1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00F7, 0x2248,
    0x00B0, 0x2219, 0x00B7, 0x221A, 0x207F, 0x00B2, 0x25A0, 0x00A0,
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

/// Render a single row at the given y coordinate.
fn renderRow(doc: *const ir.Document, writer: std.io.AnyWriter, y: u32, width: u32) !void {
    try writer.print("\x1b[{d};1H", .{y + 1});

    var state = RenderState.init();

    var x: u32 = 0;
    while (x < width) : (x += 1) {
        const cell = try doc.getCell(x, y);

        // Apply style (batches if unchanged)
        try state.applyStyle(writer, cell.fg_color, cell.bg_color);

        // Emit the glyph
        try encodeGlyph(writer, cell.contents.scalar);
    }
}

/// Encode a scalar value to UTF-8 and write to output.
///
/// ## CP437 Handling (scalars 0-255)
///
/// Uses the CP437_TO_UNICODE lookup table to translate DOS characters
/// to their Unicode equivalents. This ensures box-drawing, shading, and
/// special characters render correctly in modern terminals.
///
/// ## Unicode Passthrough (scalars > 255)
///
/// For values already in Unicode range, emits directly as UTF-8.
/// This supports UTF8ANSI source documents with emoji, CJK, etc.
///
/// ## Error Handling
///
/// If UTF-8 encoding fails (invalid codepoint), emits Unicode replacement
/// character (�) to avoid breaking the output stream.
fn encodeGlyph(writer: std.io.AnyWriter, scalar: u21) !void {
    const codepoint = if (scalar <= 255)
        CP437_TO_UNICODE[scalar]
    else
        scalar; // Already Unicode

    // Encode codepoint as UTF-8 (1-4 bytes depending on codepoint value)
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
/// Uses the DOS→ANSI 256 color mapping for palette colors.
/// Emits SGR 39/49 for Color.none (terminal default).
///
/// Currently only implements 256-color mode. Truecolor (24-bit RGB)
/// will be added in Cycle 7.
fn emitColors(writer: std.io.AnyWriter, fg: ir.Color, bg: ir.Color) !void {
    // Emit foreground color
    switch (fg) {
        .none => try writer.writeAll("\x1b[39m"), // Default foreground
        .palette => |idx| {
            // Map DOS palette to ANSI 256-color
            const ansi_idx = if (idx < 16) DOS_TO_ANSI_256[idx] else idx;
            try writer.print("\x1b[38;5;{d}m", .{ansi_idx});
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
            // Map DOS palette to ANSI 256-color
            const ansi_idx = if (idx < 16) DOS_TO_ANSI_256[idx] else idx;
            try writer.print("\x1b[48;5;{d}m", .{ansi_idx});
        },
        .rgb => |rgb| {
            // Truecolor (24-bit RGB) - SGR 48;2;R;G;B
            try writer.print("\x1b[48;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });
        },
    }
}

// Common CP437 character constants for reference
const CP437_LIGHT_SHADE: u8 = 0xB0; // ░
const CP437_MEDIUM_SHADE: u8 = 0xB1; // ▒
const CP437_DARK_SHADE: u8 = 0xB2; // ▓
const CP437_FULL_BLOCK: u8 = 0xDB; // █
const CP437_BOX_TOP_LEFT: u8 = 0xDA; // ┌
const CP437_BOX_HORIZONTAL: u8 = 0xC4; // ─
const CP437_BOX_TOP_RIGHT: u8 = 0xBF; // ┐
