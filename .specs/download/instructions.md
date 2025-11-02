# 16colors CLI & Download Client - Instructions

## Overview

A specialized command-line tool and library API for the **16colo.rs archive** (and API-compatible mirrors). This provides **two complementary CLI experiences**:

### Dual CLI Design

**`16c` / `16colors` CLI** - Archive-first interface:
- Assumes you're working with the 16colors archive
- Commands implicitly reference the remote archive and local mirror
- Example: `16c art.ans` searches all packs for files named "art.ans" and displays them
- Example: `16c download mist1025` downloads the pack
- Example: `16c list --year 2025` lists 2025 packs

**`ansilust` CLI** - File-first interface:
- Assumes you're working with local files (like `cat`, `grep`, etc.)
- Requires explicit context for archive operations
- Example: `ansilust art.ans` renders local `./art.ans` file
- Example: `ansilust --16colors download mist1025` downloads from archive
- Example: `ansilust --16colors search art.ans` searches archive

**Design Rationale**: 
- `16c` is optimized for browsing/downloading the archive
- `ansilust` is optimized for processing local files (with archive integration available)
- Both share the same underlying library and mirror structure

**Design Focus**: This is explicitly a **16colo.rs-specific client**, not a generic download manager. We will first explore and understand what the 16colo.rs APIs offer (HTTP, FTP, RSYNC) before making implementation decisions. The final solution will likely combine multiple protocols for optimal performance.

**Open Standard**: We define a **community-standard directory structure** for local 16colors mirrors (`~/Pictures/16colors/`). This is **not ansilust-specific** - any tool (PabloDraw, Moebius, ansilove, etc.) can discover and share this standardized artwork repository. We are merely one of many tools that will read and write this format.

## Design Rationale: Why Two CLIs?

### The Context Ambiguity Problem

When a user types a command with a filename, there's ambiguity:
- Does `art.ans` mean `./art.ans` (local file)?
- Does `art.ans` mean "search the 16colors archive for art.ans"?

**Traditional approach** (single CLI with flags):
```bash
ansilust art.ans              # Ambiguous! Local or archive?
ansilust --local art.ans      # Explicit local
ansilust --archive art.ans    # Explicit archive
```
This requires constant mental overhead and flag typing.

### The Dual CLI Solution

**Separate CLIs with clear default context**:
```bash
ansilust art.ans              # Unambiguous: always local (like cat, file, etc.)
16c art.ans                   # Unambiguous: always archive search
```

**Benefits**:
1. **Zero ambiguity**: Command name declares the context
2. **Muscle memory**: Archive users type `16c`, file users type `ansilust`
3. **Scriptability**: Scripts are clearer (`16c download ...` vs `ansilust --16colors download ...`)
4. **Discoverability**: `16c` command is self-documenting (obviously about 16colors)
5. **Unix philosophy**: Each tool does one thing well with clear defaults

**When to use which**:
- **Use `16c`**: When your mental model is "I'm browsing the 16colors archive"
- **Use `ansilust`**: When your mental model is "I'm processing local ANSI files"

**Escape hatches**:
- `ansilust --16colors <cmd>`: Archive operations from the file-processor CLI
- `16c local <file>`: Process local file from the archive CLI (if needed)

### Real-World Analogies

This pattern exists in many successful tools:

| Archive-First CLI | File-First CLI | Shared Backend |
|-------------------|----------------|----------------|
| `16c` | `ansilust` | 16colors library |
| `npm` (package registry) | `node` (local JS files) | Node.js runtime |
| `git` (repository ops) | `diff` (local file diff) | Git plumbing |
| `apt` (package repos) | `dpkg` (local .deb files) | APT library |

Users understand: different CLIs for different mental models, shared infrastructure.

## User Stories

### Archive Browser Persona

**As a** text art collector browsing the 16colors archive  
**I want to** use `16c <filename>` to search and display any artwork  
**So that** I can:
- Quickly find and view artwork without knowing which pack it's in
- Browse the archive like a unified collection
- Download packs on-demand as I discover interesting artwork
- Use a simple, memorable CLI (`16c`) that assumes archive context

**Example**: `16c dragon.ans` finds all files named "dragon.ans" across all 4000+ packs and displays them.

### Local File Processor Persona

**As a** developer processing local ANSI files  
**I want to** use `ansilust <filename>` to work with local files by default  
**So that** I can:
- Process files in my current directory without ambiguity
- Use ansilust like familiar Unix tools (`cat`, `file`, etc.)
- Integrate with shell pipes and scripts naturally
- Explicitly opt-in to archive operations when needed (`--16colors`)

**Example**: `ansilust art.ans` processes `./art.ans`, while `ansilust --16colors art.ans` searches the archive.

### Shared Goals (Both Personas)

- Build a local mirror following the community 16colors standard
- Share the mirror with other tools (PabloDraw, Moebius, etc.)
- Preserve SAUCE metadata and original file formats
- Avoid redundant downloads with smart caching
- Process artwork offline with ansilust parsers

## Core Requirements (EARS Notation)

### FR1.1: Download Management
FR1.1.1: The system shall download complete artpacks from 16colo.rs by pack name.  
FR1.1.2: The system shall download individual artwork files by URL or path identifier.  
FR1.1.3: WHEN a download is requested the system shall check local cache before fetching from remote.  
FR1.1.4: WHEN a download is in progress the system shall display progress information.  
FR1.1.5: IF a download fails THEN the system shall return a descriptive error with retry guidance.

### FR1.2: Protocol Support
FR1.2.1: The system shall support HTTP/HTTPS downloads from 16colo.rs.  
FR1.2.2: The system shall support FTP downloads from ftp://16colo.rs.  
FR1.2.3: WHERE rsync is available the system shall support RSYNC downloads.  
FR1.2.4: The system shall automatically select the optimal protocol based on operation type.  
FR1.2.5: IF a protocol fails THEN the system shall attempt fallback to alternative protocols.

### FR1.3: Storage Management
FR1.3.1: The system shall store artpacks in the community-standard 16colors directory structure.  
FR1.3.2: The system shall store all metadata in `.index.db` (no per-pack JSON files).  
FR1.3.3: The system shall discover existing 16colors directories created by other tools.  
FR1.3.4: The system shall store tool-specific cache in `16colors-tools/ansilust/` subdirectories.  
FR1.3.5: The system shall store artpacks in user-browsable locations (Pictures directory on macOS/Windows).  
FR1.3.6: The system shall create a `local/` directory for user-managed artwork (sideloaded, created, downloaded).  
FR1.3.7: The system shall distinguish between official archive content (`packs/`) and user content (`local/`) in the database.

