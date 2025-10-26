# Ansilust IR – Phase 4 Implementation Plan

## 1. Roadmap Overview

This plan operationalizes the requirements and design specifications for the Ansilust Intermediate Representation. Execution is structured into five sequential phases with explicit checklists, validation gates, and ownership boundaries. We alternate between a Builder role (hypothesize and implement) and a Challenger role (test and falsify), echoing Kent Beck’s Explore/Expand/Extract cadence, GAN-style adversarial collaboration, and scientific-method/OODA feedback loops so each iteration builds on validated functionality. Progression to each subsequent phase requires all exit criteria (including validation steps) to be satisfied.

---

## 2. Phase Breakdown

### Dual-Role Iteration Cadence
- **Role Alternation:** Each micro-iteration splits responsibilities into Builder (B) and Challenger (C); collaborators swap roles every loop to maintain healthy adversarial pressure.
- **Scientific Method Loop:** The Builder forms a hypothesis and implements the minimal slice; the Challenger designs falsification tests against the requirements before integration.
- **OODA Integration:** After every B/C pass, run an Observe–Orient–Decide–Act checkpoint, log outcomes in `STATUS.md`, and re-orient backlog priorities before the next loop.
- **Validation Sources:** Challengers curate regression suites from `reference/sixteencolors` alongside previously green cases, ensuring expansions rest on proven foundations.

### Phase 1 – Project Scaffolding & Infrastructure
- [ ] Instantiate module skeletons (`document`, `document_builder`, `cell_grid`, `encoding`, `color`, `attributes`, `animation`, `sauce`, `hyperlink`, `event_log`, `serialize`, `ghostty`, `opentui`, `errors`).
- [ ] Establish shared error set (`error{OutOfMemory, InvalidCoordinate, InvalidEncoding, UnsupportedAnimation, SerializationFailed, DuplicateHyperlinkId, DuplicatePaletteId, DuplicateFrameId}`).
- [ ] Wire allocator plumbing in `Document.init/deinit`, ensuring ownership rules comply with requirements.
- [ ] Implement CI hooks or build scripts to exercise `zig build`, `zig build test`, `zig build docs`, and `zig fmt`.
- [ ] Author baseline doc comments on public types and functions (even if stubs) to enforce documentation discipline.

**Exit Criteria**
- Directory structure matches design module table.
- `zig build` succeeds with placeholder implementations returning `error.UnsupportedFeature` where necessary.
- All public APIs have placeholder doc comments.
- Progress tracker updated.

---

### Phase 2 – Core Cell Grid & Grapheme Infrastructure
- [ ] Implement `CellGrid` structure-of-arrays layout with eager allocation of slices (`source_offset`, `source_len`, `encoding`, `contents`, `fg_color`, `bg_color`, `attributes`, `wide_flags`, `hyperlink_id`, `dirty`).
- [ ] Create `CellContents` union (scalar vs grapheme ID) with helper constructors.
- [ ] Implement `CellInput`, `CellView`, and accessors (`getCell`, `setCell`, `resize`, `iterCells`).
- [ ] Build grapheme pool arena + slab transition logic; expose API to intern grapheme sequences.
- [ ] Unit tests covering bounds checks, wide-character spacing, grapheme pooling, and dirty-bit invariants (T1/T2 portions).

**Validation**
- `zig fmt src/**/*.zig`
- `zig build`
- `zig build test` (focus on `cell_grid.zig`, `encoding.zig` tests)
- Leak detection using `std.testing.allocator`

**Exit Criteria**
- All core grid tests pass without leaks.
- `Document.resize` delegates to grid successfully.
- Grapheme pool API documented and validated.
- Progress tracker updated.

---

