# Ansilust IR – Design Document (Phase 3)

## 1. Purpose and Context

The Ansilust Intermediate Representation (IR) design transforms the normative requirements from `.specs/ir/requirements.md` into an actionable technical architecture. This document satisfies the Design Phase deliverables described in `.specs/AGENTS.md`, covering Zig idioms, memory strategy, module boundaries, error handling, testing, documentation, code examples, integration touchpoints, and performance considerations.

### Objectives

- Provide a lossless cell-grid IR compatible with classic BBS art and modern terminal streams.
- Preserve SAUCE metadata, font assets, palette definitions, and animation semantics.
- Supply a modular Zig API with explicit allocator ownership and defensive error handling.
- Align tightly with Ghostty semantics while remaining convertible to OpenTUI’s `OptimizedBuffer`.

---

## 2. High-Level Architecture

### Module Overview

| Module | Responsibility |
|--------|----------------|
| `ansilust-ir/src/document.zig` | Root `Document` type, metadata tables, serialization entry points |
| `ansilust-ir/src/document_builder.zig` | Safe construction facade for parsers, manages arenas and slab migration |
| `ansilust-ir/src/cell_grid.zig` | Structure-of-arrays cell storage, grapheme map, accessor APIs |
| `ansilust-ir/src/encoding.zig` | `SourceEncoding` enum, helpers for raw-byte preservation |
| `ansilust-ir/src/color.zig` | Tagged union for colors, palette table management |
| `ansilust-ir/src/attributes.zig` | Bitflag layout, underline style/color management |
| `ansilust-ir/src/animation.zig` | Frame tables, delta encoding, event association |
| `ansilust-ir/src/sauce.zig` | SAUCE record parsing/preservation |
| `ansilust-ir/src/hyperlink.zig` | OSC8 hyperlink registry |
| `ansilust-ir/src/event_log.zig` | Terminal event capture for unmodeled escape sequences |
| `ansilust-ir/src/serialize.zig` | Binary format read/write (`"ANSILUSTIR\0"` header) |
| `ansilust-ir/src/ghostty.zig` | Prototype renderer helper for Ghostty stream synthesis |
| `ansilust-ir/src/opentui.zig` | Optional conversion bridge to OpenTUI’s `OptimizedBuffer` |

All modules follow the namespace container pattern. The public surface re-exports selected symbols via `ansilust-ir/src/lib.zig` to present a cohesive API.

---

## 3. Data Model Design

### 3.1 Document Root

- `Document` owns global allocators, metadata tables, and the primary `CellGrid`.
- Maintains:
  - Dimensions (`width`, `height`).
  - Default encoding + hints (`letter_spacing`, `aspect_ratio`).
  - Palettes (`PaletteTable` array with entry counts).
  - Font descriptors and embedded glyph buffers.
  - SAUCE payload (`SauceRecord`) plus parsed view.
  - Grapheme pool arena (deduplicated UTF-8 slices, migrated to slab allocators after build finalization).
  - Raw byte arena with per-cell offsets (arena-backed during construction, slab-backed after finalization).
  - Animation table (`Animation`).
  - Hyperlink table.
  - Event log capturing non-modeled control sequences.
  - Dirty bitmask flags for diff-based renderers (eager allocation).

### 3.2 Cell Grid Structure

- Structure-of-arrays layout to maximize cache locality.
- Parallel slices:
  - `source_offset: []u32` and `source_len: []u32`.
  - `encoding: []SourceEncoding`.
  - `contents: []CellContents` where `CellContents = union(enum) { scalar: u21, grapheme: u32 }`.
  - `fg_color: []Color`, `bg_color: []Color`.
  - `attributes: []AttributeFlags`.
  - `wide_flags: []WideFlag` (`None`, `Head`, `Tail`).
  - `hyperlink_id: []u32`.
  - `dirty: []bool`.

---

## 4. Zig Patterns

### 4.1 Namespace Containers and Constructors

- Each module exposes a `pub const` struct or union with associated functions.
- Constructors use `init`/`deinit` pairs and explicit allocators.
- Accessor functions return `error.InvalidCoordinate` when bounds violated.

### 4.2 Comptime Usage

- `enum(SourceEncoding)` uses comptime maps for IANA ID lookups.
- Attribute bitfields defined via comptime constants, ensuring consistency.
- Serialization employs comptime-generated section descriptors to minimize boilerplate.

