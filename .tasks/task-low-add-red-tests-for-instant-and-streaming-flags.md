---
id: task-low-add-red-tests-for-instant-and-streaming-flags
level: low
status: pending
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Instant And Streaming Flags

Add failing tests for `--instant`, `--streaming-speed <preset>`, invalid preset rejection, and mutual exclusion across `random` and `screensaver`.

Targets: `src/cli/sixteenc.zig`, playback/session tests near `src/download/commands/`
Validation: targeted failing test run