### FR1.4: Metadata Preservation
FR1.4.1: The system shall preserve original filenames from artpacks.  
FR1.4.2: The system shall extract and store SAUCE metadata in `.index.db`.  
FR1.4.3: The system shall maintain artpack structure (directory hierarchy).  
FR1.4.4: WHEN multiple versions of a file exist the system shall support version tracking in the database.  
FR1.4.5: WHERE JSON configuration files exist they shall include a `$schema` property.  
FR1.4.6: Configuration schemas shall be valid JSON Schema Draft 2020-12.

### FR1.5: Global Archive Database (.index.db)
FR1.5.1: The system shall store the database at `16colors/.index.db` in the 16colors root directory.  
FR1.5.2: The database shall be shared by ALL tools (part of the community standard).  
FR1.5.3: The canonical database shall be distributed from `https://ansilust.com/.well-known/db/.index.db`.  
FR1.5.4: The database shall include all archive metadata (packs, files, artists, groups, SAUCE data).  
FR1.5.5: The database shall store download URLs for both source files and pre-rendered PNGs.  
FR1.5.6: The system shall automatically check for database updates on every `16c` invocation.  
FR1.5.7: WHEN a new database version is available the system shall download it automatically in the background.  
FR1.5.8: The database shall be updated via versioned SQL patch files.  
FR1.5.9: Patch files shall be numbered sequentially (e.g., `0001-add-mist1025.sql`).  
FR1.5.10: Patch files shall be distributed from `https://ansilust.com/.well-known/db/patches/`.  
FR1.5.11: The database shall include both official archive content AND local user content.  
FR1.5.12: The database shall tag entries with source_type ('archive' or 'local').  
FR1.5.13: The database shall support FTS5 full-text search across all artwork metadata.  
FR1.5.14: Users shall be able to search the archive instantly without FTP queries.  
FR1.5.15: The database schema shall be versioned with a `schema_version` table.  
FR1.5.16: WHERE database update fails the system shall continue using cached database.  
FR1.5.17: Auto-updates shall NOT be configurable (opinionated design).

### FR1.6: Discovery and Search
FR1.6.1: The system shall list available artpacks by year, group, or artist.  
FR1.6.2: The system shall query `.index.db` for search operations (no FTP needed).  
FR1.6.3: WHEN browsing packs the system shall display pack metadata (group, date, file count).  
FR1.6.4: The system shall support filtering by file format (ANS, XB, ASC, etc.).  
FR1.6.5: The system shall search both archive and local user content.

### FR1.7: Archive Mirroring
FR1.7.1: The system shall support mirroring the entire 16colors archive.  
FR1.7.2: The system shall support incremental mirror sync (only download new/changed packs).  
FR1.7.3: The system shall support filtering mirrors by year range (e.g., --since 2020).  
FR1.7.4: The system shall exclude NSFW content by default.  
FR1.7.5: The system shall exclude executable files (*.exe, *.com, *.bat) by default.  
FR1.7.6: WHERE the user specifies --include-nsfw the system shall download NSFW content.  
FR1.7.7: WHERE the user specifies --include-executables the system shall download executable files.  
FR1.7.8: The system shall support filtering by file extension (include or exclude specific types).  
FR1.7.9: The system shall support excluding specific groups from mirrors.  
FR1.7.10: The system shall support dry-run mode to preview mirror operations.  
FR1.7.11: WHERE rsync is available the system shall support bandwidth limiting.  
FR1.7.12: The system shall persist mirror configuration for subsequent sync operations.  
FR1.7.13: The system shall support pruning orphaned packs (removed from remote).

### FR1.8: CLI Interface
FR1.8.1: The system shall provide a `16c` (or `16colors`) CLI for archive-first operations.  
FR1.8.2: The system shall provide archive integration in the `ansilust` CLI via `--16colors` flag.  
FR1.8.3: The `16c` CLI shall assume archive context for all commands.  
FR1.8.4: The `ansilust` CLI shall assume local file context unless `--16colors` is specified.  
FR1.8.5: Both CLIs shall share the same underlying library implementation.

### FR1.9: Library Integration
FR1.9.1: The system shall provide a Zig library API for programmatic access.  
FR1.9.2: The library shall integrate with ansilust parsers for format validation.  
FR1.9.3: WHEN files are downloaded the library shall emit events for integration hooks.  
FR1.9.4: The library shall be usable independently of the CLI tools.

## Technical Specifications

### 16colo.rs API Research

Before implementation, we must thoroughly understand the available APIs:

#### HTTP/HTTPS API (https://16colo.rs)
**Discovered Endpoints**:
- **Pack download**: `/archive/YYYY/packname.zip` (e.g., `/archive/2025/mist1025.zip`)
  - Returns: application/zip
  - Supports: Range requests (resumable downloads)
  - Headers: ETag, Last-Modified, Accept-Ranges
- **Individual files**: `/pack/packname/filename.ext` (e.g., `/pack/mist1025/CXC-STICK.ASC`)
- **Pack listing**: `/year/YYYY/` (HTML, requires scraping)
- **Artist listing**: `/artist/artistname/` (HTML, requires scraping)
- **Group listing**: `/group/groupname/` (HTML, requires scraping)
- **Search interface**: `/search/` (HTML form, no API discovered yet)
- **RSS feed**: `/rss/` (XML, latest releases)

**Questions to Explore**:
- [ ] Is there a JSON/XML API for pack listings?
- [ ] Does the search support query parameters?
- [ ] Are there rate limits documented?
- [ ] Is there a manifest/checksum file for packs?

#### FTP API (ftp://16colo.rs)
**Discovered Structure**:
```
ftp://16colo.rs/
├── archive/              # Compressed artpacks (.zip files)
│   ├── 1990/            # 7 packs
│   ├── 1993/            # 244 packs
│   ├── 1996/            # 836 packs (peak year)
│   ├── 2025/            # 27 packs (current)
│   │   ├── mist1025.zip (5.2 MB)
│   │   └── ...
│   └── ...
├── pack/                 # Extracted artpacks (directory per pack)
│   ├── 1990/            # 7 directories
│   ├── 1996/            # 836 directories
│   ├── 2025/            # Current year
│   │   ├── mist1025/    # Individual files
│   │   │   ├── CXC-STICK.ASC
│   │   │   ├── MIST1025.NFO.ANS
│   │   │   └── ...
│   │   └── ...
│   └── ...
├── archive-mag/          # E-magazine archives
└── mag/                  # Extracted e-magazines
```

