# 16c Download Runtime - Requirements Specification

## Document Overview

This document defines the download-domain requirements for the shipped Stage 1 `16c` runtime and separates those guarantees from future archive-client work. Functional requirements use EARS notation where practical, but shipped behavior takes precedence over earlier aspirational client scope.

**Related Documents**:
- `instructions.md` - original feature framing and archive-client intent
- `design.md` - technical design notes for current and future work
- `plan.md` - staged roadmap and task breakdown
- `.ok/download.ok.md` - governing present-tense truth for shipped behavior

---

## FR1: Functional Requirements

### FR1.1: Stage 1 Runtime Surface

**FR1.1.1**: The system shall provide a standalone `16c` CLI executable for the shipped download runtime.

**FR1.1.2**: The system shall support the commands `random`, `screensaver`, and `random-1` as the shipped Stage 1 command surface.

**FR1.1.3**: The system shall support `--help` and `--version` on the `16c` executable.

**FR1.1.4**: IF the user invokes an unknown command THEN the system shall fail fast with command usage guidance.

**FR1.1.5**: The system shall treat broader archive commands such as `download`, `list`, `search`, `show`, `mirror`, `db`, `stats`, and `local` as future-facing and not as shipped Stage 1 guarantees.

### FR1.2: Playback Modes And Command Behavior

**FR1.2.1**: The `random` command shall run a looping playback mode backed by locally available artwork.

**FR1.2.2**: The `screensaver` command shall run a looping playback mode backed by locally available artwork.

**FR1.2.3**: The `random-1` command shall fetch or select a single artwork item and display it once.

**FR1.2.4**: WHILE `random` or `screensaver` is running the system shall repeatedly select playable artwork from the Stage 1 local pool.

**FR1.2.5**: WHEN `random-1` completes local or remote selection the system shall render the selected artwork through the ansilust parser and renderer path.

### FR1.3: Local-First Source Policy

**FR1.3.1**: The system shall prefer locally available playable artwork before considering any remote fallback.

**FR1.3.2**: The Stage 1 local artwork pool shall consist of playable files discovered under `random/` and `local/` beneath the resolved 16colors root.

**FR1.3.3**: The system shall treat `.ans` and `.asc` files as the evidenced Stage 1 playable local file types.

**FR1.3.4**: WHEN `random` or `screensaver` starts the system shall search only the Stage 1 local pool for playback candidates.

**FR1.3.5**: IF `random` or `screensaver` cannot find a playable local candidate THEN the system shall stop with a descriptive empty-local-pool error instead of fetching remotely.

**FR1.3.6**: WHEN `random-1` starts the system shall first attempt to select a playable local candidate from the Stage 1 local pool.

**FR1.3.7**: IF `random-1` cannot find a playable local candidate THEN the system shall be permitted to use the Stage 1 remote fallback source.

### FR1.4: Remote Source Scope

**FR1.4.1**: The system shall limit shipped remote archive behavior to the `random-1` fallback path.

**FR1.4.2**: The system shall use the archive-database abstraction as the selection surface for remote fallback, even though the shipped implementation is hardcoded and minimal.

**FR1.4.3**: The system shall treat the hardcoded curated remote source set as the only shipped archive source in Stage 1.

**FR1.4.4**: The system shall not require `.index.db`, search, pack downloads, archive listings, extraction, or metadata persistence for shipped Stage 1 playback.

**FR1.4.5**: The system shall treat any future shared local inventory as a staged successor to the Stage 1 hardcoded remote catalog abstraction rather than as a shipped Stage 1 data source.

**FR1.4.6**: WHEN a shared local inventory is introduced in a later stage the system shall allow it to unify local cache, local-library discovery, and local archive-pack enumeration without making `.index.db` mandatory in the same revision.

**FR1.4.7**: IF broader remote archive workflows are referenced elsewhere THEN those workflows shall be understood as future archive-client work unless separately implemented and evidenced.

### FR1.5: Download And Storage Behavior

**FR1.5.1**: WHEN `random-1` falls back to a remote source the system shall download exactly one selected artwork file for immediate playback.

**FR1.5.2**: WHEN a remote artwork file is downloaded the system shall save it under the Stage 1 `random/` cache.

**FR1.5.3**: The system shall resolve a 16colors root directory and create the Stage 1 storage directories required for runtime operation.

**FR1.5.4**: The shipped Stage 1 storage contract shall include `random/`, `local/`, and `packs/` as resolved directories.

**FR1.5.5**: The system shall treat writes to `random/` as the only evidenced shipped download-side persistence behavior.

**FR1.5.6**: The system shall treat `packs/` as reserved for future archive-pack management rather than as an active Stage 1 pack-download guarantee.

### FR1.6: Playback Flags

**FR1.6.1**: The system shall support `--instant` for the shipped looping playback commands.

**FR1.6.2**: The system shall support `--streaming-speed <preset>` for the shipped looping playback commands.

**FR1.6.3**: The system shall limit shipped streaming presets to `slow`, `normal`, and `fast`.

