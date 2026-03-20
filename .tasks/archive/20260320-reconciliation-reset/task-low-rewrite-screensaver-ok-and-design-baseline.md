---
id: task-low-rewrite-screensaver-ok-and-design-baseline
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Rewrite Screensaver OK And Design Baseline

Update the screensaver constitution and design so they acknowledge the current partial Stage 1 baseline (`16c random` plus renderer-backed playback) and isolate the still-missing runtime/session gaps.

Targets: `.ok/screensaver.ok.md`, `.specs/screensaver/design.md`
Validation: docs-only consistency review

## Evidence

- Updated `.ok/screensaver.ok.md` to promote checked-in `16c random` and parser-plus-renderer playback while keeping `16c screensaver`, local-pool selection, dwell/config, and session cleanup gaps future-facing.
- Updated `.specs/screensaver/design.md` so the design baseline reflects the current partial Stage 1 runtime instead of the old `random-1` plus `cat` baseline.
- Re-read the edited docs for consistency after the rewrite.
