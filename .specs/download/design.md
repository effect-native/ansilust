# 16c Download Runtime - Design Document

## Document Overview

This document describes the shipped Stage 1 download architecture for ansilust's `16c` runtime. It records the current executable, module, storage, and playback structure as it exists in checked-in code, while keeping broader archive-client ambitions staged as later work rather than present-tense truth.

**Related Documents**:
- `instructions.md` - user intent and product framing
- `requirements.md` - formal requirements language
- `plan.md` - staged implementation roadmap
- `.ok/download.ok.md` - constitutional truth for current download behavior

**Design Philosophy**: Keep the current runtime simple, local-first, and easy to reason about. Stage 1 favors a small executable surface, explicit module boundaries, platform-resolved directories, and a hardcoded archive abstraction over premature database or mirror complexity.

---

## Architecture Overview

### High-Level System Components

```
┌─────────────────────────────────────────────────────────────┐
│                       CLI Runtime                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  16c executable (`src/cli/sixteenc.zig`)             │  │
│  │  commands: random, screensaver, random-1, help, ver │  │
│  └──────────────────────────────┬────────────────────────┘  │
└─────────────────────────────────┼───────────────────────────┘
                                  │
┌─────────────────────────────────┼───────────────────────────┐
│                    Download Runtime Layer                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ `src/download/lib.zig`                                 │ │
│  │ - database interface export                            │ │
│  │ - random command runtime export                        │ │
│  │ - http protocol export                                 │ │
│  │ - storage path/file export                             │ │
│  └──────────────────────────────┬─────────────────────────┘ │
└─────────────────────────────────┼───────────────────────────┘
                                  │
┌─────────────────────────────────┼───────────────────────────┐
│                    Stage 1 Command Runtime                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ `commands/random.zig`                                  │ │
│  │ - load Stage 1 config                                  │ │
│  │ - resolve local-first artwork selection                │ │
│  │ - optional remote fallback for `random-1`             │ │
│  │ - save remote result to `random/` cache               │ │
│  │ - render via ansilust parser + UTF8ANSI renderer      │ │
│  └───────────────┬───────────────────────┬───────────────┘ │
└──────────────────┼───────────────────────┼─────────────────┘
                   │                       │
         ┌─────────┘                       └─────────┐
         │                                           │
┌────────┼───────────────┐                 ┌─────────┼──────────────┐
│   Archive Source       │                 │   Local Storage         │
│ `database/interface`   │                 │ `storage/paths.zig`     │
│ `database/hardcoded`   │                 │ `storage/files.zig`     │
│ current source set:    │                 │ root + random/packs/    │
│ one curated file entry │                 │ local directories        │
└────────┬───────────────┘                 └─────────┬──────────────┘
         │                                           │
         └───────────────────┬───────────────────────┘
                             │
                 ┌───────────┴───────────┐
                 │ HTTP Download Path    │
                 │ `protocols/http.zig`  │
                 │ curl via `sh -c`      │
                 └───────────────────────┘
```

### Component Relationships

- The shipped entrypoint is the standalone `16c` executable; there is no shipped `ansilust --16colors` integration path yet.
- `src/cli/sixteenc.zig` parses command and playback flags, then delegates to the random command runtime.
- `src/download/commands/random.zig` owns the actual Stage 1 workflow for single-play, looping, and screensaver playback.
- The archive source is abstracted behind `ArchiveDatabase`, but the shipped implementation is the hardcoded provider, not SQLite.
- Storage exists primarily to support local-first playback and the `random/` cache; `packs/` and broader archive management remain reserved structure, not active workflow.

---

## Module Organization

### Shipped Stage 1 Modules

```
src/cli/
└── sixteenc.zig                    # standalone 16c executable and flag parsing

src/download/
├── lib.zig                         # public Stage 1 download surface
├── commands/
│   ├── random.zig                  # random-1, random loop, screensaver runtime
│   └── stage1_config.zig           # minimal config parser for config.toml
├── database/
│   ├── interface.zig               # stable archive abstraction
│   └── hardcoded.zig               # current curated in-memory archive source
├── protocols/
│   └── http.zig                    # HTTP-only download path via curl shell-out
└── storage/
    ├── paths.zig                   # platform root + subdirectory resolution
    └── files.zig                   # random-cache save path and cleanup stub
```

