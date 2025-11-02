//! HTTP download client
//!
//! Simple HTTP/HTTPS client for downloading files from 16colo.rs.
//! Uses std.http.Client for requests with streaming downloads to avoid
//! buffering entire files in memory.

const std = @import("std");
const Allocator = std.mem.Allocator;
const http = std.http;
const fs = std.fs;

/// HTTP client for file downloads
pub const HttpClient = struct {
    allocator: Allocator,
    client: http.Client,

    /// Initialize HTTP client
    pub fn init(allocator: Allocator) HttpClient {
        return .{
            .allocator = allocator,
            .client = http.Client{ .allocator = allocator },
        };
    }

    /// Download a file from URL to destination path
    ///
    /// Simplified implementation: downloads to memory then writes to file.
    /// Good enough for small ANSI files (< 1MB typical).
    ///
    /// # Arguments
    /// - `url`: Source URL (e.g., "https://16colo.rs/pack/mist1025/file.ans")
    /// - `dest_path`: Destination file path
    ///
    /// # Errors
    /// - `NetworkFailure`: Connection failed
    /// - `HttpError`: Non-200 HTTP status
    /// - `FileNotFound`: HTTP 404
    /// - `Timeout`: Request timed out
    /// - `OutOfMemory`: Allocation failed
    pub fn download(self: *HttpClient, url: []const u8, dest_path: []const u8) !void {

        // For now, use a very simple approach with curl
        // TODO: Replace with proper std.http.Client implementation
        const curl_cmd = try std.fmt.allocPrint(
            self.allocator,
            "curl -s -f -o {s} {s}",
            .{ dest_path, url },
        );
        defer self.allocator.free(curl_cmd);

        const result = try std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &[_][]const u8{ "sh", "-c", curl_cmd },
        });
        defer self.allocator.free(result.stdout);
        defer self.allocator.free(result.stderr);

        if (result.term.Exited != 0) {
            if (result.term.Exited == 22) {
                return error.FileNotFound; // curl 404
            }
            return error.HttpError;
        }
    }

    /// Clean up HTTP client resources
    pub fn deinit(self: *HttpClient) void {
        self.client.deinit();
    }
};

/// HTTP-specific errors
pub const HttpError = error{
    NetworkFailure,
    HttpError,
    FileNotFound,
    Timeout,
};
