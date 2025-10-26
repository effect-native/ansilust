# PabloDraw Reference Guide

## Overview

**PabloDraw** is a modern, cross-platform ANSI/ASCII text art and RIPscrip vector graphics editor/viewer written in C# (.NET 6+) with multi-user collaborative capabilities. It's a spiritual successor to the legendary DOS-era text art editors, supporting both classic BBS art formats and modern terminal features.

**Repository**: https://github.com/cwensley/pablodraw  
**Language**: C# (.NET 6+)  
**UI Framework**: Eto (cross-platform desktop framework)  
**Key Features**: Multi-format support, animation, networking, collaborative editing

## Architecture Overview

### Project Structure

```
Source/
├── Pablo/                          # Core library (format-agnostic)
│   ├── Formats/                    # Format handlers
│   │   ├── Character/              # ANSI/ASCII text art formats
│   │   ├── Rip/                    # RIPscrip vector graphics
│   │   ├── Image/                  # Bitmap image formats
│   │   ├── Animated/               # Animation support
│   │   └── Pix/                    # PIX format
│   ├── Sauce/                      # SAUCE metadata handling
│   ├── Drawing/                    # Drawing utilities
│   ├── IO/                         # Stream I/O helpers
│   ├── Network/                    # Collaborative networking
│   └── Gallery/                    # Gallery/archive support
├── PabloDraw/                      # Desktop GUI application
├── PabloDraw.Console/              # CLI tool
├── PabloDraw.Android/              # Android mobile app
├── PabloDraw.iOS/                  # iOS mobile app
├── Pablo.Interface/                # Shared UI components
├── Pablo.Mobile/                   # Mobile-specific code
└── TestPablo/                      # Unit tests
```

## Core Data Structures

### Character Representation

**File**: `Source/Pablo/Formats/Character/Character.cs`

```csharp
[StructLayout(LayoutKind.Sequential, Pack = 1)]
public struct Character : INetworkReadWrite
{
    public short character;  // Supports extended Unicode (up to 16-bit)
}
```

- **16-bit character storage** allows both CP437 (DOS) and Unicode
- Implicit conversions to/from `byte` and `int`
- Network-serializable for collaborative editing

### Attribute Structure

**File**: `Source/Pablo/Formats/Character/Attribute.cs`

```csharp
[StructLayout(LayoutKind.Sequential, Pack = 1)]
public struct Attribute
{
    byte foreground;  // 4-bit color + 1-bit bold (high bit)
    byte background;  // 4-bit color + 1-bit blink (high bit)
}
```

**Color Encoding**:
- **Foreground**: 4 bits color (0-7) + 1 bit bold (bit 3)
- **Background**: 4 bits color (0-7) + 1 bit blink (bit 3)
- **iCE Mode**: Converts blink bit to bright background (16 colors)

**Properties**:
- `Foreground` / `Background` - Full 8-bit values
- `ForegroundOnly` / `BackgroundOnly` - 3-bit color only
- `Bold` - High intensity foreground
- `Blink` - Blinking text (or bright background in iCE mode)

### Canvas Element

**File**: `Source/Pablo/Formats/Character/CanvasElement.cs`

Combines character and attribute:
```csharp
public struct CanvasElement
{
    public Character character;
    public Attribute attribute;
}
```

### Canvas Grid

**File**: `Source/Pablo/Formats/Character/Canvas.cs`

Abstract base class for character grid storage:
- `Size` - Canvas dimensions (width × height)
- `Get(x, y)` / `Set(x, y, element)` - Cell access
- `GetElements(rect)` - Batch retrieval
- `Update` event - Notifies on cell changes

**Implementations**:
- `MemoryCanvas` - In-memory grid (standard)
- Custom implementations for streaming/compression

### Bitmap Font System

**File**: `Source/Pablo/Formats/Character/BitFont.cs` & `BitFontSet.cs`

