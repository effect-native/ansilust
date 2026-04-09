---
id: task-high-harden-download-stage1-runtime
level: high
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Harden Download Stage 1 Runtime

Reduce the remaining operational risk in the shipped `16c` Stage 1 download surface without expanding scope into the full future archive client.

## Resolution

- Confirmed this slice stays inside shipped Stage 1 runtime hardening only and does not reach into future archive-client, website, screensaver, or IR work.
- Partitioned follow-through into exactly two child medium tasks: archive database surface decisions/behavior in `task-med-expand-current-archive-database-surface` and transport/cache stub replacement in `task-med-replace-network-and-cache-stubs`.
- Unblocked both child medium tasks by removing their dependency on this orchestration task while leaving each medium task responsible for its own low-level children.

## Evidence

- `task-med-expand-current-archive-database-surface` now carries the archive-database/API slice only (`getPack`, `searchFiles`, `listPacksByYear`).
- `task-med-replace-network-and-cache-stubs` now carries the runtime transport/cache slice only (`http.zig`, `cleanupRandom`).
