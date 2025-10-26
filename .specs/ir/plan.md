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

### A2: Red Phase 1 — Simple Text Parsing

**Goal**: Parse plain ASCII text without any escape sequences.

**Test Implementation** (in `src/parsers/ansi_test.zig`):

```zig
test "ansi: parse simple text" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "Hello, World!";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // Verify cells contain expected characters
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'H');
    
    cell = try doc.getCell(6, 0);
    try expect(cell.contents.scalar == 'W');
}

test "ansi: newline handling" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "Line1\nLine2";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // "Line1" at row 0
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'L');
    
    // "Line2" at row 1
    cell = try doc.getCell(0, 1);
    try expect(cell.contents.scalar == 'L');
}

test "ansi: carriage return" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "AB\rC"; // Overwrite B with C
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(1, 0);
    try expect(cell.contents.scalar == 'C');
}
```

**Implementation** (minimal in `src/parsers/ansi.zig`):

```zig
pub const Parser = struct {
    allocator: std.mem.Allocator,
    input: []const u8,
    document: *ir.Document,
    pos: usize = 0,
    row: u16 = 0,
    col: u16 = 0,
    
    pub fn init(allocator: std.mem.Allocator, input: []const u8, doc: *ir.Document) !Parser {
        return Parser{
            .allocator = allocator,
            .input = input,
            .document = doc,
        };
    }
    
    pub fn deinit(self: *Parser) void {
        _ = self;
    }
    
    pub fn parse(self: *Parser) !void {
        while (self.pos < self.input.len) {
            const byte = self.input[self.pos];
            
            switch (byte) {
                '\n' => {
                    self.row += 1;
                    self.col = 0;
                },
                '\r' => {
                    self.col = 0;
                },
                '\t' => {
                    // Tab: advance 8 columns
                    self.col += 8;
                    if (self.col >= self.document.width) {
                        self.row += 1;
                        self.col = 0;
                    }
                },
                0x1A => break, // SUB (EOF)
                else => {
                    if (self.col >= self.document.width) {
                        self.row += 1;
                        self.col = 0;
                    }
                    try self.document.setCell(self.col, self.row, .{
                        .contents = .{ .scalar = byte },
                    });
                    self.col += 1;
                },
            }
            
            self.pos += 1;
        }
    }
};
```

**Commands**:
```bash
# Red: Run failing tests (expected to fail)
zig build test -Dtest-filter="ansi: parse simple text"

# Green: Run tests again after implementation (should pass)
zig build test -Dtest-filter="ansi"

# Refactor: Clean up code style, extract helpers

# Commit
git add src/parsers/ansi.zig src/parsers/ansi_test.zig
git commit -m "ansi(red-green-refactor): basic text parsing (char, newline, CR, tab, SUB)"
```

### A3: Red Phase 2 — SGR and Colors

**Test Cases** (extend `ansi_test.zig`):

```zig
test "ansi: SGR reset" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "A\x1B[0mB";
    // Parse...
    // Cell A: no attributes
    // Cell B: no attributes (reset applied)
}

test "ansi: SGR bold" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[1mBold\x1B[0mNormal";
    // Parse...
    // Check bold attribute set on "Bold" cells
    // Check bold unset on "Normal" cells
}

test "ansi: SGR 8-color foreground" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[30mBlack\x1B[31mRed\x1B[37mWhite";
    // Parse...
    // Verify palette indices (0, 1, 7)
}

test "ansi: SGR bright colors" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[90mBright Black\x1B[97mBright White";
    // Parse...
    // Verify bright color indices
}

test "ansi: SGR 256-color palette" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[38;5;196mRed\x1B[48;5;21mBlue";
    // Parse...
    // Verify 256-color palette lookups
}

test "ansi: SGR RGB 24-bit color" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[38;2;255;0;0mRed\x1B[48;2;0;0;255mBlue";
    // Parse...
    // Verify RGB color extraction
}
```

**Implementation** (extend `ansi.zig`):

- Add `current_attributes` struct tracking bold, faint, italic, underline, blink, reverse, etc.
- Implement CSI parsing state machine for SGR sequences
- Map SGR codes 0-39, 90-107 to palette indices or RGB
- Apply attributes to cells as they're written

**Commit**:
```bash
git add src/parsers/ansi.zig src/parsers/ansi_test.zig
git commit -m "ansi(red-green-refactor): SGR parsing and color attributes (0,1,2,3,4,5,7,8,9,22,24,25,27,28,29,30-37,40-47,39,49,90-97,100-107,38;5,48;5,38;2,48;2)"
```

### A4: Red Phase 3 — Cursor Positioning

