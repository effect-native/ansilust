//! Ansilust IR - Hyperlink Module
//!
//! Manages OSC 8 hyperlink metadata for terminal hyperlink support.
//! Cells reference hyperlinks by ID; this module maintains the lookup table.
//!
//! OSC 8 format: ESC ] 8 ; params ; URI ST
//! - params: semicolon-separated key=value pairs (e.g., "id=unique-id")
//! - URI: target URL or file path
//!
//! Implements RQ-Link-1, RQ-Link-2.
//!
//! Reference: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda

const std = @import("std");
const errors = @import("errors.zig");

/// Hyperlink definition from OSC 8 sequence.
///
/// Stores URI target and optional parameters.
/// Multiple cells may reference the same hyperlink via its ID.
pub const Hyperlink = struct {
    /// Unique hyperlink ID (document-scoped)
    id: u32,

    /// Target URI (owned slice)
    uri: []const u8,

    /// Optional parameters from OSC 8 (owned slice)
    /// Format: "key1=value1;key2=value2"
    params: ?[]const u8,

    allocator: std.mem.Allocator,

    /// Create hyperlink with URI and optional parameters.
    pub fn init(allocator: std.mem.Allocator, id: u32, uri: []const u8, params: ?[]const u8) !Hyperlink {
        const uri_copy = try allocator.dupe(u8, uri);
        errdefer allocator.free(uri_copy);

        const params_copy = if (params) |p|
            try allocator.dupe(u8, p)
        else
            null;

        return Hyperlink{
            .id = id,
            .uri = uri_copy,
            .params = params_copy,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Hyperlink) void {
        self.allocator.free(self.uri);
        if (self.params) |p| {
            self.allocator.free(p);
        }
    }

    /// Parse parameter string into key-value pairs.
    ///
    /// Returns iterator over "key=value" pairs.
    pub fn parseParams(self: *const Hyperlink) ?ParamIterator {
        const params_str = self.params orelse return null;
        return ParamIterator{
            .remaining = params_str,
        };
    }

    /// Check if hyperlink has specific parameter.
    pub fn hasParam(self: *const Hyperlink, key: []const u8) bool {
        var iter = self.parseParams() orelse return false;
        while (iter.next()) |param| {
            if (std.mem.eql(u8, param.key, key)) return true;
        }
        return false;
    }

    /// Get value for specific parameter key.
    pub fn getParam(self: *const Hyperlink, key: []const u8) ?[]const u8 {
        var iter = self.parseParams() orelse return null;
        while (iter.next()) |param| {
            if (std.mem.eql(u8, param.key, key)) return param.value;
        }
        return null;
    }
};

/// Iterator over hyperlink parameters.
pub const ParamIterator = struct {
    remaining: []const u8,

    pub fn next(self: *ParamIterator) ?struct { key: []const u8, value: []const u8 } {
        if (self.remaining.len == 0) return null;

        // Find next semicolon
        const semicolon_idx = std.mem.indexOfScalar(u8, self.remaining, ';');
        const param_str = if (semicolon_idx) |idx|
            self.remaining[0..idx]
        else
            self.remaining;

        // Advance remaining
        if (semicolon_idx) |idx| {
            self.remaining = if (idx + 1 < self.remaining.len)
                self.remaining[idx + 1 ..]
            else
                "";
        } else {
            self.remaining = "";
        }

        // Parse key=value
        const equals_idx = std.mem.indexOfScalar(u8, param_str, '=') orelse return null;
        const key = param_str[0..equals_idx];
        const value = param_str[equals_idx + 1 ..];

        return .{ .key = key, .value = value };
    }
};

/// Hyperlink table managing document-level hyperlink registry.
///
/// Provides hyperlink ID allocation, deduplication, and lookup.
pub const HyperlinkTable = struct {
    allocator: std.mem.Allocator,
    hyperlinks: std.ArrayList(Hyperlink),
    next_id: u32,

    pub fn init(allocator: std.mem.Allocator) HyperlinkTable {
        return HyperlinkTable{
            .allocator = allocator,
            .hyperlinks = std.ArrayList(Hyperlink).empty,
            .next_id = 1, // ID 0 reserved for "no hyperlink"
        };
    }

    pub fn deinit(self: *HyperlinkTable) void {
        for (self.hyperlinks.items) |*link| {
            link.deinit();
        }
        self.hyperlinks.deinit(self.allocator);
    }

    /// Add hyperlink to table with auto-assigned ID.
    ///
    /// Deduplicates identical URI+params combinations.
    pub fn add(self: *HyperlinkTable, uri: []const u8, params: ?[]const u8) !u32 {
        // Check for existing match (deduplicate)
        for (self.hyperlinks.items) |*existing| {
            if (!std.mem.eql(u8, existing.uri, uri)) continue;

            const params_match = blk: {
                if (existing.params == null and params == null) break :blk true;
                if (existing.params == null or params == null) break :blk false;
                break :blk std.mem.eql(u8, existing.params.?, params.?);
            };

            if (params_match) return existing.id;
        }

        // Create new hyperlink
        const id = self.next_id;
        self.next_id += 1;

        var link = try Hyperlink.init(self.allocator, id, uri, params);
        errdefer link.deinit();

        try self.hyperlinks.append(self.allocator, link);
        return id;
    }

    /// Add hyperlink with explicit ID (for deserialization).
    ///
    /// Returns error if ID already exists.
    pub fn addWithId(self: *HyperlinkTable, id: u32, uri: []const u8, params: ?[]const u8) !void {
        // Check for duplicate ID
        for (self.hyperlinks.items) |*existing| {
            if (existing.id == id) return error.DuplicateHyperlinkId;
        }

        var link = try Hyperlink.init(self.allocator, id, uri, params);
        errdefer link.deinit();

        try self.hyperlinks.append(self.allocator, link);

        // Update next_id if needed
        if (id >= self.next_id) {
            self.next_id = id + 1;
        }
    }

    /// Get hyperlink by ID.
    pub fn get(self: *const HyperlinkTable, id: u32) ?*const Hyperlink {
        for (self.hyperlinks.items) |*link| {
            if (link.id == id) return link;
        }
        return null;
    }

    /// Get hyperlink count.
    pub fn count(self: *const HyperlinkTable) usize {
        return self.hyperlinks.items.len;
    }

    /// Remove hyperlink by ID.
    pub fn remove(self: *HyperlinkTable, id: u32) bool {
        for (self.hyperlinks.items, 0..) |*link, i| {
            if (link.id == id) {
                link.deinit();
                _ = self.hyperlinks.orderedRemove(i);
                return true;
            }
        }
        return false;
    }
};

// === Tests ===

test "Hyperlink: creation and cleanup" {
    const allocator = std.testing.allocator;

    var link = try Hyperlink.init(allocator, 1, "https://example.com", "id=test");
    defer link.deinit();

    try std.testing.expectEqual(@as(u32, 1), link.id);
    try std.testing.expectEqualStrings("https://example.com", link.uri);
    try std.testing.expect(link.params != null);
}

test "Hyperlink: parameter parsing" {
    const allocator = std.testing.allocator;

    var link = try Hyperlink.init(allocator, 1, "https://example.com", "id=test;foo=bar");
    defer link.deinit();

    try std.testing.expect(link.hasParam("id"));
    try std.testing.expect(link.hasParam("foo"));
    try std.testing.expect(!link.hasParam("missing"));

    const id_value = link.getParam("id");
    try std.testing.expect(id_value != null);
    try std.testing.expectEqualStrings("test", id_value.?);
}

test "HyperlinkTable: add and retrieve" {
    const allocator = std.testing.allocator;

    var table = HyperlinkTable.init(allocator);
    defer table.deinit();

    const id1 = try table.add("https://example.com", null);
    const id2 = try table.add("https://other.com", "id=foo");

    try std.testing.expectEqual(@as(usize, 2), table.count());

    const link1 = table.get(id1);
    try std.testing.expect(link1 != null);
    try std.testing.expectEqualStrings("https://example.com", link1.?.uri);

    const link2 = table.get(id2);
    try std.testing.expect(link2 != null);
    try std.testing.expectEqualStrings("https://other.com", link2.?.uri);
}

test "HyperlinkTable: deduplication" {
    const allocator = std.testing.allocator;

    var table = HyperlinkTable.init(allocator);
    defer table.deinit();

    const id1 = try table.add("https://example.com", "id=test");
    const id2 = try table.add("https://example.com", "id=test"); // Duplicate

    try std.testing.expectEqual(id1, id2);
    try std.testing.expectEqual(@as(usize, 1), table.count());
}

test "HyperlinkTable: duplicate ID rejection" {
    const allocator = std.testing.allocator;

    var table = HyperlinkTable.init(allocator);
    defer table.deinit();

    try table.addWithId(5, "https://example.com", null);
    try std.testing.expectError(
        error.DuplicateHyperlinkId,
        table.addWithId(5, "https://other.com", null),
    );
}

test "HyperlinkTable: remove" {
    const allocator = std.testing.allocator;

    var table = HyperlinkTable.init(allocator);
    defer table.deinit();

    const id = try table.add("https://example.com", null);
    try std.testing.expectEqual(@as(usize, 1), table.count());

    try std.testing.expect(table.remove(id));
    try std.testing.expectEqual(@as(usize, 0), table.count());
    try std.testing.expect(!table.remove(id)); // Already removed
}
