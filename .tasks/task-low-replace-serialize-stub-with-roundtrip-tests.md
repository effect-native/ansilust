---
id: task-low-replace-serialize-stub-with-roundtrip-tests
level: low
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Replace Serialize Stub With Roundtrip Tests

Implement `src/ir/serialize.zig` beyond the current stub and add tests that prove roundtrip behavior.

## Unblocked Evidence

- Direct parent medium task `task-med-implement-ir-serialization-surface` was resolved as governance.
- This low task now carries the remaining atomic implementation-and-test work.

## Red Phase Update

- Red phase complete.
- Added executable failing tests in `src/ir/serialize.zig` that define the minimum IR serialization roundtrip contract.
- The new coverage pins both default-document roundtrip behavior and populated-document roundtrip behavior across document metadata, cell state, grapheme storage, hyperlink resources, and palette resources.
- Production serialization implementation intentionally remains unchanged in RED phase.

## Failure Evidence

- Command: `zig test src/ir/serialize.zig`
- Observed failure: `serialize: roundtrip preserves default document contract` fails with `SerializationFailed` at `src/ir/serialize.zig:26` because `serialize()` still returns the explicit stub error.
- Observed failure: `serialize: roundtrip preserves populated cells and resources` fails with `SerializationFailed` at `src/ir/serialize.zig:26` for the same reason.

## Green Phase Update

- Green phase complete.
- Implemented the minimal versioned serializer/deserializer in `src/ir/serialize.zig` needed to satisfy the pinned roundtrip tests.
- Preserved only the currently tested IR surface: document dimensions and metadata, grapheme pool entries, hyperlink resources, palette resources, and per-cell state.
- Avoided unrelated IR bridge or document-builder work.

## Passing Evidence

- Command: `zig test src/ir/serialize.zig`
- Result: `All 52 tests passed.`
- Command: `zig build test`
- Result: full project test suite passed after the serialization change.