### 4.3 Error Unions

- All fallible APIs return `!Type`.
- Error sets consolidated into `error{OutOfMemory, InvalidCoordinate, InvalidEncoding, UnsupportedAnimation, SerializationFailed, DuplicateHyperlinkId, DuplicatePaletteId, DuplicateFrameId}` with module-specific extensions when necessary.

---

## 5. Memory Management Strategy

### 5.1 Allocators

- The `Document` constructor receives an `Allocator` and caches it for owned allocations.
- Subcomponents (palettes, fonts, frames) accept an `Allocator` argument when independent lifetimes are desirable but typically borrow the document allocator.
- `CellGrid` uses a single contiguous allocation for slices via `Allocator.alloc` to simplify teardown.
- Grapheme and raw-byte storage begin life in `std.heap.ArenaAllocator` wrappers during construction; once finalized, slabs with freelists absorb mutations so bytes and graphemes can be recycled without heap churn. `Document.deinit` releases both arenas and slabs.

### 5.2 Ownership Rules

- `Document` is the sole owner of all IR resources.
- Parsers receive a mutable `DocumentBuilder` facade to enforce invariants during construction and to migrate arena-backed buffers into slab allocators during finalization.
- `DocumentBuilder` exposes `pushCell`, `pushEvent`, and `finalize` so parsers can stream updates safely without violating coordinate or encoding checks.
- Renderers operate on read-only views; mutation utilities guarded behind `*Document` methods to ensure diff/dirty bookkeeping stays consistent.

---

## 6. Module Architecture Details

### 6.1 `document.zig`

- Exposes `pub fn init(allocator: Allocator, width: usize, height: usize) !Document`.
- `pub fn deinit(self: *Document)` releases all owned resources.
- Provides metadata setters/getters and references to substructures.
- Offers builder access via `pub fn builder(self: *Document) DocumentBuilder`.
- Houses `pub fn resize(self: *Document, width: usize, height: usize) !void` delegating to `CellGrid.resize`.

### 6.2 `cell_grid.zig`

- Maintains core slices and capacity metadata.
- `pub fn getCell(self: *const CellGrid, x: usize, y: usize) !CellView`.
- `pub fn setCell(self: *CellGrid, x: usize, y: usize, cell: CellInput) !void`.
- `pub fn iterCells(self: *const CellGrid) CellIterator` to support sequential access.
- Handles wide character consistency (spacer tails auto-updated).

### 6.3 `animation.zig`

- `Frame` union: `.Snapshot(CellGridHandle)` or `.Delta([]DeltaCell)`; snapshots use reference-counted grids with copy-on-write semantics.
- `pub fn appendFrame(self: *Animation, frame: Frame, duration_ms: u32, delay_ms: u32) !void`.
- Deltas store coordinate, grapheme/color/attribute references referencing canonical tables, defaulting to delta frames except for the initial snapshot.

### 6.4 `serialize.zig`

- Binary format writer/reader ensures version header.
- Uses section IDs to maintain extensibility.
- Serializes arenas without extra copies by writing lengths + raw buffers.
- Supports streaming via `std.io.Writer`/`Reader` abstractions.

---

## 7. Error Handling Strategy

- Central `errors.zig` enumerates shared error set; modules import and extend via `error{ ..... }`.
- Guard all index arithmetic with `if (index >= len) return error.InvalidCoordinate`.
- Validate SourceEncoding IDs; unknown values return `error.InvalidEncoding`.
- Serialization errors include contextual `std.log.err` messages (target `std.log.Level.err`) gated behind debug flag.

---

## 8. Testing Strategy

### 8.1 Unit Tests

- Each module contains `test` blocks using `std.testing`.
- `std.testing.allocator` used for leak detection.
- Tests cover:
  - Cell CRUD operations and bounds (T1).
  - Encoding preservation across CP437/PETSCII/UTF-8 (T2).
  - Color union semantics, palette lookups, RGBA conversion (T3).
  - Attribute flag combinations, underline color (T4).
  - SAUCE record round-trip (T5).
  - Font embedding retention (T6).

### 8.2 Integration Tests

- `ansilust-ir/tests/roundtrip.zig` ensures ANSI/XBin/UTF8 samples survive parse→IR→render (T7, T8).
- Ghostty stream generation validated with fixture comparisons (T9).
- OpenTUI conversion tests run in CI alongside Ghostty and round-trip suites (AC7).

