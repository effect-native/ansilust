# 16colors CLI & Download Client - Requirements Specification

## Document Overview

This document provides formal, structured requirements for the 16colors download client using EARS (Easy Approach to Requirements Syntax) notation. All functional requirements use EARS patterns for clarity and testability.

**Related Documents**:
- `instructions.md` - User stories and initial requirements capture
- `design.md` - Technical design and architectural decisions (Phase 3)
- `plan.md` - Implementation roadmap (Phase 4)

---

## FR1: Functional Requirements

### FR1.1: Download Management

**FR1.1.1**: The system shall download complete artpacks from 16colo.rs by pack name.

**FR1.1.2**: The system shall download individual artwork files by URL or path identifier.

**FR1.1.3**: WHEN a download is requested the system shall check the local filesystem for existing content.

**FR1.1.4**: WHEN a download is in progress the system shall display progress information (bytes transferred, percentage, transfer speed, ETA).

**FR1.1.5**: IF a download fails THEN the system shall return a descriptive error with retry guidance.

**FR1.1.6**: The system shall support resumable downloads using HTTP Range requests.

**FR1.1.7**: WHEN a download is interrupted the system shall resume from the last transferred byte on retry.

**FR1.1.8**: IF resume is not supported THEN the system shall restart the download from the beginning.

**FR1.1.9**: The system shall verify ZIP file integrity after download completion.

**FR1.1.10**: IF integrity verification fails THEN the system shall delete the corrupted file and return error.CorruptedDownload.

### FR1.2: Protocol Support

**FR1.2.1**: The system shall support HTTP/HTTPS downloads from https://16colo.rs.

**FR1.2.2**: The system shall support FTP downloads from ftp://16colo.rs.

**FR1.2.3**: WHERE rsync is available on the system the system shall support RSYNC downloads from rsync://16colo.rs.

**FR1.2.4**: The system shall automatically select the optimal protocol based on operation type.

**FR1.2.5**: IF a protocol fails THEN the system shall attempt fallback to alternative protocols.

**FR1.2.6**: The system shall use HTTP for single pack downloads (resume support priority).

**FR1.2.7**: The system shall use FTP for directory listings (avoid HTML scraping).

**FR1.2.8**: WHERE available the system shall use RSYNC for full archive mirroring (efficiency priority).

**FR1.2.9**: The system shall handle protocol-specific errors (timeouts, connection refused, authentication).

**FR1.2.10**: The system shall respect rate limiting with configurable delays between requests.

### FR1.3: Storage Management

**FR1.3.1**: The system shall store artpacks in the community-standard 16colors directory structure.

**FR1.3.2**: The system shall determine the 16colors directory path based on platform conventions.

**FR1.3.3**: WHEN running on Linux the system shall use `~/.local/share/16colors/` or `$XDG_DATA_HOME/16colors/`.

**FR1.3.4**: WHEN running on macOS the system shall use `~/Pictures/16colors/`.

