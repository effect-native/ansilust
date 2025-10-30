//! Ansilust IR - SAUCE Metadata Module
//!
//! SAUCE (Standard Architecture for Universal Comment Extensions) is a
//! metadata format appended to BBS art files. Stores title, author, group,
//! date, dimensions, font, flags, and optional comments.
//!
//! SAUCE Record: 128 bytes at end of file
//! SAUCE Comments: Optional block before SAUCE record
//!
//! Implements RQ-SAUCE-1, RQ-SAUCE-2, RQ-Meta-1, RQ-Meta-2.
//!
//! Reference: http://www.acid.org/info/sauce/sauce.htm

const std = @import("std");
const errors = @import("errors.zig");
const encoding = @import("encoding.zig");

/// SAUCE record version identifier
pub const SAUCE_VERSION = "00";

/// SAUCE ID magic bytes: "SAUCE"
pub const SAUCE_ID = "SAUCE";

/// SAUCE comment ID magic bytes: "COMNT"
pub const COMNT_ID = "COMNT";

/// SAUCE record size (fixed 128 bytes)
pub const SAUCE_RECORD_SIZE = 128;

/// SAUCE comment line size (64 bytes per line)
pub const SAUCE_COMMENT_LINE_SIZE = 64;

/// SAUCE flags bitfield.
///
/// Encodes rendering hints critical for proper display of BBS art.
/// From SAUCE specification, the ANSiFlags byte controls:
/// - Bit 0: Non-blink mode (iCE colors)
/// - Bits 1-2: Letter spacing (00=8 pixel, 01=9 pixel, 10=invalid, 11=invalid)
/// - Bits 3-4: Aspect ratio (00=none, 01=legacy, 10=stretch, 11=square)
pub const SauceFlags = packed struct(u8) {
    /// Non-blink mode / iCE colors enabled
    /// When set, blink attribute repurposed for high-intensity backgrounds
    ice_colors: bool = false,

    /// Letter spacing mode (2 bits)
    /// 00 = 8-pixel font (default)
    /// 01 = 9-pixel font (select chars have 9th column)
    /// 10-11 = Reserved
    letter_spacing: u2 = 0,

    /// Aspect ratio selection (2 bits)
    /// 00 = No preference
    /// 01 = Legacy aspect (1.35x for DOS VGA)
    /// 10 = Stretch to fill
    /// 11 = Square pixels
    aspect_ratio: u2 = 0,

    /// Reserved bits (must be 0)
    _reserved: u3 = 0,

    /// Get letter spacing in pixels (8 or 9).
    pub fn getLetterSpacing(self: SauceFlags) u8 {
        return if (self.letter_spacing == 0) 8 else 9;
    }

    /// Get aspect ratio as float (or null if no preference).
    pub fn getAspectRatio(self: SauceFlags) ?f32 {
        return switch (self.aspect_ratio) {
            0 => null, // No preference
            1 => 1.35, // Legacy DOS aspect
            2 => null, // Stretch (renderer decides)
            3 => 1.0, // Square pixels
        };
    }
};

/// File type identifiers from SAUCE specification.
pub const FileType = enum(u8) {
    none = 0,
    character = 1, // ANSI, ASCII, etc.
    bitmap = 2,
    vector = 3,
    audio = 4,
    binary_text = 5,
    xbin = 6,
    archive = 7,
    executable = 8,
    _,
};

/// Data type for character-based files.
pub const CharacterDataType = enum(u8) {
    ascii = 0,
    ansi = 1,
    ansimation = 2,
    rip = 3,
    pcboard = 4,
    avatar = 5,
    html = 6,
    source = 7,
    tundra_draw = 8,
    _,
};

