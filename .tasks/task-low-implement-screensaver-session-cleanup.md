---
id: task-low-implement-screensaver-session-cleanup
level: low
status: pending
blocked_by: ["task-med-add-screensaver-session-cleanup", "task-low-add-red-tests-for-screensaver-session-cleanup"]
expires_at: 2026-04-03T01:51:31Z
---

# Implement Screensaver Session Cleanup

Implement the dedicated screensaver session lifecycle with alternate-screen entry/restore, cursor handling, input exit, and best-effort signal cleanup.

Targets: screensaver session module plus `src/cli/sixteenc.zig` integration
Validation: `zig build test`