**FTP Advantages**:
- Direct directory listing (no HTML scraping)
- Efficient for bulk operations
- Standard protocol, widely supported
- File metadata (size, mtime) available

**Questions to Explore**:
- [ ] FTP performance vs HTTP for large downloads?
- [ ] Are FTP listings faster than scraping HTML?
- [ ] Does FTP support resume?

#### RSYNC API (rsync://16colo.rs)
**Status**: Mentioned in FAQ but not yet explored (rsync not installed locally)

**Questions to Explore**:
- [ ] What rsync modules are available?
- [ ] Is rsync faster for mirroring operations?
- [ ] Does rsync provide checksums/verification?
- [ ] Is rsync the best choice for bulk corpus building?

### Protocol Selection Strategy

Different operations may benefit from different protocols:

| Operation | Recommended Protocol | Rationale |
|-----------|---------------------|-----------|
| Single pack download | **HTTP** | Resume support, progress tracking |
| Individual file download | **HTTP** | Direct URL access |
| Pack listing (year/artist/group) | **FTP** | Avoid HTML scraping |
| Full archive mirroring | **RSYNC** (preferred) | Incremental sync, checksums, bandwidth control |
| Full archive mirroring (fallback) | **FTP** | Batch downloads, directory listings |
| Filtered mirroring | **HTTP + FTP** | Need metadata for filtering |
| Search | **HTTP** | Web scraping or RSS feed |
| Discovery (new packs) | **RSS** over HTTP | Structured feed |

**Implementation Approach**:
1. **Phase 1**: Implement HTTP client (most versatile)
2. **Phase 2**: Add FTP for efficient listing
3. **Phase 3**: Explore RSYNC for bulk operations
4. **Phase 4**: Combine protocols for optimal UX

### Storage Architecture - Open Standard for 16colors Artwork

**Design Philosophy**: This storage layout is an **open community standard** for local 16colors mirrors, not an ansilust-specific format. Multiple tools should be able to discover and share this data. We store artwork in user-friendly locations with predictable structure.

Platform-specific storage following OS conventions:

**Linux** (XDG Base Directory Specification):
- **Artpacks**: `~/.local/share/16colors/packs/`
- **Corpus**: `~/.local/share/16colors/corpus/`
- **Tool Cache**: `~/.cache/16colors-tools/<toolname>/`
- **Tool Config**: `~/.config/16colors-tools/<toolname>/`

**macOS** (Standard Application Support):
- **Artpacks**: `~/Pictures/16colors/` (user-browsable artwork)
- **Corpus**: `~/Pictures/16colors/Corpus/`
- **Tool Cache**: `~/Library/Caches/16colors-tools/<toolname>/`
- **Tool Config**: `~/Library/Application Support/16colors-tools/<toolname>/`

**Windows**:
- **Artpacks**: `%USERPROFILE%\Pictures\16colors\` (user-browsable artwork)
- **Corpus**: `%USERPROFILE%\Pictures\16colors\Corpus\`
- **Tool Cache**: `%LOCALAPPDATA%\16colors-tools\<toolname>\Cache\`
- **Tool Config**: `%APPDATA%\16colors-tools\<toolname>\`

**Standard Directory Structure** (shown with Linux paths, adapt per platform):
```
~/.local/share/16colors/           (or ~/Pictures/16colors/ on macOS/Windows)
├── .index.db                      # Global archive database (ALL tools share this!)
├── packs/                         # Official 16colo.rs artpack archive
│   ├── 1990/
│   ├── 1996/
│   ├── 2025/
│   │   ├── mist1025.zip           # Original artpack (preserved)
│   │   └── mist1025/              # Extracted contents
│   │       ├── FILE_ID.DIZ        # Original pack files
│   │       ├── MIST1025.NFO.ANS
│   │       └── [artwork files]
│   │   └── ...
├── local/                         # User's own artwork (sideloaded, created, etc.)
│   ├── my-art/                    # User-created artwork
│   │   ├── dragon.ans
│   │   └── logo.xb
│   ├── downloads/                 # Manually downloaded files
│   │   └── random-art.ans
│   ├── screenshots/               # BBS screenshots, etc.
│   └── ...
├── collections/                   # Curated collections for research
│   ├── ansi-1990s/                # User-organized collections
│   ├── ice-colors-examples/
│   └── ...
└── .16colors-config.json          # Global configuration (optional)

~/.cache/16colors-tools/ansilust/  (tool-specific cache, not shared)
├── download-queue.json
└── http-cache/
```

**Shared Database** (`.index.db`):
- **Location**: `~/Pictures/16colors/.index.db` (or platform equivalent)
- **Shared by ALL tools**: ansilust, 16c-screensaver, hypothetical PabloDraw plugin, etc.
- **Contains**: Global 16colo.rs archive metadata + local user artwork index
- **Auto-updated**: Any tool can update it (first-write-wins with version check)
- **Read-only for most tools**: Screensaver reads, download client writes

**Why `.index.db` in 16colors root**:
- Predictable location for all tools
- Part of the community standard
- No tool-specific cache paths needed for search
- Screensaver can instantly query for random artwork
- Single source of truth for all 16colors data

**Directory Purposes**:
- **`packs/`**: Official 16colo.rs archive (managed by download client)
- **`local/`**: User's own artwork (not from 16colo.rs, manually managed)
- **`corpus/`**: Curated collections (can contain symlinks to packs/ or local/)

**Use Cases for `local/`**:
- User creates artwork in PabloDraw/Moebius and saves to `local/my-art/`
- User downloads artwork from BBS, web, Discord and saves to `local/downloads/`
- **Screensaver** (`16c-screensaver`) displays from both `packs/` and `local/` directories
- **TUI viewers** can browse all artwork in one unified location
- **Search tools** index both `packs/` and `local/` for complete coverage
- **BBS software** can serve artwork from both official archive and user content
- **SQLite database** includes entries from both directories with source tagging

**Why `local/` is Part of the Standard**:
- Other tools (screensavers, viewers, BBSes) need a predictable location for user artwork
- Users should have one central place for all text art (archive + their own)
- Separating `local/` from `packs/` prevents conflicts with official archive
- Database can distinguish archive vs user content while providing unified search

**Database as Single Source of Truth**:
- **No per-pack JSON files**: `.index.db` contains all metadata
- **Simpler**: Fewer files, single source of truth
- **Faster**: No JSON parsing, direct SQL queries
- **Smaller**: No redundant metadata files in every pack directory
- **Consistent**: All tools query same database, no sync issues

**Mirror Configuration Format** (`.16colors-mirror-config.json`):
```json
{
  "$schema": "https://ansilust.com/.well-known/schemas/16colors-mirror-config-v1.json",
  "mirror_mode": "filtered",
  "last_sync": "2025-11-01T23:30:00Z",
  "defaults": {
    "exclude_nsfw": true,
    "exclude_executables": true
  },
  "filters": {
    "year_range": {
      "since": 2020,
      "until": null
    },
    "include_nsfw": false,
    "include_executables": false,
    "exclude_extensions": ["png", "gif"],
    "include_extensions": null,
    "exclude_groups": ["acdu"],
    "include_groups": null
  },
  "sync_stats": {
    "total_packs": 127,
    "total_size_bytes": 524288000,
    "last_duration_seconds": 1834,
    "nsfw_excluded_count": 23,
    "executables_excluded_count": 47
  }
}
```

**Schema URL**: `https://ansilust.com/.well-known/schemas/16colors-mirror-config-v1.json`

