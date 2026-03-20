---
id: task-low-implement-stage1-playback-flags
level: low
status: pending
blocked_by: ["task-low-add-red-tests-for-instant-and-streaming-flags"]
expires_at: 2026-04-03T01:51:31Z
---

# Implement Stage1 Playback Flags

Implement the explicit Stage 1 playback flag surface and plumb the selected mode into the shared random/screensaver playback runtime.

Targets: `src/cli/sixteenc.zig`, playback runtime code under `src/download/commands/`
Validation: `zig build test`
