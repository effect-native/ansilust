# Ansilust Project

A next-generation text art processing system inspired by the legendary [ansilove](https://github.com/ansilove/ansilove) project. Ansilust provides a unified intermediate representation (IR) for working with both classic BBS-era text art formats and modern terminal output.

## 🚀 Quick Start

```bash
# Render classic ANSI art to your terminal
zig build run -- path/to/artwork.ans

# Or build and use the binary
zig build
./zig-out/bin/ansilust path/to/artwork.ans
```

## 📊 Current Status

### ✅ What's Implemented (Ready to Use)

**Core Infrastructure:**
- **IR (Intermediate Representation)** - Complete cell grid system with:
  - Structure-of-arrays layout for efficient memory access
  - CP437 and Unicode character support
  - 16-color palette and 24-bit RGB color support
  - Text attributes (bold, italic, underline, blink, etc.)
  - SAUCE metadata parsing and preservation
  - Animation frame support (snapshot and delta frames)
  - Hyperlink tracking (OSC 8)
  - Wide character and grapheme cluster handling

**Parsers (Input → IR):**
- **ANSI Parser** (`src/parsers/ansi.zig`) ✅ **WORKING**
  - CP437 character encoding
  - SGR (Select Graphic Rendition) attributes
  - Cursor positioning and control sequences
  - SAUCE metadata extraction
  - Tested with real-world BBS art from 1996 artpacks

**Renderers (IR → Output):**
- **UTF8ANSI Renderer** (`src/renderers/utf8ansi.zig`) ✅ **WORKING**
  - Converts classic CP437 ANSI art to modern UTF-8 terminal output
  - DOS palette to ANSI 256-color mapping
  - 24-bit RGB (truecolor) support
  - Style batching optimization
  - TTY vs file mode distinction
  - Targets: Ghostty, Alacritty, Kitty, WezTerm, and other modern terminals

**Testing:**
- 102+ unit tests (all passing)
- Memory leak detection via `std.testing.allocator` in all tests
- Real-world corpus validation (137+ ANSI files from sixteencolors archive)

### 🚧 What's Planned (Not Yet Implemented)

**Additional Parsers:**
- Binary format (.BIN) - 160-column format
- PCBoard (.PCB) - BBS-specific format with @X color codes
- XBin (.XB) - Extended Binary with embedded fonts
- Tundra/TheDraw (.TND/.IDF) - Editor formats
- ArtWorx (.ADF) - Artworx Data Format
- iCE Draw (.IDF) - iCE Draw format
- UTF8ANSI input parser - Read modern terminal sequences as input

**Additional Renderers:**
- HTML Canvas Renderer - Browser-based rendering
- PNG Renderer - Static image output (like original ansilove)
- OpenTUI integration - Direct conversion to OptimizedBuffer format

**Animation Support:**
- Ansimation playback (ANSI animations)
- Frame-by-frame rendering
- Timing control

## Project Architecture

### Intermediate Representation (IR)

The IR is a unified format that bridges classic BBS art and modern terminal capabilities:
- **Cell Grid**: Efficient structure-of-arrays layout
- **Character Support**: CP437 (DOS) and full Unicode
- **Color Models**: 16-color palette, 256-color, and 24-bit RGB
- **Metadata**: Complete SAUCE record preservation
- **Modern Features**: Hyperlinks, grapheme clusters, wide characters

### Module Structure

```
src/
├── ir/              # Intermediate representation core
│   ├── cell_grid.zig      # Cell grid and grapheme pool
│   ├── color.zig          # Color types and palettes
│   ├── attributes.zig     # Text attributes (bold, italic, etc.)
│   ├── sauce.zig          # SAUCE metadata
│   ├── animation.zig      # Animation frames
│   ├── document.zig       # Root IR container
│   └── ...
├── parsers/         # Format parsers (Input → IR)
│   ├── ansi.zig          # ANSI/ANSI-BBS parser ✅
│   └── ...               # (Binary, XBin, etc. - planned)
└── renderers/       # Output renderers (IR → Output)
    ├── utf8ansi.zig      # UTF-8 terminal renderer ✅
    └── ...               # (HTML, PNG, etc. - planned)
```

## Design Philosophy

Ansilust's IR is designed based on research from multiple reference projects:

**Classic BBS Art** (from [libansilove](https://github.com/ansilove/libansilove)):
- CP437 character encoding and DOS code pages
- SAUCE metadata (128-byte records with rendering hints)
- Bitmap font support (embeddable in XBin, ArtWorx formats)
- iCE colors mode (high-intensity backgrounds)
- DOS aspect ratio handling (non-square CRT pixels)

**Modern Terminals** (from [Ghostty](https://github.com/ghostty-org/ghostty)):
- Full Unicode support (21-bit codepoints)
- Wide character and grapheme cluster handling
- Rich text attributes (underline styles, separate underline colors)
- Hyperlink support (OSC 8)
- Efficient memory layout (reference-counted styles)

**Integration Targets** (from [OpenTUI](https://github.com/rockorager/opentui)):
- Structure-of-arrays cell grid layout
- RGBA color representation
- Diff-based rendering for efficiency
- Animation frame support

## Development & Testing

### Building

```bash
# Build the project
zig build

# Run tests
zig build test

# Format code
zig fmt src/**/*.zig
```

### Test Corpus

The project includes a test corpus from the [sixteencolors archive](https://github.com/sixteencolors/sixteencolors-archive):
- 137+ ANSI files from 1996 artpacks (ACiD, iCE, Fire)
- 6 ansimation (animated ANSI) files
- Real-world complexity and edge cases

See `CORPUS.md` for detailed corpus documentation.

## Documentation

- **`STATUS.md`** - Detailed implementation status and phase completion
- **`TODO.md`** - Planned features and future work
- **`AGENTS.md`** - Complete project architecture and reference materials
- **`IR-RESEARCH.md`** - Intermediate representation design research
- **`.specs/ir/`** - Detailed IR specifications and design documents

## Reference Projects

The `reference/` directory contains submodules and documentation for projects that informed the design:

- **libansilove** - Classic BBS art format parsers (C)
- **ansilove** - CLI tool and SAUCE metadata handling
- **Ghostty** - Modern terminal emulator architecture (Zig)
- **OpenTUI** - TUI framework integration target
- **Effect-TS** - TypeScript functional programming patterns
- **Bun** - Zig/TypeScript FFI reference

See individual `AGENTS.md` files in each reference directory for detailed guides.

## Contributing

This project follows test-driven development (TDD) with:
- Red/Green/Refactor cycles for new features
- Atomic git commits for each TDD phase
- Memory leak detection using `std.testing.allocator` in all tests
- 100% test pass rate before commits

See `.specs/ir/PHASE5_XP_TDD_SUMMARY.md` for detailed TDD methodology.

## License

See LICENSE file for details.
