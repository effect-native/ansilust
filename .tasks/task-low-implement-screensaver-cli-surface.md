---
id: task-low-implement-screensaver-cli-surface
level: low
status: pending
blocked_by: ["task-low-add-red-tests-for-screensaver-cli-surface"]
expires_at: 2026-04-03T01:51:31Z
---

# Implement Screensaver CLI Surface

Wire `16c screensaver` into the CLI and route it into a dedicated session-mode entrypoint that can later own fullscreen lifecycle behavior.

Targets: `src/cli/sixteenc.zig`, `src/download/lib.zig`, `src/download/commands/random.zig` or new session module
Validation: `zig build test`
