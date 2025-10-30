const std = @import("std");
const ir = @import("../ir/lib.zig");
const ansi = @import("ansi.zig");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

fn initDocument() !ir.Document {
    return try ir.Document.init(std.testing.allocator, 80, 25);
}

test "ansi: plain text rendering writes sequential characters" {
    var doc = try initDocument();
    defer doc.deinit();

    var parser = ansi.Parser.init(std.testing.allocator, "Hello, World!", &doc);
    defer parser.deinit();
    try parser.parse();

    try expectEqual(@as(u32, 80), doc.grid.width);
    try expectEqual(@as(u32, 25), doc.grid.height);

    try expectEqual(@as(u21, 'H'), (try doc.getCell(0, 0)).contents.scalar);
    try expectEqual(@as(u21, 'W'), (try doc.getCell(7, 0)).contents.scalar);
    try expectEqual(@as(u21, '!'), (try doc.getCell(12, 0)).contents.scalar);
}
