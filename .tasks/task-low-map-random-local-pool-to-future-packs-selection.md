---
id: task-low-map-random-local-pool-to-future-packs-selection
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Map Random Local Pool To Future Packs Selection

Define how the current `random/` plus `local/` Stage 1 source set grows into pack-aware local selection without breaking the shipped runtime.

## Evidence

- Updated `.specs/screensaver/design.md` to lock Stage 1 local-pool truth to `random/` plus `local/` while defining the additive transition to pack-aware `packs/` selection behind the same source-provider contract.
- Re-read the edited design for consistency before closing the task.
