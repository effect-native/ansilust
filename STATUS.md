# Ansilust Project Status

**Last Updated**: 2024
**Language**: Zig
**License**: See LICENSE file

## 🎯 Project Mission

Build a next-generation text art processing system that unifies classic BBS art formats (ANSI, Binary, PCBoard, XBin) with modern terminal capabilities (UTF-8, true color, Unicode) through a unified Intermediate Representation (IR).

## 📊 Current Status: Foundation Complete ✅

### Phase 1: Research & Design ✅ COMPLETE

- [x] Study libansilove (classic BBS art parsing)
- [x] Study Ghostty terminal (modern escape sequences)
- [x] Study OpenTUI (integration target)
- [x] Design IR schema (Cell Grid approach selected)
- [x] Document findings in `IR-RESEARCH.md`
- [x] Document architecture in `AGENTS.md`

### Phase 2: Core IR Implementation ✅ COMPLETE

**File**: `src/ir.zig` (410 lines)

Core data structures implemented:

- [x] `AnsilustIR` - Main IR container
  - Cell grid storage (flattened `width × height`)
  - Reference-counted style table (Ghostty pattern)
  - Grapheme cluster map for multi-codepoint characters
  - Palette management (ANSI/VGA/Workbench/Custom)
  - Font information and embedded bitmap fonts
  - SAUCE metadata support
  - Rendering hints (iCE colors, letter spacing, aspect ratio)

- [x] `Cell` - Packed 64-bit cell structure
  - Unicode codepoint or CP437 character
  - Style ID (index into style table)
  - Flags (wide char, spacer, wrap, protected)

- [x] `Style` - Reference-counted style information
  - Foreground/background colors
  - Optional underline color
  - Rich attributes (bold, italic, faint, blink, etc.)
  - Hyperlink support

- [x] `Color` - Flexible color representation
  - None variant (terminal default ≠ black)
  - Palette index (0-255)
  - RGB 24-bit true color

- [x] `Attributes` - Packed bitflags
  - Bold, faint, italic, underline (normal/double/curly)
  - Blink, reverse, invisible, strikethrough, overline

- [x] `SauceRecord` - Complete SAUCE metadata
  - Title, author, group, date
  - Dimensions (columns, rows)
  - Flags (iCE colors, letter spacing, aspect ratio)
  - Font name
  - Comments array

- [x] `FontInfo` & `BitmapFont` - Font handling
  - Font ID references ("cp437", "topaz", etc.)
  - Embedded bitmap font data support

**Tests**: 4 test cases passing ✅
- IR creation and initialization
- Cell access and bounds checking
- Style table and reference counting
- Cell flags functionality

### Phase 3: Test Corpus 🚧 IN PROGRESS

**Location**: `reference/sixteencolors/`

Current corpus:
- **Size**: 35 MB
- **ANSI files**: 137 files
- **Animated files**: 6 files
- **Artpacks**: 9 packs (ACiD, iCE, Fire from 1996)
- **Also includes**: ASCII (11), Binary (3), XBin (3)

Coverage:
- ✅ Classic ANSI art from golden age (1996)
- ✅ ANSI animations (ansimations)
- ✅ Various file sizes (13 KB - 1.2 MB)
- ✅ Multiple art groups (ACiD, iCE, Fire)
- 🔲 Binary format (.BIN)
- 🔲 PCBoard format (.PCB)
- 🔲 Modern UTF-8 ANSI

**Documentation**: 
- `CORPUS.md` - Comprehensive corpus documentation
- `scripts/analyze_corpus.sh` - Corpus analysis tool

## 🚧 What's Not Done Yet

### Parsers (High Priority)

No parsers implemented yet. Need:

- [ ] **ANSI Parser** ← START HERE
  - Parse ANSI escape sequences
  - Extract SAUCE metadata
  - Handle CP437 encoding
  - Populate IR structure
  - Reference: `reference/libansilove/libansilove/src/loaders/ansi.c`

- [ ] **Binary Parser**
  - 160-column format
  - Reference: `reference/libansilove/libansilove/src/loaders/binary.c`

