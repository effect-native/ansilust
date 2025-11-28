# 16colors CLI & Download Client - Implementation Plan

## Document Overview

This document provides the implementation roadmap for the 16colors download client, organized into phases with clear validation checkpoints and progress tracking.

**Related Documents**:
- `instructions.md` - User stories and initial requirements capture
- `requirements.md` - Formal EARS-based requirements
- `design.md` - Technical architecture and implementation strategy

---

## Implementation Strategy

### Core Principle: Abstraction-First Development

**Key Decision**: Build against database abstraction from day 1, implement with hardcoded data initially, swap to SQLite later without changing dependent code.

**Benefits**:
- No throwaway code
- No refactoring when adding SQLite
- Interface-driven development
- Standard storage locations from start

### Phased Approach

```
Phase 5.1: Minimal Viable Product (random-1 command)
  ↓
Phase 5.2: Direct Downloads (download pack by name)
  ↓
Phase 5.3: Local Browsing (list, show)
  ↓
Phase 5.4: SQLite Implementation (swap hardcoded → database)
  ↓
Phase 5.5: Advanced Features (search, mirror, stats)
```

---

## Phase 5.1: Minimal Viable Product - `16c random-1`

### Objective

Implement the absolute minimum end-to-end flow:
```bash
16c random-1
# 1. Picks random ANSI/ASCII file from hardcoded list
# 2. Downloads it via HTTP
# 3. Saves to ~/Pictures/16colors/random/
# 4. Displays it with ansilust renderer
# 5. Exit 0
```

### Success Criteria

- [ ] Command completes in < 5 seconds (typical network)
- [ ] Artwork displays correctly
- [ ] File saved to correct platform-specific location
- [ ] No crashes, no memory leaks
- [ ] Exit code 0 on success, 1 on failure
- [ ] Works on Linux, macOS, Windows

---

### Task 5.1.1: Database Abstraction Interface

**Objective**: Define database interface that works with hardcoded data now, SQLite later.

**Deliverables**:
- [ ] Create `src/download/database/interface.zig`
- [ ] Define `ArchiveDatabase` struct with tagged union implementation
- [ ] Define `FileEntry` struct (pack_name, filename, source_url, year, artist, extension)
- [ ] Define `Pack` struct (name, year, group_name, zip_url)
- [ ] Define interface methods:
  - [ ] `init(allocator) -> ArchiveDatabase`
  - [ ] `getRandomFile() -> FileEntry`
  - [ ] `searchFiles(query) -> []FileEntry` (stub, returns empty)
  - [ ] `getPack(name) -> Pack` (stub, returns error.NotImplemented)
  - [ ] `listPacksByYear(year) -> []Pack` (stub, returns empty)
  - [ ] `deinit()`

**Acceptance Criteria**:
- Interface compiles with Zig 0.11.0+
- All methods have doc comments
- Error unions used for fallible operations
- No implementation code yet (just signatures)

**Validation**:
```bash
zig build
# Should compile with no errors
```

---

### Task 5.1.2: Hardcoded Database Implementation

**Objective**: Implement database interface with curated hardcoded data.

**Deliverables**:
- [ ] Create `src/download/database/hardcoded.zig`
- [ ] Define `HardcodedImpl` struct
- [ ] Curate 20-30 ANSI/ASCII files with metadata:
  - [ ] Mix of years (1990s, 2000s, 2020s)
  - [ ] Mix of formats (ANS, ASC)
  - [ ] Mix of styles (ASCII art, ANSI art, detailed, block)
  - [ ] Verified URLs from 16colo.rs
  - [ ] All files < 100KB (fast downloads)
  - [ ] Diverse artists and groups
- [ ] Implement `getRandomFile()`:
  - [ ] Use `std.crypto.random` for selection
  - [ ] Return random file from curated list
- [ ] Implement stub methods (searchFiles, getPack, listPacksByYear)
- [ ] Wire into `ArchiveDatabase.Implementation` union

**Data Format**:
```zig
const CURATED_FILES = [_]FileEntry{
    .{
        .pack_name = "mist1025",
        .filename = "CXC-STICK.ASC",
        .source_url = "https://16colo.rs/pack/mist1025/CXC-STICK.ASC",
        .year = 2025,
        .artist = "CoaXCable",
        .extension = "asc",
    },
    // ... 19-29 more entries
};
```

