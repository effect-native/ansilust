---
id: task-low-ensure-seeded-art-survives-retention-policy
level: low
status: done
blocked_by: []
expires_at: 2026-04-16T01:18:55Z
---

# Ensure Seeded Art Survives Retention Policy

Make sure the chosen starter-art path is not accidentally evicted or degraded by the runtime's cache-retention behavior once cleanup becomes real.

## Evidence

- Solved this by contract: starter art is now materialized into `local/` instead of `random/`, so it is outside the cache-retention target in `src/download/storage/files.zig`.
- Added `FileStorage.cleanupRandom does not evict starter art stored in local pool` in `src/download/storage/files_test.zig` to pin that `cleanupRandom(random_dir, 10)` trims `random/` while leaving the seeded local starter file intact.
