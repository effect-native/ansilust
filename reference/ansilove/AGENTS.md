# ansilove Reference

## What is ansilove?

ansilove is a command-line tool (ANSI/ASCII art to PNG converter) that uses libansilove to convert text-based art files into PNG images. It provides a simple CLI interface to the library functionality.

## Contents

The `ansilove/` submodule contains:

- **CLI implementation** (`src/ansilove.c`) - Command-line argument parsing and file handling
- **SAUCE metadata support** (`src/sauce.c`, `src/sauce.h`) - Parser for SAUCE (Standard Architecture for Universal Comment Extensions) metadata
- **Security hardening** (`src/seccomp.h`) - Linux seccomp sandboxing
- **Compatibility layer** (`compat/`) - Cross-platform support (pledge, strtonum)
- **Man page** (`man/ansilove.1`) - User documentation
- **Test files** (`tests/`) - Sample art files for testing
- **Examples** (`examples/`) - Example art files in various formats

## What to do with it?

This reference implementation can be used to:

1. **Understand CLI design** - See how to build a clean command-line interface around a library
2. **Learn argument parsing** - Study how file formats and options are handled
3. **Study SAUCE metadata** - Learn about the SAUCE standard used in text art files
4. **Examine security practices** - See Linux pledge/seccomp sandboxing in action
5. **Reference example files** - Use test files to understand different format characteristics
6. **Build integration patterns** - Learn how to wrap libansilove for different use cases

## Command-Line Interface

Basic usage pattern:
```bash
ansilove [options] <input-file>
```

Key options include:
- Font selection
- Output file specification
- Format-specific rendering options
- Columns/bits configuration for binary files

## Key Files to Study

- `src/ansilove.c` - Main CLI implementation
- `src/sauce.c` - SAUCE metadata parsing
- `src/config.h` - Configuration and constants
- `man/ansilove.1` - Complete documentation
- `tests/` - Example files in various formats
- `CMakeLists.txt` - Build system

## SAUCE Metadata

SAUCE is a metadata standard that stores information about:
- Title, author, group
- Creation date
- File type and data type
- Font information
- Comments

The tool can extract and use this metadata during conversion.

## Building

```bash
cd ansilove
mkdir build && cd build
cmake ..
make
```

## Integration Notes

When building CLI tools or learning from this:
- Clean separation between CLI logic and library calls
- Robust error handling and user feedback
- Security hardening on supported platforms
- Comprehensive man page documentation
- Test files provide format validation
