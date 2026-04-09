---
id: task-med-provision-first-use-starter-art
level: medium
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Provision First-Use Starter Art

Define and implement the smallest repo-owned first-use artwork path that gives `random` and `screensaver` an immediate playable local pool on a fresh machine.

Keep bootstrap, `.index.db`, and broader archive growth out of this slice.

## Note

- Parent high-level gate was reconciled on 2026-04-09 via `task-high-enable-fresh-start-16c-screensaver`.
- This medium now owns the next executable first-use work: define the starter-art contract and materialize a repo-owned playable pool before `16c screensaver` enters its loop.

## Evidence

- Confirmed `blocked_by: []` before implementation, so this medium slice was executable.
- Defined the first-use contract in code and tests around `src/download/storage/starter_art.zig`: the repo now owns an embedded starter ANSI file and materializes it into `local/`, not `random/`, so the seeded first-use pool stays inside the current local-playable search path while remaining outside random-cache retention.
- Wired first-use provisioning into `src/download/commands/random.zig` via `ensureStarterArtwork(...)` before local-pool selection, so `random` and `screensaver` can provision a playable repo-owned local file on a fresh machine without touching bootstrap or `.index.db` work.
- Added regression coverage in `src/download/commands/random_test.zig`, `src/download/storage/starter_art.zig`, and `src/download/storage/files_test.zig` for empty-pool seeding, idempotent materialization, and retention safety for starter art stored under `local/`.
- Verified the scoped implementation with `zig build test` on 2026-04-09.
