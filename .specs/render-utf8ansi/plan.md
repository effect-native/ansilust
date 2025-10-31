# UTF8ANSI Renderer - Implementation Plan

## XP/TDD Methodology

This plan follows Kent Beck's Extreme Programming red/green/refactor cycle:
- **RED**: Write failing test first
- **GREEN**: Minimal code to make test pass
- **REFACTOR**: Clean up while keeping tests green
- **COMMIT**: Git commit after each micro-phase with validation
- **DEMO**: Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` between loops to show progress

## Phase 5 Implementation Cycles

### Cycle 1: TerminalGuard Scaffolding (RED → GREEN → REFACTOR)

**Objective**: Establish terminal safety contract with TTY vs file-mode distinction.

#### RED Phase
- [ ] Create `src/renderers/utf8ansi_test.zig`
- [ ] Write test: `TerminalGuard emits DECAWM toggle in both modes`
- [ ] Write test: `TerminalGuard emits cursor hide/clear only in TTY mode`
- [ ] Tests fail (TerminalGuard doesn't exist)
- [ ] Commit: `test(utf8ansi): add TerminalGuard red tests`

#### GREEN Phase
- [ ] Create `src/renderers/utf8ansi.zig`
- [ ] Implement `TerminalGuard` with `init`/`deinit` and `is_tty` flag
- [ ] Implement prologue (DECAWM + optional TTY sequences)
- [ ] Implement epilogue (DECAWM restore + optional TTY cleanup)
- [ ] Run `zig build test` → tests pass
- [ ] Commit: `feat(utf8ansi): implement TerminalGuard (green)`

#### REFACTOR Phase
- [ ] Extract constants for escape sequences
- [ ] Add doc comments to TerminalGuard
- [ ] Run `zig fmt src/renderers/utf8ansi.zig`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): clean up TerminalGuard`

#### DEMO
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` (expect: parse output, no render yet)

---

### Cycle 2: Minimal Render Pipeline (RED → GREEN → REFACTOR)

**Objective**: Wire render function to emit rows with cursor positioning.

#### RED Phase
- [ ] Write test: `render emits cursor positioning for each row`
- [ ] Write test: `render handles empty document`
- [ ] Tests fail (render function stub)
- [ ] Commit: `test(utf8ansi): add render pipeline red tests`

#### GREEN Phase
- [ ] Implement `Utf8Ansi.render` function signature
- [ ] Loop through grid rows, emit `CSI {row};1H` for each
- [ ] Emit cells as raw scalars (no style/color yet)
- [ ] Wire TerminalGuard into render
- [ ] Run `zig build test` → tests pass
- [ ] Commit: `feat(utf8ansi): implement minimal render pipeline (green)`

#### REFACTOR Phase
- [ ] Extract row iteration logic
- [ ] Add doc comments to render function
- [ ] Run `zig fmt`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): clean up render loop`

#### DEMO
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` (expect: parse output still)

---

### Cycle 3: CP437 Glyph Mapping (RED → GREEN → REFACTOR)

**Objective**: Translate CP437 bytes to visually-matched Unicode glyphs.

#### RED Phase
- [ ] Write test: `GlyphMapper translates box-drawing chars`
- [ ] Write test: `GlyphMapper translates shading chars`
- [ ] Write test: `GlyphMapper handles ASCII passthrough`
- [ ] Tests fail (GlyphMapper returns raw bytes)
- [ ] Commit: `test(utf8ansi): add glyph mapping red tests`

#### GREEN Phase
- [ ] Create CP437 → Unicode lookup table (256 entries from libansilove)
- [ ] Implement `GlyphMapper.encode` using table
- [ ] Handle UTF-8 multi-byte encoding
- [ ] Run `zig build test` → tests pass
- [ ] Commit: `feat(utf8ansi): implement CP437 glyph mapping (green)`

#### REFACTOR Phase
- [ ] Extract constants for common glyphs
- [ ] Add doc comments explaining visual alignment choices
- [ ] Run `zig fmt`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): document glyph mapping rationale`

