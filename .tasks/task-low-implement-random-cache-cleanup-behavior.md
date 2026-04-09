---
id: task-low-implement-random-cache-cleanup-behavior
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Implement Random Cache Cleanup Behavior

Replace the `cleanupRandom` no-op with the tested keep-last-10 behavior described by the current Stage 1 runtime.

## Evidence

- Verified `src/download/storage/files.zig` now enumerates random-cache files, sorts by parsed timestamp, and deletes the oldest entries beyond `keep_count`.
- Verified `src/download/storage/files_test.zig` covers keep-last-10 retention and oldest-first eviction.
- Command: `zig test src/download/storage/files_test.zig`
- Result: all 4 tests passed on 2026-04-09.
