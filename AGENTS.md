# Ansilust - Quick Reference

## Build & Test Commands
```bash
zig build              # Build all executables (output: zig-out/bin/)
zig build test         # Run all tests (3 modules: ansilust, parsers, exe)
zig build run -- arg   # Run main executable with args
```

## Code Style (Zig)
- **Imports**: `const std = @import("std");` first, then project modules via `@import("module_name")`
- **Naming**: snake_case for functions/variables, PascalCase for types/structs, SCREAMING_CASE for constants
- **Doc comments**: Use `///` for public API docs, `//!` for module-level docs
- **Error handling**: Return `error.ErrorName` from error sets, use `!` for error unions
- **Types**: Explicit union(enum) for variants, packed structs for bit fields
- **Module imports**: Use build.zig module deps (`@import("ansilust")`) not relative paths

## Key Directories
- `src/ir/` - Intermediate representation (cell grid, colors, attributes)
- `src/parsers/` - ANSI/BBS format parsers
- `src/renderers/` - Output renderers (UTF8ANSI)
- `reference/` - Prior art (ghostty, libansilove) - see subdirectory AGENTS.md files

---

# Ansilust Project (Detailed)

Inspired by the legendary [ansilove](https://github.com/ansilove/ansilove) project, ansilust is a next-generation text art processing system split into multiple modules. Keep `.specs/ir/prior-art-notes.md` close; it lists the exact files from Ghostty, Bun, and ansilove to re-read before refreshing IR decisions.

## Project Architecture

### ansilust-ir - Intermediate Representation Schema
An intermediate representation format that unifies various text art formats:
- Supports every format from the wild west of [sixteencolors-archive](https://github.com/sixteencolors/sixteencolors-archive)
- Supports ansimation (ANSI animations)
- Supports modern utf8ansi text like Ghostty, Alacritty, Kitty, etc.

### Parsers (Output IR)

**BBS Art Parser** - Inspired by [libansilove](https://github.com/ansilove/libansilove)
- Reference: `reference/libansilove/` - See the AGENTS.md file for detailed documentation
- Key files to study:
  - `libansilove/src/loaders/ansi.c` - ANSI format parser
  - `libansilove/src/loaders/binary.c` - Binary format parser
  - `libansilove/src/loaders/pcboard.c` - PCBoard format
  - `libansilove/src/loaders/artworx.c` - ArtWorx format
  - `libansilove/include/ansilove.h` - Public API structure
- Supported formats: ANSI, Binary, PCBoard, Tundra, ArtWorx, iCE Draw, XBin

**UTF8ANSI Parser** - Inspired by [Ghostty](https://github.com/ghostty-org/ghostty)
- Reference: `reference/ghostty/` - See the AGENTS.md file for detailed documentation
- Key files to study:
  - `ghostty/src/terminal/Parser.zig` - VT escape sequence parser
  - `ghostty/src/terminal/Screen.zig` - Terminal screen buffer implementation
  - `ghostty/src/terminal/Terminal.zig` - Main terminal state machine
  - `ghostty/src/terminal/modes.zig` - Terminal modes handling
- Modern terminal features: True color, sixel graphics, Kitty graphics protocol, Unicode handling

### Renderers (Read IR)

**UTF8ANSI Renderer** - Reads intermediate representation and outputs utf8ansi
- Outputs modern terminal-compatible ANSI sequences
- Targets: Ghostty, Alacritty, Kitty, WezTerm, and other modern terminals

**HTML Canvas Renderer** - Reads intermediate representation and outputs HTML canvas draw calls
- Browser-based rendering
- Interactive web display of text art

## Reference Projects

### libansilove
Located at `reference/libansilove/libansilove/`
- C library for converting classic text art formats to PNG
- Clean API design and format parsing reference
- See `reference/libansilove/AGENTS.md` for detailed guide
- Prior art to revisit: `.specs/ir/prior-art-notes.md` (libansilove + SAUCE sections) before touching IR encoding/metadata decisions

### ansilove CLI
Located at `reference/ansilove/ansilove/`
- Command-line interface reference
- SAUCE metadata handling
- See `reference/ansilove/AGENTS.md` for detailed guide
- Prior art to revisit: `.specs/ir/prior-art-notes.md` (ansilove CLI section) ahead of IR metadata or CLI-alignment work

### Ghostty Terminal
Located at `reference/ghostty/ghostty/`
- Modern terminal emulator in Zig
- VT/xterm protocol implementation
- GPU-accelerated rendering techniques
- See `reference/ghostty/AGENTS.md` for detailed guide
- Prior art to revisit: `.specs/ir/prior-art-notes.md` (Ghostty section) before editing IR cell/grid/state decisions

### OpenTUI Framework
Located at `reference/opentui/opentui/`
- Modern TUI framework with TypeScript/Zig hybrid architecture
- OptimizedBuffer IR pattern (cell-based grid)
- Direct integration target for ansilust
- See `reference/opentui/AGENTS.md` for detailed guide

### Effect-TS
Located at `reference/effect-smol/`
- Functional programming library for TypeScript
- Effect system for type-safe error handling and resource management
- Powerful patterns for asynchronous programming and data pipelines
- Reference for building robust TypeScript-based parsers and renderers
- See `reference/effect-smol/AGENTS.md` for detailed development guidelines

### Bun Runtime
Located at `reference/bun/`
- All-in-one JavaScript/TypeScript runtime written in Zig
- FFI (Foreign Function Interface) for Zig/JavaScript interop
- High-performance systems programming patterns
- Built-in package manager, test runner, bundler
- See `reference/bun/AGENTS.md` for development guidelines
- Prior art to revisit: When designing Zig/TypeScript hybrid systems or optimizing parser performance

## When to Reference Each Project

- **libansilove** (`reference/libansilove/`) - When implementing BBS art parsers (ANSI, Binary, PCBoard, XBin, ArtWorx, Tundra, iCE Draw). Study before modifying IR encoding/font handling.

- **ansilove CLI** (`reference/ansilove/`) - When implementing CLI tools or SAUCE metadata handling. Study before building command-line interfaces or metadata processing.

- **Ghostty** (`reference/ghostty/`) - When implementing UTF8ANSI parser, terminal state machines, or modern terminal features. Study before modifying IR cell/grid/attribute structures.

- **OpenTUI** (`reference/opentui/`) - When designing IR compatibility, buffer structures, or rendering pipelines. Study for OptimizedBuffer patterns and integration targets.

- **Effect-TS** (`reference/effect-smol/`) - When building TypeScript-based parsers, renderers, or APIs. Study for type-safe error handling and functional composition patterns.

- **Bun** (`reference/bun/`) - When designing Zig/TypeScript hybrid systems, optimizing parser performance, or building FFI bridges. Study for memory allocation patterns and cross-boundary optimization.

## Key Learnings Summary

### From OpenTUI (Integration Target)
- **OptimizedBuffer IR**: Structure-of-arrays cell grid
- **Cell structure**: char, fg, bg, attributes (u8 bitflags)
- **RGBA colors**: Normalized floats (0.0-1.0)
- **Diff-based rendering**: Only emit ANSI for changed cells
- **Grapheme pooling**: Shared storage for multi-column Unicode
- **Animation support**: Frame-based updates with delta-time
- **Direct integration**: Our IR should convert to OptimizedBuffer

## IR Design Requirements

### From libansilove (Classic BBS Art)
- **Two-pass parsing**: Parse to character buffer (IR), then render
- **Bitmap fonts**: Fonts are byte arrays, embeddable in files (XBin, ArtWorx)
- **CP437 encoding**: BBS art uses DOS code pages, not Unicode
- **8 vs 9-bit width**: Character width affects box drawing (9th column)
- **Dual color mode**: Palette indices OR 24-bit RGB in same field
- **iCE colors mode**: Changes blink to high-intensity background
- **DOS aspect ratio**: CRT displays had non-square pixels (1.35x height)

### From ansilove (SAUCE Metadata)
- **SAUCE is critical**: 128-byte record with rendering parameters
- **Columns (tinfo1)**: Wrong value breaks layout completely
- **Flags byte**: Controls iCE colors, letter spacing, aspect ratio
- **Font name**: Maps to specific fonts (38+ available)
- **Not optional**: SAUCE contains essential rendering hints

### From Ghostty (Modern Terminals)
- **64-bit cells**: Packed efficiently with reference-counted styles
- **Wide characters**: Explicit spacer_head/spacer_tail for CJK/emoji
- **Grapheme clusters**: Multi-codepoint characters in external map
- **Wrap flags**: Soft vs hard wraps for reflow support
- **Color None**: Distinguished from black (terminal default)
- **Rich attributes**: Multiple underline styles, separate underline color
- **State machine**: Paul Williams VT parser for robust escape sequences
- **Hyperlinks**: OSC 8 support for clickable links

### From OpenTUI (Integration Target)
- **OptimizedBuffer IR**: Structure-of-arrays cell grid
- **Cell structure**: char, fg, bg, attributes (u8 bitflags)
- **RGBA colors**: Normalized floats (0.0-1.0)
- **Diff-based rendering**: Only emit ANSI for changed cells
- **Grapheme pooling**: Shared storage for multi-column Unicode
- **Animation support**: Frame-based updates with delta-time
- **Direct integration**: Our IR should convert to OptimizedBuffer

### From Effect-TS (TypeScript Architecture)
- **Effect type system**: Type-safe error handling without exceptions
- **Generator-based syntax**: Clean async/error handling with `Effect.gen`
- **Pipeable APIs**: Functional composition with `pipe()` for data transformations
- **Resource management**: Safe resource allocation/cleanup with `Effect.acquireRelease`
- **Schema validation**: Runtime type checking with `@effect/schema`
- **Layered architecture**: Dependency injection and modular service design
- **Error tracking**: Typed errors in function signatures (no hidden exceptions)
- **Stream processing**: Efficient data pipeline patterns for parsing large files
- **Testing patterns**: `it.effect` for async effect-based tests

## IR Design Requirements

Based on research, our IR must support:

### Classic BBS Art (libansilove/ansilove)
1. **CP437 character encoding** or other code pages
2. **Bitmap font references** or embedded font data
3. **8/9-bit letter spacing** flag
4. **iCE colors mode** flag (changes blink behavior)
5. **DOS aspect ratio** hint (1.35x)
6. **SAUCE metadata** (complete 128-byte record)
7. **Palette**: Standard (ANSI/VGA/Workbench) or custom (16/256 colors)
8. **Format-specific quirks**: Binary=160 cols, XBin=embedded everything

### Modern Terminals (Ghostty)
1. **Unicode codepoints** (21-bit, full range)
2. **Reference-counted styles** (memory efficiency)
3. **Wide character flags** (spacer_head/spacer_tail)
4. **Grapheme cluster map** (multi-codepoint characters)
5. **Soft/hard wrap flags** (reflow support)
6. **Color None variant** (terminal default ≠ black)
7. **Rich attributes**: Multiple underline styles, faint, overline
8. **Separate underline color**
9. **Hyperlink support** (OSC 8)
10. **Terminal modes** (wraparound, alt_screen, grapheme_cluster)

### OpenTUI Compatibility
1. **Cell grid structure** (width × height)
2. **Color as RGBA or palette** index
3. **Attributes as bitflags** (u8 or u16)
4. **Conversion function**: `to_optimized_buffer()`
5. **Animation frames** with delta operations

## Development Approach

- **Testing discipline**: Never delete or down-scope unit tests enumerated in `.specs/ir/plan.md` or STATUS. When refactoring APIs, port the existing tests to the new interface instead of removing them. If a test must change, update plan/STATUS to reflect the new coverage before modifying the code.
- **Commit discipline**: Capture every XP stage with a dedicated git commit—Red (failing tests added), Green (tests passing), and Refactor (cleanup)—and repeat at each phase and micro-phase boundary once validations succeed. For Red commits, ensure the new tests fail for the expected reason. Always rerun the relevant test suite (e.g. `zig build test`) immediately before committing.
- **Task tracking**: See `tracker/AGENTS.md` for workflow on managing active tasks, bugs, and gaps. Use `tracker/index.md` to find current priorities.

## Zig Module Import Patterns

**Problem**: Files can only belong to one module. Direct imports like `@import("../parsers/lib.zig")` cause "file exists in multiple modules" errors.

**Solution**: Use module dependencies defined in `build.zig`:

```zig
// build.zig sets up module dependencies:
const parsers_mod = b.addModule("parsers", .{ .root_source_file = b.path("src/parsers/lib.zig"), ... });
mod.addImport("parsers", parsers_mod);  // Makes parsers available to ansilust module

// In test files under src/renderers/ or src/ir/:
const parsers = @import("parsers");  // ✅ Correct - uses module dependency
const parsers = @import("../parsers/lib.zig");  // ❌ Wrong - direct import causes module conflict
```

**Module Structure**:
- `ansilust` module (src/root.zig) - main library module
- `parsers` module (src/parsers/lib.zig) - parser implementations
- Module dependencies configured in build.zig line 49-50

**Test Count Verification**:
```bash
# Count all tests in codebase
rg '^test ' src/ --count-matches | awk -F: '{sum += $2} END {print sum}'

# Verify zig runs all tests
zig build test --summary all 2>&1 | grep "tests passed"

# Should match: 121 tests found = 121 tests run
```

1. **Study complete** ✓
   - Classic text art format specifications (libansilove loaders)
   - Modern terminal escape sequence handling (Ghostty parser)
   - Font rendering techniques (bitmap fonts)
   - Efficient data structures (reference-counted styles, grapheme pooling)
   - Integration patterns (OpenTUI OptimizedBuffer)

2. **Design IR schema** (See `IR-RESEARCH.md`)
   - **Approach 1: Cell Grid IR** (RECOMMENDED)
     - OpenTUI-compatible cell grid
     - Reference-counted styles
     - Grapheme cluster map
     - SAUCE metadata preservation
     - Animation frame support

3. **Implement parsers** (IR output):
   - BBS art: ANSI, Binary, PCBoard, XBin, Tundra, ArtWorx, iCE Draw
   - Modern: UTF8ANSI terminal output (VT/xterm sequences)
   - SAUCE metadata extraction

4. **Implement renderers** (IR input):
   - **UTF8ANSI**: Modern terminal sequences (Ghostty, Alacritty, Kitty)
   - **HTML Canvas**: Browser rendering with draw calls
   - **OpenTUI**: Direct conversion to OptimizedBuffer
   - **PNG**: Static image output (like ansilove)

## Next Steps

1. Implement Cell Grid IR data structures (Rust)
2. Create ANSI parser → IR converter
3. Create UTF8ANSI renderer ← IR consumer
4. Test OpenTUI integration
5. Add remaining parsers (Binary, PCBoard, XBin)
6. Add HTML Canvas renderer
7. Support animation (ansimation format)
