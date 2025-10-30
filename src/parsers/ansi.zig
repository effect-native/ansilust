const std = @import("std");
const ir = @import("ansilust").ir;

pub const Parser = struct {
    allocator: std.mem.Allocator,
    input: []const u8,
    document: *ir.Document,
    pos: usize = 0,
    cursor_x: u32 = 0,
    cursor_y: u32 = 0,

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