**Test Cases**:

```zig
test "ansi: CUP (H) cursor positioning" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[5;10HX"; // Row 5, Col 10
    // Parse...
    // Verify X is at (10, 5)
}

test "ansi: CUU/CUD/CUF/CUB movements" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[10;10HA\x1B[2AB\x1B[1CC\x1B[3DD";
    // Parse...
    // Verify positions of A, B, C, D relative to movements
}

test "ansi: cursor save/restore" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[5;5HA\x1B[sX\x1B[uB";
    // Parse...
    // A at (5,5), X at (6,5) (after A), B at (5,5) (restored)
}

test "ansi: cursor boundary clamping" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[100;100HX"; // Out of bounds
    // Parse...
    // Verify X is clamped to valid grid bounds
}
```

**Implementation**:

- Extend parser state machine to handle `ESC[` sequences
- Parse numeric parameters (row, col, count)
- Implement CUP, CUU, CUB, CUF, CUD, save/restore cursor
- Add bounds checking

**Commit**:
```bash
git commit -m "ansi(red-green-refactor): cursor positioning (CUP, CUU, CUD, CUF, CUB, save, restore)"
```

### A5: Red Phase 4 — SAUCE Metadata

**Test Cases**:

```zig
test "ansi: SAUCE extraction" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Create a buffer with SAUCE footer
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    try buf.appendSlice("Text content");
    try buf.appendSlice("SAUCE00"); // SAUCE signature
    // ... append SAUCE record fields (128 bytes total)
    
    const parser = try ansi.Parser.init(allocator, buf.items, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // Verify SAUCE metadata extracted
    try expect(doc.sauce != null);
}

test "ansi: SAUCE checksum validation" {
    // Create valid SAUCE record with correct checksum
    // Verify it parses successfully
    
    // Create invalid checksum
    // Verify it's rejected or handled gracefully
}
```

**Implementation**:

- After main parsing, seek to last 128 bytes
- Validate SAUCE signature ("SAUCE00")
- Parse all fields (title, author, group, date, filetype, tinfo1/2, flags)
- Validate checksum
- Extract comment block if present (offset field)

**Commit**:
```bash
git commit -m "ansi(red-green-refactor): SAUCE metadata extraction and validation"
```

### A6: Red Phase 5 — Wrap and Bounds Handling

**Test Cases**:

```zig
test "ansi: implicit wrap at line end" {
    var doc = try ir.Document.init(allocator, 40, 10);
    defer doc.deinit();
    
    const input = "A"; // 40 'A's
    // Parse 41 characters (should wrap to next line)
    // Verify position wrapping
}

test "ansi: wrap at TAB near boundary" {
    var doc = try ir.Document.init(allocator, 40, 10);
    defer doc.deinit();
    
    const input = "1234567\t"; // Tab at col 38, should wrap
    // Verify wrapping behavior
}

test "ansi: overflow scrolling" {
    var doc = try ir.Document.init(allocator, 80, 5);
    defer doc.deinit();
    
    // Generate more lines than grid height
    // Verify content is pushed off top (or grid expands)
}
```

**Implementation**:

- Handle implicit wrap when column reaches width
- Handle TAB wrapping logic
- Determine scrolling vs expanding grid behavior (verify against libansilove)

**Commit**:
```bash
git commit -m "ansi(red-green-refactor): line wrapping, tab positioning, and bounds handling"
```

### A7: Refactor & Integration Tests

After all red/green cycles, consolidate:

**Refactor Tasks**:
- Extract CSI parsing into `parseEscapeSequence()` helper
- Extract SGR handling into `applySGR()` helper
- Extract SAUCE parsing into `parseSauceRecord()` helper
- Clean up state machine complexity
- Add comprehensive doc comments
- Format with `zig fmt`

**Integration Tests** (in `src/parsers/ansi_integration_test.zig`):

```zig
test "ansi: round-trip with sixteencolors fixture" {
    // Load real ANSI file from sixteencolors
    const fixture = @embedFile("../../reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS");
    
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const parser = try ansi.Parser.init(allocator, fixture, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // Verify document is valid and non-empty
    try expect(doc.width == 80 or doc.width == 160);
    try expect(doc.height > 0);
    
    // Optionally: render back to ANSI and compare
}

test "ansi: comparison with libansilove output" {
    // Parse same file with our parser
    // Parse with reference libansilove (if available)
    // Compare cell-by-cell output
}
```

**Commit**:
```bash
git commit -m "ansi(refactor): consolidate helpers, add integration tests, align with sixteencolors corpus"
```

---

