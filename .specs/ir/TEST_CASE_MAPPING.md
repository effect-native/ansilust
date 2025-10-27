# Test Case Mapping: libansilove & PabloDraw → Zig

**Purpose**: Guide for systematically extracting and adapting test cases from reference implementations to Zig test format.

**Status**: Phase 5A (ANSI Parser) - Focus on libansilove/src/loaders/ansi.c

---

## Overview: Extraction Workflow

```
Reference Implementation (C/C#)
        ↓
    Extract Test Vectors
        ↓
    Document Test Cases
        ↓
    Adapt to Zig Format
        ↓
    Organize in Test Suite
        ↓
    Execute Red/Green/Refactor
```

---

## Part 1: ANSI Parser Test Cases (from libansilove/ansi.c)

### 1.1 Character Handling Tests

#### Source: libansilove/src/loaders/ansi.c

**Original C Code**:
```c
// Handle special characters
if (byte == 0x09) {  // TAB
    column = (column + 8) & ~7;
    if (column >= width) {
        row++;
        column = 0;
    }
} else if (byte == 0x0A) {  // LF
    row++;
    column = 0;
} else if (byte == 0x0D) {  // CR
    column = 0;
} else if (byte == 0x1A) {  // SUB (EOF)
    break;
}
```

**Zig Test Adaptation**:
```zig
test "ansi: TAB character advances 8 columns" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Input: "AB\tC" (A at col 0, B at col 1, tab advances to col 8, C at col 8)
    const input = "AB\tC";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // Verify positions
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(1, 0);
    try expect(cell.contents.scalar == 'B');
    
    cell = try doc.getCell(8, 0);
    try expect(cell.contents.scalar == 'C');
}

test "ansi: TAB near boundary wraps to next line" {
    var doc = try ir.Document.init(allocator, 40, 25);
    defer doc.deinit();
    
    // Input: 38 chars + TAB (should wrap to next line)
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    for (0..38) |_| try buf.append('A');
    try buf.append('\t');
    
    const parser = try ansi.Parser.init(allocator, buf.items, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // Verify wrap to row 1
    var cell = try doc.getCell(0, 1);
    try expect(cell.contents.scalar == 0);  // Empty after wrap
}

test "ansi: CR resets column to 0" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Input: "ABCD\rXYZ" (ABCD written, CR resets, XYZ overwrites AB)
    const input = "ABCD\rXYZ";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // Verify overwrite
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'X');  // Overwrote A
    
    cell = try doc.getCell(1, 0);
    try expect(cell.contents.scalar == 'Y');  // Overwrote B
    
    cell = try doc.getCell(2, 0);
    try expect(cell.contents.scalar == 'Z');  // New
    
    cell = try doc.getCell(3, 0);
    try expect(cell.contents.scalar == 'D');  // Still there
}

test "ansi: LF advances row and resets column" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Input: "AB\nCD"
    const input = "AB\nCD";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(1, 0);
    try expect(cell.contents.scalar == 'B');
    
    cell = try doc.getCell(0, 1);
    try expect(cell.contents.scalar == 'C');  // Row 1, Col 0
    
    cell = try doc.getCell(1, 1);
    try expect(cell.contents.scalar == 'D');
}

test "ansi: SUB (0x1A) terminates parsing" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Input: "AB\x1ACD" (should only parse AB, stop at SUB)
    var buf = try allocator.alloc(u8, 5);
    defer allocator.free(buf);
    buf[0] = 'A';
    buf[1] = 'B';
    buf[2] = 0x1A;  // SUB
    buf[3] = 'C';
    buf[4] = 'D';
    
    const parser = try ansi.Parser.init(allocator, buf, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(1, 0);
    try expect(cell.contents.scalar == 'B');
    
    cell = try doc.getCell(2, 0);
    try expect(cell.contents.scalar == 0);  // C never written
}
```

**Test Organization**:
```
src/parsers/tests/
├── ansi_test.zig
│   ├── test "ansi: TAB character advances 8 columns"
│   ├── test "ansi: TAB near boundary wraps to next line"
│   ├── test "ansi: CR resets column to 0"
│   ├── test "ansi: LF advances row and resets column"
│   └── test "ansi: SUB (0x1A) terminates parsing"
└── fixtures/
    ├── plain_text.ans          (simple ASCII)
    ├── tab_wrap.ans            (tab near boundary)
    ├── cr_overwrite.ans        (carriage return)
    └── sub_termination.ans     (SUB character EOF)
```

