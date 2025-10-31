# UTF8ANSI Renderer - Design Document

## 1. Overview

The UTF8ANSI renderer consumes a fully-populated Ansilust IR document and produces a buffered ANSI/UTF-8 byte stream. The renderer honors palette, glyph, and layout semantics conveyed in the IR while ensuring terminal safety (wrap management, cleanup on error). When stdout is an interactive TTY, it emits full prologue/epilogue control sequences; when stdout is redirected to a file, it still emits DECAWM toggles so replaying the `.utf8ansi` file with `cat` preserves layout, but it omits cursor-hide/clear-screen controls.

Key priorities:
- Treat IR metadata as authoritative (palette, columns, ice colors) with CLI overrides baked in during parsing.
- Preserve visual intent for CP437 and Unicode art.
- Guarantee terminal cleanup on interactive TTYs; emit layout-preserving wrap toggles even for redirected output.
- Maintain extensible architecture that could support streaming or alternate renderers later.

## 2. Module Architecture

```
ansilust
└── src
    ├── renderers
    │   └── utf8ansi.zig    # Renderer implementation (new)
    └── cli / main.zig       # Routes parse → render
```

### 2.1 Public API Shape

```zig
pub const Utf8Ansi = struct {
    pub const Options = struct {
        is_tty: bool,
    };

    pub fn render(
        allocator: std.mem.Allocator,
        ir: *const ir.Document,
        options: Options,
    ) ![]u8;
};
```

- `is_tty` passed from CLI (via `std.fs.isatty(stdout.handle)`).
- Renderer always emits DECAWM disable/enable but only emits cursor/clear sequences when `is_tty` is true.

### 2.2 Internal Helpers

- `State` struct: caches current fg/bg/attributes for batching decisions.
- `AnsiWriter`: wrapper over `std.ArrayList(u8)` with helpers (`writeCsi`, `setColor`, `setAttributes`, `moveCursor`).
- `GlyphEncoder`: translates IR cell glyphs to UTF-8 (CP437 table + overrides).
- `ColorMapper`: maps palette indices to ANSI 256 codes or truecolor sequences.
- `TerminalGuard`: RAII helper handling prologue/epilogue variations based on `is_tty`.

## 3. Rendering Pipeline

1. **Initialization**
   - Create `std.ArrayList(u8)` sized via heuristic.
   - Instantiate `TerminalGuard` (always emits DECAWM toggles; only emits cursor/clear sequences when `is_tty`).
   - Initialize `State` to defaults.

2. **Palette Setup**
   - Use IR custom palette if provided; otherwise fallback to VGA or other hints.
   - Precompute palette index → ANSI mapping and truecolor usage per cell.

3. **Row Iteration**
   - For each row `y`:
     - If `is_tty`, emit absolute cursor move `CSI {y+1};1H`; else append newline separator (if not first row) to maintain full width in file playback.
     - For each cell `x`:
       - Skip `spacer_tail`.
       - Determine `Style` from IR and emit SGR changes if needed.
       - Encode glyph to UTF-8 and append.
   - After TTY-mode row completes, no extra newline (cursor move handles positioning); file-mode relies on explicit newline separators to maintain row boundaries.

4. **Finalization**
   - `TerminalGuard` appends epilogue (DECAWM enable always, cursor show/SGR reset only in TTY mode).
   - Return `ArrayList` buffer slice.

### 3.1 Style Batching

- Compare `Style` struct (fg/bg/attrs) with previous state; emit resets only when changed.
- Works identically for both output modes.

### 3.2 Color Emission

- Palette vs truecolor logic unchanged.
- File-mode output still contains full color sequences so replaying retains fidelity.

### 3.3 Glyph Encoding

- CP437 table + override map for Bramwell-driven adjustments.
- Grapheme clusters handled using IR-provided storage.

## 4. Memory Management

- Single `std.ArrayList(u8)` with `ensureTotalCapacity` heuristic to minimize reallocations.
- No temporary allocations beyond optional override lookups.
- `errdefer` ensures guard epilogue emitted even on error.

## 5. Error Handling Strategy

- Error set includes `error.InvalidInput`, `error.OutOfMemory`, `error.EncodingError`.
- `try`/`errdefer` ensure partial TTY writes still culminate in cleanup sequences.
- File-mode skip of cursor/clear sequences simplifies error cases (only DECAWM toggles remain).

## 6. Terminal Safety Contract

- Prologue (`is_tty` true):
  - `CSI ?25l` (hide cursor)
  - `CSI ?7l` (disable wrap)
  - `CSI 2J` (clear screen)
  - `CSI H` (home cursor)
- Prologue (`is_tty` false):
  - `CSI ?7l` only (~disable wrap to signal layout to replayers).
- Epilogue (always): `CSI ?7h` (enable wrap).
- Epilogue (`is_tty` true): additionally `CSI 0m`, `CSI ?25h`.
- Guard ensures prologue/epilogue emitted exactly once in any mode.

## 7. Testing Strategy

### 7.1 Unit Tests
- Validate style batching, color mapping, glyph translation, guard behavior in both TTY and file modes.

### 7.2 Integration Tests
- Render to string in TTY-mode and assert presence of cursor/clear sequences + DECAWM toggles.
- Render in file-mode and assert only DECAWM toggles present (no cursor/clear codes).
- Replay saved `.utf8ansi` via `cat` in test harness to ensure width preserved (verify screenshot or diff vs reference string).

### 7.3 Experiment Outcomes
- Wrap behavior experiment informs guard: DECAWM toggles always emitted, consistent with test findings.
- Palette tests ensure custom palettes survive when saving + replaying files.

## 8. Extensibility Considerations

- **Streaming**: Future API could stream rows after IR parsed; guard design keeps logic stateless per row.
- **Alternate Renderers**: Shared modules (glyph encoder, color mapper) reusable.
- **Replay Tooling**: Future CLI (`ansilust --replay art.utf8ansi`) can reuse guard to interpret DECAWM toggles when outputting to TTY.

## 9. Implementation Plan Snapshot

1. Add `renderers/utf8ansi.zig` with options for `is_tty`.
2. Implement `TerminalGuard` with dual-mode prologue/epilogue.
3. Implement style batching + color mapping helpers.
4. Integrate glyph encoding + override mechanism.
5. Update CLI to determine `isatty` and pass options; still support redirection.
6. Add regression tests and golden fixtures for both output modes.
7. Validate manual flows (`ansilust art.ans > art.utf8ansi`; `cat art.utf8ansi`).

---

This design ensures the renderer emits layout-preserving sequences regardless of output destination while keeping interactive terminals clean and ready for continued use.
