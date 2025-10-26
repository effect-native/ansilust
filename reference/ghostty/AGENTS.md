# Ghostty Reference

## What is Ghostty?

Ghostty is a modern, fast, feature-rich terminal emulator written in Zig. It's designed to be cross-platform (macOS, Linux, Windows) with native platform integration and GPU-accelerated rendering.

## Contents

The `ghostty/` submodule contains:

- **Core terminal engine** (`src/terminal/`) - VT100/VT220/xterm terminal emulation
- **Rendering system** (`src/renderer/`) - GPU-accelerated text rendering
- **Font handling** (`src/font/`) - Font loading, shaping, and rendering
- **Platform integrations** - Native UI for macOS (AppKit/SwiftUI), Linux (GTK), Windows
- **Configuration** (`src/config/`) - Comprehensive configuration system
- **CLI tools** (`src/cli/`) - Command-line interface and utilities
- **Build system** (`build.zig`) - Zig build configuration
- **Tests** (`src/*/test_*.zig`) - Unit and integration tests
- **Examples** (`example/`) - C and Zig examples for embedding Ghostty

## Architecture Highlights

### Terminal Emulation
- Full VT100/VT220/xterm compatibility
- Modern terminal features (true color, sixel graphics, etc.)
- Efficient terminal state management
- Comprehensive escape sequence handling

### Rendering
- GPU-accelerated with OpenGL/Metal/Vulkan
- Text shaping with HarfBuzz
- Font fallback and ligature support
- Smooth animations and effects

### Platform Integration
- Native macOS UI with SwiftUI
- GTK4 support on Linux
- Windows native UI
- Wayland and X11 support

## What to do with it?

This reference implementation can be used to:

1. **Study terminal emulation** - Learn VT/xterm protocol implementation
2. **GPU rendering techniques** - See how to efficiently render text with GPU acceleration
3. **Font rendering** - Complex font shaping, fallback, and ligature handling
4. **Cross-platform architecture** - How to structure code for multiple platforms
5. **Configuration systems** - Comprehensive, typed configuration management
6. **Build systems** - Modern Zig build system patterns
7. **Performance optimization** - High-performance terminal rendering techniques
8. **Testing strategies** - Unit and integration testing for complex systems

## Key Files to Study

### Core Terminal
- `src/terminal/Terminal.zig` - Main terminal state machine
- `src/terminal/Screen.zig` - Terminal screen buffer
- `src/terminal/Parser.zig` - VT escape sequence parser

### Rendering
- `src/renderer/` - GPU rendering pipeline
- `src/font/` - Font loading and shaping
- `src/apprt/` - Application runtime abstractions

### Platform
- `macos/Sources/` - macOS AppKit/SwiftUI integration
- `src/apprt/gtk/` - GTK implementation
- `src/apprt/windows/` - Windows platform code

### Configuration
- `src/config/` - Configuration parsing and validation
- Configuration files show extensive feature set

### Build
- `build.zig` - Main build configuration
- `build.zig.zon` - Package dependencies

## Building

Requires Zig (see build.zig.zon for version):

```bash
cd ghostty
zig build
```

Platform-specific builds:
```bash
# macOS
zig build -Dapp-runtime=macos

# Linux (GTK)
zig build -Dapp-runtime=gtk

# Generate Xcode project (macOS)
zig build -Dapp-runtime=macos -Dxcode-project
```

## Integration Notes

Ghostty provides a C API for embedding:
- See `include/ghostty.h` for public API
- Examples in `example/c-vt/` show basic usage
- Can be embedded as a terminal widget in other applications

## Advanced Features to Study

- **Sixel graphics** - Bitmap graphics in terminal
- **Kitty graphics protocol** - Advanced image display
- **Shell integration** - Enhanced shell features
- **Unicode handling** - Complex text rendering
- **Performance profiling** - Built-in performance monitoring
- **Configuration hot-reload** - Live configuration updates

## Development Patterns

