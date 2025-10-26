# Phase 5 XP TDD Implementation Summary

## What Changed in plan.md

The plan has been restructured to implement **Phase 5 (Parser Implementation)** using **Extreme Programming (XP) Test-Driven Development (TDD)** methodology:

### Before
- Traditional waterfall-style phases with loose validation gates
- Implementation-first approach (code before tests)
- General success criteria without specific test case sources

### After
- **Strict test-first discipline**: Write failing tests before any implementation
- **Red → Green → Refactor cycles**: Explicit templates for each feature
- **Atomic git commits**: A commit after every phase boundary (RED, GREEN, REFACTOR)
- **Test case extraction**: Comprehensive test cases from PabloDraw, libansilove, and sixteencolors-archive
- **Validation checkpoints**: Build, test, docs, and integration gates on every commit
- **Detailed success mapping**: Requirements tied to specific test phases

---

## XP TDD Methodology (Kent Beck)

### The Cycle (Per Feature)

1. **RED Phase**: Write a failing test
   - Test specifies expected behavior
   - Implementation doesn't exist yet
   - Test fails (expected)
   - **Commit**: `git commit -m "RED: Add failing test for [feature]"`

2. **GREEN Phase**: Implement minimal code to pass the test
   - Write only code needed to pass the test
   - No optimization, no generalization, no speculation
   - All tests pass (expected)
   - **Commit**: `git commit -m "GREEN: Implement minimal [feature] to pass test"`

3. **REFACTOR Phase**: Clean up code without changing behavior
   - Extract helpers, improve clarity, optimize
   - Tests still pass (expected)
   - **Commit**: `git commit -m "REFACTOR: Improve [feature] implementation"`

### Benefits
- **Regression Prevention**: Tests catch breaking changes immediately
- **Documentation**: Tests serve as executable specifications
- **Design Emerges**: Architecture grows from requirements, not speculation
- **Atomic History**: Every commit is a working state; easy to bisect bugs
- **Confidence**: Green tests mean code works (within test coverage)

---

## Test Case Sources

### libansilove (`reference/libansilove/libansilove/`)
C reference implementation of classic BBS art parsers:
- `src/loaders/ansi.c` → ANSI escape sequence parsing
- `src/loaders/binary.c` → 160-column binary format
- `src/loaders/pcboard.c` → PCBoard @XX color codes
- `src/loaders/xbin.c` → XBin with embedded fonts
- `src/loaders/artworx.c` → ArtWorx format with palettes
- `src/loaders/sauce.c` → SAUCE metadata parsing

**Usage**: Extract test vectors, expected outputs, edge case handling

### PabloDraw (`reference/pablodraw/pablodraw/`)
Comprehensive C# text art editor with proven format support:
- `Types/Ansi.cs` → ANSI sequence handling and edge cases
- `Types/Bin.cs` → Binary attribute mapping and iCE colors
- `Types/Xbin.cs` → Font storage and palette handling
- `SauceInfo.cs` → SAUCE field offset calculations and validation
- `RIPScript.cs` → Vector drawing support (future)

**Usage**: Validate test cases against real-world implementation, test edge cases

### sixteencolors-archive (`reference/sixteencolors/`)
Golden file corpus (35 MB, 137+ ANSI files):
- 1996 artpacks (ACiD, iCE, Fire)
- Diverse styles and techniques
- Real-world complexity and edge cases
- Expected render output for golden tests

**Usage**: Integration testing, regression prevention, golden snapshot tests

---

## Phase 5 Structure

### MVP Scope (Phase 5A–5C)
Three parsers needed for basic functionality:

1. **Phase 5A: ANSI Parser** (16 commits planned)
   - Test case extraction (RED phase setup)
   - 5 Red/Green/Refactor cycles
   - Integration tests with sixteencolors
   - ~75 test cases total

2. **Phase 5B: UTF8ANSI Parser** (5 commits planned)
   - Modern terminal sequences (Ghostty-aligned)
   - UTF-8, wide characters, combining chars
   - Hyperlinks (OSC 8)
   - ~15 test cases

3. **Phase 5C: SAUCE Standalone Parser** (3 commits planned)
   - 128-byte record + comment blocks
   - Field validation and checksums
   - ~8 test cases

### Extended Scope (Phase 5D–5G, lower priority)
Additional parsers for format completeness:

4. **Phase 5D: Binary Parser** (4 commits)
5. **Phase 5E: XBin Parser** (5 commits)
6. **Phase 5F: ArtWorx Parser** (4 commits)
7. **Phase 5G: PCBoard Parser** (4 commits)

### Deferred (Future phases)
- Tundra Parser
- iCE Draw Parser
- RIPScript Parser
- Renderers (UTF8ANSI, HTML Canvas, OpenTUI, PNG)

---

## Commit Strategy

