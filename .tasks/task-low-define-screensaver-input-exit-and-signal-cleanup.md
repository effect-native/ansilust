---
id: task-low-define-screensaver-input-exit-and-signal-cleanup
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Screensaver Input Exit And Signal Cleanup

Specify how `16c screensaver` exits on input and how it restores state on SIGINT, SIGTERM, SIGHUP, and SIGQUIT.

## Evidence

- Updated `.specs/screensaver/requirements.md` to define the `16c screensaver` input-exit contract explicitly.
- Added explicit Stage 1 terminal restoration requirements for `SIGINT`, `SIGTERM`, `SIGHUP`, and `SIGQUIT`, plus best-effort cleanup language.
