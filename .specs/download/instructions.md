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
FR1.3.2: The system shall write metadata in the standard `.16colors-meta.json` format.  
FR1.3.3: The system shall discover existing 16colors directories created by other tools.  
FR1.3.4: The system shall store tool-specific cache in `16colors-tools/ansilust/` subdirectories.  
FR1.3.5: The system shall store artpacks in user-browsable locations (Pictures directory on macOS/Windows).

### FR1.4: Metadata Preservation
FR1.4.1: The system shall preserve original filenames from artpacks.  
FR1.4.2: The system shall extract and store SAUCE metadata when present.  
FR1.4.3: The system shall maintain artpack structure (directory hierarchy).  
FR1.4.4: WHEN multiple versions of a file exist the system shall support version tracking.

### FR1.5: Discovery and Search
FR1.5.1: The system shall list available artpacks by year, group, or artist.  
FR1.5.2: The system shall query the 16colo.rs archive for search results.  
FR1.5.3: WHEN browsing packs the system shall display pack metadata (group, date, file count).  
FR1.5.4: The system shall support filtering by file format (ANS, XB, ASC, etc.).

### FR1.6: Archive Mirroring
FR1.6.1: The system shall support mirroring the entire 16colors archive.  
FR1.6.2: The system shall support incremental mirror sync (only download new/changed packs).  
FR1.6.3: The system shall support filtering mirrors by year range (e.g., --since 2020).  
FR1.6.4: The system shall support excluding NSFW content from mirrors.  
FR1.6.5: The system shall support filtering by file extension (include or exclude specific types).  
FR1.6.6: The system shall support excluding specific groups from mirrors.  
FR1.6.7: The system shall support dry-run mode to preview mirror operations.  
FR1.6.8: WHERE rsync is available the system shall support bandwidth limiting.  
FR1.6.9: The system shall persist mirror configuration for subsequent sync operations.  
FR1.6.10: The system shall support pruning orphaned packs (removed from remote).

### FR1.7: CLI Interface
FR1.7.1: The system shall provide a `16c` (or `16colors`) CLI for archive-first operations.  
FR1.7.2: The system shall provide archive integration in the `ansilust` CLI via `--16colors` flag.  
FR1.7.3: The `16c` CLI shall assume archive context for all commands.  
FR1.7.4: The `ansilust` CLI shall assume local file context unless `--16colors` is specified.  
FR1.7.5: Both CLIs shall share the same underlying library implementation.

### FR1.8: Library Integration
FR1.8.1: The system shall provide a Zig library API for programmatic access.  
FR1.8.2: The library shall integrate with ansilust parsers for format validation.  
FR1.8.3: WHEN files are downloaded the library shall emit events for integration hooks.  
FR1.8.4: The library shall be usable independently of the CLI tools.

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
├── packs/                         # Complete artpack archive
│   ├── 1990/
│   ├── 1996/
│   ├── 2025/
│   │   ├── mist1025.zip           # Original artpack (preserved)
│   │   └── mist1025/              # Extracted contents
│   │       ├── .16colors-meta.json  # Standard metadata format
│   │       ├── FILE_ID.DIZ
│   │       ├── MIST1025.NFO.ANS
│   │       └── [artwork files]
│   └── ...
├── corpus/                        # Curated collections for research
│   ├── ansi-1990s/                # User-organized collections
│   ├── ice-colors-examples/
│   └── ...
└── .16colors-manifest.json        # Global manifest (optional)

