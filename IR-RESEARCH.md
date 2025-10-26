# Ansilust IR Research - Findings and Proposals

This document summarizes findings from studying four reference projects and proposes concrete IR design approaches.

## Research Summary

### 1. libansilove - Classic BBS Art Rendering

**Key Architecture Pattern**: Two-pass parsing with intermediate character buffer

**Data Structures**:
```c
struct ansiChar {
    int32_t column, row;        // Position
    uint32_t background;        // 0-15 palette OR 24-bit RGB
    uint32_t foreground;        // 0-15 palette OR 24-bit RGB
    uint8_t character;          // ASCII/CP437 character code
};
```

**Critical Insights**:
- Parsers build arrays of positioned characters, THEN render
- This character buffer IS their intermediate representation
- Fonts are bitmap data: `byte_array[character * height + scanline]`
- Colors: Palette indices (0-15) OR 24-bit RGB (`(R<<16)|(G<<8)|B`)
- iCE colors mode: Blink bit enables high-intensity backgrounds
- 8 vs 9 bit mode: Width of character cells (9th column for box drawing)

**What Must Be Preserved**:
- Character position (column, row)
- Character code (0-255)
- Foreground color (palette OR RGB)
- Background color (palette OR RGB)
- Font reference or embedded font data
- Rendering hints: iCE colors, bits (8/9), aspect ratio

**File Reference**: `reference/libansilove/libansilove/src/loaders/ansi.c:44-50`

---

### 2. ansilove - SAUCE Metadata Standard

**SAUCE Record** (128 bytes at EOF):
```c
struct sauce {
    char ID[6];              // "SAUCE\0"
    char version[3];         // "00"
    char title[36];          // Artwork title
    char author[21];         // Artist name
    char group[21];          // Artist group
    char date[9];            // CCYYMMDD
    int32_t fileSize;        // Original size
    unsigned char dataType;  // Format category
    unsigned char fileType;  // Format within category
    unsigned short tinfo1;   // Columns (ANS/BIN) or width
    unsigned short tinfo2;   // Rows or height
    unsigned short tinfo3;   // Type-specific
    unsigned short tinfo4;   // Type-specific
    unsigned char comments;  // Number of comment lines
    unsigned char flags;     // iCE colors, aspect, letter spacing
    char tinfos[23];         // Font name
};
```

**Critical Metadata**:
- **tinfo1 (columns)**: Wrong value completely ruins layout
- **flags & 1**: iCE colors enabled/disabled
- **flags & 6**: 8-bit vs 9-bit letter spacing
- **flags & 24**: DOS aspect ratio
- **tinfos**: Font name string (maps to specific font)

**What Must Be Preserved**:
- Artist attribution (title, author, group, date)
- Rendering parameters (columns, flags, font)
- Comments (multi-line artist notes)
- Original file format information

**File Reference**: `reference/ansilove/ansilove/src/sauce.h:27-45`

---

### 3. Ghostty - Modern Terminal Emulation

**Cell Structure** (64 bits packed):
```zig
pub const Cell = packed struct(u64) {
    content_tag: ContentTag,     // 2 bits - codepoint/grapheme/bg-only
    content: union {             // 21 bits
        codepoint: u21,          // Unicode codepoint
        color_palette: u8,       // Palette index (bg-only cell)
        color_rgb: RGB,          // 24-bit RGB (bg-only cell)
    },
    style_id: Id,                // Reference to style table
    wide: Wide,                  // 2 bits - narrow/wide/spacer_head/spacer_tail
    protected: bool,
    hyperlink: bool,
    _padding: u18,
};
```

**Style Structure**:
```zig
pub const Style = struct {
    fg_color: Color,          // none/palette/rgb
    bg_color: Color,
    underline_color: Color,   // Can differ from foreground!
    flags: Flags,             // 16-bit packed attributes
};

const Flags = packed struct(u16) {
    bold, italic, faint, blink, inverse, invisible: bool,
    strikethrough, overline: bool,
    underline: Underline,    // 3 bits: none/single/double/curly/dotted/dashed
    _padding: u5,
};
```

