# 16colors Download Plan

This plan tracks the download/archive surface against the shipped Stage 1 runtime instead of the older pre-runtime roadmap. It separates what is already present in the `16c` executable from the broader archive client still planned for later phases.

## Execution Baseline

- The current repository already ships the Stage 1 runtime through the standalone `16c` executable.
- The shipped command surface is `random`, `screensaver`, and `random-1`, plus `--help` and `--version`.
- The shipped playback path is renderer-backed: the runtime parses ANSI art and renders through ansilust instead of treating display integration as future work.
- Looping playback is local-pool-first for `random` and `screensaver`: the runtime scans `random/` and `local/` for playable `.ans` and `.asc` files before any remote fallback point.
- `random-1` remains the only shipped remote bridge: it can replay a local file first, and if the local pool is empty it falls back to the hardcoded archive source, saves the result under `random/`, and displays it.
- Minimal Stage 1 config loading is already shipped for `random` and `screensaver`; the evidenced config surface is limited to `playback.dwell_seconds` plus `source.mode = "auto"`.
- Archive-scale features such as `.index.db`, pack downloads, extraction, search, mirror sync, metadata persistence, and broader local archive management remain intentionally pending.

## Legacy Plan Translation

- The old plan treated renderer integration, end-to-end runtime wiring, and the basic `16c` surface as still unfinished. That is now stale.
- The current planning problem is no longer "make `16c random-1` basically exist." The shipped baseline already exists and is usable.
- Future work should grow from the shipped Stage 1 runtime instead of re-describing it as an MVP still waiting on renderer hookup or CLI assembly.
- The remaining roadmap is now archive growth: richer source data, pack acquisition, indexing, search, sync, and local library management.

## Milestones

- [x] M1. Stage 1 runtime foundation shipped
- [x] M2. Renderer-backed playback and looping command surface shipped
- [ ] M3. Archive acquisition growth
- [ ] M4. Indexed browsing and search
- [ ] M5. Mirror sync and broader archive management

## Phase Status Table

| Phase | Status | What it means now |
|------|--------|-------------------|
| Phase 1 - Shipped Stage 1 runtime | [x] Complete | `16c` ships `random`, `screensaver`, and `random-1`; playback is renderer-backed; local-pool-first looping and minimal config are present |
| Phase 2 - Archive acquisition growth | [ ] Pending | Pack downloads, extraction, and archive-aware acquisition remain future work |
| Phase 3 - Indexed browsing and search | [ ] Pending | `.index.db`, metadata storage, pack/file search, and local browsing commands are not shipped yet |
| Phase 4 - Mirror sync and local archive management | [ ] Pending | Mirror refresh, broader local library management, and large-scale archive workflows remain future work |

## Work Packages

### [WP-RUN-001] Shipped Stage 1 Runtime Surface

**Intent**: Record the current download/runtime baseline as already landed so later work builds on repository truth.

**Acceptance**:
- The plan treats `16c random`, `16c screensaver`, and `16c random-1` as shipped command surfaces.
- Renderer-backed playback is treated as current behavior, not a future dependency.
- Looping playback is explicitly local-pool-first for `random` and `screensaver`.
- `random-1` remains the only shipped remote fallback path.

**Status**: [x] Complete

### [WP-RUN-002] Stage 1 Runtime Hardening

**Intent**: Finish small adjacent runtime cleanup without inflating the archive roadmap.

**Acceptance**:
- Current docs stay aligned with the shipped CLI, playback, and config surface.
- Remaining Stage 1 polish items are framed as hardening only.
- Runtime cleanup does not get confused with archive-growth milestones.
- Known limitations such as the current `cleanupRandom` stub stay explicit until implemented.

**Status**: [~] In Progress

### [WP-ARCH-001] Archive Acquisition Beyond `random-1`

**Intent**: Grow from the one-piece remote bridge into pack-aware archive acquisition.

**Acceptance**:
- Pack download commands are defined and implemented beyond the hardcoded single-file source.
- Pack acquisition includes archive-aware storage under `packs/`.
- Pack extraction and preserved pack layout are handled by owned code.
- Progress/error reporting is documented against implemented behavior.

**Status**: [ ] Pending

### [WP-INDEX-001] `.index.db` And Metadata Authority

**Intent**: Replace the hardcoded in-memory source list with a real local archive index.

