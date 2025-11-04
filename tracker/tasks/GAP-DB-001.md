---
id: GAP-DB-001
title: SQLite .index.db with FTS5 and schema migrations
area: db
status: pending
priority: high
spec_ref:
  - .specs/download/requirements.md#fr15-global-archive-database
  - .specs/download/requirements.md#dr41-database-schema
code_refs:
  - src/download/database/hardcoded.zig
  - src/download/database/interface.zig
acceptance:
  - Replace hardcoded stub with SQLite implementation
  - Create schema with packs, files, groups, artists tables
  - Create FTS5 virtual table for full-text search (files_fts)
  - Implement schema_version table and migration system
  - Support querying by pack name, year, artist, extension
  - FTS5 search completes in < 500ms for full archive
  - Tests for CRUD operations and FTS5 queries
blocked_by: []
labels:
  - database
  - SQLite
  - FTS5
  - 16colors
created: 2025-11-03
---

## Context

Current database is a hardcoded stub returning fake data:
```zig
// TODO: Add more URLs after verifying them in Phase 5.2
```

From requirements:
- FR1.5.1: Store at `16colors/.index.db`
- FR1.5.6: Include all 16colo.rs archive metadata
- FR1.5.20: Support FTS5 full-text search
- DR4.1: Complete schema with packs, files, groups, artists, files_fts

## Schema Requirements (DR4.1)

**Tables**:
1. `schema_version` - migration tracking
2. `packs` - id, name, year, group_name, release_date, file_count, total_size, nsfw, zip_url, web_url
3. `files` - id, pack_id, relative_path, filename, extension, size, artist, title, sauce_data (JSON), source_url, png_url, png_url_x1, png_url_x2
4. `groups` - aggregated statistics
5. `artists` - aggregated statistics
6. `files_fts` - FTS5 virtual table indexing filename, artist, title

**Constraints**:
- Foreign keys: pack_id references packs.id
- Indexes on: year, group_name, artist, extension

## Implementation Steps

1. Add SQLite dependency (Zig FFI or pure Zig wrapper)
2. Create schema initialization SQL
3. Implement migration system (sequential .sql patch files)
4. Replace hardcoded implementation with SQLite queries
5. Add FTS5 indexing on insert/update
6. Performance test: ensure FTS5 < 500ms (NFR2.1.2)

## Reference

- `.specs/download/design.md` for database architecture
- Zig SQLite bindings: investigate available packages
- FTS5 documentation: https://www.sqlite.org/fts5.html

## Migration Strategy

From FR1.5.13-17:
- Patches numbered sequentially: `0001-initial.sql`, `0002-add-mist1025.sql`
- Distributed from `https://ansilust.com/16colors/patches/`
- Apply in order; rollback on failure
