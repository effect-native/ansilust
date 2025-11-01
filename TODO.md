# Ansilust TODO

## Critical Issues

### UTF8ANSI Renderer - Use 24-bit Colors by Default
**Status**: ⚠️ Spec updated, implementation may need adjustment  
**Priority**: HIGH  
**Updated**: 2025-11-01

The UTF8ANSI renderer spec has been updated to use 24-bit truecolor by default instead of 8-bit (256-color) mode.

**Rationale**: 8-bit 256-color palette indices cannot be trusted across different terminal emulators. Each terminal may map the same index to different RGB values, causing color inconsistencies in artwork. By emitting explicit 24-bit RGB values, we ensure the artist's intended colors are displayed consistently regardless of terminal configuration.

**Reference**: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

**Spec Updates**:
- `.specs/render-utf8ansi/instructions.md` - Changed default to 24-bit, added `--256color` flag
- `.specs/render-utf8ansi/requirements.md` - Updated FR1.2.2-FR1.2.5 with rationale
- `.specs/render-utf8ansi/design.md` - Updated color emission strategy
- `.specs/render-utf8ansi/plan.md` - Updated Cycle 4 and Cycle 7 implementation plans

**Implementation Status**:
- ✅ Current implementation (src/renderers/utf8ansi.zig) already supports both modes
- ⚠️ May need to verify default behavior matches new spec (24-bit by default)
- ⚠️ CLI may need `--256color` flag instead of `--truecolor`

**Required Actions**:
- [ ] Verify current default color mode in implementation
- [ ] Update CLI flags if needed (`--256color` instead of `--truecolor`)
- [ ] Update tests to reflect new default behavior
- [ ] Validate colors are consistent across terminals (Ghostty, Alacritty, Kitty, etc.)

### Batch/Wildcard File Processing
**Status**: ❌ Not implemented  
**Priority**: HIGH

Must support processing multiple files with wildcards and gracefully skip unsupported formats.

**Test case**:
```bash
# Should render all supported files, skip unsupported ones
zig build run -- reference/sixteencolors/fire-43/*

# Expected behavior:
# - Process .ANS files ✅
# - Skip .BIN files (with message: "Skipping FILE.BIN: Binary format not yet supported")
# - Skip .PCB files (with message: "Skipping FILE.PCB: PCBoard format not yet supported")
# - Exit code: 0 (success even if some files skipped)
```

**Required**:
- Accept multiple file arguments
- Detect file format (extension + magic bytes)
- Process supported formats
- Skip unsupported formats with informative message
- Continue processing remaining files after errors
- Return success if at least one file processed successfully

### Format Support - All Historic Art Formats
**Status**: ❌ Not implemented  
**Priority**: HIGH

Must support ALL historic BBS art formats to handle the complete 16colo.rs archive.

**Supported Formats (Target)**:

1. **ANSI (.ANS)** - ✅ Partially implemented (CP437, needs attributes)
   - Reference: `reference/libansilove/libansilove/src/loaders/ansi.c`
   - Extensions: `.ANS`, `.ANSI`

2. **Binary (.BIN)** - ❌ Not implemented
   - 160-column CP437 format
   - Reference: `reference/libansilove/libansilove/src/loaders/binary.c`
   - Extensions: `.BIN`

3. **PCBoard (.PCB)** - ❌ Not implemented
   - PCBoard BBS format with @X color codes
   - Reference: `reference/libansilove/libansilove/src/loaders/pcboard.c`
   - Extensions: `.PCB`

4. **XBin (.XB)** - ❌ Not implemented
   - Extended Binary with embedded fonts and palette
   - Reference: `reference/libansilove/libansilove/src/loaders/xbin.c`
   - Extensions: `.XB`, `.XBIN`

5. **Tundra (.TND)** - ❌ Not implemented
   - TheDraw format (TND/IDF)
   - Reference: `reference/libansilove/libansilove/src/loaders/tundra.c`
   - Extensions: `.TND`, `.IDF`

6. **IceDraw (.IDF)** - ❌ Not implemented
   - IceDraw format
   - Reference: `reference/libansilove/libansilove/src/loaders/icedraw.c`
   - Extensions: `.IDF`

7. **Artworx (.ADF)** - ❌ Not implemented
   - Artworx Data Format
   - Reference: `reference/libansilove/libansilove/src/loaders/artworx.c`
   - Extensions: `.ADF`

8. **DurDraw (.DUR)** - ❌ Not implemented
   - DurDraw native format
   - Modern ANSI editor format
   - Research: https://github.com/cmang/durdraw
   - Extensions: `.DUR`

9. **DarkDraw (.DD)** - ❌ Not implemented
   - DarkDraw native format
   - Modern ANSI editor format
   - Research: https://github.com/mkrueger/DarkDraw (if available)
   - Extensions: `.DD` (TBD)

**PabloDraw Formats** (TODO: Research):
- [ ] Research all formats supported by PabloDraw
- [ ] Cross-reference with libansilove loaders
- [ ] Identify any additional formats not in libansilove

**Modern Editor Formats** (TODO: Research):
- [ ] DurDraw: Research .DUR format specification
- [ ] DarkDraw: Research native format (if exists)
- [ ] Check if these editors have proprietary formats or just use standard ANSI/XBin

**UTF8ANSI Art in the Wild**:
- [ ] Search GitHub for `.utf8ansi` files
- [ ] Search 16colo.rs for UTF-8 encoded art
- [ ] Check modern terminal art repositories
- [ ] Search Discord/IRC art communities for UTF-8 ANSI
- [ ] Check r/ansiart and similar communities
- [ ] Look for terminal art using Unicode block characters
- [ ] Check modern roguelike/ASCII game assets