### 8.3 Property & Fuzz Testing

- `ansilust-ir/tests/fuzz_parser.zig` uses `std.rand` to generate malformed inputs, asserting invariants (T10–T12).
- Animations fuzzed for ordering and duration edge cases.

### 8.4 Performance Tests

- Benchmarks under `zig build bench` using `std.time.Timer`.
- Captures parsing throughput and memory usage (T13–T15).
- Build script integrates with `-Doptimize=ReleaseFast` for performance runs.

---

## 9. Documentation Plan

- All public APIs carry `///` doc comments with usage examples referencing modules.
- Module-level comments describe invariants and ownership.
- `docs/ir.md` auto-generated via `zig build docs`, consuming doc comments.
- Example snippets illustrate allocator usage, cell editing, and serialization.

---

## 10. Code Examples

### 10.1 Creating a Document

Helper types such as `CellInput` and fluent attribute setters ship with `cell_grid.zig` and `attributes.zig`, so the snippets compile against the public API.

```ansilust/src/examples/create_document.zig#L1-32
const std = @import("std");
const ir = @import("ansilust-ir");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();

    try doc.setDefaultEncoding(.cp437);
    try doc.setAspectRatio(.dos135);

    var cell = ir.CellInput{
        .source_bytes = "A",
        .encoding = .cp437,
        .unicode_scalar = 'A',
        .fg = .{ .palette = 15 },
        .bg = .{ .none = {} },
        .attributes = ir.AttributeFlags.init().withBold(true),
    };
    try doc.grid.setCell(10, 5, cell);
}
```

### 10.2 Serializing and Deserializing

```ansilust/src/examples/serialize_document.zig#L1-40
const std = @import("std");
const ir = @import("ansilust-ir");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();

    // ... populate doc ...

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    try ir.serialize.write(&buffer.writer(), doc);

    var stream = std.io.fixedBufferStream(buffer.items);
    const restored = try ir.serialize.read(allocator, stream.reader());
    defer restored.deinit();

    try std.testing.expectEqual(doc.dimensions(), restored.dimensions());
}
```

---

## 11. Integration Points

- **Ghostty Renderer:** `ghostty.zig` converts IR cells into Ghostty-compatible VT sequences, honoring wrap flags, hyperlink metadata, and color `None`.
- **OpenTUI Bridge:** `opentui.zig` emits `OptimizedBuffer` by mapping `Color` union into RGBA floats and reusing grapheme IDs.
- **Parsers:** Legacy format parsers populate IR via builder APIs; modern VT parser writes event log and cell updates in real time.
- **Event Log Replay:** Events capture `(frame_index, sequence_id, payload)` tuples and serialization preserves ordering for deterministic playback.

---

## 12. Performance Considerations

- Structure-of-arrays keeps per-field slices contiguous, improving SIMD-friendly diff scanning.
- Inline raw bytes ≤ 2 bytes using packed fields reduces arena lookups for ASCII content.
- Grapheme pool deduplicates repeated multi-codepoint sequences (e.g., linedrawing).
- Dirty bit array travels with the grid and resets on resize while preserving diff invariants.
- Serialization writes contiguous buffers to minimize IO calls; compressed/delta encoding reserved for future work.

---

## 13. Risk Mitigation

- **Allocator Exhaustion:** All init paths return `error.OutOfMemory`; tests simulate low-memory scenarios via failure injection.
- **Encoding Drift:** Centralized enum ensures consistent values; new encodings require citation in `.specs/ir/prior-art-notes.md`.
- **Animation Complexity:** Delta frames validated against base grid size to prevent invalid references.
- **Integration Drift:** Ghostty helper covered by regression tests comparing generated escape sequences to golden files.

---

## 14. Completion Criteria Checklist

- [ ] Implement module scaffolding per architecture table.
- [ ] Provide `Document`, `CellGrid`, serialization logic with full allocator discipline.
- [ ] Add SAUCE, font, palette preservation adhering to requirements.
- [ ] Implement animation delta support with timing metadata.
- [ ] Ensure Ghostty alignment tests pass.
- [ ] Achieve documentation coverage per plan.
- [ ] Validate performance targets through benchmarks.

---

## 15. Authorization Request

This design document fulfills Phase 3 deliverables. Please review and authorize transition to Phase 4 (Plan Phase).