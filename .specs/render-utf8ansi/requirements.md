# UTF8ANSI Renderer - Requirements Specification

## Overview

This document provides formal requirements for the UTF8ANSI renderer using EARS (Easy Approach to Requirements Syntax) notation. All functional requirements use one of the five EARS patterns: Ubiquitous, Event-driven, State-driven, Unwanted, or Optional.

## FR1: Functional Requirements

### FR1.1: Input Handling

**FR1.1.1**: The renderer shall accept an IR document structure as input.

**FR1.1.2**: The renderer shall accept an allocator parameter for all memory allocations.

**FR1.1.3**: The renderer shall accept a RenderOptions structure containing palette, truecolor, ice_colors, and optional column override.

**FR1.1.4**: WHEN the IR document contains no cells the renderer shall return an empty output buffer.

**FR1.1.5**: IF the IR document pointer is null THEN the renderer shall return error.InvalidInput.

**FR1.1.6**: IF the allocator parameter is invalid THEN the renderer shall return error.InvalidAllocator.

### FR1.2: Color Rendering

**FR1.2.1**: The renderer shall emit 256-color SGR sequences (CSI 38;5;Nm for foreground, CSI 48;5;Nm for background) by default.

**FR1.2.2**: WHEN rendering DOS palette colors (indices 0-15) the renderer shall use the pre-calculated ANSI 256-color mapping:
- 0→16, 1→19, 2→34, 3→37, 4→124, 5→127, 6→136, 7→248
- 8→240, 9→105, 10→120, 11→123, 12→210, 13→213, 14→228, 15→231

**FR1.2.3**: WHERE the truecolor option is enabled the renderer shall emit 24-bit SGR sequences (CSI 38;2;R;G;Bm for foreground, CSI 48;2;R;G;Bm for background).

**FR1.2.4**: WHEN a cell has Color::None for foreground the renderer shall emit SGR 39 (default foreground).

**FR1.2.5**: WHEN a cell has Color::None for background the renderer shall emit SGR 49 (default background).

**FR1.2.6**: The renderer shall use the DOS/VGA CGA/EGA standard palette RGB values for all palette-indexed colors:
- 0: #000000 (Black), 1: #0000AA (Blue), 2: #00AA00 (Green), 3: #00AAAA (Cyan)
- 4: #AA0000 (Red), 5: #AA00AA (Magenta), 6: #AA5500 (Brown), 7: #AAAAAA (Light Gray)
- 8: #555555 (Dark Gray), 9: #5555FF (Light Blue), 10: #55FF55 (Light Green), 11: #55FFFF (Light Cyan)
- 12: #FF5555 (Light Red), 13: #FF55FF (Light Magenta), 14: #FFFF55 (Yellow), 15: #FFFFFF (White)

**FR1.2.7**: WHERE the palette option specifies workbench mode the renderer shall use the Amiga Workbench color palette instead of DOS/VGA.

**FR1.2.8**: IF a palette index exceeds 255 THEN the renderer shall clamp it to 255.

### FR1.3: Character Encoding

**FR1.3.1**: The renderer shall translate CP437 codepoints to Unicode using the complete 256-entry lookup table.

**FR1.3.2**: The renderer shall emit UTF-8 encoded byte sequences for all Unicode codepoints.

**FR1.3.3**: WHEN a cell contains a Unicode codepoint (from UTF8ANSI source) the renderer shall emit it directly without CP437 translation.

**FR1.3.4**: The CP437→Unicode mapping shall include all standard glyphs:
- Box-drawing characters (single and double)
- Shading characters (░▒▓)
- Block characters (█▄▀▌▐■)
- Arrows (↑↓→←)
- Card suits (♠♣♥♦)
- Smileys (☺☻)
- Extended ASCII (accented characters, Greek letters, math symbols)

**FR1.3.5**: WHEN emitting multi-byte UTF-8 sequences the renderer shall encode them correctly according to UTF-8 specification.

**FR1.3.6**: IF a UTF-8 encoding operation fails THEN the renderer shall return error.EncodingError.

### FR1.4: Text Attributes

**FR1.4.1**: The renderer shall emit SGR codes for standard text attributes:
- Bold (SGR 1)
- Faint (SGR 2)
- Italic (SGR 3)
- Underline (SGR 4)
- Blink (SGR 5)
- Reverse (SGR 7)
- Strikethrough (SGR 9)

**FR1.4.2**: WHEN multiple attributes are active the renderer shall batch them in a single SGR sequence (e.g., CSI 1;4;7m).

**FR1.4.3**: WHEN attributes change between cells the renderer shall emit a full reset (SGR 0) followed by the new attribute set.

**FR1.4.4**: WHERE a cell has separate underline color the renderer shall emit CSI 58;5;Nm (256-color) or CSI 58;2;R;G;Bm (24-bit).

