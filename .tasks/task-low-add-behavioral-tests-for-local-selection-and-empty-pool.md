---
id: task-low-add-behavioral-tests-for-local-selection-and-empty-pool
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Add Behavioral Tests For Local Selection And Empty Pool

Replace source-text assertions around local selection and empty-pool behavior with real runtime or helper-level tests.

## Evidence

- Added behavior tests in `src/download/commands/random_test.zig` for selecting the only playable local Stage 1 file and for the empty-pool guidance/error path.
- Removed superseded source-text assertions for local pool scanning/filtering/order and empty-pool handling.
- Validation: `zig build test --summary all` -> 164/164 tests passed.
