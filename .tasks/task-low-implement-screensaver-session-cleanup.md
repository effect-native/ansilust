---
id: task-low-implement-screensaver-session-cleanup
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Implement Screensaver Session Cleanup

Implement the dedicated screensaver session lifecycle with alternate-screen entry/restore, cursor handling, input exit, and best-effort signal cleanup.

Targets: screensaver session module plus `src/cli/sixteenc.zig` integration
Validation: `zig build test`

## Evidence

- Added a dedicated screensaver session in `src/download/commands/random.zig` that enters/restores the alternate screen, hides/restores the cursor, polls `STDIN_FILENO` for exit input, and installs best-effort `sigaction` cleanup hooks for SIGINT/SIGTERM without changing `random` / `random-1` flow.
- Validation passed with `zig build test` (`160/160 tests passed`).
