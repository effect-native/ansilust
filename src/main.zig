const std = @import("std");
const ansilust = @import("ansilust");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Demo: Create a simple IR
    var doc = try ansilust.Document.init(allocator, 80, 25);
    defer doc.deinit();

    const dims = doc.getDimensions();
    std.debug.print("Ansilust Document initialized: {}x{}\n", .{ dims.width, dims.height });
    std.debug.print("Cell count: {}\n", .{dims.width * dims.height});
    std.debug.print("Next step: Implement parsers and renderers\n", .{});
}