**JSON Schema for Configuration** (`.16colors-config.json` only):

The `.16colors-config.json` file (if present) uses:
- **Schema URL**: `https://ansilust.com/.well-known/schemas/16colors-mirror-config-v1.json`
- **Purpose**: Mirror sync configuration (filters, preferences)
- **Optional**: Only created when users configure mirror filters

**No per-pack metadata files**: 
- Database (`.index.db`) is the single source of truth
- No `.16colors-meta.json` files in pack directories
- Simpler, faster, less redundant

**Rationale**: 
- **Single source of truth**: `.index.db` contains all metadata, no redundant JSON files
- **Shared standard**: Any tool can discover `~/Pictures/16colors/` and `.index.db`
- **User-browsable**: Artists and enthusiasts can manually explore their collection
- **Tool-agnostic**: Database format is tool-independent
- **Tool-specific cache**: Each tool manages its own cache under `16colors-tools/<toolname>/`
- **Predictable paths**: Scripts and automation can rely on consistent structure
- **Multi-tool friendly**: PabloDraw, Moebius, ansilove, ansilust all query `.index.db`
- **Persistent filters**: Mirror sync configuration survives across invocations

### Network Protocol Requirements

#### HTTP/HTTPS
- **User-Agent**: `ansilust/VERSION (https://github.com/user/ansilust)`
- **Resume support**: Send `Range: bytes=X-` header
- **Compression**: Accept `gzip, deflate`
- **Conditional requests**: Use `If-Modified-Since`, `If-None-Match` (ETag)
- **Rate limiting**: Configurable delay between requests (default: 500ms)
- **Timeout**: Configurable (default: 30s for metadata, 300s for downloads)

#### FTP
- **Mode**: Passive (PASV) for firewall compatibility
- **Resume support**: REST command
- **Listing format**: Parse Unix-style `ls -l` output
- **Connection pooling**: Reuse connections for multiple operations

#### RSYNC (Future)
- **Checksum algorithm**: Investigate what 16colo.rs supports
- **Bandwidth limiting**: Configurable (default: no limit)
- **Incremental**: Only transfer changed files

### File Format Support

**Included by default**:
- **Archives**: ZIP (primary format used by 16colo.rs)
- **Text Art**: ANS, ASC, XB, ICE, BIN, PCB, TND, ADF, IDF, RIP, LIT, DRK
- **Metadata**: SAUCE records, DIZ, NFO, TXT (info files)
- **Images**: PNG, GIF (rendered previews)

**Excluded by default** (require explicit flags):
- **Executables**: EXE, COM, BAT (require `--include-executables`)
- **NSFW Content**: Tagged NSFW (require `--include-nsfw`)

**Rationale**: 
- **Security**: Executables from 1990s BBSs pose potential security risks
- **Safety**: NSFW content excluded by default for public/institutional use
- **Explicit opt-in**: Users must consciously choose to include potentially problematic content

## CLI Usage Examples

### `16c` CLI - Archive-First Interface

**Download operations**:
```bash
# Download a pack by name (auto-detects year)
16c download mist1025

# Download multiple packs
16c download mist1025 fire-43 impure90

# Download all packs from a year
16c download --year 2025

# Download all packs from a group
16c download --group mistigris

# Mirror the entire archive (full local copy)
16c mirror sync                           # Sync entire archive (excludes NSFW & executables by default)
16c mirror sync --year 2025               # Sync only 2025
16c mirror sync --since 2020              # Sync 2020-present

# Include content excluded by default
16c mirror sync --include-nsfw            # Include NSFW content
16c mirror sync --include-executables     # Include .exe, .com, .bat files
16c mirror sync --include-all             # Include everything (NSFW + executables)

# Additional filters (on top of defaults)
16c mirror sync --exclude-ext png,gif     # Also exclude image types
16c mirror sync --only-ext ans,asc,xb     # Only specific types (overrides defaults)
16c mirror sync --exclude-group acdu      # Exclude specific groups

# Mirror options
16c mirror sync --dry-run                 # Preview what would be downloaded
16c mirror sync --bandwidth 1M            # Limit bandwidth (rsync)
16c mirror sync --force                   # Re-download everything
```

**Search and discovery** (SQLite-powered):
```bash
# Search for files by name across the entire archive
16c art.ans                    # Find all files named "art.ans" and display them
16c search "dragon"            # Full-text search across all artwork (uses FTS5)
16c search --artist cthulu     # Search by artist (database query)
16c search --artist cthulu --year 1996  # Complex queries from database

# List packs (fast database queries)
16c list --year 2025           # List 2025 packs
16c list --group mistigris     # List mistigris packs
16c list --new                 # Show new packs (from RSS)
16c list --artist misfit       # All packs with artwork by artist

# Statistics and analytics (from SQLite database)
16c stats --artist cthulu      # Artist statistics (file count, years active, groups)
16c stats --group mistigris    # Group statistics (pack count, active years)
16c stats --year 1996          # Year statistics (groups, artists, formats)
16c stats --format ans         # Format statistics (count by year, top artists)
```

**Display operations**:
```bash
# Display file from archive (searches and renders)
16c mist1025/CXC-STICK.ASC              # Display specific file
16c show mist1025/CXC-STICK.ASC         # Explicit show command
16c show mist1025/CXC-STICK.ASC --raw   # Show raw ANSI (no rendering)
```

