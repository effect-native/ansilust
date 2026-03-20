---
id: task-low-add-red-tests-for-screensaver-session-cleanup
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Screensaver Session Cleanup

Add failing tests that pin alternate-screen restore, cursor restore, input-triggered exit, and signal-triggered cleanup expectations for `16c screensaver`.

Targets: screensaver session tests near `src/download/commands/`
Validation: targeted failing test run

## Evidence

- Failing command: `zig test src/download/commands/random_test.zig`
- Result: `8 passed; 0 skipped; 4 failed.`
- Failure reason: the new red tests assert that `src/download/commands/random.zig` references alternate-screen enter/restore, cursor hide/restore, stdin-driven exit handling, and signal cleanup hooks, but the current screensaver loop only delegates to `playback.run` and does not contain those session-management references yet.
