# Intermediate Representation (IR) - Instructions

## Overview

The Ansilust Intermediate Representation (IR) is a unified data format that serves as the bridge between various text art input formats (ANSI, Binary, PCBoard, XBin, etc.) and multiple output renderers (UTF8ANSI, HTML Canvas, PNG). The IR normalizes diverse legacy formats while preserving their essential characteristics, enabling format conversion, rendering, and manipulation.

## User Story

**As a** text art enthusiast and developer  
**I want** a single intermediate representation that can capture both classic BBS art and modern terminal art  
**So that** I can parse any text art format once and render it to any target format without losing fidelity

**Problem**: Classic text art formats (ANSI, Binary, PCBoard, XBin) and modern terminal formats (UTF8ANSI with true color, sixel, Kitty graphics) have fundamentally different data models:
- Classic formats use CP437 encoding, palette colors, bitmap fonts, and SAUCE metadata
- Modern formats use Unicode, true color, grapheme clusters, and rich attributes
- No unified representation exists to bridge these worlds

**Solution**: Create a Cell Grid IR that:
- Captures raw source bytes plus an encoding tag (CP437, PETSCII, UTF-8, etc.) for every cell while also storing normalized Unicode.
- Handles both palette-indexed and true color (RGBA) pipelines.
- Preserves SAUCE metadata and rendering hints.
- Represents ansimation frames and timing metadata even when downstream renderers ignore animations.
- Enables lossless conversion between compatible formats.
- Provides a clean API for parsers (write IR) and renderers (read IR).

## Core Requirements (EARS Notation)

### Input Format Support

**R1.1**: The IR shall represent text art from classic BBS formats (ANSI, Binary, PCBoard, XBin, Tundra, ArtWorx, iCE Draw).

**R1.2**: The IR shall represent text art from modern terminal formats (UTF8ANSI with VT/xterm escape sequences).

**R1.3**: WHEN SAUCE metadata is present in source data the IR shall preserve all 128 bytes of the SAUCE record.

**R1.4**: The IR shall store per-cell source code unit bytes plus an explicit encoding tag (e.g., CP437, PETSCII, UTF-8) together with the normalized Unicode representation.
**R1.5**: WHEN ansimation data is present in source content the IR shall preserve frame ordering, timing metadata, and repeat semantics even if no renderer consumes it.

### Character and Color Representation

**R2.1**: The IR shall represent individual cells in a two-dimensional grid structure.

**R2.2**: The IR shall support character widths from 1 to 2 columns (for wide Unicode characters).

**R2.3**: The IR shall support both palette-indexed colors (16/256 color palettes) and true color (24-bit RGB).

**R2.4**: The IR shall distinguish between "no color" (terminal default) and explicit black.

**R2.5**: WHILE representing classic BBS art the IR shall preserve palette index information.

**R2.6**: WHILE representing modern terminal art the IR shall preserve RGBA color values.

### Text Attributes

**R3.1**: The IR shall support standard text attributes (bold, italic, underline, blink, reverse, strikethrough).

**R3.2**: The IR shall support extended attributes (faint, overline, multiple underline styles).

**R3.3**: WHERE underline attributes are present the IR shall support separate underline color.

**R3.4**: The IR shall support the iCE colors mode flag (blink vs high-intensity background).

### Font and Rendering Hints

**R4.1**: The IR shall preserve font information (font name or embedded font data).

**R4.2**: The IR shall preserve letter spacing hints (8-bit vs 9-bit width).

**R4.3**: The IR shall preserve aspect ratio hints (DOS CRT 1.35x vs square pixels).

**R4.4**: WHERE XBin or ArtWorx formats include embedded fonts the IR shall store font bitmap data.

### Metadata and Context

**R5.1**: The IR shall preserve SAUCE metadata fields (title, author, group, date, comments).

**R5.2**: The IR shall record the source format type for rendering optimization.

**R5.3**: The IR shall store grid dimensions (width and height in cells).

**R5.4**: WHERE multi-byte character sequences exist the IR shall maintain grapheme cluster integrity.

### Memory and Performance

**R6.1**: The IR shall use explicit allocator parameters for all memory allocations.

**R6.2**: The IR shall support efficient serialization and deserialization.

**R6.3**: The IR shall minimize memory overhead for typical text art files.

**R6.4**: The IR shall support zero-copy access to cell data where possible.

### Error Handling

**R7.1**: IF memory allocation fails during IR construction THEN the system shall return error.OutOfMemory.

**R7.2**: IF invalid cell coordinates are accessed THEN the system shall return error.InvalidCoordinate.

**R7.3**: IF serialization fails THEN the system shall return appropriate error with context.

## Technical Specifications

### Data Structures

