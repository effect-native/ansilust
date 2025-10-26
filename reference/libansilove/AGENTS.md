# libansilove Reference

## What is libansilove?

libansilove is a C library for converting ANSI, ASCII art, and other text-based art formats into PNG images. It's the core library that powers the ansilove command-line tool.

## Contents

The `libansilove/` submodule contains:

- **Core library** (`src/`) - The main conversion engine
- **Font data** (`src/fonts/`) - Various bitmap fonts used in text art rendering
- **Loaders** (`src/loaders/`) - Format-specific parsers for different art file types
- **Public API** (`include/ansilove.h`) - Header file defining the library interface
- **Man pages** (`man/`) - Documentation for library functions
- **Examples** (`example/`) - Sample code showing how to use the library
- **Compatibility layer** (`compat/`) - Cross-platform compatibility functions

## Supported Formats

- ANSI (.ans) - ANSI art with color codes
- Binary (.bin) - Raw binary text files
- PCBoard (.pcb) - PCBoard BBS format
- Tundra (.tnd) - Tundra Draw format
- ArtWorx (.adf) - ArtWorx Data Format
- iCE Draw (.idf) - iCE Draw format
- XBin (.xb) - Extended Binary format

## What to do with it?

This reference implementation can be used to:

1. **Understand the conversion algorithms** - Study how different text art formats are parsed and rendered
2. **Reference the API design** - See how a clean C library API is structured
3. **Examine font rendering** - Learn about bitmap font rendering techniques
4. **Study format specifications** - Each loader implements a specific format's parsing logic
5. **Build integration** - Reference for linking against libansilove in your own projects

## Key Files to Study

- `include/ansilove.h` - Public API surface
- `src/loaders/ansi.c` - ANSI format parser (most common format)
- `src/drawchar.c` - Character rendering implementation
- `src/fonts/` - Bitmap font data structures
- `CMakeLists.txt` - Build configuration

## Building

```bash
cd libansilove
mkdir build && cd build
cmake ..
make
```

## Critical Learnings for Ansilust IR

### 1. Two-Pass Parsing Architecture

libansilove uses an intermediate representation pattern:

**Pass 1**: Parse file into character buffer, determine dimensions
```c
struct ansiChar {
    int32_t column, row;
    uint32_t background;  // Palette index OR 24-bit RGB
    uint32_t foreground;
    uint8_t character;    // CP437 code 0-255
};
```

**Pass 2**: Render character buffer to output (PNG)

**Key Insight**: The character buffer IS their intermediate representation. This validates our Cell Grid IR approach.

**File Reference**: `src/loaders/ansi.c:44-50`

### 2. Bitmap Font Structure

Fonts are simple byte arrays:
```c
const uint8_t font_pc_80x25[4096];  // 256 chars × 16 bytes/char

// Access character 'A' (65), scanline 5:
byte = font_data[65 * 16 + 5];
// Each bit = one pixel (MSB = leftmost)
```

**Critical**: XBin and ArtWorx files can embed custom fonts. Without the exact font, art looks wrong.

**File Reference**: `src/fonts/font_pc_80x25.h`

### 3. Character Set Encoding (CP437)

BBS art uses CP437 (DOS code page), not Unicode:
- Character 0-31: Special glyphs (not control codes!)
- Character 127: House symbol (⌂)
- Character 176-223: Box drawing characters
- Character 1 (☺), 2 (☻), 3 (♥)

**Our IR must preserve**: Original character encoding for reversibility.

### 4. 8-bit vs 9-bit Character Width

Critical rendering parameter affects box drawing:
- **8-bit mode**: Characters are 8 pixels wide
- **9-bit mode**: Characters are 9 pixels wide
  - Characters 192-223 (box drawing) get 9th column by duplicating bit 7
  - Creates seamless box drawing lines

**File Reference**: `src/drawchar.c:36-39`

**Our IR must preserve**: Bit width preference (8 vs 9).

### 5. Color Model: Dual Mode

libansilove handles BOTH palette and RGB in the same field:
```c
uint32_t foreground;  // Could be 0-15 OR 0xRRGGBB

// 24-bit color takes priority if set
if (foreground24) {
    use_color = foreground24;  // RGB
} else {
    use_color = foreground;     // Palette index
}
```

**File Reference**: `src/loaders/ansi.c:201-205`