### Dependency Flow

```text
src/cli/sixteenc.zig
  -> src/download/commands/random.zig
  -> src/download/commands/stage1_config.zig
  -> src/download/database/interface.zig
  -> src/download/database/hardcoded.zig
  -> src/download/protocols/http.zig
  -> src/download/storage/paths.zig
  -> src/download/storage/files.zig
  -> ansilust parser + renderer APIs
```

### Module Boundary Intent

- `sixteenc.zig` owns CLI syntax and user-facing dispatch only.
- `random.zig` owns runtime orchestration and playback/session behavior.
- `stage1_config.zig` owns the tiny Stage 1 config schema and parsing rules.
- `database/interface.zig` preserves a stable seam for later archive metadata growth without forcing SQLite into the shipped MVP.
- `storage/*.zig` isolates platform path policy and on-disk file behavior from command orchestration.

---

## Shipped Runtime Baseline

### CLI Surface

The current runtime is centered on these command paths in `src/cli/sixteenc.zig`:

- `random` - replay artwork continuously using the Stage 1 playback loop
- `screensaver` - run the alternate-screen looping session
- `random-1` - fetch or select one artwork and display it once
- `--help` / `-h`
- `--version` / `-v`

Playback control is intentionally small:

- `--instant` disables dwell delay between loop iterations
- `--streaming-speed <preset>` accepts `slow`, `normal`, or `fast`
- conflicting playback flags fail fast

### Stage 1 Source Policy

Stage 1 is local-first, not database-first:

- `random` and `screensaver` first scan `random/` and `local/` for playable `.ans` or `.asc` files
- if no playable local file exists, `random` and `screensaver` stop with guidance rather than fetching remotely
- `random-1` uses the same local-first scan, but may fall back to one remote archive selection when the local pool is empty
- remote fallback currently uses the hardcoded archive abstraction and HTTP-only download path

### Storage Reality

`src/download/storage/paths.zig` resolves a shared `16colors` root and creates:

- `random/` - runtime cache used by Stage 1 playback
- `packs/` - reserved official archive area, not yet populated by shipped workflows
- `local/` - user-managed artwork input for local-first playback

`src/download/storage/files.zig` currently implements:

- timestamped saves into `random/`
- a declared random-cache cleanup seam
- a no-op cleanup implementation for now

### Archive Reality

`src/download/database/interface.zig` provides the long-lived abstraction surface, but the shipped implementation is `database/hardcoded.zig`:

- `getRandomFile` works
- `searchFiles` returns an empty result set
- `getPack` returns `error.NotImplemented`
- `listPacksByYear` returns an empty result set
- the curated source list currently contains one verified remote file entry

This is deliberate Stage 1 scaffolding, not an accidental partial SQLite client.

---

## Runtime Flows

### `16c random-1`

High-level flow:

```text
1. Resolve platform paths and create root/random/packs/local directories.
2. Scan random/ and local/ for playable .ans/.asc artwork.
3. If a local candidate exists, display it and exit.
4. Otherwise initialize ArchiveDatabase using the hardcoded implementation.
5. Select one remote file entry.
6. Download it to /tmp via HttpClient.
7. Save the downloaded file into random/ with a timestamped filename.
8. Call random-cache cleanup.
9. Parse and render the saved file through ansilust.
```

### `16c random`

High-level flow:

```text
1. Load config.toml from the 16colors root, or use built-in defaults.
2. Resolve dwell/playback mode from CLI flags plus config.
3. Repeatedly call the shared one-shot playback path with remote fallback disabled.
4. Sleep between iterations unless instant mode is selected.
5. Stop only on process termination or surfaced runtime error.
```

### `16c screensaver`

High-level flow:

```text
1. Load the same Stage 1 config defaults/overrides as random.
2. Enter alternate-screen session if stdout is a TTY.
3. Install SIGINT and SIGTERM handlers for best-effort exit.
4. Repeatedly play one local artwork item with remote fallback disabled.
5. Exit on signal, input readiness, iteration bound in tests, or runtime error.
6. Restore terminal state on the way out.
```

