//! Ansilust IR - Source Encoding Module
//!
//! Defines character encoding identifiers for raw source bytes.
//! Uses IANA MIBenum values where available, with a documented vendor
//! range (65024-65535) for text-art specific encodings.
//!
//! See: https://www.iana.org/assignments/character-sets/character-sets.xhtml

const std = @import("std");
const errors = @import("errors.zig");

/// Source encoding identifier using IANA MIBenum values.
///
/// Value 0 is reserved for Unknown encoding.
/// Values 1-999 are IANA-registered.
/// Values 65024-65535 are vendor-specific (text-art formats).
///
/// Parsers MUST preserve raw bytes even when encoding is known,
/// to support lossless round-trips (RQ-Encoding-3).
pub const SourceEncoding = enum(u16) {
    /// Unknown or unspecified encoding (default/fallback)
    unknown = 0,

    // === IANA Registered Encodings (Common in Text Art) ===

    /// US-ASCII (ANSI X3.4-1968) - IANA MIBenum 3
    us_ascii = 3,

    /// ISO-8859-1 (Latin-1) - IANA MIBenum 4
    /// Common in early BBS systems and European text art
    iso_8859_1 = 4,

    /// ISO-8859-2 (Latin-2, Central European) - IANA MIBenum 5
    iso_8859_2 = 5,

    /// ISO-8859-15 (Latin-9, Western European with Euro) - IANA MIBenum 111
    iso_8859_15 = 111,

    /// UTF-8 - IANA MIBenum 106
    /// Modern terminal art, ansimations, contemporary ANSI
    utf_8 = 106,

    /// UTF-16BE (Big Endian) - IANA MIBenum 1013
    utf_16be = 1013,

    /// UTF-16LE (Little Endian) - IANA MIBenum 1014
    utf_16le = 1014,

    /// UTF-32BE - IANA MIBenum 1018
    utf_32be = 1018,

    /// UTF-32LE - IANA MIBenum 1019
    utf_32le = 1019,

    /// IBM Code Page 437 (DOS, PC-8) - IANA MIBenum 2011
    /// THE classic BBS encoding - box drawing, extended ASCII art
    cp437 = 2011,

    /// IBM Code Page 850 (DOS Latin-1) - IANA MIBenum 2009
    /// Western European DOS systems
    cp850 = 2009,

    /// IBM Code Page 852 (DOS Latin-2) - IANA MIBenum 2010
    /// Central/Eastern European DOS systems
    cp852 = 2010,

    /// IBM Code Page 866 (DOS Cyrillic) - IANA MIBenum 2086
    /// Russian/Cyrillic BBS art
    cp866 = 2086,

    /// Windows-1252 (CP1252, Western European) - IANA MIBenum 2252
    windows_1252 = 2252,

    /// KOI8-R (Russian Cyrillic) - IANA MIBenum 2084
    koi8_r = 2084,

    // === Vendor Range: Text-Art Specific (65024-65535) ===

    /// PETSCII (Commodore 64/128) - No IANA assignment
    /// Vendor range base: 65024
    petscii = 65024,

    /// ATASCII (Atari 8-bit computers) - No IANA assignment
    atascii = 65025,

    /// Amiga Topaz font encoding (CP437 variant) - No IANA assignment
    amiga_topaz = 65026,

    /// Teletext/Viewdata (UK Prestel, French Minitel) - No IANA assignment
    teletext = 65027,

    /// Apple II character set - No IANA assignment
    apple_ii = 65028,

    /// TRS-80 Model I/III character set - No IANA assignment
    trs80 = 65029,

    _,

    /// Returns the IANA MIBenum value or vendor-assigned ID.
    pub fn toMIBenum(self: SourceEncoding) u16 {
        return @intFromEnum(self);
    }

    /// Constructs SourceEncoding from raw MIBenum value.
    ///
    /// Returns error.InvalidEncoding for reserved ranges or invalid values.
    pub fn fromMIBenum(mib: u16) errors.Error!SourceEncoding {
        // Validate range
        if (mib >= 1000 and mib < 2000 and mib != 1013 and mib != 1014 and mib != 1018 and mib != 1019) {
            // Reserved IANA range not explicitly supported
            return error.InvalidEncoding;
        }

        return @enumFromInt(mib);
    }

    /// Returns human-readable name for the encoding.
    pub fn name(self: SourceEncoding) []const u8 {
        return switch (self) {
            .unknown => "Unknown",
            .us_ascii => "US-ASCII",
            .iso_8859_1 => "ISO-8859-1",
            .iso_8859_2 => "ISO-8859-2",
            .iso_8859_15 => "ISO-8859-15",
            .utf_8 => "UTF-8",
            .utf_16be => "UTF-16BE",
            .utf_16le => "UTF-16LE",
            .utf_32be => "UTF-32BE",
            .utf_32le => "UTF-32LE",
            .cp437 => "IBM CP437",
            .cp850 => "IBM CP850",
            .cp852 => "IBM CP852",
            .cp866 => "IBM CP866",
            .windows_1252 => "Windows-1252",
            .koi8_r => "KOI8-R",
            .petscii => "PETSCII",
            .atascii => "ATASCII",
            .amiga_topaz => "Amiga Topaz",
            .teletext => "Teletext",
            .apple_ii => "Apple II",
            .trs80 => "TRS-80",
            _ => "Unknown",
        };
    }

    /// Returns true if encoding is in the vendor-specific range (65024-65535).
    pub fn isVendor(self: SourceEncoding) bool {
        const val = @intFromEnum(self);
        return val >= 65024 and val <= 65535;
    }

    /// Returns true if encoding is IANA-registered.
    pub fn isIANA(self: SourceEncoding) bool {
        const val = @intFromEnum(self);
        return val > 0 and val < 65024;
    }

    /// Returns true if encoding uses single-byte character set.
    pub fn isSingleByte(self: SourceEncoding) bool {
        return switch (self) {
            .us_ascii,
            .iso_8859_1,
            .iso_8859_2,
            .iso_8859_15,
            .cp437,
            .cp850,
            .cp852,
            .cp866,
            .windows_1252,
            .koi8_r,
            .petscii,
            .atascii,
            .amiga_topaz,
            .apple_ii,
            .trs80,
            => true,

            .utf_8,
            .utf_16be,
            .utf_16le,
            .utf_32be,
            .utf_32le,
            .teletext,
            .unknown,
            => false,

            _ => false,
        };
    }

    /// Returns maximum bytes per character for this encoding.
    pub fn maxBytesPerChar(self: SourceEncoding) u8 {
        return switch (self) {
            // Single-byte encodings
            .us_ascii,
            .iso_8859_1,
            .iso_8859_2,
            .iso_8859_15,
            .cp437,
            .cp850,
            .cp852,
            .cp866,
            .windows_1252,
            .koi8_r,
            .petscii,
            .atascii,
            .amiga_topaz,
            .apple_ii,
            .trs80,
            => 1,

            // UTF-8: up to 4 bytes per codepoint
            .utf_8 => 4,

            // UTF-16: 2 or 4 bytes (surrogate pairs)
            .utf_16be, .utf_16le => 4,

            // UTF-32: always 4 bytes
            .utf_32be, .utf_32le => 4,

            // Teletext uses escape sequences
            .teletext => 8,

            .unknown => 4,
            _ => 4,
        };
    }
};