### Commit Message Format
```
<TYPE>: <SUBJECT>

<BODY>

<FOOTER>
```

### Types & Examples

```bash
# RED: Add failing test
git commit -m "RED: Add failing test for ANSI SGR bold attribute

Add 3 test cases:
- SGR 1 (bold on)
- SGR 22 (bold off)
- Mixed bold + color

These tests will drive SGR implementation.

Refs: #42"

# GREEN: Implement feature to pass test
git commit -m "GREEN: Implement ANSI SGR bold attribute handling

Parse ESC[1m and ESC[22m sequences.
Track bold state in parser.
Apply to cells as they're written.

Passes all 3 RED tests.

Refs: #42"

# REFACTOR: Improve code without changing behavior
git commit -m "REFACTOR: Extract SGR parsing into helper function

Create applySGR(code: u8, state: *ParserState) function.
Consolidate all SGR handling logic.
Improve clarity and testability.

All tests still pass.

Refs: #42"
```

### Commit Frequency
- **RED phase**: Commit immediately after writing tests (1-5 tests per commit)
- **GREEN phase**: Commit immediately after tests pass
- **REFACTOR phase**: Commit after each logical improvement (extract helper, improve error handling, etc.)
- **INTEGRATION phase**: Commit after adding golden tests with corpus fixtures

---

## Example: Phase 5A ANSI Parser Cycles

### A1: Test Case Extraction (setup)
Extract from `reference/libansilove/libansilove/src/loaders/ansi.c`:
- Character handling (TAB, CR, LF, SUB, CP437)
- Cursor positioning (CUP, CUU, CUD, CUF, CUB, save/restore)
- SGR attributes (bold, faint, italic, underline, colors)
- Edge cases (wrap, bounds, malformed sequences)
- SAUCE metadata extraction

### A2–A7: Red/Green/Refactor Cycles

**Cycle 1: Basic Text**
```bash
git commit -m "RED: Add ANSI parser tests for plain text (5 cases)"
git commit -m "GREEN: Implement text rendering to IR cells"
git commit -m "REFACTOR: Add character handling (TAB, CR, LF, SUB)"
```

**Cycle 2: SGR and Colors**
```bash
git commit -m "RED: Add ANSI parser tests for SGR (20 cases)"
git commit -m "GREEN: Implement SGR parsing and attribute application"
git commit -m "REFACTOR: Extract applySGR helper, improve state tracking"
```

**Cycle 3: Cursor Control**
```bash
git commit -m "RED: Add ANSI parser tests for cursor (8 cases)"
git commit -m "GREEN: Implement CUP, CUU, CUD, CUF, CUB, save/restore"
git commit -m "REFACTOR: Extract parseCursorSequence helper"
```

**Cycle 4: SAUCE Integration**
```bash
git commit -m "RED: Add ANSI parser tests for SAUCE (4 cases)"
git commit -m "GREEN: Implement SAUCE extraction and hint application"
git commit -m "REFACTOR: Extract sauce parsing into standalone function"
```

**Cycle 5: Wrapping & Bounds**
```bash
git commit -m "RED: Add ANSI parser tests for wrapping (6 cases)"
git commit -m "GREEN: Implement implicit wrapping and bounds clamping"
git commit -m "REFACTOR: Consolidate bounds checking logic"
```

**Final: Integration Tests**
```bash
git commit -m "INTEGRATION: Add corpus golden tests for sixteencolors ANSI files"
```

---

## Validation Checkpoints (Every Commit)

Before committing, run:

```bash
# Format code
zig fmt src/parsers/**/*.zig

# Build with safety checks
zig build -Doptimize=Debug

# Full build
zig build

# Run all tests (watch for leaks)
zig build test

# Generate docs
zig build docs
```

**Failure at any checkpoint blocks the commit.** Fix issues, then commit.

---

## Success Criteria

### Per XP Cycle
- ✅ RED: All tests fail (expected)
- ✅ GREEN: All tests pass
- ✅ REFACTOR: Tests still pass, code is cleaner
- ✅ COMMIT: Git history shows atomic, meaningful commits

### Per Parser Phase
- ✅ All test cases pass (no leaks)
- ✅ Integration tests green (corpus fixtures parse without error)
- ✅ Round-trip tests validate (parse → IR → render)
- ✅ Comparison with reference (libansilove, PabloDraw outputs)
- ✅ Build/docs/format gates all pass

### Final (Phase 5 Exit)
- ✅ All parsers implemented and tested (MVP + Extended)
- ✅ ~200+ unit tests across all parsers
- ✅ Integration tests against sixteencolors corpus (137+ files)
- ✅ Golden snapshot tests for Ghostty renderer
- ✅ Git history shows disciplined XP progression
- ✅ Zero memory leaks (validated with `std.testing.allocator`)

---

