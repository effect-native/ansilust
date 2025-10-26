# ANSI/ASCII Art Corpus Building Progress

**Source**: https://github.com/sixteencolors/sixteencolors-archive  
**Date Started**: 2025-10-26  
**Target Groups**: ACID, iCE, Fire

## Objectives
- Download sample artpacks from major ANSI art groups (ACID, iCE, Fire)
- Extract and organize ANSI art files
- Build a test corpus for libansilove fuzzing and validation

## Progress Log

### 2025-10-26

#### Initial Setup
- Created progress tracking file
- Set up todo list for corpus building
- Researched sixteencolors-archive structure (organized by year: 1990-2024)

#### Repository Access
- Attempted full clone - repository too large (timed out)
- Strategy: Download individual artpacks via direct URLs from GitHub

#### Directory Setup
- Created corpus/ directory with subdirectories: acid/, ice/, fire/

#### Testing Download URLs
- HYPOTHESIS: Files named acid0996.zip, acid1096.zip exist in repository
- EXPERIMENT: Attempted to download these files
- RESULT: Downloaded HTML 404 pages instead of ZIP files
- CONCLUSION: These file names don't exist in the archive

#### Discovered Actual File Names (via GitHub API)
**1996 ACID packs:**
- acid-50a.zip, acid-50b.zip, acid-50c.zip
- acid-51a.zip, acid-51b.zip
- acid-52.zip, acid-53a.zip, acid-53b.zip

**1996 iCE packs:**
- ice9601a.zip, ice9601b.zip
- ice9602a.zip, ice9602b.zip
- ice9603a.zip, ice9603b.zip
- ice9604a.zip, ice9604b.zip

**1996 Fire packs:**
- fire0296.zip, fire0396.zip, fire0496.zip
- fire0596.zip, fire0696.zip, fire0796.zip
- fire0896.zip, fire0996.zip, fire1096.zip

#### Actual Downloads
- Downloaded 3 ACID artpacks (3.8M total)
- Downloaded 3 iCE artpacks (3.3M total)
- Downloaded 3 Fire artpacks (4.5M total)

#### Extraction & Organization
- Extracted all 9 artpacks successfully
- Organized 137 ANSI/ASCII files into ansi_files/ directory
- Note: iCE packs appear to use different format (.iCE extension) - only 1 .ans/.asc file found

#### Cleanup Plan
- Keep: ansi_files/ directory (137 organized ANSI files)
- Keep: Original .zip files for reference
- Remove: Extracted directories (acid-*/, ice*/, fire*/) to save space

#### Cleanup Completed
- Removed extracted directories (saved 20MB)
- Final corpus size: 15MB (down from 35MB)
- Kept original .zip files and organized ansi_files/

#### Reorganization Request
- User requested organizing files like 16colo.rs website
- 16colors structure: year/pack-name/files (preserves original pack context)
- Current structure: group/ansi_files/ (loses pack context)

#### Reorganization Implementation
- MISTAKE: Accidentally deleted downloaded artpacks during reorganization
- ACTION: Re-downloading artpacks to rebuild with proper structure

#### Reorganization Completed
- Re-downloaded all 9 artpacks into 1996/ directory
- Extracted each pack into its own subdirectory (e.g., 1996/acid-50a/)
- Structure now matches 16colo.rs: corpus/year/pack-name/files
- All original files preserved (executables, docs, art files)

## Final Status
**SUCCESS**: Corpus organized following 16colo.rs structure with 142 ANSI/ASCII art files from 1996.

### Usage Examples
```bash
# Fuzz with all packs
./fuzz-build/ansi -runs=10000 corpus/1996/

# Fuzz specific pack
./fuzz-build/ansi -runs=10000 corpus/1996/acid-50a/

# Test individual file
./build/example/ansilove_example corpus/1996/acid-50a/BS-ROCK1.ANS

# Browse like 16colors.net
ls corpus/1996/                    # List all packs from 1996
ls corpus/1996/acid-50a/           # List files in acid-50a pack
cat corpus/1996/acid-50a/FILE_ID.DIZ  # Read pack description
```

## Downloaded Artpacks

### ACID (ACiD Productions)
- [x] acid-50a.zip (1.3M)
- [x] acid-51a.zip (1.3M)
- [x] acid-52.zip (1.2M)

### iCE (Insane Creators Enterprise)
- [x] ice9601a.zip (1.1M)
- [x] ice9602a.zip (990K)
- [x] ice9603a.zip (1.2M)

### Fire
- [x] fire0296.zip (875K)
- [x] fire0496.zip (1.4M)
- [x] fire0696.zip (2.2M)

## Directory Structure
Organized to match 16colo.rs website structure:
```
corpus/
└── 1996/               # Year-based organization
    ├── acid-50a.zip    # Original artpack archive
    ├── acid-50a/       # Extracted pack (all files preserved)
    │   ├── FILE_ID.DIZ
    │   ├── NEWS-50.ANS
    │   ├── BS-ROCK1.ANS
    │   └── ... (28 ANSI files, 42 total files)
    ├── acid-51a.zip
    ├── acid-51a/       # (8 ANSI files, 27 total files)
    ├── acid-52.zip
    ├── acid-52/        # (4 ANSI files, 29 total files)
    ├── fire0296.zip
    ├── fire0296/       # (24 ANSI files, 52 total files)
    ├── fire0496.zip
    ├── fire0496/       # (27 ANSI files, 53 total files)
    ├── fire0696.zip
    ├── fire0696/       # (50 ANSI files, 78 total files)
    ├── ice9601a.zip
    ├── ice9601a/       # (1 ANSI file, 71 total files)
    ├── ice9602a.zip
    ├── ice9602a/       # (0 ANSI files, 75 total files)
    ├── ice9603a.zip
    └── ice9603a/       # (0 ANSI files, 86 total files)
```