---

### 1.2 SGR (Select Graphic Rendition) Tests

#### Source: libansilove/src/loaders/ansi.c & PabloDraw/Types/Ansi.cs

**Original C Code**:
```c
// Parse SGR codes
if (sgr_code == 0) {
    // Reset all attributes
    current_attr = DEFAULT_ATTR;
} else if (sgr_code == 1) {
    current_attr.bold = 1;
} else if (sgr_code == 2) {
    current_attr.faint = 1;
} else if (sgr_code >= 30 && sgr_code <= 37) {
    // 8 foreground colors
    current_attr.fg_color = sgr_code - 30;
} else if (sgr_code >= 40 && sgr_code <= 47) {
    // 8 background colors
    current_attr.bg_color = sgr_code - 40;
} else if (sgr_code >= 90 && sgr_code <= 97) {
    // Bright foreground
    current_attr.fg_color = (sgr_code - 90) + 8;
} else if (sgr_code >= 100 && sgr_code <= 107) {
    // Bright background
    current_attr.bg_color = (sgr_code - 100) + 8;
}
```

**Zig Test Adaptation**:
```zig
test "ansi: SGR reset (0) clears all attributes" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Input: ESC[1mBold\x1B[0mNormal
    const input = "\x1B[1mBold\x1B[0mNormal";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // "Bold" should have bold attribute
    var cell = try doc.getCell(0, 0);
    try expect(cell.attributes.bold == 1);
    
    // "Normal" should not have bold
    cell = try doc.getCell(5, 0);  // "Normal" starts after "Bold\0"
    try expect(cell.attributes.bold == 0);
}

test "ansi: SGR bold (1)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[1mBold";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.attributes.bold == 1);
}

test "ansi: SGR faint (2)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[2mFaint";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.attributes.faint == 1);
}

test "ansi: SGR italic (3)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[3mItalic";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.attributes.italic == 1);
}

test "ansi: SGR underline (4)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[4mUnderline";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.attributes.underline != .none);
}

test "ansi: SGR blink (5)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[5mBlink";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.attributes.blink == 1);
}

test "ansi: SGR 8-color foreground (30-37)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // ESC[30m=black, ESC[31m=red, ... ESC[37m=white
    const colors = [8]u8{ 30, 31, 32, 33, 34, 35, 36, 37 };
    for (colors, 0..) |code, idx| {
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();
        try buf.writer().print("\x1B[{}mX", .{code});
        
        var doc_tmp = try ir.Document.init(allocator, 80, 25);
        defer doc_tmp.deinit();
        
        const parser = try ansi.Parser.init(allocator, buf.items, &doc_tmp);
        defer parser.deinit();
        try parser.parse();
        
        var cell = try doc_tmp.getCell(0, 0);
        try expect(cell.fg_color.palette == @as(u8, @intCast(idx)));
    }
}

test "ansi: SGR 8-color background (40-47)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[40mBlackBG\x1B[47mWhiteBG";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.bg_color.palette == 0);  // Black
    
    cell = try doc.getCell(0, 1);
    try expect(cell.bg_color.palette == 7);  // White
}

test "ansi: SGR bright foreground (90-97)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[90mBright Black\x1B[97mBright White";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.fg_color.palette == 8);  // Bright black
}

test "ansi: SGR bright background (100-107)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    const input = "\x1B[100mBright Black BG\x1B[107mBright White BG";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.bg_color.palette == 8);  // Bright black BG
}

test "ansi: SGR 256-color foreground (38;5;n)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // ESC[38;5;196m = Red (256-color palette)
    const input = "\x1B[38;5;196mRed";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.fg_color.palette == 196);
}

test "ansi: SGR RGB foreground (38;2;r;g;b)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // ESC[38;2;255;0;0m = Red (RGB)
    const input = "\x1B[38;2;255;0;0mRed";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.fg_color.rgb.r == 255);
    try expect(cell.fg_color.rgb.g == 0);
    try expect(cell.fg_color.rgb.b == 0);
}

test "ansi: SGR default foreground (39)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // ESC[31mRed\x1B[39mDefault
    const input = "\x1B[31mRed\x1B[39mDefault";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.fg_color == .none);  // Back to default
}

test "ansi: SGR multiple attributes in one sequence" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // ESC[1;31;40m = bold + red fg + black bg
    const input = "\x1B[1;31;40mBoldRedOnBlack";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.attributes.bold == 1);
    try expect(cell.fg_color.palette == 1);  // Red
    try expect(cell.bg_color.palette == 0);  // Black
}
```