~/.cache/16colors-tools/ansilust/  (tool-specific cache, not shared)
├── download-queue.json
├── http-cache/
└── index.db                       # ansilust-specific index
```

**Standard Metadata Format** (`.16colors-meta.json`):
```json
{
  "schema_version": "1.0",
  "source": "https://16colo.rs",
  "pack_name": "mist1025",
  "year": 2025,
  "group": "mistigris",
  "downloaded_at": "2025-11-01T23:30:00Z",
  "downloaded_by": "ansilust/0.1.0",
  "source_url": "https://16colo.rs/archive/2025/mist1025.zip",
  "zip_checksum": "sha256:...",
  "file_count": 43,
  "extracted_at": "2025-11-01T23:30:05Z"
}
```

**Mirror Configuration Format** (`.16colors-mirror-config.json`):
```json
{
  "schema_version": "1.0",
  "mirror_mode": "filtered",
  "last_sync": "2025-11-01T23:30:00Z",
  "filters": {
    "year_range": {
      "since": 2020,
      "until": null
    },
    "exclude_nsfw": true,
    "exclude_extensions": ["png", "gif", "jpg"],
    "include_extensions": null,
    "exclude_groups": ["acdu"],
    "include_groups": null
  },
  "sync_stats": {
    "total_packs": 127,
    "total_size_bytes": 524288000,
    "last_duration_seconds": 1834
  }
}
```

**Rationale**: 
- **Shared standard**: Any tool can discover `~/Pictures/16colors/` or `~/.local/share/16colors/`
- **User-browsable**: Artists and enthusiasts can manually explore their collection
- **Tool-agnostic**: Metadata format is tool-independent (`.16colors-meta.json`)
- **Tool-specific cache**: Each tool manages its own cache under `16colors-tools/<toolname>/`
- **Predictable paths**: Scripts and automation can rely on consistent structure
- **Multi-tool friendly**: PabloDraw, Moebius, ansilove, ansilust can all share this archive
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
Must handle extraction and validation for:
- **Archives**: ZIP (primary format used by 16colo.rs)
- **Text Art**: ANS, ASC, XB, ICE, BIN, PCB, TND, ADF, IDF, RIP, LIT, DRK
- **Metadata**: SAUCE records embedded in files
- **Misc**: DIZ, NFO, TXT (info files), PNG/GIF (rendered previews)

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
16c mirror sync                           # Sync entire archive
16c mirror sync --year 2025               # Sync only 2025
16c mirror sync --since 2020              # Sync 2020-present
16c mirror sync --exclude-nsfw            # Exclude NSFW content
16c mirror sync --exclude-ext png,gif     # Exclude file types
16c mirror sync --only-ext ans,asc,xb     # Only specific types
16c mirror sync --exclude-group acdu      # Exclude specific groups
16c mirror sync --dry-run                 # Preview what would be downloaded
16c mirror sync --bandwidth 1M            # Limit bandwidth (rsync)
```