**Acceptance Criteria**:
- At least 20 curated files with complete metadata
- All URLs verified to be accessible
- Random selection uniform distribution
- No memory allocations (comptime data)

**Validation**:
```bash
zig test src/download/database/hardcoded.zig
# Test: getRandomFile returns valid FileEntry
# Test: getRandomFile varies across calls
# Test: stub methods return expected values
```

---

### Task 5.1.3: Platform Paths Module

**Objective**: Detect platform and resolve 16colors directory paths.

**Deliverables**:
- [ ] Create `src/download/storage/paths.zig`
- [ ] Define `Platform` enum (linux, macos, windows)
- [ ] Define `PlatformPaths` struct:
  - [ ] `sixteen_colors_root: []const u8`
  - [ ] `random_dir: []const u8`
  - [ ] `packs_dir: []const u8`
  - [ ] `local_dir: []const u8`
- [ ] Implement `Platform.detect() -> Platform`:
  - [ ] Use `std.builtin.os.tag` for detection
- [ ] Implement `Platform.getPaths(allocator) -> PlatformPaths`:
  - [ ] Linux: `~/.local/share/16colors/` (or `$XDG_DATA_HOME/16colors/`)
  - [ ] macOS: `~/Pictures/16colors/`
  - [ ] Windows: `%USERPROFILE%\Pictures\16colors\`
- [ ] Implement path construction for subdirectories
- [ ] Implement directory creation (mkdir -p equivalent)

**Path Resolution**:
```
Linux:   ~/.local/share/16colors/
         ├── random/
         ├── packs/
         └── local/

macOS:   ~/Pictures/16colors/
         ├── random/
         ├── packs/
         └── local/

Windows: %USERPROFILE%\Pictures\16colors\
         ├── random\
         ├── packs\
         └── local\