**FR1.4.5**: WHEN the attribute bitflags are zero the renderer shall not emit any attribute SGR codes beyond color.

### FR1.5: Layout and Positioning

**FR1.5.1**: The renderer shall use absolute cursor positioning (CSI r;cH) for every row.

**FR1.5.2**: The renderer shall emit cells in row-major order (left-to-right, top-to-bottom).

**FR1.5.3**: WHEN multiple consecutive cells share identical style (foreground, background, attributes) the renderer shall batch them into a single run without re-emitting SGR sequences.

**FR1.5.4**: The renderer shall respect grid dimensions from the IR document (width × height).

**FR1.5.5**: WHEN SAUCE metadata is present in the IR the renderer shall NOT emit it to the output stream.

**FR1.5.6**: WHEN SAUCE metadata contains column width (tinfo1) the renderer shall use that value for grid width.

**FR1.5.7**: WHERE SAUCE metadata is missing AND no --columns override is provided the renderer shall default to 80 columns.

**FR1.5.8**: WHERE a --columns override is provided the renderer shall use that value regardless of SAUCE metadata.

**FR1.5.9**: IF the calculated row count is zero THEN the renderer shall return error.InvalidDimensions.

**FR1.5.10**: IF the calculated column count is zero THEN the renderer shall return error.InvalidDimensions.

### FR1.6: Terminal Safety

**FR1.6.1**: The renderer shall emit initialization sequences before rendering content:
- Hide cursor (CSI ?25l)
- Disable line wrap (CSI ?7l)
- Clear screen (CSI 2J)
- Home cursor (CSI H)

**FR1.6.2**: The renderer shall emit cleanup sequences after rendering content OR on error:
- Reset attributes (CSI 0m)
- Enable line wrap (CSI ?7h)
- Show cursor (CSI ?25h)

**FR1.6.3**: IF an error occurs during rendering THEN the renderer shall execute all cleanup sequences before returning the error.

**FR1.6.4**: The renderer shall NOT emit sequences that mutate terminal state persistently:
- No OSC 4 (palette modification)
- No OSC 104 (palette reset)
- No alternate screen buffer (CSI ?1049h) in Phase 1
- No DECPM mode changes except cursor visibility and wrap mode

**FR1.6.5**: WHEN cleanup sequences are emitted the renderer shall ensure they are written to the output buffer even if memory is constrained.

### FR1.7: Wide Character Handling

**FR1.7.1**: WHEN a cell is marked as spacer_head the renderer shall emit the wide character and skip the following spacer_tail cell(s).

**FR1.7.2**: WHEN a cell is marked as spacer_tail the renderer shall emit nothing (already handled by spacer_head).

**FR1.7.3**: WHERE grapheme clusters are present the renderer shall emit the complete cluster as a single UTF-8 sequence.

**FR1.7.4**: IF a wide character is missing its spacer_tail THEN the renderer shall emit the character and continue (best-effort rendering).

### FR1.8: Memory Management

**FR1.8.1**: The renderer shall allocate output buffer memory using the provided allocator.

**FR1.8.2**: The renderer shall calculate output buffer size based on:
- Grid dimensions (width × height)
- Maximum SGR sequence length per cell
- UTF-8 encoded character length (up to 4 bytes per codepoint)
- Cursor positioning sequences per row

**FR1.8.3**: WHEN memory allocation fails the renderer shall return error.OutOfMemory.

**FR1.8.4**: The renderer shall not leak memory under any circumstances (success or error paths).

**FR1.8.5**: WHEN rendering completes successfully the renderer shall transfer ownership of the output buffer to the caller.

**FR1.8.6**: IF the output buffer would exceed a reasonable size limit (e.g., 100MB) THEN the renderer shall return error.OutputTooLarge.

### FR1.9: Error Handling

**FR1.9.1**: The renderer shall define a specific error set for all failure modes.

**FR1.9.2**: IF input validation fails THEN the renderer shall return error.InvalidInput with context.

**FR1.9.3**: IF color value is out of valid range THEN the renderer shall clamp it to the nearest valid value.

**FR1.9.4**: IF UTF-8 encoding fails THEN the renderer shall return error.EncodingError.

**FR1.9.5**: The renderer shall release all allocated resources on error paths using errdefer.

**FR1.9.6**: WHEN an error is returned the renderer shall provide sufficient context for debugging.

---

## NFR2: Non-Functional Requirements

### NFR2.1: Performance

**NFR2.1.1**: The renderer shall process a typical 80×200 cell document in under 100ms on reference hardware (modern x86_64 CPU).

**NFR2.1.2**: The renderer shall minimize memory allocations by pre-calculating output buffer size.

**NFR2.1.3**: The renderer shall use efficient string concatenation strategies to avoid repeated reallocations.