**Critical Insights**:
- **Reference-counted styles**: Styles stored in table, cells reference by ID
- **Grapheme clusters**: Multi-codepoint characters stored separately
- **Wide characters**: Use 2 cells (wide + spacer_tail)
- **Wrap flags**: Soft vs hard line breaks (for reflow)
- **Offset-based pointers**: All data within page memory
- **21-bit codepoints**: Full Unicode range

**What Must Be Preserved**:
- Unicode codepoints (U+0000 to U+10FFFF)
- Style attributes (bold, italic, underline variants, etc.)
- Color precision (256-color palette OR 24-bit RGB)
- Wide character spans
- Grapheme cluster boundaries
- Hyperlinks
- Terminal modes (wraparound, alt screen, etc.)

**File Reference**: `reference/ghostty/ghostty/src/terminal/page.zig` (Cell/Row structs)

---

### 4. OpenTUI - Modern TUI Framework

**OptimizedBuffer Structure** (Structure-of-Arrays):
```typescript
{
  char: Uint32Array,      // Unicode codepoints (one per cell)
  fg: Float32Array,       // RGBA colors (4 floats per cell)
  bg: Float32Array,       // RGBA colors (4 floats per cell)
  attributes: Uint8Array  // Bitflags for styling (one per cell)
}
```

**Cell Representation** (conceptual):
```zig
pub const Cell = struct {
    char: u32,        // Unicode codepoint or grapheme ID
    fg: RGBA,         // [r, g, b, a] as f32 (0.0-1.0)
    bg: RGBA,
    attributes: u8,   // Bold, italic, underline, etc.
};
```

**Critical Insights**:
- **Format-agnostic IR**: Can be populated from any source
- **Renderer-agnostic**: Can output to ANSI, HTML, or other targets
- **Structure-of-arrays**: Cache-friendly memory layout
- **Normalized colors**: Float RGBA (0.0-1.0) for precision
- **Diff-based rendering**: Only emit ANSI for changed cells
- **Run-length encoding**: Optimize consecutive cells with same attributes
- **Grapheme pooling**: Shared storage for multi-column Unicode
- **Animation support**: Frame-based updates with delta-time

**Rendering Pipeline**:
```
Source → OptimizedBuffer → Diff → ANSI Output
```

**Integration Pattern**:
```typescript
// This is what we want for ansilust:
parse_ansi_file() → AnsilustIR → toOptimizedBuffer() → render()
```

**File Reference**: `reference/opentui/opentui/packages/core/src/zig/buffer.zig:84-89`

---

## IR Design Principles

Based on the research, our IR must:

1. **Thread the needle**: Not too verbose (like stream of escape codes), not too lossy (like pure bitmap)
2. **Preserve intent**: Enough data to accurately render artist's original vision
3. **Be reversible**: Where practical, regenerate original format
4. **Support both worlds**: Classic BBS art (CP437, palette) AND modern terminals (Unicode, RGB)
5. **Enable animation**: Frame-based updates for ansimation
6. **Be consumable**: Direct integration with OpenTUI and similar frameworks

---

## Three IR Approach Proposals

### Approach 1: Cell Grid IR (OpenTUI-Compatible)

**Philosophy**: Match OpenTUI's OptimizedBuffer structure for zero-friction integration

