---
id: task-low-implement-random-dwell-and-empty-pool-policy
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Implement Random Dwell And Empty Pool Policy

Implement the fixed Stage 1 dwell default, replay policy for a one-file local pool, and the helpful empty-pool error path without regressing `random-1`.

Targets: `src/download/commands/random.zig`, `src/cli/sixteenc.zig` if CLI/default plumbing is needed
Validation: `zig build test`

## Evidence

- Updated `src/download/commands/random.zig` so `RandomPlaybackLoop` defaults to a 20-second dwell, replays the only playable local file explicitly, and returns `error.EmptyLocalArtworkPool` with guidance naming `random/` and `local/` when `16c random` has no local artwork.
- Preserved local-first behavior and kept remote fallback available only for `random-1` after local selection fails.
- Validation: `zig test src/download/commands/random_test.zig` and `zig build test`
