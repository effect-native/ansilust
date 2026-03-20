---
id: task-low-add-looping-random-command-module
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Add Looping Random Command Module

Create the module and orchestration surface that turns one-shot random display into a reusable continuous playback loop.

Evidence: added public `RandomPlaybackLoop` in `src/download/commands/random.zig` with `playOnce` and bounded `run` entry points for later CLI reuse.
