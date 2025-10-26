const std = @import("std");
const Ir = @import("ansilust").ir;

const log = std.log.scoped(.ansi_parser);

/// Maximum CSI sequence length (libansilove compatibility)
const ANSI_SEQUENCE_MAX_LENGTH = 14;

pub const AnsiParserError = error{
    /// The input buffer ended unexpectedly.
    UnexpectedEof,
    /// An invalid SAUCE record was detected.
    InvalidSauceRecord,
    /// An ANSI escape sequence was malformed or unsupported.
    InvalidAnsiSequence,
    /// An invalid parameter was found in an escape sequence.
    InvalidParameter,
};

/// AnsiParser processes a byte stream containing classic ANSI art (with CP437
/// encoding and escape sequences) and converts it into an Ansilust IR Document.
/// It simulates a terminal screen buffer to handle cursor movements and color
// changes.
pub const AnsiParser = struct {
    allocator: std.mem.Allocator,
    doc: Ir.Document,

    // File buffer state
    buffer: []const u8,
    pos: usize,

    // Terminal state
    cursor_x: u32,
    cursor_y: u32,
    saved_cursor_x: u32,
    saved_cursor_y: u32,
    current_attributes: Ir.Attributes,
    current_fg: Ir.Color,
    current_bg: Ir.Color,

    // Parser state
    ice_colors: bool,
    width: u32,
    height: u32,

    const Self = @This();

    /// Initializes a new AnsiParser.
    fn init(allocator: std.mem.Allocator, buffer: []const u8) !Self {
        // Default to 80x25, can be overridden by SAUCE.
        const default_width = 80;
        const default_height = 25;

        const doc = try Ir.Document.init(allocator, default_width, default_height);

        return Self{
            .allocator = allocator,
            .doc = doc,
            .buffer = buffer,
            .pos = 0,
            .cursor_x = 0,
            .cursor_y = 0,
            .saved_cursor_x = 0,
            .saved_cursor_y = 0,
            .current_attributes = Ir.Attributes.none(),
            .current_fg = Ir.Color{ .palette = 7 }, // Default white
            .current_bg = Ir.Color{ .palette = 0 }, // Default black
            .ice_colors = false,
            .width = default_width,
            .height = default_height,
        };
    }

    /// Releases resources held by the parser.
    fn deinit(self: *Self) void {
        self.doc.deinit();
    }

    /// Main parsing loop. Iterates through the buffer and processes each byte.
    fn run(self: *Self) !void {
        while (self.pos < self.buffer.len) {
            const byte = self.buffer[self.pos];
            self.pos += 1;

            // TODO: Implement the full state machine based on libansilove/ansi.c
            switch (byte) {
                // Escape character
                0x1B => try self.handleEscape(),
                // Standard characters
                else => try self.putChar(byte),
            }
        }
    }

    /// Handles an escape sequence starting with ESC (0x1B).
    fn handleEscape(self: *Self) !void {
        if (self.pos >= self.buffer.len) return error.UnexpectedEof;

        const byte = self.buffer[self.pos];
        self.pos += 1;

        if (byte != '[') {
            // Not a CSI sequence, could be other ESC codes.
            // For now, we only handle CSI.
            log.warn("unhandled non-CSI escape sequence: '0x{x}'", .{byte});
            return;
        }

        // Parse CSI parameters with length limit
        var params = std.ArrayList(u32).init(self.allocator);
        defer params.deinit();

        var current_param: u32 = 0;
        var has_param = false;
        var csi_length: usize = 0; // Track CSI sequence length

        loop: while (self.pos < self.buffer.len) {
            // Enforce CSI buffer limit (libansilove: 14 bytes)
            csi_length += 1;
            if (csi_length > ANSI_SEQUENCE_MAX_LENGTH) {
                log.warn("CSI sequence exceeds maximum length ({} bytes), truncating", .{ANSI_SEQUENCE_MAX_LENGTH});
                break :loop;
            }

            const cmd_byte = self.buffer[self.pos];
            self.pos += 1;

            switch (cmd_byte) {
                '0'...'9' => {
                    has_param = true;
                    current_param = current_param * 10 + (cmd_byte - '0');
                },
                ';' => {
                    try params.append(current_param);
                    current_param = 0;
                },
                'm' => { // SGR - Select Graphic Rendition
                    if (has_param) {
                        try params.append(current_param);
                    } else if (params.items.len == 0) {
                        // Empty `[m` resets attributes
                        try params.append(0);
                    }
                    try self.handleSgr(&params);
                    break :loop;
                },
                'A', 'B', 'C', 'D', 'H', 'f', 'J', 'K', 's', 'u' => {
                    // Cursor movement, screen clearing, etc.
                    if (has_param) {
                        try params.append(current_param);
                    }
                    try self.handleCursorOrErase(cmd_byte, &params);
                    break :loop;
                },
                else => {
                    log.warn("unsupported CSI command: '{c}'", .{cmd_byte});
                    break :loop;
                },
            }
        }
    }

    /// Handles SGR (Select Graphic Rendition) escape sequences.
    fn handleSgr(self: *Self, params: *const std.ArrayList(u32)) !void {
        // Placeholder implementation
        if (params.items.len == 0) {
            // `[m` is equivalent to `[0m`
            self.current_attributes = Ir.Attributes.none();
            self.current_fg = Ir.Color{ .palette = 7 };
            self.current_bg = Ir.Color{ .palette = 0 };
            return;
        }

        var i: usize = 0;
        while (i < params.items.len) : (i += 1) {
            const p = params.items[i];
            switch (p) {
                0 => { // Reset all attributes
                    self.current_attributes = Ir.Attributes.none();
                    self.current_fg = Ir.Color{ .palette = 7 };
                    self.current_bg = Ir.Color{ .palette = 0 };
                },
                1 => self.current_attributes = self.current_attributes.setBold(true),
                2 => self.current_attributes = self.current_attributes.setFaint(true),
                3 => self.current_attributes = self.current_attributes.setItalic(true),
                4 => self.current_attributes = self.current_attributes.setUnderline(.single),
                5 => self.current_attributes = self.current_attributes.setBlink(true),
                7 => self.current_attributes = self.current_attributes.setReverse(true),
                8 => self.current_attributes = self.current_attributes.setInvisible(true),
                9 => self.current_attributes = self.current_attributes.setStrikethrough(true),

                // Attribute off commands
                22 => { // Turn off bold and faint
                    self.current_attributes = self.current_attributes.setBold(false);
                    self.current_attributes = self.current_attributes.setFaint(false);
                },
                24 => self.current_attributes = self.current_attributes.setUnderline(.none),
                25 => self.current_attributes = self.current_attributes.setBlink(false),
                27 => self.current_attributes = self.current_attributes.setReverse(false),
                28 => self.current_attributes = self.current_attributes.setInvisible(false),
                29 => self.current_attributes = self.current_attributes.setStrikethrough(false),

                // Standard 16-color foreground
                30...37 => self.current_fg = Ir.Color{ .palette = @intCast(p - 30) },

                // 256-color or 24-bit foreground
                38 => {
                    if (i + 1 < params.items.len) {
                        i += 1;
                        const mode = params.items[i];
                        if (mode == 5 and i + 1 < params.items.len) {
                            // 256-color: ESC[38;5;n
                            i += 1;
                            const color_idx = params.items[i];
                            if (color_idx <= 255) {
                                self.current_fg = Ir.Color{ .palette = @intCast(color_idx) };
                            }
                        } else if (mode == 2 and i + 3 < params.items.len) {
                            // 24-bit RGB: ESC[38;2;r;g;b
                            i += 1;
                            const r = @min(params.items[i], 255);
                            i += 1;
                            const g = @min(params.items[i], 255);
                            i += 1;
                            const b = @min(params.items[i], 255);
                            self.current_fg = Ir.Color{ .rgb = .{
                                .r = @intCast(r),
                                .g = @intCast(g),
                                .b = @intCast(b),
                            } };
                        }
                    }
                },

                // Default foreground color
                39 => self.current_fg = Ir.Color{ .palette = 7 },

                // Standard 16-color background
                40...47 => self.current_bg = Ir.Color{ .palette = @intCast(p - 40) },

                // 256-color or 24-bit background
                48 => {
                    if (i + 1 < params.items.len) {
                        i += 1;
                        const mode = params.items[i];
                        if (mode == 5 and i + 1 < params.items.len) {
                            // 256-color: ESC[48;5;n
                            i += 1;
                            const color_idx = params.items[i];
                            if (color_idx <= 255) {
                                self.current_bg = Ir.Color{ .palette = @intCast(color_idx) };
                            }
                        } else if (mode == 2 and i + 3 < params.items.len) {
                            // 24-bit RGB: ESC[48;2;r;g;b
                            i += 1;
                            const r = @min(params.items[i], 255);
                            i += 1;
                            const g = @min(params.items[i], 255);
                            i += 1;
                            const b = @min(params.items[i], 255);
                            self.current_bg = Ir.Color{ .rgb = .{
                                .r = @intCast(r),
                                .g = @intCast(g),
                                .b = @intCast(b),
                            } };
                        }
                    }
                },

                // Default background color
                49 => self.current_bg = Ir.Color{ .palette = 0 },

                // High intensity foreground colors (bright)
                90...97 => self.current_fg = Ir.Color{ .palette = @intCast(p - 90 + 8) },

                // High intensity background colors (bright)
                100...107 => self.current_bg = Ir.Color{ .palette = @intCast(p - 100 + 8) },

                else => log.warn("unhandled SGR parameter: {}", .{p}),
            }
        }
    }

    /// Handles cursor movement and screen erase commands.
    fn handleCursorOrErase(self: *Self, cmd: u8, params: *const std.ArrayList(u32)) !void {
        switch (cmd) {
            // CUP - Cursor Position (H or f)
            'H', 'f' => {
                const row = if (params.items.len > 0 and params.items[0] > 0) params.items[0] - 1 else 0;
                const col = if (params.items.len > 1 and params.items[1] > 0) params.items[1] - 1 else 0;
                self.cursor_y = @min(row, self.height - 1);
                self.cursor_x = @min(col, self.width - 1);
            },

            // CUU - Cursor Up (A)
            'A' => {
                const n = if (params.items.len > 0 and params.items[0] > 0) params.items[0] else 1;
                if (self.cursor_y >= n) {
                    self.cursor_y -= n;
                } else {
                    self.cursor_y = 0;
                }
            },

            // CUD - Cursor Down (B)
            'B' => {
                const n = if (params.items.len > 0 and params.items[0] > 0) params.items[0] else 1;
                self.cursor_y = @min(self.cursor_y + n, self.height - 1);
            },

            // CUF - Cursor Forward (C)
            'C' => {
                const n = if (params.items.len > 0 and params.items[0] > 0) params.items[0] else 1;
                self.cursor_x = @min(self.cursor_x + n, self.width - 1);
            },

            // CUB - Cursor Back (D)
            'D' => {
                const n = if (params.items.len > 0 and params.items[0] > 0) params.items[0] else 1;
                if (self.cursor_x >= n) {
                    self.cursor_x -= n;
                } else {
                    self.cursor_x = 0;
                }
            },

            // Save cursor position (s)
            's' => {
                self.saved_cursor_x = self.cursor_x;
                self.saved_cursor_y = self.cursor_y;
            },

            // Restore cursor position (u)
            'u' => {
                self.cursor_x = self.saved_cursor_x;
                self.cursor_y = self.saved_cursor_y;
            },

            // Erase in Display (J)
            'J' => {
                const param = if (params.items.len > 0) params.items[0] else 0;
                if (param == 2) {
                    // Clear entire screen and reset cursor to home
                    var y: u32 = 0;
                    while (y < self.height) : (y += 1) {
                        var x: u32 = 0;
                        while (x < self.width) : (x += 1) {
                            _ = self.doc.setCell(x, y, .{
                                .contents = Ir.CellGrid.CellContents{ .scalar = ' ' },
                                .fg_color = self.current_fg,
                                .bg_color = self.current_bg,
                                .attr_flags = Ir.Attributes.none(),
                            }) catch {};
                        }
                    }
                    self.cursor_x = 0;
                    self.cursor_y = 0;
                }
                // Other J variants (0, 1) not commonly used in ANSI art
            },

            // No-op commands that appear in real files
            'K' => {}, // EL - Erase in Line (not implemented, ignored)
            'p' => {}, // Cursor activation (non-standard, ignored)
            'h' => {}, // Set mode (ignored)
            'l' => {}, // Reset mode (ignored)

            else => {
                log.warn("unhandled cursor/erase command: '{c}'", .{cmd});
            },
        }
    }

    /// Places a character on the grid at the current cursor position and advances
    /// the cursor.
    fn putChar(self: *Self, byte: u8) !void {
        // Handle control characters

        // TAB: Advance cursor by 8 columns (libansilove behavior)
        if (byte == '\t') { // 0x09
            self.cursor_x = ((self.cursor_x / 8) + 1) * 8;
            // Handle wrap after TAB
            while (self.cursor_x >= self.width) {
                self.cursor_x -= self.width;
                self.cursor_y += 1;
            }
            return;
        }

        // LF: Move to next line and reset column (libansilove behavior)
        if (byte == '\n') { // 0x0A
            self.cursor_y += 1;
            self.cursor_x = 0;
            return;
        }

        // CR: Reset column to 0 (effectively ignored in most ANSI files)
        if (byte == '\r') { // 0x0D
            self.cursor_x = 0;
            return;
        }

        // SUB: EOF marker, stop processing (rest of file is likely SAUCE)
        if (byte == 0x1A) {
            self.pos = self.buffer.len;
            return;
        }

        // Place character if within bounds
        if (self.cursor_x < self.width and self.cursor_y < self.height) {
            try self.doc.setCell(self.cursor_x, self.cursor_y, .{
                .contents = Ir.CellGrid.CellContents{ .scalar = byte },
                .fg_color = self.current_fg,
                .bg_color = self.current_bg,
                .attr_flags = self.current_attributes,
            });
        }

        // Advance cursor (implicit wrap when reaching width)
        self.cursor_x += 1;
        if (self.cursor_x >= self.width) {
            self.cursor_x = 0;
            self.cursor_y += 1;
        }

        // TODO: Handle scrolling when cursor_y exceeds height.
    }

    /// Checks for and parses a SAUCE record at the end of the file.
    fn checkForSauce(self: *Self) !void {
        const record_size = Ir.Sauce.SAUCE_RECORD_SIZE;
        if (self.buffer.len < record_size) return;

        const sauce_start = self.buffer.len - record_size;
        const sauce_bytes = self.buffer[sauce_start..];

        if (!std.mem.eql(u8, sauce_bytes[0..5], "SAUCE")) {
            return; // No SAUCE record found.
        }

        log.info("SAUCE record detected", .{});
        const sauce_record = try Ir.Sauce.SauceRecord.parse(self.allocator, sauce_bytes);
        self.doc.sauce_record = sauce_record;

        // Apply SAUCE info
        const tinfo1 = sauce_record.tinfo1;
        if (tinfo1 > 0) {
            self.width = tinfo1;
        }
        const tinfo2 = sauce_record.tinfo2;
        if (tinfo2 > 0) {
            self.height = tinfo2;
        }

        // Resize grid based on SAUCE, preserving content
        try self.doc.grid.resize(self.width, self.height);

        const flags = sauce_record.flags;
        self.ice_colors = flags.ice_colors;

        log.debug("Applied SAUCE: width={}, height={}, ice_colors={}", .{ self.width, self.height, self.ice_colors });
    }
};

