---
id: task-med-expand-current-archive-database-surface
level: medium
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Expand Current Archive Database Surface

Either implement the currently exposed archive interface shape or narrow the public surface so stubbed behaviors stop masquerading as near-term runtime capability.

This medium slice owns only the Stage 1 archive database contract and evidence around `getPack`, `searchFiles`, and `listPacksByYear`. It excludes HTTP transport, cache cleanup, and any future archive-client expansion.

## Resolution

Resolved as slice-governance only. The medium scope is fully decomposed into two direct low tasks covering the remaining atomic decisions and evidence work:

1. `task-low-decide-current-getpack-contract-vs-demotion`
2. `task-low-add-tested-search-and-pack-list-behavior`

## Evidence

- Confirmed this medium task has no blockers.
- Confirmed both direct child low tasks exist and map cleanly to the stated Stage 1 archive database surface.
- Unblocked only those direct child low tasks so execution can proceed at the atomic level.