**Our IR solution**: Use Color enum with variants for None, Palette, RGB.

### 6. iCE Colors Mode (CRITICAL!)

This single flag changes color interpretation:

**Normal mode** (iCE colors OFF):
- Foreground: 16 colors (0-15)
- Background: 8 colors (0-7)
- Blink attribute: Makes text blink

**iCE colors mode** (iCE colors ON):
- Foreground: 16 colors (0-15)
- Background: 16 colors (0-15)
- Blink bit repurposed: Enables high-intensity backgrounds (8-15)

```c
if (bold) foreground += 8;
if (blink && icecolors) background += 8;  // Only if iCE mode!
```

**File Reference**: `src/loaders/ansi.c:418-419, 443-444`

**Our IR must preserve**: iCE colors flag. Without it, colors will be wrong!

### 7. Format-Specific Quirks

**ANSI (.ans)** - `src/loaders/ansi.c`:
- Uses escape sequences
- Supports cursor positioning (non-linear)
- PabloDraw 24-bit extension: `ESC[<type>;<R>;<G>;<B>t`
- Default: 80 columns

**Binary (.bin)** - `src/loaders/binary.c`:
- Alternating byte pairs: character, attribute
- Attribute byte: `(bg << 4) | fg`
- No escape sequences, pure sequential
- Default: **160 columns** (not 80!)

**PCBoard (.pcb)** - `src/loaders/pcboard.c`:
- Uses `@X<bg><fg>` for colors (two hex digits)
- `@CLS@` for clear screen

**XBin (.xb)** - `src/loaders/xbin.c`:
- Self-contained binary format with header
- **Embedded custom palette** (16 RGB triplets)
- **Embedded custom font** (up to 512 characters)
- Optional RLE compression
- Width/height in header

**Tundra (.tnd)** - `src/loaders/tundra.c`:
- Always 24-bit color support
- Special escape codes for RGB values

### 8. Palette Variations

Three standard palettes in `src/config.h:28-71`:
- **ansi_palette**: Standard PC ANSI colors
- **vga_palette**: Standard VGA colors (slightly different)
- **workbench_palette**: Amiga Workbench colors

XBin/ArtWorx/iCE can embed custom 16-color palettes.

**Our IR must support**: Standard palette references AND custom embedded palettes.

### 9. DOS Aspect Ratio

Classic BBS art designed for CRT monitors with non-square pixels:
- VGA text mode: 720×400 pixels
- Aspect ratio correction: multiply height by 1.35

**File Reference**: `src/output.c:21-79`

**Our IR should preserve**: Aspect ratio hint for accurate rendering.

### 10. State Machine Parsing

All loaders use explicit state machines:
```c
#define STATE_TEXT      0  // Normal text mode
#define STATE_SEQUENCE  1  // Inside ANSI escape sequence
#define STATE_END       2  // EOF or SUB character
```

**File Reference**: `src/loaders/ansi.c:39-42`

**Lesson**: For parsing modern terminal output, use proper state machine, not regex.

### 11. Rendering Pipeline

```
Parse → Character Buffer (IR) → Render to GD Image → Output PNG
```

**Key insight**: GD library (`gdImagePtr`) is the rendering target, not a true IR. The character buffer array IS the IR.

### 12. No Animation Support

libansilove renders **static images only**. No frame sequences, no timing.

**Our value-add**: Support animation from day one (ansimation).

## What Our IR Must Preserve

1. **Character position** (column, row)
2. **Character code** (0-255, CP437 or other codepage)
3. **Foreground color** (palette index OR 24-bit RGB)
4. **Background color** (palette index OR 24-bit RGB)
5. **Font reference** (ID string) or embedded bitmap data
6. **iCE colors mode** (changes blink behavior)
7. **Letter spacing** (8 vs 9 bit)
8. **Aspect ratio hint** (DOS mode 1.35 or other)
9. **Palette** (standard reference OR custom embedded)
10. **Original format type** (for format-specific rendering)

## Integration Notes

When integrating this library or learning from it:
- The library is designed to be simple and focused
- No external dependencies beyond standard C library
- Clean separation between format parsing and rendering
- Font data is embedded directly in the library
- Character buffer pattern validates our Cell Grid IR approach
- Two-pass parsing is efficient and clean