**Mirror management**:
```bash
# Show local mirror status
16c mirror                     # Show mirror path and stats
16c mirror list                # List all cached packs
16c mirror verify              # Verify integrity
16c mirror path                # Print mirror directory path
16c mirror stats               # Detailed statistics (size, count, by year/group)
16c mirror prune               # Remove packs not on remote (clean orphans)
16c mirror config              # Show mirror configuration (filters, exclusions)

# Local artwork management (user's own content)
16c local add myart.ans        # Add file to local/ directory
16c local list                 # List all files in local/ directory
16c local import ~/Downloads/art/  # Import directory to local/
16c local path                 # Print local/ directory path

# Global archive database operations (auto-updates on every invocation!)
16c db version                 # Show current database version
16c db info                    # Database info (last update, size, pack count)
16c db query "SELECT ..."      # Direct SQL queries (read-only on global DB)
16c db export artists.csv      # Export global database tables to CSV
16c db stats                   # Database statistics (version, size, table counts)

# Manual operations (rarely needed, auto-updates by default)
16c db update --now            # Force immediate update (bypass throttle)

# Local mirror database operations
16c mirror rebuild             # Rebuild .index.db from downloaded packs and local content
16c mirror verify              # Verify local files match global database
```

### `ansilust` CLI - File-First Interface

**Local file operations** (default behavior):
```bash
# Process local files (current directory)
ansilust art.ans               # Render ./art.ans (like cat)
ansilust parse art.ans         # Parse and show IR
ansilust validate art.ans      # Validate format

# Explicit local paths
ansilust ./art.ans
ansilust /path/to/art.ans
```

**Archive operations** (via `--16colors` flag):
```bash
# Download from archive
ansilust --16colors download mist1025

# Search archive
ansilust --16colors search "dragon"

# Render file from archive
ansilust --16colors mist1025/CXC-STICK.ASC

# List archive contents
ansilust --16colors list --year 2025
```

**Combined workflows**:
```bash
# Download and immediately process
ansilust --16colors download mist1025 && ansilust ~/Pictures/16colors/packs/2025/mist1025/*.ANS

# Search archive, download matches, then process
ansilust --16colors search "dragon" | ansilust --16colors download --from-search | xargs ansilust parse
```

## Acceptance Criteria (EARS Patterns)

### AC1: Basic Pack Download (HTTP) - Both CLIs
- WHEN the user requests `16c download mist1025` the system shall download from `/archive/2025/mist1025.zip`
- WHEN the user requests `ansilust --16colors download mist1025` the system shall perform the same operation
- The system shall extract files to 16colors mirror directory preserving structure
- The system shall display download progress (bytes, percentage, speed, ETA)
- IF the pack is already in mirror THEN the system shall skip download unless --force is specified
- The system shall verify ZIP integrity after download

### AC2: Automatic Database Updates
- WHEN the user runs any `16c` command the system shall check for database updates
- The update check shall be throttled (max once per hour)
- The update check shall use a lightweight HEAD/metadata request (< 1KB)
- WHEN a new version is available the system shall download it in the background
- The system shall use the cached database immediately (non-blocking update)
- IF the database does not exist the system shall download it on first run
- IF update fails the system shall continue with cached database and log the error
- The system shall NOT prompt users for update consent on every run

### AC3: File Search and Display (`16c` CLI)
- WHEN the user requests `16c art.ans` the system shall search `16colors.db` for files named "art.ans"
- The search shall be instant (no FTP queries, no filesystem scanning)
- The system shall display matches with pack/year/artist context and download URLs
- The system shall download missing files on-demand
- The system shall render all matching files using ansilust renderers
- IF multiple matches exist THEN the system shall display them sequentially or prompt for selection

### AC4: Local File Processing (`ansilust` CLI)
- WHEN the user requests `ansilust art.ans` the system shall process `./art.ans` as a local file
- The system shall NOT search the archive unless `--16colors` is specified
- IF the file does not exist locally THEN the system shall return error.FileNotFound
- The behavior shall be consistent with Unix tools like `cat`, `file`, etc.

### AC5: Pack Listing (FTP) - Both CLIs
- The system shall support `16c list --year 2025` using FTP directory listing
- The system shall support `ansilust --16colors list --year 2025` with identical behavior
- The output shall show pack names, sizes, and modification dates
- The system shall indicate which packs are already in the local 16colors mirror
- The listing operation shall complete in < 5 seconds for a single year

### AC6: Resume Support (HTTP)
- WHEN a download is interrupted the system shall resume from last position
- The system shall use Range requests for resume
- IF resume fails THEN the system shall restart from beginning

### AC7: Mirror Operations - Both CLIs
- The system shall support `16c mirror` to show local 16colors mirror status
- The system shall support `16c mirror list` to show mirror contents
- The system shall support `16c mirror verify` to check file integrity against metadata
- The system shall support `16c mirror path` to display the 16colors directory location
- The `ansilust --16colors mirror` commands shall have identical behavior
- The system shall report mirror size and statistics on demand

### AC8: Discovery via RSS - Both CLIs
- The system shall parse https://16colo.rs/rss/ for new releases
- The system shall support `16c list --new` to show packs not yet in local mirror
- The system shall support `ansilust --16colors list --new` with identical behavior
- The system shall display pack metadata from RSS (title, date, description)

### AC9: CLI Naming and Aliases
- The primary archive CLI shall be named `16c`
- The system shall support `16colors` as an alias to `16c`
- The system shall support `16` as a short alias to `16c`
- All three names shall invoke identical functionality
- The `ansilust` CLI shall remain the primary file-processing tool

### AC10: Full Archive Mirroring with Safe Defaults
- WHEN the user requests `16c mirror sync` the system shall download the entire 16colors archive
- The system shall exclude NSFW content by default (unless `--include-nsfw` specified)
- The system shall exclude executable files (*.exe, *.com, *.bat) by default (unless `--include-executables` specified)
- The system shall use the optimal protocol (RSYNC > FTP > HTTP) based on availability
- The system shall display progress for the overall mirror operation (packs downloaded, total size, ETA)
- The system shall show how many files were excluded due to default filters
- WHEN sync is run again the system shall only download new or changed packs (incremental)
- The system shall skip already-mirrored packs unless --force is specified

### AC11: Explicit Inclusion of Filtered Content
- WHEN the user requests `16c mirror sync --include-nsfw` the system shall download NSFW-tagged content
- WHEN the user requests `16c mirror sync --include-executables` the system shall download executable files
- WHEN the user requests `16c mirror sync --include-all` the system shall include both NSFW and executables
- The system shall warn users when including NSFW or executables
- The system shall track included content in mirror statistics

