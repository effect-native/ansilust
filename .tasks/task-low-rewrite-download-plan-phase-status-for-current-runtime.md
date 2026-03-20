---
id: task-low-rewrite-download-plan-phase-status-for-current-runtime
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Rewrite Download Plan Phase Status For Current Runtime

Refresh `.specs/download/plan.md` so its phases, progress tables, and next steps match the shipped Stage 1 runtime and the remaining archive-client roadmap.

## Evidence

- Rewrote `.specs/download/plan.md` around the shipped Stage 1 `16c` runtime instead of the stale pre-runtime Phase 5.1 checklist.
- Marked renderer-backed playback, the `random` / `screensaver` / `random-1` surface, and local-pool-first looping behavior as shipped, while keeping `.index.db`, pack downloads, search, mirror sync, and broader local archive management explicitly pending.
- Performed a consistency read of the edited plan after the update.
