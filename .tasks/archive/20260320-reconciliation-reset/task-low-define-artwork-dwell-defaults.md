---
id: task-low-define-artwork-dwell-defaults
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Artwork Dwell Defaults

Choose the default dwell time and pacing policy for artwork rotation so the MVP has predictable behavior.

## Evidence

- Updated `.specs/screensaver/requirements.md` to set the Stage 1 default artwork dwell to 20 seconds for both `16c random` and `16c screensaver`.
- Documented Stage 1 pacing as fixed-duration, immediate-cut rotation with no heuristic or transition-based timing.