### AC12: Additional Filtering
- WHEN the user requests `16c mirror sync --since 2020` the system shall only download packs from 2020 onwards
- WHEN the user requests `16c mirror sync --exclude-ext png,gif` the system shall also exclude those extensions (in addition to defaults)
- WHEN the user requests `16c mirror sync --only-ext ans,asc,xb` the system shall only download those extensions (overrides defaults)
- The system shall persist filter configuration in `.16colors-mirror-config.json`
- WHEN sync is run without filters the system shall use previously configured filters
- The system shall always apply default exclusions unless explicitly overridden

### AC13: Mirror Management
- WHEN the user requests `16c mirror sync --dry-run` the system shall display what would be downloaded without downloading
- The dry-run output shall show total size, pack count, and excluded content counts
- The dry-run output shall indicate which defaults are active (NSFW excluded, executables excluded)
- WHEN the user requests `16c mirror prune` the system shall remove local packs that no longer exist on remote
- The system shall support `16c mirror stats` to show breakdown by year, group, file type
- The mirror stats shall include excluded content statistics (NSFW count, executable count)
- The mirror stats shall include total size, pack count, file count, and oldest/newest packs
- The mirror stats shall show both archive and local content separately

### AC14: Local Artwork Management
- The system shall create a `local/` directory within the 16colors directory on first run
- WHEN the user requests `16c local add myart.ans` the system shall copy the file to the `local/` directory
- WHEN the user requests `16c local import ~/Downloads/art/` the system shall recursively copy the directory to `local/`
- The system shall support `16c local list` to show all files in the `local/` directory
- The SQLite database shall index files from both `packs/` and `local/` directories
- Search and display operations shall include results from `local/` by default
- The database shall tag entries with source_type='local' for user-managed content
- Statistics shall distinguish between archive and local content

## Out of Scope

- **Generic download manager**: This is 16colo.rs-specific only
- **Upload functionality**: Publishing to 16colo.rs (separate feature)
- **Web interface**: Browser-based download manager (CLI only for now)
- **Format conversion**: Rendering/conversion (handled by existing parsers/renderers)
- **Social features**: Comments, ratings, favorites (use 16colo.rs website)
- **Automatic updates**: Background sync daemon (manual refresh only, use cron/systemd for automation)
- **Search implementation**: Full-text search (defer to 16colo.rs website for now)
- **Content filtering logic**: NSFW detection (rely on 16colo.rs tags/metadata)
- **Deduplication**: Handling duplicate files across packs (future enhancement)
- **Schema hosting infrastructure**: Initial implementation will assume schemas exist (separate deployment concern)

## Success Metrics

### CLI Usability
- **SM1**: Archive users can find and display any artwork with `16c <filename>` without knowing the pack
- **SM2**: File users can process local files with `ansilust <filename>` without ambiguity
- **SM3**: Both CLIs feel natural for their respective use cases (archive-first vs file-first)
- **SM4**: The `16c` CLI name is memorable and clearly associated with 16colors
- **SM5**: Archive operations in `ansilust` via `--16colors` flag are discoverable and intuitive

### Download & Storage
- **SM6**: Users can download any artpack from 16colo.rs with a single command
- **SM7**: Downloaded files follow the community 16colors standard with no unnecessary re-downloads
- **SM8**: Storage follows platform conventions and artpacks are easily discoverable by users and other tools
- **SM9**: Network usage is reasonable (progress display, resumable downloads, rate limiting)

### Mirroring
- **SM10**: Users can mirror the entire 16colors archive with `16c mirror sync`
- **SM11**: Incremental sync only downloads new/changed packs (efficient bandwidth usage)
- **SM12**: Users can easily filter mirrors by year, group, content type, or file format
- **SM13**: Mirror configuration persists across sync operations (no need to re-specify filters)
- **SM14**: Dry-run mode provides accurate preview of mirror operations before download

### Database & Search
- **SM15**: Users can search the entire archive instantly without FTP queries (`16colors.db`)
- **SM16**: Global database includes download URLs for both source files and pre-rendered PNGs
- **SM17**: Database updates automatically on every `16c` invocation (zero-friction, no manual updates)
- **SM18**: Update checks are lightweight and throttled (< 1KB, max once per hour)
- **SM19**: Database updates are non-blocking (use cached DB while updating in background)
- **SM20**: Database updates use incremental patches when possible (efficient bandwidth)
- **SM21**: Local mirror database tracks what's downloaded without duplicating archive metadata

### Integration & Interoperability
- **SM22**: Integration with ansilust parsers is seamless (files ready for processing)
- **SM23**: The 16colors directory standard enables interoperability between multiple tools
- **SM24**: Error handling is clear and actionable (network issues, missing packs, etc.)
- **SM25**: Protocol selection is transparent and optimal for each operation type

## Future Considerations

### Protocol Research Tasks
Before Phase 2 (Requirements), we should:
- [ ] Investigate 16colo.rs JSON/XML API (if it exists)
- [ ] Test RSYNC performance and features
- [ ] Measure HTTP vs FTP performance for common operations
- [ ] Check if search supports query parameters
- [ ] Document rate limits and acceptable use
- [ ] Investigate checksum/manifest availability

### Global Database (16colors.db) Tasks
Before implementation, we should:
- [ ] Design initial schema for `16colors.db`
- [ ] Create tooling to generate database from 16colo.rs FTP listings
- [ ] Establish patch file numbering and format conventions
- [ ] Set up hosting for `16colors.db` and patch files at ansilust.com
- [ ] Determine update frequency (daily? weekly?)
- [ ] Create SQL migration tooling
- [ ] Document schema versioning strategy

### Phase 2 Enhancements
- **Corpus building**: Automated download of curated sets for research (stored in `corpus/`)
- **Watch mode**: Monitor RSS feed for new releases and auto-download to mirror
- **Collection management**: User-defined collections with metadata
- **Mirror failover**: Automatic fallback to FTP/RSYNC if HTTP fails
- **Parallel downloads**: Concurrent pack downloads with connection pooling
- **Checksum verification**: SHA256 validation against published manifests
- **Smart filtering**: NSFW detection beyond tags (analyze SAUCE/content)
- **Deduplication**: Handle duplicate files across packs
- **Incremental extraction**: Only extract changed files within updated packs
- **16colors standard v1.0**: Formalize and document the directory standard for community adoption

### Dual Database Architecture