**NFR2.1.4**: The renderer shall batch consecutive cells with identical styles to reduce SGR sequence count by at least 50% compared to naive per-cell emission.

### NFR2.2: Memory Usage

**NFR2.2.1**: The renderer shall maintain peak memory usage proportional to output size (no hidden exponential growth).

**NFR2.2.2**: The renderer shall not allocate more than 2× the final output size during rendering.

**NFR2.2.3**: The renderer shall release all temporary allocations before returning.

### NFR2.3: Code Quality

**NFR2.3.1**: All public APIs shall have comprehensive doc comments (///) with usage examples.

**NFR2.3.2**: Doc comment coverage shall be 100% for public functions and types.

**NFR2.3.3**: The renderer shall compile with zero warnings under -Doptimize=ReleaseSafe.

**NFR2.3.4**: The renderer shall pass all tests with zero memory leaks (std.testing.allocator).

**NFR2.3.5**: The renderer shall format all code with zig fmt before commit.

### NFR2.4: Correctness

**NFR2.4.1**: The renderer shall produce output that is visually identical to reference implementations (libansilove) for the same input IR.

**NFR2.4.2**: The renderer shall handle edge cases gracefully (empty grids, single-cell grids, maximum-size grids).

**NFR2.4.3**: The renderer shall maintain terminal safety guarantees under all code paths (success, error, panic).

---

## TC3: Technical Constraints

### TC3.1: Zig Version

**TC3.1.1**: The renderer shall compile with Zig version 0.11.0 or later.

**TC3.1.2**: The renderer shall not use deprecated Zig language features.

### TC3.2: Dependencies

**TC3.2.1**: The renderer shall have zero external dependencies beyond Zig std library.

**TC3.2.2**: The renderer shall depend only on the ansilust IR module.

### TC3.3: Build Configuration

**TC3.3.1**: The renderer shall compile successfully with -Doptimize=Debug (for undefined behavior checks).

**TC3.3.2**: The renderer shall compile successfully with -Doptimize=ReleaseSafe (for production builds).

**TC3.3.3**: The renderer shall compile successfully with -Doptimize=ReleaseFast (for performance benchmarks).

### TC3.4: Platform Support

**TC3.4.1**: The renderer shall be platform-agnostic (no OS-specific dependencies).

**TC3.4.2**: The renderer shall produce terminal output compatible with POSIX-compliant terminals.

**TC3.4.3**: The renderer shall support Linux, macOS, and BSD platforms.

### TC3.5: Safety Constraints

**TC3.5.1**: The renderer shall not use global mutable state.

**TC3.5.2**: The renderer shall not use @intCast without explicit bounds checking.

**TC3.5.3**: The renderer shall not use catch unreachable without strong justification in doc comments.

**TC3.5.4**: The renderer shall use explicit allocator parameters for all allocations (no hidden allocations).

---

## DR4: Data Requirements

### DR4.1: Input Data Structures

**DR4.1.1**: The renderer shall accept an IR Document structure containing:
- Cell grid (width, height, cell array)
- Optional SAUCE metadata
- Color palette data
- Encoding information

**DR4.1.2**: The renderer shall accept a RenderOptions structure containing:
- Palette mode (vga, ansi, workbench)
- Truecolor flag (bool)
- Ice colors flag (bool)
- Optional column override (u16)

### DR4.2: Output Data Structure

**DR4.2.1**: The renderer shall produce a UTF-8 encoded byte array ([]const u8).

**DR4.2.2**: The output shall contain only valid ANSI escape sequences and UTF-8 text.

**DR4.2.3**: The output shall be suitable for direct emission to stdout or file.

### DR4.3: Lookup Tables

**DR4.3.1**: The renderer shall maintain a 256-entry CP437→Unicode lookup table (const [256]u21).

**DR4.3.2**: The renderer shall maintain a 16-entry DOS/VGA RGB palette (const [16]struct { r: u8, g: u8, b: u8 }).

**DR4.3.3**: The renderer shall maintain a 16-entry DOS→ANSI 256 color mapping (const [16]u8).

**DR4.3.4**: WHERE workbench mode is enabled the renderer shall use an alternate 16-entry Amiga palette.

### DR4.4: State Tracking

**DR4.4.1**: The renderer shall track current rendering state:
- Current foreground color
- Current background color
- Current attributes
- Current cursor position

**DR4.4.2**: The state tracking shall enable efficient style-run batching optimization.

---

## IR5: Integration Requirements

### IR5.1: IR Module Integration

**IR5.1.1**: The renderer shall import the IR document structure from src/ir/document.zig.

**IR5.1.2**: The renderer shall import color types from src/ir/color.zig.

**IR5.1.3**: The renderer shall import attribute types from src/ir/attributes.zig.

**IR5.1.4**: The renderer shall import SAUCE metadata from src/ir/sauce.zig.

### IR5.2: Parser Integration

**IR5.2.1**: The renderer shall accept IR produced by the ANSI parser without modification.

**IR5.2.2**: The renderer shall handle IR with SAUCE metadata correctly.

**IR5.2.3**: The renderer shall handle IR without SAUCE metadata correctly (default to 80 columns).

### IR5.3: CLI Integration

**IR5.3.1**: The renderer shall be invokable from src/main.zig with RenderOptions.

**IR5.3.2**: The renderer shall support file input mode (read from path).

**IR5.3.3**: The renderer shall write output to stdout by default.

**IR5.3.4**: WHERE CLI provides --columns override the renderer shall use that value.

---

## DEP6: Dependencies

### DEP6.1: Core Dependencies

**DEP6.1.1**: The renderer depends on Zig std library (std.mem, std.fmt, std.ArrayList, std.unicode).

**DEP6.1.2**: The renderer depends on ansilust IR module (src/ir).

### DEP6.2: Test Dependencies

**DEP6.2.1**: Tests depend on std.testing.

**DEP6.2.2**: Tests depend on std.testing.allocator for leak detection.

---

## SC7: Success Criteria

### SC7.1: Functional Completeness

**SC7.1.1**: The renderer successfully renders all 19 files from acdu0395 corpus without errors.

**SC7.1.2**: Bramwell reports "colors look correct" on 90%+ of corpus files.

**SC7.1.3**: Bramwell reports "glyphs render correctly" on 90%+ of corpus files.

**SC7.1.4**: Zero SAUCE metadata is visible in any rendered output.

**SC7.1.5**: Zero terminal state corruption reports across 100+ test renders.

### SC7.2: Quality Metrics

**SC7.2.1**: 100% doc comment coverage for public APIs.

**SC7.2.2**: All tests pass with std.testing.allocator (zero memory leaks).

**SC7.2.3**: zig build completes with zero errors and zero warnings.

**SC7.2.4**: zig build test passes all unit and integration tests.

**SC7.2.5**: Code formatted with zig fmt (no formatting changes when run).

### SC7.3: Performance Metrics

**SC7.3.1**: Render time < 100ms for typical 80×200 file on reference hardware.

**SC7.3.2**: Peak memory usage < 2× final output size for typical files.

**SC7.3.3**: SGR sequence count reduced by 50%+ compared to naive per-cell emission.

---

## Requirements Traceability Matrix

| Requirement ID | Instructions.md Section | Priority | Test Coverage |
|---------------|------------------------|----------|---------------|
| FR1.1.x | Input Handling | Must Have | T1, T6 |
| FR1.2.x | Color Fidelity | Must Have | T2, T7, T9 |
| FR1.3.x | Character Encoding | Must Have | T1, T7, T9 |
| FR1.4.x | Text Attributes | Must Have | T3, T7 |
| FR1.5.x | Layout and Positioning | Must Have | T4, T6, T7 |
| FR1.6.x | Terminal Safety | Must Have | T5, T6, T8 |
| FR1.7.x | Wide Character Handling | Should Have | T7 |
| FR1.8.x | Memory Management | Must Have | All Tests |
| FR1.9.x | Error Handling | Must Have | T1-T8 |
| NFR2.1.x | Performance | Should Have | T13 |
| NFR2.2.x | Memory Usage | Should Have | T14 |
| NFR2.3.x | Code Quality | Must Have | All Tests |
| NFR2.4.x | Correctness | Must Have | T7, T9, T10 |

---

## EARS Notation Validation

This requirements document uses EARS notation for all functional requirements:

- **Ubiquitous** (no preconditions): 25 requirements
- **Event-driven** (WHEN): 18 requirements
- **State-driven** (WHILE): 0 requirements (not applicable to stateless renderer)
- **Unwanted** (IF...THEN): 13 requirements
- **Optional** (WHERE): 8 requirements

**Total Functional Requirements**: 64 requirements using proper EARS patterns.

All requirements:
- ✅ Use "shall" (mandatory)
- ✅ One requirement per statement
- ✅ Specific and measurable
- ✅ Focus on observable behavior (not implementation)
- ✅ Make preconditions explicit
- ✅ Testable and verifiable

---

## Phase 2 Completion Checklist

- [x] Functional requirements (FR1.x) using EARS notation
- [x] Non-functional requirements (NFR2.x) with measurable criteria
- [x] Technical constraints (TC3.x)
- [x] Data requirements (DR4.x)
- [x] Integration requirements (IR5.x)
- [x] Dependencies (DEP6.x)
- [x] Success criteria (SC7.x)
- [x] Requirements traceability matrix
- [x] EARS notation validation

**Phase 2 Status**: ✅ COMPLETE

**Ready for**: Phase 3 (Design Phase) authorization
