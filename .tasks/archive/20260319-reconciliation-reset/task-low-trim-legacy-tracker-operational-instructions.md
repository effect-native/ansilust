---
id: task-low-trim-legacy-tracker-operational-instructions
level: low
status: done
blocked_by: []
expires_at: 2026-03-20T22:49:25Z
---

# Trim Legacy Tracker Operational Instructions

Reduce `tracker/` documents to archival context so they do not still read like live task-management procedures.

## Done When

- `tracker/AGENTS.md` and related tracker docs keep legacy context but stop instructing operators to create, update, or complete live tracker tasks.
- Any remaining tracker guidance is explicitly archival and non-authoritative.

## Evidence

- Rewrote `tracker/AGENTS.md` as archive-only guidance and removed live task lifecycle, query, maintenance, and workflow instructions.
- Rewrote `tracker/README.md` as an archive overview that preserves schema context without telling operators to run tracker workflows.
- Rewrote `tracker/index.md` as a historical snapshot notice instead of a usable priority/status dashboard.
- Re-read all edited tracker docs and confirmed they consistently point operators to `.ok/project-management.ok.md` and `.tasks/` for live work.
