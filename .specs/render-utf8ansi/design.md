# UTF8ANSI Renderer - Design Document

## 1. Overview

The UTF8ANSI renderer consumes a fully-populated Ansilust IR document and produces a buffered ANSI/UTF-8 byte stream. The renderer honors palette, glyph, and layout semantics conveyed in the IR while ensuring terminal safety (wrap management, cleanup on error). Regardless of whether stdout is an interactive TTY or redirected to a file, the renderer emits DECAWM toggles and absolute cursor positioning sequences so the byte stream preserves the artwork’s layout exactly; TTY-specific niceties (cursor hide/show, clear screen) are emitted only when the render targets a live terminal.

Key priorities:
- Treat IR metadata as authoritative (palette, columns, ice colors) with CLI overrides baked in during parsing.
- Preserve visual intent for CP437 and Unicode art.
- Guarantee terminal cleanup on interactive TTYs while still producing replayable streams when redirected.
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

- `is_tty` determined by CLI via `std.fs.isatty(stdout.handle)`.
- Render always emits DECAWM disable/enable and `CSI {row};{col}H` positioning.
- Cursor hide/show and screen clearing only occur when `is_tty` is true.

### 2.2 Internal Helpers

- `State`: caches current fg/bg/attributes for batching decisions.
- `AnsiWriter`: helper over `std.ArrayList(u8)` to append CSI sequences, glyphs, etc.
- `GlyphEncoder`: renderer-owned CP437/Unicode mapping tables translating glyphs to UTF-8 (IR remains semantic source).
- `ColorMapper`: maps palette indices to ANSI 256 codes or truecolor sequences.
- `TerminalGuard`: RAII helper handling prologue/epilogue variations based on `is_tty`.

## 3. Rendering Pipeline

1. **Initialization**
   - Allocate `std.ArrayList(u8)` with capacity heuristic.
   - Instantiate `TerminalGuard`
     - Always writes `CSI ?7l` (DECAWM off).
     - If `is_tty`, also write `CSI ?25l` (hide cursor) and `CSI 2J`/`CSI H` (clear/home).
   - Initialize `State` to defaults.

2. **Palette Setup**
   - Use IR custom palette if present; otherwise fallback to VGA/other hints.
   - Precompute palette index → ANSI mapping and truecolor usage per cell.

3. **Row Iteration**
   - For each row `y`:
     - Emit absolute cursor move `CSI {y+1};1H` (always, so file playback respects layout).
      - Iterate columns `x`:
        - Skip cells marked `spacer_tail`.
        - Determine `Style` (fg/bg/attrs) from IR; emit SGR changes when style differs from previous state.
        - Encode glyph to UTF-8 via renderer-owned mapping (ensuring visual alignment) and append.
    - No explicit newline needed because positioning commands define layout; smoothing with newline optional when writing to file but redundant.


4. **Finalization**
   - `TerminalGuard` epilogue writes `CSI ?7h` (DECAWM on) in all modes; if `is_tty`, also writes `CSI 0m` (reset) and `CSI ?25h` (show cursor).
   - Return buffer slice from `ArrayList`.

### 3.1 Style Batching

- Styles stored in struct `{ fg: Color, bg: Color, attrs: Attributes }`.
- Compare with previous style to avoid redundant `SGR` sequences.
- `SGR 0` emitted when style changes drastically; subsequent attribute/color codes follow.

### 3.2 Color Emission

- `ColorMapper` handles palette vs truecolor emission per cell.
- `Color::None` uses `SGR 39` or `SGR 49`.
- Works identically for TTY and file output.

### 3.3 Glyph Encoding

- Renderer maintains CP437 → Unicode map tuned for visual fidelity (baseline alignment, weight) while IR retains raw CP437 bytes.
- Override table stored within renderer module for quick adjustments as Bramwell feedback arrives.
- Grapheme clusters fetched from IR’s shared storage and encoded to UTF-8 via `std.unicode.utf8Encode` or manual bitpacking.


## 4. Memory Management

- Single `std.ArrayList(u8)` tuned via `ensureTotalCapacity` to minimize reallocs.
- No temporary allocations beyond override table lookups.
- `errdefer` ensures guard epilogue emitted even if `render` fails mid-way.

## 5. Error Handling Strategy

- Error union covers `error.InvalidInput`, `error.OutOfMemory`, `error.EncodingError`.
- `try` used for all fallible operations; `errdefer` ensures cleanup sequences appended for TTY output.
- File-mode simplicity: only DECAWM toggles require symmetry.

## 6. Terminal Safety Contract

- Prologue (all modes): `CSI ?7l` (disable wrap).
- Prologue (`is_tty` true): additional `CSI ?25l`, `CSI 2J`, `CSI H`.
- Epilogue (all modes): `CSI ?7h` (enable wrap).
- Epilogue (`is_tty` true): `CSI 0m`, `CSI ?25h`.
- Absolute positioning commands maintain layout in both modes.

## 7. Testing Strategy

### 7.1 Unit Tests
- Validate style batching, color mapping, glyph translation, guard variations.

### 7.2 Integration Tests
- Render to string with `is_tty = true` and ensure prologue/epilogue + positioning present.
- Render with `is_tty = false`; assert presence of DECAWM/positioning sequences but absence of cursor hide/clear-screen codes.
- Round-trip test: parse ANSI → render to file → `cat` the bytes and compare to TTY-mode render.

### 7.3 Experiment Outcomes
- Wrap experiment ensures DECAWM toggles necessary; tests verify presence.
- Palette tests confirm custom palettes persist in output stream.

## 8. Extensibility Considerations

- **Streaming**: Renderer design remains stateless per row to support future streaming once IR is available.
- **Alternate Renderers**: Glyph/color helpers reusable.
- **Replay Tooling**: Future CLI command could reuse same renderer with `is_tty = true` to display saved `.utf8ansi` files interactively.

## 9. Implementation Plan Snapshot

1. Create `renderers/utf8ansi.zig` with options/guard.
2. Implement `TerminalGuard` dual-mode prologue/epilogue.
3. Add style batching + color mapping helpers.
4. Wire in glyph encoder + overrides.
5. Update CLI to determine `isatty` and pass options.
6. Add tests/golden fixtures for both output modes.
7. Manual verification: `ansilust art.ans > art.utf8ansi`; `cat art.utf8ansi` (no cropping, correct layout); interactive run ensures cleanup.

---

This design ensures the renderer produces a layout-faithful byte stream for both interactive viewing and offline replay, while keeping terminal safety intact.