**Structure**:
```rust
struct AnsilustIR {
    // Metadata
    version: String,                    // "1.0.0"
    source_format: SourceFormat,        // ANSI, Binary, PCBoard, etc.
    
    // Canvas dimensions
    width: u32,                         // Columns
    height: u32,                        // Rows
    
    // Cell grid (width × height)
    cells: Vec<Cell>,
    
    // Resources
    palette: Option<Palette>,           // Custom palette (16 or 256 colors)
    font: FontInfo,                     // Font reference or embedded data
    
    // Metadata
    sauce: Option<SauceRecord>,
    metadata: HashMap<String, Value>,
    
    // Animation (optional)
    frames: Option<Vec<Frame>>,
}

struct Cell {
    char: u32,              // Unicode codepoint OR CP437 code
    fg: Color,              // Foreground color
    bg: Color,              // Background color
    attributes: Attributes, // Packed bitflags
}

enum Color {
    None,                   // Default/transparent
    Palette(u8),            // Index into palette (0-255)
    RGB(u8, u8, u8),        // 24-bit true color
}

bitflags! {
    struct Attributes: u16 {
        const BOLD          = 0b0000_0001;
        const FAINT         = 0b0000_0010;
        const ITALIC        = 0b0000_0100;
        const UNDERLINE     = 0b0000_1000;
        const BLINK         = 0b0001_0000;
        const REVERSE       = 0b0010_0000;
        const INVISIBLE     = 0b0100_0000;
        const STRIKETHROUGH = 0b1000_0000;
        // 8 more bits for extended attributes
    }
}

struct FontInfo {
    id: Option<String>,           // "cp437", "topaz", etc.
    embedded: Option<BitmapFont>, // Or embed font data
}

struct Frame {
    timestamp_ms: u32,            // When to display
    operations: Vec<Operation>,   // Changes from previous frame
}

enum Operation {
    SetCell { x: u32, y: u32, cell: Cell },
    FillRect { x: u32, y: u32, w: u32, h: u32, cell: Cell },
    ScrollRect { x: u32, y: u32, w: u32, h: u32, dx: i32, dy: i32 },
    SetPalette { palette: Palette },
}
```

**Pros**:
- ✅ **Direct OpenTUI compatibility**: Convert to OptimizedBuffer by copying arrays
- ✅ **Simple and clean**: Easy to understand and implement
- ✅ **Efficient rendering**: Cell grid maps directly to output
- ✅ **Animation support**: Frame-based updates with delta operations
- ✅ **Handles both formats**: Classic (palette) and modern (RGB) via Color enum
- ✅ **Compact for static art**: Single frame with full cell grid

**Cons**:
- ❌ **Verbose for sparse content**: Full grid even if mostly empty
- ❌ **No direct ANSI reversibility**: Lost original escape sequence structure
- ❌ **Wide character complexity**: Need special handling for double-width chars
- ❌ **Font embedding overhead**: Bitmap fonts can be large (4-8KB each)

**Use Cases**:
- Converting BBS art to modern terminals
- OpenTUI integration
- HTML canvas rendering
- Animation playback

**Conversion Examples**:
```rust
// ANSI → Cell Grid
let ir = parse_ansi("artwork.ans");
let buffer = ir.to_optimized_buffer();
renderer.set_buffer(buffer);

// Cell Grid → UTF8ANSI
let ansi_output = render_utf8ansi(&ir);
println!("{}", ansi_output);

// Cell Grid → HTML Canvas
let canvas_js = render_html_canvas(&ir);
```

---

### Approach 2: Operation Stream IR (ANSI-Friendly)

**Philosophy**: Preserve original command structure for perfect reversibility

**Structure**:
```rust
struct AnsilustIR {
    // Metadata
    version: String,
    source_format: SourceFormat,
    
    // Initial state
    initial_state: TerminalState,
    
    // Command stream
    operations: Vec<Operation>,
    
    // Resources
    resources: Resources,
    
    // Metadata
    sauce: Option<SauceRecord>,
}

struct TerminalState {
    width: u32,
    height: u32,
    palette: Palette,
    font: FontInfo,
    cursor: CursorState,
    modes: Modes,
}

enum Operation {
    // Text output
    WriteText { text: String, style: Style },
    WriteChar { char: u32, style: Style },
    
    // Cursor movement
    MoveCursor { x: u32, y: u32 },
    MoveCursorRelative { dx: i32, dy: i32 },
    SaveCursor,
    RestoreCursor,
    
    // Style changes
    SetForeground { color: Color },
    SetBackground { color: Color },
    SetAttributes { add: Attributes, remove: Attributes },
    ResetStyle,
    
    // Screen operations
    ClearScreen,
    ClearLine,
    EraseRect { x: u32, y: u32, w: u32, h: u32 },
    ScrollUp { lines: u32 },
    ScrollDown { lines: u32 },
    
    // Modes
    SetMode { mode: Mode, enabled: bool },
    
    // Resources
    SetPalette { palette: Palette },
    SetPaletteColor { index: u8, rgb: (u8, u8, u8) },
    
    // Animation
    Delay { ms: u32 },
}

struct Resources {
    palettes: HashMap<String, Palette>,
    fonts: HashMap<String, BitmapFont>,
    images: HashMap<String, Image>,
}
```

