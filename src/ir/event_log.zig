//! Ansilust IR - Event Log Module
//!
//! Captures terminal control sequences not directly modeled in the cell grid.
//! Provides deterministic ordering for replay and renderer compatibility.
//!
//! Events include:
//! - Palette updates (OSC 4/10/11/12)
//! - Mode changes (DECSET/DECRST)
//! - Cursor visibility toggles
//! - Screen clear operations
//! - Custom escape sequences
//!
//! Each event is timestamped relative to animation frames.
//! Implements RQ-Event requirements (referenced in requirements.md).

const std = @import("std");
const errors = @import("errors.zig");

/// Terminal event type discriminator.
pub const EventType = enum(u8) {
    /// Palette color update (OSC 4/10/11/12)
    palette_update,

    /// Terminal mode change (DECSET/DECRST)
    mode_change,

    /// Cursor visibility toggle
    cursor_visibility,

    /// Screen clear operation
    screen_clear,

    /// Title/icon update (OSC 0/1/2)
    title_update,

    /// Raw escape sequence (unclassified)
    raw_sequence,

    /// Custom application-specific event
    custom,
};

/// Palette update event data.
pub const PaletteUpdate = struct {
    /// Palette index to update (0-255)
    index: u8,

    /// New RGB color value
    r: u8,
    g: u8,
    b: u8,
};

/// Terminal mode change event data.
pub const ModeChange = struct {
    /// Mode number (e.g., 1049 for alt screen)
    mode: u16,

    /// Enable or disable
    enable: bool,
};

/// Cursor visibility event data.
pub const CursorVisibility = struct {
    /// Show or hide cursor
    visible: bool,
};

/// Screen clear event data.
pub const ScreenClear = struct {
    /// Clear mode (entire screen, from cursor, to cursor)
    mode: u8,
};

/// Title update event data.
pub const TitleUpdate = struct {
    /// Title text (owned)
    text: []const u8,

    allocator: std.mem.Allocator,

    pub fn deinit(self: *TitleUpdate) void {
        self.allocator.free(self.text);
    }
};

/// Raw escape sequence event data.
pub const RawSequence = struct {
    /// Raw bytes of escape sequence (owned)
    bytes: []const u8,

    allocator: std.mem.Allocator,

    pub fn deinit(self: *RawSequence) void {
        self.allocator.free(self.bytes);
    }
};

/// Custom event data (application-defined).
pub const CustomEvent = struct {
    /// Event identifier
    id: u32,

    /// Optional payload (owned)
    payload: ?[]const u8,

    allocator: std.mem.Allocator,

    pub fn deinit(self: *CustomEvent) void {
        if (self.payload) |p| {
            self.allocator.free(p);
        }
    }
};

/// Terminal event with timestamping.
pub const Event = struct {
    /// Unique sequence ID (for ordering)
    sequence_id: u64,

    /// Associated animation frame (0 for static, 1+ for animations)
    frame_index: u32,

    /// Event type discriminator
    event_type: EventType,

    /// Event-specific data
    data: EventData,

    allocator: std.mem.Allocator,

    pub fn deinit(self: *Event) void {
        switch (self.data) {
            .title_update => |*tu| tu.deinit(),
            .raw_sequence => |*rs| rs.deinit(),
            .custom => |*ce| ce.deinit(),
            else => {},
        }
    }
};

/// Event data union (discriminated by event_type).
pub const EventData = union(EventType) {
    palette_update: PaletteUpdate,
    mode_change: ModeChange,
    cursor_visibility: CursorVisibility,
    screen_clear: ScreenClear,
    title_update: TitleUpdate,
    raw_sequence: RawSequence,
    custom: CustomEvent,
};

/// Event log with deterministic ordering.
///
/// Stores events in sequence order with frame associations.
/// Enables replay for renderer compatibility and debugging.
pub const EventLog = struct {
    allocator: std.mem.Allocator,
    events: std.ArrayList(Event),
    next_sequence_id: u64,

    pub fn init(allocator: std.mem.Allocator) EventLog {
        return EventLog{
            .allocator = allocator,
            .events = std.ArrayList(Event).empty,
            .next_sequence_id = 0,
        };
    }

    pub fn deinit(self: *EventLog) void {
        for (self.events.items) |*event| {
            event.deinit();
        }
        self.events.deinit(self.allocator);
    }

    /// Add event to log.
    pub fn addEvent(self: *EventLog, frame_index: u32, event_type: EventType, data: EventData) !void {
        const event = Event{
            .sequence_id = self.next_sequence_id,
            .frame_index = frame_index,
            .event_type = event_type,
            .data = data,
            .allocator = self.allocator,
        };

        try self.events.append(self.allocator, event);
        self.next_sequence_id += 1;
    }

    /// Get event count.
    pub fn count(self: *const EventLog) usize {
        return self.events.items.len;
    }

    /// Get events for specific frame.
    pub fn getFrameEvents(self: *const EventLog, frame_index: u32, allocator: std.mem.Allocator) !std.ArrayList(Event) {
        var result = std.ArrayList(Event).empty;
        for (self.events.items) |event| {
            if (event.frame_index == frame_index) {
                try result.append(allocator, event);
            }
        }
        return result;
    }

    /// Clear all events.
    pub fn clear(self: *EventLog) void {
        for (self.events.items) |*event| {
            event.deinit();
        }
        self.events.clearRetainingCapacity();
        self.next_sequence_id = 0;
    }
};

// === Tests ===

test "EventLog: palette update" {
    const allocator = std.testing.allocator;

    var log = EventLog.init(allocator);
    defer log.deinit();

    const data = EventData{
        .palette_update = PaletteUpdate{
            .index = 7,
            .r = 255,
            .g = 255,
            .b = 255,
        },
    };

    try log.addEvent(0, .palette_update, data);
    try std.testing.expectEqual(@as(usize, 1), log.count());
}

test "EventLog: deterministic ordering" {
    const allocator = std.testing.allocator;

    var log = EventLog.init(allocator);
    defer log.deinit();

    try log.addEvent(0, .screen_clear, EventData{ .screen_clear = .{ .mode = 2 } });
    try log.addEvent(0, .cursor_visibility, EventData{ .cursor_visibility = .{ .visible = true } });

    try std.testing.expectEqual(@as(usize, 2), log.count());
    try std.testing.expectEqual(@as(u64, 0), log.events.items[0].sequence_id);
    try std.testing.expectEqual(@as(u64, 1), log.events.items[1].sequence_id);
}

test "EventLog: frame association" {
    const allocator = std.testing.allocator;

    var log = EventLog.init(allocator);
    defer log.deinit();

    try log.addEvent(0, .screen_clear, EventData{ .screen_clear = .{ .mode = 2 } });
    try log.addEvent(1, .screen_clear, EventData{ .screen_clear = .{ .mode = 2 } });
    try log.addEvent(1, .cursor_visibility, EventData{ .cursor_visibility = .{ .visible = false } });

    var frame1_events = try log.getFrameEvents(1, allocator);
    defer frame1_events.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 2), frame1_events.items.len);
}
