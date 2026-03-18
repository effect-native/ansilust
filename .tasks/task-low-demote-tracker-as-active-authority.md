---
id: task-low-demote-tracker-as-active-authority
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T18:00:00-04:00
---

# Demote Tracker Authority

Archive, redirect, or rewrite `tracker/` so it no longer functions as the active execution source of truth.

## Evidence

- Rewrote `tracker/README.md` to mark tracker as legacy-only and redirect live execution to `.tasks/` and `.ok/project-management.ok.md`.
- Rewrote `tracker/AGENTS.md` to remove active-work authority and explicitly forbid using tracker as the live queue.
- Rewrote `tracker/index.md` header and closing section so it no longer instructs operators to pick or manage current work there.