/// Lookup encoding by name (case-insensitive).
///
/// Returns error.InvalidEncoding if name not recognized.
pub fn fromName(comptime_name: []const u8) errors.Error!SourceEncoding {
    const name_upper = comptime blk: {
        var buf: [64]u8 = undefined;
        const len = @min(comptime_name.len, 64);
        for (comptime_name[0..len], 0..) |c, i| {
            buf[i] = std.ascii.toLower(c);
        }
        break :blk buf[0..len];
    };

    inline for (@typeInfo(SourceEncoding).Enum.fields) |field| {
        const field_lower = comptime blk: {
            var buf: [64]u8 = undefined;
            const field_name = field.name;
            for (field_name, 0..) |c, i| {
                buf[i] = if (c == '_') '-' else c;
            }
            break :blk buf[0..field_name.len];
        };

        if (std.mem.eql(u8, name_upper, field_lower)) {
            return @enumFromInt(field.value);
        }
    }

    return error.InvalidEncoding;
}

// === Tests ===

test "SourceEncoding: MIBenum round-trip" {
    const enc = SourceEncoding.cp437;
    try std.testing.expectEqual(@as(u16, 2011), enc.toMIBenum());

    const roundtrip = try SourceEncoding.fromMIBenum(2011);
    try std.testing.expectEqual(SourceEncoding.cp437, roundtrip);
}

test "SourceEncoding: vendor range detection" {
    try std.testing.expect(SourceEncoding.petscii.isVendor());
    try std.testing.expect(!SourceEncoding.cp437.isIANA() == false);
    try std.testing.expect(SourceEncoding.cp437.isIANA());
}

test "SourceEncoding: name lookup" {
    try std.testing.expectEqualStrings("IBM CP437", SourceEncoding.cp437.name());
    try std.testing.expectEqualStrings("UTF-8", SourceEncoding.utf_8.name());
    try std.testing.expectEqualStrings("PETSCII", SourceEncoding.petscii.name());
}

test "SourceEncoding: single-byte detection" {
    try std.testing.expect(SourceEncoding.cp437.isSingleByte());
    try std.testing.expect(SourceEncoding.iso_8859_1.isSingleByte());
    try std.testing.expect(!SourceEncoding.utf_8.isSingleByte());
    try std.testing.expect(!SourceEncoding.utf_16le.isSingleByte());
}

test "SourceEncoding: max bytes per char" {
    try std.testing.expectEqual(@as(u8, 1), SourceEncoding.cp437.maxBytesPerChar());
    try std.testing.expectEqual(@as(u8, 4), SourceEncoding.utf_8.maxBytesPerChar());
    try std.testing.expectEqual(@as(u8, 4), SourceEncoding.utf_16be.maxBytesPerChar());
    try std.testing.expectEqual(@as(u8, 4), SourceEncoding.utf_32le.maxBytesPerChar());
}
