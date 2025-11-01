# Download Feature - Instructions

## Overview

A command-line tool and library API for downloading artpacks and individual artwork files from the 16colo.rs archive with intelligent caching, metadata preservation, and efficient storage management.

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

### FR1.2: Cache Management
FR1.2.1: The system shall store downloaded files in platform-specific standard locations.  
FR1.2.2: The system shall maintain cache metadata (download date, source URL, checksum).  
FR1.2.3: The system shall support cache validation and refresh operations.  
FR1.2.4: WHEN cache storage exceeds configured limits the system shall support cache cleanup operations.  
FR1.2.5: The system shall store artpacks in user-browsable locations (Pictures directory on macOS/Windows).

### FR1.3: Metadata Preservation
FR1.3.1: The system shall preserve original filenames from artpacks.  
FR1.3.2: The system shall extract and store SAUCE metadata when present.  
FR1.3.3: The system shall maintain artpack structure (directory hierarchy).  
FR1.3.4: WHEN multiple versions of a file exist the system shall support version tracking.

### FR1.4: Discovery and Search
FR1.4.1: The system shall list available artpacks by year, group, or artist.  
FR1.4.2: The system shall query the 16colo.rs archive for search results.  
FR1.4.3: WHEN browsing packs the system shall display pack metadata (group, date, file count).  
FR1.4.4: The system shall support filtering by file format (ANS, XB, ASC, etc.).

### FR1.5: Integration
FR1.5.1: The system shall provide a Zig library API for programmatic access.  
FR1.5.2: The system shall provide a command-line interface for interactive use.  
FR1.5.3: The system shall integrate with ansilust parsers for format validation.  
FR1.5.4: WHEN files are downloaded the system shall emit events for integration hooks.

## Technical Specifications

### Data Sources
- **Primary**: https://16colo.rs/
  - Web interface: Browse packs, artists, groups
  - Download endpoint: `/archive/YYYY/packname.zip`
  - Individual files: `/pack/packname/filename.ext`