**FR1.6.4**: IF the user supplies conflicting shipped playback flags THEN the system shall reject the invocation with a descriptive error.

**FR1.6.5**: The system shall treat richer playback controls, overlays, and advanced renderer simulation as future-facing unless independently implemented and evidenced.

### FR1.7: Minimal Config Loading

**FR1.7.1**: The system shall load `config.toml` from the resolved 16colors root for `random` and `screensaver`.

**FR1.7.2**: IF `config.toml` is missing THEN the system shall fall back to built-in Stage 1 defaults.

**FR1.7.3**: The system shall treat `playback.dwell_seconds` as an evidenced Stage 1 configuration value.

**FR1.7.4**: The system shall treat `source.mode = "auto"` as an evidenced Stage 1 configuration value.

**FR1.7.5**: The system shall not require broader config schema support for shipped Stage 1 behavior.

### FR1.8: Renderer-Backed Playback

**FR1.8.1**: The system shall display selected artwork through ansilust's parser-and-renderer pipeline rather than by raw file passthrough.

**FR1.8.2**: WHEN playback output is emitted the system shall pass terminal-context information through to the renderer.

**FR1.8.3**: IF parsing or rendering fails THEN the system shall return a playback error rather than silently degrade to a raw output path.

### FR1.9: Future Archive-Client Boundary

**FR1.9.1**: The system shall treat `.index.db` as a future archive-client capability rather than a shipped Stage 1 dependency.

**FR1.9.2**: The system shall treat search, pack downloads by name, archive browsing, aliases, protocol expansion, mirroring, and full archive management as future-facing work.

**FR1.9.3**: The system shall stage the catalog handoff in this order: Stage 1 hardcoded remote catalog, later shared local inventory, and only after that optional `.index.db` authority where separately shipped and evidenced.

### FR1.9.1A: Stage 2 Local Archive Enumeration Contract

**FR1.9.1A.1**: WHEN Stage 2 local archive enumeration is introduced the system shall define a local-archive source contract that reads only from filesystem state under the resolved 16colors root.

**FR1.9.1A.2**: The Stage 2 local-archive source contract shall treat discovered archive packs under `packs/` as local inventory candidates distinct from the shipped Stage 1 playable-file pool under `random/` and `local/`.

**FR1.9.1A.3**: The Stage 2 local-archive source contract shall require only pack enumeration metadata that can be derived directly from local archive files and paths, without requiring mirror manifests, remote selection metadata, or `.index.db`.

**FR1.9.1A.4**: IF Stage 2 local archive enumeration cannot derive richer metadata from a local archive file THEN the system shall still permit the pack to exist as an enumerated local candidate with minimal filesystem-derived identity.

**FR1.9.1A.5**: WHERE Stage 2 local archive enumeration is used for later workflows the system shall treat that enumerated local source as advisory local discovery input rather than immediate authoritative selection state.

**FR1.9.4**: WHEN shared local inventory is introduced the system shall treat it as the common local selection surface for playback, cache awareness, and local archive-pack enumeration before any `.index.db`-driven authority is adopted.

**FR1.9.5**: WHERE `.index.db` is introduced in a later stage the system shall specify whether it is advisory or authoritative for each workflow instead of implying an immediate global authority change.

**FR1.9.6**: IF `.index.db` is present before a later stage promotes it THEN the shipped runtime shall continue to behave according to the Stage 1 hardcoded-catalog and local-pool rules.

**FR1.9.7**: WHERE future archive-client capabilities are implemented the system shall specify them in later revisions of this document with separate evidenced requirements.

---

## NFR2: Non-Functional Requirements

### NFR2.1: Scope Discipline

**NFR2.1.1**: This specification shall distinguish shipped Stage 1 behavior from future archive-client intent.

**NFR2.1.2**: This specification shall not present future archive-management capabilities as current runtime guarantees.

### NFR2.2: Runtime Expectations

**NFR2.2.1**: The shipped runtime shall remain local-first for looping playback operations.

**NFR2.2.2**: The shipped runtime shall keep remote behavior narrow enough that `random-1` remains the only required fetch path.

**NFR2.2.3**: The shipped runtime shall rely on renderer-backed playback rather than raw terminal file dumping.

### NFR2.3: Documentation Quality

**NFR2.3.1**: Requirements statements shall remain internally consistent with `.ok/download.ok.md` and checked-in runtime behavior.

**NFR2.3.2**: Future-facing requirements shall be clearly labeled so they are not mistaken for shipped guarantees.

---

## TC3: Technical Constraints

### TC3.1: Shipped Stage 1 Constraints

**TC3.1.1**: The shipped runtime shall be specified around the standalone `16c` executable.

**TC3.1.2**: The shipped runtime shall not depend on `.index.db` or SQLite for current playback behavior.

**TC3.1.3**: The shipped runtime shall not require protocol families beyond the current hardcoded remote fallback path.

**TC3.1.4**: The shipped runtime shall not require alias executables such as `16colors` or `16`.

### TC3.2: Revision Constraints

