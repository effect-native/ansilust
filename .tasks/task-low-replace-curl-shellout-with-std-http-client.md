---
id: task-low-replace-curl-shellout-with-std-http-client
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Replace Curl Shellout With Std Http Client

Move `src/download/protocols/http.zig` off `sh -c curl` and onto a tested native HTTP client implementation.

## Evidence

- Verified `src/download/protocols/http.zig` now uses `std.http.Client.fetch` and no longer shells out through `sh -c curl`.
- Verified `src/download/protocols/http_test.zig` pins the no-shellout and no-curl-TODO contract.
- Command: `zig test src/download/protocols/http_test.zig`
- Result: all 4 tests passed on 2026-04-09.