**Pros**:
- ✅ **Perfect ANSI reversibility**: Can regenerate exact escape sequences
- ✅ **Compact for sparse content**: Only stores actual operations
- ✅ **Efficient for streaming**: Operations apply in sequence
- ✅ **Natural animation support**: Delay operations between frames
- ✅ **Preserves artist intent**: Cursor movements, timing, effects
- ✅ **Format-agnostic**: Works for ANSI, PCBoard, Tundra, modern terminals

**Cons**:
- ❌ **Complex to render**: Must simulate terminal state machine
- ❌ **No random access**: Can't directly read cell at (x, y) without replay
- ❌ **OpenTUI integration harder**: Needs conversion to cell grid first
- ❌ **Large for dense content**: More operations than cells
- ❌ **Cursor tracking required**: Renderer must maintain cursor position

**Use Cases**:
- Lossless ANSI conversion
- Terminal emulator integration
- Streaming/progressive rendering
- Preserving original structure for archival

**Conversion Examples**:
```rust
// ANSI → Operation Stream (lossless)
let ir = parse_ansi_lossless("artwork.ans");
// ir.operations preserves original ESC sequences

// Operation Stream → ANSI (reversible)
let ansi = ir.to_ansi(); // Nearly identical to original

// Operation Stream → Cell Grid (for rendering)
let mut terminal = VirtualTerminal::new(80, 25);
for op in &ir.operations {
    terminal.execute(op);
}
let cells = terminal.cells();
```

---

### Approach 3: Hybrid Layer IR (Best of Both Worlds)

**Philosophy**: Combine cell grid (for rendering) with operation stream (for reversibility)

**Structure**:
```rust
struct AnsilustIR {
    // Metadata
    version: String,
    source_format: SourceFormat,
    
    // Rendering layer (required)
    canvas: Canvas,
    
    // Source layer (optional, for reversibility)
    source: Option<SourceLayer>,
    
    // Resources
    resources: Resources,
    
    // Metadata
    sauce: Option<SauceRecord>,
    metadata: Metadata,
}

// Fast rendering path
struct Canvas {
    width: u32,
    height: u32,
    cells: Vec<Cell>,           // Flattened cell grid
    style_table: Vec<Style>,    // Reference-counted styles (like Ghostty)
    palette: Palette,
    font: FontInfo,
}

struct Cell {
    char: u32,                  // Unicode or CP437
    style_id: u16,              // Index into style_table
    flags: CellFlags,           // Wide char, wrap, etc.
}

bitflags! {
    struct CellFlags: u8 {
        const WIDE_CHAR      = 0b0001;
        const SPACER_TAIL    = 0b0010;
        const SPACER_HEAD    = 0b0100;
        const SOFT_WRAP      = 0b1000;
    }
}

struct Style {
    fg: Color,
    bg: Color,
    attributes: Attributes,
    ref_count: u32,             // Track usage
}

// Lossless source layer (optional)
struct SourceLayer {
    format: SourceFormat,
    operations: Vec<Operation>,
    initial_state: TerminalState,
}

struct Resources {
    palettes: HashMap<String, Palette>,
    fonts: HashMap<String, BitmapFont>,
    images: HashMap<String, Image>,
}

// Animation support
struct Metadata {
    frames: Option<Vec<Frame>>,
    // ...
}

struct Frame {
    timestamp_ms: u32,
    canvas_delta: CanvasDelta,        // For fast rendering
    operations: Option<Vec<Operation>>, // For reversibility
}

struct CanvasDelta {
    changed_cells: Vec<(u32, u32, Cell)>, // (x, y, new_cell)
}
```

