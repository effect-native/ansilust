# ANSI/ASCII Artpack Corpus

This corpus contains artpacks from the sixteencolors-archive, organized by year following the 16colo.rs website structure.

## Contents

- **Year:** 1996
- **Artpacks:** 9 total (3 ACID, 3 iCE, 3 Fire)
- **Files:** 513 total files, 142 ANSI/ASCII art files
- **Size:** 30 MB

## Structure

```
1996/
├── acid-50a.zip          # Original artpack archive
├── acid-50a/             # Extracted files (all files preserved)
│   ├── FILE_ID.DIZ       # Pack description
│   ├── NEWS-50.ANS       # News/info file
│   ├── BS-ROCK1.ANS      # Individual ANSI art files
│   └── ...
├── ice9601a.zip
├── ice9601a/
└── ...
```

Each pack directory contains all original files including executables, documentation, and art files to preserve the historical context.

## Tools

### analyze_archive_sizes.py

Query GitHub API to get file sizes and statistics for any year without downloading:

```bash
./analyze_archive_sizes.py 1996    # Analyze 1996
./analyze_archive_sizes.py 1995    # Analyze 1995
```

## Usage with libansilove

### Fuzzing
```bash
# Fuzz all 1996 artpacks
./fuzz-build/ansi -runs=10000 corpus/1996/

# Fuzz specific pack
./fuzz-build/ansi -runs=10000 corpus/1996/acid-50a/
```

### Testing Individual Files
```bash
# Convert ANSI to PNG
./build/example/ansilove_example corpus/1996/acid-50a/BS-ROCK1.ANS

# Output UTF-8 ANSI to terminal
./build/ansilove-utf8ansi corpus/1996/fire0296/TNT-AE1.ANS
```

### Browse Pack Contents
```bash
# List all packs from 1996
ls corpus/1996/

# List files in specific pack
ls corpus/1996/acid-50a/

# Read pack description
cat corpus/1996/acid-50a/FILE_ID.DIZ
```

## Building Your Own Corpus

See the main [CORPUS_BUILDING.md](../CORPUS_BUILDING.md) for detailed instructions on building your own artpack corpus from the sixteencolors-archive.

Quick start:
1. Use `analyze_archive_sizes.py YEAR` to survey available packs
2. Verify filenames via GitHub API before downloading
3. Download from: `https://github.com/sixteencolors/sixteencolors-archive/raw/master/YEAR/FILENAME.zip`
4. Extract into year-based directories
5. Verify file sizes match API metadata

## Source

All artpacks sourced from: https://github.com/sixteencolors/sixteencolors-archive

## Notes

- **Golden age:** 1995-1996 had peak ANSI art activity (500+ packs per year)
- **iCE format:** Some iCE packs use proprietary .iCE format instead of .ANS
- **Preservation:** All original files kept (not just ANSI) to maintain historical context