/// Parses a buffer containing ANSI art into a new IR Document.
/// The returned Document must be deinitialized by the caller.
pub fn parse(allocator: std.mem.Allocator, buffer: []const u8) !Ir.Document {
    var parser = try AnsiParser.init(allocator, buffer);
    errdefer parser.deinit();

    // SAUCE is at the end, so check for it first to get dimensions.
    try parser.checkForSauce();

    // Now parse the content.
    try parser.run();

    // The document is now owned by the caller.
    return parser.doc;
}

// === Tests ===

test "ANSI parser: basic text" {
    const allocator = std.testing.allocator;
    const input = "Hello, World!";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    try std.testing.expectEqual(@as(u32, 80), doc.grid.width);
    try std.testing.expectEqual(@as(u32, 25), doc.grid.height);

    const hello_bytes = "Hello, World!";
    for (hello_bytes, 0..) |char, i| {
        const cell = try doc.getCell(@intCast(i), 0);
        try std.testing.expectEqual(@as(u21, char), cell.contents.scalar);
    }
}

test "ANSI parser: TAB handling" {
    const allocator = std.testing.allocator;
    const input = "A\tB";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    // 'A' at column 0
    const cell_a = try doc.getCell(0, 0);
    try std.testing.expectEqual(@as(u21, 'A'), cell_a.contents.scalar);

    // TAB advances to column 8 (next multiple of 8)
    const cell_b = try doc.getCell(8, 0);
    try std.testing.expectEqual(@as(u21, 'B'), cell_b.contents.scalar);
}