### Phase 3 – Metadata Systems (Palettes, Fonts, SAUCE, Attributes)
- [ ] Implement `Color` union with palette/true color/None variants; add palette tables with shared ownership.
- [ ] Implement attribute bitflag helpers (`AttributeFlags`, fluent setters, underline style/color handling).
- [ ] Complete `SourceEncoding` enum (IANA + vendor range) with lookup helpers.
- [ ] Add SAUCE preservation module (`SauceRecord`, comment handling with encoding tags).
- [ ] Implement font storage (embedded glyph buffers, spacing/aspect hints).
- [ ] Unit tests: palette round-trip, attribute toggles, SAUCE parsing, font embedding (T3–T6).

**Validation**
- `zig fmt`
- `zig build`
- `zig build test` (metadata suites)
- `zig build docs` (ensures doc comments render)

**Exit Criteria**
- Metadata APIs satisfy RQ-Palette, RQ-Attr, RQ-Font, RQ-SAUCE.
- Tests demonstrate preservation of raw bytes vs parsed views.
- Progress tracker updated.

---

### Phase 4 – Animation, Event Log, and Hyperlinks
- [ ] Implement `Animation` module with frame records (snapshot/delta union, duration/delay, loop metadata).
- [ ] Implement delta application and copy-on-write snapshot strategy.
- [ ] Integrate hyperlink registry (OSC 8) with cell references and validation.
- [ ] Build event log capturing `(frame_index, sequence_id, payload)` tuples; ensure deterministic ordering.
- [ ] Extend `DocumentBuilder` to orchestrate per-frame cell pushes, events, and allocator migrations.
- [ ] Unit & integration tests: animation sequencing, delta integrity, hyperlink preservation, event ordering (T7 partial, T8 partial, T9 foundation).

**Validation**
- `zig fmt`
- `zig build`
- `zig build test` (animation/event-focused)
- Optional: targeted fuzz harness for timeline invariants (early T12 coverage)

**Exit Criteria**
- Animation structures comply with RQ-Anim and RQ-Event requirements.
- Builder finalization enforces invariants and allocator transitions.
- Progress tracker updated.

---

### Phase 5 – Serialization, Render Bridges, and System Integration
- [ ] Implement binary serializer/deserializer (`ANSILUSTIR\0` header, versioning, section layout).
- [ ] Add `toGhosttyStream` helper honoring wrap flags, color None semantics, hyperlinks, and event replay.
- [ ] Add OpenTUI `OptimizedBuffer` conversion (satisfy AC7, RQ-Ghostty-1 alignment).
- [ ] Complete integration tests: format round-trips (ANSI, XBin, UTF8ANSI, ansimation) using fixtures curated from `reference/sixteencolors`, alongside Ghostty golden tests and OpenTUI conversion (T7–T9).
- [ ] Property-based tests and fuzzers (T10–T12) plus performance benchmarks (T13–T15) using representative fixtures.
- [ ] Documentation polishing: ensure `docs/ir.md` up to date, README/STATUS updates, release notes.

**ANSI Parser Review (2024):** 

**Phase 5 - ANSI Parser Fixes (Completed 2024):**

The ANSI parser in `src/parsers/ansi.zig` has been brought to feature parity with libansilove's ansi.c implementation. All core functionality is implemented and tested.

**Completed Items:**

*API Fixes:*
- ✓ Fixed `Ir.Document.init` to accept width and height parameters (80x25 default)
- ✓ Replaced non-existent `Ir.Color.fromAnsi` with `Color{ .palette = idx }`
- ✓ Fixed cell mutation API to use `doc.setCell(x, y, CellInput{ ... })`
- ✓ Fixed SAUCE parsing to use correct types and field access
- ✓ Fixed attribute API to use `AttributeFlags` fluent methods
- ✓ Parser compiles cleanly and passes all tests

*Character Handling (libansilove-aligned):*
- ✓ TAB (0x09): Advance cursor by 8 columns with wrap handling
- ✓ SUB (0x1A): Terminate parsing (EOF marker)
- ✓ CR (0x0D): Reset column to 0
- ✓ LF (0x0A): Move to next line and reset column
- ✓ Implicit wrap: Auto-wrap to next line when column reaches width