**Cell Grid**: Structure-of-arrays design inspired by OpenTUI's OptimizedBuffer
- Width and height (usize)
- Cell arrays for raw source byte slices, encoding tags, normalized Unicode scalars or grapheme IDs, foreground, background, and attribute bitflags
- Grapheme cluster map for multi-codepoint characters
- Style reference counting for memory efficiency

**Character Representation**:
- Source code unit bytes (e.g., []u8) plus an encoding tag enumerating CP437, PETSCII, UTF-8, or future code pages.
- Normalized Unicode codepoint (u21) or grapheme cluster reference for renderer-friendly text.
- Wide character flags (spacer_head, spacer_tail)
- Grapheme cluster ID for complex characters

**Color Representation**:
- Tagged union: PaletteIndex(u8) | RGB(r: u8, g: u8, b: u8) | None
- RGBA support (normalized 0.0-1.0 floats) for modern rendering
- Palette data structure (16 or 256 colors)

**Attributes**:
- Bitflags (u16) for standard attributes
- Extended attribute structure for underline style/color

**SAUCE Metadata**:
- Complete 128-byte record preservation
- Parsed fields (title, author, group, date, datatype, filetype, flags)
- Comment block storage (optional)

**Font Information**:
- Font name string (e.g., "IBM VGA", "Amiga Topaz")
- Embedded font data (optional, for XBin/ArtWorx)
- Font dimensions (character width x height in pixels)

**Animation Support**:
- Ordered frame list with each frame referencing a cell grid snapshot or delta against a previous frame.
- Per-frame timing metadata (duration, optional delay, repeat markers) preserved from source data.
- Global animation controls such as loop count or play-until-end flags, even when renderers ignore them.

### API Design

**Parser API** (writes to IR):
```zig
pub fn parse(allocator: Allocator, input: []const u8, format: FormatType) !IR
```

**Renderer API** (reads from IR):
```zig
pub fn render(ir: IR, allocator: Allocator, options: RenderOptions) ![]const u8
```

**IR Manipulation**:
```zig
pub fn getCell(ir: IR, x: usize, y: usize) !Cell
pub fn setCell(ir: *IR, x: usize, y: usize, cell: Cell) !void
pub fn resize(ir: *IR, width: usize, height: usize) !void
```

### Integration Points

- **Ghostty Integration**: Primary terminal target ensuring VT/xterm semantics, grapheme handling, OSC 8, and color None behavior remain intact.
- **OpenTUI Integration (optional)**: Provide conversion to OptimizedBuffer when that toolchain is part of the deployment story.
- **Parser Integration**: ANSI, Binary, PCBoard, XBin parsers write to IR
- **Renderer Integration**: UTF8ANSI, HTML Canvas, PNG renderers read from IR

## Acceptance Criteria

**AC1**: The IR can successfully represent a CP437 ANSI file with SAUCE metadata.

**AC2**: The IR can successfully represent a UTF8ANSI file with true color and wide characters.

**AC3**: WHEN an ANSI file with iCE colors is parsed THEN the IR preserves the iCE colors mode flag.

**AC4**: WHEN an XBin file with embedded fonts is parsed THEN the IR preserves the complete font bitmap data.

**AC5**: WHEN ansimation data is parsed THEN the IR preserves frame ordering, timing metadata, and repeat semantics even if renderers ignore animations.

**AC6**: The IR can be serialized to bytes and deserialized without data loss.

**AC7**: The IR can be converted to OpenTUI's OptimizedBuffer format.

**AC8**: WHEN rendering the IR to UTF8ANSI THEN the output produces visually identical results to the original.

**AC9**: All IR operations pass memory leak detection with std.testing.allocator.

**AC10**: All public IR APIs have comprehensive doc comments with examples.

**AC11**: The IR processes a 1KB ANSI file in under 1ms on reference hardware.

## Out of Scope

**OS1**: Real-time animation playback (handled by renderer layer)

**OS2**: Image processing or pixel-level manipulation (use dedicated graphics libraries)

**OS3**: Font rendering to pixels (handled by renderer layer)

**OS4**: Network protocols or file I/O (handled by application layer)

**OS5**: Format auto-detection (handled by parser selection logic)

**OS6**: Compression or encryption (handled by application layer)

## Success Metrics

**SM1**: IR successfully represents 100% of test files from sixteencolors-archive

**SM2**: Zero memory leaks detected in all IR operations

**SM3**: IR serialization overhead < 50% of original file size for typical files

**SM4**: 100% doc comment coverage for public IR APIs

**SM5**: All reference files round-trip through IR without visual differences

**SM6**: Conversion from legacy format → IR → modern format maintains fidelity

**SM7**: Build and test suite complete in under 5 seconds

## Future Considerations

**FC1**: Animation frame support (ansimation format)
- Frame timing metadata
- Delta compression for frame changes
- Keyframe support

**FC2**: Layering support
- Multiple cell grid layers
- Blend modes
- Layer visibility and opacity

