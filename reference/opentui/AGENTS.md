# OpenTUI Reference

## What is OpenTUI?

OpenTUI is a modern TypeScript/Zig framework for building Terminal User Interfaces (TUIs) with a component-based architecture similar to React/Solid.js. It provides high-performance rendering with a hybrid approach: TypeScript for framework logic and Zig for performance-critical buffer operations and ANSI generation.

## Contents

The `opentui/` submodule contains:

- **Core Framework** (`packages/core/`) - Main rendering engine and buffer management
- **Zig Native Layer** (`packages/core/src/zig/`) - High-performance buffer operations and ANSI rendering
- **React Integration** (`packages/react/`) - React reconciler for declarative TUIs
- **Solid.js Integration** (`packages/solid/`) - Solid.js reconciler
- **3D Rendering** (`packages/core/src/3d/`) - WebGPU-based advanced rendering
- **Examples** (`examples/`) - Sample applications

## Architecture Highlights

### Hybrid TypeScript/Zig Design
- **TypeScript**: Component tree, event handling, framework integrations
- **Zig**: Cell buffer operations, diff algorithms, ANSI generation
- **FFI Bridge**: bun:ffi for zero-copy communication

### Double-Buffered Rendering
- Current buffer (on-screen) vs Next buffer (pending changes)
- Cell-by-cell diff to minimize ANSI output
- Run-length encoding of attributes for efficiency

### Intermediate Representation
OpenTUI uses **OptimizedBuffer** as its IR:
- Structure-of-arrays layout (separate arrays for char, fg, bg, attributes)
- Format-agnostic: can be populated from any source
- Renderer-agnostic: can output to ANSI, HTML, or other targets

## What to do with it?

This reference implementation is critical for ansilust because:

1. **IR Pattern**: OpenTUI's `OptimizedBuffer` is an excellent model for ansilust-ir
2. **Renderer Separation**: Demonstrates clean separation between buffer IR and output renderers
3. **ANSI Generation**: Highly optimized ANSI escape sequence generation
4. **Unicode Handling**: Production-grade grapheme cluster and wide character support
5. **Animation Support**: Frame-based rendering with delta-time
6. **Integration Target**: Ansilust should be consumable by OpenTUI programs

## Key Files to Study

### TypeScript Core
- `packages/core/src/renderer.ts` - Main renderer orchestration (1615 lines)
- `packages/core/src/Renderable.ts` - Component tree and Yoga layout (800+ lines)
- `packages/core/src/buffer.ts` - Buffer wrapper with FFI to Zig (349 lines)
- `packages/core/src/text-buffer.ts` - Text buffer wrapper (211 lines)

### Zig Native Layer
- `packages/core/src/zig/renderer.zig` - Diff algorithm and ANSI output (900+ lines)
  - Lines 514-700: `prepareRenderFrame()` - The diff algorithm
  - Lines 571-604: Run-length attribute encoding
- `packages/core/src/zig/buffer.zig` - Cell buffer implementation (1100+ lines)
  - Lines 84-89: Cell structure definition
  - Lines 122-197: Buffer initialization
- `packages/core/src/zig/text-buffer.zig` - Rope-based text storage (1200+ lines)
- `packages/core/src/zig/ansi.zig` - ANSI utilities (190 lines)
- `packages/core/src/zig/grapheme.zig` - Unicode grapheme handling (800+ lines)
- `packages/core/src/zig/terminal.zig` - Capability detection (600+ lines)

### Framework Integrations
- `packages/react/` - React reconciler
- `packages/solid/` - Solid.js reconciler

## Cell Buffer Structure

```typescript
// Each cell stores:
{
  char: u32,         // Unicode codepoint or grapheme ID
  fg: RGBA,          // Foreground color (f32[4])
  bg: RGBA,          // Background color (f32[4])
  attributes: u8     // Bold, italic, underline, etc.
}

// Colors are normalized float RGBA (0.0 to 1.0)
type RGBA = [r: f32, g: f32, b: f32, a: f32]
```

## Critical Insights for Ansilust

### 1. IR Compatibility
OpenTUI's `OptimizedBuffer` format should be compatible with ansilust-ir:
- Both use cell-based grids
- Both need color, character, and attribute data
- Both support Unicode and grapheme clusters

### 2. Data Structure Alignment
```rust
// Ansilust IR should match OpenTUI's cell structure:
struct Cell {
    char: u32,        // Unicode or font index
    fg: Color,        // RGBA or palette index
    bg: Color,
    attributes: u8,   // Bitflags for styling
}
```

### 3. Renderer Pattern
```
Ansilust Parser → Ansilust IR → OpenTUI Buffer → ANSI/HTML Output
     ↓                ↓              ↓
  (BBS Art)      (Universal)   (OptimizedBuffer)
```

### 4. Animation Support
- Frame-based updates (delta-time)
- Double-buffered for flicker-free rendering
- Streaming support for live ANSI animations

## Integration Strategy

For ansilust to work with OpenTUI programs:

1. **Parse BBS art formats** (ANSI, Binary, PCBoard, XBin, etc.) into ansilust-ir
2. **Convert ansilust-ir to OptimizedBuffer** format
3. **Load into OpenTUI renderer** for display
4. **Support animation frames** for ansimation playback

Example flow:
```typescript
// Load BBS art file
const ir = parseAnsiFile("artwork.ans");

// Convert to OpenTUI buffer
const buffer = ansilustToOptimizedBuffer(ir);

// Render in OpenTUI
renderer.setBuffer(buffer);
```

## Building

Requires Bun runtime:

```bash
cd opentui
bun install
bun run build
```

## Integration Notes

When integrating with OpenTUI:
- Use the same cell structure for compatibility
- Convert colors from palette indices to RGBA floats
- Map font glyphs to Unicode codepoints where possible
- Support wide character flags for double-width characters
- Preserve attributes (bold, blink, etc.) in the bitflag format
- Handle grapheme clusters for multi-codepoint characters

## Advanced Features

- **Mouse tracking** - SGR mode, button events, movement
- **Keyboard handling** - Including Kitty keyboard protocol
- **Terminal capabilities** - Detection and adaptation
- **Split-screen mode** - For console capture
- **3D rendering** - WebGPU integration
- **Layout engine** - Yoga-based flexbox layout

This reference is essential for ensuring ansilust-ir can be consumed by modern TUI frameworks without friction.