**FR1.3.5**: WHEN running on Windows the system shall use `%USERPROFILE%\Pictures\16colors\`.

**FR1.3.6**: The system shall create the 16colors directory structure on first run if it does not exist.

**FR1.3.7**: The system shall create subdirectories: `packs/`, `local/`, `collections/`, `patches/`.

**FR1.3.8**: The system shall discover existing 16colors directories created by other tools.

**FR1.3.9**: The system shall preserve the original ZIP file in addition to extracted contents.

**FR1.3.10**: The system shall maintain directory hierarchy from artpack structures.

**FR1.3.11**: The system shall store tool-specific cache in platform-appropriate cache directories.

**FR1.3.12**: WHEN running on Linux the system shall use `~/.cache/16colors-tools/ansilust/`.

**FR1.3.13**: WHEN running on macOS the system shall use `~/Library/Caches/16colors-tools/ansilust/`.

**FR1.3.14**: WHEN running on Windows the system shall use `%LOCALAPPDATA%\16colors-tools\ansilust\Cache\`.

### FR1.4: Metadata Preservation

**FR1.4.1**: The system shall preserve original filenames from artpacks without modification.

**FR1.4.2**: WHEN SAUCE metadata is present in a file the system shall extract and store it in `.index.db`.

**FR1.4.3**: The system shall maintain artpack directory hierarchy (subdirectories preserved).

**FR1.4.4**: The system shall extract SAUCE fields: title, author, group, date, file type, data type.

**FR1.4.5**: WHEN multiple versions of a file exist the system shall support version tracking in the database.

**FR1.4.6**: WHERE JSON configuration files exist they shall include a `$schema` property pointing to published schemas.

**FR1.4.7**: Configuration file schemas shall be valid JSON Schema Draft 2020-12.

**FR1.4.8**: The system shall store SAUCE metadata as JSON in the database for efficient querying.

### FR1.5: Global Archive Database

**FR1.5.1**: The system shall store the global archive database at `16colors/.index.db` in the 16colors root directory.

**FR1.5.2**: The database shall be shared by ALL tools (part of the community standard).

**FR1.5.3**: The canonical database shall be distributed from `https://ansilust.com/16colors/.index.db`.

**FR1.5.4**: The canonical mirror structure at ansilust.com/16colors/ shall mirror local directory structure exactly.

**FR1.5.5**: All paths under `https://ansilust.com/16colors/*` shall correspond to local `~/Pictures/16colors/*` paths.

**FR1.5.6**: The database shall include all 16colo.rs archive metadata (packs, files, artists, groups, SAUCE data).

**FR1.5.7**: The database shall store download URLs for source files and pre-rendered PNGs (thumbnail, x1, x2 sizes).

**FR1.5.8**: The system shall automatically check for database updates on every `16c` CLI invocation.

**FR1.5.9**: The update check shall be throttled to maximum once per hour.

**FR1.5.10**: The update check shall use a lightweight request (< 1KB metadata).

**FR1.5.11**: WHEN a new database version is available the system shall download it automatically in the background.

**FR1.5.12**: WHILE a database update downloads the system shall use the cached database (non-blocking).

**FR1.5.13**: The database shall be updated via versioned SQL patch files.

**FR1.5.14**: Patch files shall be numbered sequentially with zero-padded 4-digit prefixes (e.g., `0001-add-mist1025.sql`).

**FR1.5.15**: Patch files shall be distributed from `https://ansilust.com/16colors/patches/`.

**FR1.5.16**: WHEN applying patches the system shall execute them in sequential order.

**FR1.5.17**: IF a patch fails to apply THEN the system shall roll back and continue with the previous database version.

**FR1.5.18**: The database shall contain ONLY official 16colo.rs archive content.

**FR1.5.19**: The database shall NOT track local user content or download state.

**FR1.5.20**: The database shall support FTS5 full-text search across artwork metadata.

**FR1.5.21**: The system shall index filename, artist, and title fields in FTS5.

**FR1.5.22**: The database schema shall be versioned with a `schema_version` table.

**FR1.5.23**: WHERE database update fails the system shall continue using cached database.

**FR1.5.24**: Auto-updates shall NOT be configurable (opinionated design - users cannot disable).

**FR1.5.25**: WHEN the database does not exist locally the system shall download it on first `16c` invocation.

### FR1.6: Discovery and Search

**FR1.6.1**: The system shall list available artpacks by year, group, or artist.

**FR1.6.2**: The system shall query `.index.db` for search operations (no FTP queries needed).

**FR1.6.3**: WHEN browsing packs the system shall display pack metadata (group, release date, file count).

**FR1.6.4**: The system shall support filtering by file format (ANS, XB, ASC, ICE, BIN, etc.).

**FR1.6.5**: To check if files are downloaded locally the system shall use filesystem operations.

**FR1.6.6**: The system shall indicate which packs are downloaded when displaying listings.

**FR1.6.7**: WHEN searching for files the system shall return results from the database instantly.