test "ANSI parser: newline handling" {
    const allocator = std.testing.allocator;
    const input = "Line1\nLine2";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    // First line
    const cell1 = try doc.getCell(0, 0);
    try std.testing.expectEqual(@as(u21, 'L'), cell1.contents.scalar);

    // Second line after newline
    const cell2 = try doc.getCell(0, 1);
    try std.testing.expectEqual(@as(u21, 'L'), cell2.contents.scalar);
}

test "ANSI parser: SUB termination" {
    const allocator = std.testing.allocator;
    const input = "Before\x1AAfter";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    // Should parse up to SUB
    const cell = try doc.getCell(5, 0);
    try std.testing.expectEqual(@as(u21, 'e'), cell.contents.scalar);

    // Should NOT parse after SUB
    const cell_after = try doc.getCell(6, 0);
    try std.testing.expectEqual(@as(u21, ' '), cell_after.contents.scalar);
}

test "ANSI parser: SGR bold" {
    const allocator = std.testing.allocator;
    const input = "\x1B[1mBOLD";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    const cell = try doc.getCell(0, 0);
    try std.testing.expect(cell.attr_flags.bold);
}

test "ANSI parser: SGR colors" {
    const allocator = std.testing.allocator;
    const input = "\x1B[31;42mRED";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    const cell = try doc.getCell(0, 0);
    try std.testing.expectEqual(Ir.Color{ .palette = 1 }, cell.fg_color); // Red
    try std.testing.expectEqual(Ir.Color{ .palette = 2 }, cell.bg_color); // Green bg
}