## Phase 5B: UTF8ANSI Parser (XP TDD Cycles)

### B1: Test Case Extraction

**Source**: `reference/ghostty/ghostty/src/terminal/Parser.zig` + modern terminal sequences

**Extract Test Cases**:

1. **Basic UTF-8 Handling**
   - Single-byte ASCII
   - Multi-byte UTF-8 sequences (2, 3, 4-byte)
   - Invalid UTF-8 sequences (graceful handling)
   - Combining characters

2. **Extended SGR (Modern Terminals)**
   - SGR 38;2;r;g;b (RGB foreground)
   - SGR 48;2;r;g;b (RGB background)
   - SGR 58;2;r;g;b (Underline color)
   - SGR 1:5 (bright color variations)
   - Ghostty-specific modes

3. **Wrap Flags & Reflow**
   - Soft wrap detection
   - Hard wrap detection
   - Reflow-safe vs reflow-unsafe cells

4. **Hyperlinks (OSC 8)**
   - OSC 8 ; params ; URI ST
   - Parsing URI and params
   - Hyperlink boundary detection

5. **Edge Cases**
   - Incomplete sequences (buffer boundary)
   - Malformed sequences
   - Mixed UTF-8 and ANSI
   - Terminal reset

### B2-B5: Red/Green/Refactor Cycles

Similar structure to ANSI parser:
- **B2**: Basic UTF-8 text + simple SGR
- **B3**: Extended SGR (RGB, underline color, Ghostty modes)
- **B4**: Hyperlinks (OSC 8) and wrap flags
- **B5**: Integration tests with modern terminal output

**Commit Strategy**:
```bash
git commit -m "utf8ansi(red-green-refactor): basic UTF-8 and ASCII parsing"
git commit -m "utf8ansi(red-green-refactor): extended SGR with RGB and underline color"
git commit -m "utf8ansi(red-green-refactor): hyperlink (OSC 8) and wrap flags support"
git commit -m "utf8ansi(refactor): integration tests with modern terminal corpus"
```

---

## Phase 5C: SAUCE Standalone Parser (XP TDD)

### C1: Test Cases

Extract from `reference/pablodraw/pablodraw/` and `reference/ansilove/ansilove/`:

1. **SAUCE Record Format**
   - Signature "SAUCE00" (7 bytes)
   - 128-byte fixed record
   - Field offsets and lengths
   - Checksum validation (CRC-32)

2. **Field Parsing**
   - Title (35 bytes)
   - Author (20 bytes)
   - Group (20 bytes)
   - Date (8 bytes, YYYYMMDD)
   - Filetype (1 byte)
   - tinfo1, tinfo2, tinfo3, tinfo4 (4 bytes)
   - Comments count (1 byte)
   - Flags (1 byte)

3. **Comment Block**
   - Offset to comment block (field in SAUCE)
   - Each comment is 64 bytes
   - Parsing multiple comments

4. **Flags Interpretation**
   - iCE colors mode (bit 0)
   - Letter spacing (bit 1)
   - Aspect ratio (bits 2-3)
   - Font information (bits 4-5)

5. **Edge Cases**
   - Missing SAUCE
   - Partial SAUCE (file too short)
   - Invalid checksum
   - Malformed dates

### C2-C3: Red/Green/Refactor

**C2 Red**: Write tests for full SAUCE parsing

**C2 Green**: Implement minimal SAUCE parser (reuse from Phase 3)

**C3 Refactor**: Extract into standalone module, add comprehensive validation

**Commits**:
```bash
git commit -m "sauce(red-green-refactor): record parsing and checksum validation"
git commit -m "sauce(red-green-refactor): comment block extraction"
git commit -m "sauce(refactor): standalone parser with full field validation"
```

---

## Phase 5D-G: Extended Parsers (Binary, XBin, ArtWorx, PCBoard)

Each follows same pattern as ANSI:

### D: Binary Parser

**Test case extraction from**:
- `reference/libansilove/libansilove/src/loaders/binary.c`
- `reference/pablodraw/pablodraw/Types/Bin.cs`

**XP TDD Cycles**:
- D1 Red: 160-column detection and cell parsing
- D2 Green: Implement minimal binary loader
- D3 Refactor: Consolidate with ANSI patterns
- D4 Integration: sixteencolors fixtures

**Key differences from ANSI**:
- Fixed 160-column width
- No escape sequences (raw cell data)
- Cell format: character + attribute pairs
- Direct attribute (no SGR parsing)

### E: XBin Parser

**Test case extraction from**:
- `reference/libansilove/libansilove/src/loaders/xbin.c`
- `reference/pablodraw/pablodraw/Types/Xbin.cs`

