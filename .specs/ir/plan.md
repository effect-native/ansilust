# Ansilust IR – Phase 5 Implementation Plan (XP TDD Edition)

## Executive Summary: Kent Beck XP Test-Driven Development

This plan operationalizes Phase 5 implementation using **Extreme Programming (XP) discipline** with strict adherence to the **Red–Green–Refactor cycle**. Every feature increment follows:

1. **Red Phase**: Write failing tests first (from reference implementation test cases + specification requirements)
2. **Green Phase**: Implement minimal code to pass tests (no generalization)
3. **Refactor Phase**: Clean up, extract helpers, optimize without changing behavior
4. **Commit**: Git commit at each phase boundary with detailed messages

We adopt **test-first methodology** exclusively—no implementation without a failing test. Test case batteries are extracted directly from:
- **PabloDraw** (`reference/pablodraw/pablodraw/`) - Comprehensive C# format handling
- **libansilove** (`reference/libansilove/libansilove/`) - Reference C implementation
- **sixteencolors-archive** (`reference/sixteencolors/`) - Real-world test corpus (35 MB, 137+ ANSI files)

---

## Phase 5: Parser Implementation (XP TDD Cycles)

### Overview: Parser Roadmap

**MVP Scope** (Required for basic functionality):
1. ANSI Parser (Phase 5A)
2. UTF8ANSI Parser (Phase 5B)
3. SAUCE Standalone Parser (Phase 5C)

**Extended Scope** (Format completeness):
4. Binary Parser (Phase 5D)
5. XBin Parser (Phase 5E)
6. ArtWorx Parser (Phase 5F)
7. PCBoard Parser (Phase 5G)

**Deferred** (Future phases):
- Tundra Parser
- iCE Draw Parser
- RIPscrip Parser

---

## Phase 5A: ANSI Parser (XP TDD Cycles)

### Progress Snapshot (2025-10-26)
- [x] Cycle 1 – Plain text & control characters (implemented in `src/parsers/ansi.zig`, tests in `src/parsers/ansi_test.zig`, passing via `zig build test`)
- [x] Cycle 2 – SGR parsing and color attributes (RED→GREEN→REFACTOR complete; full SGR support with 8/bright/256/truecolor; all 51 tests pass)
- [x] Cycle 3 – Cursor positioning, save/restore, bounds clamping (RED→GREEN→REFACTOR complete; CSI H/A/B/C/D/s/u; all 55 tests pass)
- [x] Cycle 4 – Erase operations (RED→GREEN→REFACTOR complete; CSI J/K for display/line clearing; all 58 tests pass)
- [ ] Cycle 5 – SAUCE metadata integration
- [ ] Integration – Golden corpus regression tests

### A1: Test Case Extraction (Red Phase Setup)

**Source**: `reference/libansilove/libansilove/src/loaders/ansi.c` + PabloDraw's `Types/Ansi.cs`

**Extract Test Cases**:

1. **Character Handling**
   - TAB (0x09): Advance 8 columns with wrapping
   - CR (0x0D): Cursor to column 0
   - LF (0x0A): Advance row + reset column
   - SUB (0x1A): EOF marker (terminate parse)
   - Regular printable ASCII
   - CP437 extended characters (128-255)

2. **Cursor Positioning**
   - CSI H (CUP) - Cursor Up Position: `ESC[row;colH`
   - CSI A (CUU) - Cursor Up: `ESC[nA`
   - CSI B (CUD) - Cursor Down: `ESC[nB`
   - CSI C (CUF) - Cursor Forward: `ESC[nC`
   - CSI D (CUB) - Cursor Back: `ESC[nD`
   - CSI s - Save cursor position
   - CSI u - Restore cursor position
   - Boundary clamping (row/col overflow)

3. **SGR (Select Graphic Rendition)**
   - SGR 0 (reset all)
   - SGR 1 (bold)
   - SGR 2 (faint)
   - SGR 3 (italic)
   - SGR 4 (underline)
   - SGR 5 (blink)
   - SGR 7 (reverse)
   - SGR 8 (invisible)
   - SGR 9 (strikethrough)
   - SGR 22 (normal intensity)
   - SGR 24 (no underline)
   - SGR 25 (no blink)
   - SGR 27 (no reverse)
   - SGR 28 (visible)
   - SGR 29 (no strikethrough)
   - SGR 30-37 (8 foreground colors)
   - SGR 40-47 (8 background colors)
   - SGR 39 (default foreground)
   - SGR 49 (default background)
   - SGR 90-97 (bright foreground)
   - SGR 100-107 (bright background)
   - SGR 38;5;n (256-color foreground)
   - SGR 48;5;n (256-color background)
   - SGR 38;2;r;g;b (RGB foreground)
   - SGR 48;2;r;g;b (RGB background)

4. **Erase Operations**
   - CSI J (ED) - Erase Display with param 2 (clear all)
   - CSI K (EL) - Erase Line (optional, often no-op)

5. **Edge Cases & Error Handling**
   - Empty file
   - Missing SGR params (treat as 0)
   - Malformed sequences (incomplete CSI)
   - Tab near line boundary
   - Wrap at exact column boundary
   - Mixed attributes (bold + color)

