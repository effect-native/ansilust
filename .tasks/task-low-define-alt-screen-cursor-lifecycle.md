---
id: task-low-define-alt-screen-cursor-lifecycle
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Alt Screen Cursor Lifecycle

Define when the screensaver enters alternate screen mode, hides the cursor, restores terminal state, and returns to the caller environment.

## Evidence

- `.specs/screensaver/requirements.md:19` says `16c screensaver` enters isolated terminal presentation mode when it starts.
- `.specs/screensaver/requirements.md:20-22` defines hidden terminal chrome while active, prompt exit on input, and terminal-state restoration on termination.
- `.specs/screensaver/design.md:105` says the screensaver session manager enters and restores alternate screen plus cursor visibility.
- `.specs/screensaver/design.md:112-120` places session setup at initialization and restoration at cleanup, which defines return to the caller environment on exit.
- `.specs/screensaver/design.md:189-195` explicitly states alternate-screen entry/restoration, cursor hide/restore, input exit, signal exit, and final cleanup even on playback failure.