**XP TDD Cycles**:
- E1 Red: XBin header parsing
- E2 Green: Embedded font extraction
- E3 Refactor: Palette handling
- E4 Integration: Real XBin fixtures

**Key complexity**:
- Embedded bitmap fonts (8-16 bytes per char)
- Custom palettes (16/256 color)
- Tile-based rendering hints

### F: ArtWorx Parser

Similar structure, target `reference/libansilove/src/loaders/artworx.c`

### G: PCBoard Parser

Similar structure, target `reference/libansilove/src/loaders/pcboard.c`

---

## Git Commit Strategy

Every XP cycle produces commits at boundaries:

```bash
# Red Phase: Test file only
git commit -m "parser-name(red): test cases for [feature name]"

# Green Phase: Minimal implementation
git commit -m "parser-name(green): minimal implementation to pass [feature] tests"

# Refactor Phase: Code cleanup
git commit -m "parser-name(refactor): consolidate [feature], extract helpers, improve docs"

# Integration Phase: Real-world tests
git commit -m "parser-name(integration): golden tests against sixteencolors corpus"
```

**Example history after ANSI phase**:
```
abc1234 ansi(refactor): consolidate helpers, add integration tests
def5678 ansi(red-green-refactor): line wrapping and bounds handling
ghi9999 ansi(red-green-refactor): SAUCE metadata extraction
jkl2222 ansi(red-green-refactor): cursor positioning
mno3333 ansi(red-green-refactor): SGR parsing and color attributes
pqr4444 ansi(red-green-refactor): basic text parsing
```

---

## Test Validation Checkpoints

### Per XP Cycle

| Step | Command | Expected Output |
|------|---------|-----------------|
| Red | `zig build test -Dtest-filter="..."` | All new tests FAIL |
| Green | `zig build test -Dtest-filter="..."` | All tests PASS |
| Refactor | `zig fmt` | No changes to logic |
| Refactor | `zig build test -Dtest-filter="..."` | All tests still PASS |
| Commit | `git log --oneline -5` | New commits visible |

### After Each Parser Phase

| Step | Command | Notes |
|------|---------|-------|
| Format | `zig fmt src/parsers/**/*.zig` | All files formatted |
| Build | `zig build -Doptimize=Debug` | No warnings |
| Tests | `zig build test` | All tests pass, no leaks |
| Integration | Custom round-trip test | Parse → IR → Render matches libansilove |
| Docs | `zig build docs` | Doc comments complete |

---

## Test Case Adaptation Checklist

### From libansilove

- [ ] `ansi.c`: Extract all test vectors (wrap, SGR, cursor, SAUCE)
- [ ] `binary.c`: Extract 160-col test vectors
- [ ] `pcboard.c`: Extract code-based vector handling
- [ ] `artworx.c`: Extract palette and compression tests
- [ ] `xbin.c`: Extract header and font tests
- [ ] `tundra.c`: Extract sequence tests (deferred)
- [ ] `icedraw.c`: Extract draw command tests (deferred)

### From PabloDraw

- [ ] `Types/Ansi.cs`: Extract sequence edge cases
- [ ] `Types/Bin.cs`: Extract attribute mapping
- [ ] `Types/Xbin.cs`: Extract font storage logic
- [ ] `SauceInfo.cs`: Extract offset calculations
- [ ] `RIPScript.cs`: Extract vector drawing (deferred)

### From sixteencolors-archive

- [ ] Curate 5-10 "golden" ANSI files (diverse styles)
- [ ] Curate 2-3 ANSI animations
- [ ] Curate 1-2 Binary files
- [ ] Curate 1-2 XBin files
- [ ] Document expected rendering in CORPUS.md

---

## Validation & Acceptance Gates

### Exit Criteria (Per Parser)

1. **Red/Green/Refactor Complete**
   - All features tested in isolation
   - Commits logged per cycle
   - Code reviewed for clarity

2. **Integration Tests Pass**
   - Round-trip parse → IR → render
   - Comparison with reference implementation
   - Corpus fixtures parse without error

3. **Build & Test Suite**
   - `zig fmt` passes
   - `zig build` succeeds
   - `zig build test` all green, no leaks
   - `zig build docs` renders cleanly

4. **Golden Snapshot Tests** (Phase 5 only)
   - Parse fixture file
   - Render to Ghostty stream
   - Compare against reference output
   - Document discrepancies

5. **Commit History**
   - Atomic commits (test-first, minimal, refactor)
   - Descriptive messages
   - All work traceable

---

## Success Criteria Mapping