#### Global Archive Database (`16colors.db`)
Canonical, version-controlled database of the entire 16colo.rs archive:

**Distribution**:
- Downloadable from: `https://ansilust.com/.well-known/db/16colors.db`
- Updated regularly with new packs
- Versioned with semantic versioning (e.g., `16colors-v1.2.3.db`)
- Patch files: `https://ansilust.com/.well-known/db/patches/0001-add-mist1025.sql`

**Schema** (`16colors.db`):
```sql
CREATE TABLE schema_version (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);

CREATE TABLE packs (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  year INTEGER NOT NULL,
  group_name TEXT,
  release_date TEXT,
  file_count INTEGER,
  total_size INTEGER,
  nsfw BOOLEAN DEFAULT 0,
  -- Download URLs
  zip_url TEXT NOT NULL,  -- e.g., https://16colo.rs/archive/2025/mist1025.zip
  web_url TEXT NOT NULL   -- e.g., https://16colo.rs/pack/mist1025/
);

CREATE TABLE files (
  id INTEGER PRIMARY KEY,
  pack_id INTEGER REFERENCES packs(id),
  relative_path TEXT NOT NULL,
  filename TEXT NOT NULL,
  extension TEXT,
  size INTEGER,
  artist TEXT,
  title TEXT,
  sauce_data JSON,
  -- Download URLs
  source_url TEXT NOT NULL,  -- https://16colo.rs/pack/mist1025/art.ans
  png_url TEXT,              -- https://16colo.rs/pack/mist1025/tn/art.ans.png (thumbnail)
  png_url_x1 TEXT,           -- x1 size PNG
  png_url_x2 TEXT            -- x2 size PNG
);

CREATE VIRTUAL TABLE files_fts USING fts5(filename, artist, title);

CREATE TABLE groups (
  name TEXT PRIMARY KEY,
  pack_count INTEGER,
  first_pack_year INTEGER,
  last_pack_year INTEGER
);

CREATE TABLE artists (
  name TEXT PRIMARY KEY,
  file_count INTEGER,
  first_seen_year INTEGER,
  last_seen_year INTEGER,
  groups TEXT  -- JSON array
);
```

**Database Size Optimization**:

Estimated size for ~4000 packs with ~100,000 files:
- Packs table: ~4000 rows × ~200 bytes = ~800KB
- Files table: ~100,000 rows × ~300 bytes = ~30MB
- FTS5 index: ~10-20MB (filename/artist/title only, not full content)
- Groups/Artists: ~1MB
- **Total estimate**: ~40-50MB (acceptable for auto-download)

**What we DON'T store** (to avoid bloat):
- ❌ Full file content (only metadata)
- ❌ Binary data (images, executables)
- ❌ Rendered PNG data (only URLs)
- ❌ Duplicate SAUCE fields (normalize to JSON)
- ❌ Redundant URL patterns (use base URL + template)

**What we DO store** (essential for search):
- ✅ Filename, artist, title (FTS5 indexed)
- ✅ SAUCE metadata (JSON, for filtering)
- ✅ Download URLs (source + PNG variants)
- ✅ Pack/group/year relationships
- ✅ File extensions and sizes (for statistics)

**Size Monitoring**:
If database grows beyond 100MB, consider:
- URL normalization (base URL + path template)
- SAUCE field compression
- Removing unnecessary FTS5 fields
- Splitting into archive.db + local.db again

**Auto-Update Mechanism**:

The database updates **automatically** on every `16c` invocation:

1. **On first run**: Downloads initial `16colors.db` (or prompts for consent)
2. **On every run**: 
   - Checks for updates (quick HEAD request for version metadata)
   - If new version available: downloads in background (non-blocking)
   - Uses cached database immediately while update happens
3. **Update frequency**: Throttled (max once per hour to avoid spam)
4. **Update method**: 
   - Small updates: Apply SQL patches incrementally
   - Large updates: Download new database file
5. **Failure handling**: Continues with cached database if update fails

**User Control** (informational only, no opt-out):
```bash
16c db version                 # Show current database version
16c db info                    # Database stats, last update time
16c db update --now            # Force immediate update (bypass throttle)

# Manual patch application (advanced users, rarely needed)
16c db patch 0001-add-mist1025.sql
```

**Design Philosophy**: 
- **Zero-friction**: Updates just work, users don't think about it
- **No opt-out**: Auto-updates are core functionality, not optional
- **If users hate this**: They can uninstall and use native FTP/RSYNC tools instead
- **Opinionated design**: We believe auto-updates are the right default

**Patch File Example** (`0001-add-mist1025.sql`):
```sql
-- Patch: Add mist1025 pack
-- Version: 1.2.1
-- Date: 2025-11-01

INSERT INTO packs (name, year, group_name, file_count, zip_url, web_url) VALUES
  ('mist1025', 2025, 'mistigris', 43, 
   'https://16colo.rs/archive/2025/mist1025.zip',
   'https://16colo.rs/pack/mist1025/');

INSERT INTO files (pack_id, relative_path, filename, extension, artist, source_url, png_url) VALUES
  (last_insert_rowid(), 'CXC-STICK.ASC', 'CXC-STICK.ASC', 'asc', 'CoaXCable',
   'https://16colo.rs/pack/mist1025/CXC-STICK.ASC',
   'https://16colo.rs/pack/mist1025/tn/CXC-STICK.ASC.png');
-- ... more files

UPDATE schema_version SET version = 1;
```

**Use Cases**:
```bash
# Search entire archive + local content (no FTP needed!)
16c search "dragon" --artist cthulu     # Queries .index.db

# Find and download
16c get dragon.ans                      # Finds in .index.db, shows download URLs, offers to download

# Filter by source
16c search "dragon" --archive-only      # Only official archive
16c search "dragon" --local-only        # Only user's local/ content

# Statistics from database
16c stats --artist misfit               # Instant stats from .index.db
16c stats --group mistigris --year 1996 # Fast filtered queries
16c stats --local                       # Stats for local/ content only
```

**Benefits**:
- **Shared by all tools**: Screensaver, viewers, editors all use same `.index.db`
- **No FTP queries**: Search entire archive instantly offline
- **Download URLs included**: Know exact URLs for source and PNGs
- **Incremental updates**: Patch files keep database current
- **Single source of truth**: One database for archive + local content
- **Predictable location**: `16colors/.index.db` in the 16colors root