**TC3.2.1**: Future archive-client capabilities shall be added by extending this specification instead of reinterpreting Stage 1 clauses.

**TC3.2.2**: Revised requirements shall continue to separate shipped guarantees from roadmap intent.

---

## DR4: Data Requirements

### DR4.1: Stage 1 Runtime Data

**DR4.1.1**: The runtime shall resolve a 16colors root directory used for `random/`, `local/`, and `packs/`.

**DR4.1.2**: The runtime shall treat cached remote artwork saved under `random/` as reusable local playback input.

**DR4.1.3**: The runtime shall treat `config.toml` in the 16colors root as the Stage 1 configuration file.

**DR4.1.4**: The runtime shall not require a shipped archive metadata database for Stage 1 operation.

### DR4.2: Future Archive-Client Data

**DR4.2.1**: `.index.db` shall remain a future archive-client data surface until shipped behavior promotes it to a required runtime artifact.

**DR4.2.2**: A future shared local inventory shall remain a distinct intermediate data surface for local selection, cache awareness, and local archive-pack enumeration rather than being conflated with `.index.db`.

**DR4.2.2A**: The future Stage 2 local-archive source contract shall derive its minimum identity from local filesystem-observable fields such as pack path, filename, and archive presence under `packs/`, without requiring extracted archive indexes or mirror-owned identifiers.

**DR4.2.3**: Archive search indexes, patch files, extracted pack metadata, and mirror manifests shall remain future-facing data structures.

---

## IR5: Integration Requirements

### IR5.1: Ansilust Integration

**IR5.1.1**: The Stage 1 runtime shall integrate with ansilust parsing and UTF8 ANSI rendering for displayed artwork.

**IR5.1.2**: The Stage 1 runtime shall use renderer-backed display for both locally selected artwork and `random-1` remote fallback playback.

### IR5.2: Future Archive Integration

**IR5.2.1**: Search, metadata, and mirror integration shall remain future archive-client integration work.

**IR5.2.2**: Cross-tool archive interoperability based on `.index.db` shall remain future-facing until separately shipped.

---

## DEP6: Dependencies

### DEP6.1: Shipped Runtime Dependencies

**DEP6.1.1**: The shipped runtime shall depend on the ansilust playback pipeline for parsing and rendering displayed artwork.

**DEP6.1.2**: The shipped runtime shall depend on local filesystem access for local-first selection and cache persistence.

### DEP6.2: Future Archive-Client Dependencies

**DEP6.2.1**: SQLite and related archive-index dependencies shall remain future-facing until `.index.db` becomes a shipped runtime requirement.

**DEP6.2.2**: Expanded protocol clients, mirror tooling, and archive-management dependencies shall remain future-facing.

---

## SC7: Success Criteria

### SC7.1: Shipped Stage 1 Success Criteria

**SC7.1.1**: A user can run `16c random` or `16c screensaver` against a non-empty local pool and receive looping renderer-backed playback.

**SC7.1.2**: A user who runs `16c random` or `16c screensaver` with an empty local pool receives a descriptive local-only failure instead of implicit remote fetching.

**SC7.1.3**: A user can run `16c random-1` and receive a single artwork display from a local candidate or the hardcoded remote fallback path.

**SC7.1.4**: The shipped requirements do not imply `.index.db`, search, pack downloads, aliases, protocol expansion, or mirroring as already delivered functionality.

### SC7.2: Documentation Success Criteria

**SC7.2.1**: Readers can distinguish current Stage 1 guarantees from future archive-client plans without referring to implementation code.

**SC7.2.2**: The requirements document stays consistent with `.ok/download.ok.md` regarding local-first playback, minimal config loading, narrow remote fallback, and renderer-backed display.

---

## Requirements Traceability

### Stage Mapping

| Current Stage | Requirements Sections |
|---------------|-----------------------|
| Shipped Stage 1 runtime | FR1.1-FR1.8, NFR2, TC3.1, DR4.1, IR5.1, DEP6.1, SC7.1 |
| Future archive-client work | FR1.9, TC3.2, DR4.2, IR5.2, DEP6.2 |

### Boundary Mapping

| Area | Present Requirement Status |
|------|----------------------------|
| `random`, `screensaver`, `random-1` | Shipped Stage 1 |
| Local-first looping playback | Shipped Stage 1 |
| Minimal playback flags | Shipped Stage 1 |
| Minimal config loading | Shipped Stage 1 |
| Hardcoded remote fallback for `random-1` | Shipped Stage 1 |
| Renderer-backed display | Shipped Stage 1 |
| Stage 2 local archive enumeration from `packs/` | Future staged local contract before `.index.db` authority |
| Shared local inventory for unified local awareness | Future staged handoff before `.index.db` authority |
| `.index.db`, search, pack downloads, mirroring | Future archive-client |
| Alias executables, protocol expansion, full archive management | Future archive-client |

---

This requirements specification now defines the shipped Stage 1 `16c` runtime as the current contract and preserves broader archive-client ambitions as future work rather than present-tense guarantees.
