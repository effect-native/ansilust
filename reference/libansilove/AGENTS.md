# libansilove Reference

## What is libansilove?

libansilove is a C library for converting ANSI, ASCII art, and other text-based art formats into PNG images. It's the core library that powers the ansilove command-line tool.

## Contents

The `libansilove/` submodule contains:

- **Core library** (`src/`) - The main conversion engine
- **Font data** (`src/fonts/`) - Various bitmap fonts used in text art rendering
- **Loaders** (`src/loaders/`) - Format-specific parsers for different art file types
- **Public API** (`include/ansilove.h`) - Header file defining the library interface
- **Man pages** (`man/`) - Documentation for library functions
- **Examples** (`example/`) - Sample code showing how to use the library
- **Compatibility layer** (`compat/`) - Cross-platform compatibility functions

## Supported Formats

- ANSI (.ans) - ANSI art with color codes
- Binary (.bin) - Raw binary text files
- PCBoard (.pcb) - PCBoard BBS format
- Tundra (.tnd) - Tundra Draw format
- ArtWorx (.adf) - ArtWorx Data Format
- iCE Draw (.idf) - iCE Draw format
- XBin (.xb) - Extended Binary format

## What to do with it?

This reference implementation can be used to:

1. **Understand the conversion algorithms** - Study how different text art formats are parsed and rendered
2. **Reference the API design** - See how a clean C library API is structured
3. **Examine font rendering** - Learn about bitmap font rendering techniques
4. **Study format specifications** - Each loader implements a specific format's parsing logic
5. **Build integration** - Reference for linking against libansilove in your own projects

## Key Files to Study

- `include/ansilove.h` - Public API surface
- `src/loaders/ansi.c` - ANSI format parser (most common format)
- `src/drawchar.c` - Character rendering implementation
- `src/fonts/` - Bitmap font data structures
- `CMakeLists.txt` - Build configuration

## Building

```bash
cd libansilove
mkdir build && cd build
cmake ..
make
```

## Integration Notes

When integrating this library or learning from it:
- The library is designed to be simple and focused
- No external dependencies beyond standard C library
- Clean separation between format parsing and rendering
- Font data is embedded directly in the library