**FR1.6.8**: Search results shall include pack name, year, group, artist, and download URLs.

**FR1.6.9**: The system shall support FTS5 full-text search queries across indexed fields.

**FR1.6.10**: The system shall parse and index RSS feed from https://16colo.rs/rss/.

**FR1.6.11**: The system shall identify new packs from RSS that are not yet in the local mirror.

### FR1.7: Archive Mirroring

**FR1.7.1**: The system shall support mirroring the entire 16colors archive.

**FR1.7.2**: The system shall support incremental mirror sync (only download new/changed packs).

**FR1.7.3**: The system shall support filtering mirrors by year range.

**FR1.7.4**: The system shall exclude NSFW content by default.

**FR1.7.5**: The system shall exclude executable files (*.exe, *.com, *.bat) by default.

**FR1.7.6**: WHERE the user specifies `--include-nsfw` the system shall download NSFW-tagged content.

**FR1.7.7**: WHERE the user specifies `--include-executables` the system shall download executable files.

**FR1.7.8**: WHERE the user specifies `--include-all` the system shall include both NSFW and executables.

**FR1.7.9**: The system shall support filtering by file extension (include or exclude lists).

**FR1.7.10**: The system shall support excluding specific groups from mirrors.

**FR1.7.11**: The system shall support dry-run mode to preview mirror operations without downloading.

**FR1.7.12**: WHERE rsync is available the system shall support bandwidth limiting for mirror operations.

**FR1.7.13**: The system shall persist mirror configuration in `.16colors-config.json`.

**FR1.7.14**: WHEN sync is run without filter arguments the system shall use previously configured filters.

**FR1.7.15**: The system shall always apply default exclusions (NSFW, executables) unless explicitly overridden.

**FR1.7.16**: The system shall support pruning orphaned packs (packs deleted from remote).

**FR1.7.17**: WHEN displaying mirror sync progress the system shall show excluded file counts.

**FR1.7.18**: WHEN including NSFW or executables the system shall warn the user.

### FR1.8: CLI Interface

**FR1.8.1**: The system shall provide a `16c` CLI executable for archive-first operations.

**FR1.8.2**: The system shall support `16colors` as an alias to `16c`.

**FR1.8.3**: The system shall support `16` as a short alias to `16c`.

**FR1.8.4**: All three names (`16c`, `16colors`, `16`) shall invoke identical functionality.

**FR1.8.5**: The system shall integrate archive operations into the `ansilust` CLI via `--16colors` flag.

**FR1.8.6**: The `16c` CLI shall assume archive context for all commands (no explicit `--archive` flag needed).

**FR1.8.7**: The `ansilust` CLI shall assume local file context unless `--16colors` is specified.

**FR1.8.8**: Both CLIs shall share the same underlying library implementation.

**FR1.8.9**: The system shall provide `--help` documentation for all commands.

**FR1.8.10**: The system shall provide `--version` flag showing software version.

**FR1.8.11**: The system shall support `--quiet` mode for suppressing progress output.

**FR1.8.12**: The system shall support `--verbose` mode for detailed logging.

**FR1.8.13**: WHEN invoked with invalid arguments the system shall display usage help and exit with error.

### FR1.9: Library Integration

**FR1.9.1**: The system shall provide a Zig library API for programmatic access.

**FR1.9.2**: The library shall integrate with ansilust parsers for format validation.

**FR1.9.3**: WHEN files are downloaded the library shall emit events for integration hooks.

**FR1.9.4**: The library shall be usable independently of the CLI tools.

**FR1.9.5**: The library shall provide functions for database queries, downloads, and mirror operations.

**FR1.9.6**: All library functions accepting allocators shall make memory allocation explicit.

**FR1.9.7**: All library functions shall use error unions for fallible operations.

---

## NFR2: Non-Functional Requirements

### NFR2.1: Performance

**NFR2.1.1**: Database search operations shall complete in < 100ms for typical queries.

**NFR2.1.2**: FTS5 full-text search shall complete in < 500ms for the entire archive.