- **BitFont**: Single font (8×16 pixels typical)
  - Character bitmap data (8-bit width, variable height)
  - Supports multiple code pages (CP437, CP850, etc.)
  - Embeddable in XBin/ArtWorx files

- **BitFontSet**: Collection of fonts
  - Loads from `.fnt` files
  - Fallback code page support
  - System vs. custom fonts

**Key Properties**:
- `Width` - Character width (8 or 9 bits)
- `Height` - Character height (typically 16)
- `CharacterData` - Bitmap array for each glyph

## Format Support

### Character Formats (Text Art)

Located in `Source/Pablo/Formats/Character/Types/`

#### ANSI Format (`Ansi.cs`)

**Supported Extensions**: `.ans`, `.diz`, `.mem`, `.cia`, `.drk`, `.ice`, `.tri`, `.tas`, `.tag`, `.lit`, `.vor`, `.uni`, `.vnt`, `.bad`, `.crp`, `.cma`, `.rel`, `.sca`, `.sui`, `.wbl`, `.srg`, `.lgo`, `.vib`, `.sap`, `.pur`, `.nat`, `.jus`, `.itr`, `.imp`, `.ali`, `.grp`, `.fwk`, `.mft`, `.min`, `.nwa`, `.nit`, `.axe`, `.ace`, `.ete`, `.evl`, `.sik`, `.tly`, `.tsd`, `.wkd`, `.---`, `.___.`, `.···`

**Features**:
- VT100/ANSI escape sequences (`ESC[...m`)
- Color codes (30-37 foreground, 40-47 background)
- Bold (code 1), Blink (code 5)
- Ansimation support (animated ANSI)
- SAUCE metadata required for non-standard widths

**Key Methods**:
- `Load()` - Parse ANSI escape sequences
- `Save()` - Generate ANSI output with optimal escape sequences
- `FillSauce()` - Populate SAUCE metadata
- `DetectAnimation()` - Check for animation markers

**Implementation Details**:
- Two-pass rendering: parse to character buffer, then emit ANSI
- Escape sequence optimization (reuse attributes when possible)
- Space compression (consecutive spaces → count)
- iCE color mode support (blink → bright background)

#### ArtWorx Format (`Adf.cs`)

**Extension**: `.adf`

**Features**:
- Embedded bitmap font
- Palette data
- SAUCE metadata
- Binary character/attribute pairs

#### XBin Format (`Xbin.cs`)

**Extension**: `.xb`

**Features**:
- Extended BIN format with embedded fonts
- Palette support (256-color)
- Compression options
- SAUCE metadata

#### Binary Format (`Bin.cs`)

**Extension**: `.bin`

**Features**:
- Raw character/attribute pairs (2 bytes per cell)
- Fixed 160-column width (CGA standard)
- No metadata
- Fastest to load/save

#### PCBoard Format (`Pcb.cs`)

**Extension**: `.pcb`

