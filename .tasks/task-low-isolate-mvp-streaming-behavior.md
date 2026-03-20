---
id: task-low-isolate-mvp-streaming-behavior
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Isolate MVP Streaming Behavior

Decide the minimum streaming behavior that must ship first so presentation polish does not block a working screensaver.

## Evidence

- `.specs/screensaver/requirements.md` limits Stage 1 playback to rotating one artwork at a time on a defined interval (`FR1.3.2`-`FR1.3.4`) and does not require transition effects or baud-style streaming simulation.
- `.specs/screensaver/design.md` defines MVP playback as simple parser-to-IR-to-renderer handoff, says hardcoded defaults are acceptable for MVP, and explicitly defers streaming simulation, richer transitions, overlays, and advanced presentation polish to later layers.
- `.specs/screensaver/plan.md` places streaming/transition questions inside `WP-DISP-002`, whose intent is to define first shippable presentation rules without blocking MVP on later polish.
- `.ok/screensaver.ok.md` reinforces that Stage 1 is local looping playback first and marks richer renderer ambitions such as streaming simulation and metadata overlays as non-current guarantees.
