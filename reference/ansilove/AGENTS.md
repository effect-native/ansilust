# ansilove Reference

## What is ansilove?

ansilove is a command-line tool (ANSI/ASCII art to PNG converter) that uses libansilove to convert text-based art files into PNG images. It provides a simple CLI interface to the library functionality.

## Contents

The `ansilove/` submodule contains:

- **CLI implementation** (`src/ansilove.c`) - Command-line argument parsing and file handling
- **SAUCE metadata support** (`src/sauce.c`, `src/sauce.h`) - Parser for SAUCE (Standard Architecture for Universal Comment Extensions) metadata
- **Security hardening** (`src/seccomp.h`) - Linux seccomp sandboxing
- **Compatibility layer** (`compat/`) - Cross-platform support (pledge, strtonum)
- **Man page** (`man/ansilove.1`) - User documentation
- **Test files** (`tests/`) - Sample art files for testing
- **Examples** (`examples/`) - Example art files in various formats

## What to do with it?

This reference implementation can be used to:

1. **Understand CLI design** - See how to build a clean command-line interface around a library
2. **Learn argument parsing** - Study how file formats and options are handled
3. **Study SAUCE metadata** - Learn about the SAUCE standard used in text art files
4. **Examine security practices** - See Linux pledge/seccomp sandboxing in action
5. **Reference example files** - Use test files to understand different format characteristics
6. **Build integration patterns** - Learn how to wrap libansilove for different use cases

## Command-Line Interface

Basic usage pattern:
```bash
ansilove [options] <input-file>
```

Key options include:
- Font selection
- Output file specification
- Format-specific rendering options
- Columns/bits configuration for binary files

## Key Files to Study

- `src/ansilove.c` - Main CLI implementation
- `src/sauce.c` - SAUCE metadata parsing
- `src/config.h` - Configuration and constants
- `man/ansilove.1` - Complete documentation
- `tests/` - Example files in various formats
- `CMakeLists.txt` - Build system

## SAUCE Metadata (CRITICAL!)