## Next Immediate Steps (Now)

### 1. Start Phase 5A: ANSI Parser

**Right now (RED phase setup)**:
```bash
cd ansilust/

# 1. Create test file structure
mkdir -p src/parsers/tests/ansi_fixtures/{red_phase,green_phase,refactor_phase}

# 2. Create test case file
touch src/parsers/ansi_test.zig

# 3. Extract ANSI test cases from libansilove
# - Read reference/libansilove/libansilove/src/loaders/ansi.c
# - Identify test vectors and edge cases
# - Document in src/parsers/tests/ansi_test_cases.md

# 4. Create first RED phase test
# - Write 3-5 failing tests for "plain text" feature
# - Commit: "RED: Add ANSI parser tests for plain text"

# 5. Implement GREEN
# - Add minimal parser implementation
# - Run tests until they pass
# - Commit: "GREEN: Implement plain text parsing"

# 6. Refactor
# - Extract helpers, improve clarity
# - Ensure tests still pass
# - Commit: "REFACTOR: Improve text parsing implementation"

# 7. Repeat for SGR, Cursor, SAUCE, Wrapping
```

### 2. Document Test Cases

Create `src/parsers/tests/ansi_test_cases.md`:
- List all test cases extracted from libansilove
- Map to Zig test functions
- Include expected inputs/outputs

### 3. Validate Build

Ensure project still builds:
```bash
zig build
zig build test
```

### 4. Execute First RED Phase

Write first batch of tests (plain text handling):
```bash
git commit -m "RED: Add ANSI parser tests for plain text (5 cases)"
```

---

## Key References

- **Plan Details**: `.specs/ir/plan.md` (Sections 3-10)
- **Prior Art**: `.specs/ir/prior-art-notes.md` (libansilove + PabloDraw deep dive)
- **IR Design**: `.specs/ir/design.md` (Cell grid, encoding, color model)
- **Corpus**: `.specs/CORPUS.md` (sixteencolors documentation)
- **Architecture**: `AGENTS.md` (Complete project architecture)

---

## Expected Timeline

### Phase 5A (ANSI Parser)
- **RED phases**: 5 × ~30 min = 2.5 hours
- **GREEN phases**: 5 × ~1 hour = 5 hours
- **REFACTOR phases**: 5 × ~30 min = 2.5 hours
- **INTEGRATION**: ~2 hours
- **Total**: ~12 hours (spread over 3–4 work sessions)

### Phase 5B–5C (UTF8ANSI, SAUCE)
- **Each**: ~4–6 hours (similar structure, fewer cycles)
- **Total**: ~10 hours

### Phase 5D–5G (Extended Parsers)
- **Each**: ~6–8 hours (more complex formats)
- **Total**: ~28 hours

### Phase 5 Total
- **MVP (5A–5C)**: ~22 hours
- **Extended (5D–5G)**: ~28 hours
- **Full scope**: ~50 hours

---

## Success Metrics

Track in STATUS.md after each phase:

```markdown
## Phase 5A: ANSI Parser ✅ COMPLETE

- **Commits**: 16 (5 RED, 5 GREEN, 5 REFACTOR, 1 INTEGRATION)
- **Test Cases**: 75 (all passing)
- **Memory Leaks**: 0 (verified with std.testing.allocator)
- **Build Status**: ✅ Passing
- **Test Status**: ✅ Passing
- **Docs Status**: ✅ Passing
- **Integration Tests**: ✅ Passing (137 corpus files parse without error)
- **Time**: ~12 hours

**Key Learnings**:
- [Notes on what we learned implementing ANSI parser]

**Next Phase**: Phase 5B (UTF8ANSI Parser)
```

---

## Questions & Support

**Q: What if a RED test is too ambitious (>5 failing tests)?**  
A: Split into smaller Red phases. One Red phase should test one feature.

**Q: What if I find a bug while refactoring?**  
A: Write a failing test that catches it (new RED phase). Don't refactor past the bug.

**Q: What about the existing ANSI parser skeleton?**  
A: Use it as reference, but start fresh with RED phase. Tests will drive reimplementation.

**Q: How strict are the validation checkpoints?**  
A: Strict. No commit without passing `zig fmt`, `zig build`, `zig build test`, `zig build docs`.

**Q: What if a sixteencolors file fails to parse?**  
A: Document as a golden snapshot failure. Add a specific test case to RED phase. Don't ship broken parser.

---

## Go Forth & Test-Drive! 🧪

This summary captures the essence of the XP TDD approach now embedded in plan.md. Follow the Red/Green/Refactor cycles, commit atomically, validate at every checkpoint, and rely on test cases from proven reference implementations.

**The goal**: Build Phase 5 with discipline, confidence, and a clean git history that shows exactly how the parsers evolved through test-driven development.

See you in Phase 5A! 🚀