#### DEMO
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` (expect: parse output still, glyph tests pass)

---

### Cycle 4: Color Emission - DOS Palette (RED → GREEN → REFACTOR)

**Objective**: Emit 256-color SGR sequences using DOS→ANSI 256 mapping.

#### RED Phase
- [ ] Write test: `ColorMapper emits SGR 38;5;N for DOS palette indices`
- [ ] Write test: `ColorMapper uses pre-calculated ANSI 256 mapping`
- [ ] Write test: `ColorMapper emits SGR 39/49 for Color::None`
- [ ] Tests fail (ColorMapper.apply is stub)
- [ ] Commit: `test(utf8ansi): add color emission red tests`

#### GREEN Phase
- [ ] Implement DOS→ANSI 256 mapping table (16 entries)
- [ ] Implement `ColorMapper.apply` to emit foreground/background SGR
- [ ] Handle Color::None → SGR 39/49
- [ ] Run `zig build test` → tests pass
- [ ] Commit: `feat(utf8ansi): implement DOS palette color emission (green)`

#### REFACTOR Phase
- [ ] Extract color emission logic to helper functions
- [ ] Add doc comments for palette mapping
- [ ] Run `zig fmt`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): clean up color emission`

#### DEMO
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` (expect: parse output still)

---

### Cycle 5: Style Batching Optimization (RED → GREEN → REFACTOR)

**Objective**: Avoid redundant SGR sequences for consecutive cells with identical style.

#### RED Phase
- [ ] Write test: `RenderState batches consecutive cells with same style`
- [ ] Write test: `RenderState emits SGR 0 when style changes`
- [ ] Tests fail (every cell emits full SGR)
- [ ] Commit: `test(utf8ansi): add style batching red tests`

#### GREEN Phase
- [ ] Implement `RenderState` with current style tracking
- [ ] Implement `applyStyle` that compares and only emits on change
- [ ] Emit `SGR 0` before new style
- [ ] Run `zig build test` → tests pass
- [ ] Commit: `feat(utf8ansi): implement style batching (green)`

#### REFACTOR Phase
- [ ] Simplify style comparison logic
- [ ] Add doc comments
- [ ] Run `zig fmt`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): optimize style batching`

#### DEMO
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` (expect: parse output still)

---

### Cycle 6: CLI Integration (RED → GREEN → REFACTOR)

**Objective**: Wire renderer into main.zig CLI so `ansilust <file>` renders to terminal.

#### RED Phase
- [ ] Manually test: `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` → expect parse output
- [ ] Note: should render artwork instead
- [ ] Commit: `test(cli): document expected render behavior`

#### GREEN Phase
- [ ] Update `src/main.zig` to call `Utf8Ansi.render` after parse
- [ ] Detect `isatty(stdout)` and pass to renderer options
- [ ] Write rendered output to stdout
- [ ] Run `zig build` → compiles
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` → renders to terminal!
- [ ] Commit: `feat(cli): integrate utf8ansi renderer into main`

#### REFACTOR Phase
- [ ] Extract render logic to helper function
- [ ] Add error handling for render failures
- [ ] Add doc comments
- [ ] Run `zig fmt src/main.zig`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(cli): clean up render integration`

#### DEMO
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS` → **DOPAMINE HIT: actual artwork renders!**
- [ ] Bramwell feedback: note issues with colors, glyphs, layout

---

### Cycle 7: Truecolor Support (RED → GREEN → REFACTOR)

**Objective**: Add 24-bit color emission for `--truecolor` flag.

#### RED Phase
- [ ] Write test: `ColorMapper emits SGR 38;2;R;G;B in truecolor mode`
- [ ] Tests fail (only 256-color implemented)
- [ ] Commit: `test(utf8ansi): add truecolor red tests`

#### GREEN Phase
- [ ] Add `truecolor` field to Options
- [ ] Modify `ColorMapper.apply` to emit 24-bit SGR when enabled
- [ ] Update CLI to support `--truecolor` flag
- [ ] Run `zig build test` → tests pass
- [ ] Commit: `feat(utf8ansi): add truecolor support (green)`

#### REFACTOR Phase
- [ ] Consolidate color emission logic
- [ ] Add doc comments
- [ ] Run `zig fmt`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): simplify truecolor logic`

#### DEMO
- [ ] Run `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS --truecolor`
- [ ] Bramwell feedback: visual comparison with 256-color mode

---

### Cycle 8: File Mode Validation (RED → GREEN → REFACTOR)

**Objective**: Verify `ansilust art.ans > art.utf8ansi` produces replayable output.

#### RED Phase
- [ ] Write test: `render in file mode omits cursor hide/clear`
- [ ] Write test: `render in file mode still emits DECAWM toggles`
- [ ] Tests fail (not distinguished yet)
- [ ] Commit: `test(utf8ansi): add file mode red tests`

#### GREEN Phase
- [ ] Ensure TerminalGuard respects `is_tty` flag
- [ ] Verify file-mode output contains positioning but not TTY-only sequences
- [ ] Run `zig build test` → tests pass
- [ ] Manual test: `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS > /tmp/test.utf8ansi`
- [ ] Manual test: `cat /tmp/test.utf8ansi` → artwork displays correctly
- [ ] Commit: `feat(utf8ansi): validate file mode output (green)`

#### REFACTOR Phase
- [ ] Clean up guard conditionals
- [ ] Add doc comments explaining TTY vs file behavior
- [ ] Run `zig fmt`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): clarify tty vs file modes`

