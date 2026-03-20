---
id: task-low-defer-nonessential-transition-effects
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Defer Nonessential Transition Effects

Separate fade, scroll, reveal, scanline, and other nonessential effects into explicit post-MVP follow-on work.

## Evidence

- `.specs/screensaver/design.md:54` defines Stage 4 as deferred enhancements and names advanced transitions as outside MVP scope.
- `.specs/screensaver/design.md:167` limits MVP renderer scope and says richer transitions are later layers, not core handoff.
- `.specs/screensaver/design.md:220` explicitly defers transition effects beyond simple clear-and-render playback.
- `.specs/screensaver/plan.md:112` makes `WP-DISP-002` the policy package and requires transition effects to remain clearly post-MVP.
- `rfcs/inbox/screensaver.md:122` moves richer presentation features into Stage 3 config/experience expansion instead of the playable loop MVP.
