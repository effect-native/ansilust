//! Ansilust IR - Animation Module
//!
//! Supports frame-based animations (ansimations) with snapshot and delta frames.
//! Implements copy-on-write strategy for memory efficiency.
//!
//! Frame types:
//! - Snapshot: Complete cell grid state (first frame, keyframes)
//! - Delta: Coordinate-based updates relative to previous frame
//!
//! Implements RQ-Anim-1, RQ-Anim-2, RQ-Anim-3, RQ-Anim-4, RQ-Anim-5.

const std = @import("std");
const errors = @import("errors.zig");
const cell_grid = @import("cell_grid.zig");

/// Animation frame discriminated union.
///
/// Frames can either store a complete grid snapshot (keyframe)
/// or a delta list of cell updates relative to the previous frame.
pub const Frame = union(enum) {
    /// Complete cell grid snapshot
    snapshot: Snapshot,

    /// Delta updates relative to previous frame
    delta: Delta,

    pub fn deinit(self: *Frame, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .snapshot => |*snap| snap.deinit(),
            .delta => |*dlt| dlt.deinit(allocator),
        }
    }
};

/// Complete grid snapshot frame.
///
/// Used for first frame and periodic keyframes to limit error propagation.
/// Stores full cell grid state.
pub const Snapshot = struct {
    /// Complete cell grid
    grid: cell_grid.CellGrid,

    /// Frame timing (milliseconds)
    duration: u32,

    /// Optional delay before this frame (milliseconds)
    delay: u32,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, duration: u32) !Snapshot {
        return Snapshot{
            .grid = try cell_grid.CellGrid.init(allocator, width, height),
            .duration = duration,
            .delay = 0,
        };
    }

    pub fn deinit(self: *Snapshot) void {
        self.grid.deinit();
    }
};

/// Delta frame with coordinate-based cell updates.
///
/// Stores only changed cells relative to previous frame.
/// More memory-efficient than snapshots for incremental changes.
pub const Delta = struct {
    /// List of cell updates (coordinate + new state)
    updates: std.ArrayList(CellUpdate),

    /// Frame timing (milliseconds)
    duration: u32,

    /// Optional delay before this frame (milliseconds)
    delay: u32,

    /// Allocator for updates list
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, duration: u32) Delta {
        return Delta{
            .updates = std.ArrayList(CellUpdate).empty,
            .duration = duration,
            .delay = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Delta, allocator: std.mem.Allocator) void {
        _ = allocator; // Use self.allocator instead
        self.updates.deinit(self.allocator);
    }

    /// Add cell update to delta.
    pub fn addUpdate(self: *Delta, update: CellUpdate) !void {
        try self.updates.append(self.allocator, update);
    }

    /// Apply delta to target grid.
    ///
    /// Modifies grid in-place with all delta updates.
    pub fn apply(self: *const Delta, grid: *cell_grid.CellGrid) !void {
        for (self.updates.items) |update| {
            try grid.setCell(update.x, update.y, update.input);
        }
    }
};

/// Single cell update in a delta frame.
pub const CellUpdate = struct {
    /// Cell X coordinate
    x: u32,

    /// Cell Y coordinate
    y: u32,

    /// New cell state (partial update via CellInput)
    input: cell_grid.CellInput,
};

/// Loop mode for animation playback.
pub const LoopMode = enum {
    /// Play once and stop on last frame
    once,

    /// Loop infinitely
    infinite,

    /// Loop N times then stop
    count,

    /// Ping-pong (forward then reverse)
    pingpong,
};