#### DEMO
- [ ] Run full pipeline: `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS > /tmp/test.utf8ansi && cat /tmp/test.utf8ansi`
- [ ] Bramwell feedback: layout preservation, wrap behavior

---

### Cycle 9: Bramwell Feedback Loop - Iteration 1

**Objective**: Collect and address initial visual fidelity issues.

#### Bramwell Evaluation
- [ ] Run renderer on 5-10 corpus files
- [ ] Collect feedback on:
  - Colors (accurate vs theme-influenced)
  - Glyphs (box-drawing, shading, suits)
  - Layout (wrap issues, alignment)
  - Terminal state (cleanup, persistent errors)

#### RED Phase
- [ ] Document issues as failing acceptance criteria
- [ ] Add tests for specific glyph/color problems identified
- [ ] Commit: `test(utf8ansi): add bramwell feedback red tests`

#### GREEN Phase
- [ ] Adjust CP437 mapping for mis-rendered glyphs
- [ ] Fix color emission bugs
- [ ] Fix layout issues
- [ ] Run `zig build test` → tests pass
- [ ] Commit: `fix(utf8ansi): address bramwell feedback iteration 1 (green)`

#### REFACTOR Phase
- [ ] Document rationale for glyph mapping adjustments
- [ ] Clean up any hacky fixes
- [ ] Run `zig fmt`
- [ ] Run `zig build test` → still passing
- [ ] Commit: `refactor(utf8ansi): clean up feedback fixes`

#### DEMO
- [ ] Re-run on same corpus files
- [ ] Bramwell evaluation: visual improvement check

---

## Progress Tracking

### Completed Cycles
- [ ] Cycle 1: TerminalGuard
- [ ] Cycle 2: Minimal Pipeline
- [ ] Cycle 3: Glyph Mapping
- [ ] Cycle 4: Color Emission
- [ ] Cycle 5: Style Batching
- [ ] Cycle 6: CLI Integration ← **FIRST VISUAL RENDER**
- [ ] Cycle 7: Truecolor Support
- [ ] Cycle 8: File Mode
- [ ] Cycle 9: Bramwell Iteration 1

### Validation Gates (Run after each GREEN phase)

```bash
# Format code
zig fmt src/renderers/utf8ansi.zig

# Build project
zig build

# Run tests
zig build test

# Demo render (after Cycle 6)
zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS
```

---

## Success Criteria Validation

After all cycles complete:

- [ ] **SC7.1.1**: All 19 acdu0395 files render without errors
- [ ] **SC7.1.2**: Bramwell: "colors look correct" on 90%+ of files
- [ ] **SC7.1.3**: Bramwell: "glyphs render correctly" on 90%+ of files
- [ ] **SC7.1.4**: Zero SAUCE metadata visible in output
- [ ] **SC7.1.5**: Zero terminal corruption after 100+ renders
- [ ] **SC7.2.1**: 100% doc comment coverage
- [ ] **SC7.2.2**: Zero memory leaks (std.testing.allocator)
- [ ] **SC7.2.3**: `zig build` → zero errors/warnings
- [ ] **SC7.2.4**: `zig build test` → all pass
- [ ] **SC7.2.5**: Code formatted with `zig fmt`
- [ ] **SC7.3.1**: Render time < 100ms for 80×200 files

---

## Risk Mitigation

- **Memory leaks**: Use `std.testing.allocator` in all tests; run after each GREEN phase
- **Terminal quirks**: DECAWM experiment validated; tests ensure sequences present
- **Glyph mapping disputes**: Override table in renderer; iterate with Bramwell
- **CLI regression**: Ensure `zig build run` still works for parse-only demo

---

## Notes

- Commit message format: `<type>(scope): <description>` (e.g., `test(utf8ansi): add red tests`)
- Demo command after Cycle 6+: `zig build run -- ~/Downloads/acdu0395/STC-ACID.ANS`
- Bramwell is the human-in-the-loop for visual acceptance testing
