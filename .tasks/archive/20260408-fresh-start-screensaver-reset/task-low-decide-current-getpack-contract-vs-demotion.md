---
id: task-low-decide-current-getpack-contract-vs-demotion
level: low
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Decide Current GetPack Contract Vs Demotion

Choose whether `getPack` is part of the Stage 1 public contract now or should be explicitly demoted until real evidence exists.

## Resolution

Demote `getPack` from the current Stage 1 public contract.

## Evidence

- Confirmed this task was unblocked (`blocked_by: []`).
- Verified `src/download/database/hardcoded.zig` implements `getPack` only as a stub returning `error.NotImplemented`.
- Verified `src/download/database/interface_test.zig` pins that stub behavior instead of any successful pack lookup behavior.
- Verified no current runtime path calls `getPack`; the shipped Stage 1 flow uses only the working `getRandomFile` path.
- Updated `.specs/download/design.md` to explicitly state that `getPack` is a future archive-database seam and not a current shipped pack-lookup guarantee.