**Search and discovery**:
```bash
# Search for files by name across the entire archive
16c art.ans                    # Find all files named "art.ans" and display them
16c search "dragon"            # Full-text search across all artwork
16c search --artist cthulu     # Search by artist

# List packs
16c list --year 2025           # List 2025 packs
16c list --group mistigris     # List mistigris packs
16c list --new                 # Show new packs (from RSS)
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

### AC2: File Search and Display (`16c` CLI)
- WHEN the user requests `16c art.ans` the system shall search the entire archive for files named "art.ans"
- The system shall display a list of matches with pack/year context
- The system shall download missing files on-demand
- The system shall render all matching files using ansilust renderers
- IF multiple matches exist THEN the system shall display them sequentially or prompt for selection

### AC3: Local File Processing (`ansilust` CLI)
- WHEN the user requests `ansilust art.ans` the system shall process `./art.ans` as a local file
- The system shall NOT search the archive unless `--16colors` is specified
- IF the file does not exist locally THEN the system shall return error.FileNotFound
- The behavior shall be consistent with Unix tools like `cat`, `file`, etc.

### AC4: Pack Listing (FTP) - Both CLIs
- The system shall support `16c list --year 2025` using FTP directory listing
- The system shall support `ansilust --16colors list --year 2025` with identical behavior
- The output shall show pack names, sizes, and modification dates
- The system shall indicate which packs are already in the local 16colors mirror
- The listing operation shall complete in < 5 seconds for a single year

### AC5: Resume Support (HTTP)
- WHEN a download is interrupted the system shall resume from last position
- The system shall use Range requests for resume
- IF resume fails THEN the system shall restart from beginning

### AC6: Mirror Operations - Both CLIs
- The system shall support `16c mirror` to show local 16colors mirror status
- The system shall support `16c mirror list` to show mirror contents
- The system shall support `16c mirror verify` to check file integrity against metadata
- The system shall support `16c mirror path` to display the 16colors directory location
- The `ansilust --16colors mirror` commands shall have identical behavior
- The system shall report mirror size and statistics on demand

### AC7: Discovery via RSS - Both CLIs
- The system shall parse https://16colo.rs/rss/ for new releases
- The system shall support `16c list --new` to show packs not yet in local mirror
- The system shall support `ansilust --16colors list --new` with identical behavior
- The system shall display pack metadata from RSS (title, date, description)

### AC8: CLI Naming and Aliases
- The primary archive CLI shall be named `16c`
- The system shall support `16colors` as an alias to `16c`
- The system shall support `16` as a short alias to `16c`
- All three names shall invoke identical functionality
- The `ansilust` CLI shall remain the primary file-processing tool

### AC9: Full Archive Mirroring
- WHEN the user requests `16c mirror sync` the system shall download the entire 16colors archive
- The system shall use the optimal protocol (RSYNC > FTP > HTTP) based on availability
- The system shall display progress for the overall mirror operation (packs downloaded, total size, ETA)
- WHEN sync is run again the system shall only download new or changed packs (incremental)
- The system shall skip already-mirrored packs unless --force is specified

### AC10: Filtered Mirroring
- WHEN the user requests `16c mirror sync --exclude-nsfw` the system shall skip NSFW-tagged content
- WHEN the user requests `16c mirror sync --since 2020` the system shall only download packs from 2020 onwards
- WHEN the user requests `16c mirror sync --exclude-ext png,gif` the system shall skip files with those extensions
- WHEN the user requests `16c mirror sync --only-ext ans,asc,xb` the system shall only download files with those extensions
- The system shall persist filter configuration in `.16colors-mirror-config.json`
- WHEN sync is run without filters the system shall use previously configured filters

### AC11: Mirror Management
- WHEN the user requests `16c mirror sync --dry-run` the system shall display what would be downloaded without downloading
- The dry-run output shall show total size and pack count
- WHEN the user requests `16c mirror prune` the system shall remove local packs that no longer exist on remote
- The system shall support `16c mirror stats` to show breakdown by year, group, file type
- The mirror stats shall include total size, pack count, file count, and oldest/newest packs

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

### Integration & Interoperability
- **SM15**: Integration with ansilust parsers is seamless (files ready for processing)
- **SM16**: The 16colors directory standard enables interoperability between multiple tools
- **SM17**: Error handling is clear and actionable (network issues, missing packs, etc.)
- **SM18**: Protocol selection is transparent and optimal for each operation type

## Future Considerations

### Protocol Research Tasks
Before Phase 2 (Requirements), we should:
- [ ] Investigate 16colo.rs JSON/XML API (if it exists)
- [ ] Test RSYNC performance and features
- [ ] Measure HTTP vs FTP performance for common operations
- [ ] Check if search supports query parameters
- [ ] Document rate limits and acceptable use
- [ ] Investigate checksum/manifest availability

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

### Integration Opportunities
- **OpenTUI integration**: Display artwork directly from 16colors mirror
- **Database indexing**: Full-text search of local mirror content
- **SAUCE database**: Aggregate metadata from `.16colors-meta.json` files for analysis
- **Format statistics**: Analyze corpus by format, year, group, etc.
- **PabloDraw integration**: Recognize and use shared 16colors directory
- **Moebius integration**: Open files from standard 16colors paths
- **BBS software**: Mount 16colors mirror as art file repository

## Testing Requirements

### Unit Tests
- 16colors directory path resolution (platform-specific)
- `.16colors-meta.json` metadata format serialization/deserialization
- URL construction for 16colo.rs endpoints
- FTP directory listing parser
- RSS feed parser
- File integrity verification (checksums)
- Error handling for all failure modes
- Discovery of existing 16colors directories from other tools

### Integration Tests
- Download complete artpack via HTTP to 16colors directory
- Download complete artpack via FTP to 16colors directory
- Download individual file via HTTP
- Extract ZIP archive preserving structure
- Write valid `.16colors-meta.json` metadata
- Verify SAUCE metadata extraction
- Detect existing packs in 16colors mirror (avoid re-download)
- Resume interrupted download
- Network failure recovery
- Rate limiting compliance
- FTP directory listing
- RSS feed parsing
- Interoperability: Read metadata written by hypothetical other tools

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
- Metadata read/write performance (`.16colors-meta.json`)
- Mirror stats calculation performance (thousands of packs)

## Dependencies

### Required
- **Zig std library**: HTTP client, filesystem, allocators
- **ZIP extraction**: `std.zip` or equivalent
- **HTTP client**: `std.http.Client` for downloads
- **FTP client**: Custom implementation or library (to be determined)
- **Platform directories**: Cross-platform path resolution (XDG on Linux, AppSupport/Pictures on macOS, AppData/Pictures on Windows)

### Optional
- **RSYNC wrapper**: Shell out to system rsync (Phase 3)
- **SQLite**: For cache index (can start with JSON/filesystem only)
- **libansilove integration**: For format validation after download
- **TLS**: System TLS for HTTPS (Zig std or OpenSSL/LibreSSL)

### To Research
- **FTP library**: Does Zig have FTP support? Need custom implementation?
- **HTML scraping**: If needed for search, what's the best approach?
- **XML parsing**: For RSS feed (Zig std or external?)

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