| Requirement | Test Phase | Validation |
|-------------|-----------|------------|
| ANSI format fidelity (AC1) | Phase 5A integration | Parse corpus, compare with libansilove |
| Binary format fidelity (AC2) | Phase 5D integration | Round-trip test with fixtures |
| XBin format fidelity (AC3) | Phase 5E integration | Font and palette preservation |
| UTF8ANSI rendering (AC8) | Phase 5B integration | Ghostty golden tests |
| Serialization round-trip (AC6) | Phase 5 final | Binary format tests |
| Leak-free operation (AC9) | All phases | `std.testing.allocator` reports |
| Doc comments complete (AC10) | All phases | `zig build docs` success |

---

## Risk Mitigation (Updated for XP)

| Risk | Mitigation |
|------|-----------|
| Red phase too ambitious (many failing tests) | Start small: test one feature per Red phase; split if >5 tests fail |
| Green phase "hacky" code | Accept temporary duplication; refactor fixes it |
| Refactor changes behavior | Run all tests after refactor before commit |
| Test corpus missing edge cases | Augment with fuzz tests in Phase 6 |
| Git history becomes noise | Squash if refactor is trivial; keep meaningful commits |

---

## Phase Transition Protocol (Updated)

1. **Complete Red/Green/Refactor cycle** for all planned features
2. **Verify integration tests** against corpus and reference implementations
3. **Run validation checkpoints** (build, test, docs, integration)
4. **Log all commits** and generate summary in STATUS.md
5. **Obtain approval** before advancing to next parser phase

---

## Next Immediate Steps

### Now (Phase 5A: ANSI Parser)

1. Fix ANSI parser skeleton compile issues
2. Extract libansilove + PabloDraw test cases
3. Organize test fixtures
4. Execute Red Phase 1–5 cycles
5. Commit after each phase
6. Consolidate into integration tests

### Then (Phases 5B–5G: Extended Parsers)

Repeat XP TDD cycles for UTF8ANSI, SAUCE, Binary, XBin, ArtWorx, PCBoard parsers.

### Finally (Phase 5 Exit)

- All parsers implemented and tested
- Integration tests green against sixteencolors corpus
- Binary serialization and renderers ready (Phase 5 final)
- Git history shows disciplined XP progression

---

## References

- **libansilove**: `reference/libansilove/libansilove/src/loaders/`
- **ansilove CLI**: `reference/ansilove/ansilove/`
- **PabloDraw**: `reference/pablodraw/pablodraw/`
- **Ghostty**: `reference/ghostty/ghostty/src/terminal/`
- **sixteencolors-archive**: `reference/sixteencolors/`
- **Ansilust IR Design**: `.specs/ir/design.md`
- **Prior Art Notes**: `.specs/ir/prior-art-notes.md`

---

## Appendix: XP Principles

1. **Test-First**: Write failing test before any implementation
2. **Small Steps**: Red → Green → Refactor → Commit cycles of ~30 mins
3. **Continuous Integration**: Build + test after every commit
4. **Simple Design**: Implement only what tests require, refactor to generalize
5. **Pair Review**: (Simulated) review commits for clarity and correctness
6. **Documented Decisions**: Commit messages explain intent
7. **Regression Prevention**: Integration tests guard against regressions

---

## Tracking Progress

| Parser | Phase | Red Tests | Green | Refactor | Integration | Status |
|--------|-------|-----------|-------|----------|-------------|--------|
| ANSI | 5A | 🚧 | ⬜️ | ⬜️ | ⬜️ | TODO |
| UTF8ANSI | 5B | ⬜️ | ⬜️ | ⬜️ | ⬜️ | Blocked on 5A |
| SAUCE | 5C | ⬜️ | ⬜️ | ⬜️ | ⬜️ | Blocked on 5A |
| Binary | 5D | ⬜️ | ⬜️ | ⬜️ | ⬜️ | Blocked on 5A |
| XBin | 5E | ⬜️ | ⬜️ | ⬜️ | ⬜️ | Blocked on 5A |
| ArtWorx | 5F | ⬜️ | ⬜️ | ⬜️ | ⬜️ | Blocked on 5A |
| PCBoard | 5G | ⬜️ | ⬜️ | ⬜️ | ⬜️ | Blocked on 5A |

Update this table after each completed cycle. Record commits in STATUS.md.

---

## Ready for XP Implementation

This plan establishes a disciplined TDD approach with test case extraction from PabloDraw and libansilove, XP Red/Green/Refactor cycles, iterative git commits, and comprehensive integration testing. Proceed with Phase 5A ANSI parser implementation.