**FC3**: Hyperlink support (OSC 8)
- URL storage and cell association
- Link ID management

**FC4**: Advanced graphics protocols
- Sixel image data preservation
- Kitty graphics protocol support
- ReGIS graphics

**FC5**: Accessibility features
- Alt text for visual elements
- Semantic structure hints
- Screen reader optimization

**FC6**: Compression
- RLE compression for sparse grids
- Delta encoding for similar cells
- Reference-based deduplication

**FC7**: Additional encoding families
- Extend the encoding enumeration to cover PETSCII variants, Shift-JIS, ISO-8859, and future code pages.
- Maintain raw source bytes and mapping tables even when renderers lack native support for those encodings.


## Testing Requirements

### Unit Tests (T1–T6)

**T1**: Cell Grid Operations
- Create grid with specified dimensions
- Get/set cells at valid coordinates
- Error handling for invalid coordinates
- Memory leak detection

**T2**: Character Encoding
- Raw source byte slices preserved and retrievable for CP437, PETSCII, and UTF-8 samples
- Encoding tag values remain consistent with the stored raw bytes
- Encoding tag enumeration covers CP437, PETSCII, UTF-8, and placeholder slots for future code pages
- Unicode codepoint storage and retrieval
- Wide character handling (spacer cells)
- Grapheme cluster management

**T3**: Color Representation
- Palette index colors (16 and 256)
- RGB true colors
- Color None (terminal default)
- RGBA conversion and normalization

**T4**: Attributes
- Standard attribute flags
- Extended attributes
- Separate underline color
- Attribute combinations

**T5**: SAUCE Metadata
- Parse complete SAUCE record
- Extract all metadata fields
- Preserve comment blocks
- Handle files without SAUCE

**T6**: Font Information
- Store font name
- Store embedded font data
- Validate font dimensions

### Integration Tests (T7–T9)

**T7**: Format Round-Trips
- ANSI → IR → ANSI (lossless)
- XBin → IR → XBin (preserve fonts)
- UTF8ANSI → IR → UTF8ANSI (preserve Unicode)
- Ansimation → IR → Ansimation (preserve frame order, timing, and loop semantics)

**T8**: Cross-Format Conversion
- Classic BBS → IR → Modern terminal
- Palette colors → true color mapping
- CP437 → Unicode conversion

**T9**: OpenTUI Integration
- IR → OptimizedBuffer conversion
- Validate cell structure compatibility
- Verify color format conversion

### Property-Based Tests (T10–T12)

**T10**: Fuzz testing for parsers writing to IR
- Random byte sequences
- Invalid SAUCE records
- Malformed escape sequences

**T11**: Invariant testing
- Grid dimensions consistent
- No out-of-bounds access
- Memory allocation balanced with deallocation

**T12**: Ansimation timeline fuzzing
- Randomized frame counts, delays, and loop flags
- Delta-only frames mixed with full snapshots
- Boundary values for zero-duration and maximum-duration frames

### Performance Tests (T13–T15)

**T13**: Benchmark typical operations
- Create IR from 1KB, 10KB, 100KB files
- Cell access patterns (sequential, random)
- Serialization and deserialization

**T14**: Memory usage profiling
- Typical file overhead
- Peak memory during parsing
- Memory pooling effectiveness

**T15**: Ansimation playback benchmarking
- Measure frame-application throughput with varying frame counts
- Evaluate timing metadata parsing overhead
- Validate loop and repeat handling under sustained playback

## Example EARS Requirements (Reference)

These examples demonstrate proper EARS notation for the IR feature:

### Ubiquitous Requirements
```
The IR shall validate grid dimensions before allocating memory.
The IR shall provide a public API for cell access operations.
The IR shall support serialization to byte format.
```

### Event-Driven Requirements
```
WHEN a parser encounters SAUCE metadata the IR shall extract all 128 bytes.
WHEN an allocation fails the IR shall return error.OutOfMemory.
WHEN serialization completes the IR shall return the byte array.
```

### State-Driven Requirements
```
WHILE in iCE colors mode the IR shall interpret bit 7 as background intensity.
WHILE processing CP437 data the IR shall use code page 437 mapping.
WHILE the IR instance is active the IR shall track all allocations.
```

### Unwanted Behavior Requirements
```
IF invalid grid coordinates are provided THEN the IR shall return error.InvalidCoordinate.
IF SAUCE magic bytes are incorrect THEN the IR shall treat the data as regular content.
IF buffer overflow is detected THEN the IR shall return error.BufferTooSmall.
```

### Optional Feature Requirements
```
WHERE XBin support is enabled the IR shall preserve embedded font data.
WHERE animation is supported the IR shall maintain frame timing information.
WHERE debug mode is active the IR shall emit detailed diagnostic logs.
```
