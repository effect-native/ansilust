---
id: NFR-QA-001
title: Eliminate catch unreachable without justification
area: qa
status: pending
priority: medium
spec_ref:
  - .specs/download/requirements.md#tc34-safety-and-correctness
code_refs:
  - src/ir/cell_grid.zig:323
acceptance:
  - All `catch unreachable` uses audited
  - Each justified with comment OR replaced with proper error handling
  - Zero unjustified unreachable assertions
  - Document pattern in coding guidelines
blocked_by: []
labels:
  - safety
  - error-handling
  - NFR
created: 2025-11-03
---

## Context

From requirements:
- TC3.4.5: Error handling comprehensive with no `catch unreachable` without justification
- TC3.4.1: Zero undefined behavior

Current violation:
```zig
// src/ir/cell_grid.zig:323
.cell = self.grid.getCell(self.x, self.y) catch unreachable, // Valid coords
```

## Gap

`catch unreachable` asserts the error can never occur, but should be justified or eliminated.

## Acceptable Uses (with justification comment)

1. **Provably valid bounds**: Coordinates known to be within bounds
2. **Infallible allocations**: Fixed-size stack arrays
3. **Internal invariants**: State guaranteed by prior checks

## Pattern for Justification

```zig
// SAFETY: x,y validated in calling function; grid bounds guaranteed
.cell = self.grid.getCell(self.x, self.y) catch unreachable,
```

OR replace with defensive check:
```zig
.cell = self.grid.getCell(self.x, self.y) catch |err| {
    std.debug.panic("BUG: iterator coords out of bounds: {}", .{err});
},
```

## Audit Steps

1. Search codebase for `catch unreachable`
2. For each occurrence:
   - Verify invariant is truly guaranteed
   - Add justification comment OR replace with error handling
3. Add coding guideline to CLAUDE.md or AGENTS.md

## Reference

- Zig safety philosophy: https://ziglang.org/documentation/master/#Undefined-Behavior
- `.specs/download/requirements.md` TC3.4 Safety requirements