/// Complete animation sequence.
///
/// Contains ordered list of frames plus global metadata.
/// First frame MUST be a snapshot; subsequent frames may be snapshots or deltas.
pub const Animation = struct {
    allocator: std.mem.Allocator,

    /// Ordered list of animation frames
    frames: std.ArrayList(Frame),

    /// Base grid dimensions (all frames must match)
    width: u32,
    height: u32,

    /// Loop mode
    loop_mode: LoopMode,

    /// Loop count (if loop_mode == .count)
    loop_count: u32,

    /// Animation metadata
    metadata: AnimationMetadata,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) Animation {
        return Animation{
            .allocator = allocator,
            .frames = std.ArrayList(Frame).empty,
            .width = width,
            .height = height,
            .loop_mode = .once,
            .loop_count = 0,
            .metadata = AnimationMetadata{},
        };
    }

    pub fn deinit(self: *Animation) void {
        for (self.frames.items) |*frame| {
            frame.deinit(self.allocator);
        }
        self.frames.deinit(self.allocator);
    }

    /// Add frame to animation sequence.
    ///
    /// First frame MUST be a snapshot. Returns error if constraints violated.
    pub fn addFrame(self: *Animation, frame: Frame) !void {
        // First frame must be snapshot
        if (self.frames.items.len == 0) {
            if (frame != .snapshot) {
                return error.UnsupportedAnimation;
            }
        }

        try self.frames.append(self.allocator, frame);
    }

    /// Get total animation duration (milliseconds).
    pub fn getTotalDuration(self: *const Animation) u64 {
        var total: u64 = 0;
        for (self.frames.items) |*frame| {
            const duration = switch (frame.*) {
                .snapshot => |snap| snap.duration + snap.delay,
                .delta => |dlt| dlt.duration + dlt.delay,
            };
            total += duration;
        }
        return total;
    }

    /// Get frame count.
    pub fn getFrameCount(self: *const Animation) usize {
        return self.frames.items.len;
    }

    /// Decode frame at index into a complete grid.
    ///
    /// For snapshots: returns grid directly.
    /// For deltas: applies delta chain from last snapshot.
    pub fn decodeFrame(self: *const Animation, frame_index: usize, allocator: std.mem.Allocator) !cell_grid.CellGrid {
        if (frame_index >= self.frames.items.len) {
            return error.InvalidCoordinate; // Reusing error type
        }

        // Find last snapshot before this frame
        var snapshot_idx: usize = frame_index;
        while (snapshot_idx > 0) : (snapshot_idx -= 1) {
            if (self.frames.items[snapshot_idx] == .snapshot) break;
        }

        const base_snapshot = &self.frames.items[snapshot_idx].snapshot;

        // If requesting snapshot frame directly, clone it
        if (frame_index == snapshot_idx) {
            var grid = try cell_grid.CellGrid.init(allocator, self.width, self.height);
            errdefer grid.deinit();

            // Copy snapshot data
            @memcpy(grid.contents, base_snapshot.grid.contents);
            @memcpy(grid.fg_color, base_snapshot.grid.fg_color);
            @memcpy(grid.bg_color, base_snapshot.grid.bg_color);
            @memcpy(grid.attr_flags, base_snapshot.grid.attr_flags);
            @memcpy(grid.wide_flags, base_snapshot.grid.wide_flags);
            @memcpy(grid.hyperlink_id, base_snapshot.grid.hyperlink_id);
            @memcpy(grid.source_offset, base_snapshot.grid.source_offset);
            @memcpy(grid.source_len, base_snapshot.grid.source_len);
            @memcpy(grid.source_encoding, base_snapshot.grid.source_encoding);

            return grid;
        }

        // Clone snapshot and apply deltas
        var grid = try cell_grid.CellGrid.init(allocator, self.width, self.height);
        errdefer grid.deinit();

        // Copy base snapshot
        @memcpy(grid.contents, base_snapshot.grid.contents);
        @memcpy(grid.fg_color, base_snapshot.grid.fg_color);
        @memcpy(grid.bg_color, base_snapshot.grid.bg_color);
        @memcpy(grid.attr_flags, base_snapshot.grid.attr_flags);
        @memcpy(grid.wide_flags, base_snapshot.grid.wide_flags);
        @memcpy(grid.hyperlink_id, base_snapshot.grid.hyperlink_id);
        @memcpy(grid.source_offset, base_snapshot.grid.source_offset);
        @memcpy(grid.source_len, base_snapshot.grid.source_len);
        @memcpy(grid.source_encoding, base_snapshot.grid.source_encoding);

        // Apply deltas in sequence
        var i = snapshot_idx + 1;
        while (i <= frame_index) : (i += 1) {
            const frame = &self.frames.items[i];
            if (frame.* == .delta) {
                try frame.delta.apply(&grid);
            } else {
                // Hit another snapshot, use it as base instead
                const new_snapshot = &frame.snapshot;
                @memcpy(grid.contents, new_snapshot.grid.contents);
                @memcpy(grid.fg_color, new_snapshot.grid.fg_color);
                @memcpy(grid.bg_color, new_snapshot.grid.bg_color);
                @memcpy(grid.attr_flags, new_snapshot.grid.attr_flags);
                @memcpy(grid.wide_flags, new_snapshot.grid.wide_flags);
                @memcpy(grid.hyperlink_id, new_snapshot.grid.hyperlink_id);
                @memcpy(grid.source_offset, new_snapshot.grid.source_offset);
                @memcpy(grid.source_len, new_snapshot.grid.source_len);
                @memcpy(grid.source_encoding, new_snapshot.grid.source_encoding);
            }
        }

        return grid;
    }
};

