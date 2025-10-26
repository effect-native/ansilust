# Ansilust Project Status

**Last Updated**: 2024
**Language**: Zig
**License**: See LICENSE file

## 🎯 Project Mission

Build a next-generation text art processing system that unifies classic BBS art formats (ANSI, Binary, PCBoard, XBin) with modern terminal capabilities (UTF-8, true color, Unicode) through a unified Intermediate Representation (IR).

## 📊 Current Status: Phase 1 Complete - IR Scaffolding ✅

### Phase 1: Research & Design ✅ COMPLETE

- [x] Study libansilove (classic BBS art parsing)
- [x] Study Ghostty terminal (modern escape sequences)
- [x] Study OpenTUI (integration target)
- [x] Design IR schema (Cell Grid approach selected)
- [x] Document findings in `IR-RESEARCH.md`
- [x] Document architecture in `AGENTS.md`

### Phase 2: IR Module Scaffolding ✅ COMPLETE (Plan Phase 1)

**Location**: `src/ir/` (modular architecture)

All core modules implemented and tested:

**Core Infrastructure** ✅
- [x] `errors.zig` - Shared error set with 15 error types
- [x] `encoding.zig` - IANA MIBenum + vendor range (65024-65535)
- [x] `color.zig` - Color union (None/Palette/RGB) + palette tables
- [x] `attributes.zig` - 32-bit attribute flags + underline styles
- [x] `sauce.zig` - SAUCE metadata parsing (128-byte records)

**Cell Grid & Storage** ✅
- [x] `cell_grid.zig` - Structure-of-arrays layout
  - Parallel slices for source bytes, encoding, contents, colors, attributes
  - CellContents union (scalar u21 or grapheme ID)
  - Wide character flags (none/head/tail)
  - Dirty tracking for diff rendering
  - Bounds-checked accessors with proper error handling
- [x] `GraphemePool` - Multi-codepoint character storage
  - Arena allocation with deduplication
  - 1-based ID system (0 = no grapheme)

**Animation & Events** ✅
- [x] `animation.zig` - Frame-based animation
  - Snapshot frames (complete grid state)
  - Delta frames (coordinate-based updates)
  - LoopMode (once/infinite/count/pingpong)
  - Copy-on-write strategy
- [x] `hyperlink.zig` - OSC 8 hyperlink registry
  - URI + params storage
  - Deduplication by (URI, params)
  - Parameter parsing iterator
- [x] `event_log.zig` - Terminal event capture
  - Palette updates, mode changes, cursor visibility
  - Deterministic ordering with sequence IDs
  - Frame association for animations

**Document & Integration** ✅
- [x] `document.zig` - Root IR container
  - Integrates all subsystems
  - Convenience API (getCell, setCell, resize)
  - SAUCE hint application
  - Resource management (palettes, hyperlinks, fonts)
- [x] `document_builder.zig` - Safe construction facade (stub)
- [x] `serialize.zig` - Binary format support (stub)
- [x] `ghostty.zig` - Ghostty renderer bridge (stub)
- [x] `opentui.zig` - OpenTUI conversion (stub)

**Public API** ✅
- [x] `lib.zig` - Clean re-export layer
  - 50+ types exposed
  - Comprehensive module documentation

**Build & Tests** ✅
- All modules compile cleanly (`zig build` ✓)
- Test suite passing (`zig build test` ✓)
- Executable runs (`zig build run` ✓)
- **Test Coverage**: 40+ unit tests across all modules
  - Error handling and recoverability
  - Encoding validation and conversion
  - Color/palette operations
  - SAUCE parsing
  - Cell grid operations and iteration
  - Animation frame sequencing
  - Hyperlink management
  - Event log ordering

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

### Step 1: Core Cell Grid Implementation (Phase 2 of Plan) 👈

**Goal**: Complete cell grid implementation with grapheme pool and raw byte storage