test "ANSI parser: SGR reset" {
    const allocator = std.testing.allocator;
    const input = "\x1B[1;31mBOLD\x1B[0mNORMAL";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    // Bold red text
    const cell1 = try doc.getCell(0, 0);
    try std.testing.expect(cell1.attr_flags.bold);
    try std.testing.expectEqual(Ir.Color{ .palette = 1 }, cell1.fg_color);

    // Reset to normal
    const cell2 = try doc.getCell(4, 0);
    try std.testing.expect(!cell2.attr_flags.bold);
    try std.testing.expectEqual(Ir.Color{ .palette = 7 }, cell2.fg_color);
}

test "ANSI parser: cursor positioning" {
    const allocator = std.testing.allocator;
    const input = "ABC\x1B[2;3HX";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    // 'X' should be at row 1 (2-1), column 2 (3-1)
    const cell = try doc.getCell(2, 1);
    try std.testing.expectEqual(@as(u21, 'X'), cell.contents.scalar);
}

test "ANSI parser: high intensity colors" {
    const allocator = std.testing.allocator;
    const input = "\x1B[91;104mTEST";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    const cell = try doc.getCell(0, 0);
    try std.testing.expectEqual(Ir.Color{ .palette = 9 }, cell.fg_color); // Bright red (90+1=91 -> 8+1=9)
    try std.testing.expectEqual(Ir.Color{ .palette = 12 }, cell.bg_color); // Bright blue (100+4=104 -> 8+4=12)
}