SAUCE (Standard Architecture for Universal Comment Extensions) is a **128-byte** record appended to the end of files. Before touching IR metadata or SAUCE handling, revisit [`.specs/ir/prior-art-notes.md`](../../.specs/ir/prior-art-notes.md#ansilove-referenceansilove), then re-read `src/ansilove.c` (SAUCE detection + rendering hints) and `src/sauce.c` (record parsing) so the exact behavior stays fresh.

### SAUCE Record Structure

**File Reference**: `src/sauce.h:27-45`

```c
struct sauce {
    char ID[6];              // "SAUCE" + null terminator
    char version[3];         // Version string (usually "00")
    char title[36];          // Artwork title
    char author[21];         // Artist name
    char group[21];          // Artist group/affiliation
    char date[9];            // Creation date (CCYYMMDD format)
    int32_t fileSize;        // Original file size (before SAUCE)
    unsigned char dataType;  // Data type category
    unsigned char fileType;  // File type within category
    unsigned short tinfo1;   // Type-specific info 1 (COLUMNS!)
    unsigned short tinfo2;   // Type-specific info 2 (ROWS!)
    unsigned short tinfo3;   // Type-specific info 3
    unsigned short tinfo4;   // Type-specific info 4
    unsigned char comments;  // Number of comment lines
    unsigned char flags;     // Flag bits (iCE colors, aspect, etc.)
    char tinfos[23];         // Font name string
};
```

### File Location

- SAUCE record: **EOF - 128 bytes**
- Comments block (if any): **EOF - (128 + 5 + 64×comments)** bytes
- Comments start with "COMNT" identifier (5 bytes)
- Each comment line: 64 characters

**File Reference**: `src/sauce.c:59`

### Rendering-Critical Metadata

#### 1. Columns (tinfo1) - **CRITICAL**

**File Reference**: `src/ansilove.c:204,214,220`

- For ANS/PCB files: tinfo1 = column width
- For BIN files: tinfo1 = column width
- Default: 80 columns for ANS, 160 for BIN

**Without correct columns**: Layout is completely broken!

#### 2. Flags Byte - **CRITICAL**

**File Reference**: `src/ansilove.c:206-210`

```c
// Bit 0 (flags & 1): iCE colors enabled
// When set: 16 background colors (no blink)
// When clear: 8 background colors + blink

// Bits 1-2 (flags & 6): Letter spacing
// Value 4: 9-bit mode (render 9th column of block chars)

// Bits 3-4 (flags & 24): Aspect ratio
// Value 8: DOS aspect ratio enabled
```

**Without correct flags**: Colors and character width are wrong!

#### 3. Font Name (tinfos)

**File Reference**: `src/ansilove.c:225-299`

Maps SAUCE font strings to internal fonts:
- "IBM VGA" → 80x25 (CP437)
- "IBM VGA50" → 80x50 (CP437)
- "IBM VGA 437" → 80x25
- "IBM VGA 775" → Baltic
- "IBM VGA 850" → Latin1
- "Amiga Topaz 2" → topaz
- "Amiga MicroKnight" → microknight
- Plus 30+ more fonts

**Without correct font**: Wrong glyphs, completely changes appearance!

#### 4. DataType and FileType

**File Reference**: `src/ansilove.c:202-221`

- dataType 1 = Character-based (ANS/PCB)
  - fileType 0,1,2 = ANS variants
  - fileType 8 = Avatar
- dataType 5 = Binary
- dataType 6 = XBin

Determines which loader to use.

### Example SAUCE Record

From `tests/bs-alove.ans`:
```
SAUCE00ansilove                         burps           fuel            20171019
```

Parsed fields:
- ID: "SAUCE00"
- Title: "ansilove"
- Author: "burps"
- Group: "fuel"
- Date: "20171019" (Oct 19, 2017)
- tinfo1: 0x0050 = 80 columns
- tinfo2: 0x003b = 59 rows
- Font: "IBM VGA" (default PC font)

## Building

```bash
cd ansilove
mkdir build && cd build
cmake ..
make
```

## Rendering Options (Command-Line)

### Critical Options

**File Reference**: `src/ansilove.c:103-168`

#### `-b bits` (8 or 9)
- Default: 8
- **9-bit mode**: Renders 9th column of box drawing characters (192-223)
- Creates seamless box drawing lines

#### `-c columns`
- Range: 1-4096
- Default: **80 for ANS/PCB/TND**, **160 for BIN**
- **Critical for layout**: Wrong columns = wrapped/truncated lines

#### `-i` iCE colors
- Enables 16 background colors (disables blink attribute)
- Default: disabled (8 backgrounds + blink)
- **Impact**: Completely changes color interpretation

#### `-d` DOS aspect
- Enables DOS aspect ratio correction (×1.35 height)
- Matches CRT display proportions

#### `-f font`
- 38 fonts available
- PC fonts: CP437 (80x25, 80x50), CP737-CP869
- Amiga fonts: topaz, microknight, mosoul, pot-noodle
- Modern fonts: spleen, terminus

#### `-S` Use SAUCE
- Apply SAUCE metadata as rendering hints
- Overrides command-line options with SAUCE values

### Options Structure

```c
struct ansilove_options {
    bool diz;           // .diz file (special handling)
    bool dos;           // DOS aspect ratio
    bool icecolors;     // iCE colors mode
    bool truecolor;     // 24-bit color (Tundra)
    int16_t columns;    // Column width
    uint8_t font;       // Font ID
    uint8_t bits;       // 8 or 9 bit mode
    uint8_t mode;       // Rendering mode (ced/transparent/workbench)
    uint8_t scale_factor; // Retina scaling (0=none, 2-8=factor)
};
```

## Test Files and Format Variations

**File Reference**: `tests/` directory

| File | Size | Format | Notes |
|------|------|--------|-------|
| bs-alove.ans | 8,963 | ANSI | Escape sequences, 80×59, SAUCE |
| bs-alove.bin | 9,567 | Binary | Raw char+attr pairs, larger (no compression) |
| bs-alove.pcb | 7,591 | PCBoard | @X color codes, smaller (efficient) |
| bs-alove.tnd | 12,544 | Tundra | 24-bit color support, largest |
| bs-alove.adf | 14,646 | ArtWorx | Custom charset/palette |
| bs-alove.xb | 8,303 | XBin | Self-contained with header |

### Format Feature Matrix

| Format | Custom Palette | Custom Font | Compression | SAUCE Usage |
|--------|---------------|-------------|-------------|-------------|
| ANS    | No            | No          | Yes (ESC)   | Heavy       |
| BIN    | No            | No          | No          | Medium      |
| PCB    | No            | No          | Yes (@X)    | Medium      |
| TND    | 24-bit        | No          | No          | Medium      |
| ADF    | Yes           | Yes         | No          | Light       |
| IDF    | Yes           | Yes         | No          | Light       |
| XB     | Yes           | Yes         | Optional    | Light       |

## Critical Learnings for Ansilust IR

### What Our IR MUST Preserve

1. **SAUCE Record** - Complete structure with all fields
   - Artist attribution (title, author, group, date)
   - Rendering hints (columns, rows, flags, font)
   - Comments (multi-line artist notes)

2. **Rendering Flags** - From SAUCE flags byte
   - iCE colors mode (bit 0)
   - Letter spacing 8/9 bit (bits 1-2)
   - DOS aspect ratio (bits 3-4)

3. **Font Information**
   - Font name string from SAUCE tinfos
   - Or font ID from command-line override

4. **Dimensions**
   - Columns (tinfo1) - **CRITICAL FOR LAYOUT**
   - Rows (tinfo2)

5. **Format Type**
   - Original format (dataType, fileType)
   - Affects rendering behavior

### SAUCE is NOT Optional

Many rendering parameters depend on SAUCE:
- Without correct **columns**: Layout breaks
- Without **iCE colors flag**: Colors wrong
- Without **font name**: Glyphs wrong
- Without **flags**: Character width wrong

**Our IR must**: Preserve complete SAUCE record and apply it intelligently.

## Integration Notes

When building CLI tools or learning from this:
- Clean separation between CLI logic and library calls
- Robust error handling and user feedback
- Security hardening on supported platforms
- Comprehensive man page documentation
- Test files provide format validation
- **SAUCE metadata is essential**, not optional
- Command-line options can override SAUCE values