**Pros**:
- ✅ **Fast rendering**: Cell grid ready for immediate display
- ✅ **Lossless reversibility**: Source layer preserves original structure
- ✅ **OpenTUI compatible**: Canvas converts directly to OptimizedBuffer
- ✅ **Compact storage**: Can omit source layer if not needed
- ✅ **Best of both**: Rendering speed + format fidelity
- ✅ **Reference-counted styles**: Efficient memory usage (Ghostty pattern)
- ✅ **Animation optimized**: Store both full frames and deltas

**Cons**:
- ❌ **More complex**: Two representations to maintain
- ❌ **Larger file size**: Redundant data if both layers included
- ❌ **Consistency risk**: Canvas and source could diverge
- ❌ **Implementation complexity**: Must keep layers in sync

**Use Cases**:
- Professional tools requiring both speed and accuracy
- Archival format (preserve original + rendered result)
- Format conversion (use canvas for output, source for input)
- Advanced editing (modify canvas, regenerate operations)

**Conversion Examples**:
```rust
// ANSI → Hybrid IR
let ir = parse_ansi_hybrid("artwork.ans");
// ir.canvas: ready for immediate rendering
// ir.source: preserves original ANSI structure

// Hybrid → OpenTUI (fast path)
let buffer = ir.canvas.to_optimized_buffer();

// Hybrid → ANSI (source path)
if let Some(source) = &ir.source {
    let ansi = source.to_ansi();
}

// Hybrid → HTML Canvas (rendering path)
let html = render_html_canvas(&ir.canvas);
```

---

## Recommendation

**Start with Approach 1 (Cell Grid IR)** for the following reasons:

1. **Simplest to implement**: Clear data model, straightforward parsers
2. **OpenTUI compatibility**: Primary requirement met immediately
3. **Handles 90% of use cases**: Static art, simple animations
4. **Clean foundation**: Can evolve to Approach 3 later if needed

**Migration Path**:
```
Phase 1: Implement Cell Grid IR (Approach 1)
  ↓
Phase 2: Add parsers (ANSI, Binary, PCBoard, XBin)
  ↓
Phase 3: Add renderers (UTF8ANSI, HTML Canvas)
  ↓
Phase 4: Add source layer (Approach 3) if lossless ANSI needed
```

**Key Design Decisions**:

1. **Color Representation**: Use `enum Color { None, Palette(u8), RGB(u8, u8, u8) }`
   - Handles both classic (palette) and modern (RGB) formats
   - Explicit None variant for default colors

2. **Style Storage**: Start with inline attributes, migrate to table if needed
   - Simple: Store attributes in each cell
   - Optimized: Reference-counted style table (like Ghostty/Hybrid)

3. **Font Handling**: Reference by ID, embed on demand
   - Default fonts: String IDs ("cp437", "topaz", etc.)
   - Custom fonts: Embed bitmap data with metadata

4. **Animation**: Frame-based with delta operations
   - Frame 0: Full cell grid
   - Frame N: Operations to apply to previous frame

5. **OpenTUI Integration**: Provide conversion function
   ```rust
   impl AnsilustIR {
       fn to_optimized_buffer(&self) -> OptimizedBuffer {
           // Convert Cell vec to SoA layout
           // Convert Color to RGBA f32
           // Map attributes to u8 bitflags
       }
   }
   ```

---

## Next Steps

1. **Define Rust data structures** for Cell Grid IR (Approach 1)
2. **Implement ANSI parser** → Cell Grid IR
3. **Implement UTF8ANSI renderer** ← Cell Grid IR
4. **Test with OpenTUI integration**
5. **Add more parsers** (Binary, PCBoard, XBin)
6. **Add HTML Canvas renderer**
7. **Evaluate if source layer needed** (upgrade to Approach 3)

