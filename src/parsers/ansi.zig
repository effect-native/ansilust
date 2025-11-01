const std = @import("std");
const ir = @import("ansilust").ir;
const sauce = ir.sauce;

// Default ANSI colors (in DOS palette order)
const DEFAULT_FG_COLOR: ir.Color = .{ .palette = 7 }; // Light Gray
const DEFAULT_BG_COLOR: ir.Color = .{ .palette = 0 }; // Black

/// ANSI/VT SGR color order → DOS/CGA palette order mapping.
///
/// ANSI/VT (SGR 30-37) uses: Black, Red, Green, Yellow, Blue, Magenta, Cyan, White
/// DOS/CGA palette uses:     Black, Blue, Green, Cyan, Red, Magenta, Brown, Light Gray
///
/// This table converts ANSI SGR indices (0-7) to DOS palette indices (0-7).
/// Reference: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
const ANSI_TO_DOS_COLOR: [8]u8 = .{
    0, // 0: Black   → DOS 0 (Black)
    4, // 1: Red     → DOS 4 (Red)
    2, // 2: Green   → DOS 2 (Green)
    6, // 3: Yellow  → DOS 6 (Brown/Yellow)
    1, // 4: Blue    → DOS 1 (Blue)
    5, // 5: Magenta → DOS 5 (Magenta)
    3, // 6: Cyan    → DOS 3 (Cyan)
    7, // 7: White   → DOS 7 (Light Gray)
};

/// Bright ANSI/VT color order → DOS/CGA palette order mapping (indices 8-15).
const ANSI_TO_DOS_BRIGHT_COLOR: [8]u8 = .{
    8, // 0: Bright Black (Dark Gray)   → DOS 8
    12, // 1: Bright Red                 → DOS 12
    10, // 2: Bright Green               → DOS 10
    14, // 3: Bright Yellow              → DOS 14
    9, // 4: Bright Blue                → DOS 9
    13, // 5: Bright Magenta             → DOS 13
    11, // 6: Bright Cyan                → DOS 11
    15, // 7: Bright White               → DOS 15
};

