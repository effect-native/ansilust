# 16colors CLI & Download Client - Design Document

## Document Overview

This document provides the technical architecture and implementation strategy for the 16colors download client. It focuses on **WHAT** to build and **HOW** it will be structured, not the actual implementation code.

**Related Documents**:
- `instructions.md` - User stories and initial requirements capture
- `requirements.md` - Formal EARS-based requirements
- `plan.md` - Implementation roadmap (Phase 4)

**Design Philosophy**: This design follows Zig best practices for memory safety, explicit error handling, and zero hidden control flow. The architecture separates concerns cleanly while maintaining simplicity and performance.

---

## Architecture Overview

### High-Level System Components

```
┌─────────────────────────────────────────────────────────────┐
│                        CLI Layer                             │
│  ┌──────────────┐                  ┌────────────────────┐   │
│  │  16c CLI     │                  │  ansilust CLI      │   │
│  │  (archive)   │                  │  (--16colors)      │   │
│  └──────┬───────┘                  └─────────┬──────────┘   │
│         │                                    │              │
│         └────────────────┬───────────────────┘              │
└──────────────────────────┼────────────────────────────────┘
                           │
┌──────────────────────────┼────────────────────────────────┐
│                   Library Layer                            │
│  ┌────────────────────────────────────────────────────┐   │
│  │           16colors Download Library                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────────────┐   │   │
│  │  │ Database │  │ Protocol │  │ Mirror Manager  │   │   │
│  │  │ Manager  │  │ Clients  │  │                 │   │   │
│  │  └──────────┘  └──────────┘  └─────────────────┘   │   │
│  └────────────────────────────────────────────────────┘   │
└────────────────────────────┬───────────────────────────────┘
                             │
┌────────────────────────────┼───────────────────────────────┐
│                     Protocol Layer                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────────────────┐   │
│  │   HTTP   │   │   FTP    │   │   RSYNC (wrapper)    │   │
│  │  Client  │   │  Client  │   │                      │   │
│  └──────────┘   └──────────┘   └──────────────────────┘   │
└────────────────────────────┬───────────────────────────────┘
                             │
┌────────────────────────────┼───────────────────────────────┐
│                      Storage Layer                          │
│  ┌──────────────────┐   ┌──────────────────────────────┐   │
│  │   File System    │   │   SQLite Database            │   │
│  │   (16colors/)    │   │   (.index.db)                │   │
│  └──────────────────┘   └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Component Relationships

**CLI Layer** → **Library Layer** → **Protocol Layer** → **Storage Layer**

- **CLI Layer**: Two entry points (`16c`, `ansilust --16colors`) with different default contexts
- **Library Layer**: Reusable download/mirror/search logic (independent of CLI)
- **Protocol Layer**: HTTP/FTP/RSYNC clients with automatic fallback
- **Storage Layer**: Platform-specific filesystem + SQLite database

---

## Module Organization

### Primary Modules

```
src/download/
├── lib.zig                    # Public library API
├── cli/
│   ├── sixteenc.zig          # 16c CLI entry point
│   ├── ansilust_integration.zig  # --16colors flag handling
│   └── commands.zig          # Shared CLI commands
├── database/
│   ├── schema.zig            # Database schema and migrations
│   ├── queries.zig           # Query builders
│   ├── fts.zig               # Full-text search
│   └── updates.zig           # Auto-update mechanism
├── protocols/
│   ├── http.zig              # HTTP/HTTPS client
│   ├── ftp.zig               # FTP client
│   └── rsync.zig             # RSYNC wrapper
├── mirror/
│   ├── sync.zig              # Mirror sync logic
│   ├── filters.zig           # Content filtering (NSFW, executables, etc.)
│   └── config.zig            # Mirror configuration management
├── storage/
│   ├── paths.zig             # Platform-specific path resolution
│   ├── extract.zig           # ZIP extraction
│   └── sauce.zig             # SAUCE metadata extraction
└── errors.zig                # Error definitions

