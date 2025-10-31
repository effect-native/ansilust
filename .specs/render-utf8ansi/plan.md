# UTF8ANSI Renderer - Implementation Plan

## Phase Checklist

- [ ] Phase 4.1: Scaffold renderer module and options
- [ ] Phase 4.2: Implement TerminalGuard (DECAWM + TTY niceties)
- [ ] Phase 4.3: Wire glyph + color encoding with style batching
- [ ] Phase 4.4: CLI integration and replay validation
- [ ] Phase 4.5: Testing, experiments, and sign-off

## Task Breakdown

### Phase 4.1 – Module Setup
- Create `src/renderers/utf8ansi.zig` with `Utf8Ansi.render` and options struct.
- Import IR modules (document, cell grid, color, attributes, sauce).
- Add placeholder `render` returning empty buffer to ensure build passes.

### Phase 4.2 – TerminalGuard Implementation
- Implement guard that writes prologue/epilogue sequences based on `is_tty`.
- Ensure `errdefer` restores wrap/cursor on error paths.
- Unit test guard to verify emitted sequences for both modes.

### Phase 4.3 – Rendering Core
- Implement style batching (fg/bg/attrs comparisons).
- Integrate CP437/Unicode glyph encoding (shared tables).
- Map palette indices to ANSI 256 or truecolor output.
- Emit absolute cursor moves for every row; skip spacer tails.

### Phase 4.4 – CLI Integration & Replay Flow
- Update CLI to detect `isatty(stdout)` and pass options into renderer.
- Replace demo `ansi.parse` output with real renderer invocation.
- Verify `ansilust art.ans` (TTY) and `ansilust art.ans > art.utf8ansi` (file).
- Confirm `cat art.utf8ansi` replays correctly (no cropping, stable layout).

### Phase 4.5 – Validation & Documentation
- Add unit tests for glyph mapping, style batching, guard variations.
- Add integration tests comparing outputs to golden files (TTY vs file mode).
- Document CLI usage in README or instructions if changed.
- Update `.specs/render-utf8ansi/plan.md` progress as tasks complete.
- Capture experiment results or manual validation in `experiments/` if needed.

## Validation Checklist

- [ ] `zig fmt src/renderers/utf8ansi.zig`
- [ ] `zig build`
- [ ] `zig build test`
- [ ] TTY manual tests (`ansilust <file>`)
- [ ] File-mode manual tests (`ansilust <file> > out.utf8ansi`; `cat out.utf8ansi`)
- [ ] Update specs (instructions/plan/status) with outcomes

## Risks & Mitigations

- **Large files causing memory pressure** – mitigate by pre-sizing buffer and monitoring heap usage; adjust heuristic if needed.
- **Glyph mapping disagreements** – use override table, capture Bramwell feedback to refine mapping without structural changes.
- **Terminal quirks** – rely on DECAWM experiment results, but keep guard configurable if future terminals misbehave.
- **CLI regression** – ensure previous `zig build run --` flows still operate; add tests for CLI entry path.

---

This plan translates the requirements/design into sequenced tasks with validation gates, preparing the team for Phase 5 implementation.
