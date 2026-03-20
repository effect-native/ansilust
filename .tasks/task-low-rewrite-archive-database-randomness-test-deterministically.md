---
id: task-low-rewrite-archive-database-randomness-test-deterministically
level: low
status: pending
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Rewrite Archive Database Randomness Test Deterministically

Replace the probabilistic variety assertion in `src/download/database/interface_test.zig` with deterministic coverage that fits the current hardcoded catalog contract and restores a stable green test suite.

Targets: `src/download/database/interface_test.zig`
Validation: `zig build test`
