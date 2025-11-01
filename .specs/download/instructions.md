# 16colo.rs Download Client - Instructions

## Overview

A specialized command-line tool and library API for the **16colo.rs archive** (and API-compatible mirrors). This client provides efficient downloading of artpacks and individual artwork files with intelligent caching, metadata preservation, and multi-protocol support.

**Design Focus**: This is explicitly a **16colo.rs-specific client**, not a generic download manager. We will first explore and understand what the 16colo.rs APIs offer (HTTP, FTP, RSYNC) before making implementation decisions. The final solution will likely combine multiple protocols for optimal performance.

**Open Standard**: We define a **community-standard directory structure** for local 16colors mirrors (`~/Pictures/16colors/`). This is **not ansilust-specific** - any tool (PabloDraw, Moebius, ansilove, etc.) can discover and share this standardized artwork repository. We are merely one of many tools that will read and write this format.

## User Story

**As a** text art enthusiast, developer, or researcher  
**I want to** download artpacks and individual artwork from the 16colo.rs archive  
**So that** I can:
- Process artwork offline with ansilust parsers
- Build collections for analysis or display
- Cache frequently accessed artwork locally
- Share a standardized corpus across multiple applications
- Preserve SAUCE metadata and original file formats
- Avoid redundant downloads with smart caching

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

### FR1.6: Integration
FR1.6.1: The system shall provide a Zig library API for programmatic access.  
FR1.6.2: The system shall provide a command-line interface for interactive use.  
FR1.6.3: The system shall integrate with ansilust parsers for format validation.  
FR1.6.4: WHEN files are downloaded the system shall emit events for integration hooks.

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
| Bulk mirroring | **RSYNC** (TBD) | Efficient sync, checksums |
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

**Rationale**: 
- **Shared standard**: Any tool can discover `~/Pictures/16colors/` or `~/.local/share/16colors/`
- **User-browsable**: Artists and enthusiasts can manually explore their collection
- **Tool-agnostic**: Metadata format is tool-independent (`.16colors-meta.json`)
- **Tool-specific cache**: Each tool manages its own cache under `16colors-tools/<toolname>/`
- **Predictable paths**: Scripts and automation can rely on consistent structure
- **Multi-tool friendly**: PabloDraw, Moebius, ansilove, ansilust can all share this archive

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

## Acceptance Criteria (EARS Patterns)

### AC1: Basic Pack Download (HTTP)
- WHEN the user requests `ansilust download pack mist1025` the system shall download from `/archive/2025/mist1025.zip`
- The system shall extract files to cache directory preserving structure
- The system shall display download progress (bytes, percentage, speed, ETA)
- IF the pack is already cached THEN the system shall skip download unless --force is specified
- The system shall verify ZIP integrity after download

### AC2: Individual File Download (HTTP)
- WHEN the user requests a specific file the system shall download from `/pack/packname/filename.ext`
- The system shall preserve the original filename and SAUCE metadata
- IF the file exists in cache THEN the system shall verify integrity and skip download if valid

### AC3: Pack Listing (FTP)
- The system shall support `ansilust list packs --year 2025` using FTP directory listing
- The output shall show pack names, sizes, and modification dates
- The system shall indicate which packs are already in the local 16colors mirror
- The listing operation shall complete in < 5 seconds for a single year

### AC4: Resume Support (HTTP)
- WHEN a download is interrupted the system shall resume from last position
- The system shall use Range requests for resume
- IF resume fails THEN the system shall restart from beginning

### AC5: Mirror Operations
- The system shall support `ansilust mirror list` to show local 16colors mirror contents
- The system shall support `ansilust mirror verify` to check file integrity against metadata
- The system shall support `ansilust mirror path` to display the 16colors directory location
- The system shall report mirror size and statistics on demand

### AC6: Discovery via RSS
- The system shall parse https://16colo.rs/rss/ for new releases
- The system shall support `ansilust discover --new` to show packs not yet in local mirror
- The system shall display pack metadata from RSS (title, date, description)

## Out of Scope

- **Generic download manager**: This is 16colo.rs-specific only
- **Full archive mirroring**: Users can use native FTP/RSYNC tools for complete mirrors
- **Upload functionality**: Publishing to 16colo.rs (separate feature)
- **Web interface**: Browser-based download manager (CLI only for now)
- **Format conversion**: Rendering/conversion (handled by existing parsers/renderers)
- **Social features**: Comments, ratings, favorites (use 16colo.rs website)
- **Automatic updates**: Background sync daemon (manual refresh only)
- **Search implementation**: Full-text search (defer to 16colo.rs website for now)

## Success Metrics

- **SM1**: Users can download any artpack from 16colo.rs with a single command
- **SM2**: Downloaded files follow the community 16colors standard with no unnecessary re-downloads
- **SM3**: Storage follows platform conventions and artpacks are easily discoverable by users and other tools
- **SM4**: Integration with ansilust parsers is seamless (files ready for processing)
- **SM5**: Network usage is reasonable (progress display, resumable downloads, rate limiting)
- **SM6**: Error handling is clear and actionable (network issues, missing packs, etc.)
- **SM7**: Protocol selection is transparent and optimal for each operation type
- **SM8**: The 16colors directory standard enables interoperability between multiple tools

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
- **Watch mode**: Monitor RSS feed for new releases and auto-download
- **Collection management**: User-defined collections with metadata
- **Mirror failover**: Automatic fallback to FTP/RSYNC if HTTP fails
- **Parallel downloads**: Concurrent downloads with connection pooling
- **Checksum verification**: SHA256 validation against published manifests
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
- Mirror operations (list, verify, path)
- Discovery operations (RSS, FTP listings)
- Integration with existing ansilust parsers
- Cross-platform compatibility (Linux, macOS, Windows)
- Verify 16colors directory is browsable by users in file managers

### Performance Tests
- Large pack download (>100MB, e.g., mist0625.zip at 7.3MB)
- FTP listing performance (all years, ~4000+ packs)
- Mirror lookup performance (thousands of files)
- Memory usage during extraction
- HTTP vs FTP performance comparison
- Metadata read/write performance (`.16colors-meta.json`)

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
