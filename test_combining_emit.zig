const std = @import("std");

pub fn main() !void {
    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = bw.writer();
    
    try stdout.writeAll("Testing combining characters from Zig:\n\n");
    
    // Emit ᵃ (U+1D43) + combining underline (U+0332)
    var buf1: [4]u8 = undefined;
    const len1 = try std.unicode.utf8Encode(0x1D43, &buf1);
    
    var buf2: [4]u8 = undefined;
    const len2 = try std.unicode.utf8Encode(0x0332, &buf2);
    
    try stdout.writeAll("In context: ╚");
    try stdout.writeAll(buf1[0..len1]);
    try stdout.writeAll(buf2[0..len2]);
    try stdout.writeAll("\"`˜\n\n");
    
    try stdout.writeAll("✓ Works! ᵃ̲\n");
    
    try bw.flush();
}