**Acceptance**:
- `.index.db` exists as the owned local metadata/index authority.
- Archive metadata and file records persist beyond the current hardcoded source list.
- The runtime can query indexed archive information without changing the public CLI story.
- Search and browse features consume the index instead of relying on ad hoc stubs.

**Status**: [ ] Pending

### [WP-INDEX-002] Search And Local Browsing Commands

**Intent**: Add user-facing archive discovery once the index exists.

**Acceptance**:
- Search commands are backed by shipped index/query behavior.
- Local browsing commands can enumerate downloaded packs and playable files.
- Command help and tests describe the actual supported archive-browsing surface.
- Search/browse scope is separated from sync and mirror management.

**Status**: [ ] Pending

### [WP-MIRROR-001] Mirror Sync And Archive Management

**Intent**: Add broader long-lived archive workflows after acquisition and indexing exist.

**Acceptance**:
- Mirror sync is explicit owned behavior rather than spec-only intent.
- Broader local archive management covers more than the current `random/` cache and user-managed `local/` pool.
- Sync/update workflows are separated from the shipped Stage 1 playback baseline.
- Large-scale archive operations are backed by code, tests, and docs before being treated as complete.

**Status**: [ ] Pending

## Detailed Progress Table

| Area | Current truth | Remaining work |
|------|---------------|----------------|
| CLI surface | `16c`, `random`, `screensaver`, `random-1`, help/version are shipped | Add future archive commands only when implemented |
| Playback integration | Parser + UTF8ANSI renderer path is shipped | Limit future work to polish, not baseline integration |
| Local source policy | `random` and `screensaver` are local-pool-first over `random/` and `local/` | Grow into pack-aware local selection and broader library controls |
| Remote source policy | `random-1` can fall back to one hardcoded remote entry | Replace with pack-aware acquisition and indexed sources |
| Config | Minimal Stage 1 config for `playback.dwell_seconds` and `source.mode = "auto"` is shipped | Keep richer source/config management pending |
| Storage | `16colors` root plus `random/`, `packs/`, and `local/` paths exist | Populate `packs/` with real archive workflows; expand local archive management later |
| Indexing | No shipped `.index.db` yet | Add SQLite or other owned index implementation |
| Search | No shipped search/browse commands yet | Add indexed search and local archive browsing |
| Mirror sync | No shipped mirror sync yet | Add explicit sync/update workflows later |

## Validation Checkpoints

- **Docs truth**: `.specs/download/plan.md` must stay aligned with `.ok/download.ok.md` and the checked-in `16c` runtime surface.
- **Build truth**: `build.zig` and `src/cli/sixteenc.zig` remain the source of truth for what commands are actually shipped.
- **Runtime truth**: `src/download/commands/random.zig` and `src/download/commands/stage1_config.zig` remain the source of truth for local-pool-first playback, `random-1` fallback behavior, and minimal config scope.
- **Archive-growth truth**: `.index.db`, pack acquisition, search, mirror sync, and broader local archive management stay pending until backed by code and tests.

## Risks And Guardrails

- Do not regress into describing renderer integration or the Stage 1 CLI/runtime surface as unfinished when the code already ships those behaviors.
- Do not let future `.index.db`, search, or mirror plans rewrite current truth; they are pending growth layers.
- Do not treat directory creation for `packs/` or `local/` as proof that pack management or local archive management is complete.
- Keep Stage 1 hardening separate from archive-growth scope so small runtime cleanup does not turn into a vague "Phase 1 still in progress" claim.

## Next Steps

1. Keep the shipped Stage 1 runtime documented as complete while landing only adjacent hardening.
2. Define and implement pack-aware downloads so archive acquisition grows beyond `random-1`.
3. Introduce `.index.db` as the owned archive metadata/search boundary.
4. Add search and local browsing commands on top of the shipped index.
5. Add mirror sync and broader local archive management only after acquisition and indexing are real.

## Success Criteria Validation

- Stage 1 is considered complete in planning terms because the repo already ships the `16c` runtime surface, renderer-backed playback, and minimal config/runtime behavior.
- Future completion claims for pack downloads, `.index.db`, search, mirror sync, and broader local archive management require direct implementation evidence.
- This plan stays correct only if it distinguishes shipped runtime truth from later archive-client growth.