---

## Data Structures

### Playback Types

`src/download/commands/random.zig` defines the current playback control model:

- `PlaybackMode` - `.standard`, `.instant`, or `.streaming`
- `StreamingSpeed` - `slow`, `normal`, `fast`
- `RandomPlaybackLoop` - loop state containing playback mode, resolved delay, and source mode
- `ScreensaverPlaybackLoop` - screensaver wrapper around the random playback loop

These are runtime control types, not archive metadata models.

### Config Types

`src/download/commands/stage1_config.zig` defines the shipped config schema:

```zig
pub const Stage1Config = struct {
    playback: PlaybackConfig = .{},
    source: SourceConfig = .{},
};
```

Shipped knobs are intentionally minimal:

- `playback.dwell_seconds`
- `source.mode = "auto"`

No checked-in evidence yet supports richer source policies, filtering, or mirror settings.

### Archive Types

`src/download/database/interface.zig` provides the archive-facing types:

- `FileEntry` - pack name, filename, source URL, year, optional artist, extension
- `Pack` - pack name, year, optional group name, zip URL
- `Implementation` - union over `.hardcoded` and future `.sqlite`
- `ArchiveDatabase` - wrapper that dispatches to the selected backend

The important architectural point is that the interface is shipped, while the SQLite branch remains a placeholder.

### Storage Types

`src/download/storage/paths.zig` defines `PlatformPaths` with:

- `sixteen_colors_root`
- `random_dir`
- `packs_dir`
- `local_dir`

`src/download/storage/files.zig` defines `FileStorage` for saving cache files and later pruning them.

---

## Error Handling Strategy

### Current Strategy

Stage 1 uses explicit Zig error propagation and keeps failure modes close to the command runtime:

- CLI parsing errors fail immediately for unknown commands, unknown flags, missing presets, and conflicting flags
- local-playback commands surface `error.EmptyLocalArtworkPool` when no playable local files exist
- config loading falls back to defaults when `config.toml` is missing
- remote failures bubble from the HTTP client or archive abstraction
- unimplemented archive APIs remain explicit through empty results or `error.NotImplemented`

### Architectural Intent

- Keep Stage 1 errors concrete and visible rather than hiding them behind a large speculative shared error taxonomy.
- Preserve stable seams where later search, pack, mirror, or database features can introduce more structured domain errors.
- Treat missing future capabilities as explicit non-support, not partial silent behavior.

---

## Memory Management Strategy

### Current Patterns

- CLI and command entrypoints receive an explicit allocator.
- `PlatformPaths` owns allocated path strings and requires `deinit`.
- `ArchiveDatabase` owns its backend wrapper and provides `deinit`.
- local file candidate selection duplicates owned path strings before returning them.
- temporary download paths and saved-path strings are allocator-owned and released by the caller.
- artwork display uses page allocator reads/renders for the one-shot render path.

### Design Intent

- Keep ownership local and obvious.
- Avoid introducing a long-lived cache manager or shared database state before Stage 1 needs it.
- Prefer short-lived allocations per command invocation over speculative persistent services.

---

## Testing Approach

### Shipped Validation Surface

The public Stage 1 download surface is validated by tests re-exported from `src/download/lib.zig`:

- `src/download/commands/random_test.zig`
- `src/download/database/interface_test.zig`
- `src/download/protocols/http_test.zig`
- `src/download/storage/paths_test.zig`
- `src/download/storage/files_test.zig`
- command-surface tests in `src/cli/sixteenc.zig`

### What Stage 1 Tests Need To Prove

- the `16c` command surface matches the shipped runtime
- playback flags and conflicts are enforced
- local-first selection only accepts playable `.ans` and `.asc` files
- config loading defaults work without a checked-in config file
- path resolution and file save behavior remain stable
- the archive abstraction still selects the hardcoded backend today

This test strategy is intentionally aligned to the MVP runtime, not to future search or mirror promises.

---

## Integration Points

### Ansilust Rendering Integration

The download runtime integrates with ansilust only at display time:

- `random.zig` reads the chosen file
- `ansilust.parsers.ansi.parse` parses it
- `ansilust.renderToUtf8Ansi` renders it for the current stdout context

