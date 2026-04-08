---
id: task-med-expand-current-archive-database-surface
level: medium
status: pending
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Expand Current Archive Database Surface

Either implement the currently exposed archive interface shape or narrow the public surface so stubbed behaviors stop masquerading as near-term runtime capability.

This medium slice owns only the Stage 1 archive database contract and evidence around `getPack`, `searchFiles`, and `listPacksByYear`. It excludes HTTP transport, cache cleanup, and any future archive-client expansion.
