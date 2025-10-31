const std = @import("std");
const ansi = @import("parsers/ansi.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read test file
    const file_content = try std.fs.cwd().readFileAlloc(allocator, "test_16colors.ans", 10000);
    defer allocator.free(file_content);

    // Parse to IR
    var doc = try ansi.parse(allocator, file_content);
    defer doc.deinit();

    const dims = doc.getDimensions();
    std.debug.print("Document: {}x{}\n", .{ dims.width, dims.height });

    // Print first two rows with their colors
    var y: u32 = 0;
    while (y < 2) : (y += 1) {
        std.debug.print("\nRow {}:\n", .{y});
        var x: u32 = 0;
        while (x < 80) : (x += 1) {
            const cell = try doc.getCell(x, y);
            if (cell.contents.scalar != ' ') {
                std.debug.print("  [{d}] '{u}' fg=", .{ x, cell.contents.scalar });
                switch (cell.fg_color) {
                    .palette => |idx| std.debug.print("palette({d})", .{idx}),
                    .rgb => |rgb| std.debug.print("rgb({d},{d},{d})", .{ rgb.r, rgb.g, rgb.b }),
                    .none => std.debug.print("none", .{}),
                }
                std.debug.print(" bg=", .{});
                switch (cell.bg_color) {
                    .palette => |idx| std.debug.print("palette({d})\n", .{idx}),
                    .rgb => |rgb| std.debug.print("rgb({d},{d},{d})\n", .{ rgb.r, rgb.g, rgb.b }),
                    .none => std.debug.print("none\n", .{}),
                }
            }
        }
    }
}