**Status**: ✅ COMPLETE - All core functionality implemented

**Completed Tasks**:
1. ✅ Implemented structure-of-arrays cell grid layout
2. ✅ Created CellContents union (scalar vs grapheme)
3. ✅ Built grapheme pool with deduplication
4. ✅ Added wide character support (head/tail flags)
5. ✅ Implemented dirty tracking for diff rendering
6. ✅ Unit tests for bounds checks, iteration, resize

**Achievements**:
- 40+ unit tests passing
- Zero memory leaks (validated with std.testing.allocator)
- Proper error handling throughout
- Cache-friendly structure-of-arrays layout
- Ghostty-aligned semantics (color None, wrap flags)

**Reference Alignment**:
- ✅ Ghostty: Wide chars, color None, wrap semantics
- ✅ OpenTUI: Compatible cell grid structure
- ✅ libansilove: SAUCE preservation patterns

### Step 2: Metadata Systems (Phase 3 of Plan)

**Goal**: Complete palette, font, SAUCE, and attribute systems

**Status**: ✅ COMPLETE - All metadata modules implemented

**Completed Tasks**:
1. ✅ Color union with palette/RGB/None variants
2. ✅ Palette tables (ANSI, VGA, Workbench, custom)
3. ✅ Attribute bitflags (32-bit with underline styles)
4. ✅ SAUCE record parsing (128-byte + comments)
5. ✅ Font info with embedded bitmap support
6. ✅ Source encoding registry (IANA + vendor range)

### Step 3: Animation & Events (Phase 4 of Plan)

**Goal**: Implement animation frames, hyperlinks, and event log

**Status**: ✅ COMPLETE - Core structures implemented

**Completed Tasks**:
1. ✅ Animation with snapshot/delta frames
2. ✅ Hyperlink registry (OSC 8 support)
3. ✅ Event log with deterministic ordering
4. ✅ Frame association for events
5. ✅ Loop modes and timing metadata

### Step 4: Serialization & Render Bridges (Phase 5 of Plan - NEXT)

**Goal**: Binary format, Ghostty bridge, OpenTUI conversion

**Status**: 🚧 STUB - Ready for implementation

**Remaining Tasks**:
- [ ] Implement binary serializer/deserializer
- [ ] Build Ghostty stream renderer
- [ ] Create OpenTUI OptimizedBuffer conversion
- [ ] Integration tests with fixtures
- [ ] Property-based testing and fuzzers
- [ ] Performance benchmarks

## 📁 Project Structure

