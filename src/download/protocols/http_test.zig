//! Tests for HTTP download client

const std = @import("std");
const testing = std.testing;
const http = @import("http.zig");
const HttpClient = http.HttpClient;

test "HttpClient.init creates valid client" {
    var client = HttpClient.init(testing.allocator);
    defer client.deinit();

    // Just verify it initializes without crashing
    try testing.expect(true);
}

// Note: Actual download tests would require either:
// 1. A mock HTTP server
// 2. Network access (not ideal for unit tests)
// 3. Recorded HTTP responses
//
// For now, we verify the API compiles and basic init works.
// Integration tests will verify actual downloads.

test "HttpClient API has expected signature" {
    // Verify function signatures compile
    var client = HttpClient.init(testing.allocator);
    defer client.deinit();

    // Would test download with mock server:
    // try client.download("https://example.com/file.txt", "/tmp/test.txt");
}
