# Ansilust Test Corpus

This directory contains a curated collection of historic ANSI/ASCII art files from the [sixteencolors-archive](https://github.com/sixteencolors/sixteencolors-archive) used for testing and validating the ansilust parsers and renderers.

## Current Contents

### Summary Statistics
- **Total Size**: ~35 MB
- **ANSI Files**: 131+ files
- **Animated Files**: 7 files
- **Artpacks**: 9 packs from 1996
- **Groups Represented**: ACiD, iCE, Fire

### Directory Structure

```
reference/sixteencolors/
├── animated/              # ANSI animations (ansimations)
│   ├── FILE_ID-ANSIMATION.ANS       (24 KB)
│   ├── FIREWORK.ANS                  (13 KB)
│   ├── SHUTTLE2.ANS                  (15 KB)
│   ├── SI-INT13.ANS                 (383 KB) - Large animation
│   ├── WZKM-MERMAID.ANS             (1.2 MB) - Very large animation
│   └── __BLOCKTRONICS_Detention_Block_AA-23_Animated_NFO_File.ans
│
└── 1996/                  # Golden age artpacks (peak ANSI era)
    ├── acid-50a/          # ACiD Productions pack 50a
    ├── acid-51a/          # ACiD Productions pack 51a
    ├── acid-52/           # ACiD Productions pack 52
    ├── fire0296/          # Fire artpack Feb 1996
    ├── fire0496/          # Fire artpack Apr 1996
    ├── fire0696/          # Fire artpack Jun 1996
    ├── ice9601a/          # iCE Advertisements pack Jan 1996
    ├── ice9602a/          # iCE Advertisements pack Feb 1996
    └── ice9603a/          # iCE Advertisements pack Mar 1996
```

## File Types in Corpus

### ANSI Files (.ANS)
Standard ANSI art with escape sequences:
- Text positioning (cursor movement)
- Color codes (SGR sequences)
- Character drawing (CP437 encoding)
- SAUCE metadata (128-byte footer)

**Examples**:
```bash
reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS
reference/sixteencolors/1996/fire0296/TNT-AE1.ANS
```

### Animated ANSI Files
ANSI files with time-delay sequences for animation:
- Frame-based animations using cursor positioning
- Delay sequences (ESC[<n>q or similar)
- Progressive drawing effects
- Can be very large (1+ MB for complex animations)

**Examples**:
```bash
reference/sixteencolors/animated/FIREWORK.ANS       # Simple firework effect
reference/sixteencolors/animated/SI-INT13.ANS       # Medium complexity (383 KB)
reference/sixteencolors/animated/WZKM-MERMAID.ANS   # Complex animation (1.2 MB)
```

### Other Files in Artpacks
Each artpack preserves historical context with:
- `FILE_ID.DIZ` - Pack description (standard in all scene releases)
- `*.NFO` - Information files
- `*.EXE` - Original viewers/installers
- `*.TXT` - Documentation
- ASCII art files (`.ASC`, `.TXT`)
- Binary art files (`.BIN`)

## Testing Strategy

### Phase 1: Simple ANSI Files
Start with basic static ANSI art (no animation):

```bash
# Small, well-formed files from ACiD packs
reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS
reference/sixteencolors/1996/acid-50a/KM-FIFTY.ANS
reference/sixteencolors/1996/fire0296/*.ANS
```

**Test Coverage**:
- Basic ANSI escape sequences
- CP437 character encoding
- Standard 16-color palette
- SAUCE metadata parsing
- Column width detection

### Phase 2: Edge Cases
Test files with specific features:

```bash
# iCE color mode (high-intensity backgrounds)
reference/sixteencolors/1996/ice9601a/*.ANS

# Various widths and heights
# (Some files may be 40-col, 80-col, or 160-col)
```

**Test Coverage**:
- iCE colors flag
- Non-standard dimensions
- Different fonts specified in SAUCE
- Custom palettes

### Phase 3: Animations
Test animated ANSI files:

```bash
# Progressive complexity
reference/sixteencolors/animated/FIREWORK.ANS       # Simple (13 KB)
reference/sixteencolors/animated/SHUTTLE2.ANS       # Medium (15 KB)
reference/sixteencolors/animated/SI-INT13.ANS       # Complex (383 KB)
```

**Test Coverage**:
- Frame extraction
- Delay sequences
- Cursor save/restore
- Clear screen operations
- Progressive rendering

### Phase 4: Stress Testing
Large and complex files:

```bash
# Very large animation
reference/sixteencolors/animated/WZKM-MERMAID.ANS   # 1.2 MB

# Full artpack fuzzing
find reference/sixteencolors/1996 -name "*.ANS" | xargs ./ansilust-test
```

**Test Coverage**:
- Memory efficiency
- Performance benchmarks
- Parser robustness
- Malformed sequence handling

## Expanding the Corpus

### Adding More Years

The sixteencolors-archive has packs from **1990-2023**. Peak years:
- **1995-1996**: Golden age, 500+ packs/year
- **1997-1999**: Still very active
- **2010+**: Modern revival with BlockTronics, Impure

**Download Process**:
```bash
# 1. Survey available packs for a year
./reference/sixteencolors/analyze_archive_sizes.py 1995

# 2. Download packs from GitHub
wget https://github.com/sixteencolors/sixteencolors-archive/raw/master/1995/PACKNAME.zip

# 3. Extract into year directory
unzip PACKNAME.zip -d reference/sixteencolors/1995/PACKNAME/

# 4. Keep original zip for archival
mv PACKNAME.zip reference/sixteencolors/1995/
```

### Recommended Additions

**Priority 1: Format Diversity**
- Binary art files (`.BIN`) - 160-column format
- PCBoard files (`.PCB`) - PCBoard BBS format
- XBin files (`.XB`) - Extended Binary format with embedded fonts
- Tundra Draw files (`.TND`)
- ArtWorx files (`.ADF`)

**Priority 2: More Animations**
Search for packs tagged with "ansimation" on 16colo.rs

**Priority 3: Modern UTF-8 ANSI**
Terminal-native artwork from modern tools:
- Generated by modern terminal applications
- Uses 24-bit color (true color)
- Unicode characters beyond CP437
- Modern escape sequences (Kitty graphics, Sixel)

## Using the Corpus

### With libansilove (Reference Implementation)
```bash
# Convert to PNG
./reference/libansilove/build/ansilove \
  reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS

# Fuzz test entire 1996 collection
./reference/libansilove/fuzz-build/ansi \
  -runs=10000 reference/sixteencolors/1996/
```

### With Ansilust (This Project)
```bash
# Parse to IR and validate
./zig-out/bin/ansilust parse reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS

# Render to modern terminal
./zig-out/bin/ansilust render --utf8ansi \
  reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS

# Batch test all files
find reference/sixteencolors -name "*.ANS" | \
  xargs -I {} ./zig-out/bin/ansilust test {}
```

### Validation Workflow
1. **Parse**: Can we read the file without errors?
2. **IR Roundtrip**: Parse → IR → Validate structure
3. **Render**: IR → UTF8ANSI output to terminal
4. **Compare**: Visual comparison with libansilove PNG output
5. **SAUCE**: Verify metadata extraction matches spec

## Known Issues and Edge Cases

### iCE Colors
Some iCE pack files use the iCE colors extension:
- Blink bit repurposed for high-intensity backgrounds
- Must be detected from SAUCE flags or file source
- Affects color interpretation

### Font Variations
SAUCE metadata may specify fonts:
- `IBM VGA` (default, CP437, 8x16)
- `IBM VGA 9x16` (9-pixel width for box drawing)
- `Amiga Topaz` (different character set)
- `Amiga Microknight` 
- 38+ font variations total

### Non-Standard Formats
Some files may have:
- No SAUCE metadata (older files)
- Incorrect SAUCE data (manual editing)
- Mixed line endings (CR, LF, CRLF)
- Truncated or corrupted data

### Animations
ANSI animations have no standard:
- Various delay mechanisms used
- Some use ESC[<n>q, others use timing tricks
- Frame boundaries are implicit
- May require specific terminal emulator behavior

## Corpus Metadata

### Provenance
All files sourced from: https://github.com/sixteencolors/sixteencolors-archive

### License
Original artworks are copyright their respective artists and groups. This corpus is maintained for:
- Software testing and validation
- Format preservation
- Educational purposes
- Historical archiving

### Attribution
Groups represented in current corpus:
- **ACiD Productions** - Legendary art group (1990-present)
- **iCE Advertisements** - Major competitor to ACiD
- **Fire** - Independent artpack group
- **BlockTronics** - Modern revival group
- Various independent artists

## Resources

### Tools
- [ansilove](https://github.com/ansilove/ansilove) - Reference ANSI-to-PNG converter
- [libansilove](https://github.com/ansilove/libansilove) - C library
- [sauce](https://github.com/ansilove/sauce) - SAUCE metadata utility

### Archives
- [16colo.rs](https://16colo.rs/) - Searchable online archive
- [sixteencolors-archive](https://github.com/sixteencolors/sixteencolors-archive) - GitHub mirror
- [textfiles.com](http://artpacks.textfiles.com/) - Jason Scott's archive

### Specifications
- [SAUCE Specification](https://www.acid.org/info/sauce/sauce.htm) - Standard metadata format
- [ANSI Art Guide](https://16colo.rs/info) - Format documentation
- [CP437 Code Page](https://en.wikipedia.org/wiki/Code_page_437) - Character encoding

## Next Steps

1. **Expand coverage** to 1995-1997 (peak years)
2. **Add format variety** (BIN, PCB, XBin)
3. **Create test suite** with expected outputs
4. **Document edge cases** found during testing
5. **Build regression tests** using corpus files
6. **Automated validation** against libansilove