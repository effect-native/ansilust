---
id: task-low-implement-stage1-playback-flags
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Implement Stage1 Playback Flags

Implement the explicit Stage 1 playback flag surface and plumb the selected mode into the shared random/screensaver playback runtime.

Targets: `src/cli/sixteenc.zig`, playback runtime code under `src/download/commands/`
Validation: `zig build test`

## Evidence

- Added `--instant` and `--streaming-speed <preset>` parsing for `random` and `screensaver` in `src/cli/sixteenc.zig`, including invalid preset and mutually exclusive flag errors.
- Added explicit playback mode plumbing in `src/download/commands/random.zig` so shared random/screensaver loops carry the selected Stage 1 mode while preserving default behavior.
- Validation: `zig build test` passed.
