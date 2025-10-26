# Ansilust IR – Design Concerns and Resolutions

This document records the contentious points raised during review of `.specs/ir/design.md`, the agreed resolutions, and the reasoning—grounded in prior art from the Ghostty and Bun teams—that led to each decision.

---

## 1. Cell Raw-Byte Bookkeeping

**Concern**  
`source_len` was specified as `u8`, limiting a cell’s preserved source slice to 255 bytes.

**Impact**  
Large OSC payloads (e.g., sixel, Kitty graphics, OSC 52 hyperlinks) or verbose grapheme sequences would be truncated, violating RQ-Raw-1 and RQ-Event-1.

**Resolution**  
Adopt `u32` for both offset and length. Inline payloads ≤ 2 bytes remain packed, but the metadata allows arbitrarily large escape segments.

**Reasoning**  
Ghostty stores OSC payloads in buffers sized for worst-case terminals, and Bun’s bundler tracks slices with 32-bit lengths to avoid truncation. Both teams value lossless capture of source bytes.

---

## 2. Redundant Unicode Scalar and Grapheme ID Fields

**Concern**  
The design kept both `unicode_scalar` and `grapheme_id` slices per cell, creating redundant state.

**Impact**  
Every mutation must maintain two correlated fields, increasing bug risk and cache pressure.

**Resolution**  
Replace the pair with a tagged union: either `Scalar(u21)` or `GraphemeId(u32)`. `Scalar` is used for simple cells, `GraphemeId` for pooled graphemes.

**Reasoning**  
Ghostty’s terminal cells track either a scalar or a grapheme reference (never both). Bun’s AST nodes use discriminated unions for interned data. Following this pattern yields clearer invariants.

---

## 3. Optional Dirty Bitset

**Concern**  
Dirty flags were described as optional slices allocated on demand.

**Impact**  
Renderer logic and `Document.resize` would need to handle both allocated and null states, complicating diff-based rendering—a core requirement.

**Resolution**  
Allocate the dirty bitset eagerly alongside other cell slices. The allocation cost is negligible compared to the grid itself.

**Reasoning**  
Ghostty always materializes dirty regions to maintain constant-time diffing, and Bun prefers consistent allocation for hot paths. Mandatory allocation keeps invariants simple.

---

## 4. Arena-Only Storage for Raw Bytes and Graphemes

**Concern**  
Using arenas without release mechanisms prevents reclaiming memory when frames or cells are rewritten.

**Impact**  
Documents with animation edits or aggressive resizing would leak space inside arenas, breaking RQ-Anim-2 expectations over long sessions.

**Resolution**  
Keep arenas for append-only phases but introduce slab allocators with freelists for mutation-heavy tables (animations, grapheme pool, raw bytes). Builders use arenas; mature documents use slabs.

**Reasoning**  
Ghostty mixes arenas for immutable data and lists/slabs for mutable structures (e.g., scrollback). Bun’s runtime reuses slabs for websocket frames. Adopting a hybrid mirrors those battle-tested approaches.

---

## 5. Animation Frame Representation

**Concern**  
`Frame.Full` implied full grid snapshots per frame, risking huge memory consumption.

**Impact**  
Long ansimations become infeasible; memory overhead explodes.

**Resolution**  
Define `Frame` as:
- `.Delta([]const DeltaCell)` representing mutations since the prior frame.
- `.Snapshot(CellGridHandle)` where snapshots point to shared, reference-counted grids (copy-on-write when mutated).

Default path uses deltas; snapshots are reserved for first frame or rare keyframes.

**Reasoning**  
Ghostty favors delta logs for scrollback; Bun’s incremental bundler avoids full clones. This pattern balances fidelity with memory efficiency.

---

## 6. Ambiguous `DuplicateId` Error

**Concern**  
The shared error set listed `DuplicateId` without specifying the context.

**Impact**  
Ambiguity hinders debugging and documentation clarity, contrary to RQ-Err-2.

**Resolution**  
Replace `DuplicateId` with scoped variants: `DuplicateHyperlinkId`, `DuplicatePaletteId`, `DuplicateFrameId`. Modules import only the relevant cases.

**Reasoning**  
Ghostty names errors by subsystem (`InvalidEscapeSequence`), and Bun scopes errors by feature modules. Explicit naming improves diagnostics.

---

## 7. Optional OpenTUI Integration Tests

**Concern**  
Design text characterized OpenTUI conversion tests as “optional,” yet AC7 requires them.

**Impact**  
Non-mandatory language could allow regressions into CI unnoticed, failing acceptance criteria.

**Resolution**  
Classify OpenTUI conversion tests as mandatory integration tests. CI will gate merges on them alongside Ghostty, round-trip, and performance suites.

**Reasoning**  
Both Ghostty and Bun tie tests directly to acceptance requirements; “optional” tests are treated as future work, not compliance. Clarifying status maintains quality gates.

---

## 8. Documentation Examples vs. Actual API Surface

**Concern**  
Examples referenced helpers (`CellInput`, `AttributeFlags.withBold`) not specified elsewhere.

**Impact**  
Mismatch between documentation and actual API forces downstream consumers to guess or re-implement utilities.

**Resolution**  
Either (1) add the helper types and builder-style flag setters to the module plan, or (2) rewrite examples to use the minimal API (`Cell.init`, manual bitflag toggles). The design now commits to include `CellInput` and fluent flag setters in `attributes.zig`.

**Reasoning**  
Ghostty ensures doc examples compile against real APIs, and Bun’s docs are generated from source definitions. Aligning examples with the concrete API avoids developer confusion.

---

## 9. Event Log Ordering and Frame Association

**Concern**  
The interplay between global event log and per-frame data was unspecified.

**Impact**  
Deserialization might reorder events, breaking deterministic replay and violating RQ-Event-2.

**Resolution**  
Define the event log as an ordered list of `(frame_index, sequence_id, event)` tuples. Serialization preserves tuple order; deserialization replays events by sorting on `(frame_index, sequence_id)`. Frames reference local events via indices, enabling time-aligned playback.

**Reasoning**  
Ghostty’s OSC recorder associates sequences with frame timestamps, and Bun maintains deterministic ordering for source maps. Explicit ordering maintains lossless event reproduction.

---

## 10. Unspecified `DocumentBuilder` Façade

**Concern**  
The design mentioned a `DocumentBuilder` but provided no structure or API outline.

**Impact**  
Parser authors lack guidance on constructing documents safely; enforcement of invariants is unclear.

**Resolution**  
Document the builder in the module table and sketch its API:
- `DocumentBuilder.init(Document*)`
- `pushCell(frame_index, CellInput)`
- `pushEvent(frame_index, Event)`
- `finalize()`
The builder handles allocator bookkeeping, ensures space for deltas, and validates coordinates before sealing the document.

**Reasoning**  
Ghostty uses builder structs (e.g., parser configuration) with explicit APIs, and Bun’s bundler context exposes clear construction steps. Providing a concrete outline prevents divergent implementations.

---

## Traceability

- **Source Document**: `.specs/ir/design.md`
- **Requirements Referenced**: RQ-Cell-2, RQ-Raw-1, RQ-Event-1, RQ-Event-2, RQ-Err-1, RQ-Err-2, AC7, AC8, AC10.
- **Prior Art Cited**: Ghostty terminal architecture (Parser/Screen), Bun bundler/runtime memory patterns.

This file will be updated if additional concerns emerge during the Plan or Implementation phases.