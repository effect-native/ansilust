---
id: task-low-remove-stage1-config-compatibility-shims
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T15:55:56Z
---

# Remove Stage1 Config Compatibility Shims

Eliminate temporary helper hacks and assertion shims left behind in the Stage 1 runtime/config path.

## Evidence

- Removed dead Stage 1 config compatibility assertions from `src/download/commands/random.zig` and kept the fallback contract documented inline.
- Removed the single-candidate local-pool string-shape shim by returning the duplicated path directly in `src/download/commands/random.zig`.
- Validation: `zig build test --summary all` -> `167/167 tests passed`.