/// Animation metadata (optional descriptive fields).
pub const AnimationMetadata = struct {
    /// Optional title
    title: ?[]const u8 = null,

    /// Optional author
    author: ?[]const u8 = null,

    /// Optional description
    description: ?[]const u8 = null,

    /// Frame rate hint (frames per second)
    fps_hint: ?f32 = null,
};

// === Tests ===

test "Animation: snapshot frame creation" {
    const allocator = std.testing.allocator;

    var snapshot = try Snapshot.init(allocator, 80, 25, 100);
    defer snapshot.deinit();

    try std.testing.expectEqual(@as(u32, 80), snapshot.grid.width);
    try std.testing.expectEqual(@as(u32, 25), snapshot.grid.height);
    try std.testing.expectEqual(@as(u32, 100), snapshot.duration);
}

test "Animation: delta frame creation and apply" {
    const allocator = std.testing.allocator;

    var delta = Delta.init(allocator, 50);
    defer delta.deinit(allocator);

    // Add update
    const update = CellUpdate{
        .x = 5,
        .y = 5,
        .input = cell_grid.CellInput{
            .contents = cell_grid.CellContents{ .scalar = 'X' },
        },
    };
    try delta.addUpdate(update);

    // Apply to grid
    var grid = try cell_grid.CellGrid.init(allocator, 80, 25);
    defer grid.deinit();

    try delta.apply(&grid);

    const cell = try grid.getCell(5, 5);
    try std.testing.expectEqual(@as(u21, 'X'), cell.contents.scalar);
}

test "Animation: sequence with snapshot and deltas" {
    const allocator = std.testing.allocator;

    var anim = Animation.init(allocator, 80, 25);
    defer anim.deinit();

    // Add initial snapshot
    const snapshot = try Snapshot.init(allocator, 80, 25, 100);
    try anim.addFrame(Frame{ .snapshot = snapshot });

    // Add delta
    var delta = Delta.init(allocator, 50);
    const update = CellUpdate{
        .x = 10,
        .y = 10,
        .input = cell_grid.CellInput{
            .contents = cell_grid.CellContents{ .scalar = 'A' },
        },
    };
    try delta.addUpdate(update);
    try anim.addFrame(Frame{ .delta = delta });

    try std.testing.expectEqual(@as(usize, 2), anim.getFrameCount());
    try std.testing.expectEqual(@as(u64, 150), anim.getTotalDuration());
}

test "Animation: first frame must be snapshot" {
    const allocator = std.testing.allocator;

    var anim = Animation.init(allocator, 80, 25);
    defer anim.deinit();

    // Attempting to add delta as first frame should fail
    const delta = Delta.init(allocator, 50);
    const frame = Frame{ .delta = delta };

    try std.testing.expectError(error.UnsupportedAnimation, anim.addFrame(frame));

    // Clean up the rejected frame
    var rejected = frame;
    rejected.deinit(allocator);
}