const StyleState = struct {
    fg_color: ir.Color = DEFAULT_FG_COLOR,
    bg_color: ir.Color = DEFAULT_BG_COLOR,
    attributes: ir.AttributeFlags = ir.AttributeFlags.none(),

    fn reset(self: *StyleState) void {
        self.* = StyleState{};
    }

    fn applySGR(self: *StyleState, params: []const u16) void {
        if (params.len == 0) {
            self.reset();
            return;
        }

        var i: usize = 0;
        while (i < params.len) : (i += 1) {
            const param = params[i];

            switch (param) {
                0 => self.reset(),
                1 => {
                    self.attributes = self.attributes.setBold(true);
                    // Bold converts palette 0-7 to 8-15 for foreground
                    self.applyBoldToForeground();
                },
                2 => self.attributes = self.attributes.setFaint(true),
                3 => self.attributes = self.attributes.setItalic(true),
                4 => self.attributes = self.attributes.setUnderline(.single),
                5 => self.attributes = self.attributes.setBlink(true),
                7 => self.attributes = self.attributes.setReverse(true),
                8 => self.attributes = self.attributes.setInvisible(true),
                9 => self.attributes = self.attributes.setStrikethrough(true),
                22 => {
                    self.attributes = self.attributes.setBold(false);
                    self.attributes = self.attributes.setFaint(false);
                    // Unbold converts palette 8-15 back to 0-7 for foreground
                    self.removeBoldFromForeground();
                },
                24 => self.attributes = self.attributes.setUnderline(.none),
                25 => self.attributes = self.attributes.setBlink(false),
                27 => self.attributes = self.attributes.setReverse(false),
                28 => self.attributes = self.attributes.setInvisible(false),
                29 => self.attributes = self.attributes.setStrikethrough(false),

                // Foreground colors (30-37) - remap ANSI order to DOS order
                30...37 => {
                    var dos_idx = ANSI_TO_DOS_COLOR[param - 30];
                    // In classic ANSI, bold converts normal colors (0-7) to bright (8-15)
                    if (self.attributes.bold and dos_idx < 8) {
                        dos_idx += 8;
                    }
                    self.fg_color = .{ .palette = dos_idx };
                },

                // Background colors (40-47) - remap ANSI order to DOS order
                40...47 => self.bg_color = .{ .palette = ANSI_TO_DOS_COLOR[param - 40] },

                // Default foreground
                39 => self.fg_color = DEFAULT_FG_COLOR,

                // Default background
                49 => self.bg_color = DEFAULT_BG_COLOR,

                // Bright foreground colors (90-97) - remap ANSI order to DOS order
                90...97 => self.fg_color = .{ .palette = ANSI_TO_DOS_BRIGHT_COLOR[param - 90] },

                // Bright background colors (100-107) - remap ANSI order to DOS order
                100...107 => self.bg_color = .{ .palette = ANSI_TO_DOS_BRIGHT_COLOR[param - 100] },

                // 256-color foreground (38;5;n)
                38 => {
                    if (i + 2 < params.len and params[i + 1] == 5) {
                        const color_index = params[i + 2];
                        self.fg_color = palette256ToRGB(color_index);
                        i += 2;
                    } else if (i + 4 < params.len and params[i + 1] == 2) {
                        // Truecolor foreground (38;2;r;g;b)
                        const r: u8 = @intCast(@min(params[i + 2], 255));
                        const g: u8 = @intCast(@min(params[i + 3], 255));
                        const b: u8 = @intCast(@min(params[i + 4], 255));
                        self.fg_color = .{ .rgb = .{ .r = r, .g = g, .b = b } };
                        i += 4;
                    }
                },

                // 256-color background (48;5;n)
                48 => {
                    if (i + 2 < params.len and params[i + 1] == 5) {
                        const color_index = params[i + 2];
                        self.bg_color = palette256ToRGB(color_index);
                        i += 2;
                    } else if (i + 4 < params.len and params[i + 1] == 2) {
                        // Truecolor background (48;2;r;g;b)
                        const r: u8 = @intCast(@min(params[i + 2], 255));
                        const g: u8 = @intCast(@min(params[i + 3], 255));
                        const b: u8 = @intCast(@min(params[i + 4], 255));
                        self.bg_color = .{ .rgb = .{ .r = r, .g = g, .b = b } };
                        i += 4;
                    }
                },

                else => {}, // Ignore unknown SGR codes
            }
        }
    }

    /// Apply bold attribute to current foreground color (palette 0-7 → 8-15).
    fn applyBoldToForeground(self: *StyleState) void {
        switch (self.fg_color) {
            .palette => |idx| {
                if (idx < 8) {
                    self.fg_color = .{ .palette = idx + 8 };
                }
            },
            else => {},
        }
    }

    /// Remove bold attribute from current foreground color (palette 8-15 → 0-7).
    fn removeBoldFromForeground(self: *StyleState) void {
        switch (self.fg_color) {
            .palette => |idx| {
                if (idx >= 8 and idx < 16) {
                    self.fg_color = .{ .palette = idx - 8 };
                }
            },
            else => {},
        }
    }
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    input: []const u8,
    document: *ir.Document,
    pos: usize = 0,
    content_end: usize = 0,
    cursor_x: u32 = 0,
    cursor_y: u32 = 0,
    sauce_processed: bool = false,

    style: StyleState = .{},
    saved_cursor_x: u32 = 0,
    saved_cursor_y: u32 = 0,
    current_hyperlink_id: u32 = 0,

    pub fn init(allocator: std.mem.Allocator, input: []const u8, document: *ir.Document) Parser {
        document.source_format = .ansi;
        document.default_encoding = .cp437;
        return Parser{
            .allocator = allocator,
            .input = input,
            .document = document,
            .content_end = input.len,
        };
    }

    pub fn deinit(self: *Parser) void {
        _ = self;
    }

    pub fn parse(self: *Parser) !void {
        try self.ensureSauce();

        while (self.pos < self.content_end) {
            const byte = self.input[self.pos];
            self.pos += 1;

            switch (byte) {
                0x1B => try self.handleEscape(),
                0x0A => self.handleNewline(),
                0x0D => self.handleCarriageReturn(),
                0x09 => self.handleTab(),
                0x1A => {
                    break;
                },
                else => try self.writeScalar(byte),
            }
        }
    }

    fn ensureSauce(self: *Parser) !void {
        if (self.sauce_processed) return;
        self.content_end = self.input.len;

        const sauce_offset = sauce.detectSauce(self.input) orelse {
            self.sauce_processed = true;
            return;
        };

        self.content_end = sauce_offset;

        var record = sauce.SauceRecord.parse(self.allocator, self.input[sauce_offset..]) catch {
            self.sauce_processed = true;
            return;
        };

        var comments_start = sauce_offset;
        if (record.comment_lines > 0) {
            if (sauce.detectComments(self.input, record.comment_lines, sauce_offset)) |comment_offset| {
                comments_start = comment_offset;
                self.content_end = comment_offset;
                record.parseComments(self.input[comment_offset..sauce_offset]) catch {
                    // Ignore comment parse errors but keep SAUCE record
                };
            }
        }

        const columns_opt = record.getColumns();
        const lines_opt = record.getLines();

        self.document.setSauce(record);
        self.document.applySauceHints();
        try self.applySauceDimensions(columns_opt, lines_opt);

        self.content_end = @min(self.content_end, comments_start);
        self.sauce_processed = true;
    }

    fn applySauceDimensions(self: *Parser, columns_opt: ?u16, lines_opt: ?u16) !void {
        var new_width: u32 = self.document.grid.width;
        var new_height: u32 = self.document.grid.height;

        if (columns_opt) |cols| {
            if (cols > 0) new_width = cols;
        }

        if (lines_opt) |lines| {
            if (lines > 0) new_height = lines;
        }

        if (new_width == 0 or new_height == 0) {
            return;
        }

        if (new_width != self.document.grid.width or new_height != self.document.grid.height) {
            try self.document.resize(new_width, new_height);
        }
    }

    fn handleNewline(self: *Parser) void {
        self.advanceRow();
        self.cursor_x = 0;
    }

    fn handleCarriageReturn(self: *Parser) void {
        self.cursor_x = 0;
    }

    fn handleTab(self: *Parser) void {
        const width = self.document.grid.width;
        if (width == 0) return;

        const next_stop = ((self.cursor_x / 8) + 1) * 8;
        if (next_stop < width) {
            self.cursor_x = next_stop;
            return;
        }

        self.cursor_x = 0;
        self.advanceRow();
    }

    /// Attempt to decode a UTF-8 sequence starting at given position.
    /// Returns the decoded codepoint and number of bytes consumed, or null if not valid UTF-8.
    fn tryDecodeUTF8(self: *Parser, start_pos: usize, first_byte: u8) ?struct { codepoint: u21, bytes_consumed: u8 } {
        // Single-byte ASCII (0x00-0x7F)
        if (first_byte < 0x80) {
            return .{ .codepoint = @as(u21, first_byte), .bytes_consumed = 1 };
        }

        // Invalid UTF-8 start byte (0x80-0xBF are continuation bytes)
        if (first_byte < 0xC0) return null;

        // Multi-byte sequence
        var bytes_needed: u8 = 0;
        var codepoint: u21 = 0;

        if (first_byte < 0xE0) {
            // 2-byte sequence (110xxxxx 10xxxxxx)
            bytes_needed = 2;
            codepoint = @as(u21, first_byte & 0x1F);
        } else if (first_byte < 0xF0) {
            // 3-byte sequence (1110xxxx 10xxxxxx 10xxxxxx)
            bytes_needed = 3;
            codepoint = @as(u21, first_byte & 0x0F);
        } else if (first_byte < 0xF8) {
            // 4-byte sequence (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
            bytes_needed = 4;
            codepoint = @as(u21, first_byte & 0x07);
        } else {
            // Invalid UTF-8 (0xF8-0xFF)
            return null;
        }

        // Check if we have enough bytes remaining
        // Note: start_pos points to the byte AFTER first_byte (due to parse loop increment)
        if (start_pos + bytes_needed - 1 > self.content_end) return null;

        // Decode continuation bytes
        var i: u8 = 1;
        while (i < bytes_needed) : (i += 1) {
            const cont_byte = self.input[start_pos + i - 1];
            // Continuation bytes must be 10xxxxxx
            if ((cont_byte & 0xC0) != 0x80) return null;
            codepoint = (codepoint << 6) | @as(u21, cont_byte & 0x3F);
        }

        // Validate codepoint range
        if (codepoint > 0x10FFFF) return null;

        // Check for overlong encoding
        const min_codepoint: u21 = switch (bytes_needed) {
            2 => 0x80,
            3 => 0x800,
            4 => 0x10000,
            else => 0,
        };
        if (codepoint < min_codepoint) return null;

        // IMPORTANT: Disambiguate CP437 from UTF-8.
        //
        // CP437 uses ALL bytes 0x80-0xFF as single-byte characters (box drawing, etc.).
        // UTF-8 also uses bytes 0x80-0xFF, creating ambiguity. We use these heuristics:
        //
        // 1. 2-byte UTF-8 (0xC0-0xDF): Encodes U+0080 to U+07FF
        //    - Reject if codepoint < 0x100 (likely CP437, not UTF-8)
        //    - Reject if codepoint in Latin-1 supplement (U+0080-U+00FF) since CP437
        //      has its own encoding for these (not 1:1 with Unicode)
        //
        // 2. 3-byte UTF-8 (0xE0-0xEF): Encodes U+0800 to U+FFFF
        //    - Accept! These are clearly beyond CP437's range
        //    - Common for arrows (→ U+2192), checkmarks (✓ U+2713), emoji
        //
        // 3. 4-byte UTF-8 (0xF0-0xF7): Encodes U+10000 to U+10FFFF
        //    - Accept! Clearly beyond CP437
        //
        // This allows modern UTF8ANSI (from our renderer) while preserving CP437.
        if (bytes_needed == 2 and codepoint < 0x800) {
            // 2-byte sequence for low codepoint - likely CP437, not UTF-8
            return null;
        }

        return .{ .codepoint = codepoint, .bytes_consumed = bytes_needed };
    }

    fn writeScalar(self: *Parser, byte: u8) !void {
        const width = self.document.grid.width;
        var height = self.document.grid.height;

        if (width == 0 or height == 0) return;

        // Auto-expand grid if cursor is beyond current bounds
        if (self.cursor_y >= height) {
            const new_height = self.cursor_y + 25;
            try self.document.resize(width, new_height);
            height = new_height;
        }

        if (self.cursor_x >= width) {
            self.cursor_x = 0;
            self.advanceRow();
        }

        if (self.cursor_y >= height) return;

        // Try UTF-8 decoding first
        // Note: self.pos has already been incremented by parse loop, so it points to next byte
        var scalar: u21 = undefined;
        var encoding: ir.SourceEncoding = undefined;

        if (self.tryDecodeUTF8(self.pos, byte)) |utf8_result| {
            scalar = utf8_result.codepoint;
            encoding = .utf_8;
            // Advance position past UTF-8 continuation bytes (first byte already consumed by loop)
            self.pos += utf8_result.bytes_consumed - 1;
        } else {
            // Fall back to CP437 decoding for single byte
            scalar = decodeCP437(byte);
            encoding = .cp437;
        }

        try self.document.setCell(self.cursor_x, self.cursor_y, .{
            .contents = ir.CellContents{ .scalar = scalar },
            .source_encoding = encoding,
            .fg_color = self.style.fg_color,
            .bg_color = self.style.bg_color,
            .attr_flags = self.style.attributes,
            .hyperlink_id = if (self.current_hyperlink_id > 0) self.current_hyperlink_id else null,
        });

        self.cursor_x += 1;
        if (self.cursor_x >= width) {
            self.cursor_x = 0;
            self.advanceRow();
        }
    }

    fn advanceRow(self: *Parser) void {
        // Always advance cursor; writeScalar() will auto-expand if needed
        self.cursor_y += 1;
    }

    fn handleEscape(self: *Parser) !void {
        if (self.pos >= self.input.len) return;

        const next_byte = self.input[self.pos];
        if (next_byte == '[') {
            self.pos += 1;
            try self.handleCSI();
        } else if (next_byte == ']') {
            self.pos += 1;
            try self.handleOSC();
        }
    }

    fn handleCSI(self: *Parser) !void {
        var params: [16]u16 = undefined;
        var param_count: usize = 0;
        var current_param: u16 = 0;
        var has_digit = false;

        while (self.pos < self.input.len) {
            const byte = self.input[self.pos];
            self.pos += 1;

            switch (byte) {
                '0'...'9' => {
                    has_digit = true;
                    const digit: u16 = byte - '0';
                    // Guard against overflow: cap at max u16 value
                    const new_value = @as(u32, current_param) * 10 + digit;
                    current_param = if (new_value > 65535) 65535 else @intCast(new_value);
                },
                ';' => {
                    if (param_count < params.len) {
                        params[param_count] = current_param;
                        param_count += 1;
                    }
                    current_param = 0;
                    has_digit = false;
                },
                'A'...'Z', 'a'...'z' => {
                    // Final byte
                    if (has_digit) {
                        if (param_count < params.len) {
                            params[param_count] = current_param;
                            param_count += 1;
                        }
                    }

                    if (param_count == 0) {
                        params[0] = 0;
                        param_count = 1;
                    }

                    // Handle CSI command
                    switch (byte) {
                        'm' => self.style.applySGR(params[0..param_count]),
                        'H' => self.handleCursorPosition(params[0..param_count]),
                        'A' => self.handleCursorUp(params[0..param_count]),
                        'B' => self.handleCursorDown(params[0..param_count]),
                        'C' => self.handleCursorForward(params[0..param_count]),
                        'D' => self.handleCursorBack(params[0..param_count]),
                        's' => self.handleSaveCursor(),
                        'u' => self.handleRestoreCursor(),
                        'J' => try self.handleEraseDisplay(params[0..param_count]),
                        'K' => try self.handleEraseLine(params[0..param_count]),
                        else => {}, // Ignore unknown sequences
                    }
                    return;
                },
                else => {
                    // Malformed - abort sequence
                    return;
                },
            }
        }
    }

    fn handleCursorPosition(self: *Parser, params: []const u16) void {
        const width = self.document.grid.width;
        const height = self.document.grid.height;
        if (width == 0 or height == 0) return;

        // CSI H uses 1-based coordinates; default is 1;1
        const row = if (params.len > 0 and params[0] > 0) params[0] - 1 else 0;
        const col = if (params.len > 1 and params[1] > 0) params[1] - 1 else 0;

        self.cursor_y = @min(row, height - 1);
        self.cursor_x = @min(col, width - 1);
    }

    fn handleCursorUp(self: *Parser, params: []const u16) void {
        const n = if (params.len > 0 and params[0] > 0) params[0] else 1;
        self.cursor_y = if (self.cursor_y >= n) self.cursor_y - n else 0;
    }

    fn handleCursorDown(self: *Parser, params: []const u16) void {
        const height = self.document.grid.height;
        if (height == 0) return;

        const n = if (params.len > 0 and params[0] > 0) params[0] else 1;
        self.cursor_y = @min(self.cursor_y + n, height - 1);
    }

    fn handleCursorForward(self: *Parser, params: []const u16) void {
        const width = self.document.grid.width;
        if (width == 0) return;

        const n = if (params.len > 0 and params[0] > 0) params[0] else 1;
        self.cursor_x = @min(self.cursor_x + n, width - 1);
    }

    fn handleCursorBack(self: *Parser, params: []const u16) void {
        const n = if (params.len > 0 and params[0] > 0) params[0] else 1;
        self.cursor_x = if (self.cursor_x >= n) self.cursor_x - n else 0;
    }

    fn handleSaveCursor(self: *Parser) void {
        self.saved_cursor_x = self.cursor_x;
        self.saved_cursor_y = self.cursor_y;
    }

    fn handleRestoreCursor(self: *Parser) void {
        self.cursor_x = self.saved_cursor_x;
        self.cursor_y = self.saved_cursor_y;
    }

    fn handleEraseDisplay(self: *Parser, params: []const u16) !void {
        const mode = if (params.len > 0) params[0] else 0;
        const width = self.document.grid.width;
        const height = self.document.grid.height;

        const saved_y = self.cursor_y;

        switch (mode) {
            0 => {
                // Erase from cursor to end of display
                var x = self.cursor_x;
                while (x < width) : (x += 1) {
                    try self.clearCell(x, self.cursor_y);
                }

                var y = self.cursor_y + 1;
                while (y < height) : (y += 1) {
                    x = 0;
                    while (x < width) : (x += 1) {
                        try self.clearCell(x, y);
                    }
                }
            },
            2 => {
                // Erase entire display
                var y: u32 = 0;
                while (y < height) : (y += 1) {
                    var x: u32 = 0;
                    while (x < width) : (x += 1) {
                        try self.clearCell(x, y);
                    }
                }
            },
            else => {},
        }

        self.cursor_y = saved_y;
    }

    fn handleEraseLine(self: *Parser, params: []const u16) !void {
        const mode = if (params.len > 0) params[0] else 0;
        const width = self.document.grid.width;

        switch (mode) {
            0 => {
                // Erase from cursor to end of line
                var x = self.cursor_x;
                while (x < width) : (x += 1) {
                    try self.clearCell(x, self.cursor_y);
                }
            },
            else => {},
        }
    }

    fn clearCell(self: *Parser, x: u32, y: u32) !void {
        try self.document.setCell(x, y, .{
            .contents = ir.CellContents{ .scalar = ' ' },
            .source_encoding = ir.SourceEncoding.cp437,
            .fg_color = DEFAULT_FG_COLOR,
            .bg_color = DEFAULT_BG_COLOR,
            .attr_flags = ir.AttributeFlags.none(),
        });
    }

    fn handleOSC(self: *Parser) !void {
        // OSC format: ESC ] Ps ; Pt ST
        // where ST = ESC \ or BEL (0x07)
        // For OSC 8: ESC ] 8 ; params ; URI ST

        // Parse command number
        var cmd: u16 = 0;
        while (self.pos < self.input.len) {
            const byte = self.input[self.pos];
            if (byte >= '0' and byte <= '9') {
                cmd = cmd * 10 + (byte - '0');
                self.pos += 1;
            } else if (byte == ';') {
                self.pos += 1;
                break;
            } else {
                // Invalid OSC sequence, skip it
                self.skipToStringTerminator();
                return;
            }
        }

        // Only handle OSC 8 (hyperlinks)
        if (cmd == 8) {
            try self.handleOSC8();
        } else {
            // Skip unknown OSC sequences
            self.skipToStringTerminator();
        }
    }

    fn handleOSC8(self: *Parser) !void {
        // OSC 8 format: ESC ] 8 ; params ; URI ST
        // Parse params (optional key=value pairs separated by :)
        const params_start = self.pos;
        var params_end = self.pos;

        // Find end of params (next semicolon)
        while (self.pos < self.input.len) {
            const byte = self.input[self.pos];
            if (byte == ';') {
                params_end = self.pos;
                self.pos += 1;
                break;
            }
            self.pos += 1;
        }

        // Parse URI (everything until ST)
        const uri_start = self.pos;
        var uri_end = self.pos;

        while (self.pos < self.input.len) {
            const byte = self.input[self.pos];

            // Check for string terminator: ESC \ or BEL
            if (byte == 0x07) {
                // BEL terminator
                uri_end = self.pos;
                self.pos += 1;
                break;
            } else if (byte == 0x1B) {
                // Possible ESC \ terminator
                if (self.pos + 1 < self.input.len and self.input[self.pos + 1] == '\\') {
                    uri_end = self.pos;
                    self.pos += 2;
                    break;
                }
            }

            self.pos += 1;
        }

        const uri = self.input[uri_start..uri_end];
        const params = if (params_end > params_start) self.input[params_start..params_end] else null;

        // Empty URI means end hyperlink
        if (uri.len == 0) {
            self.current_hyperlink_id = 0;
        } else {
            // Add hyperlink to document (deduplicates automatically)
            self.current_hyperlink_id = try self.document.addHyperlink(uri, params);
        }
    }

    fn skipToStringTerminator(self: *Parser) void {
        // Skip until we find ST (ESC \ or BEL)
        while (self.pos < self.input.len) {
            const byte = self.input[self.pos];

            if (byte == 0x07) {
                // BEL terminator
                self.pos += 1;
                break;
            } else if (byte == 0x1B) {
                // Possible ESC \ terminator
                if (self.pos + 1 < self.input.len and self.input[self.pos + 1] == '\\') {
                    self.pos += 2;
                    break;
                }
            }

            self.pos += 1;
        }
    }
};

