---
id: task-low-implement-screensaver-cli-surface
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Implement Screensaver CLI Surface

Wire `16c screensaver` into the CLI and route it into a dedicated session-mode entrypoint that can later own fullscreen lifecycle behavior.

Targets: `src/cli/sixteenc.zig`, `src/download/lib.zig`, `src/download/commands/random.zig` or new session module
Validation: `zig build test`

## Evidence

- Added a distinct `screensaver` branch in `src/cli/sixteenc.zig` and exposed it in usage/help output.
- Routed `16c screensaver` through `executeScreensaver` and `ScreensaverPlaybackLoop` in `src/download/commands/random.zig`, keeping the current playback loop reusable while separating the entrypoint.
- Validation: `zig build test` passed after the change.
