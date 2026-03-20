---
id: task-low-define-resize-handling-and-render-mode-escalation
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Resize Handling And Render Mode Escalation

Decide what the MVP does on terminal resize and which fit, fill, or native modes are deferred beyond the first usable release.

## Evidence

- Updated `.specs/screensaver/design.md` to define Stage 1 resize handling at artwork boundaries rather than promising live relayout.
- Clarified that fit, fill, native, user-selectable render-mode switches, and aspect-correct presentation modes are explicitly deferred beyond MVP.
