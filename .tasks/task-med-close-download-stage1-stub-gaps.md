---
id: task-med-close-download-stage1-stub-gaps
level: medium
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Close Download Stage 1 Stub Gaps

Finish the remaining transport and cache stubs described in the current download constitution.

This slice excludes starter-art provisioning, pack acquisition, and any later archive-client growth.

## Evidence

- `task-low-replace-curl-shellout-with-std-http-client` is satisfied by the checked-in native `std.http.Client` downloader in `src/download/protocols/http.zig`.
- `task-low-implement-random-cache-cleanup-behavior` is satisfied by the checked-in deterministic cache eviction logic in `src/download/storage/files.zig`.
- Commands:
  - `zig test src/download/protocols/http_test.zig`
  - `zig test src/download/storage/files_test.zig`
- Result: both scoped test suites passed on 2026-04-09.
