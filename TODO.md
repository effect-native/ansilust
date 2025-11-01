# Ansilust TODO

## Critical Issues

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
**Status**: ❌ Not implemented  
**Priority**: HIGH

Ansilust must support both CP437 and UTF8ANSI as input types without issues.
zig build run -- reference/sixteencolors/animated/WZKM-MERMAID.ANS
**Test case**:
```bash
# Render CP437 ANSI to UTF8ANSI
zig build run -- reference/sixteencolors/fire-43/US-JELLY.ANS > reference/sixteencolors/fire-43/US-JELLY.utf8ansi

# Re-render UTF8ANSI (should work identically)
zig build run -- reference/sixteencolors/fire-43/US-JELLY.utf8ansi
```

**Current status**: ❌ CONFIRMED BUG - Freezes on UTF8ANSI input (timeout after 3s)
**Required**: Parser must detect UTF8ANSI vs CP437 input and handle both

**Test results (2025-10-31)**:
```bash
# CP437 → UTF8ANSI works fine
zig build run -- reference/sixteencolors/fire-43/US-JELLY.ANS > /tmp/us-jelly.utf8ansi
# Exit code: 0 ✅

# UTF8ANSI input FREEZES
timeout 3 zig build run -- /tmp/us-jelly.utf8ansi
# Exit code: 124 (timeout) ❌
```

### Animation Handling - No Freezing
**Status**: ❌ Not implemented  
**Priority**: HIGH

Ansilust must not freeze on ansimation files. Should render instantly or fail gracefully.

**Test case**:
```bash
# Must complete in <3 seconds (no freeze/hang)
timeout 3 zig build run -- reference/sixteencolors/animated/WZKM-MERMAID.ANS
```

**Current status**: ⚠️ NEEDS TESTING - Likely freezes on animation sequences  
**Required**: 
- Detect ansimation control sequences
- Either render first frame only, or
- Fail fast with clear error message

**Files to test**:
- `reference/sixteencolors/animated/WZKM-MERMAID.ANS`
- Other files in `reference/sixteencolors/animated/`

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
- [ ] Detect ansimation control sequences (ANSI Music, timing codes)
- [ ] Add `--first-frame-only` flag for animations
- [ ] Add timeout protection in parser
- [ ] Graceful error for unsupported animation features

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
- [ ] Hyperlinks (OSC 8)

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
- [x] 102/102 tests passing