---

### 1.3 Cursor Positioning Tests

#### Source: libansilove/src/loaders/ansi.c

**Original C Code**:
```c
// CUP: Cursor Position (ESC[row;colH)
if (csi_code == 'H' || csi_code == 'f') {
    cursor_row = (params[0] > 0) ? params[0] - 1 : 0;
    cursor_col = (params[1] > 0) ? params[1] - 1 : 0;
    cursor_row = MIN(cursor_row, max_rows - 1);
    cursor_col = MIN(cursor_col, max_cols - 1);
}
```

**Zig Test Adaptation**:
```zig
test "ansi: CUP (H) cursor positioning to row 5, col 10" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // ESC[5;10H positions cursor to row 5, col 10, then write X
    const input = "\x1B[5;10HX";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(10, 5);  // Col 10, Row 5
    try expect(cell.contents.scalar == 'X');
}

test "ansi: CUU (A) cursor up" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Write at row 10, then CUU 5 (should move to row 5)
    const input = "\x1B[10;0HA\x1B[5AB";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 10);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(1, 5);  // 5 rows up
    try expect(cell.contents.scalar == 'B');
}

test "ansi: CUD (B) cursor down" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Write at row 5, then CUD 3 (should move to row 8)
    const input = "\x1B[5;0HA\x1B[3BB";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 5);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(1, 8);  // 3 rows down
    try expect(cell.contents.scalar == 'B');
}

test "ansi: cursor save and restore (s/u)" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Move to 5,5, write A, save, move to 10,10, write B, restore, write C
    // C should be at 5,6 (right of A)
    const input = "\x1B[5;5HA\x1B[sX\x1B[10;10HB\x1B[uC";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(5, 5);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(10, 10);
    try expect(cell.contents.scalar == 'B');
    
    cell = try doc.getCell(6, 5);  // Restored cursor position
    try expect(cell.contents.scalar == 'C');
}

test "ansi: cursor bounds clamping" {
    var doc = try ir.Document.init(allocator, 80, 25);
    defer doc.deinit();
    
    // Try to move to row 100, col 200 (should clamp to 24, 79)
    const input = "\x1B[100;200HX";
    const parser = try ansi.Parser.init(allocator, input, &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(79, 24);  // Clamped position
    try expect(cell.contents.scalar == 'X');
}
```

---

## Part 2: SAUCE Parser Test Cases (from PabloDraw/SauceInfo.cs)

### 2.1 SAUCE Record Parsing

**Original C# Code**:
```csharp
// Read SAUCE record (last 128 bytes)
if (fileSize >= 128) {
    long sauceOffset = fileSize - 128;
    byte[] sauceData = new byte[128];
    fs.Seek(sauceOffset, SeekOrigin.Begin);
    fs.Read(sauceData, 0, 128);
    
    // Verify signature
    if (sauceData[7..14].SequenceEqual("SAUCE00"u8)) {
        Title = Encoding.ASCII.GetString(sauceData[0..35]);
        Author = Encoding.ASCII.GetString(sauceData[35..55]);
        Group = Encoding.ASCII.GetString(sauceData[55..75]);
        Date = Encoding.ASCII.GetString(sauceData[75..83]);
        FileSize = BitConverter.ToInt32(sauceData[83..87]);
        DataType = sauceData[87];
        FileType = sauceData[88];
        // ... more fields
    }
}
```

