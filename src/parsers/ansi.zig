const std = @import("std");
const ir = @import("ansilust").ir;

pub const Parser = struct {
    allocator: std.mem.Allocator,
    input: []const u8,
    document: *ir.Document,
    pos: usize = 0,
    cursor_x: u32 = 0,
    cursor_y: u32 = 0,

    // Current style state
    fg_color: ir.Color = .{ .palette = 7 }, // Default white
    bg_color: ir.Color = .{ .palette = 0 }, // Default black
    attributes: ir.AttributeFlags = ir.AttributeFlags.none(),

    pub fn init(allocator: std.mem.Allocator, input: []const u8, document: *ir.Document) Parser {
        document.source_format = .ansi;
        document.default_encoding = .cp437;
        return Parser{
            .allocator = allocator,
            .input = input,
            .document = document,
        };
    }

    pub fn deinit(self: *Parser) void {
        _ = self;
    }

    pub fn parse(self: *Parser) !void {
        while (self.pos < self.input.len) {
            const byte = self.input[self.pos];
            self.pos += 1;

            switch (byte) {
                0x1B => try self.handleEscape(),
                0x0A => self.handleNewline(),
                0x0D => self.handleCarriageReturn(),
                0x09 => self.handleTab(),
                0x1A => return,
                else => try self.writeScalar(byte),
            }
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

    fn writeScalar(self: *Parser, byte: u8) !void {
        const width = self.document.grid.width;
        const height = self.document.grid.height;

        if (width == 0 or height == 0) return;

        if (self.cursor_y >= height) {
            self.cursor_y = height - 1;
        }

        if (self.cursor_x >= width) {
            self.cursor_x = 0;
            self.advanceRow();
        }

        if (self.cursor_y >= height) return;

        const scalar = decodeCP437(byte);
        try self.document.setCell(self.cursor_x, self.cursor_y, .{
            .contents = ir.CellContents{ .scalar = scalar },
            .source_encoding = ir.SourceEncoding.cp437,
            .fg_color = self.fg_color,
            .bg_color = self.bg_color,
            .attr_flags = self.attributes,
        });

        self.cursor_x += 1;
        if (self.cursor_x >= width) {
            self.cursor_x = 0;
            self.advanceRow();
        }
    }

    fn advanceRow(self: *Parser) void {
        const height = self.document.grid.height;
        if (height == 0) return;

        if (self.cursor_y + 1 < height) {
            self.cursor_y += 1;
        } else {
            self.cursor_y = height - 1;
        }
    }

    fn handleEscape(self: *Parser) !void {
        if (self.pos >= self.input.len) return;

        const next_byte = self.input[self.pos];
        if (next_byte == '[') {
            self.pos += 1;
            try self.handleCSI();
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
                    current_param = current_param * 10 + (byte - '0');
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
                    if (has_digit and param_count < params.len) {
                        params[param_count] = current_param;
                        param_count += 1;
                    }

                    // Handle CSI command
                    switch (byte) {
                        'm' => try self.handleSGR(params[0..param_count]),
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

    fn handleSGR(self: *Parser, params: []const u16) !void {
        if (params.len == 0) {
            // SGR 0 (reset)
            self.resetStyle();
            return;
        }

        var i: usize = 0;
        while (i < params.len) : (i += 1) {
            const param = params[i];

            switch (param) {
                0 => self.resetStyle(),
                1 => self.attributes = self.attributes.setBold(true),
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
                },
                24 => self.attributes = self.attributes.setUnderline(.none),
                25 => self.attributes = self.attributes.setBlink(false),
                27 => self.attributes = self.attributes.setReverse(false),
                28 => self.attributes = self.attributes.setInvisible(false),
                29 => self.attributes = self.attributes.setStrikethrough(false),

                // Foreground colors (30-37)
                30...37 => self.fg_color = .{ .palette = @intCast(param - 30) },

                // Background colors (40-47)
                40...47 => self.bg_color = .{ .palette = @intCast(param - 40) },

                // Default foreground
                39 => self.fg_color = .{ .palette = 7 },

                // Default background
                49 => self.bg_color = .{ .palette = 0 },

                // Bright foreground colors (90-97)
                90...97 => self.fg_color = .{ .palette = @intCast(param - 90 + 8) },

                // Bright background colors (100-107)
                100...107 => self.bg_color = .{ .palette = @intCast(param - 100 + 8) },

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

    fn resetStyle(self: *Parser) void {
        self.fg_color = .{ .palette = 7 };
        self.bg_color = .{ .palette = 0 };
        self.attributes = ir.AttributeFlags.none();
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
