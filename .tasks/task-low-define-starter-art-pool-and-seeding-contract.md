---
id: task-low-define-starter-art-pool-and-seeding-contract
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Define Starter Art Pool And Seeding Contract

Choose the minimal starter-art contract for first use, including where seeded art lives (`random/`, `local/`, `packs/`, or another repo-owned path) and how that choice stays compatible with the current runtime and retention semantics.

## Evidence

- Chose `local/` as the starter-art destination, evidenced by `src/download/storage/starter_art.zig` and the checked-in asset `src/download/storage/starter_art/ansilust-starter.ans`.
- This contract stays compatible with the current runtime because `src/download/commands/random.zig` already scans `random/` and `local/` for playable `.ans`/`.asc` files before any remote fallback.
- This contract stays compatible with current retention semantics because `src/download/storage/files.zig` cleanup targets `random/` only, while the new starter-art tests pin that starter files remain in `local/`.