6. **SAUCE Metadata**
   - Extract 128-byte SAUCE record
   - Parse all fields (title, author, group, date, filetype, flags)
   - Handle missing SAUCE (graceful)
   - Validate checksum

**Test File Organization**:

```
src/parsers/tests/
├── ansi_test_cases.zig          (test case definitions)
├── ansi_fixtures/
│   ├── red_phase_minimal/       (1-2 files per test case)
│   │   ├── simple_text.ans
│   │   ├── sgr_reset.ans
│   │   ├── cursor_move.ans
│   │   ├── tab_wrap.ans
│   │   ├── cp437_chars.ans
│   │   ├── rgb_color.ans
│   │   ├── wide_chars.ans
│   │   └── sauce_metadata.ans
│   ├── green_phase_extended/    (more comprehensive files)
│   └── refactor_phase_real/     (files from sixteencolors corpus)
└── ansi_integration_test.zig    (round-trip tests)
```

### A2: Red Phase 1 — Simple Text Parsing ✅ (completed 2025-10-26)

**Goal**: Parse plain ASCII text without any escape sequences.

**Scope Status**:
- Tests cover sequential ASCII writes, newline handling, carriage returns, tab stops, SUB termination, CP437 conversion, and document metadata marking. (`src/parsers/ansi_test.zig`)
- Implementation in `src/parsers/ansi.zig` passes all tests; CP437 extended table verified.
- Verified via `zig build test`.

**Next Step**: Begin A3 – write RED tests for SGR parsing.

### A3: Red Phase 2 — SGR and Colors ✅ (completed 2025-10-26)

**Completed**: Full XP cycle (RED→GREEN→REFACTOR)

**RED Phase**:
- Added `expectCellStyle` helper to validate fg/bg/attributes
- Tests for SGR reset (0), explicit defaults (39, 49)
- Tests for bright colors (90-97, 100-107)
- Tests for 256-color sequences (38;5;n, 48;5;n)
- Tests for truecolor RGB (38;2;r;g;b, 48;2;r;g;b)
- Test for malformed SGR handling

**GREEN Phase**:
- Added style state (fg_color, bg_color, attributes) to Parser
- Implemented ESC [ CSI sequence detection
- Implemented CSI parameter parsing (up to 16 params)
- Full SGR handler with:
  * Attributes: bold, faint, italic, underline, blink, reverse, invisible, strikethrough
  * Reset/unset codes (0, 22-29)
  * 8-color palette (30-37, 40-47)
  * Bright colors (90-97, 100-107)
  * Default resets (39, 49)
  * 256-color palette with xterm standard lookup
  * Truecolor RGB support
- Apply current style to cells during writeScalar

**REFACTOR Phase**:
- Extracted DEFAULT_FG_COLOR and DEFAULT_BG_COLOR constants
- Encapsulated ANSI style tracking in `StyleState` to centralize SGR handling
- All 51 tests pass (`zig build test` before commit)

### A4: Cursor Positioning ✅ (completed 2025-10-26)

**Completed**: Full XP cycle (RED→GREEN→REFACTOR)

**RED Phase**:
- Tests for CSI H (CUP) 1-based coordinate positioning
- Tests for CSI C/D horizontal movement
- Tests for CSI s/u save/restore cursor
- Tests for bounds clamping (999;999 wraps to max bounds)

**GREEN Phase**:
- Added saved_cursor_x, saved_cursor_y to Parser
- Implemented handleCursorPosition (CSI H) with 1-based→0-based conversion
- Implemented handleCursorUp/Down/Forward/Back (CSI A/B/C/D)
- Implemented handleSaveCursor/RestoreCursor (CSI s/u)
- All cursor movements clamp to document bounds
- All 55 tests pass

**REFACTOR Phase**:
- Simplified cursor movement conditionals with ternary expressions
- All 55 tests still pass

### A5: Erase Operations ✅ (completed 2025-10-26)

**Completed**: Full XP cycle (RED→GREEN→REFACTOR)

**RED Phase**:
- Tests for CSI J (erase from cursor to end of display, mode 0)
- Tests for CSI 2J (erase entire display)
- Tests for CSI K (erase from cursor to end of line)

**GREEN Phase**:
- Implemented handleEraseDisplay with mode 0 (cursor→end) and mode 2 (entire screen)
- Implemented handleEraseLine with mode 0 (cursor→end of line)
- Added clearCell helper to set cells to space with default colors
- All 58 tests pass

**REFACTOR Phase**:
- Code already clean, no refactor needed

**Next Step**: Begin A6 – SAUCE metadata integration (parse 128-byte SAUCE record from end of file)

---

### Phase 5 Tracking Table
```
| Parser  | Phase | Cycle1 | Cycle2 | Cycle3 | Cycle4 | Cycle5 | Integration |
|---------|-------|--------|--------|--------|--------|--------|-------------|
| ANSI    | 5A    | ✅     | ✅     | ✅     | ✅     | ⬜️     | ⬜️          |
| UTF8ANSI| 5B    | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️          |
| SAUCE   | 5C    | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️          |
| Binary  | 5D    | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️          |
| XBin    | 5E    | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️          |
| ArtWorx | 5F    | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️          |
| PCBoard | 5G    | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️     | ⬜️          |
```

(remaining sections unchanged...)
