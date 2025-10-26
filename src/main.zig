const std = @import("std");
const ansilust = @import("ansilust");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Demo: Create a simple IR
    var ir = try ansilust.AnsilustIR.init(allocator, 80, 25);
    defer ir.deinit();

    std.debug.print("Ansilust IR initialized: {}x{} cells\n", .{ ir.width, ir.height });
    std.debug.print("Next step: Implement parsers and renderers\n", .{});
}
