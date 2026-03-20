---
id: task-low-fix-stage1-config-build-error
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Fix Stage1 Config Build Error

Repair the current `zig build` failure in `src/download/commands/stage1_config.zig` and revalidate the Stage 1 config-loading slice.

Targets: `src/download/commands/stage1_config.zig`, any tiny adjacent runtime fix required by the compiler
Validation: `zig build`, `zig build test`

## Evidence

- Fixed `src/download/commands/stage1_config.zig` to handle the missing-config case with the valid `readFileAlloc` error set.
- Applied the smallest adjacent `src/download/commands/random.zig` compile-compatibility fixes needed to restore the Stage 1 config slice build floor without changing config behavior.
- Validation passed: `zig build`
- Validation passed: `zig build test`