### Integration Opportunities
- **OpenTUI integration**: Display artwork directly from 16colors mirror
- **SQLite-powered search**: Fast queries without scanning 4000+ packs
- **SAUCE analytics**: Complex queries on SAUCE metadata corpus
- **Format statistics**: Real-time statistics from database queries
- **PabloDraw integration**: Recognize and use shared 16colors directory
- **Moebius integration**: Open files from standard 16colors paths
- **BBS software**: Mount 16colors mirror as art file repository
- **Research exports**: Export database to CSV, JSON for academic analysis

## Testing Requirements

### Unit Tests
- 16colors directory path resolution (platform-specific)
- `.index.db` database schema and operations
- JSON Schema validation (`$schema` property)
- URL construction for 16colo.rs endpoints
- FTP directory listing parser
- RSS feed parser
- File integrity verification (checksums)
- Error handling for all failure modes
- Discovery of existing 16colors directories from other tools
- SQLite database schema creation and migrations
- SQLite query builders for complex searches
- SAUCE metadata extraction and indexing

### Integration Tests
- Download complete artpack via HTTP to 16colors directory
- Download complete artpack via FTP to 16colors directory
- Download individual file via HTTP
- Extract ZIP archive preserving structure
- Update `.index.db` with downloaded pack metadata
- Verify SAUCE metadata extraction
- Update SQLite database after pack download
- Query SQLite database for search operations
- FTS5 full-text search accuracy
- Detect existing packs in 16colors mirror (avoid re-download)
- Resume interrupted download
- Network failure recovery
- Rate limiting compliance
- FTP directory listing
- RSS feed parsing
- Interoperability: Read metadata written by hypothetical other tools
- Database rebuild from existing mirror metadata
- Database export to CSV/JSON formats

### System Tests
- End-to-end download workflow via CLI
- Mirror operations (list, verify, path, stats)
- Full archive mirror sync (small subset for testing)
- Filtered mirror sync (year range, extensions, NSFW)
- Incremental mirror sync (only new packs)
- Mirror prune (remove orphaned packs)
- Dry-run accuracy (compare preview to actual)
- Mirror configuration persistence
- Discovery operations (RSS, FTP listings)
- Integration with existing ansilust parsers
- Cross-platform compatibility (Linux, macOS, Windows)
- Verify 16colors directory is browsable by users in file managers

### Performance Tests
- Large pack download (>100MB, e.g., mist0625.zip at 7.3MB)
- FTP listing performance (all years, ~4000+ packs)
- Mirror lookup performance (thousands of files)
- Memory usage during extraction
- HTTP vs FTP vs RSYNC performance comparison
- Full mirror sync performance (time to mirror entire archive)
- Incremental sync performance (detect and download only new packs)
- Filter evaluation performance (large archive with complex filters)
- Database write performance (.index.db updates)
- Mirror stats calculation performance (thousands of packs)

## Dependencies

### Required
- **Zig std library**: HTTP client, filesystem, allocators
- **ZIP extraction**: `std.zip` or equivalent
- **HTTP client**: `std.http.Client` for downloads
- **FTP client**: Custom implementation or library (to be determined)
- **Platform directories**: Cross-platform path resolution (XDG on Linux, AppSupport/Pictures on macOS, AppData/Pictures on Windows)

### Strongly Recommended
- **SQLite**: Full mirror database with FTS5 search capabilities
  - Consider: `sqlite3` C library via Zig FFI
  - Consider: Pure Zig SQLite implementation (if available)
  - FTS5 extension for full-text search
  - JSON1 extension for SAUCE metadata storage

### Optional
- **RSYNC wrapper**: Shell out to system rsync (Phase 3)
- **libansilove integration**: For format validation after download
- **TLS**: System TLS for HTTPS (Zig std or OpenSSL/LibreSSL)

### To Research
- **FTP library**: Does Zig have FTP support? Need custom implementation?
- **HTML scraping**: If needed for search, what's the best approach?
- **XML parsing**: For RSS feed (Zig std or external?)
- **SQLite bindings**: Best approach for Zig/SQLite integration?
- **JSON Schema validation**: Zig library for validating `$schema` compliance?

## Development Notes

### Implementation Phases

#### Phase 1: HTTP Client & Basic Download
- Implement HTTP download with progress tracking
- Platform-specific path resolution
- Basic ZIP extraction
- Cache metadata (JSON)
- CLI: `download pack <name>`, `download file <url>`

#### Phase 2: FTP Client & Listings
- FTP client implementation
- Directory listing parser
- CLI: `list packs --year YYYY`, `list artists`
- Compare HTTP vs FTP performance

#### Phase 3: Discovery & RSS
- RSS feed parser
- New pack detection
- CLI: `discover --new`, `discover --since DATE`

#### Phase 4: RSYNC Integration (Optional)
- Investigate rsync module availability
- Shell wrapper or native implementation
- Bulk mirroring support

#### Phase 5: Optimization & Integration
- Protocol auto-selection
- Parallel downloads (if beneficial)
- Parser integration
- Error recovery strategies

### Security Considerations
- **Path traversal**: Validate ZIP entries to prevent directory escape
- **HTTPS validation**: Verify SSL certificates (don't disable verification!)
- **Input sanitization**: Validate pack names and URLs
- **Resource limits**: Prevent zip bombs, limit memory usage
- **Permissions**: Ensure cache directories have appropriate permissions (0700 for cache, 0755 for Pictures)
- **FTP security**: Use explicit TLS (FTPS) if available

### Research Questions for Requirements Phase

Before writing detailed requirements, answer:
1. What is the optimal HTTP User-Agent string?
2. Are there documented rate limits for 16colo.rs?
3. Does 16colo.rs provide checksums for verification?
4. What are the RSYNC modules and their structure?
5. Is there an undocumented JSON/XML API?
6. What's the best way to detect new packs (RSS vs FTP listing)?
7. Should we cache HTTP responses (HTML pages) separately?
8. What error codes do FTP and HTTP endpoints return?

### Accessibility
- **Progress output**: Support quiet mode for scripting (`-q` flag)
- **Error messages**: Clear, actionable error reporting with suggestions
- **Documentation**: Man pages, `--help` output, examples
- **Logging**: Optional verbose logging for debugging (`-v` flag)
- **Dry run**: `--dry-run` to preview operations without downloading

---

**Ready for Phase 2: Requirements Phase**  
This instructions document captures the 16colo.rs-specific design focus and research approach. 

**Next Steps**:
1. Explore RSYNC API (install rsync and investigate)
2. Test HTTP vs FTP performance with real downloads
3. Investigate if 16colo.rs has JSON/XML endpoints
4. Write detailed EARS-based requirements incorporating research findings
