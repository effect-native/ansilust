const std = @import("std");
const Ir = @import("ansilust").ir;

const log = std.log.scoped(.ansi_parser);

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

        var doc = try Ir.Document.init(allocator);
        try doc.grid.resize(default_width, default_height);

        return Self{
            .allocator = allocator,
            .doc = doc,
            .buffer = buffer,
            .pos = 0,
            .cursor_x = 0,
            .cursor_y = 0,
            .saved_cursor_x = 0,
            .saved_cursor_y = 0,
            .current_attributes = .{},
            .current_fg = Ir.Color.fromAnsi(7), // Default white
            .current_bg = Ir.Color.fromAnsi(0), // Default black
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

        // TODO: Implement CSI parameter parsing and command dispatch.
        // This is a placeholder.
        var params = std.ArrayList(u32).init(self.allocator);
        defer params.deinit();

        var current_param: u32 = 0;
        var has_param = false;

        loop: while (self.pos < self.buffer.len) {
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
            self.current_attributes = .{};
            self.current_fg = Ir.Color.fromAnsi(7);
            self.current_bg = Ir.Color.fromAnsi(0);
            return;
        }

        var i: usize = 0;
        while (i < params.items.len) : (i += 1) {
            const p = params.items[i];
            switch (p) {
                0 => { // Reset
                    self.current_attributes = .{};
                    self.current_fg = Ir.Color.fromAnsi(7);
                    self.current_bg = Ir.Color.fromAnsi(0);
                },
                1 => self.current_attributes.bold = true,
                5 => self.current_attributes.blink = true,
                7 => self.current_attributes.inverse = true,
                // TODO: Add other attributes (underline, faint, etc.)

                30...37 => self.current_fg = Ir.Color.fromAnsi(@intCast(p - 30)),
                40...47 => self.current_bg = Ir.Color.fromAnsi(@intCast(p - 40)),

                // TODO: Add high intensity colors (90-97, 100-107)
                // TODO: Add 256-color and 24-bit color support

                else => log.warn("unhandled SGR parameter: {}", .{p}),
            }
        }
    }

    /// Handles cursor movement and screen erase commands.
    fn handleCursorOrErase(self: *Self, cmd: u8, params: *const std.ArrayList(u32)) !void {
        _ = self;
        _ = cmd;
        _ = params;
        // TODO: Implement cursor up/down/left/right, position, save/restore,
        // and screen/line clearing logic.
        log.warn("handleCursorOrErase not yet implemented", .{});
    }

    /// Places a character on the grid at the current cursor position and advances
    /// the cursor.
    fn putChar(self: *Self, byte: u8) !void {
        // Handle newline characters
        if (byte == '\n') { // LF
            self.cursor_y += 1;
            // Ansilove also resets cursor_x on LF, let's mimic that.
            self.cursor_x = 0;
            return;
        }
        if (byte == '\r') { // CR
            self.cursor_x = 0;
            return;
        }

        // Ignore EOF character
        if (byte == 0x1A) {
            // Stop processing at SUB character, rest of file might be SAUCE
            self.pos = self.buffer.len;
            return;
        }

        // Place character if within bounds
        if (self.cursor_x < self.width and self.cursor_y < self.height) {
            var cell = self.doc.grid.cell(self.cursor_x, self.cursor_y);
            try cell.setContent(.{ .scalar = byte });
            cell.setColors(self.current_fg, self.current_bg);
            cell.setAttributes(self.current_attributes);
        }

        // Advance cursor
        self.cursor_x += 1;
        if (self.cursor_x >= self.width) {
            self.cursor_x = 0;
            self.cursor_y += 1;
        }

        // TODO: Handle scrolling when cursor_y exceeds height.
    }

    /// Checks for and parses a SAUCE record at the end of the file.
    fn checkForSauce(self: *Self) !void {
        const record_size = Ir.Sauce.Record.size;
        if (self.buffer.len < record_size) return;

        const sauce_start = self.buffer.len - record_size;
        const sauce_bytes = self.buffer[sauce_start..];

        if (!std.mem.eql(u8, sauce_bytes[0..5], "SAUCE")) {
            return; // No SAUCE record found.
        }

        log.info("SAUCE record detected", .{});
        const sauce_record = try Ir.Sauce.parse(self.allocator, sauce_bytes);
        self.doc.sauce = sauce_record;

        // Apply SAUCE info
        const tinfo1 = sauce_record.record.tinfo1;
        if (tinfo1 > 0) {
            self.width = tinfo1;
        }
        const tinfo2 = sauce_record.record.tinfo2;
        if (tinfo2 > 0) {
            self.height = tinfo2;
        }

        // Resize grid based on SAUCE, preserving content
        try self.doc.grid.resize(self.width, self.height);

        const flags = sauce_record.record.flags;
        self.ice_colors = flags.ice_colors;

        log.debug("Applied SAUCE: width={}, height={}, ice_colors={}", .{ self.width, self.height, self.ice_colors });
    }
};

/// Parses a buffer containing ANSI art into a new IR Document.
/// The returned Document must be deinitialized by the caller.
pub fn parse(allocator: std.mem.Allocator, buffer: []const u8) !Ir.Document {
    var parser = try AnsiParser.init(allocator, buffer);
    errdefer parser.deinit();

    // SAUCE is at the end, so check for it first.
    try parser.checkForSauce();

    // Now parse the content.
    try parser.run();

    // The document is now owned by the caller.
    return parser.doc;
}

// TODO: Add a comprehensive test suite.
test "initial parse function" {
    const allocator = std.testing.allocator;
    const input = "Hello, World!";
    var doc = try parse(allocator, input);
    defer doc.deinit();

    try std.testing.expectEqual(@as(u32, 80), doc.grid.width);
    try std.testing.expectEqual(@as(u32, 25), doc.grid.height);

    const hello_bytes = "Hello, World!".*;
    for (hello_bytes, 0..) |char, i| {
        const cell = doc.grid.cell(@intCast(i), 0);
        const content = cell.getContent();
        try std.testing.expect(content.scalar == char);
    }
}