**Zig Test Adaptation**:
```zig
test "sauce: parse valid 128-byte SAUCE record" {
    var allocator = std.testing.allocator;
    
    // Create minimal valid SAUCE record
    var buf = try allocator.alloc(u8, 128);
    defer allocator.free(buf);
    
    @memset(buf, 0);
    
    // Signature: "SAUCE00" at offset 105
    buf[105..112].* = "SAUCE00".*;
    
    // Title (35 bytes at offset 0)
    buf[0..7].* = "MyTitle".*;
    
    // Author (20 bytes at offset 35)
    buf[35..41].* = "Author".*;
    
    // Group (20 bytes at offset 55)
    buf[55..59].* = "iCE!".*;
    
    // Date (8 bytes at offset 75, YYYYMMDD)
    buf[75..83].* = "20240101".*;
    
    // FileType (1 byte at offset 88)
    buf[88] = 1;  // ANSI
    
    // Parse
    const sauce = try sauce.Parser.parse(allocator, buf);
    defer sauce.deinit();
    
    try expect(std.mem.eql(u8, sauce.title, "MyTitle"));
    try expect(std.mem.eql(u8, sauce.author, "Author"));
    try expect(std.mem.eql(u8, sauce.group, "iCE!"));
    try expect(std.mem.eql(u8, sauce.date, "20240101"));
    try expect(sauce.file_type == 1);
}

test "sauce: reject invalid SAUCE signature" {
    var allocator = std.testing.allocator;
    
    var buf = try allocator.alloc(u8, 128);
    defer allocator.free(buf);
    
    @memset(buf, 0);
    
    // Wrong signature
    buf[105..112].* = "INVALID!".*;
    
    const result = sauce.Parser.parse(allocator, buf);
    try expect(result == error.InvalidSauceSignature);
}

test "sauce: parse SAUCE with comment block" {
    var allocator = std.testing.allocator;
    
    // File structure: text + comment block header + comments + SAUCE record
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    
    // Text content
    try buf.appendSlice("Hello World");
    
    // Comment block offset (points to start of comment block header)
    const comment_offset = buf.items.len;
    
    // Comment block header (64 bytes)
    var comment_header = std.ArrayList(u8).init(allocator);
    defer comment_header.deinit();
    
    try comment_header.appendSlice("COMNT");  // Signature
    try comment_header.appendSlice("0000000");  // 1 comment (zero-padded)
    
    // Comment 1 (64 bytes)
    var comment = std.ArrayList(u8).init(allocator);
    defer comment.deinit();
    try comment.appendSlice("This is a comment\n");
    
    try buf.appendSlice(comment_header.items);
    try buf.appendSlice(comment.items);
    
    // SAUCE record (128 bytes)
    var sauce_rec = try allocator.alloc(u8, 128);
    defer allocator.free(sauce_rec);
    @memset(sauce_rec, 0);
    
    sauce_rec[105..112].* = "SAUCE00".*;
    sauce_rec[88] = 1;  // ANSI
    sauce_rec[93] = 1;  // 1 comment
    
    // Comment offset (little-endian)
    var comment_offset_bytes: [4]u8 = undefined;
    std.mem.writeInt(u32, &comment_offset_bytes, @intCast(comment_offset), .little);
    sauce_rec[97..101].* = comment_offset_bytes;
    
    try buf.appendSlice(sauce_rec);
    
    // Parse
    const parsed_sauce = try sauce.Parser.parse(allocator, buf.items);
    defer parsed_sauce.deinit();
    
    try expect(parsed_sauce.comments.len == 1);
    try expect(std.mem.eql(u8, parsed_sauce.comments[0], "This is a comment\n"));
}

test "sauce: validate date field (YYYYMMDD)" {
    // Valid dates
    const valid_dates = [_][]const u8{
        "19960101",  // First day of 1996
        "20240612",  // Today
        "20991231",  // Far future
    };
    
    for (valid_dates) |date| {
        var buf = try allocator.alloc(u8, 128);
        defer allocator.free(buf);
        @memset(buf, 0);
        buf[105..112].* = "SAUCE00".*;
        buf[75..83].* = date.*;
        
        const sauce_rec = try sauce.Parser.parse(allocator, buf);
        defer sauce_rec.deinit();
        
        try expect(sauce_rec.date_valid);
    }
    
    // Invalid dates
    const invalid_dates = [_][]const u8{
        "99999999",  // Not a real date
        "20241399",  // Invalid month
        "20240132",  // Invalid day
    };
    
    for (invalid_dates) |date| {
        var buf = try allocator.alloc(u8, 128);
        defer allocator.free(buf);
        @memset(buf, 0);
        buf[105..112].* = "SAUCE00".*;
        buf[75..83].* = date.*;
        
        const sauce_rec = try sauce.Parser.parse(allocator, buf);
        defer sauce_rec.deinit();
        
        try expect(!sauce_rec.date_valid);
    }
}
```

---

## Part 3: Binary Parser Test Cases (from libansilove/binary.c)

### 3.1 Binary Format Parsing