**NFR2.1.3**: Database update checks shall complete in < 1 second (throttled, cached).

**NFR2.1.4**: FTP directory listing for a single year shall complete in < 5 seconds.

**NFR2.1.5**: HTTP pack downloads shall achieve reasonable throughput (> 1MB/s on typical connections).

**NFR2.1.6**: ZIP extraction shall process at > 10MB/s (memory-limited, not CPU-bound).

**NFR2.1.7**: Database auto-updates shall not block CLI operations (background downloads).

### NFR2.2: Resource Usage

**NFR2.2.1**: The `.index.db` database shall not exceed 100MB for the full archive (~4000 packs, ~100K files).

**NFR2.2.2**: Memory usage during ZIP extraction shall not exceed 2x the largest file size.

**NFR2.2.3**: The system shall release network connections after operations complete.

**NFR2.2.4**: Database connections shall use SQLite WAL mode for concurrent access safety.

**NFR2.2.5**: Tool-specific cache shall not exceed 500MB without user notification.

### NFR2.3: Reliability

**NFR2.3.1**: The system shall gracefully handle network failures and continue with cached data.

**NFR2.3.2**: The system shall handle incomplete downloads and support resume operations.

**NFR2.3.3**: Database corruption shall be detected and recovered from backup or re-download.

**NFR2.3.4**: The system shall validate all remote data before persisting to disk.

**NFR2.3.5**: File system operations shall handle full disk conditions gracefully.

### NFR2.4: Usability

**NFR2.4.1**: Error messages shall be actionable and include suggestions for resolution.

**NFR2.4.2**: Progress output shall be human-readable with clear units (MB, %, speed).

**NFR2.4.3**: The `16c` CLI name shall be memorable and clearly associated with 16colors.

**NFR2.4.4**: Command syntax shall follow Unix conventions (flags, arguments, pipes).

**NFR2.4.5**: The system shall provide examples in `--help` output for common operations.

### NFR2.5: Documentation

**NFR2.5.1**: All public APIs shall have doc comments (`///` in Zig).

**NFR2.5.2**: Doc comments shall include usage examples for non-trivial functions.

**NFR2.5.3**: Doc comment coverage for public APIs shall be 100%.

**NFR2.5.4**: The system shall provide man pages for CLI tools.

**NFR2.5.5**: Error codes shall be documented with meaning and resolution steps.

---

## TC3: Technical Constraints

### TC3.1: Platform Support

**TC3.1.1**: The system shall compile and run on Linux (x86_64, aarch64).

**TC3.1.2**: The system shall compile and run on macOS (Intel, Apple Silicon).

**TC3.1.3**: The system shall compile and run on Windows (x86_64).