/// Complete SAUCE metadata record.
///
/// Preserves both raw 128-byte record and parsed fields.
/// All string fields are stored as owned slices (caller must deinit).
pub const SauceRecord = struct {
    // === Raw Record Preservation ===

    /// Raw 128-byte SAUCE record (lossless preservation)
    raw_bytes: [SAUCE_RECORD_SIZE]u8,

    // === Parsed Fields ===

    /// SAUCE version (typically "00")
    version: [2]u8,

    /// Title of the work (max 35 chars, null-padded)
    title: []u8,

    /// Author/creator name (max 20 chars, null-padded)
    author: []u8,

    /// Group/organization name (max 20 chars, null-padded)
    group: []u8,

    /// Date in CCYYMMDD format (max 8 chars)
    date: []u8,

    /// File size in bytes (excluding SAUCE)
    file_size: u32,

    /// File type identifier
    file_type: FileType,

    /// Data type (interpretation depends on file_type)
    data_type: u8,

    /// Type-specific info fields (meaning varies by file type)
    /// For ANSI: tinfo1 = character width, tinfo2 = lines
    tinfo1: u16,
    tinfo2: u16,
    tinfo3: u16,
    tinfo4: u16,

    /// Number of comment lines (max 255)
    comment_lines: u8,

    /// Flags byte (ANSiFlags for character art)
    flags: SauceFlags,

    /// Font name (max 22 chars, null-padded)
    font_name: []u8,

    // === Comments ===

    /// Optional comment lines (64 bytes each)
    comments: [][]u8,

    allocator: std.mem.Allocator,

    /// Parse SAUCE record from raw bytes at end of file.
    ///
    /// Expects data to contain at least 128 bytes starting at the SAUCE record.
    /// Does NOT include comment block; use parseComments() separately.
    pub fn parse(allocator: std.mem.Allocator, data: []const u8) errors.Error!SauceRecord {
        if (data.len < SAUCE_RECORD_SIZE) return error.InvalidSauce;

        // Verify SAUCE ID
        if (!std.mem.eql(u8, data[0..5], SAUCE_ID)) return error.InvalidSauce;

        var record: SauceRecord = undefined;
        record.allocator = allocator;

        // Preserve raw bytes
        @memcpy(&record.raw_bytes, data[0..SAUCE_RECORD_SIZE]);

        // Parse version
        record.version = data[5..7].*;

        // Parse strings (allocate and copy, trimming null padding)
        record.title = try allocAndTrim(allocator, data[7..42]);
        errdefer allocator.free(record.title);

        record.author = try allocAndTrim(allocator, data[42..62]);
        errdefer allocator.free(record.author);

        record.group = try allocAndTrim(allocator, data[62..82]);
        errdefer allocator.free(record.group);

        record.date = try allocAndTrim(allocator, data[82..90]);
        errdefer allocator.free(record.date);

        // Parse numeric fields (little-endian)
        record.file_size = std.mem.readInt(u32, data[90..94], .little);

        // Parse type fields
        record.file_type = @enumFromInt(data[94]);
        record.data_type = data[95];

        // Parse tinfo fields (little-endian u16)
        record.tinfo1 = std.mem.readInt(u16, data[96..98], .little);
        record.tinfo2 = std.mem.readInt(u16, data[98..100], .little);
        record.tinfo3 = std.mem.readInt(u16, data[100..102], .little);
        record.tinfo4 = std.mem.readInt(u16, data[102..104], .little);

        // Parse comment lines count
        record.comment_lines = data[104];

        // Parse flags
        record.flags = @bitCast(data[105]);

        // Parse font name
        record.font_name = try allocAndTrim(allocator, data[106..128]);

        // Initialize empty comments (caller must use parseComments separately)
        // Allocate empty slice so deinit() can safely call allocator.free()
        record.comments = try allocator.alloc([]u8, 0);

        return record;
    }

    /// Parse SAUCE comment block.
    ///
    /// Comment block appears BEFORE SAUCE record, consists of:
    /// - 5 bytes: "COMNT"
    /// - N × 64 bytes: comment lines (N = comment_lines from SAUCE)
    ///
    /// Call after parse() if comment_lines > 0.
    pub fn parseComments(self: *SauceRecord, data: []const u8) errors.Error!void {
        if (self.comment_lines == 0) return;

        const expected_size = 5 + (@as(usize, self.comment_lines) * SAUCE_COMMENT_LINE_SIZE);
        if (data.len < expected_size) return error.InvalidSauce;

        // Verify COMNT ID
        if (!std.mem.eql(u8, data[0..5], COMNT_ID)) return error.InvalidSauce;

        // Allocate comment array
        self.comments = try self.allocator.alloc([]u8, self.comment_lines);
        errdefer self.allocator.free(self.comments);

        // Parse each comment line
        var i: usize = 0;
        while (i < self.comment_lines) : (i += 1) {
            const offset = 5 + (i * SAUCE_COMMENT_LINE_SIZE);
            const line_data = data[offset .. offset + SAUCE_COMMENT_LINE_SIZE];
            self.comments[i] = try allocAndTrim(self.allocator, line_data);
        }
    }

    /// Free all allocated memory.
    pub fn deinit(self: *SauceRecord) void {
        self.allocator.free(self.title);
        self.allocator.free(self.author);
        self.allocator.free(self.group);
        self.allocator.free(self.date);
        self.allocator.free(self.font_name);

        for (self.comments) |comment| {
            self.allocator.free(comment);
        }
        if (self.comments.len > 0) {
            self.allocator.free(self.comments);
        }
    }

    /// Get column width for ANSI/character art.
    /// Returns tinfo1 for character-based files.
    pub fn getColumns(self: *const SauceRecord) ?u16 {
        if (self.file_type != .character) return null;
        return if (self.tinfo1 > 0) self.tinfo1 else null;
    }

    /// Get line count for ANSI/character art.
    /// Returns tinfo2 for character-based files.
    pub fn getLines(self: *const SauceRecord) ?u16 {
        if (self.file_type != .character) return null;
        return if (self.tinfo2 > 0) self.tinfo2 else null;
    }

    /// Check if this is an ANSI file.
    pub fn isANSI(self: *const SauceRecord) bool {
        return self.file_type == .character and
            (self.data_type == @intFromEnum(CharacterDataType.ansi) or
                self.data_type == @intFromEnum(CharacterDataType.ansimation));
    }

    /// Check if this is an ansimation (animated ANSI).
    pub fn isAnsimation(self: *const SauceRecord) bool {
        return self.file_type == .character and
            self.data_type == @intFromEnum(CharacterDataType.ansimation);
    }
};

