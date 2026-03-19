---
id: task-low-archive-completed-top-level-task-files
level: low
status: done
blocked_by: []
expires_at: 2026-03-26T23:35:25Z
---

# Archive Completed Top-Level Task Files

Verify the previous active `.tasks/*.md` files were moved under `.tasks/archive/20260319-reconciliation-reset/` and are no longer occupying the active task root.

## Evidence

- `.tasks/archive/20260319-reconciliation-reset/` contains the prior top-level task files.
- Active root files with the same names are regenerated replacements with newer `expires_at` values and narrowed/rewritten scope, so the archived prior instances remain distinguishable from the current active copies.