**Features**:
- Text with embedded color codes (@X## syntax)
- Line-based format
- SAUCE metadata

#### Tundra Format (`Tun.cs`)

**Extension**: `.tun`

**Features**:
- Tundra BBS text format
- Color codes and control sequences

#### iCE Draw Format (`Ice.cs`)

**Extension**: `.ice`

**Features**:
- iCE color mode (16 background colors)
- Similar to ANSI but with extended palette

### RIPscrip Format (Vector Graphics)

**File**: `Source/Pablo/Formats/Rip/FormatRip.cs`

**Extension**: `.rip`

**Features**:
- Vector graphics commands (lines, rectangles, circles, polygons)
- Text rendering with fonts
- Color fills and patterns
- Animation support
- Pixel-based rendering

**Key Components**:
- `RipCommand` - Base class for all RIP commands
- `RipCommandType` - Enum of 100+ command types
- `RipWriter` - Serializes commands to stream
- `RipDocument` - In-memory RIP document
- `BGI` (Borland Graphics Interface) - Rendering engine

**Command Categories**:
- Drawing: line, rectangle, circle, polygon, fill
- Text: text output with font selection
- Palette: color and palette manipulation
- Control: window management, animation timing
- Media: image embedding, sound

### Animated Format

**File**: `Source/Pablo/Formats/Animated/AnimatedFormat.cs`

**Features**:
- Frame-based animation
- Baud rate simulation (playback speed)
- Delta encoding (only changed cells per frame)
- Timing information

**Key Classes**:
- `AnimatedDocument` - Stores animation frames
- `BaudStream` - Simulates modem transmission speed
- `BaudRateMap` - Standard modem speeds (300-56k)

## SAUCE Metadata System

**Files**: `Source/Pablo/Sauce/SauceInfo.cs`, `SauceStream.cs`, `SauceDataTypeInfo.cs`

### SAUCE Structure

128-byte record appended to file (after optional EOF marker 0x1A):

```
Offset  Size  Field
------  ----  -----
0       5     ID ("SAUCE")
5       2     Version ("00")
7       35    Title
42      20    Author
62      20    Group
82      8     Date (YYYYMMDD)
90      4     File Size
94      1     Data Type
95      1     File Type
96      2     TInfo1 (width for text)
98      2     TInfo2 (height for text)
100     2     TInfo3 (font height)
102     2     TInfo4 (aspect ratio)
104     1     Number of Comments
105     1     Flags (iCE, letter spacing, aspect)
106     22    TInfoS (font name, null-terminated)
```

### Data Types

```csharp
public enum SauceDataType
{
    None = 0,
    Character = 1,      // ANSI, ASCII, etc.
    Bitmap = 2,         // Image files
    Vector = 3,         // RIPscrip
    Audio = 4,          // Sound files
    BinaryText = 5,     // Binary text
    XBIN = 6,           // Extended BIN
    Archive = 7,        // Compressed archives
    Executable = 8      // Programs
}
```

### Character File Types

```csharp
public enum CharacterFileType
{
    Ansi = 0,
    Ansimation = 1,
    RIPscrip = 2,
    PCBoard = 3,
    Avatar = 4,
    TundraDraw = 5,
    Binary = 6,
    Xbin = 7,
    ArtWorx = 8,
    IceDraw = 9
}
```

### SAUCE Flags

**Byte Flags**:
- Bit 0: iCE colors enabled (changes blink to bright background)
- Bit 1: Letter spacing (9-bit vs 8-bit character width)
- Bits 2-3: Aspect ratio (1.0, 0.833, 1.35, etc.)
- Bits 4-7: Reserved

### Implementation

**Key Methods**:
- `HasSauce(stream)` - Check if SAUCE exists
- `LoadSauce(stream)` - Parse SAUCE record
- `SaveSauce(stream)` - Write SAUCE record
- `GetSauce(filename)` - Load from file

**Comments Support**:
- Optional comment block (64 bytes each)
- Stored before SAUCE record
- Identified by "COMNT" marker

## Document Model

### Character Document

**File**: `Source/Pablo/Formats/Character/CharacterDocument.cs`

```csharp
public class CharacterDocument : Document
{
    public List<Page> Pages { get; }
    public Palette Palette { get; set; }
    public BitFontSet FontSet { get; set; }
    public bool ICEColours { get; set; }
    public SauceInfo Sauce { get; set; }
}
```

**Properties**:
- `Pages` - Multi-page support
- `Palette` - Color palette (standard DOS or custom)
- `FontSet` - Available fonts
- `ICEColours` - Enable iCE color mode
- `Sauce` - Metadata

### Page

**File**: `Source/Pablo/Formats/Character/Page.cs`

```csharp
public class Page
{
    public Canvas Canvas { get; }
    public Palette Palette { get; set; }
    public BitFontSet FontSet { get; set; }
}
```

- Each page has independent canvas, palette, and fonts
- Supports multi-page documents

### RIP Document

**File**: `Source/Pablo/Formats/Rip/RipDocument.cs`

```csharp
public class RipDocument : Document
{
    public List<RipCommand> Commands { get; }
    public BGI BGI { get; }  // Rendering engine
}
```

## Palette System

**File**: `Source/Pablo/Formats/Character/Palette.cs`

**Standard Palettes**:
- **DOS/VGA**: 16-color standard (0-15)
- **Workbench**: Amiga palette
- **Custom**: User-defined colors

**Color Format**:
- RGB triplets (8-bit each)
- Indexed access (0-255 for extended palettes)

## Undo/Redo System

**File**: `Source/Pablo/Formats/Character/Undo/`

- Command pattern implementation
- `Action` base class for all edits
- Stack-based undo/redo
- Network-serializable for collaborative editing

## Network/Collaborative Features

**Files**: `Source/Pablo/Network/`, `Source/Lidgren.Network/`

**Protocol**:
- Uses Lidgren.Network (UDP-based)
- Command serialization via `INetworkReadWrite`
- Real-time synchronization
- User presence and cursor tracking

**Serializable Types**:
- `Character`, `Attribute`, `CanvasElement`
- `SauceInfo`
- All `Action` commands

## Key Design Patterns

### 1. Format Abstraction

**Base Class**: `CharacterFormat` (extends `AnimatedFormat`)

All text art formats inherit from `CharacterFormat`:
```csharp
public abstract class CharacterFormat : AnimatedFormat
{
    public abstract void Load(Stream fs, CharacterDocument doc, CharacterHandler handler);
    public virtual void Save(Stream stream, CharacterDocument document);
    public virtual void FillSauce(SauceInfo sauce, CharacterDocument document);
}
```

### 2. Handler Pattern

**File**: `Source/Pablo/Formats/Character/CharacterHandler.cs`

Manages document lifecycle:
- Loading/saving
- Undo/redo
- Event dispatching
- UI updates

### 3. Canvas Abstraction

Multiple canvas implementations:
- `MemoryCanvas` - Full in-memory grid
- `StreamCanvas` - Streaming/lazy-load
- Custom implementations for optimization

### 4. Tool System

**File**: `Source/Pablo/Formats/Character/CharacterTool.cs`

Tools for drawing:
- Brush, line, rectangle, ellipse
- Text, fill, block operations
- Extensible architecture

## Integration Points for Ansilust

### 1. SAUCE Metadata

PabloDraw's SAUCE implementation is comprehensive:
- Complete 128-byte record handling
- Comment support
- All data types and file types
- **Recommendation**: Study `SauceInfo.cs` for IR metadata preservation

### 2. Character/Attribute Encoding

PabloDraw uses simple but effective encoding:
- 16-bit character (supports CP437 + Unicode)
- 8-bit attribute (4-bit color + 1-bit flag per nibble)
- **Recommendation**: Consider similar packing for IR cells

### 3. Multi-Format Support

PabloDraw handles 10+ text art formats:
- ANSI, Binary, PCBoard, Tundra, ArtWorx, iCE Draw, XBin
- **Recommendation**: Study format-specific quirks in `Types/` directory

### 4. Animation Support

Ansimation format with baud rate simulation:
- Frame-based delta encoding
- Timing information
- **Recommendation**: Reference `AnimatedFormat.cs` for IR animation support

### 5. Palette Handling

Flexible palette system:
- Standard DOS (16 colors)
- Extended (256 colors)
- Custom palettes
- **Recommendation**: IR should support palette references

## Development Guidelines

### When to Reference PabloDraw

- **Format Parsing**: Study specific format loaders in `Types/` for edge cases
- **SAUCE Handling**: Reference `SauceInfo.cs` for complete metadata support
- **Animation**: Study `AnimatedFormat.cs` for frame-based animation patterns
- **Palette Management**: Reference palette system for color handling
- **Character Encoding**: Study `Character.cs` and `Attribute.cs` for cell structure
- **Multi-Format Architecture**: Study `CharacterFormat` base class design

### Key Files to Study

1. **Core Data Structures**:
   - `Character.cs` - Character representation
   - `Attribute.cs` - Color/style encoding
   - `Canvas.cs` - Grid abstraction

2. **Format Implementations**:
   - `Types/Ansi.cs` - ANSI format (most complete)
   - `Types/Bin.cs` - Binary format (simplest)
   - `Types/Xbin.cs` - Extended features

3. **Metadata**:
   - `Sauce/SauceInfo.cs` - Complete SAUCE handling
   - `Sauce/SauceStream.cs` - Serialization

4. **Document Model**:
   - `CharacterDocument.cs` - Document structure
   - `Page.cs` - Page management
   - `CharacterHandler.cs` - Lifecycle management

5. **Advanced Features**:
   - `Formats/Animated/AnimatedFormat.cs` - Animation
   - `Formats/Rip/FormatRip.cs` - Vector graphics
   - `Network/` - Collaborative editing

## Notable Implementation Details

### 1. ANSI Escape Sequence Optimization

PabloDraw's ANSI saver is sophisticated:
- Tracks attribute state to minimize escape sequences
- Reuses colors when possible
- Handles bold/blink state transitions
- Space compression for efficiency

### 2. iCE Color Mode

Properly implements iCE colors:
- Blink bit becomes bright background (16 colors)
- SAUCE flag controls mode
- Affects rendering and output

### 3. Multi-Page Support

Documents can have multiple pages:
- Each page has independent canvas, palette, fonts
- Useful for complex artwork

### 4. Font Embedding

XBin and ArtWorx formats embed fonts:
- Bitmap font data stored in file
- Supports multiple code pages
- Fallback mechanism for missing fonts

### 5. Network Serialization

All major types implement `INetworkReadWrite`:
- Enables real-time collaborative editing
- Efficient binary protocol
- Extensible for new types

## Limitations & Considerations

1. **No True Color**: Limited to 16-color palette (or 256 with extended formats)
   - PabloDraw doesn't support 24-bit RGB in text art
   - Recommendation: IR should support both palette and RGB

2. **CP437 Focus**: Primarily designed for DOS code page
   - Unicode support exists but secondary
   - Recommendation: IR should prioritize Unicode with CP437 fallback

3. **Fixed Grid**: Canvas is always rectangular grid
   - No support for variable-width characters
   - Recommendation: IR should handle grapheme clusters

4. **No Soft Wrapping**: Hard line breaks only
   - Recommendation: IR should support wrap flags (like Ghostty)

## Comparison with Ansilust IR Requirements

| Feature | PabloDraw | Ansilust IR Need |
|---------|-----------|------------------|
| Character Storage | 16-bit | 21-bit Unicode |
| Attribute Encoding | 8-bit packed | Richer (underline styles, etc.) |
| Color Support | 16-color palette | Palette + 24-bit RGB |
| Animation | Baud-rate based | Frame-based delta |
| Metadata | SAUCE only | SAUCE + extended |
| Multi-page | Yes | Yes |
| Font Embedding | Yes (XBin/ADF) | Yes |
| Network Sync | Yes | Optional |
| Grapheme Clusters | No | Yes (needed) |
| Soft Wrapping | No | Yes (needed) |

## Conclusion

PabloDraw is a mature, well-architected text art editor with:
- **Strengths**: Format support, SAUCE handling, animation, collaborative editing
- **Weaknesses**: Limited color depth, CP437-centric, no modern terminal features

For Ansilust, PabloDraw serves as an excellent reference for:
1. Format-specific parsing quirks
2. SAUCE metadata handling (study before IR metadata decisions)
3. Multi-format architecture patterns
4. Animation frame management
5. Character/attribute encoding strategies

Study PabloDraw's approach to format abstraction and SAUCE handling before finalizing Ansilust's IR design.