## Statistics
- Total artpacks: 9 (3 ACID, 3 iCE, 3 Fire)
- Year: 1996
- Total files extracted: 513 files
- Total ANSI/ASCII files: 142 (.ans, .asc)
  - ACID packs (acid-50a, acid-51a, acid-52): 40 ANSI files
  - iCE packs (ice9601a, ice9602a, ice9603a): 1 ANSI file
  - Fire packs (fire0296, fire0496, fire0696): 101 ANSI files
- Disk space: 30 MB
  - Original .zip files: ~12 MB
  - Extracted files: ~18 MB

## File Size Analysis

### Approach
- HYPOTHESIS: GitHub API returns file metadata including size without downloading
- EXPERIMENT: Query GitHub API for file information from 1996 directory
- RESULT: SUCCESS - API returns JSON with "size" field in bytes

### Downloaded Artpack Sizes (Verified via API)
```
Filename              Size (bytes)    Size (MB)
--------------------------------------------------
acid-50a.zip             1,290,421        1.23 MB
acid-51a.zip             1,274,287        1.22 MB
acid-52.zip              1,195,289        1.14 MB
fire0296.zip               895,858        0.85 MB
fire0496.zip             1,442,367        1.38 MB
fire0696.zip             2,209,845        2.11 MB
ice9601a.zip             1,112,585        1.06 MB
ice9602a.zip             1,013,337        0.97 MB
ice9603a.zip             1,255,528        1.20 MB
```

### Full 1996 Archive Statistics (Without Downloading)
- **Total artpacks in 1996:** 753 files
- **Total archive size:** 352.42 MB (369,541,626 bytes)

**By Group:**
| Group | Count | Total Size | Avg Size |
|-------|-------|------------|----------|
| ACID  | 8     | 7.63 MB    | 976.6 KB |
| iCE   | 31    | 28.27 MB   | 933.9 KB |
| Fire  | 12    | 14.51 MB   | 1238.5 KB |
| Other | 702   | 302.01 MB  | 440.5 KB |

**Largest artpacks in 1996:**
- hrg-dark.zip: 3.65 MB
- acdu0396.zip: 3.52 MB
- blde9612.zip: 3.20 MB
- ice-spc6.zip: 2.93 MB
- acdu0696.zip: 2.50 MB

### Archive Size by Year (Sample)
| Year | Files | Total Size |
|------|-------|------------|
| 1990 | 4     | 0.5 MB     |
| 1995 | 581   | 312.9 MB   |
| 1996 | 753   | 352.4 MB   |
| 2000 | 192   | 198.6 MB   |
| 2010 | 4     | 52.4 MB    |
| 2020 | 32    | 310.0 MB   |

**Peak years:** 1995-1996 (golden age of BBS ANSI art scene)

### Verification
- Downloaded file sizes verified against API metadata: ✓ All match
- Method: SHA hash comparison unnecessary - byte-exact size match confirms integrity

### Reusable Analysis Tool
Created `corpus/analyze_archive_sizes.py` - a script that queries GitHub API to get file sizes and statistics for any year without downloading files.

Usage:
```bash
./corpus/analyze_archive_sizes.py 1996  # Analyze 1996
./corpus/analyze_archive_sizes.py 1995  # Analyze 1995
```

This demonstrates the scientific method: gathering data via API queries before taking action (downloading).

## Building Your Own Corpus - Quick Start Guide

To build your own artpack corpus from the sixteencolors-archive:

1. **Research first** - Use the `analyze_archive_sizes.py` script to survey available artpacks by year and group without downloading anything: `./analyze_archive_sizes.py 1995` will show all packs from 1995 with sizes and statistics.

2. **Verify file existence** - Before downloading, query the GitHub API to confirm exact filenames exist: `curl -s "https://api.github.com/repos/sixteencolors/sixteencolors-archive/contents/YEAR" | grep '"name":'` where YEAR is your target year (e.g., 1996).

3. **Download with verified URLs** - Use the raw GitHub URL format: `https://github.com/sixteencolors/sixteencolors-archive/raw/master/YEAR/FILENAME.zip`. Always verify the downloaded file is actually a ZIP (use `file filename.zip`) and not an HTML 404 page before proceeding.

4. **Organize like 16colo.rs** - Create a year-based structure (`corpus/YEAR/`) and extract each pack into its own directory (`corpus/YEAR/packname/`). Keep the original `.zip` files alongside the extracted directories. This preserves the original artpack context (FILE_ID.DIZ, NFO files, etc.) rather than just isolating ANSI files.

5. **Verify integrity** - After downloading, compare file sizes against the GitHub API response to ensure complete downloads: `curl -s "API_URL" | grep '"size":'` and match against your local file size.

**Pro tip:** The golden age of ANSI art was 1994-1997. Start with years 1995-1996 for the highest quality and quantity of artpacks. Use the analysis script to identify the largest/most active groups before downloading.

## Notes
- Focusing on .ANS, .ASC, .NFO files
- Excluding executables, images, and other binary formats