- [ ] **PCBoard Parser**
  - PCBoard BBS format
  - Reference: `reference/libansilove/libansilove/src/loaders/pcboard.c`

- [ ] **XBin Parser**
  - Extended Binary with embedded fonts
  - Reference: `reference/libansilove/libansilove/src/loaders/xbin.c`

- [ ] **UTF8ANSI Parser**
  - Modern terminal sequences (VT/xterm)
  - Reference: `reference/ghostty/ghostty/src/terminal/Parser.zig`

- [ ] **SAUCE Parser**
  - Standalone SAUCE metadata extractor
  - 128-byte footer parsing
  - Validation and error handling

### Renderers (Medium Priority)

No renderers implemented yet. Need:

- [ ] **UTF8ANSI Renderer**
  - Output modern terminal ANSI sequences
  - Target: Ghostty, Alacritty, Kitty, WezTerm
  - True color support
  - Unicode character handling

- [ ] **HTML Canvas Renderer**
  - Browser-based rendering
  - Canvas draw calls
  - Interactive display

- [ ] **OpenTUI Integration**
  - `to_optimized_buffer()` conversion function
  - Cell grid → Structure-of-arrays
  - Color → RGBA floats
  - Attributes → u8 bitflags

- [ ] **PNG Renderer**
  - Static image output (like ansilove)
  - Bitmap font rendering
  - Aspect ratio handling

### Animation Support (Lower Priority)

- [ ] Frame extraction from ansimations
- [ ] Delta operations between frames
- [ ] Timing/delay sequence handling
- [ ] Progressive rendering

### Testing & Validation

- [ ] Parser test suite
- [ ] Renderer test suite
- [ ] SAUCE metadata validation tests
- [ ] Roundtrip tests (parse → IR → render)
- [ ] Visual comparison with libansilove
- [ ] Fuzzing tests
- [ ] Regression test suite

## 🎯 Next Immediate Steps

### Step 1: ANSI Parser (YOU ARE HERE 👈)

**Goal**: Parse classic ANSI art files into IR

**Tasks**:
1. Create `src/parsers/ansi.zig`
2. Implement ANSI escape sequence parser
   - CSI sequences (cursor movement, SGR colors)
   - Character output (CP437 decoding)
   - Screen buffer management
3. Implement SAUCE reader
   - Detect 128-byte SAUCE record
   - Parse all fields
   - Validate checksums
4. Populate `AnsilustIR` structure
5. Test with corpus files

**Success Criteria**:
- Parse `reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS`
- Extract SAUCE metadata correctly
- Build valid IR with correct dimensions
- All cells populated with correct chars/colors

**Reference Implementation**:
- `reference/libansilove/libansilove/src/loaders/ansi.c`
- `reference/ansilove/ansilove/src/sauce.c`

### Step 2: UTF8ANSI Renderer

**Goal**: Output IR as modern terminal ANSI

**Tasks**:
1. Create `src/renderers/utf8ansi.zig`
2. Iterate through IR cell grid
3. Generate ANSI escape sequences
4. Optimize output (combine sequences, skip redundant codes)
5. Test output in modern terminals

**Success Criteria**:
- Render parsed ANSI art to terminal
- Visual comparison with original matches
- True color support works
- Unicode characters display correctly

### Step 3: Integration Test

**Goal**: End-to-end flow working

**Tasks**:
1. Update `src/main.zig` with CLI
2. Add subcommands: `parse`, `render`, `info`
3. Test: ANSI file → Parse → IR → Render → Terminal
4. Visual validation

## 📁 Project Structure