**Corpus Collection Strategy**:

```bash
# For EACH format, search 16colo.rs to find ALL historic art
# Examples:

# 1. Binary files
# Search: https://16colo.rs/search?format=binary
# Download representative samples from different eras/groups

# 2. XBin files
# Search: https://16colo.rs/search?format=xbin
# Download all XBin files (likely small corpus)

# 3. PCBoard files
# Search: https://16colo.rs/search?format=pcboard
# Download samples

# 4. Tundra/IceDraw files
# Search: https://16colo.rs/search?format=tundra
# Download samples

# 5. Artworx files
# Search: https://16colo.rs/search?format=artworx
# Download samples
```

**Required Actions**:

- [ ] **Corpus Collection**: Search 16colo.rs for EACH format
  - [ ] Binary (.BIN)
  - [ ] XBin (.XB)
  - [ ] PCBoard (.PCB)
  - [ ] Tundra (.TND)
  - [ ] IceDraw (.IDF)
  - [ ] Artworx (.ADF)
  - [ ] DurDraw (.DUR) - Check DurDraw repo for samples
  - [ ] DarkDraw (.DD) - Check DarkDraw repo for samples
  - [ ] UTF8ANSI (.utf8ansi) - **Find examples in the wild**
  - [ ] Any PabloDraw-specific formats

- [ ] **UTF8ANSI Discovery**:
  - [ ] Search GitHub for UTF8ANSI art
  - [ ] Check modern terminal art communities
  - [ ] Look for Unicode/emoji ANSI art
  - [ ] Test output from modern terminal tools
  - [ ] Create reference corpus of UTF8ANSI files

- [ ] **Download Representative Samples**:
  - At least 10-20 files per format
  - Cover different eras (1990s-2000s)
  - Cover different art groups (ACiD, iCE, etc.)
  - Include edge cases (huge files, minimal files, corrupted files)

- [ ] **Organize Corpus**:
  - `reference/sixteencolors/binary/` - Binary format files
  - `reference/sixteencolors/xbin/` - XBin files
  - `reference/sixteencolors/pcboard/` - PCBoard files
  - `reference/sixteencolors/tundra/` - Tundra/TheDraw files
  - `reference/sixteencolors/icedraw/` - IceDraw files
  - `reference/sixteencolors/artworx/` - Artworx files
  - Update `CORPUS.md` with inventory

- [ ] **Implement Parsers** (in priority order):
  1. Binary (.BIN) - Most common after ANSI
  2. XBin (.XB) - Extended format with fonts
  3. PCBoard (.PCB) - BBS specific
  4. Tundra/IceDraw (.TND/.IDF) - Editor formats
  5. Artworx (.ADF) - Less common