*CSI Sequence Support:*
- ✓ Enforce CSI buffer limits (ANSI_SEQUENCE_MAX_LENGTH = 14 bytes)
- ✓ Cursor positioning: CUP (H/f) - absolute position with bounds clamping
- ✓ Cursor movement: CUU (A), CUD (B), CUF (C), CUB (D) - relative movements with bounds
- ✓ Cursor save/restore: s (save), u (restore)
- ✓ Erase display: J with param 2 (clear screen and reset position)
- ✓ No-op sequences: p (cursor activation), h/l (set/reset modes), K (EL)

*SGR (Select Graphic Rendition):*
- ✓ Full attribute support: bold (1), faint (2), italic (3), underline (4), blink (5), reverse (7), invisible (8), strikethrough (9)
- ✓ Attribute off commands: SGR 22 (bold/faint off), 24 (underline off), 25 (blink off), 27 (reverse off), 28 (invisible off), 29 (strikethrough off)
- ✓ Standard 16-color palette: 30-37 (fg), 40-47 (bg)
- ✓ High intensity colors: 90-97 (bright fg), 100-107 (bright bg)
- ✓ Default colors: 39 (default fg), 49 (default bg)
- ✓ 256-color support: ESC[38;5;n (fg), ESC[48;5;n (bg)
- ✓ 24-bit RGB support: ESC[38;2;r;g;b (fg), ESC[48;2;r;g;b (bg)

*Test Coverage:*
- ✓ Basic text rendering
- ✓ TAB handling and wrapping
- ✓ Newline handling
- ✓ SUB termination
- ✓ SGR bold, colors, and reset
- ✓ Cursor positioning
- ✓ High intensity colors
- ✓ 256-color support
- ✓ 24-bit RGB support
- ✓ Implicit wrapping at line end

**Current Status:** The ANSI parser is production-ready for basic ANSI art files. It correctly parses SAUCE metadata, handles all common escape sequences, and writes to the IR document structure. All tests pass cleanly.

**Remaining Work (Future Enhancements):**

1. **Attribute interactions (libansilove compatibility):**
   - [ ] Bold adds fg bright (except in Workbench mode) - requires palette mode detection
   - [ ] Blink promotes bg to bright in iCE colors mode - requires iCE flag handling in rendering
   - [ ] Verify invert toggling behavior matches libansilove exactly

2. **PabloDraw extensions (optional):**
   - [ ] ESC [ ... t sequences for truecolor mode toggle
   - [ ] PabloDraw-specific RGB payload handling

3. **Encoding and character set support:**
   - [ ] CP437-to-Unicode mapping table for DOS character data
   - [ ] Raw byte + encoding tagging in IR cells for lossless round-trips
   - [ ] Support for additional code pages (CP866, ISO-8859-1, etc.)

4. **Extended testing:**
   - [ ] Golden file tests against sixteencolors-archive corpus
   - [ ] Regression tests comparing output to libansilove
   - [ ] Ansimation (animated ANSI) support and tests
   - [ ] SAUCE comment block parsing tests
   - [ ] Edge case tests (malformed sequences, buffer overruns, etc.)

5. **Performance optimization:**
   - [ ] Profile parser with large files (>100KB)
   - [ ] Optimize cell write operations for bulk content
   - [ ] Consider streaming API for very large files

**Validation (per acceptance gate)**
- `zig fmt`
- `zig build -Doptimize=Debug`
- `zig build`
- `zig build test`
- `zig build docs`
- Benchmarks executed and results recorded
- Golden snapshot comparison for Ghostty stream

**Exit Criteria**
- Serialization round-trips losslessly (AC6).
- Ghostty and OpenTUI integration tests green.
- Performance targets documented (Perf-1..4).
- Success criteria checklist satisfied.
- Plan progress tracker marked complete.

---

## 3. Validation Checkpoints (Applies to Every Phase)

| Step | Command | Notes |
|------|---------|-------|
| Format | `zig fmt` | Run on all touched files before validation |
| Debug Build | `zig build -Doptimize=Debug` | Triggers safety checks |
| Release Build | `zig build` | Must succeed cleanly |
| Tests | `zig build test` | Watch for leaks via `std.testing.allocator` |
| Docs | `zig build docs` | Ensures doc comments remain valid |
| Benchmarks | `zig build bench` (Phase 5) | Capture and log metrics |

Failure at any checkpoint blocks phase exit. Record failures and remediation steps in STATUS log.

---

## 4. Task Hierarchies

```
Phase 1
 ├─ Module scaffolding
 ├─ Error surface definition
 ├─ Allocator plumbing
 └─ CI/build harness
Phase 2
 ├─ CellGrid slices
 ├─ Grapheme pool
 ├─ Accessors & iterators
 └─ Core unit tests
Phase 3
 ├─ Color & palette management
 ├─ Attribute bitflags/helpers
 ├─ Encoding registry
 ├─ SAUCE handling
 └─ Font metadata
Phase 4
 ├─ Animation tables
 ├─ Delta application
 ├─ DocumentBuilder orchestration
 ├─ Hyperlink registry
 └─ Event log sequencing
Phase 5
 ├─ Serialization/Deserialization
 ├─ Ghostty renderer bridge
 ├─ OpenTUI conversion
 ├─ Integration & fuzz tests
 └─ Performance benchmarking
```

---

## 5. Risk Mitigation

| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|----------------------|
| Memory leaks due to allocator misuse | Medium | High | Enforce allocator ownership in reviews; exhaustive tests with `std.testing.allocator`; adopt `errdefer` cleanup patterns. |
| Performance regressions in delta application | Medium | Medium | Benchmark per milestone; profile with Zig’s timer utilities; optimize hot paths before Phase 5 closure. |
| Encoding enum drift vs requirements | Low | Medium | Freeze enum list in `.specs/ir/prior-art-notes.md`; require citation for new entries; add compile-time assertions. |
| Ghostty alignment failures | Medium | High | Maintain golden tests; run Ghostty bridge integration after each major change; prioritize fix before other tasks. |
| Serialization version churn | Low | High | Lock format post Phase 5; require decision log entry for changes; add compatibility tests across versions. |

---

## 6. Success Criteria Mapping

| Requirement / Acceptance | Covered In | Verification |
|--------------------------|------------|--------------|
| AC1–AC5 (format fidelity) | Phases 2–4 | Integration tests with fixture assets |
| AC6 (serialization) | Phase 5 | Round-trip tests + binary diff |
| AC7 (OpenTUI) | Phase 5 | Conversion tests + manual inspection |
| AC8 (UTF8ANSI render fidelity) | Phase 5 | Golden Ghostty output comparison |
| AC9 (leak-free) | All phases | `std.testing.allocator` reports |
| AC10 (doc comments) | Ongoing | `zig build docs` + review |
| AC11 / Perf targets | Phase 5 | Benchmark suite results |
| RQ-Event / RQ-Link compliance | Phase 4 | Event log & hyperlink unit tests |

---

## 7. Progress Tracking

| Phase | Status | Owner | Last Updated | Notes |
|-------|--------|-------|--------------|-------|
| Phase 1 | ☐ Not Started | (assign) | — | — |
| Phase 2 | ☐ Not Started | (assign) | — | — |
| Phase 3 | ☐ Not Started | (assign) | — | — |
| Phase 4 | ☐ Not Started | (assign) | — | — |
| Phase 5 | ☐ Not Started | (assign) | — | — |

Update this table at the end of each work session in tandem with `STATUS.md`.

---

## 8. Phase Transition Protocol

1. Complete checklist items and validation steps.
2. Document outcomes in `STATUS.md` (pass/fail, benchmarks, notable findings).
3. Submit summary for review (include diffs, test logs, benchmark data).
4. Obtain explicit approval before advancing to the next phase (per `.specs/AGENTS.md` gates).

---

## 9. Ready for Authorization

This plan satisfies Phase 4 deliverables: structured roadmap, validation checkpoints, risk mitigation, success criteria alignment, and tracking scaffolding. Upon approval, the team may proceed to Implementation Phase execution aligned with this document.