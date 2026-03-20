---
id: task-low-rewrite-archive-database-randomness-test-deterministically
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Rewrite Archive Database Randomness Test Deterministically

Replace the probabilistic variety assertion in `src/download/database/interface_test.zig` with deterministic coverage that fits the current hardcoded catalog contract and restores a stable green test suite.

Targets: `src/download/database/interface_test.zig`
Validation: `zig build test`

## Evidence

- Replaced the probabilistic "returns different files" assertion in `src/download/database/interface_test.zig` with a deterministic contract test that checks the current hardcoded `mist1025/CXC-STICK.ASC` entry and verifies repeated calls return the same catalog record.
- Ran `zig build test` successfully after the change.