**Original C Code**:
```c
// Binary format: 160 columns × 25 rows
// Each cell: char (1 byte) + attribute (1 byte)
for (int row = 0; row < 25; row++) {
    for (int col = 0; col < 160; col++) {
        uint8_t ch = fgetc(fp);
        uint8_t attr = fgetc(fp);
        
        // Parse attribute byte
        uint8_t fg = attr & 0x0F;          // Foreground color
        uint8_t bg = (attr >> 4) & 0x07;   // Background color
        uint8_t bold = (attr >> 3) & 0x01; // Bold flag in foreground
        uint8_t blink = (attr >> 7) & 0x01;// Blink flag
        
        // Write to grid
        grid[row][col] = ch;
        colors[row][col] = (fg, bg, bold, blink);
    }
}
```

**Zig Test Adaptation**:
```zig
test "binary: parse 160-column format" {
    var allocator = std.testing.allocator;
    
    // Create binary data: 160 cells × 1 row
    var buf = try allocator.alloc(u8, 160 * 2);
    defer allocator.free(buf);
    
    // Fill with pattern: A-Z repeated
    for (0..160) |i| {
        buf[i * 2] = @as(u8, @intCast(65 + (i % 26)));  // A-Z
        buf[i * 2 + 1] = 0x07;  // White on black
    }
    
    var doc = try ir.Document.init(allocator, 160, 25);
    defer doc.deinit();
    
    const parser = try binary.Parser.init(allocator, buf, &doc);
    defer parser.deinit();
    try parser.parse();
    
    // Verify first row is A-Z pattern
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'A');
    
    cell = try doc.getCell(1, 0);
    try expect(cell.contents.scalar == 'B');
}

test "binary: parse attribute byte (foreground, background, bold, blink)" {
    var allocator = std.testing.allocator;
    
    // Create single cell: 'X' with red foreground (1), bold (8), on blue background (4)
    var buf = try allocator.alloc(u8, 2);
    defer allocator.free(buf);
    
    buf[0] = 'X';
    // Attribute: FG (red=1), BG (blue=4<<4), bold (1<<3), blink=0
    // = 0x01 | 0x40 | 0x08 = 0x49
    buf[1] = 0x49;
    
    var doc = try ir.Document.init(allocator, 160, 25);
    defer doc.deinit();
    
    const parser = try binary.Parser.init(allocator, buf[0..2], &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    try expect(cell.contents.scalar == 'X');
    try expect(cell.fg_color.palette == 1);   // Red
    try expect(cell.bg_color.palette == 4);   // Blue
    try expect(cell.attributes.bold == 1);
}

test "binary: iCE colors mode (blink → bright background)" {
    var allocator = std.testing.allocator;
    
    // In iCE mode, blink flag becomes bright background flag
    // Attribute byte: FG=7 (white), BG=0 (black), blink=1
    var buf = try allocator.alloc(u8, 2);
    defer allocator.free(buf);
    
    buf[0] = 'X';
    buf[1] = 0x87;  // 0x80 (blink) | 0x07 (white)
    
    var doc = try ir.Document.init(allocator, 160, 25);
    defer doc.deinit();
    
    // Apply iCE colors flag
    doc.sauce.flags |= 0x01;  // iCE colors enabled
    
    const parser = try binary.Parser.init(allocator, buf[0..2], &doc);
    defer parser.deinit();
    try parser.parse();
    
    var cell = try doc.getCell(0, 0);
    // In iCE mode, blink (bit 7) becomes bright background (high bit of BG)
    try expect(cell.bg_color.palette >= 8);  // Bright color
}
```

---

## Part 4: Test Case Extraction Checklist

### For Each Parser (ANSI, Binary, XBin, etc.)

1. **Identify Source Code**
   - [ ] Locate reference implementation (libansilove or PabloDraw)
   - [ ] Find main parsing function
   - [ ] Identify state machine or state variables

2. **Extract Test Vectors**
   - [ ] Identify all special cases and edge cases
   - [ ] Extract input/output pairs
   - [ ] Document expected behavior
   - [ ] Create simple test files

3. **Document Test Cases**
   - [ ] Create `test_cases.md` describing all tests
   - [ ] Include source line numbers from reference
   - [ ] Note any platform-specific behavior
   - [ ] Record expected outputs

