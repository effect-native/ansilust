# Ansilust Project Status

**Last Updated**: 2025-10-26
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

- [ ] **ANSI Parser** ← START HERE
  - Status: Plain text path implemented (Phase 5A Cycle 1). Handles ASCII, LF, CR, TAB, SUB, CP437 mapping. No SGR/cursor handling yet.
  - Next: Implement cursor addressing, erase commands, SGR attributes, SAUCE interpretation, wrapping/scrolling.
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

### Step 1: ANSI Parser Cycle 1 (Phase 5A) ✅ COMPLETED (2025-10-26)

**Goal**: Implement ANSI parser via XP TDD cycles. Cycle 1 (plain text & control chars) implemented and passing.

**Completed Tasks**:
1. ✅ Added foundational tests covering ASCII, LF, CR, TAB, SUB, CP437 mapping
2. ✅ Implemented minimal parser handling sequential characters and basic control flow
3. ✅ Added CP437 extended decoding table
4. ✅ Ensured document metadata (source_format, encoding) set
5. ✅ Tests integrated with `zig build test`

**TODO (per plan)**:
- [ ] Cycle 2: SGR parsing and attribute application
- [ ] Cycle 3: Cursor positioning (CUP/CUU/CUD/CUF/CUB/etc.)
- [ ] Cycle 4: SAUCE metadata detection and hints
- [ ] Cycle 5: Wrapping, scrolling, bounds handling
- [ ] Integration: Corpus-based golden tests

### Step 2: Extend Parsers (Phases 5B–5G)

Blocked until ANSI parser cycles complete.

### Step 3: Renderers & Serialization (Phase 5+)

Pending parser completion.