- **Mirror Support**: FTP (ftp://16colo.rs) and RSYNC (rsync://16colo.rs/)
- **RSS Feed**: https://16colo.rs/rss/ for discovering new releases

### Storage Architecture

Platform-specific storage following OS conventions:

**Linux** (XDG Base Directory Specification):
- **Artpacks**: `~/.local/share/ansilust/packs/`
- **Cache**: `~/.cache/ansilust/`
- **Config**: `~/.config/ansilust/`

**macOS** (Standard Application Support):
- **Artpacks**: `~/Pictures/Ansilust/` (user-browsable artwork)
- **Cache**: `~/Library/Caches/com.ansilust/`
- **Config**: `~/Library/Application Support/Ansilust/`

**Windows**:
- **Artpacks**: `%USERPROFILE%\Pictures\Ansilust\` (user-browsable artwork)
- **Cache**: `%LOCALAPPDATA%\Ansilust\Cache\`
- **Config**: `%APPDATA%\Ansilust\`

Directory structure (shown with Linux paths, adapt per platform):
```
~/.local/share/ansilust/packs/     (or ~/Pictures/Ansilust/ on macOS/Windows)
├── 2025/
│   ├── mist1025.zip               # Original artpack
│   └── mist1025/                  # Extracted contents
│       ├── .metadata.json         # Cache metadata
│       └── [artwork files]
└── ...

~/.cache/ansilust/                 (platform-specific cache location)
└── metadata.db                    # SQLite cache index (optional)

~/.local/share/ansilust/corpus/    (or ~/Pictures/Ansilust/Corpus/)
└── [curated collections]
```

**Rationale**: Artpacks are valuable user content (like photos) and should be easily discoverable in platform-standard locations. Cache and config follow platform conventions for application data.

### Network Protocol Requirements
- **HTTP/HTTPS**: Primary download protocol
- **Resumable downloads**: Support Range requests for large packs
- **Compression**: Handle gzip/deflate transparently
- **Rate limiting**: Respect server bandwidth (configurable delay)
- **User-Agent**: Identify as `ansilust/VERSION` for tracking

### File Format Support
Must handle extraction and validation for:
- **Archives**: ZIP (primary format used by 16colo.rs)
- **Text Art**: ANS, ASC, XB, ICE, BIN, PCB, TND, ADF, IDF, RIP, LIT, DRK
- **Metadata**: SAUCE records embedded in files
- **Misc**: DIZ, NFO, TXT (info files), PNG/GIF (rendered previews)

## Acceptance Criteria (EARS Patterns)

### AC1: Basic Download
- WHEN the user requests `ansilust download pack mist1025` the system shall download the complete artpack
- The system shall extract files to cache directory preserving structure
- The system shall display download progress (bytes, percentage, speed)
- IF the pack is already cached THEN the system shall skip download unless --force is specified

### AC2: Individual File Download
- WHEN the user requests a specific file URL the system shall download only that file
- The system shall preserve the original filename and SAUCE metadata
- IF the file exists in cache THEN the system shall verify integrity and skip download if valid

### AC3: Cache Operations
- The system shall support `ansilust cache list` to show cached packs
- The system shall support `ansilust cache clean` to remove old or unused entries
- The system shall support `ansilust cache verify` to check file integrity
- The system shall report cache size and location on demand

### AC4: Discovery
- The system shall support `ansilust search "keyword"` to query 16colo.rs
- The system shall support `ansilust list packs --year 2025` to browse by year
- The system shall support `ansilust list artists` to browse artists
- WHEN listing items the system shall indicate which are already cached

### AC5: Integration
- The system shall provide Zig APIs: `downloadPack()`, `downloadFile()`, `getCachedPath()`
- The system shall emit events: `onDownloadStart`, `onProgress`, `onComplete`, `onError`
- WHEN integrated with parsers the system shall validate file formats after download

## Out of Scope

- **Bulk mirroring**: Full archive mirroring via FTP/RSYNC (users can use native tools)
- **Upload functionality**: Publishing to 16colo.rs (separate feature)
- **Web interface**: Browser-based download manager (CLI only for now)
- **Format conversion**: Rendering/conversion (handled by existing parsers/renderers)
- **Social features**: Comments, ratings, favorites (use 16colo.rs website)
- **Automatic updates**: Background sync daemon (manual refresh only)

## Success Metrics

- **SM1**: Users can download any artpack from 16colo.rs with a single command
- **SM2**: Downloaded files are cached efficiently with no unnecessary re-downloads
- **SM3**: Cache follows platform conventions and artpacks are easily discoverable by users
- **SM4**: Integration with ansilust parsers is seamless (files ready for processing)
- **SM5**: Network usage is reasonable (progress display, resumable downloads)
- **SM6**: Error handling is clear and actionable (network issues, missing packs, etc.)

## Future Considerations

### Phase 2 Enhancements
- **Corpus building**: Automated download of curated sets for research
- **Watch mode**: Monitor RSS feed for new releases and auto-download
- **Collection management**: User-defined collections with metadata
- **Mirror failover**: Automatic fallback to FTP/RSYNC if HTTP fails
- **Parallel downloads**: Concurrent downloads with connection pooling
- **Checksum verification**: SHA256 validation against published manifests

### Integration Opportunities
- **OpenTUI integration**: Display artwork directly from cache
- **Database indexing**: Full-text search of cached artwork content
- **SAUCE database**: Aggregate metadata for analysis
- **Format statistics**: Analyze corpus by format, year, group, etc.

## Testing Requirements

### Unit Tests
- Cache path resolution (platform-specific path handling)
- URL parsing and validation
- Metadata serialization/deserialization
- File integrity verification (checksums)
- Error handling for all failure modes

### Integration Tests
- Download complete artpack from 16colo.rs
- Extract ZIP archive preserving structure
- Verify SAUCE metadata extraction
- Cache hit/miss scenarios
- Network failure recovery
- Rate limiting compliance

### System Tests
- End-to-end download workflow via CLI
- Cache operations (list, clean, verify)
- Discovery operations (search, browse)
- Integration with existing parsers
- Cross-platform compatibility (Linux, macOS, Windows)

### Performance Tests
- Large pack download (>100MB)
- Concurrent downloads (if implemented)
- Cache lookup performance (thousands of files)
- Memory usage during extraction

## Dependencies

### Required
- **Zig std library**: HTTP client, filesystem, allocators
- **ZIP extraction**: Consider `std.zip` or external library
- **HTTP client**: `std.http.Client` for downloads
- **Platform directories**: Cross-platform path resolution (XDG on Linux, AppSupport/Pictures on macOS, AppData/Pictures on Windows)

### Optional
- **SQLite**: For cache index (can start with JSON/filesystem only)
- **libansilove**: For format validation after download
- **OpenSSL/LibreSSL**: For HTTPS if not using system TLS

## Development Notes

### Implementation Phases
1. **Core Download**: Basic HTTP download with progress
2. **Cache Management**: Platform-specific storage and metadata
3. **ZIP Extraction**: Unpack artpacks preserving structure
4. **Discovery**: Browse and search 16colo.rs
5. **CLI Interface**: User-friendly command-line tool
6. **Integration**: Library API and parser hooks

### Security Considerations
- **Path traversal**: Validate ZIP entries to prevent directory escape
- **HTTPS validation**: Verify SSL certificates
- **Input sanitization**: Validate pack names and URLs
- **Resource limits**: Prevent zip bombs and excessive memory use
- **Permissions**: Ensure cache directories have appropriate permissions

### Accessibility
- **Progress output**: Support quiet mode for scripting
- **Error messages**: Clear, actionable error reporting
- **Documentation**: Man pages and --help output
- **Logging**: Optional verbose logging for debugging

---

**Ready for Phase 2: Requirements Phase**  
This instructions document captures the initial vision. Next step: detailed EARS-based requirements specification.