/// Allocate and trim null/space padding from SAUCE string field.
fn allocAndTrim(allocator: std.mem.Allocator, data: []const u8) ![]u8 {
    // Trim trailing nulls and spaces
    var end = data.len;
    while (end > 0 and (data[end - 1] == 0 or data[end - 1] == ' ')) {
        end -= 1;
    }

    const trimmed = data[0..end];
    const result = try allocator.alloc(u8, trimmed.len);
    @memcpy(result, trimmed);
    return result;
}

/// Detect SAUCE record in file data.
///
/// Returns offset to SAUCE record if found, null otherwise.
/// Checks last 128 bytes for SAUCE ID.
pub fn detectSauce(data: []const u8) ?usize {
    if (data.len < SAUCE_RECORD_SIZE) return null;

    const sauce_offset = data.len - SAUCE_RECORD_SIZE;
    const candidate = data[sauce_offset..];

    if (std.mem.eql(u8, candidate[0..5], SAUCE_ID)) {
        return sauce_offset;
    }

    return null;
}

/// Detect SAUCE comments in file data.
///
/// Returns offset to comment block if found, null otherwise.
/// Must be called after detecting SAUCE record to know comment_lines count.
pub fn detectComments(data: []const u8, comment_lines: u8, sauce_offset: usize) ?usize {
    if (comment_lines == 0) return null;

    const comment_block_size = 5 + (@as(usize, comment_lines) * SAUCE_COMMENT_LINE_SIZE);
    if (sauce_offset < comment_block_size) return null;

    const comment_offset = sauce_offset - comment_block_size;
    const candidate = data[comment_offset..];

    if (std.mem.eql(u8, candidate[0..5], COMNT_ID)) {
        return comment_offset;
    }

    return null;
}

// === Tests ===

test "SauceFlags: encoding and decoding" {
    const flags = SauceFlags{
        .ice_colors = true,
        .letter_spacing = 1, // 9-pixel
        .aspect_ratio = 1, // Legacy
    };

    try std.testing.expect(flags.ice_colors);
    try std.testing.expectEqual(@as(u8, 9), flags.getLetterSpacing());
    try std.testing.expectEqual(@as(?f32, 1.35), flags.getAspectRatio());
}

test "SauceFlags: size constraint" {
    try std.testing.expectEqual(@as(usize, 1), @sizeOf(SauceFlags));
}

test "SAUCE detection: valid record" {
    const allocator = std.testing.allocator;

    // Create minimal valid SAUCE record
    var data: [SAUCE_RECORD_SIZE]u8 = undefined;
    @memset(&data, 0);
    @memcpy(data[0..5], SAUCE_ID);
    @memcpy(data[5..7], SAUCE_VERSION);

    const offset = detectSauce(&data);
    try std.testing.expectEqual(@as(?usize, 0), offset);

    var record = try SauceRecord.parse(allocator, &data);
    defer record.deinit();

    try std.testing.expectEqualStrings(SAUCE_VERSION, &record.version);
}

test "SAUCE: string field trimming" {
    const allocator = std.testing.allocator;

    const padded = "Test\x00\x00\x00  ";
    const trimmed = try allocAndTrim(allocator, padded);
    defer allocator.free(trimmed);

    try std.testing.expectEqualStrings("Test", trimmed);
}
