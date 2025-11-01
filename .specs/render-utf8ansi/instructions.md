# UTF8ANSI Renderer - Instructions

## Overview

The UTF8ANSI renderer consumes the Ansilust IR and emits ANSI escape sequences for modern terminal emulators. The renderer focuses on maximum compatibility while maintaining visual fidelity to the original artwork through explicit color mapping and CP437→Unicode glyph translation.

## User Story

**As a** text art enthusiast using a modern terminal emulator  
**I want** to view classic BBS art files in my terminal with correct colors and glyphs  
**So that** the artwork looks as the artist intended without relying on my terminal's color theme or font configuration

**Baseline Problem** (from Bramwell's feedback on `cat *.ANS`):
- Colors are wrong because terminal theme overrides ANSI palette
- Box-drawing and shading characters render as "?" boxes (CP437→UTF-8 mapping missing)
- SAUCE metadata prints visibly (should be consumed internally only)
- Terminal state corruption (unknown terminal type errors persist after viewing)
- Line wrapping issues cause layout corruption

**MVP Solution**: Create a renderer that:
- Renders UTF8ANSI by default with simple CLI: `ansilust <file>` or `cat <file> | ansilust`
- Respects SAUCE metadata for grid dimensions and rendering hints (defaults to 80 columns when missing)
- Emits 24-bit truecolor SGR sequences with explicit VGA palette RGB values (no theme dependency, maximum compatibility)
- Translates CP437 glyphs to visually-equivalent Unicode characters (Phase 1 subset)
- Consumes SAUCE internally without rendering it to screen
- Guarantees terminal state cleanup (cursor visibility, wrap mode restoration)
- Uses absolute positioning to avoid relying on terminal wrap behavior

## Core Requirements (EARS Notation)

### Color Fidelity

**R1.1**: The renderer shall emit 24-bit truecolor SGR sequences (CSI 38;2;R;G;Bm / CSI 48;2;R;G;Bm) for all palette-indexed colors by default, using the exact RGB values from the palette specification.

**R1.1a**: **Rationale**: 24-bit truecolor is preferred over 8-bit (256-color) mode because the 256-color palette indices cannot be trusted across different terminal emulators. Each terminal may map the same index to different RGB values, causing color inconsistencies. By emitting explicit RGB values, we ensure the artist's intended colors are displayed consistently regardless of terminal configuration. See: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

**R1.2**: The renderer shall map 16-color DOS/VGA palette indices to their canonical RGB values (CGA/EGA standard):
- 0: #000000 (Black), 1: #0000AA (Blue), 2: #00AA00 (Green), 3: #00AAAA (Cyan)
- 4: #AA0000 (Red), 5: #AA00AA (Magenta), 6: #AA5500 (Brown), 7: #AAAAAA (Light Gray)
- 8: #555555 (Dark Gray), 9: #5555FF (Light Blue), 10: #55FF55 (Light Green), 11: #55FFFF (Light Cyan)
- 12: #FF5555 (Light Red), 13: #FF55FF (Light Magenta), 14: #FFFF55 (Yellow), 15: #FFFFFF (White)

**R1.3**: WHERE `--256color` flag is provided the renderer may optionally emit 8-bit SGR sequences (CSI 38;5;Nm / CSI 48;5;Nm) for compatibility with older terminals that don't support 24-bit color, using the pre-calculated ANSI 256-color code mapping for DOS palette indices (0-15): 0→16, 1→19, 2→34, 3→37, 4→124, 5→127, 6→136, 7→248, 8→240, 9→105, 10→120, 11→123, 12→210, 13→213, 14→228, 15→231.

**R1.4**: WHEN a cell has Color::None the renderer shall emit SGR 39 (default foreground) or SGR 49 (default background) instead of an explicit color code.

**R1.5**: The renderer shall support `--palette vga|ansi|workbench` to select different palette definitions.

### Character Encoding

**R2.1**: The renderer shall translate CP437 codepoints to visually-equivalent Unicode characters using a Phase 1 mapping table.

**R2.2**: The renderer shall use the complete CP437→Unicode mapping table (all 256 codepoints) from libansilove reference implementation.

**R2.2a**: The CP437→Unicode mapping shall include (critical glyphs for BBS art):
- **Shades/Blocks**: 0xB0→░ (2591), 0xB1→▒ (2592), 0xB2→▓ (2593), 0xDB→█ (2588), 0xDC→▄ (2584), 0xDF→▀ (2580), 0xDD→▌ (258C), 0xDE→▐ (2590), 0xFE→■ (25A0)
- **Single box**: 0xC4→─ (2500), 0xB3→│ (2502), 0xDA→┌ (250C), 0xBF→┐ (2510), 0xC0→└ (2514), 0xD9→┘ (2518), 0xC3→├ (251C), 0xB4→┤ (2524), 0xC2→┬ (252C), 0xC1→┴ (2534), 0xC5→┼ (253C)
- **Double box**: 0xCD→═ (2550), 0xBA→║ (2551), 0xC9→╔ (2554), 0xBB→╗ (2557), 0xC8→╚ (255A), 0xBC→╝ (255D), 0xCC→╠ (2560), 0xB9→╣ (2563), 0xCB→╦ (2566), 0xCA→╩ (2569), 0xCE→╬ (256C)
- **Arrows**: 0x18→↑ (2191), 0x19→↓ (2193), 0x1A→→ (2192), 0x1B→← (2190)
- **Card suits**: 0x03→♥ (2665), 0x04→♦ (2666), 0x05→♣ (2663), 0x06→♠ (2660)
- **Smileys**: 0x01→☺ (263A), 0x02→☻ (263B)
- **Extended ASCII**: 0x80-0xFF (accented characters, Greek letters, math symbols - see libansilove cp437_unicode.h)

**R2.3**: WHEN emitting CP437 characters the renderer shall use the complete 256-entry lookup table (no fallback needed for valid CP437 input).

**R2.5**: WHEN the IR contains Unicode codepoints (from UTF8ANSI source) the renderer shall emit them directly without translation.

### Text Attributes

**R3.1**: The renderer shall emit SGR codes for standard attributes (bold=1, faint=2, italic=3, underline=4, blink=5, reverse=7, strikethrough=9).

**R3.2**: WHEN multiple attributes are active the renderer shall batch them in a single SGR sequence (e.g., CSI 1;4;7m).

**R3.3**: WHERE separate underline color is present the renderer shall emit CSI 58;5;Nm or CSI 58;2;R;G;Bm.

**R3.4**: WHEN attributes change between cells the renderer shall emit a full reset (SGR 0) followed by the new attribute set.

### Terminal Safety

**R4.1**: The renderer shall emit initialization sequences before rendering:
- Hide cursor: CSI ?25l
- Disable line wrap: CSI ?7l
- Clear screen: CSI 2J
- Home cursor: CSI H

**R4.2**: The renderer shall emit cleanup sequences after rendering OR on error:
- Reset attributes: CSI 0m
- Enable line wrap: CSI ?7h
- Show cursor: CSI ?25h

**R4.3**: The renderer shall NOT emit sequences that mutate terminal state persistently:
- No OSC 4 (palette changes)
- No OSC 104 (palette reset)
- No DECPM mode changes except those listed in R4.1/R4.2
- No alternate screen buffer (CSI ?1049h) in Phase 1

**R4.4**: IF an error occurs during rendering THEN the renderer shall execute all cleanup sequences before returning the error.

### Layout and Positioning

**R5.1**: The renderer shall use absolute cursor positioning (CSI r;cH) for every row, never relying on terminal wrap behavior.

**R5.2**: The renderer shall emit cells in row-major order (left-to-right, top-to-bottom).

**R5.3**: WHEN multiple consecutive cells share identical style (fg, bg, attributes) the renderer shall batch them into a single run without re-emitting SGR sequences.

**R5.4**: The renderer shall respect grid dimensions from IR (width × height) and render exactly those bounds.

**R5.5**: WHEN SAUCE metadata is present in IR the renderer shall NOT emit it to the output stream.

**R5.6**: WHEN SAUCE metadata contains column width (tinfo1) the renderer shall use that value for grid width.

**R5.7**: WHERE SAUCE metadata is missing AND no --columns override is provided the renderer shall default to 80 columns (following libansilove convention).

### Wide Character Handling

**R6.1**: WHEN a cell is marked as spacer_head the renderer shall emit the wide character and skip the following spacer_tail cell(s).

**R6.2**: WHEN a cell is marked as spacer_tail the renderer shall emit nothing (already handled by spacer_head).

**R6.3**: WHERE grapheme clusters are present the renderer shall emit the complete cluster as a single UTF-8 sequence.

## Technical Specifications

### Data Structures

**CP437 Translation Table** (complete 256-entry table from libansilove):
```zig
pub const cp437_to_unicode: [256]u21 = .{
    // Complete mapping based on effect-native/libansilove cp437_unicode.h
    // Includes: control chars, ASCII, extended ASCII, box-drawing, Greek, math symbols
    // See: https://raw.githubusercontent.com/effect-native/libansilove/refs/heads/utf8ansi-terminal/src/cp437_unicode.h
    0x0000, 0x263A, 0x263B, 0x2665, 0x2666, 0x2663, 0x2660, 0x2022,
    // ... (full 256 entries)
};
```

**DOS/VGA Palette** (CGA/EGA standard):
```zig
pub const dos_palette: [16]struct { r: u8, g: u8, b: u8 } = .{
    .{ .r = 0x00, .g = 0x00, .b = 0x00 }, // 0: Black
    .{ .r = 0x00, .g = 0x00, .b = 0xAA }, // 1: Blue
    .{ .r = 0x00, .g = 0xAA, .b = 0x00 }, // 2: Green
    .{ .r = 0x00, .g = 0xAA, .b = 0xAA }, // 3: Cyan
    .{ .r = 0xAA, .g = 0x00, .b = 0x00 }, // 4: Red
    .{ .r = 0xAA, .g = 0x00, .b = 0xAA }, // 5: Magenta
    .{ .r = 0xAA, .g = 0x55, .b = 0x00 }, // 6: Brown
    .{ .r = 0xAA, .g = 0xAA, .b = 0xAA }, // 7: Light Gray
    .{ .r = 0x55, .g = 0x55, .b = 0x55 }, // 8: Dark Gray
    .{ .r = 0x55, .g = 0x55, .b = 0xFF }, // 9: Light Blue
    .{ .r = 0x55, .g = 0xFF, .b = 0x55 }, // 10: Light Green
    .{ .r = 0x55, .g = 0xFF, .b = 0xFF }, // 11: Light Cyan
    .{ .r = 0xFF, .g = 0x55, .b = 0x55 }, // 12: Light Red
    .{ .r = 0xFF, .g = 0x55, .b = 0xFF }, // 13: Light Magenta
    .{ .r = 0xFF, .g = 0xFF, .b = 0x55 }, // 14: Yellow
    .{ .r = 0xFF, .g = 0xFF, .b = 0xFF }, // 15: White
};

pub const dos_to_ansi256: [16]u8 = .{
    16, 19, 34, 37, 124, 127, 136, 248,
    240, 105, 120, 123, 210, 213, 228, 231,
};
```

**Render State**:
```zig
pub const RenderState = struct {
    current_fg: ?Color,
    current_bg: ?Color,
    current_attrs: Attributes,
    cursor_visible: bool,
    wrap_enabled: bool,
};
```

### Algorithm: Run-Length Style Batching

1. Initialize terminal (hide cursor, disable wrap, clear, home)
2. For each row (0..height):
   - Emit absolute position: CSI (row+1);1H
   - Track current style (fg, bg, attrs)
   - For each cell in row:
     - If style differs from current: emit SGR reset + new style
     - If cell is spacer_tail: skip
     - Emit character (translated CP437 or direct Unicode)
   - Advance to next row
3. Cleanup terminal (reset SGR, enable wrap, show cursor)

### CLI Interface

**Default Behavior**: UTF8ANSI rendering with no subcommand required

**Command Syntax**:
```bash
# Read from file (UTF8ANSI render by default)
ansilust <file> [options]

# Read from stdin (UTF8ANSI render by default)
cat <file> | ansilust [options]

Options:
  --palette <vga|ansi|workbench>   Palette to use (default: vga)
  --256color                       Use 8-bit 256-color mode instead of 24-bit (for older terminals)
  --ice                            Enable iCE colors mode (if not in SAUCE)
  --no-cleanup                     Skip terminal cleanup (for debugging)
  --columns <N>                    Override column width (default: SAUCE or 80)
```

**Example Usage**:
```bash
# Render from file (simplest form)
ansilust ~/Downloads/acdu0395/SO-PG1.ANS

# Render from stdin (classic pipeline)
cat ~/Downloads/acdu0395/SO-PG1.ANS | ansilust

# Render with 256-color mode (for older terminals)
ansilust ~/Downloads/acdu0395/SO-PG1.ANS --256color

# Render with column override (when SAUCE missing)
cat file-without-sauce.ans | ansilust --columns 80

# Debug mode (no cleanup to inspect terminal state)
ansilust test.ans --no-cleanup
```

**Future Renderer Support** (out of scope for Phase 1):
```bash
# Hypothetical future renderers (require explicit opt-in)
ansilust --render html <file>
ansilust --render png <file>
ansilust --render sixel <file>
```

### Integration with Parser

```zig
// Read from file or stdin
const input = if (args.file) |path|
    try std.fs.cwd().readFileAlloc(allocator, path, max_size)
else
    try std.io.getStdIn().readToEndAlloc(allocator, max_size);
defer allocator.free(input);

// Parse ANSI file to IR
const ir = try ansi.parse(allocator, input);
defer ir.deinit();

// Render IR to UTF8ANSI (respects SAUCE or defaults to 80 columns)
const output = try utf8ansi.render(ir, allocator, .{
    .palette = args.palette orelse .vga,
    .use_256color = args.use_256color, // Default: false (use 24-bit)
    .ice_colors = ir.sauce.?.ice_colors,
    .columns = args.columns, // Optional override
});
defer allocator.free(output);

// Write to stdout
try stdout.writeAll(output);
```

## Acceptance Criteria

**AC1**: WHEN viewing a 16-color ANSI file with `--palette vga` THEN colors match the VGA palette specification regardless of terminal theme or terminal-specific palette mappings.

**AC2**: WHEN viewing a file containing CP437 box-drawing characters THEN they render as Unicode box-drawing glyphs (not "?" boxes).

**AC3**: WHEN viewing a file containing CP437 shading characters THEN they render as Unicode shading glyphs (░▒▓).

**AC4**: WHEN viewing a file with SAUCE metadata THEN the SAUCE record does NOT appear in terminal output.

**AC5**: WHEN rendering completes OR errors THEN the terminal state is fully restored (cursor visible, wrap enabled, no persistent errors).

**AC6**: WHEN viewing SO-PG1.ANS from acdu0395 corpus THEN:
- Grid dimensions match SAUCE metadata (80×159)
- Colors render correctly (no theme interference)
- Box-drawing and shading characters render correctly
- No SAUCE metadata visible
- No terminal state corruption after exit

**AC7**: WHEN rendering with `--256color` THEN 8-bit SGR sequences are emitted instead of 24-bit for compatibility with older terminals.

**AC8**: WHEN running `ansilust <file>` THEN Bramwell reports significantly improved rendering quality compared to baseline `cat <file>`.

**AC9**: WHEN running `cat <file> | ansilust` THEN output is identical to `ansilust <file>`.

**AC10**: WHEN SAUCE metadata is present THEN grid dimensions and colors respect SAUCE hints.

**AC11**: WHERE SAUCE metadata is missing AND no --columns override THEN grid defaults to 80 columns.

## Out of Scope (Phase 1)

**OS1**: Animation playback (ansimation format support)

**OS2**: Alternate screen buffer (CSI ?1049h)

**OS3**: Sixel or Kitty graphics protocol

**OS4**: Mouse tracking or other interactive features

**OS5**: Automatic terminal capability detection (explicit flags only)

**OS6**: Font rendering or bitmap font support (assumes terminal has suitable font)

**OS7**: Hyperlink support (OSC 8)

**OS8**: Stdin input parsing (deferred to later phase or never)

## Testing Strategy

### Unit Tests

**T1**: CP437 Translation Table
- Verify all 256 mappings against libansilove reference table
- Spot-check critical glyphs: shades, blocks, single/double box, arrows, card suits
- Verify UTF-8 encoding correctness for multi-byte codepoints

**T2**: VGA Palette Mapping
- Verify all 16 colors map to correct RGB values
- Verify Color::None emits SGR 39/49

**T3**: SGR Sequence Generation
- Single attribute (bold, underline, etc.)
- Multiple attributes batched correctly
- Reset behavior (SGR 0 before new style)
- Separate underline color

**T4**: Run-Length Style Batching
- Consecutive cells with same style: emit characters without redundant SGR
- Style change: emit reset + new SGR
- Row boundaries: absolute positioning emitted

**T5**: Terminal State Management
- Initialization sequences in correct order
- Cleanup sequences even on error path
- No persistent state mutations

### Integration Tests

**T6**: Corpus Validation
- Parse and render 10 representative files from acdu0395 corpus
- Verify no SAUCE leakage in output
- Verify no terminal state corruption (manual check or test harness)

**T7**: Round-Trip Validation
- Parse ANSI → IR → render UTF8ANSI → visually compare to original
- Document any expected differences (e.g., font variations)

**T8**: Terminal Compatibility
- Test output on: Ghostty, Alacritty, Kitty, WezTerm, xterm
- Verify colors render consistently across terminals

### Manual Acceptance Tests

**T9**: Bramwell Subjective Quality Assessment
- Render SO-PG1.ANS and other acdu0395 files
- Collect feedback on:
  - Color accuracy (compared to known reference renders)
  - Glyph correctness (box-drawing, shading)
  - Layout correctness (no wrap issues)
  - Terminal state (no persistent errors)

**T10**: Visual Regression
- Capture terminal screenshots of 5–10 reference files
- Compare against known-good reference images (from ansilove PNG output)

## Success Metrics

**SM1**: Bramwell reports "colors look correct" on 90%+ of corpus files

**SM2**: Bramwell reports "glyphs render correctly" on 90%+ of corpus files

**SM3**: Zero SAUCE metadata visible in any rendered output

**SM4**: Zero terminal state corruption reports across 100+ test renders

**SM5**: Render time < 100ms for typical 80×200 file on reference hardware

**SM6**: All unit tests pass with zero memory leaks (std.testing.allocator)

## Future Considerations

**FC1**: Complete CP437 Mapping (Phase 2)
- Add remaining glyphs (arrows, card suits, math symbols, etc.)
- User-configurable mapping overrides

**FC2**: Animation Playback
- Frame timing support
- Delta frame optimization
- Loop and repeat handling

**FC3**: Alternate Screen Buffer
- CSI ?1049h for non-persistent rendering
- Restore previous screen on exit

**FC4**: Advanced SGR Features
- Multiple underline styles (double, curly, dotted)
- Overline support
- Custom underline colors

**FC5**: Terminal Capability Detection
- Query terminal for 24-bit color support
- Auto-fallback to 256-color if needed
- Query for Unicode support

**FC6**: Performance Optimization
- Buffered writes (reduce syscalls)
- SIMD optimizations for style-run detection
- Zero-copy rendering where possible

**FC7**: Accessibility
- Screen reader hints (skip decorative elements)
- Alt text for complex artwork

## References

**CP437 Mapping Reference**: [effect-native/libansilove cp437_unicode.h](https://raw.githubusercontent.com/effect-native/libansilove/refs/heads/utf8ansi-terminal/src/cp437_unicode.h)

**DOS Color Palette Reference**: [effect-native/libansilove dos_colors.h](https://raw.githubusercontent.com/effect-native/libansilove/refs/heads/utf8ansi-terminal/src/dos_colors.h)

**libansilove ANSI Parser**: `reference/libansilove/libansilove/src/loaders/ansi.c` (column default logic at line 110-111)

**VGA Palette Source**: [Wikipedia - ANSI escape code](https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit)

**CP437 Reference**: [Wikipedia - Code page 437](https://en.wikipedia.org/wiki/Code_page_437)

**ANSI Escape Sequences**: [ECMA-48 Standard](https://www.ecma-international.org/publications-and-standards/standards/ecma-48/)

**Terminal Control Sequences**: [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)

## Open Questions for Iteration

**Q1**: Should we support auto-detection of 24-bit color capability (e.g., check $COLORTERM)?
**Answer**: No - default to 24-bit as it's widely supported; users can opt into 256-color with `--256color` if needed.

**Q3**: Should we add a `--verify` mode that parses output and compares to IR (round-trip test)?

**Q4**: Should we support rendering to a file instead of stdout for testing?

**Q5**: Should we add a `--diff` mode to compare two renders visually?

**Q6**: Should we preserve blank lines at end of file, or trim trailing whitespace?

**Q7**: Should we add telemetry (e.g., count of CP437 glyphs translated, SGR sequence count)?

## Decisions Made (from prior art research)

**Q2 (CP437 scope)**: ✅ Use complete 256-entry CP437→Unicode table from libansilove (includes arrows, card suits, smileys, Greek, math symbols).

**Q8 (Missing SAUCE column width)**: ✅ Default to 80 columns (libansilove convention: `options->columns = options->columns ? options->columns : 80`).

**Q9 (Stdin parsing)**: ⏸️ Deferred to later phase or never (not in MVP scope).
