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
        var file = try fs.cwd().createFile(dest_path, .{});
        defer file.close();

        var file_buffer: [4096]u8 = undefined;
        var file_writer = file.writer(&file_buffer);

        const result = self.client.fetch(.{
            .location = .{ .url = url },
            .response_writer = &file_writer.interface,
        }) catch |err| switch (err) {
            error.ConnectionRefused,
            error.NetworkUnreachable,
            error.ConnectionResetByPeer,
            error.HostLacksNetworkAddresses,
            error.NameServerFailure,
            error.TemporaryNameServerFailure,
            error.UnknownHostName,
            error.UnexpectedConnectFailure,
            => return error.NetworkFailure,
            error.ConnectionTimedOut,
            => return error.Timeout,
            error.TlsInitializationFailed,
            => return error.NetworkFailure,
            error.CertificateBundleLoadFailure,
            error.InvalidFormat,
            error.InvalidPort,
            error.UnsupportedUriScheme,
            error.UriMissingHost,
            error.UriHostTooLong,
            error.UnsupportedCompressionMethod,
            error.TooManyHttpRedirects,
            error.HttpChunkInvalid,
            error.HttpChunkTruncated,
            error.HttpConnectionClosing,
            error.HttpContentEncodingUnsupported,
            error.HttpHeadersInvalid,
            error.HttpHeadersOversize,
            error.HttpRedirectLocationInvalid,
            error.HttpRedirectLocationMissing,
            error.HttpRedirectLocationOversize,
            error.HttpRequestTruncated,
            error.ReadFailed,
            error.RedirectRequiresResend,
            error.UnexpectedCharacter,
            error.WriteFailed,
            error.StreamTooLong,
            => return error.HttpError,
            else => |e| return e,
        };

        try file_writer.interface.flush();

        switch (result.status) {
            .ok => {},
            .not_found => return error.FileNotFound,
            else => return error.HttpError,
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
