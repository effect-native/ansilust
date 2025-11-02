//! 16colors download library
//!
//! Public API for 16colors archive downloads and management.

pub const database = @import("database/interface.zig");
pub const commands = struct {
    pub const random = @import("commands/random.zig");
};
pub const protocols = struct {
    pub const http = @import("protocols/http.zig");
};
pub const storage = struct {
    pub const paths = @import("storage/paths.zig");
    pub const files = @import("storage/files.zig");
};
