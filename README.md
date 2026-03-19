# Ansilust Project

A next-generation text art processing system inspired by the legendary [ansilove](https://github.com/ansilove/ansilove) project. Ansilust provides a unified intermediate representation (IR) for working with both classic BBS-era text art formats and modern terminal output.

---

|Status|Package|Purpose|
|---|---|---|
|![](https://img.shields.io/npm/v/16c)|`16c`|coming soon|
|![](https://img.shields.io/npm/v/16colors)|`16colors`|coming soon|
|![](https://img.shields.io/npm/v/ansilust)|`ansilust`|coming sooner|

---

## 🚀 Quick Start

Project-management authority lives in `.ok/project-management.ok.md`, and active execution work lives in `.tasks/`. `README.md` and `STATUS.md` are reader-facing artifacts only.

```bash
# Render classic ANSI art to your terminal
zig build run -- path/to/artwork.ans

# Or build and use the binary
zig build
./zig-out/bin/ansilust path/to/artwork.ans
```

## 📦 Installation

The only install path fully exercised in this repository today is building from source. Release-channel guidance below is limited to the target matrix declared in `.ok/deployments.ok.md` and the current non-website reality in `.ok/website.ok.md`.

### Current install matrix

| Channel | Supported targets evidenced in repo | Notes |
|---|---|---|
| Source build | Any system with Zig that can build this repository | This is the primary path shown in Quick Start and Current Status. |
| GitHub Releases | `darwin-arm64`, `darwin-x64`, `linux-x64-gnu`, `linux-x64-musl`, `linux-arm64-gnu`, `linux-arm64-musl`, `linux-arm-gnu`, `linux-arm-musl` | GitHub Releases is the canonical direct-download source when a tagged release is published. |
| npm | Same target set as GitHub Releases | The `ansilust` npm package is only supported where matching platform packages and release artifacts exist at the same version. |
| Repository shell installer | Same Unix target set as GitHub Releases | Hosted from raw GitHub repository paths, not from `ansilust.com`; downloads release artifacts plus `SHA256SUMS`. |
| Container image | `linux/amd64`, `linux/arm64`, `linux/arm/v7` | Built and pushed by the tag-driven release workflow to `ghcr.io/effect-native/ansilust`. |

### npm

Use npm only on the currently supported release targets listed above.

```bash
# Install globally
npm install -g ansilust

# Or run directly without installing
npx ansilust path/to/artwork.ans
```

### Repository Installer Script (Linux/macOS release targets only)

```bash
curl -fsSL https://raw.githubusercontent.com/effect-native/ansilust/main/scripts/install.sh | bash
```

The shell installer currently ships from this repository, not from `ansilust.com`. It installs only from the GitHub release artifacts and checksum manifest supported by the current release workflow.

### Docker

```bash
docker run ghcr.io/effect-native/ansilust:latest path/to/artwork.ans
```

### Not currently shipped as supported install channels

- The in-repo PowerShell installer is informational only until Windows artifacts are published in the release workflow.
- AUR packaging remains aspirational and is not presented as a current install path.
- Nix packaging remains aspirational and is not presented as a current install path.
- No website-hosted installer or `ansilust.com` install flow is currently evidenced in this repository.

### From Source

```bash
git clone https://github.com/effect-native/ansilust.git
cd ansilust
zig build -Doptimize=ReleaseSafe
./zig-out/bin/ansilust path/to/artwork.ans
```

## 📊 Current Status

Ansilust is an active source build, not a packaged release. The repository currently demonstrates a working ANSI-to-IR-to-UTF-8 terminal path backed by tests and corpus fixtures, while broader parser, renderer, and distribution work remains in progress.

### Implemented and exercised in this repository

**Core infrastructure:**
- **IR (Intermediate Representation)** includes a cell-grid foundation with CP437 and Unicode support, palette and RGB colors, text attributes, SAUCE metadata handling, animation frame structures, hyperlink tracking, and wide-character or grapheme support.

**Parsers (Input -> IR):**
- **ANSI parser** (`src/parsers/ansi.zig`) is present and covered by the current test suite, including CP437 decoding, SGR attributes, cursor movement, and SAUCE extraction.

**Renderers (IR -> Output):**
- **UTF8ANSI renderer** (`src/renderers/utf8ansi.zig`) is present and covered by the current test suite, including CP437-to-UTF-8 rendering, palette and RGB output, style batching, and TTY versus file behavior.

**Current evidence:**
- `zig build test` is the project validation path documented in this repository.
- The README's quick-start commands run from source via `zig build` and `./zig-out/bin/ansilust`.
- The repository includes unit tests plus corpus-based validation against ANSI art fixtures from the sixteencolors archive.

### Planned or still in progress

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

## 📁 Repository Structure

This is a monorepo managed with npm workspaces. The `packages/` directory contains:

### Main Package

- **`packages/ansilust/`** - Meta package (platform launcher)
  - Detects your OS and CPU architecture
  - Automatically uses the correct native binary
  - Single `ansilust` command works across all platforms

### Platform Packages (Published Separately)

- **`ansilust-darwin-arm64`** - macOS Apple Silicon
- **`ansilust-darwin-x64`** - macOS Intel
- **`ansilust-linux-x64-gnu`** - Linux x64 (glibc)
- **`ansilust-linux-x64-musl`** - Linux x64 (musl)
- **`ansilust-linux-arm64-gnu`** - Linux ARM64 (glibc)
- **`ansilust-linux-arm64-musl`** - Linux ARM64 (musl)
- **`ansilust-linux-arm-gnu`** - Linux ARMv7 (glibc)
- **`ansilust-linux-arm-musl`** - Linux ARMv7 (musl)

Each platform package contains a pre-built native binary for that architecture.

### Development

```bash
# Install all workspace packages
npm install

# List all workspaces
npm ls --workspaces

# Run build for all packages
npm run build --workspaces
```

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

- **`.ok/project-management.ok.md`** - Project-management constitution and authority rules
- **`.tasks/`** - Current ephemeral work orders and execution state
- **`STATUS.md`** - Historical and reader-facing status narrative only
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
