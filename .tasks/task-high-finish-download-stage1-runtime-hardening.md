---
id: task-high-finish-download-stage1-runtime-hardening
level: high
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Finish Download Stage 1 Runtime Hardening

Close the two still-open Stage 1 download hardening gaps without reopening the broader archive-client scope.

## Evidence

- Reconciled the runtime-hardening slice to the checked-in downloader/cache reality only.
- Verified the two Stage 1 hardening gaps called out by this task are already closed in code:
  - `src/download/protocols/http.zig` uses native `std.http.Client` transport.
  - `src/download/storage/files.zig` implements deterministic random-cache cleanup.
- Verified the scoped task chain is complete:
  - `task-low-replace-curl-shellout-with-std-http-client` -> done
  - `task-low-implement-random-cache-cleanup-behavior` -> done
  - `task-med-close-download-stage1-stub-gaps` -> done
- Commands:
  - `zig test src/download/protocols/http_test.zig`
  - `zig test src/download/storage/files_test.zig`
- Result: both scoped test suites passed on 2026-04-09.