tests/
├── database_test.zig
├── protocols_test.zig
├── mirror_test.zig
└── integration_test.zig
```

### Module Dependencies

**Dependency Flow**:
```
cli/* → lib.zig → database/*, protocols/*, mirror/*, storage/*
database/* → storage/paths.zig
protocols/* → (std.http, custom FTP, shell rsync)
mirror/* → protocols/*, database/*, storage/*
storage/* → (std.fs, std.zip)
```

**Key Design Decisions**:
- No circular dependencies (DAG structure)
- Each module has clear single responsibility
- Protocol clients are interchangeable (interface-based design)
- Database layer is isolated (can swap SQLite implementation)

---

## Data Structures

### Core Types

#### Platform Detection
```zig
/// Platform-specific directory paths
pub const PlatformPaths = struct {
    /// 16colors root directory (~/Pictures/16colors/ or platform equivalent)
    sixteen_colors_root: []const u8,
    
    /// Tool-specific cache directory
    cache_dir: []const u8,
    
    /// Tool-specific config directory
    config_dir: []const u8,
};

/// Platform detection and path resolution
pub const Platform = enum {
    linux,
    macos,
    windows,
    
    pub fn detect() Platform;
    pub fn getPaths(allocator: Allocator) !PlatformPaths;
};
```

#### Database Types
```zig
/// Global archive database (.index.db)
pub const ArchiveDatabase = struct {
    db: *sqlite.Database,
    allocator: Allocator,
    path: []const u8,
    
    pub fn init(allocator: Allocator, path: []const u8) !ArchiveDatabase;
    pub fn deinit(self: *ArchiveDatabase) void;
    pub fn checkForUpdates(self: *ArchiveDatabase) !?UpdateInfo;
    pub fn applyPatch(self: *ArchiveDatabase, patch_sql: []const u8) !void;
};

/// Pack metadata from database
pub const Pack = struct {
    id: i64,
    name: []const u8,
    year: u16,
    group_name: ?[]const u8,
    release_date: ?[]const u8,
    file_count: u32,
    total_size: u64,
    nsfw: bool,
    zip_url: []const u8,
    web_url: []const u8,
};

/// File metadata from database
pub const ArtFile = struct {
    id: i64,
    pack_id: i64,
    relative_path: []const u8,
    filename: []const u8,
    extension: ?[]const u8,
    size: u64,
    artist: ?[]const u8,
    title: ?[]const u8,
    sauce_data: ?[]const u8,  // JSON string
    source_url: []const u8,
    png_url: ?[]const u8,
    png_url_x1: ?[]const u8,
    png_url_x2: ?[]const u8,
};

/// Search results with context
pub const SearchResult = struct {
    file: ArtFile,
    pack: Pack,
    match_score: f32,  // FTS5 relevance
};
```

#### Protocol Types
```zig
/// Download progress callback
pub const ProgressCallback = fn (bytes_transferred: u64, total_bytes: u64) void;

/// Protocol selection strategy
pub const ProtocolStrategy = enum {
    auto,        // Automatic selection
    http_only,
    ftp_only,
    rsync_only,
};

/// Download options
pub const DownloadOptions = struct {
    allocator: Allocator,
    protocol: ProtocolStrategy = .auto,
    resume: bool = true,
    progress_callback: ?ProgressCallback = null,
    rate_limit_bytes_per_sec: ?u64 = null,
};

/// Protocol client interface (concept, not explicit trait)
/// All protocol clients implement: download(url, dest, options)
pub const HttpClient = struct {
    allocator: Allocator,
    
    pub fn init(allocator: Allocator) HttpClient;
    pub fn download(self: *HttpClient, url: []const u8, dest: []const u8, options: DownloadOptions) !void;
    pub fn head(self: *HttpClient, url: []const u8) !HttpHeaders;
};

pub const FtpClient = struct {
    allocator: Allocator,
    
    pub fn init(allocator: Allocator) FtpClient;
    pub fn download(self: *FtpClient, url: []const u8, dest: []const u8, options: DownloadOptions) !void;
    pub fn list(self: *FtpClient, path: []const u8) ![]FtpEntry;
};

pub const RsyncClient = struct {
    allocator: Allocator,
    
    pub fn init(allocator: Allocator) !RsyncClient;  // May fail if rsync not found
    pub fn sync(self: *RsyncClient, src: []const u8, dest: []const u8, options: RsyncOptions) !void;
};
```

#### Mirror Types
```zig
/// Mirror filter configuration
pub const MirrorFilters = struct {
    year_range: ?struct { since: u16, until: ?u16 } = null,
    include_nsfw: bool = false,
    include_executables: bool = false,
    exclude_extensions: ?[]const []const u8 = null,
    include_extensions: ?[]const []const u8 = null,  // Overrides defaults if set
    exclude_groups: ?[]const []const u8 = null,
    include_groups: ?[]const []const u8 = null,
};

/// Mirror configuration (persisted to .16colors-config.json)
pub const MirrorConfig = struct {
    mirror_mode: enum { full, filtered } = .filtered,
    last_sync: ?[]const u8 = null,  // ISO 8601 timestamp
    defaults: struct {
        exclude_nsfw: bool = true,
        exclude_executables: bool = true,
    } = .{},
    filters: MirrorFilters = .{},
    sync_stats: ?SyncStats = null,
    
    pub fn load(allocator: Allocator, path: []const u8) !MirrorConfig;
    pub fn save(self: *const MirrorConfig, path: []const u8) !void;
};

/// Mirror sync statistics
pub const SyncStats = struct {
    total_packs: u32,
    total_size_bytes: u64,
    last_duration_seconds: u64,
    nsfw_excluded_count: u32,
    executables_excluded_count: u32,
};
```

---

## Algorithm Approaches

### Database Auto-Update Flow

**High-level algorithm** (non-blocking, throttled):

```
1. On CLI invocation (16c command):
   a. Load cached .index.db (instant access to search)
   b. Check if update check is due (throttle: max once per hour)
   c. If not due: proceed with command
   d. If due: spawn background update check
   
2. Background update check:
   a. HEAD request to https://ansilust.com/16colors/.index.db.version
   b. Compare remote version with local schema_version
   c. If versions match: update throttle timestamp, exit
   d. If remote newer: determine update strategy
   
3. Update strategy decision:
   a. Check for available patches (0001.sql, 0002.sql, ...)
   b. Calculate patch count needed (remote_version - local_version)
   c. If patch count < 10: incremental update (apply patches)
   d. If patch count >= 10: full update (download new .index.db)
   
4. Incremental update:
   a. Download missing patches sequentially
   b. Apply each patch in transaction
   c. On failure: rollback, fallback to full update
   d. Update schema_version on success
   
5. Full update:
   a. Download .index.db to temporary location
   b. Verify database integrity (SQLite PRAGMA integrity_check)
   c. If valid: atomic rename to replace .index.db
   d. If invalid: delete temp, continue with cached database
   
6. Error handling:
   a. Network failure: log error, continue with cached DB
   b. Corruption: log error, continue with cached DB
   c. Never block user's command on update failure
```

**Throttling mechanism**:
- Store last update check timestamp in cache directory
- File: `~/.cache/16colors-tools/ansilust/last_update_check`
- Format: Unix timestamp (seconds since epoch)
- Check on every CLI invocation, proceed only if > 3600 seconds elapsed

### Search Algorithm (FTS5)

**Full-text search flow**:

```
1. Parse user query (filename or full-text search):
   a. Simple filename: exact match first, then FTS5
   b. Complex query: direct FTS5 query
   
2. Execute FTS5 query:
   SELECT f.*, p.*, rank 
   FROM files_fts 
   JOIN files f ON files_fts.rowid = f.id
   JOIN packs p ON f.pack_id = p.id
   WHERE files_fts MATCH :query
   ORDER BY rank
   LIMIT 100
   
3. Enhance results:
   a. Check filesystem for local availability
   b. Add download URLs from database
   c. Calculate match score (FTS5 rank)
   
4. Return SearchResult array sorted by relevance
```

**Filesystem check** (local download detection):
```
For each result:
  path = ~/Pictures/16colors/packs/{year}/{pack_name}/{relative_path}
  if file_exists(path):
    result.locally_available = true
  else:
    result.locally_available = false
```

### Mirror Sync Algorithm

**Incremental sync flow**:

```
1. Load mirror configuration (.16colors-config.json)
   - Read filters, exclusions, last sync timestamp
   
2. Query database for packs to sync:
   SELECT * FROM packs
   WHERE (year >= filters.year_range.since)
     AND (filters.include_nsfw OR nsfw = 0)
     AND ...  -- Apply all filters
   ORDER BY year, name
   
3. For each pack in query results:
   a. Check if already downloaded (filesystem check)
   b. If exists and not --force: skip
   c. If not exists or --force: add to download queue
   
4. Apply file-level filters:
   a. For each file in pack (from database):
      - Check extension against include/exclude lists
      - Check for executable extensions (default exclude)
      - Track exclusion statistics
   b. Build filtered file list per pack
   
5. Execute downloads:
   a. Select protocol (RSYNC > FTP > HTTP)
   b. Download in order (sequential for now, parallel future)
   c. Display progress per pack and overall
   d. Extract ZIP after download
   e. Update sync statistics
   
6. Persist updated configuration:
   - Update last_sync timestamp
   - Update sync_stats
   - Save .16colors-config.json
```

**Dry-run mode**:
- Execute steps 1-4 (filtering and planning)
- Display what would be downloaded (pack names, sizes, counts)
- Show exclusion statistics (NSFW, executables, extensions)
- Exit without downloading

### ZIP Extraction with Security

**Path traversal prevention**:

```
1. For each entry in ZIP archive:
   a. Normalize path (resolve .., ., etc.)
   b. Ensure path does not start with / (absolute path)
   c. Ensure path does not contain .. components
   d. Construct full destination path
   e. Verify destination is within allowed directory
   
2. Security checks:
   IF normalized_path starts with '/': REJECT (absolute path)
   IF normalized_path contains '..': REJECT (parent traversal)
   IF destination_path not within base_dir: REJECT (escape attempt)
   
3. Extract if all checks pass:
   a. Create intermediate directories as needed
   b. Write file contents
   c. Preserve timestamps if available
   d. Track extracted files for indexing
```

---

## Error Handling Strategy

### Error Sets

```zig
/// Download-related errors
pub const DownloadError = error{
    NetworkFailure,
    ConnectionRefused,
    Timeout,
    HttpError,
    FtpError,
    FileNotFound,
    PermissionDenied,
    DiskFull,
    CorruptedDownload,
    InvalidUrl,
    UnsupportedProtocol,
};

/// Database-related errors
pub const DatabaseError = error{
    SchemaVersionMismatch,
    CorruptedDatabase,
    MigrationFailed,
    QueryFailed,
    OutOfMemory,
    LockTimeout,
};

/// Mirror-related errors
pub const MirrorError = error{
    InvalidConfiguration,
    FilterError,
    SyncFailed,
    InsufficientSpace,
};

/// Combined library error set
pub const LibraryError = DownloadError || DatabaseError || MirrorError || std.mem.Allocator.Error || std.fs.File.OpenError;
```

### Error Propagation Patterns

**Functions use error unions**:
```zig
pub fn downloadPack(
    allocator: Allocator,
    pack_name: []const u8,
    options: DownloadOptions
) DownloadError!void {
    // Explicit error handling, propagate with try
}

pub fn searchArchive(
    db: *ArchiveDatabase,
    query: []const u8
) DatabaseError![]SearchResult {
    // FTS5 search with explicit error handling
}
```

**Error context**:
- Store error context in stack-allocated structures
- Include relevant info: URL, file path, pack name, operation type
- Log errors with context for debugging
- Display user-friendly error messages in CLI

**Fallback strategies**:
- Protocol failure → fallback to alternative protocol
- Database update failure → continue with cached database
- Single pack download failure → continue with next pack (in batch)
- Network timeout → retry with exponential backoff (max 3 attempts)

---

## Memory Management Strategy

### Allocator Usage

**Allocator passing patterns**:
```zig
// Explicit allocator for all allocations
pub fn init(allocator: Allocator) !Self {
    // Store allocator in struct
    return Self{ .allocator = allocator };
}

// Caller-owned memory (common for queries)
pub fn searchArchive(
    allocator: Allocator,  // Results allocated with this
    db: *ArchiveDatabase,
    query: []const u8
) ![]SearchResult {
    // Caller must deinit results
}

// Self-owned memory (cleanup with deinit)
pub const HttpClient = struct {
    allocator: Allocator,
    buffer: []u8,
    
    pub fn deinit(self: *HttpClient) void {
        self.allocator.free(self.buffer);
    }
};
```

**Resource cleanup patterns**:
```zig
// defer for success path cleanup
pub fn downloadPack(...) !void {
    const temp_file = try fs.createFile(temp_path, .{});
    defer temp_file.close();  // Always close
    
    // Download to temp_file...
}

// errdefer for error path cleanup
pub fn extractZip(...) !void {
    const entries = try allocator.alloc(Entry, count);
    errdefer allocator.free(entries);  // Free on error
    
    // Process entries...
    // On success, caller owns entries
}

// Combined defer + errdefer for complex resources
pub fn syncMirror(...) !void {
    var state = try State.init(allocator);
    defer state.deinit();      // Cleanup on success
    errdefer state.cleanup();  // Rollback on error
}
```

### Memory Allocation Patterns

**Arena allocator for request-scoped allocations**:
```zig
pub fn handleCliCommand(allocator: Allocator, args: []const []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();  // Free all at once
    
    const arena_alloc = arena.allocator();
    // All CLI-command allocations use arena_alloc
    // Automatic cleanup on function return
}
```

**Pooled allocations for long-lived resources**:
```zig
pub const DatabaseManager = struct {
    allocator: Allocator,
    query_buffer_pool: BufferPool,
    
    pub fn executeQuery(self: *DatabaseManager, query: []const u8) ![]Row {
        const buffer = try self.query_buffer_pool.acquire();
        defer self.query_buffer_pool.release(buffer);
        // Reuse buffer across queries
    }
};
```

**Ownership rules**:
- **Caller-owned**: Search results, query outputs (caller must free)
- **Self-owned**: Internal buffers, caches (freed in deinit)
- **Arena-owned**: Temporary CLI command data (auto-freed)
- **Database-owned**: Database connections, prepared statements

---

## Testing Approach

### Test Categories

#### Unit Tests
**What to test**:
- Platform path resolution (Linux, macOS, Windows)
- URL construction (pack URLs, file URLs, PNG URLs)
- Filter logic (NSFW, executables, extensions, year ranges)
- SAUCE metadata parsing
- Database query builders
- Error handling for each module

**Test structure**:
```zig
test "Platform.getPaths returns correct paths on Linux" {
    const allocator = testing.allocator;
    const platform = Platform.linux;
    
    const paths = try platform.getPaths(allocator);
    defer allocator.free(paths.sixteen_colors_root);
    defer allocator.free(paths.cache_dir);
    
    try testing.expect(std.mem.endsWith(u8, paths.sixteen_colors_root, ".local/share/16colors"));
}

test "MirrorFilters excludes NSFW by default" {
    const filters = MirrorFilters{};
    
    try testing.expectEqual(false, filters.include_nsfw);
    try testing.expectEqual(false, filters.include_executables);
}
```

#### Integration Tests
**What to test**:
- Download complete pack via HTTP (use test server or fixture)
- Extract ZIP and verify structure
- Database operations (create, query, update, FTS5 search)
- Protocol fallback (HTTP fails → FTP succeeds)
- Mirror sync with filters (dry-run vs actual)
- Configuration persistence (save/load)

**Test fixtures**:
- Mock HTTP server (return canned responses)
- Sample ZIP files (small test packs)
- Sample SQLite database (pre-populated with test data)
- Temporary directories (isolated test environments)

#### System Tests
**What to test**:
- End-to-end CLI workflows (`16c download`, `16c search`, etc.)
- Cross-platform compatibility (run on Linux, macOS, Windows)
- Performance benchmarks (large pack download, FTS5 search)
- Error recovery (network failures, disk full, corrupted files)
- Concurrent access (multiple tools using .index.db)

### Test Execution Strategy

**Test isolation**:
- Each test uses temporary directories
- Database tests use in-memory SQLite (`:memory:`)
- Network tests use mock servers or recorded responses
- No tests depend on external services (16colo.rs)

**Memory leak detection**:
```zig
test "downloadPack does not leak memory" {
    const allocator = testing.allocator;  // Leak detection
    
    try downloadPack(allocator, "test-pack", .{});
    
    // testing.allocator will fail test if leaks detected
}
```

**Performance benchmarks**:
```zig
test "FTS5 search completes in < 500ms" {
    const start = std.time.milliTimestamp();
    
    const results = try db.searchArchive(allocator, "dragon");
    defer allocator.free(results);
    
    const duration = std.time.milliTimestamp() - start;
    try testing.expect(duration < 500);
}
```

---

## Integration Points

### Existing Ansilust Codebase

**Parser integration**:
```zig
// From ansilust parsers module
const parsers = @import("parsers");

pub fn validateDownloadedFile(file_path: []const u8) !void {
    // Use ansilust parser to validate format
    const format = try parsers.detectFormat(file_path);
    const valid = try parsers.validate(file_path, format);
    
    if (!valid) {
        return error.InvalidFormat;
    }
}
```

**Renderer integration**:
```zig
// From ansilust renderers module
const renderers = @import("renderers");

pub fn displayArtwork(file_path: []const u8, format: Format) !void {
    // Render using ansilust utf8ansi renderer
    const renderer = renderers.Utf8AnsiRenderer.init(allocator);
    try renderer.renderFile(file_path);
}
```

### Third-Party Tool Integration

**Database schema documentation**:
- Publish schema at `https://ansilust.com/.well-known/schemas/index-db-schema-v1.sql`
- Include comments explaining each table and field
- Provide example queries for common operations

**Event emission** (future):
```zig
pub const DownloadEvent = union(enum) {
    pack_downloaded: struct { pack_name: []const u8, path: []const u8 },
    database_updated: struct { old_version: u32, new_version: u32 },
    artwork_available: struct { file: ArtFile, pack: Pack },
};

pub const EventCallback = fn (event: DownloadEvent) void;

pub fn registerCallback(callback: EventCallback) void {
    // Allow screensavers, viewers to hook into events
}
```

---

## Performance Considerations

### Expected Performance Characteristics

**Database operations**:
- Simple queries (pack by name): < 10ms
- FTS5 search (entire archive): < 500ms
- Database update check: < 1s (network-bound)
- Patch application: < 100ms per patch

**Download operations**:
- HTTP pack download: Network-bound (aim for > 1MB/s throughput)
- Resume support: Negligible overhead (Range header)
- ZIP extraction: > 10MB/s (I/O-bound, not CPU)

**Memory usage**:
- Database: < 100MB (entire .index.db loaded into memory by SQLite)
- HTTP client: < 10MB (streaming downloads, 8KB buffer)
- ZIP extraction: < 2x largest file size (decompress buffer)
- CLI command: < 50MB total (arena allocator for request)

### Optimization Strategies

**Database optimizations**:
- Create indexes on frequently queried fields (year, artist, extension)
- Use prepared statements for repeated queries
- Enable SQLite WAL mode (concurrent reads)
- Vacuum database periodically (reclaim space)

**Network optimizations**:
- Connection pooling for FTP (reuse connections)
- HTTP keep-alive (multiple requests per connection)
- Streaming downloads (no buffer entire file)
- Resume support (avoid re-downloading)

**Filesystem optimizations**:
- Batch filesystem operations (create all directories first)
- Use memory-mapped files for large ZIP extraction (future)
- Preallocate file space before download (avoid fragmentation)

---

## API Surface

### Public Library API

#### Core Functions

```zig
/// Initialize 16colors download library
pub fn init(allocator: Allocator) !Library {
    // Detect platform, resolve paths, open database
}

/// Search archive for files
pub fn searchArchive(
    lib: *Library,
    query: []const u8
) ![]SearchResult {
    // FTS5 full-text search
}

/// Download a pack by name
pub fn downloadPack(
    lib: *Library,
    pack_name: []const u8,
    options: DownloadOptions
) !void {
    // Automatic protocol selection, progress tracking
}

/// Sync mirror with filters
pub fn syncMirror(
    lib: *Library,
    filters: MirrorFilters,
    dry_run: bool
) !SyncStats {
    // Incremental sync, apply filters, return statistics
}

/// Get pack information from database
pub fn getPack(
    lib: *Library,
    pack_name: []const u8
) !Pack {
    // Query database for pack metadata
}

/// List packs matching criteria
pub fn listPacks(
    lib: *Library,
    filters: struct {
        year: ?u16 = null,
        group: ?[]const u8 = null,
        artist: ?[]const u8 = null,
    }
) ![]Pack {
    // Filtered pack listing
}
```

#### CLI Commands API

```zig
/// CLI command handler (internal, not public library API)
pub const Commands = struct {
    /// Execute 16c download command
    pub fn download(args: []const []const u8) !void;
    
    /// Execute 16c search command
    pub fn search(args: []const []const u8) !void;
    
    /// Execute 16c list command
    pub fn list(args: []const []const u8) !void;
    
    /// Execute 16c mirror command
    pub fn mirror(args: []const []const u8) !void;
    
    /// Execute 16c stats command
    pub fn stats(args: []const []const u8) !void;
};
```

---

## Security Considerations

### Path Traversal Prevention

**ZIP extraction security**:
- Validate all paths before extraction
- Reject absolute paths (starting with `/`)
- Reject parent references (`..`)
- Ensure destination within allowed directory

**Input sanitization**:
- Validate pack names (alphanumeric, hyphen, underscore only)
- Reject paths with null bytes
- Limit filename length (max 255 characters)

### Network Security

**HTTPS certificate validation**:
- Use system CA certificates
- Never disable certificate verification
- Fail download on certificate errors

**FTP security**:
- Use explicit TLS (FTPS) if available
- Fall back to plain FTP only if necessary
- Warn user if using insecure connection

### Resource Limits

**ZIP bomb protection**:
- Limit maximum extracted size (e.g., 10GB)
- Limit maximum file count per archive (e.g., 10,000 files)
- Monitor disk space before extraction
- Abort if limits exceeded

**Memory limits**:
- Streaming downloads (no buffer entire file)
- Incremental ZIP extraction (process entry-by-entry)
- Database query result limits (max 1000 results)

---

## Design Decisions and Rationale

### Key Decisions

**Decision 1: SQLite for .index.db**
- **Rationale**: Mature, fast, embedded, supports FTS5 and JSON
- **Alternatives considered**: Custom binary format, JSON files
- **Trade-offs**: External dependency (SQLite C library), but gains performance and features

**Decision 2: Auto-update by default (no opt-out)**
- **Rationale**: Zero-friction UX, users don't think about database updates
- **Alternatives considered**: Manual updates, opt-in auto-update
- **Trade-offs**: Opinionated, but aligns with modern tools (brew, apt, npm)

**Decision 3: Dual CLI (16c + ansilust)**
- **Rationale**: Eliminates context ambiguity (archive vs local file)
- **Alternatives considered**: Single CLI with flags, single CLI with auto-detection
- **Trade-offs**: Two executables, but clearer user mental model

**Decision 4: Platform-specific paths (Pictures/ on macOS/Windows)**
- **Rationale**: User-browsable artwork, follows OS conventions
- **Alternatives considered**: Hidden directories (~/.local/share everywhere)
- **Trade-offs**: Platform-specific code, but better UX for non-technical users

**Decision 5: Filesystem for download state, database for archive index**
- **Rationale**: Simple, fast, no sync issues
- **Alternatives considered**: Track downloads in database
- **Trade-offs**: No centralized "what's downloaded" query, but simpler implementation

**Decision 6: Default exclusions (NSFW, executables)**
- **Rationale**: Safety and security for public/institutional use
- **Alternatives considered**: Include everything by default
- **Trade-offs**: Requires explicit opt-in, but safer default

---

## Open Questions for Implementation Phase

**Protocol Selection**:
- What is the actual performance difference between HTTP, FTP, RSYNC?
- Should we implement HTTP/2 support?
- How does RSYNC bandwidth limiting work in practice?

**Database**:
- Should we use sqlite3 C library (FFI) or pure Zig implementation (if available)?
- What is the optimal FTS5 tokenizer configuration for artwork filenames?
- Should we support database compression (smaller .index.db)?

**FTP Client**:
- Implement custom FTP client in Zig or use C library?
- How do we handle different FTP server list formats?

**Concurrency**:
- Should mirror sync download multiple packs in parallel?
- What is the optimal concurrency level (connection limit)?
- How do we handle progress reporting for parallel downloads?

**Error Recovery**:
- How many retry attempts for network failures?
- What is the exponential backoff strategy?
- Should we implement circuit breaker pattern for repeated failures?

---

## Phase 3: Design Phase - Complete

This design document provides the technical architecture for the 16colors download client. It focuses on structure, patterns, and approach without full implementation code. The design follows Zig best practices for memory safety, explicit error handling, and performance.

**Next Phase**: Phase 4 - Plan Phase (create detailed implementation roadmap)

**Key Deliverables**:
- ✅ Architecture overview with component relationships
- ✅ Module organization and dependency flow
- ✅ Data structure descriptions (no full implementations)
- ✅ Algorithm approaches (high-level pseudocode)
- ✅ Error handling strategy with error sets
- ✅ Memory management patterns and ownership rules
- ✅ Testing approach and categories
- ✅ Integration points with existing codebase
- ✅ Performance considerations and optimization strategies
- ✅ API surface descriptions (interfaces, not implementations)
- ✅ Security considerations and mitigation strategies
- ✅ Design decisions with rationale

**Ready for user review and authorization to proceed to Plan Phase.**
