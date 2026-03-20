---
id: task-low-specify-bootstrap-preseed-and-first-run-growth-boundary
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Specify Bootstrap Preseed And First Run Growth Boundary

Define how curated preseed, optional bootstrap downloads, and first-run growth should stay separate from the shipped Stage 1 runtime.

## Evidence

- Updated `.specs/screensaver/plan.md` to state that Stage 1 shipped truth stops at the local playable pool, with curated preseed allowed only as already-local content and bootstrap/first-run growth kept explicitly post-MVP.
- Added a concrete future growth ladder from current local pool -> larger curated preseed -> optional bootstrap expansion -> later metadata/index/sync work, without leaking those steps into Stage 1 claims.
