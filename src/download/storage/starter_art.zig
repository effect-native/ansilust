//! Repo-owned starter artwork provisioning for first use.

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const StarterArtwork = struct {
    filename: []const u8,
    data: []const u8,
};

const starter_pool = [_]StarterArtwork{
    .{
        .filename = "ansilust-starter.ans",
        .data = @embedFile("starter_art/ansilust-starter.ans"),
    },
};

pub fn materializeLocalStarterPool(allocator: Allocator, local_dir: []const u8) !usize {
    var written_count: usize = 0;

    for (starter_pool) |artwork| {
        if (try writeFileIfMissing(allocator, local_dir, artwork)) {
            written_count += 1;
        }
    }

    return written_count;
}

fn writeFileIfMissing(allocator: Allocator, local_dir: []const u8, artwork: StarterArtwork) !bool {
    const dest_path = try std.fs.path.join(allocator, &.{ local_dir, artwork.filename });
    defer allocator.free(dest_path);

    const file = std.fs.createFileAbsolute(dest_path, .{ .exclusive = true }) catch |err| switch (err) {
        error.PathAlreadyExists => return false,
        else => return err,
    };
    defer file.close();

    try file.writeAll(artwork.data);
    return true;
}

test "starter art materializes repo-owned ANSI into local pool" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makePath("local");

    const allocator = std.testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const local_dir = try std.fs.path.join(allocator, &.{ root, "local" });
    defer allocator.free(local_dir);

    const written_count = try materializeLocalStarterPool(allocator, local_dir);
    try std.testing.expectEqual(@as(usize, 1), written_count);

    const starter_path = try std.fs.path.join(allocator, &.{ local_dir, starter_pool[0].filename });
    defer allocator.free(starter_path);

    const file = try std.fs.openFileAbsolute(starter_path, .{});
    defer file.close();

    const contents = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(contents);

    try std.testing.expectEqualStrings(starter_pool[0].data, contents);
}

test "starter art materialization is idempotent" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.makePath("local");

    const allocator = std.testing.allocator;
    const root = try tmp.dir.realpathAlloc(allocator, ".");
    defer allocator.free(root);

    const local_dir = try std.fs.path.join(allocator, &.{ root, "local" });
    defer allocator.free(local_dir);

    try std.testing.expectEqual(@as(usize, 1), try materializeLocalStarterPool(allocator, local_dir));
    try std.testing.expectEqual(@as(usize, 0), try materializeLocalStarterPool(allocator, local_dir));
}