- Zig's comptime for optimization
- Zero-cost abstractions
- Memory-efficient data structures
- Comprehensive error handling
- Cross-platform abstractions

This is an excellent reference for building modern, high-performance terminal applications.

---

## Critical Learnings for Ansilust IR

### 1. Memory-Efficient Cell Structure

Ghostty packs an entire cell into **exactly 64 bits**:

**File Reference**: `src/terminal/page.zig` (search for "pub const Cell =")

```zig
pub const Cell = packed struct(u64) {
    content_tag: ContentTag,     // 2 bits
    content: union {             // 21 bits
        codepoint: u21,          // Full Unicode range
        color_palette: u8,
        color_rgb: RGB,
    },
    style_id: Id,                // Reference to style table
    wide: Wide,                  // 2 bits
    protected: bool,
    hyperlink: bool,
    _padding: u18,
};
```

**Lesson**: Be memory-efficient with careful bit packing. Cells don't need to inline all style data—use reference counting.

### 2. Reference-Counted Styles

Instead of storing full style data in every cell, Ghostty uses a **style table**:

**File Reference**: `src/terminal/style.zig:20-104`

- Cells store a `style_id` (small integer)
- Styles are stored once and reference-counted
- Typical terminal content reuses the same few styles

**Performance benefit**: **4x faster** when most cells share styles (per Ghostty benchmarks).

**Our IR should consider**:
```rust
struct Canvas {
    cells: Vec<Cell>,           // Just IDs, not full styles
    style_table: Vec<Style>,    // Shared styles
}
```

### 3. Wide Character Handling

Ghostty handles double-width characters (CJK, emoji) elegantly:

**File Reference**: `src/terminal/Terminal.zig:519-560`

- **Wide char** occupies 2 cells
- First cell: `{ codepoint: '中', wide: .wide }`
- Second cell: `{ codepoint: 0, wide: .spacer_tail }`

When wrapping at line end:
- Last cell: `{ wide: .spacer_head }` (indicates continuation)
- Next line starts with the actual wide char

**Our IR needs**:
```rust
bitflags! {
    struct CellFlags: u8 {
        const WIDE_CHAR      = 0b0001;
        const SPACER_TAIL    = 0b0010;
        const SPACER_HEAD    = 0b0100;
        const SOFT_WRAP      = 0b1000;
    }
}
```

### 4. Grapheme Cluster Storage

For multi-codepoint characters (emoji with modifiers, combining marks):

**File Reference**: `src/terminal/Terminal.zig:302-449`

- Primary codepoint in cell (21 bits)
- Additional codepoints stored separately in **grapheme map**
- Map: `Cell offset → []u21` (array of codepoints)
- Only allocated when needed (lazy)

**Lesson**: Don't inline multi-codepoint graphemes. Use external storage:
```rust
struct Canvas {
    cells: Vec<Cell>,
    grapheme_map: HashMap<u32, Vec<u32>>,  // cell_index → extra codepoints
}
```

### 5. Wrap Flags for Reflow

Ghostty distinguishes between:
- **Hard wrap**: User pressed Enter (paragraph break)
- **Soft wrap**: Line exceeded width (can reflow)

**File Reference**: `src/terminal/page.zig` (Row structure)

This is critical for terminal resize operations.

**Our IR should preserve**:
```rust
struct Row {
    cells: Vec<Cell>,
    soft_wrap: bool,  // Line continues on next row
}
```

### 6. Color Model Sophistication

**File Reference**: `src/terminal/style.zig:20-104`

```zig
pub const Color = union(Tag) {
    none: void,           // Use default (not black!)
    palette: u8,          // Index 0-255
    rgb: RGB,             // 24-bit true color
}
```

**Critical**: `None` is NOT the same as black—it means "use terminal default."

**Our IR needs**:
```rust
enum Color {
    None,              // Terminal default (not black!)
    Palette(u8),       // Index 0-255
    RGB(u8, u8, u8),   // 24-bit true color
}
```

