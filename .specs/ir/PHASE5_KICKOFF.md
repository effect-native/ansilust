# Phase 5 Kickoff: XP TDD Parser Implementation

**Date**: 2024
**Phase**: 5 (Serialization, Render Bridges, and Parser Implementation)
**Sub-Phase**: 5A (ANSI Parser) - START HERE
**Methodology**: Extreme Programming (XP) Test-Driven Development (TDD)
**Status**: ✅ Ready to begin

---

## What's Changed: Plan Update Summary

The `plan.md` file has been completely restructured for Phase 5 implementation using **Extreme Programming discipline**:

### Before (Traditional Approach)
- General, high-level phases with loose criteria
- Implementation-first mentality
- Validation at phase end
- Risk of scope creep and rework

### After (XP TDD Approach)
- **Test-first methodology**: Write failing tests BEFORE any code
- **Red/Green/Refactor cycles**: Explicit templates with step-by-step instructions
- **Atomic git commits**: A commit at every cycle boundary
- **Continuous validation**: Build, test, docs, integration checks after every commit
- **Test case extraction**: Comprehensive test cases sourced from libansilove and PabloDraw
- **Incremental delivery**: Each cycle produces working, tested code

---

## Documents Created

Three supporting documents now guide Phase 5 implementation:

### 1. `.specs/ir/plan.md` (Updated)
**Purpose**: Complete Phase 5 implementation plan using XP TDD methodology

**Sections**:
- Overview: Kent Beck XP TDD methodology
- Test corpus & fixture strategy
- Red → Green → Refactor cycle templates
- Phase 5 structure (MVP, Extended, Deferred)
- Git commit strategy with message format
- Validation checkpoints for every commit
- Success criteria mapping
- Risk mitigation strategies

**How to use**: Detailed reference guide for each parser phase. Consult when implementing specific features.

### 2. `.specs/ir/PHASE5_XP_TDD_SUMMARY.md` (New)
**Purpose**: Executive summary and quick-start guide

**Sections**:
- XP TDD methodology explained simply
- Test case sources (libansilove, PabloDraw, sixteencolors)
- Phase 5 structure overview (MVP → Extended → Deferred)
- Commit strategy with examples
- Validation checkpoints
- Expected timeline
- Next immediate steps
- Common questions and answers

**How to use**: Read first to understand the approach. Reference when questions arise.

### 3. `.specs/ir/TEST_CASE_MAPPING.md` (New)
**Purpose**: Comprehensive test case extraction from reference implementations

**Sections**:
- Part 1: ANSI Parser test cases (from libansilove/ansi.c)
  - Character handling (TAB, CR, LF, SUB, CP437)
  - SGR parsing (bold, colors, RGB)
  - Cursor positioning (CUP, CUU, CUD, etc.)
  - Edge cases and error handling
  - SAUCE metadata integration
- Part 2: SAUCE Parser test cases (from PabloDraw/SauceInfo.cs)
- Part 3: Binary Parser test cases (from libansilove/binary.c)
- Part 4: XBin, ArtWorx, PCBoard parser test cases
- Part 5: Integration and corpus tests
- Part 6: Implementation workflow

**How to use**: When implementing a parser, refer to the corresponding section to understand what tests to write first.

---

## Quick-Start: Phase 5A ANSI Parser

### Right Now (15 minutes)

1. **Read the approach**:
   ```bash
   cat .specs/ir/PHASE5_XP_TDD_SUMMARY.md | less
   ```

2. **Understand test case sources**:
   - Open `reference/libansilove/libansilove/src/loaders/ansi.c`
   - Scan the `main_ansi()` function and parsing state machine
   - Note the different escape sequence types and special characters

3. **Review test cases**:
   ```bash
   cat .specs/ir/TEST_CASE_MAPPING.md | less  # Focus on Part 1: ANSI Parser
   ```

### Next (1-2 hours)

#### Step 1: Create Test File (30 min)

```bash
# Create the ANSI parser test file
touch src/parsers/ansi_test.zig

# Add minimal test template
cat > src/parsers/ansi_test.zig << 'EOF'
const std = @import("std");
const ir = @import("../ir/lib.zig");
const ansi = @import("ansi.zig");

const expect = std.testing.expect;

test "ansi: plain text rendering" {
    var doc = try ir.Document.init(std.testing.allocator, 80, 25);
    defer doc.deinit();

    const input = "Hello, World!";
    const parser = try ansi.Parser.init(std.testing.allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();

    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'H');
}

test "ansi: newline handling" {
    var doc = try ir.Document.init(std.testing.allocator, 80, 25);
    defer doc.deinit();

    const input = "Line1\nLine2";
    const parser = try ansi.Parser.init(std.testing.allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();

    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'L');

    cell = try doc.getCell(0, 1);
    try expect(cell.contents.scalar == 'L');
}

test "ansi: carriage return" {
    var doc = try ir.Document.init(std.testing.allocator, 80, 25);
    defer doc.deinit();

    const input = "AB\rC";
    const parser = try ansi.Parser.init(std.testing.allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();

    var cell = try doc.getCell(1, 0);
    try expect(cell.contents.scalar == 'C');  // C overwrote B
}

test "ansi: tab character handling" {
    var doc = try ir.Document.init(std.testing.allocator, 80, 25);
    defer doc.deinit();

    const input = "AB\tC";
    const parser = try ansi.Parser.init(std.testing.allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();

    var cell = try doc.getCell(8, 0);
    try expect(cell.contents.scalar == 'C');  // Tab advances to column 8
}

test "ansi: SUB termination" {
    var doc = try ir.Document.init(std.testing.allocator, 80, 25);
    defer doc.deinit();

    var buf = try std.testing.allocator.alloc(u8, 5);
    defer std.testing.allocator.free(buf);
    buf[0] = 'A';
    buf[1] = 'B';
    buf[2] = 0x1A;  // SUB
    buf[3] = 'C';
    buf[4] = 'D';

    const parser = try ansi.Parser.init(std.testing.allocator, buf, &doc);
    defer parser.deinit();
    try parser.parse();

    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'A');

    cell = try doc.getCell(2, 0);
    try expect(cell.contents.scalar == 0);  // C never written
}
EOF
```

