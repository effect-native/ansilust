---
id: task-low-define-random-packs-and-local-rotation-surface
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Random Packs And Local Rotation Surface

Decide how `random/`, `packs/`, and `local/` participate in selection, retention, and rotation as the screensaver library grows.

## Evidence

- Updated `.specs/screensaver/design.md` with explicit Stage 2+ roles for `random/`, `packs/`, and `local/`.
- Added retention and steady-state rotation policy that keeps the existing MVP fallback order intact while defining how fresh intake and durable library growth should behave.