4. **Adapt to Zig**
   - [ ] Create `parser_test.zig` in `src/parsers/tests/`
   - [ ] Implement each test function
   - [ ] Ensure tests fail initially (RED phase)
   - [ ] Verify imports and allocators are correct

5. **Organize Fixtures**
   - [ ] Create fixture files for complex cases
   - [ ] Store in `src/parsers/tests/fixtures/`
   - [ ] Use `@embedFile()` for small fixtures
   - [ ] Document fixture format and expected output

6. **Validate Extraction**
   - [ ] Run `zig build test` to verify tests compile
   - [ ] Confirm all tests fail (RED phase)
   - [ ] Review test coverage against reference
   - [ ] Adjust scope if too large (>10 failing tests)

---

## Part 5: Test Case Organization Template

```
src/parsers/tests/
├── ansi_test.zig                    # ANSI parser tests
│   ├── Character Handling (5 tests)
│   ├── SGR Attributes (15 tests)
│   ├── Cursor Positioning (8 tests)
│   ├── SAUCE Integration (4 tests)
│   ├── Wrapping & Bounds (6 tests)
│   └── Integration Tests (6 tests)
│
├── binary_test.zig                  # Binary parser tests
│   ├── 160-col Format (4 tests)
│   ├── Attribute Parsing (6 tests)
│   ├── iCE Colors (2 tests)
│   └── Integration Tests (4 tests)
│
├── xbin_test.zig                    # XBin parser tests
│   ├── Header Parsing (4 tests)
│   ├── Font Embedding (4 tests)
│   ├── Palette Support (3 tests)
│   └── Integration Tests (3 tests)
│
├── sauce_test.zig                   # SAUCE parser tests
│   ├── Record Parsing (4 tests)
│   ├── Field Validation (5 tests)
│   ├── Comment Blocks (4 tests)
│   └── Edge Cases (3 tests)
│
├── fixtures/
│   ├── ansi/
│   │   ├── simple_text.ans
│   │   ├── sgr_colors.ans
│   │   ├── cursor_moves.ans
│   │   └── wrap_test.ans
│   ├── binary/
│   │   ├── standard.bin
│   │   └── with_sauce.bin
│   ├── xbin/
│   │   ├── with_font.xb
│   │   └── with_palette.xb
│   └── sauce/
│       ├── valid_record.bin
│       └── with_comments.bin
│
├── test_cases.md                    # Extraction documentation
│   ├── ANSI: libansilove/src/loaders/ansi.c lines X-Y
│   ├── Binary: libansilove/src/loaders/binary.c lines X-Y
│   ├── XBin: libansilove/src/loaders/xbin.c lines X-Y
│   └── SAUCE: PabloDraw/SauceInfo.cs lines X-Y
│
└── integration_test.zig             # Cross-parser tests
    ├── Parse → IR → Render round-trip
    ├── sixteencolors corpus validation
    └── Memory leak checks
```

---

## Part 6: Implementation Workflow

### Step 1: Extract Test Cases (30 min)
```bash
# For ANSI parser:
# 1. Open reference/libansilove/libansilove/src/loaders/ansi.c
# 2. Read main parsing loop and state machine
# 3. Identify all escape sequences, special chars, SGR codes
# 4. Note edge cases (TAB wrapping, bounds clamping, etc.)
# 5. Document in src/parsers/tests/test_cases.md
```

### Step 2: Create Test File (30 min)
```bash
# Create src/parsers/ansi_test.zig with failing tests
zig build test  # Should fail - RED phase
```

### Step 3: Implement Parser (1-2 hours)
```bash
# Implement src/parsers/ansi.zig
zig build test  # Should pass - GREEN phase
```

### Step 4: Refactor (30 min)
```bash
# Extract helpers, improve clarity
zig fmt src/parsers/**/*.zig
zig build test  # Should still pass
```

### Step 5: Commit
```bash
git add src/parsers/
git commit -m "ansi(red-green-refactor): [feature description]"
```

---

## References

- **libansilove**: `reference/libansilove/libansilove/src/loaders/`
- **PabloDraw**: `reference/pablodraw/pablodraw/Types/`
- **sixteencolors-archive**: `reference/sixteencolors/`
- **Plan**: `.specs/ir/plan.md` (Section 3: Red/Green/Refactor Cycles)
- **XP Summary**: `.specs/ir/PHASE5_XP_TDD_SUMMARY.md`