#### Step 2: Run RED Phase Tests (5 min)

```bash
# Should fail with "undefined reference" or similar
zig build test -Dtest-filter="ansi"
```

**Expected output**: All tests FAIL. This is correct (RED phase).

```bash
# Commit the RED phase
git add src/parsers/ansi_test.zig
git commit -m "RED: Add ANSI parser tests for plain text (5 test cases)

Add failing tests:
- plain text rendering
- newline handling
- carriage return
- tab character handling
- SUB termination

These tests will drive the ANSI parser implementation in the GREEN phase.

Refs: #42"
```

#### Step 3: Implement GREEN Phase (1 hour)

Create `src/parsers/ansi.zig`:

```bash
cat > src/parsers/ansi.zig << 'EOF'
const std = @import("std");
const ir = @import("../ir/lib.zig");

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
                    self.col = (self.col + 8) & ~@as(u16, 7);
                    if (self.col >= self.document.width) {
                        self.row += 1;
                        self.col = 0;
                    }
                },
                0x1A => break,  // SUB (EOF)
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
EOF
```

Update `src/parsers/lib.zig` to export the ANSI parser:

```bash
# If lib.zig doesn't exist, create it
cat > src/parsers/lib.zig << 'EOF'
pub const ansi = @import("ansi.zig");
EOF
```

#### Step 4: Run GREEN Phase Tests (5 min)

```bash
# Should pass
zig build test -Dtest-filter="ansi"
```

**Expected output**: All tests PASS. ✅

```bash
# Commit the GREEN phase
git add src/parsers/ansi.zig src/parsers/lib.zig
git commit -m "GREEN: Implement minimal ANSI text parser

Implement plain character handling:
- TAB: Advance 8 columns with wrapping
- CR: Reset column to 0
- LF: Advance row, reset column
- SUB: Terminate parsing
- Regular ASCII: Write to cell grid

All 5 RED tests pass.

Refs: #42"
```

#### Step 5: REFACTOR Phase (30 min)

Extract helpers:

```bash
cat > src/parsers/ansi.zig << 'EOF'
const std = @import("std");
const ir = @import("../ir/lib.zig");

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
            try self.parseCharacter(byte);
            self.pos += 1;
        }
    }

    fn parseCharacter(self: *Parser, byte: u8) !void {
        switch (byte) {
            '\n' => self.handleNewline(),
            '\r' => self.handleCarriageReturn(),
            '\t' => self.handleTab(),
            0x1A => self.stopParsing(),
            else => try self.writeCharacter(byte),
        }
    }

    fn handleNewline(self: *Parser) void {
        self.row += 1;
        self.col = 0;
    }

    fn handleCarriageReturn(self: *Parser) void {
        self.col = 0;
    }

    fn handleTab(self: *Parser) void {
        self.col = (self.col + 8) & ~@as(u16, 7);
        if (self.col >= self.document.width) {
            self.row += 1;
            self.col = 0;
        }
    }

    fn stopParsing(self: *Parser) void {
        self.pos = self.input.len;
    }

    fn writeCharacter(self: *Parser, byte: u8) !void {
        if (self.col >= self.document.width) {
            self.row += 1;
            self.col = 0;
        }
        try self.document.setCell(self.col, self.row, .{
            .contents = .{ .scalar = byte },
        });
        self.col += 1;
    }
};
EOF
```

```bash
# Verify tests still pass
zig build test -Dtest-filter="ansi"
zig fmt src/parsers/ansi.zig

# Commit the REFACTOR phase
git add src/parsers/ansi.zig
git commit -m "REFACTOR: Extract character handling helpers

- Extract parseCharacter() method
- Create handleNewline(), handleCarriageReturn(), handleTab(), stopParsing()
- Create writeCharacter() helper with bounds checking
- Improve code clarity and testability

All 5 tests still pass.

Refs: #42"
```

### After Completing First Cycle (Next Work Session)

Continue with cycles 2-5:

