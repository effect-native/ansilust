---
id: task-low-add-red-tests-for-screensaver-session-cleanup
level: low
status: pending
blocked_by: ["task-med-add-screensaver-session-cleanup"]
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Screensaver Session Cleanup

Add failing tests that pin alternate-screen restore, cursor restore, input-triggered exit, and signal-triggered cleanup expectations for `16c screensaver`.

Targets: screensaver session tests near `src/download/commands/`
Validation: targeted failing test run
