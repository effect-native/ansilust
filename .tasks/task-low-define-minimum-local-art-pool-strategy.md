---
id: task-low-define-minimum-local-art-pool-strategy
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define Minimum Local Art Pool Strategy

Choose the smallest local art pool that can make `16c random` and `16c screensaver` usable before a full mirror exists.

## Evidence

- Updated `.specs/screensaver/requirements.md` to define the Stage 1 minimum local art pool as the existing `random/` cache plus `local/` user-art directories under the 16colors data root.
- Documented that one supported ANSI file is enough for Stage 1 playback, that `random-1` downloads become reusable immediately, and that `packs/` stays deferred to Stage 2.