```
ansilust/
├── src/
│   ├── ir.zig              ✅ Core IR (410 lines, 4 tests passing)
│   ├── root.zig            ✅ Public API exports
│   ├── main.zig            ✅ CLI entry point (basic demo)
│   ├── parsers/            🔲 Not created yet
│   │   ├── ansi.zig        🔲 TODO: ANSI parser
│   │   ├── binary.zig      🔲 TODO: Binary parser
│   │   ├── pcboard.zig     🔲 TODO: PCBoard parser
│   │   ├── xbin.zig        🔲 TODO: XBin parser
│   │   └── sauce.zig       🔲 TODO: SAUCE metadata
│   └── renderers/          🔲 Not created yet
│       ├── utf8ansi.zig    🔲 TODO: Modern terminal renderer
│       ├── html.zig        🔲 TODO: HTML canvas renderer
│       └── opentui.zig     🔲 TODO: OpenTUI integration
├── reference/
│   ├── libansilove/        ✅ C reference implementation
│   ├── ansilove/           ✅ CLI reference
│   ├── ghostty/            ✅ Modern terminal reference
│   ├── opentui/            ✅ Integration target
│   └── sixteencolors/      ✅ Test corpus (35 MB, 137 ANSI files)
├── scripts/
│   └── analyze_corpus.sh   ✅ Corpus analysis tool
├── build.zig               ✅ Zig build configuration
├── AGENTS.md               ✅ Project architecture & plan
├── IR-RESEARCH.md          ✅ IR design research & proposals
├── CORPUS.md               ✅ Test corpus documentation
├── STATUS.md               ✅ This file
└── README.md               ✅ Project overview
```

## 🔧 Development Commands

```bash
# Build project
zig build

# Run tests
zig build test

# Run CLI demo
zig build run

# Analyze test corpus
bash scripts/analyze_corpus.sh

# Future: Parse ANSI file (not implemented yet)
# zig build run -- parse reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS

# Future: Render to terminal (not implemented yet)
# zig build run -- render reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS
```

## 📚 Key Documentation

- **[AGENTS.md](AGENTS.md)** - Complete project architecture, learnings from reference projects
- **[IR-RESEARCH.md](IR-RESEARCH.md)** - IR design research, three approaches evaluated
- **[CORPUS.md](CORPUS.md)** - Test corpus documentation and usage
- **[STATUS.md](STATUS.md)** - This file, current project status

## 🎓 Key Design Decisions Made

1. **Language**: Zig (not Rust as originally considered)
   - Better C interop with reference implementations
   - Manual memory management for precise control
   - Native terminal/graphics capabilities

2. **IR Approach**: Cell Grid (Approach 1 from research)
   - OpenTUI-compatible from day one
   - Simplest to implement
   - Handles 90% of use cases
   - Can evolve to Hybrid approach later if needed

3. **Style Storage**: Reference-counted style table
   - Memory efficient (Ghostty pattern)
   - Deduplicates identical styles
   - Fast style lookups

4. **Color Representation**: Enum with three variants
   - `None` - Terminal default (distinct from black)
   - `Palette(u8)` - Classic BBS palette indices
   - `RGB(r, g, b)` - Modern 24-bit color

5. **Font Handling**: Reference by ID with optional embedding
   - Default fonts by string ID ("cp437", "topaz")
   - Embedded bitmap data for XBin/ArtWorx formats

## 🐛 Known Issues & Limitations

- No parsers implemented yet (main blocker)
- No renderers implemented yet
- Animation support planned but not implemented
- Test corpus limited to 1996 (need more years)
- No modern UTF-8 ANSI samples in corpus yet

## 💡 Future Enhancements

- [ ] Expand corpus to 1995-1997 (peak ANSI years)
- [ ] Add modern terminal art samples
- [ ] Web viewer (WASM compilation)
- [ ] REST API for batch processing
- [ ] Font library with all SAUCE fonts
- [ ] Animation player/timeline editor
- [ ] Format auto-detection
- [ ] Lossless ANSI editing (save source operations)

## 🙏 Credits & References

**Inspired by**:
- [ansilove](https://github.com/ansilove/ansilove) - The legendary ANSI art converter
- [libansilove](https://github.com/ansilove/libansilove) - C library we study heavily
- [Ghostty](https://github.com/ghostty-org/ghostty) - Modern terminal for VT/xterm parsing
- [OpenTUI](https://github.com/opentui/opentui) - Our integration target

**Art Source**:
- [sixteencolors-archive](https://github.com/sixteencolors/sixteencolors-archive) - Historic artpack archive
- [16colo.rs](https://16colo.rs/) - Searchable ANSI art database

---

**Status Legend**:
- ✅ Complete
- 🚧 In Progress
- 🔲 Not Started
- 👈 Current Focus