```
ansilust/
├── src/
│   ├── ir/                 ✅ IR Module (14 modules, 40+ tests)
│   │   ├── lib.zig         ✅ Public API re-exports
│   │   ├── errors.zig      ✅ Shared error set
│   │   ├── encoding.zig    ✅ IANA MIBenum + vendor range
│   │   ├── color.zig       ✅ Color union + palettes
│   │   ├── attributes.zig  ✅ 32-bit attribute flags
│   │   ├── sauce.zig       ✅ SAUCE metadata parsing
│   │   ├── cell_grid.zig   ✅ Structure-of-arrays layout
│   │   ├── animation.zig   ✅ Snapshot/delta frames
│   │   ├── hyperlink.zig   ✅ OSC 8 hyperlink registry
│   │   ├── event_log.zig   ✅ Terminal event capture
│   │   ├── document.zig    ✅ Root IR container
│   │   ├── document_builder.zig  🔲 Builder facade (stub)
│   │   ├── serialize.zig   🔲 Binary format (stub)
│   │   ├── ghostty.zig     🔲 Ghostty bridge (stub)
│   │   └── opentui.zig     🔲 OpenTUI conversion (stub)
│   ├── root.zig            ✅ Public API exports
│   ├── main.zig            ✅ CLI entry point
│   ├── parsers/            🔲 Not created yet
│   │   ├── ansi.zig        🔲 TODO: ANSI parser
│   │   ├── binary.zig      🔲 TODO: Binary parser
│   │   ├── pcboard.zig     🔲 TODO: PCBoard parser
│   │   └── xbin.zig        🔲 TODO: XBin parser
│   └── renderers/          🔲 Not created yet
│       ├── utf8ansi.zig    🔲 TODO: Modern terminal renderer
│       └── html.zig        🔲 TODO: HTML canvas renderer
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
zig build                    # ✅ Working

# Run tests (40+ tests)
zig build test              # ✅ All passing

# Run CLI demo
zig build run               # ✅ Working

# Format code
zig fmt src/ir/*.zig        # ✅ All formatted

# Analyze test corpus
bash scripts/analyze_corpus.sh

# Future: Parse ANSI file (Phase 5)
# zig build run -- parse reference/sixteencolors/1996/acid-50a/BS-ROCK1.ANS

# Future: Render to terminal (Phase 5)
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

2. **IR Approach**: Cell Grid with Structure-of-Arrays
   - OpenTUI-compatible from day one ✅
   - Cache-friendly parallel slices
   - Handles 100% of documented use cases
   - Ghostty semantics aligned (color None, wrap flags)

3. **Module Architecture**: 14 focused modules
   - Clear separation of concerns
   - Explicit allocator ownership
   - Comprehensive error handling
   - 40+ unit tests with zero leaks

4. **Color Representation**: Tagged union with three variants
   - `None` - Terminal default (distinct from black) ✅
   - `Palette(u8)` - Classic BBS palette indices ✅
   - `RGB(r, g, b)` - Modern 24-bit color ✅
   - Standard palettes: ANSI (16), VGA (256), Workbench (16)

5. **Encoding Strategy**: IANA MIBenum + vendor range
   - Standard encodings: CP437, UTF-8, ISO-8859-1, etc.
   - Vendor range (65024-65535) for PETSCII, ATASCII, etc.
   - Per-cell source encoding tracking
   - Raw byte preservation for lossless round-trips

6. **Animation Support**: Snapshot + delta frames
   - Copy-on-write strategy for memory efficiency
   - Frame timing (duration + delay)
   - Loop modes: once, infinite, count, pingpong
   - Event log association per frame

## 🐛 Known Issues & Limitations

- Parsers not yet implemented (main blocker for Phase 5)
- Renderers not yet implemented (main blocker for Phase 5)
- Serialization stubs need implementation
- Integration tests pending (need parsers first)
- Performance benchmarks pending (need larger test data)
- Test corpus limited to 1996 (can expand when parsers ready)

## 💡 Next Immediate Steps (Phase 5 Implementation)

1. **DocumentBuilder implementation**
   - Arena → slab allocator migration
   - Safe incremental construction
   - Finalization with invariant enforcement

2. **Binary serialization**
   - "ANSILUSTIR\0" header format
   - Section-based layout (metadata, grid, graphemes, etc.)
   - Versioning support
   - Round-trip tests

3. **ANSI Parser** (first parser)
   - CSI sequence parsing
   - CP437 decoding
   - SAUCE extraction
   - Screen buffer simulation
   - Test with sixteencolors corpus

4. **UTF8ANSI Renderer** (first renderer)
   - Ghostty-compatible output
   - SGR sequence optimization
   - Dirty-cell diff rendering
   - Hyperlink support (OSC 8)

5. **Integration & Testing**
   - Golden tests with corpus fixtures
   - Property-based tests
   - Fuzz testing
   - Performance benchmarks

## 💡 Future Enhancements (Post Phase 5)

- [ ] Additional parsers (Binary, PCBoard, XBin)
- [ ] HTML Canvas renderer
- [ ] Web viewer (WASM compilation)
- [ ] Animation player with timeline
- [ ] Font library with all SAUCE fonts
- [ ] Format auto-detection
- [ ] Expand corpus to 1995-1997

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