This means the Stage 1 runtime is already useful as a downloader-plus-player without requiring broader archive management features.

### Build Integration

- `build.zig` installs the standalone `16c` executable
- `src/download/lib.zig` defines the checked-in public module surface for download functionality
- no shipped build wiring currently proves alternate executable aliases or ansilust-side integration flags

---

## Performance Considerations

### Current Expectations

- local replay should dominate the common loop path once `random/` or `local/` has artwork
- remote fallback is lightweight because Stage 1 downloads only one artwork file at a time
- the hardcoded archive provider keeps metadata lookup trivial
- HTTP download implementation is simple rather than optimized
- rendering cost is bounded by one file per iteration, not by pack extraction or large-index queries

### Non-Goals For Stage 1

- no pack-scale synchronization
- no search indexing performance target
- no database update scheduler
- no concurrent mirror bandwidth management

---

## API Surface

### Shipped Public Surface

`src/download/lib.zig` currently exports:

- `database`
- `commands.random`
- `RandomPlaybackLoop`
- `ScreensaverPlaybackLoop`
- `protocols.http`
- `storage.paths`
- `storage.files`

Representative Stage 1 runtime entrypoints are:

```zig
pub fn executeRandomOne(allocator: Allocator) !void;
pub fn executeRandomLoop(allocator: Allocator, mode: PlaybackMode) !void;
pub fn executeScreensaverWithMode(allocator: Allocator, mode: PlaybackMode) !void;
pub fn loadFromRoot(allocator: Allocator, root_path: []const u8, config_file_name: []const u8) !Stage1Config;
pub fn init(allocator: Allocator) !ArchiveDatabase;
pub fn download(self: *HttpClient, url: []const u8, dest_path: []const u8) !void;
```

This is a runtime-oriented API surface, not yet a full archive-client SDK.

---

## Staged Future Architecture

The following items remain later-stage architecture and must not be treated as shipped design truth:

- `.index.db` as the canonical archive metadata store
- SQLite-backed search, FTS, pack lookup, and yearly listing
- mirror sync and filtering workflows
- pack download, ZIP extraction, and long-lived `packs/` population
- alias executables such as `16colors` or `16`
- `ansilust --16colors` integration mode
- richer `config.toml` source policies beyond `auto`
- protocol expansion beyond the current HTTP/curl path

### Growth Path

Future stages should layer onto the current seams rather than replace the Stage 1 baseline narrative:

1. Expand `ArchiveDatabase` from hardcoded source to shipped database-backed metadata.
2. Promote search and pack workflows only when code, tests, and build wiring exist.
3. Add real pack storage behavior under `packs/` when extraction and lifecycle rules are implemented.
4. Grow protocol support only after the runtime proves native clients or fallback logic.

---

## Design Decisions and Rationale

### Decision 1: Standalone `16c` first

- **Rationale**: one executable keeps the MVP easy to build, test, and explain
- **Trade-off**: integrated ansilust archive UX waits until later stages

### Decision 2: Local-first playback before metadata-rich archive features

- **Rationale**: the runtime becomes immediately useful for replay and screensaver scenarios
- **Trade-off**: broad archive browsing and search are deferred

### Decision 3: Stable archive abstraction without shipping SQLite yet

- **Rationale**: `ArchiveDatabase` gives later stages a seam without forcing unfinished database behavior into the MVP
- **Trade-off**: current archive content is intentionally tiny and curated

### Decision 4: Shared directory layout now, fuller storage semantics later

- **Rationale**: establishing `random/`, `packs/`, and `local/` early avoids later path churn
- **Trade-off**: some directories exist before all workflows that will eventually use them

### Decision 5: Minimal Stage 1 config

- **Rationale**: only ship knobs that the runtime actually honors
- **Trade-off**: richer source and playback policy stays out of current guarantees

---

## Design Status

This design now describes the shipped Stage 1 runtime centered on `16c`, local-first playback, a hardcoded archive abstraction, HTTP-only remote fallback, and renderer-backed display. It intentionally separates future `.index.db`, search, mirror, pack, and protocol growth from current architectural truth so the document stays consistent with `.ok/download.ok.md` and the checked-in runtime.