**TC3.1.4**: The system shall handle platform-specific path separators (`/` vs `\`).

**TC3.1.5**: The system shall handle platform-specific line endings in text files.

### TC3.2: Zig Version

**TC3.2.1**: The system shall compile with Zig version 0.11.0 or later.

**TC3.2.2**: The system shall pass compilation with `-Doptimize=ReleaseSafe`.

**TC3.2.3**: The system shall pass all tests with `-Doptimize=Debug` (undefined behavior detection).

**TC3.2.4**: The system shall produce zero compiler warnings.

### TC3.3: Dependencies

**TC3.3.1**: The system shall use only Zig standard library for core functionality.

**TC3.3.2**: WHERE external dependencies are required they shall be justified and documented.

**TC3.3.3**: SQLite shall be the only required external dependency (via C library or Zig implementation).

**TC3.3.4**: The system shall NOT depend on external HTTP/FTP clients (implement in Zig or use std lib).

**TC3.3.5**: RSYNC support shall shell out to system rsync binary (not reimplemented).

### TC3.4: Safety and Correctness

**TC3.4.1**: The system shall have zero undefined behavior (verified with `-Doptimize=Debug`).

**TC3.4.2**: All memory allocations shall use explicit allocator parameters.

**TC3.4.3**: All resources shall be cleaned up with `defer` or `errdefer`.

**TC3.4.4**: The system shall detect memory leaks using `std.testing.allocator`.

**TC3.4.5**: ZIP extraction shall validate paths to prevent directory traversal attacks.

**TC3.4.6**: The system shall validate SSL certificates for HTTPS connections.

**TC3.4.7**: The system shall sanitize user inputs (pack names, URLs) to prevent injection attacks.

---

## DR4: Data Requirements

### DR4.1: Database Schema

**DR4.1.1**: The database shall use SQLite version 3.35.0 or later (for FTS5 support).

**DR4.1.2**: The database shall include a `schema_version` table for migration tracking.

**DR4.1.3**: The database shall include a `packs` table with fields: id, name, year, group_name, release_date, file_count, total_size, nsfw, zip_url, web_url.

**DR4.1.4**: The database shall include a `files` table with fields: id, pack_id, relative_path, filename, extension, size, artist, title, sauce_data, source_url, png_url, png_url_x1, png_url_x2.

**DR4.1.5**: The database shall include a `groups` table with aggregated statistics.

**DR4.1.6**: The database shall include an `artists` table with aggregated statistics.

**DR4.1.7**: The database shall include an FTS5 virtual table `files_fts` indexing filename, artist, title.

**DR4.1.8**: The `sauce_data` field shall store JSON with complete SAUCE record.

**DR4.1.9**: The database shall use foreign key constraints (pack_id references packs.id).

**DR4.1.10**: The database shall use indexes on frequently queried fields (year, group_name, artist, extension).

### DR4.2: File Formats

**DR4.2.1**: The system shall handle ZIP archives as the primary artpack format.

**DR4.2.2**: The system shall recognize text art extensions: ans, asc, xb, ice, bin, pcb, tnd, adf, idf, rip, lit, drk.

**DR4.2.3**: The system shall recognize metadata file extensions: diz, nfo, txt.

**DR4.2.4**: The system shall recognize image extensions: png, gif, jpg.

**DR4.2.5**: The system shall recognize executable extensions (for exclusion): exe, com, bat.

**DR4.2.6**: SAUCE metadata shall be extracted from the last 128 bytes of files (if present).

### DR4.3: URL Construction

**DR4.3.1**: Pack download URLs shall follow the pattern: `https://16colo.rs/archive/{year}/{pack_name}.zip`.

**DR4.3.2**: Individual file URLs shall follow the pattern: `https://16colo.rs/pack/{pack_name}/{filename}`.

**DR4.3.3**: PNG thumbnail URLs shall follow the pattern: `https://16colo.rs/pack/{pack_name}/tn/{filename}.png`.

**DR4.3.4**: PNG x1 render URLs shall follow the pattern: `https://16colo.rs/pack/{pack_name}/x1/{filename}.png`.

**DR4.3.5**: PNG x2 render URLs shall follow the pattern: `https://16colo.rs/pack/{pack_name}/x2/{filename}.png`.

**DR4.3.6**: FTP archive listing shall use path: `ftp://16colo.rs/archive/{year}/`.

**DR4.3.7**: FTP pack listing shall use path: `ftp://16colo.rs/pack/`.

---

## IR5: Integration Requirements

### IR5.1: Parser Integration

**IR5.1.1**: The system shall integrate with ansilust ANSI parser for format validation.

**IR5.1.2**: WHEN a file is downloaded the system shall optionally validate its format.

**IR5.1.3**: The system shall support rendering downloaded files using ansilust renderers.

**IR5.1.4**: WHEN rendering fails the system shall provide format-specific error details.

### IR5.2: Tool Interoperability

**IR5.2.1**: The 16colors directory structure shall be discoverable by other tools.

**IR5.2.2**: The `.index.db` database schema shall be documented for third-party tool access.

**IR5.2.3**: The system shall use SQLite WAL mode to support concurrent reads from multiple tools.

**IR5.2.4**: WHERE another tool has locked the database the system shall wait or use stale cache.

**IR5.2.5**: The system shall emit events for screensaver integration (artwork available, database updated).

---

## DEP6: Dependencies

### DEP6.1: Required Dependencies

**DEP6.1.1**: Zig standard library (std.http, std.zip, std.fs, std.mem).

**DEP6.1.2**: SQLite 3.35.0+ (via C FFI or pure Zig implementation).

**DEP6.1.3**: SQLite FTS5 extension (full-text search).

**DEP6.1.4**: SQLite JSON1 extension (SAUCE metadata storage).

### DEP6.2: Optional Dependencies

**DEP6.2.1**: System rsync binary (for RSYNC protocol support).

**DEP6.2.2**: System TLS/SSL library (if not using Zig std HTTPS).

### DEP6.3: Build Dependencies

**DEP6.3.1**: Zig build system (build.zig).

**DEP6.3.2**: No npm, make, or other build tools required.

---

## SC7: Success Criteria

### SC7.1: Core Functionality

**SC7.1.1**: A user can search for any file by name across the entire archive in < 1 second.

**SC7.1.2**: A user can download any artpack with a single command: `16c download <packname>`.

**SC7.1.3**: Downloaded packs are automatically extracted and indexed in `.index.db`.

**SC7.1.4**: The `.index.db` database updates automatically without user intervention.

**SC7.1.5**: Local file processing with `ansilust <file>` works identically to `cat <file>` in terms of mental model.

### SC7.2: Performance

**SC7.2.1**: Archive search completes instantly without network access (database-powered).

**SC7.2.2**: Database update checks add < 100ms overhead to CLI invocations (throttled).

**SC7.2.3**: Full archive mirror sync completes in reasonable time (hours, not days) on typical connections.

### SC7.3: Compatibility

**SC7.3.1**: The 16colors directory structure works identically on Linux, macOS, and Windows.

**SC7.3.2**: Other tools (screensavers, viewers) can discover and use `~/Pictures/16colors/`.

**SC7.3.3**: The `.index.db` database can be queried by any SQLite-compatible tool.

### SC7.4: Quality

**SC7.4.1**: All Zig source files pass `zig fmt` without modification.

**SC7.4.2**: `zig build test` passes with zero failures and zero memory leaks.

**SC7.4.3**: `zig build -Doptimize=Debug` detects zero undefined behavior.

**SC7.4.4**: All public APIs have 100% doc comment coverage.

**SC7.4.5**: Error handling is comprehensive with no `catch unreachable` without justification.

---

## Requirements Traceability

### Instructions to Requirements Mapping

| Instructions Section | Requirements Sections |
|---------------------|----------------------|
| FR1.1: Download Management | FR1.1 |
| FR1.2: Protocol Support | FR1.2 |
| FR1.3: Storage Management | FR1.3 |
| FR1.4: Metadata Preservation | FR1.4 |
| FR1.5: Global Archive Database | FR1.5, DR4.1 |
| FR1.6: Discovery and Search | FR1.6 |
| FR1.7: Archive Mirroring | FR1.7 |
| FR1.8: CLI Interface | FR1.8 |
| FR1.9: Library Integration | FR1.9, IR5 |

### Success Metrics to Criteria Mapping

| Success Metric | Success Criteria |
|----------------|------------------|
| SM1-5 (CLI Usability) | SC7.1.5, SC7.4 |
| SM6-9 (Download & Storage) | SC7.1.2-3, SC7.3.1 |
| SM10-14 (Mirroring) | SC7.2.3 |
| SM15-21 (Database & Search) | SC7.1.1, SC7.1.4, SC7.2.1-2 |
| SM22-25 (Integration) | SC7.3.2-3, IR5 |

---

**Phase 2: Requirements Phase - Complete**

This requirements specification provides detailed, testable requirements using EARS notation. All functional requirements follow EARS patterns (Ubiquitous, Event-driven, State-driven, Unwanted, Optional). Ready for Phase 3: Design Phase.