test "ANSI parser: 256-color support" {
    const allocator = std.testing.allocator;
    const input = "\x1B[38;5;196mTEST";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    const cell = try doc.getCell(0, 0);
    try std.testing.expectEqual(Ir.Color{ .palette = 196 }, cell.fg_color);
}

test "ANSI parser: 24-bit color support" {
    const allocator = std.testing.allocator;
    const input = "\x1B[38;2;255;128;64mTEST";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    const cell = try doc.getCell(0, 0);
    const expected = Ir.Color{ .rgb = .{ .r = 255, .g = 128, .b = 64 } };
    try std.testing.expect(cell.fg_color.eql(expected));
}

test "ANSI parser: implicit wrapping" {
    const allocator = std.testing.allocator;
    // Create a string longer than 80 characters to test wrapping
    var buf: [100]u8 = undefined;
    @memset(&buf, 'X');
    const input = buf[0..85];
    var doc = try parse(allocator, input);
    defer doc.deinit();

    // Character 79 should be at end of first line
    const cell79 = try doc.getCell(79, 0);
    try std.testing.expectEqual(@as(u21, 'X'), cell79.contents.scalar);

    // Character 80 should wrap to second line
    const cell80 = try doc.getCell(0, 1);
    try std.testing.expectEqual(@as(u21, 'X'), cell80.contents.scalar);
}