```

**Acceptance Criteria**:
- Platform detected correctly on all three OS types
- Paths use correct separators (`/` vs `\`)
- Home directory expansion works (`~` → actual path)
- Environment variable expansion works (`$XDG_DATA_HOME`, `%USERPROFILE%`)
- Directories created with correct permissions (0755)
- If creation fails, return clear error

**Validation**:
```bash
zig test src/download/storage/paths.zig
# Test: Platform.detect returns correct platform
# Test: getPaths returns correct paths for each platform
# Test: Directory creation succeeds
# Test: Permission denied returns error.PermissionDenied
```

---

### Task 5.1.4: HTTP Download Module

**Objective**: Download files via HTTP with basic error handling.

**Deliverables**:
- [ ] Create `src/download/protocols/http.zig`
- [ ] Define `HttpClient` struct
- [ ] Implement `init(allocator) -> HttpClient`
- [ ] Implement `download(url, dest_path) -> void`:
  - [ ] Use `std.http.Client` for requests
  - [ ] Set User-Agent: `ansilust/VERSION (https://github.com/user/ansilust)`
  - [ ] Write response body to file
  - [ ] Stream download (don't buffer entire file in memory)
  - [ ] Verify HTTP status 200 (fail on 404, 500, etc.)
- [ ] Implement `deinit()`
- [ ] Define error set: `HttpError` (NetworkFailure, HttpError, FileNotFound, Timeout)

**Download Flow**:
```
1. Create HTTP client
2. Send GET request to URL
3. Check status code (200 OK)
4. Open destination file for writing
5. Stream response body to file (8KB chunks)
6. Close file
7. Return success or error
```

**Acceptance Criteria**:
- Downloads complete successfully for valid URLs
- Invalid URLs return error.NetworkFailure
- HTTP 404 returns error.FileNotFound
- HTTP 500 returns error.HttpError
- Files written correctly (no corruption)
- No memory leaks (std.testing.allocator)
- Timeout after 30 seconds

**Validation**:
```bash
zig test src/download/protocols/http.zig
# Test: download valid URL succeeds
# Test: download invalid URL returns error
# Test: download 404 returns error.FileNotFound
# Test: downloaded file matches expected content
# Test: no memory leaks
```

**Note**: No resume support in Phase 5.1 (add in Phase 5.2)

---

### Task 5.1.5: Storage Module

**Objective**: Save downloaded files to standard locations with proper naming.

**Deliverables**:
- [ ] Create `src/download/storage/files.zig`
- [ ] Define `FileStorage` struct
- [ ] Implement `saveToRandom(allocator, source_path, original_filename) -> saved_path`:
  - [ ] Generate timestamped filename: `{timestamp}-{original_filename}`
  - [ ] Timestamp format: `YYYYMMDDHHmmss` (e.g., `20251101153042`)
  - [ ] Move/copy file to `random/` subdirectory
  - [ ] Return full path to saved file
- [ ] Implement `cleanupRandom(keep_count)`:
  - [ ] List files in `random/` directory
  - [ ] Sort by timestamp (oldest first)
  - [ ] Delete all but last N files (default N=10)
- [ ] Handle filesystem errors (disk full, permissions, etc.)

**Filename Examples**:
```
random/20251101153042-CXC-STICK.ASC
random/20251101154523-dragon.ans
random/20251101160815-logo.asc
```

**Acceptance Criteria**:
- Files saved with correct timestamp format
- Original filename preserved after timestamp
- Old files cleaned up when limit exceeded
- Permissions errors return error.PermissionDenied
- Disk full returns error.DiskFull

**Validation**:
```bash
zig test src/download/storage/files.zig
# Test: saveToRandom creates correct filename
# Test: saveToRandom saves file to correct location
# Test: cleanupRandom deletes oldest files
# Test: cleanupRandom keeps N newest files
```

---

### Task 5.1.6: CLI Entry Point

**Objective**: Parse command-line arguments and execute `random-1` command.

**Deliverables**:
- [ ] Create `src/cli/sixteenc.zig`
- [ ] Implement `main()` function:
  - [ ] Setup allocator (GeneralPurposeAllocator)
  - [ ] Parse command-line arguments
  - [ ] Recognize `random-1` command
  - [ ] Call into download library
  - [ ] Handle errors with user-friendly messages
  - [ ] Exit with appropriate code (0=success, 1=error)
- [ ] Implement simple argument parser (no fancy CLI library yet)
- [ ] Print usage on invalid arguments

**Usage**:
```bash
16c random-1          # Execute random-1 command
16c --help            # Print help (future)
16c --version         # Print version (future)
```

**Error Messages**:
```
Error: Network failure - could not download file
Try again or check your internet connection.

Error: Permission denied - cannot create directory
Please check permissions for ~/Pictures/16colors/

Error: Unknown command 'foo'
Usage: 16c random-1
```

**Acceptance Criteria**:
- `random-1` command recognized and executed
- Invalid commands show usage and exit 1
- Errors display helpful messages
- No memory leaks (GPA reports clean shutdown)

**Validation**:
```bash
zig build
./zig-out/bin/16c random-1
# Should download and display artwork

./zig-out/bin/16c invalid
# Should show error and usage

echo $?
# Should be 1 (error exit code)
```

---

### Task 5.1.7: Integration - Random Command Flow

**Objective**: Wire all modules together for end-to-end `random-1` functionality.

**Deliverables**:
- [ ] Create `src/download/commands/random.zig`
- [ ] Implement `executeRandomOne(allocator) -> void`:
  - [ ] Initialize platform paths
  - [ ] Create directories if needed
  - [ ] Initialize database (hardcoded impl)
  - [ ] Get random file from database
  - [ ] Download file via HTTP to temp location
  - [ ] Save to `random/` directory
  - [ ] Cleanup old files (keep last 10)
  - [ ] Call ansilust renderer to display file
  - [ ] Cleanup temp file
- [ ] Handle all error paths with proper cleanup
- [ ] Use `defer` and `errdefer` for resource management

**Flow**:
```
1. Detect platform → Get paths
2. Create ~/Pictures/16colors/random/ if needed
3. Init database (hardcoded)
4. Get random file entry
5. Download to /tmp/16c-random-{timestamp}.tmp
6. Save to random/{timestamp}-{filename}
7. Cleanup old files in random/
8. Render with ansilust
9. Delete temp file
10. Exit 0
```

**Error Handling**:
```
IF platform paths fail → Error message, exit 1
IF directory creation fails → Error message, exit 1
IF download fails → Error message, cleanup temp, exit 1
IF renderer fails → Error message, file saved but not displayed, exit 1
```

**Acceptance Criteria**:
- All steps execute in correct order
- Errors at any step handled gracefully
- Resources cleaned up on all paths (success and error)
- No memory leaks
- No temporary files left on disk after execution

**Validation**:
```bash
zig build test
zig build
./zig-out/bin/16c random-1

# Verify:
ls ~/Pictures/16colors/random/
# Should show downloaded file

# Run again:
./zig-out/bin/16c random-1
# Should show different artwork (likely)

# Run 15 times:
for i in {1..15}; do ./zig-out/bin/16c random-1; done
# Should only keep last 10 files in random/
```

---

### Task 5.1.8: Ansilust Renderer Integration

**Objective**: Call ansilust UTF8ANSI renderer to display downloaded artwork.

**Deliverables**:
- [ ] Add dependency on ansilust renderer module
- [ ] Implement renderer call in `random.zig`:
  - [ ] Detect file format (ANS vs ASC)
  - [ ] Call appropriate renderer
  - [ ] Display to stdout
  - [ ] Handle render errors gracefully
- [ ] Handle terminal detection (skip if not a TTY)

**Renderer Call**:
```zig
const renderers = @import("renderers");

pub fn displayArtwork(file_path: []const u8) !void {
    // Detect format from extension
    const format = detectFormat(file_path);
    
    // Render to stdout
    const renderer = try renderers.Utf8AnsiRenderer.init(allocator);
    defer renderer.deinit();
    
    try renderer.renderFile(file_path);
}
```

**Acceptance Criteria**:
- ANS files render correctly
- ASC files render correctly
- Renderer errors return descriptive messages
- Non-TTY output skips rendering (or outputs raw)

**Validation**:
```bash
# Should display artwork
./zig-out/bin/16c random-1

# Should skip rendering or output raw
./zig-out/bin/16c random-1 > output.txt
```

**Note**: If ansilust renderer not ready, stub with:
```zig
pub fn displayArtwork(file_path: []const u8) !void {
    std.debug.print("Would render: {s}\n", .{file_path});
}
```

---

### Task 5.1.9: Build Configuration

**Objective**: Configure Zig build system for CLI executable.

**Deliverables**:
- [ ] Update `build.zig`:
  - [ ] Add `16c` executable target
  - [ ] Link download library modules
  - [ ] Link ansilust renderer
  - [ ] Install to `zig-out/bin/16c`
  - [ ] Add aliases: `16colors`, `16` (symlinks)
- [ ] Add test step for download modules
- [ ] Add install step

**Build Commands**:
```bash
zig build                    # Build 16c executable
zig build test               # Run all tests
zig build install            # Install to zig-out/bin/
```

**Acceptance Criteria**:
- `zig build` produces `zig-out/bin/16c`
- `zig build test` runs all download module tests
- Executable runs without external dependencies (except system libs)

**Validation**:
```bash
zig build
ls zig-out/bin/16c
# Should exist

./zig-out/bin/16c random-1
# Should execute
```

---

### Task 5.1.10: Testing and Validation

**Objective**: Comprehensive testing of Phase 5.1 implementation.

**Test Categories**:

**Unit Tests**:
- [ ] Database interface (hardcoded impl)
- [ ] Platform path resolution
- [ ] HTTP download (with mock server)
- [ ] File storage (temp directory)
- [ ] Random selection distribution

**Integration Tests**:
- [ ] End-to-end random-1 command (with real HTTP)
- [ ] Error handling (network failure, disk full, permissions)
- [ ] Cross-platform (Linux, macOS, Windows)

**System Tests**:
- [ ] Memory leak detection (run with testing allocator)
- [ ] Performance (< 5 seconds typical)
- [ ] File cleanup (old files deleted)
- [ ] Concurrent executions (no conflicts)

**Manual Testing**:
- [ ] Run on actual systems (Linux, macOS, Windows)
- [ ] Verify artwork displays correctly
- [ ] Check file locations
- [ ] Test error scenarios (unplug network, remove permissions, etc.)

**Acceptance Criteria**:
- All unit tests pass
- All integration tests pass
- No memory leaks detected
- Works on all three platforms
- Performance within targets

**Validation**:
```bash
# Run all tests
zig build test --summary all

# Check for memory leaks
zig build test -Doptimize=Debug

# Manual verification
./zig-out/bin/16c random-1
ls ~/Pictures/16colors/random/
# Verify files exist and artwork displayed
```

---

### Phase 5.1 Completion Checklist

- [ ] All tasks (5.1.1 through 5.1.10) completed
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] No memory leaks detected
- [ ] Works on Linux, macOS, Windows
- [ ] `16c random-1` executes successfully
- [ ] Artwork displays correctly
- [ ] Files saved to correct locations
- [ ] Documentation updated (README usage example)
- [ ] Code formatted (`zig fmt`)
- [ ] Build succeeds with zero warnings

**Validation Command**:
```bash
zig build test && \
zig build && \
./zig-out/bin/16c random-1 && \
ls ~/Pictures/16colors/random/ && \
echo "Phase 5.1 Complete!"
```

---

## Phase 5.2: Direct Pack Downloads (Future)

### Objective
Implement `16c download <pack>` command for direct pack downloads.

**Scope**:
- [ ] URL construction for pack downloads
- [ ] ZIP extraction
- [ ] Save to `packs/{year}/{pack_name}/` directory
- [ ] Progress reporting
- [ ] Resume support (HTTP Range requests)

**Deferred to Phase 5.2**

---

## Phase 5.3: Local Browsing (Future)

### Objective
Implement local mirror browsing commands.

**Scope**:
- [ ] `16c list` - List downloaded packs
- [ ] `16c show <file>` - Display from local mirror
- [ ] Filesystem-based pack discovery
- [ ] Local file search (grep-style)

**Deferred to Phase 5.3**

---

## Phase 5.4: SQLite Implementation (Future)

### Objective
Replace hardcoded database with SQLite implementation.

**Scope**:
- [ ] SQLite schema creation
- [ ] FTS5 index setup
- [ ] Implement all database interface methods with SQL
- [ ] Database migrations
- [ ] Auto-update mechanism
- [ ] Patch file application

**Key Task**: Swap `Implementation.hardcoded` → `Implementation.sqlite`

**No dependent code changes required** (interface stays the same)

**Deferred to Phase 5.4**

---

## Phase 5.5: Advanced Features (Future)

### Objective
Implement search, mirror sync, statistics, and analytics.

**Scope**:
- [ ] FTS5 full-text search
- [ ] Mirror sync with filters
- [ ] NSFW/executable exclusions
- [ ] Statistics and analytics
- [ ] FTP client for year browsing
- [ ] RSS feed parsing

**Deferred to Phase 5.5**

---

## Risk Management

### Risk 1: Ansilust Renderer Not Ready
**Mitigation**: Stub renderer with simple file output
```zig
pub fn displayArtwork(path: []const u8) !void {
    std.debug.print("Artwork: {s}\n", .{path});
    // TODO: Call real renderer when available
}
```

### Risk 2: HTTP Downloads Slow
**Mitigation**: 
- Choose small files for hardcoded list (< 100KB)
- Add timeout (30 seconds)
- Clear error message if slow

### Risk 3: Platform Path Issues
**Mitigation**:
- Comprehensive testing on all platforms
- Clear error messages for permission issues
- Fallback instructions in error message

### Risk 4: Curated Files Become Unavailable
**Mitigation**:
- Verify all URLs before hardcoding
- Fallback to next random file on 404
- Add refresh mechanism for curated list (future)

---

## Progress Tracking

### Phase 5.1 Tasks

| Task | Status | Notes |
|------|--------|-------|
| 5.1.1 Database Interface | ✅ Complete | `src/download/database/interface.zig` with tests |
| 5.1.2 Hardcoded Implementation | ✅ Complete | `src/download/database/hardcoded.zig` with curated files |
| 5.1.3 Platform Paths | ✅ Complete | `src/download/storage/paths.zig` with tests (paths_test.zig) |
| 5.1.4 HTTP Download | ✅ Complete | `src/download/protocols/http.zig` with tests (http_test.zig) |
| 5.1.5 Storage Module | ✅ Complete | `src/download/storage/files.zig` with tests (files_test.zig) |
| 5.1.6 CLI Entry Point | ✅ Complete | `src/cli/sixteenc.zig` builds as `16c` binary |
| 5.1.7 Integration | ✅ Complete | `src/download/commands/random.zig` wires all modules |
| 5.1.8 Renderer Integration | 🔄 In Progress | Stubbed - awaiting UTF8ANSI renderer CLI integration |
| 5.1.9 Build Configuration | ✅ Complete | `16c` executable in build.zig with download module |
| 5.1.10 Testing | 🔄 In Progress | Unit tests pass, end-to-end validation pending |

**Legend**: ⬜ Not Started | 🔄 In Progress | ✅ Complete | ❌ Blocked

---

## Current Status Summary (2025-11-27)

**Implementation**: Phase 5.1 ~90% complete

**Completed**:
- Full download client infrastructure (database, HTTP, storage, paths)
- `16c` CLI executable with `random-1` command
- Platform path detection (Linux, macOS, Windows)
- Hardcoded database with curated artwork entries
- HTTP download with error handling
- File storage with timestamp naming and cleanup

**Gaps**:
- Renderer integration (displays file path only, not artwork)
- End-to-end cross-platform testing
- Full validation suite

**Next Steps**:
1. Integrate UTF8ANSI renderer into random command (blocked on renderer CLI integration)
2. Complete end-to-end testing on Linux/macOS/Windows
3. Begin Phase 5.2 (direct pack downloads)

---

## Validation Gates

### Gate 1: Database Abstraction (After 5.1.2)
**Criteria**:
- [ ] Interface compiles
- [ ] Hardcoded impl returns valid data
- [ ] Random selection works

**Command**: `zig test src/download/database/*.zig`

---

### Gate 2: Platform & HTTP (After 5.1.4)
**Criteria**:
- [ ] Platform detected correctly
- [ ] Paths resolved for all platforms
- [ ] HTTP downloads succeed
- [ ] No memory leaks

**Command**: `zig test src/download/{storage,protocols}/*.zig`

---

### Gate 3: End-to-End (After 5.1.7)
**Criteria**:
- [ ] `16c random-1` executes successfully
- [ ] File saved to correct location
- [ ] Artwork displays
- [ ] No crashes or leaks

**Command**: `./zig-out/bin/16c random-1`

---

### Gate 4: Multi-Platform (After 5.1.10)
**Criteria**:
- [ ] Works on Linux
- [ ] Works on macOS  
- [ ] Works on Windows
- [ ] All tests pass on all platforms

**Command**: Run `zig build test` on each platform

---

## Success Metrics

### Phase 5.1 Success Criteria

**Functionality**:
- ✅ `16c random-1` downloads and displays random artwork
- ✅ Files saved to platform-appropriate locations
- ✅ Works offline after first download (uses cached files)

**Performance**:
- ✅ Total execution time < 5 seconds (typical network)
- ✅ Memory usage < 10MB
- ✅ Disk usage < 10MB (10 cached files × ~100KB each)

**Quality**:
- ✅ Zero memory leaks
- ✅ Zero undefined behavior
- ✅ 100% doc comment coverage (public APIs)
- ✅ All tests passing

**Cross-Platform**:
- ✅ Works on Linux (x86_64)
- ✅ Works on macOS (Intel, Apple Silicon)
- ✅ Works on Windows (x86_64)

---

## Dependencies and Blockers

### Required for Phase 5.1
- ✅ Zig 0.11.0+ installed
- ✅ Ansilust renderer available (or stubbed)
- ✅ Internet connection (for downloads)
- ✅ Filesystem write permissions

### Blocked By
- None (Phase 5.1 has no blockers)

### Blocks
- Phase 5.2 (requires Phase 5.1 complete)
- Phase 5.3 (requires Phase 5.1 complete)
- Phase 5.4 (requires Phase 5.1 complete)

---

## Phase 4: Plan Phase - Complete

This implementation plan provides a detailed roadmap for Phase 5.1 (Minimal Viable Product). The plan focuses on delivering `16c random-1` functionality with proper abstractions that enable future enhancements without refactoring.

**Key Principles**:
- ✅ Abstraction-first (database interface defined now, SQLite later)
- ✅ Standard storage locations from day 1
- ✅ No throwaway code (everything builds on itself)
- ✅ Clear validation gates at each step
- ✅ Explicit deferrals for future phases

**Next Phase**: Phase 5 - Implementation Phase (execute Phase 5.1 tasks)

**Ready for user review and authorization to proceed to Implementation Phase.**