1. **Cycle 2**: SGR parsing (bold, faint, colors, attributes)
2. **Cycle 3**: Cursor positioning (CUP, CUU, CUD, CUF, CUB, save/restore)
3. **Cycle 4**: SAUCE metadata integration
4. **Cycle 5**: Wrapping, scrolling, bounds handling
5. **Integration**: Golden tests with sixteencolors corpus

Each cycle follows the same pattern:
1. Write failing tests (RED)
2. Implement minimal code (GREEN)
3. Extract helpers and improve (REFACTOR)
4. Commit with descriptive message

---

## Git History After Phase 5A

Expected commit history after completing ANSI parser:

```
abc1234 ansi(integration): add corpus golden tests (sixteencolors)
def5678 ansi(refactor): consolidate SGR parsing helpers
ghi9999 ansi(red-green-refactor): wrap, scroll, and bounds handling
jkl2222 ansi(red-green-refactor): SAUCE metadata extraction
mno3333 ansi(red-green-refactor): cursor positioning (CUP, CUU, CUD, etc.)
pqr4444 ansi(red-green-refactor): SGR parsing (bold, colors, 256-color, RGB)
stu5555 ansi(refactor): extract character handling helpers
vwx6666 GREEN: implement minimal ANSI text parser
yza7777 RED: add ANSI parser tests for plain text (5 test cases)
```

**Key observations**:
- Each feature gets RED/GREEN/REFACTOR cycles
- Commits are atomic and descriptive
- Git history shows exactly how parser evolved
- Easy to bisect bugs or revert problematic changes
- Tests validate every commit

---

## Validation Checklist

After each cycle, before committing:

```bash
# 1. Format code
zig fmt src/parsers/**/*.zig

# 2. Build (debug with safety checks)
zig build -Doptimize=Debug

# 3. Full build
zig build

# 4. Run all tests (watch for memory leaks)
zig build test

# 5. Generate documentation
zig build docs

# If any step fails, fix before committing
```

---

## Success Metrics (Phase 5A)

Track progress in `STATUS.md`:

```markdown
## Phase 5A: ANSI Parser ✅ COMPLETE

- **Cycles**: 5 (basic text, SGR, cursor, SAUCE, wrapping)
- **Commits**: 16 (5 RED, 5 GREEN, 5 REFACTOR, 1 integration)
- **Test Cases**: 75 (all passing)
- **Memory Leaks**: 0 (verified)
- **Build Status**: ✅ Passing
- **Test Status**: ✅ Passing
- **Docs Status**: ✅ Passing
- **Integration Tests**: ✅ Passing (137 corpus files)
- **Time**: ~12 hours

**Next Phase**: Phase 5B (UTF8ANSI Parser)
```

---

## Common Questions

**Q: "I'm in the middle of a cycle. Should I commit?"**
A: Yes, always commit at cycle boundaries (after RED, after GREEN, after REFACTOR). Don't commit in the middle.

**Q: "What if I find a bug while refactoring?"**
A: Don't fix it during REFACTOR. Create a new RED phase test that catches it, then implement a fix.

**Q: "Can I combine RED and GREEN?"**
A: No. RED must have only the test. GREEN must have only the minimal implementation. This discipline ensures we stay test-driven.

**Q: "What if the test is wrong?"**
A: Fix the test first (it's still in RED phase), then implement. Tests should define the spec.

**Q: "Should I test everything?"**
A: Test the important cases. Aim for 70-80% coverage. Perfect coverage requires diminishing effort.

**Q: "Can I skip REFACTOR if code is already clean?"**
A: Even if code looks clean, there's often value in extracting helpers, improving variable names, or adding comments.

---

## Next Steps Summary

1. **Now (15 min)**: Read PHASE5_XP_TDD_SUMMARY.md
2. **Today (1-2 hours)**: Complete first Red/Green/Refactor cycle (plain text parsing)
3. **This week (4 cycles)**: Complete SGR, cursor, SAUCE, wrapping cycles
4. **Next week (integration)**: Add golden tests with corpus fixtures
5. **Then (Phase 5B)**: Start UTF8ANSI parser with same methodology

---

## References

- **Full Plan**: `.specs/ir/plan.md` (detailed reference guide)
- **XP Summary**: `.specs/ir/PHASE5_XP_TDD_SUMMARY.md` (executive summary)
- **Test Cases**: `.specs/ir/TEST_CASE_MAPPING.md` (test case extraction guide)
- **Source Code**: `reference/libansilove/libansilove/src/loaders/ansi.c` (reference)
- **Status**: `STATUS.md` (update after each phase)

---

## Ready to Start? 🚀

Follow the **Quick-Start** section above to begin Phase 5A RIGHT NOW with the first Red/Green/Refactor cycle.

Expected time to first commit: **~30 minutes**

Let's build Phase 5 with discipline and confidence!

---

**Last Updated**: 2025-10-26
**Status**: ✅ Ready for Phase 5A implementation
**Methodology**: Extreme Programming (XP) Test-Driven Development (TDD)
**Commit Strategy**: Atomic commits after every cycle boundary
