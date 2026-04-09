---
id: task-low-materialize-starter-art-into-playable-pool-on-first-run
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Materialize Starter Art Into Playable Pool On First Run

Implement the repo-owned step that places starter art into the chosen local playable pool before `16c screensaver` begins on a fresh machine.

## Evidence

- Added repo-owned first-use materialization at `src/download/storage/starter_art.zig`, which writes embedded starter ANSI art into `local/` only when the playable pool is empty.
- Wired `src/download/commands/random.zig` to call `ensureStarterArtwork(...)` immediately after path creation and before local-pool selection/display, so first-use seeding happens before loop playback starts.
- Added functional regression coverage in `src/download/commands/random_test.zig` proving that an empty `random/` + `local/` pool gets a playable `local/ansilust-starter.ans` file.