### 7. Rich Text Attributes

**File Reference**: `src/terminal/style.zig`

```zig
const Flags = packed struct(u16) {
    bold, italic, faint, blink, inverse, invisible: bool,
    strikethrough, overline: bool,
    underline: Underline,  // 3 bits: none/single/double/curly/dotted/dashed
    _padding: u5,
};
```

Plus **separate underline color** (can differ from foreground!).

**Our IR should support**:
- Multiple underline styles (single, double, curly, dotted, dashed)
- Independent underline color
- Faint vs bold (different from just "bold off")

### 8. Terminal Modes Matter

Ghostty tracks 30+ terminal modes that affect rendering:

**File Reference**: `src/terminal/modes.zig:189-233`

- `wraparound` (7) - Auto-wrap at right margin
- `alt_screen` (1047/1049) - Alternate screen buffer
- `grapheme_cluster` (2027) - Proper grapheme clustering
- `origin` (6) - Cursor positioning relative to margins

**For complete fidelity**, our IR might need:
```rust
struct TerminalState {
    modes: Modes,
    scrolling_region: Option<(u32, u32)>,
}
```

### 9. Offset-Based, Not Pointer-Based

All Ghostty data structures use **offsets within page memory**, not raw pointers:

**File Reference**: `src/terminal/page.zig:82-186`

- Makes pages fully serializable
- Can mmap/munmap pages without pointer fixups
- Enables efficient scrollback management

**Lesson**: For serialization (saving IR to disk), offset-based is better than pointer-based.

### 10. State Machine Parser

Ghostty implements the **Paul Williams VT parser** state machine:

**File Reference**: `src/terminal/Parser.zig:16-32`

States: `ground`, `escape`, `csi_entry`, `csi_param`, `csi_dispatch`, etc.

**Lesson**: When parsing modern terminal output (UTF8ANSI), use a proper state machine, not regex.

### 11. Hyperlink Support (OSC 8)

Modern terminals support OSC 8 hyperlinks:

**File Reference**: `src/terminal/Screen.zig`

```
ESC]8;;https://example.com\aclickable text\ESC]8;;\a
```

**Our IR should support**:
```rust
struct Style {
    hyperlink: Option<HyperlinkId>,
}

struct Hyperlink {
    url: String,
    id: Option<String>,
}
```

### 12. Performance Through Dirty Tracking

Ghostty tracks which rows/cells are dirty:

**File Reference**: `src/terminal/Screen.zig`

- Only re-render changed content
- Per-row dirty bits
- Enables 60+ FPS terminal rendering

**For animation in our IR**:
```rust
struct Frame {
    timestamp_ms: u32,
    changed_cells: Vec<(u32, u32, Cell)>,  // (x, y, new_cell)
}
```

## What Our IR Must Preserve (Modern Terminals)

1. **Unicode codepoints** (U+0000 to U+10FFFF) - 21 bits
2. **Style attributes** - Bold, italic, underline variants, faint, etc.
3. **Color precision** - 256-color palette OR 24-bit RGB
4. **Wide character spans** - Double-width CJK and emoji
5. **Grapheme cluster boundaries** - Multi-codepoint characters
6. **Hyperlinks** - OSC 8 support
7. **Wrap flags** - Soft vs hard line breaks
8. **Terminal modes** - Wraparound, alt screen, grapheme clustering
9. **Separate underline color** - Can differ from foreground

## Key Architectural Patterns to Adopt

1. **Reference-counted styles** - Store styles once, reference by ID
2. **Grapheme pooling** - External storage for multi-codepoint chars
3. **Wide character flags** - Explicit spacer_head/spacer_tail markers
4. **Color None variant** - Distinguished from black
5. **Offset-based serialization** - For disk storage
6. **State machine parsing** - For robust escape sequence handling
7. **Dirty tracking** - For efficient animation rendering

These patterns enable production-grade terminal emulation with careful attention to performance, memory efficiency, and standards compliance.