**Philosophy**:
- Support ALL formats (even if we can't render ALL features)
- Graceful degradation (render what we can, note what we skip)
- Clear error messages for unsupported features
- No freezing or crashes on any valid art file

### Corpus Expansion - Complete Historic Archive
**Status**: 🚧 In progress  
**Priority**: HIGH (Required for comprehensive format support)

Build a complete test corpus covering ALL historic BBS art formats.

**Current corpus**:
- `reference/sixteencolors/fire-43/` - ANSI files (13 files)
- `reference/sixteencolors/animated/` - Ansimations (6 files)

**Target corpus structure**:
```
reference/sixteencolors/
├── ansi/           # ANSI format (.ANS, .ANSI)
├── binary/         # Binary format (.BIN)
├── xbin/           # XBin format (.XB, .XBIN)
├── pcboard/        # PCBoard format (.PCB)
├── tundra/         # Tundra/TheDraw (.TND)
├── icedraw/        # IceDraw format (.IDF)
├── artworx/        # Artworx format (.ADF)
├── durdraw/        # DurDraw format (.DUR)
├── darkdraw/       # DarkDraw format (.DD or similar)
├── animated/       # Ansimations (all formats)
├── edge-cases/     # Corrupted, 0-byte, huge files
└── modern/         # Modern UTF-8 ANSI
```

**Collection Tasks**:

1. **Search 16colo.rs by format**:
   - [ ] Visit https://16colo.rs/
   - [ ] Use format filter for each type
   - [ ] Download 10-20 representative files per format
   - [ ] Include variety: small/large, simple/complex, different groups

2. **Specific format searches on 16colo.rs**:
   - [ ] Binary: https://16colo.rs/search?format=binary
   - [ ] XBin: https://16colo.rs/search?format=xbin
   - [ ] PCBoard: https://16colo.rs/search?format=pcboard
   - [ ] Tundra: https://16colo.rs/search?format=tundra
   - [ ] IceDraw: https://16colo.rs/search?format=icedraw
   - [ ] Artworx: https://16colo.rs/search?format=artworx

3. **Modern format samples**:
   - [ ] DurDraw: Check DurDraw examples/samples directory
   - [ ] DarkDraw: Check DarkDraw examples/samples
   - [ ] Create test files with modern editors

4. **UTF8ANSI art collection**:
   - [ ] Search GitHub: `extension:utf8ansi`
   - [ ] Search GitHub: `filename:.utf8ansi`
   - [ ] Search modern art repositories
   - [ ] Create samples by rendering ANSI → UTF8ANSI
   - [ ] Test with various terminal emulators

5. **Download complete artpacks**:
   - [ ] ACiD packs (various years)
   - [ ] iCE packs (various years)
   - [ ] Multiple groups for format diversity
   - [ ] **Blocktronics artpacks**: `git submodule add https://github.com/blocktronics/artpacks reference/artpacks/blocktronics`
   - [ ] Other modern art groups from GitHub

6. **Edge case collection**:
   - [ ] Find minimal files (1 character)
   - [ ] Find huge files (>1MB)
   - [ ] Find corrupted/malformed files
   - [ ] Create synthetic test cases

7. **Git submodules for reference materials**:
   - [ ] `git submodule add https://github.com/blocktronics/moebius reference/editors/moebius`
   - [ ] `git submodule add https://github.com/blocktronics/artpacks reference/artpacks/blocktronics`
   - [ ] Clone other ANSI editor repos as submodules
   - [ ] Document submodule usage in README

8. **Documentation**:
   - [ ] Update `CORPUS.md` with:
     - File count per format
     - Size statistics
     - Notable files
     - Format-specific notes
   - [ ] Create `reference/sixteencolors/README.md` with corpus overview

### UTF8ANSI Roundtrip Support
**Status**: ✅ COMPLETE  
**Priority**: HIGH

Ansilust must support both CP437 and UTF8ANSI as input types without issues.

**Test case**:
```bash
# Render CP437 ANSI to UTF8ANSI
zig build run -- reference/sixteencolors/fire-43/US-JELLY.ANS > /tmp/us-jelly.utf8ansi

# Re-render UTF8ANSI (should work identically)
timeout 3 zig build run -- /tmp/us-jelly.utf8ansi
```

**Completed**: 2025-11-01  
**Implementation**: TDD approach with RED→GREEN→REFACTOR phases

**Solution implemented**:
- Added `tryDecodeUTF8()` function with smart CP437/UTF-8 disambiguation
- UTF-8 detection heuristics:
  * Accept 3-byte and 4-byte UTF-8 (clearly beyond CP437 range)
  * Reject 2-byte UTF-8 for codepoints < U+0800 (likely CP437)
  * Preserves CP437 box drawing (0x80-0xFF) while enabling modern UTF-8
- Modified `writeScalar()` to try UTF-8 first, fall back to CP437
- Track source encoding per cell (`.utf_8` vs `.cp437`)

**Tests added** (all passing):
- UTF8ANSI roundtrip: basic ASCII text
- UTF8ANSI roundtrip: multi-byte UTF-8 characters (→ U+2192)
- UTF8ANSI roundtrip: mixed UTF-8 and ANSI escapes (✓ U+2713)
- Preserves existing CP437 box drawing tests

**Validation results** (2025-11-01):
```bash
# CP437 → UTF8ANSI ✅
zig build run -- reference/sixteencolors/fire-43/US-JELLY.ANS > /tmp/us-jelly.utf8ansi
# Exit code: 0

# UTF8ANSI → UTF8ANSI ✅ (NO FREEZE!)
timeout 3 zig build run -- /tmp/us-jelly.utf8ansi > /tmp/us-jelly-round2.utf8ansi
# Exit code: 0

# Multiple file validation ✅
zig build run -- reference/ansilove/ansilove/examples/burps/bs-alove.ans > /tmp/test.utf8ansi
zig build run -- /tmp/test.utf8ansi > /tmp/test2.utf8ansi
# Both succeed without freeze
```

**Git commits**:
- `62fbc86` - GREEN: Add UTF-8 support to ANSI parser
- `3c29eaf` - REFACTOR: Clean up UTF-8 decoder implementation

### Animation Handling - No Freezing
**Status**: ✅ COMPLETE  
**Priority**: HIGH

Ansilust successfully parses ansimation files without freezing.

**Test case**:
```bash
# Must complete in <3 seconds (no freeze/hang)
timeout 3 zig build run -- reference/sixteencolors/animated/WZKM-MERMAID.ANS
```

**Completed**: 2025-11-01  
**Implementation**: TDD approach with RED→GREEN→REFACTOR phases

**Solution implemented**:
- Added ansimation frame detection (ESC[2J + content + ESC[1;1H pattern)
- Multi-frame parsing: captures all frames as snapshots in `animation_data`
- SAUCE dimension validation: rejects unreasonable dimensions (>1024 width, >4096 height)
- Performance: WZKM-MERMAID.ANS (1.2MB, 55 frames) parses in ~242ms

**Tests added** (all passing):
- Detect ansimation frame boundaries (ESC[2J → content → ESC[1;1H)
- Capture multiple frames into animation_data
- Validate SAUCE dimensions (reject malformed metadata)
- Handle large ansimation files without hanging

**Validation results** (2025-11-01):
```bash
# WZKM-MERMAID.ANS ✅ (55 frames, 242ms)
timeout 3 zig build run -- reference/sixteencolors/animated/WZKM-MERMAID.ANS
# Exit code: 0

# All 123/123 tests passing ✅
zig build test --summary all
# Build Summary: 7/7 steps succeeded; 123/123 tests passed
```

**Git commits**:
- `63a2a77` - GREEN: Implement ansimation frame detection
- `5abf1d2` - GREEN: Fix parse hang from malformed SAUCE dimensions
- `cd00f83` - GREEN: Parse all animation frames into animation_data

**Known limitations**:
- Currently renders **last frame only** (frame 55 of WZKM-MERMAID.ANS)
- Need to implement frame timing from SAUCE baud rate
- Need renderer support for animation playback (future work)

## Implementation Tasks

### 1. Input Format Detection
- [ ] Add auto-detection of CP437 vs UTF8ANSI input
- [ ] Check for UTF-8 BOM or high-bit characters
- [ ] Fallback to CP437 if ambiguous

### 2. Format Parsers (All Historic Formats)

**Priority order based on corpus prevalence**:

- [ ] **Binary (.BIN)** - High priority
  - [ ] 160-column layout support
  - [ ] Auto-detect binary vs ANSI
  - [ ] Reference: `libansilove/src/loaders/binary.c`

- [ ] **XBin (.XB)** - High priority
  - [ ] Parse XBin header
  - [ ] Embedded font support
  - [ ] Embedded palette support
  - [ ] Reference: `libansilove/src/loaders/xbin.c`

- [ ] **PCBoard (.PCB)** - Medium priority
  - [ ] @X color code parser
  - [ ] PCBoard-specific sequences
  - [ ] Reference: `libansilove/src/loaders/pcboard.c`

- [ ] **Tundra (.TND)** - Medium priority
  - [ ] TheDraw format parser
  - [ ] Reference: `libansilove/src/loaders/tundra.c`

- [ ] **IceDraw (.IDF)** - Medium priority
  - [ ] IceDraw format parser
  - [ ] Reference: `libansilove/src/loaders/icedraw.c`

- [ ] **Artworx (.ADF)** - Lower priority
  - [ ] Artworx format parser
  - [ ] Reference: `libansilove/src/loaders/artworx.c`

- [ ] **DurDraw (.DUR)** - Modern format, medium priority
  - [ ] Research .DUR format specification
  - [ ] Check DurDraw source code for format details
  - [ ] Reference: https://github.com/cmang/durdraw

- [ ] **DarkDraw (.DD)** - Modern format, medium priority
  - [ ] Research DarkDraw native format (if exists)
  - [ ] May just be standard ANSI/XBin
  - [ ] Reference: DarkDraw repository/documentation

- [ ] **PabloDraw formats** - Research needed
  - [ ] Identify PabloDraw-specific formats
  - [ ] Add parsers as needed

### 3. Multi-file Processing
- [ ] Accept multiple file arguments
- [ ] Iterate through all provided files
- [ ] Format detection per file
- [ ] Skip unsupported formats gracefully
- [ ] Report summary (X processed, Y skipped)

### 4. UTF8ANSI Parser
- [ ] Implement UTF8ANSI input parser
- [ ] Handle modern terminal sequences (already in IR)
- [ ] Map to same IR as CP437 parser

### 5. Animation Handling
- [x] Detect ansimation control sequences (ESC[2J clear screen pattern) ✅
- [x] Parse all frames into animation_data ✅
- [x] SAUCE dimension validation (prevent malformed metadata hang) ✅
- [ ] Extract frame timing from SAUCE baud rate
- [ ] Add `--frame N` flag to render specific frame
- [ ] Add `--animate` flag for sequential playback
- [ ] Renderer support for animation output (currently shows last frame only)

### 6. Validation Tests
- [ ] Test US-JELLY.ANS roundtrip
- [ ] Test all animated files with timeout
- [ ] Test wildcard processing: `zig build run -- reference/sixteencolors/fire-43/*`
- [ ] Test mixed format batches (ANS + BIN + unsupported)
- [ ] Add CI check for timeout/freeze conditions
- [ ] Corpus regression tests (all files should process without error)

## ANSI Editor Research & Setup

### Known ANSI Editors Inventory
**Status**: ❌ Not catalogued  
**Priority**: MEDIUM

Build comprehensive list of ANSI editors and get them running for testing/research.

**Historic Editors (DOS-based)**:
- [ ] **TheDraw** - Classic ANSI editor
  - Platform: DOS
  - Setup: DOSBox
  - Source/Binary: Find archive
  
- [ ] **ACiDDraw** - ACiD Productions editor
  - Platform: DOS
  - Setup: DOSBox
  - Source/Binary: ACiD archive
  
- [ ] **IceDraw** - iCE Advertisements editor
  - Platform: DOS
  - Setup: DOSBox
  - Source/Binary: iCE archive

- [ ] **PabloDraw** - Popular DOS editor
  - Platform: DOS/Windows
  - Setup: DOSBox or Wine
  - Source/Binary: https://picoe.ca/products/pablodraw/

**Modern Editors (Cross-platform)**:
- [ ] **Moebius** - Modern ANSI/ASCII editor
  - Platform: Java (cross-platform)
  - Setup: Direct install
  - Source: https://github.com/blocktronics/moebius
  - Submodule: `git submodule add https://github.com/blocktronics/moebius reference/editors/moebius`

- [ ] **DurDraw** - Terminal-based ANSI editor
  - Platform: Python (cross-platform)
  - Setup: `pip install durdraw`
  - Source: https://github.com/cmang/durdraw

- [ ] **DarkDraw** - Rust ANSI editor
  - Platform: Native (cross-platform)
  - Setup: Cargo install or binary
  - Source: Research GitHub

- [ ] **SyncDraw** - Web-based collaborative ANSI editor
  - Platform: Web/Electron
  - Setup: Web app or download
  - URL: https://syncdraw.com/

**Modern Terminal Art Tools**:
- [ ] **ans2png** - ANSI to PNG converter
- [ ] **ansilove** - ANSI art to PNG
- [ ] **cat-ans** - Modern ANSI viewer
- [ ] **ansee** - Terminal ANSI renderer

**Research Tasks**:
- [ ] Catalog ALL known ANSI editors (past and present)
- [ ] Find download links or archives
- [ ] Document file formats each editor supports
- [ ] Test which editors work in DOSBox
- [ ] Document setup process for each editor
- [ ] Create test files with each editor
- [ ] Compare output formats

**DOSBox Setup**:
- [ ] Install DOSBox-X (enhanced fork)
- [ ] Create DOS environment for running editors
- [ ] Document configuration for each editor
- [ ] Script automated testing with editors

**Testing Strategy**:
- [ ] Create identical art piece in each editor
- [ ] Export in all supported formats
- [ ] Add to test corpus
- [ ] Verify ansilust can parse all outputs

## Nice to Have (Lower Priority)

### Parser Improvements
- [ ] Better error messages for malformed files
- [ ] Progress indicator for large files
- [ ] Streaming parse mode

### Renderer Improvements
- [ ] Text attributes (bold, underline, blink)
- [ ] Animation playback support
- [x] Hyperlinks (OSC 8) - ✅ Completed 2025-11-01

## Future Applications (Long-term Vision)

### TUI ANSI Editor
**Status**: ❌ Not started  
**Priority**: FUTURE

Build a modern, terminal-based ANSI editor using ansilust IR as the backend.

**Research Tasks**:
- [ ] Study existing TUI editors (DurDraw, TheDraw, PabloDraw)
- [ ] Research terminal UI frameworks:
  - [ ] vaxis (Zig TUI library)
  - [ ] termbox
  - [ ] notcurses
  - [ ] ncurses
- [ ] Define feature set (MVP vs full-featured)
- [ ] Design architecture (IR-based editing)

**Core Features to Spec**:
- [ ] Canvas editor with CP437/Unicode support
- [ ] Color palette picker (DOS 16-color + truecolor)
- [ ] Drawing tools (brush, line, box, fill)
- [ ] Layer support
- [ ] Animation timeline
- [ ] Export to all supported formats
- [ ] Import from all supported formats
- [ ] Live preview in terminal

**Technical Spec Requirements**:
- [ ] Document TUI framework choice
- [ ] Define keybindings and UI layout
- [ ] Spec undo/redo system
- [ ] Spec file format (use ansilust IR?)
- [ ] Performance requirements (60fps canvas updates)
- [ ] Memory budget for large canvases

**Advantages of ansilust-based editor**:
- Unified IR supports all formats
- Modern codebase (Zig)
- Cross-platform
- Can import/export legacy formats

### BBS Platform (terminal.shop-inspired)
**Status**: ❌ Not started  
**Priority**: FUTURE

Create modern BBS software platform for SSH-based communities.

**Inspiration**: `ssh terminal.shop`

**Research Tasks**:
- [ ] SSH to terminal.shop and document features
- [ ] Study existing BBS software:
  - [ ] Mystic BBS
  - [ ] Synchronet
  - [ ] ENiGMA½ BBS
- [ ] Research SSH server libraries (Zig or compatible)
- [ ] Study terminal.shop's tech stack

**Core Features to Spec**:
- [ ] SSH-based access (no telnet)
- [ ] Multi-user support
- [ ] Message boards/forums
- [ ] File areas (download ANSI art)
- [ ] ANSI art galleries (using ansilust renderer)
- [ ] Live chat/messaging
- [ ] Door games support
- [ ] User profiles and customization
- [ ] Modern authentication (SSH keys, 2FA)

**Technical Spec Requirements**:
- [ ] Document SSH server architecture
- [ ] Define user database schema
- [ ] Spec message storage format
- [ ] Spec file area organization
- [ ] ANSI rendering integration (use ansilust)
- [ ] Session management
- [ ] Performance: 100+ concurrent users

**Integration with ansilust**:
- Use ansilust for rendering all art
- Support uploading art in any format
- Live art preview in galleries
- Art format conversion on upload

### SSH Art Viewer - `ssh 16colo.rs`
**Status**: ❌ Not started  
**Priority**: HIGH (Showcase ansilust capabilities)

Create an SSH-accessible ANSI art viewer inspired by ACiDView.exe and similar DOS art viewers.

**Concept**: `ssh 16colo.rs` - Browse the entire 16colors.net archive via SSH

**Inspiration**:
- ACiDView.exe (DOS art pack viewer)
- iCEView (iCE art pack viewer)
- `ssh terminal.shop` (modern SSH service)
- Similar viewers from the BBS era

**Research Tasks**:
- [ ] Run ACiDView.exe in DOSBox to study UX
- [ ] Document ACiDView navigation and features
- [ ] Study other DOS art viewers (iCEView, etc.)
- [ ] Research 16colors.net API or scraping options
- [ ] Check if 16colors.net has bulk download options

**Core Features to Spec**:

**Browse Interface**:
- [ ] Main menu: Browse by year, group, artist, format
- [ ] Art pack listing (scrollable)
- [ ] File browser within packs
- [ ] Preview pane showing current art
- [ ] Info panel (filename, size, artist, date, format)

**Viewing Features**:
- [ ] Full-screen art display
- [ ] Next/Previous navigation (arrow keys, vim keys)
- [ ] Zoom/pan for large files
- [ ] Animation playback for ansimations
- [ ] Format info display (CP437, ANSI, XBin, etc.)

**Search & Filter**:
- [ ] Search by artist name
- [ ] Search by art pack name
- [ ] Filter by year/decade
- [ ] Filter by art group (ACiD, iCE, etc.)
- [ ] Filter by format type
- [ ] Random art button

**Download/Export**:
- [ ] Download original file (scp/sftp)
- [ ] Export as UTF8ANSI
- [ ] Export as PNG (future)
- [ ] Create shareable links

**Social Features**:
- [ ] Favorites/bookmarks
- [ ] View count tracking
- [ ] Comments/ratings (optional)
- [ ] Share to social media

**Technical Architecture**:

**Backend**:
- [ ] SSH server (libssh or similar)
- [ ] Ansilust integration for rendering
- [ ] 16colors.net data sync/cache
- [ ] SQLite database for metadata
- [ ] Redis for session management

**UI Framework**:
- [ ] TUI library (vaxis, notcurses, etc.)
- [ ] Keyboard navigation
- [ ] Mouse support (optional)
- [ ] Layout: menu + preview + info panels

**Performance Requirements**:
- [ ] Support 50+ concurrent users
- [ ] Art rendering < 100ms
- [ ] Instant navigation between files
- [ ] Efficient caching of rendered art

**Data Management**:
- [ ] Sync 16colors.net archive (100GB+)
- [ ] Organize by year/group/pack
- [ ] Extract SAUCE metadata
- [ ] Build search index
- [ ] Incremental updates

**User Experience (inspired by ACiDView)**:
```
┌─ 16COLO.RS ────────────────────────────────────────────────────┐
│ [F]ile  [B]rowse  [S]earch  [R]andom  [H]elp  [Q]uit          │
├────────────────────────────────────────────────────────────────┤
│ Art Packs (1996)                    │  US-JELLY.ANS            │
│ ─────────────────                   │  ────────────────────    │
│ > ACiD 1996                         │  [Art preview here]      │
│   iCE 1996                          │  Using ansilust          │
│   Fire 1996                         │  renderer                │
│   Fuel 1996                         │                          │
│                                     │  Artist: Unknown         │
│                                     │  Group: ACiD             │
│ Files in ACiD 1996                  │  Size: 162KB             │
│ ──────────────────                  │  Format: ANSI/CP437      │
│   US-JELLY.ANS                      │  Date: 1996-08-15        │
│   US-NEON.ANS                       │                          │
│   US-CYBER.ANS                      │  [↑↓] Navigate           │
│                                     │  [Enter] View full       │
│                                     │  [D] Download            │
└─────────────────────────────────────┴──────────────────────────┘
```

**Implementation Phases**:

**Phase 1 - MVP**:
- [ ] Basic SSH server
- [ ] Simple file browser
- [ ] Ansilust rendering
- [ ] Navigation (arrows, enter, q)
- [ ] Static data set (fire-43 pack)

**Phase 2 - Full Archive**:
- [ ] 16colors.net sync
- [ ] Search functionality
- [ ] Multiple packs/years
- [ ] Metadata extraction

**Phase 3 - Polish**:
- [ ] Advanced navigation
- [ ] Animation support
- [ ] Download/export
- [ ] User accounts/favorites

**Phase 4 - Social**:
- [ ] Comments/ratings
- [ ] Statistics
- [ ] Recommendations

**Deployment**:
- [ ] Domain: `16colo.rs` (check availability) or `art.16colo.rs`
- [ ] Server: VPS with 200GB+ storage
- [ ] Bandwidth: Handle art downloads
- [ ] SSL/TLS for SSH
- [ ] Monitoring and logging

**Legal/Licensing**:
- [ ] Verify 16colors.net terms of use
- [ ] Respect artist copyrights
- [ ] Provide attribution
- [ ] Link back to 16colors.net
- [ ] Contact 16colors.net maintainers for permission

**Why This Matters**:
- Showcases ansilust's rendering capabilities
- Makes BBS art accessible to modern audience
- Preserves computing history
- Tests all format parsers with real data
- Drives development of missing features

### AI MUD - AI-Populated Multi-User Dungeon
**Status**: ❌ Not started  
**Priority**: FUTURE (Experimental)

Create a text-based MUD where most NPCs are AI agents with persistent personalities and memories.

**Concept**: Traditional MUD gameplay enhanced with AI NPCs that remember interactions, develop relationships, and create emergent storylines.

**Core Vision**:
- Small number of human players (5-20)
- Large number of AI NPCs (100-500)
- Persistent world with dynamic storylines
- ANSI art for room descriptions and character portraits
- Terminal-based interface (SSH access)

**Research Tasks**:
- [ ] Study classic MUDs (DikuMUD, CircleMUD, LPMud)
- [ ] Research AI NPC systems in games
- [ ] Study LLM agent frameworks (AutoGen, LangChain, etc.)
- [ ] Research persistent memory systems (vector DBs, RAG)
- [ ] Study multi-agent simulation papers
- [ ] Look at existing AI Dungeon / AI RPG systems

**AI NPC System**:

**Personality & Memory**:
- [ ] Each NPC has persistent personality profile
- [ ] Long-term memory of interactions with players
- [ ] Relationship tracking (friend/enemy/neutral)
- [ ] Emotional state modeling
- [ ] Goals and motivations
- [ ] Cultural background and knowledge

**Behavior Types**:
- [ ] Shopkeepers (buy/sell, remember prices/haggling)
- [ ] Quest givers (generate quests based on world state)
- [ ] Guards (remember faces, enforce rules)
- [ ] Commoners (gossip, daily routines)
- [ ] Monsters (patrol, hunt, flee)
- [ ] Faction leaders (politics, alliances)

**AI Agent Architecture**:
- [ ] LLM-based decision making (GPT-4, Claude, Llama)
- [ ] Vector database for memory (Pinecone, Weaviate)
- [ ] State machine for basic behaviors
- [ ] Natural language understanding for commands
- [ ] Response generation (contextual, personality-aware)

**World Simulation**:

**Dynamic World State**:
- [ ] NPCs have daily routines (work, sleep, socialize)
- [ ] Economic simulation (supply/demand, prices)
- [ ] Weather and time of day
- [ ] Faction relationships (war, peace, trade)
- [ ] Emergent events (AI NPCs can start quests)

**Persistent Changes**:
- [ ] Player actions remembered by NPCs
- [ ] Reputation system (per-faction, per-NPC)
- [ ] World state changes based on player/NPC actions
- [ ] Story arcs emerge from AI interactions

**Technical Specifications**:

**Game Engine**:
- [ ] Written in Zig (integrate with ansilust)
- [ ] Event-driven architecture
- [ ] Multi-threaded for AI processing
- [ ] Database for persistence (PostgreSQL)
- [ ] Redis for caching/sessions

**AI Integration**:
- [ ] LLM API integration (OpenAI, Anthropic, local models)
- [ ] Rate limiting and cost management
- [ ] Fallback to scripted behavior when API unavailable
- [ ] Batch processing for NPC updates
- [ ] Asynchronous AI decision making

**Rendering**:
- [ ] ANSI art room descriptions (use ansilust)
- [ ] Character portraits in CP437/Unicode art
- [ ] Dynamic text wrapping
- [ ] Color-coded NPC dialogue
- [ ] Status displays (HP, location, inventory)

**Performance Requirements**:
- [ ] Support 20 concurrent human players
- [ ] 500 AI NPCs updating every 1-5 minutes
- [ ] LLM API calls < 1000/hour (cost management)
- [ ] Response time < 1 second for player commands
- [ ] Database queries optimized

**Game Mechanics**:

**Traditional MUD Elements**:
- [ ] Rooms, exits, objects
- [ ] Combat system (turn-based)
- [ ] Inventory and equipment
- [ ] Skills and leveling
- [ ] Crafting system
- [ ] Magic system

**AI-Enhanced Features**:
- [ ] Dynamic quests generated by AI
- [ ] NPC-driven storylines
- [ ] Unique dialogue every interaction
- [ ] NPCs remember promises/betrayals
- [ ] Emergent faction politics
- [ ] AI dungeon master mode

**Example Interactions**:

**Shopkeeper NPC**:
```
> look shopkeeper
You see Marta the Blacksmith, a weathered dwarf with soot-stained hands.
She looks up from her anvil and recognizes you.

Marta says: "Ah, you're back! How did that sword I sold you work out?"
Marta says: "I heard you helped defend the village last week. Brave of you."
Marta says: "For that, I'll give you 10% off today. What do you need?"

> buy dagger
Marta examines your coin purse and nods approvingly.
Marta says: "This is well-crafted steel. I made it myself yesterday."
Marta says: "That'll be 45 gold. Friend price."
```

**Guard NPC**:
```
> enter castle
Guard Theron blocks your path with his spear.

Theron says: "Hold there! I remember you from last month."
Theron says: "You caused trouble in the tavern. The captain still wants words."
Theron says: "State your business, or turn around."

> say I've come to apologize to the captain
Theron studies your face, then nods slowly.

Theron says: "Alright. But I'm watching you. No more brawls."
Theron says: "The captain is in the throne room. Be respectful."
Theron steps aside and lets you pass.
```

**Implementation Phases**:

**Phase 1 - Basic MUD + Simple AI**:
- [ ] Core MUD engine (rooms, combat, inventory)
- [ ] SSH server integration
- [ ] 5-10 AI NPCs with basic responses
- [ ] Simple memory (last interaction only)
- [ ] ANSI art integration

**Phase 2 - Persistent AI**:
- [ ] Vector database for NPC memories
- [ ] Relationship tracking
- [ ] Personality profiles
- [ ] Daily routines

**Phase 3 - Dynamic World**:
- [ ] Quest generation
- [ ] Faction system
- [ ] Economic simulation
- [ ] Emergent events

**Phase 4 - Advanced AI**:
- [ ] Multi-agent interactions
- [ ] NPC-to-NPC dialogue
- [ ] Political intrigue
- [ ] Player-driven story arcs

**Cost Considerations**:

**LLM API Costs**:
- [ ] Estimate: 500 NPCs × 10 updates/day = 5000 API calls/day
- [ ] GPT-4: ~$15-30/day at current pricing
- [ ] Optimization: Cache common responses, use cheaper models
- [ ] Alternative: Self-hosted LLM (Llama 3, Mistral)

**Infrastructure**:
- [ ] VPS: $50-100/month (8GB RAM, 4 cores)
- [ ] Database: Managed PostgreSQL $20/month
- [ ] Vector DB: Pinecone free tier or self-hosted
- [ ] Total: $100-150/month + LLM costs

**Monetization (Optional)**:
- [ ] Subscription for human players ($5-10/month)
- [ ] Cosmetic items (character portraits, ANSI art)
- [ ] Premium AI interactions
- [ ] Early access to new areas

**Unique Selling Points**:
- NPCs feel alive (remember you, develop relationships)
- Every conversation is unique
- Emergent storytelling (not scripted)
- Retro aesthetic (ANSI art, SSH access)
- Persistent world that evolves

**Integration with Ansilust**:
- Use ansilust for rendering room descriptions
- Support multiple art formats (ANS, XBin, etc.)
- Dynamic art selection based on time/weather
- Character portraits in CP437 art
- Map displays using box-drawing characters

**Challenges to Solve**:
- [ ] AI consistency (NPCs don't contradict themselves)
- [ ] Cost management (LLM API calls)
- [ ] Response quality (avoid generic replies)
- [ ] NPC coordination (factions, politics)
- [ ] Abuse prevention (players trolling AI)
- [ ] Latency (AI responses must be fast)

**Research Inspirations**:
- [ ] Westworld (AI hosts with memories)
- [ ] AI Dungeon (GPT-powered adventures)
- [ ] Generative Agents paper (Stanford, 2023)
- [ ] Classic MUDs (for game mechanics)
- [ ] Dwarf Fortress (emergent simulation)

**Why This Matters**:
- Pushes boundaries of AI-human interaction
- Creates living, breathing virtual world
- Tests limits of LLM agent systems
- Showcases ansilust rendering in game context
- Could be foundation for new genre of games

### TUI Web Browser
**Status**: ❌ Spec exists somewhere  
**Priority**: FUTURE

Build terminal-based web browser with TML markup support.

**Find Existing Spec**:
- [x] ~~Search for existing TUI browser spec~~ - NOT FOUND (searched 2025-10-31)
- [ ] Check old GitHub repos/gists
- [ ] Check email archives for specs
- [ ] Check Discord/Slack DMs for shared specs
- [ ] Ask if spec was shared anywhere

**Search Results (2025-10-31)**:
- Searched ~/Documents: Empty directory
- Searched ~/Work: No spec files found
- Searched ~/Hack: Only found libansilove/TERMINAL_MODE.md
- No TML references found (except in this TODO)

**Next Steps**:
- [ ] If spec found elsewhere: Copy to `reference/specs/tui-browser.md`
- [ ] If spec not found: Create new spec from scratch

**If spec not found, create new**:
- [ ] Document TUI browser architecture
- [ ] Define supported protocols (HTTP, Gopher, Gemini)
- [ ] Spec rendering engine for TML
- [ ] Define keybindings and navigation
- [ ] Bookmark system
- [ ] History tracking
- [ ] Tab support

### TML - Terminal Markup Language
**Status**: ❌ Not started  
**Priority**: FUTURE

Design markup language for TUI browsers (like HTML for terminals).

**Concept**: HTML-like markup that renders in terminals using ANSI/Unicode.

**Spec Requirements**:

**Basic Tags**:
```tml
<document>
  <head>
    <title>Page Title</title>
    <style>
      h1 { fg: blue; bold: true; }
      p { fg: white; }
    </style>
  </head>
  <body>
    <h1>Heading</h1>
    <p>Paragraph text with <b>bold</b> and <i>italic</i>.</p>
    <box border="double" fg="cyan">
      Box drawing with Unicode characters
    </box>
    <ansi src="art.ans" />
    <link href="page2.tml">Click here</link>
  </body>
</document>
```

**Feature Spec**:
- [ ] Define core tag set (h1-h6, p, b, i, u, link, img, box, table)
- [ ] Define style system (CSS-like for terminals)
- [ ] Color support (DOS palette + truecolor)
- [ ] Box-drawing characters
- [ ] Embedded ANSI art (`<ansi>` tag)
- [ ] Links and navigation
- [ ] Forms and input
- [ ] Tables and layout
- [ ] Unicode support

**Rendering**:
- [ ] Text flow and wrapping
- [ ] Layout engine (flexbox-like for terminals)
- [ ] Mouse support (for compatible terminals)
- [ ] Keyboard navigation

**Integration with ansilust**:
- `<ansi src="file.ans">` tag embeds ANSI art
- Use ansilust IR for rendering embedded art
- Support all ansilust-supported formats

**Comparison with existing**:
- [ ] Research Gopher protocol
- [ ] Research Gemini protocol (gemtext)
- [ ] Research existing TUI markup (if any)
- [ ] Borrow best ideas from each

**Implementation Tasks**:
- [ ] Write formal TML specification document
- [ ] Create TML parser (Zig)
- [ ] Create TML renderer (using vaxis or similar)
- [ ] Create example TML documents
- [ ] Build validator/linter

**Use Cases**:
- Terminal-based documentation
- BBS content (integrate with BBS platform)
- Terminal applications with rich content
- Accessible web browsing alternative
- Retro computing enthusiasts

**File Extension**: `.tml`

## Completed ✅

- [x] UTF8ANSI renderer implementation
- [x] CP437 glyph mapping
- [x] DOS palette colors
- [x] Null byte handling (renders as spaces)
- [x] Zig 0.15 compatibility
- [x] OSC 8 Hyperlink support (parser + renderer) - 2025-11-01
  - Parser: OSC 8 sequence parsing with ESC \ and BEL terminators
  - Renderer: Emit OSC 8 start/end sequences, track hyperlink state
  - Tests: 15 comprehensive tests (8 parser + 6 renderer + 1 integration)
  - Round-trip validation: ANSI → IR → UTF8ANSI preserves hyperlinks
- [x] UTF8ANSI roundtrip support - 2025-11-01
  - Smart CP437/UTF-8 disambiguation (3-byte/4-byte UTF-8 detection)
  - Preserves CP437 box drawing while enabling modern UTF-8
  - Tests: 3 roundtrip tests (ASCII, multi-byte, mixed escapes)
  - Validation: US-JELLY.ANS → UTF8ANSI → UTF8ANSI works without freeze
- [x] Ansimation support (multi-frame parsing) - 2025-11-01
  - Frame detection: ESC[2J + content + ESC[1;1H pattern
  - Multi-frame capture into animation_data (all frames as snapshots)
  - SAUCE dimension validation (prevents hang on malformed metadata)
  - Performance: 1.2MB file (55 frames) parses in ~242ms
  - Tests: 3 ansimation tests (detection, capture, validation)
  - All 123/123 tests passing