pub fn parse(allocator: std.mem.Allocator, input: []const u8) !ir.Document {
    var doc = try ir.Document.init(allocator, 80, 25);
    errdefer doc.deinit();

    var parser = Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();

    return doc;
}

fn decodeCP437(byte: u8) u21 {
    if (byte < 0x80) {
        return @as(u21, byte);
    }

    const index: usize = @intCast(byte - 0x80);
    return CP437_EXTENDED[index];
}

const CP437_EXTENDED = [_]u21{
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

// Convert 256-color palette index to RGB
// Uses xterm 256-color palette standard
fn palette256ToRGB(index: u16) ir.Color {
    if (index < 16) {
        // Standard ANSI colors (0-15) - use palette
        return .{ .palette = @intCast(index) };
    } else if (index >= 16 and index < 232) {
        // 216-color RGB cube (6x6x6)
        // Each component: 0, 95, 135, 175, 215, 255
        const COLOR_LEVELS = [6]u8{ 0, 95, 135, 175, 215, 255 };

        const offset = index - 16;
        const r_idx: usize = @intCast(offset / 36);
        const g_idx: usize = @intCast((offset % 36) / 6);
        const b_idx: usize = @intCast(offset % 6);

        return .{ .rgb = .{ .r = COLOR_LEVELS[r_idx], .g = COLOR_LEVELS[g_idx], .b = COLOR_LEVELS[b_idx] } };
    } else if (index >= 232 and index < 256) {
        // Grayscale ramp (24 values)
        const gray_idx = index - 232;
        const gray: u8 = @intCast(8 + gray_idx * 10);
        return .{ .rgb = .{ .r = gray, .g = gray, .b = gray } };
    } else {
        // Out of range - return white
        return .{ .palette = 7 };
    }
}
