---
id: task-low-implement-random-cache-cleanup-behavior
level: low
status: in_progress
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Implement Random Cache Cleanup Behavior

Replace the `cleanupRandom` TODO with the tested keep-last-10 behavior described by the current Stage 1 runtime.

## Red Phase Update

- Red phase complete.
- Added executable failing tests in `src/download/storage/files_test.zig` that pin the Stage 1 keep-last-10 cleanup contract for timestamped random-cache files.
- The new coverage requires `cleanupRandom` to retain only the newest 10 files and to evict the lexicographically oldest timestamp-prefixed entries first.
- Production cleanup implementation in `src/download/storage/files.zig` intentionally remains unchanged in RED phase.

## Failure Evidence

- Command: `zig test src/download/storage/files_test.zig`
- Observed failure: `FileStorage.cleanupRandom keeps only the newest 10 timestamped files` fails at `src/download/storage/files_test.zig:118` with `expected 10, found 12` because `src/download/storage/files.zig` still leaves all files in place.
- Observed failure: `FileStorage.cleanupRandom removes the oldest timestamp-prefixed files first` fails at `src/download/storage/files_test.zig:164` because `20260101000001-oldest.ans` still remains after cleanup, confirming the stub performs no eviction.
