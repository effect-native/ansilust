# Download OK

This file governs ansilust's current download and archive-surface reality. It translates `.specs/download/` into binary constitutional truth so reconciliation stays anchored to checked-in behavior and tests rather than aspirational client and mirror plans.

## Governing References

- Constitution source intent: `.specs/download/instructions.md`, `.specs/download/requirements.md`, `.specs/download/design.md`, `.specs/download/plan.md`
- Live build wiring: `build.zig`
- Live CLI and module surface: `src/cli/sixteenc.zig`, `src/download/lib.zig`
- Live command, config, and backend wiring: `src/download/commands/random.zig`, `src/download/commands/stage1_config.zig`, `src/download/database/interface.zig`, `src/download/database/hardcoded.zig`, `src/download/protocols/http.zig`, `src/download/storage/paths.zig`, `src/download/storage/files.zig`
- Live test evidence: `src/download/commands/random_test.zig`, `src/download/database/interface_test.zig`, `src/download/protocols/http_test.zig`, `src/download/storage/paths_test.zig`, `src/download/storage/files_test.zig`
- Live artifact status: no checked-in download-specific artifact directory currently provides stronger evidence than the code, build wiring, and tests above

## Live Checked-In Evidence

- The shipped download surface is build-wired in `build.zig`, which installs a standalone `16c` executable from `src/cli/sixteenc.zig` and does not install `16colors`, `16`, or an `ansilust --16colors` entrypoint.
- The current CLI contract is checked in at `src/cli/sixteenc.zig`, where `random`, `screensaver`, `random-1`, `--help`/`-h`, and `--version`/`-v` are recognized command paths, `random` dispatches through `executeRandomLoop`, `screensaver` dispatches through `executeScreensaverWithMode`, `random-1` dispatches through `executeRandomOne`, and unknown commands fail fast.
- The same CLI surface also exposes the currently evidenced playback flags `--instant` and `--streaming-speed <preset>` for `random` and `screensaver`, rejects conflicting flag combinations, and limits streaming presets to `slow`, `normal`, and `fast` in `src/cli/sixteenc.zig`.
- The public download module surface is checked in at `src/download/lib.zig`, which currently re-exports the database interface module, `commands.random`, `RandomPlaybackLoop`, `protocols.http`, and `storage.paths` plus `storage.files`.
- The current end-to-end download workflow lives in `src/download/commands/random.zig`, where `16c random-1` creates platform directories, first tries to replay a local file from `random/` or `local/`, and only when that local pool is empty falls back to the archive database, downloads one file to `/tmp`, saves it under `random/`, calls random-cache cleanup, and displays the saved file through ansilust's ANSI parser plus UTF8ANSI renderer.
- The checked-in Stage 1 local-source policy is also in `src/download/commands/random.zig`: `selectLocalArtwork` scans `random/` and `local/`, filters to `.ans` and `.asc`, prefers any playable local candidate before remote fallback, and returns `error.EmptyLocalArtworkPool` with guidance when `random` or `screensaver` runs without a playable local file.
- Minimal Stage 1 config loading is checked in at `src/download/commands/random.zig` and `src/download/commands/stage1_config.zig`: `random` and `screensaver` load `config.toml` from `paths.sixteen_colors_root`, missing config files fall back to built-in defaults, and the only evidenced parsed knobs are `[playback] dwell_seconds` and `[source] mode = "auto"`.
- Current archive-source reality is checked in at `src/download/database/interface.zig` and `src/download/database/hardcoded.zig`: `ArchiveDatabase.init` always selects the hardcoded implementation, `searchFiles` and `listPacksByYear` stay stubbed, `getPack` returns `error.NotImplemented`, and the curated file list currently contains only `mist1025/CXC-STICK.ASC`.
- Current network and storage behavior is checked in at `src/download/protocols/http.zig`, `src/download/storage/paths.zig`, and `src/download/storage/files.zig`: downloads shell out through `sh -c` to `curl`, storage resolves a `16colors` root plus `random/`, `packs/`, and `local/`, `saveToRandom` writes timestamped files only under `random/`, and `cleanupRandom` is called with a keep-last-10 contract but still remains a no-op stub.
- Current validation evidence is checked in at `src/download/commands/random_test.zig`, `src/download/database/interface_test.zig`, `src/download/protocols/http_test.zig`, `src/download/storage/paths_test.zig`, and `src/download/storage/files_test.zig`; these tests now also pin local-pool-first selection, playable-extension filtering, Stage 1 config defaults, and current playback/runtime surface more than full archive behavior.
- Evidence for SQLite indexing, pack extraction, pack browsing, mirror sync, alias executables, local-art management, renderer-backed display, or protocol fallback is currently negative: no checked-in code, tests, or stable artifacts promote those behaviors beyond spec intent.

## Ideal End State

- TRUE: The current shipped download surface is an MVP centered on the standalone `16c` executable plus its `random`, `screensaver`, and `random-1` entrypoints, with `random-1` still serving as the one-piece fetch-and-display path.
- TRUE: The current `16c` CLI contract includes `random`, `screensaver`, `random-1`, `--help`/`-h`, and `--version`/`-v`, while the checked-in help text and help test promote `random` and `screensaver` as the public-facing looping examples.
- TRUE: The current playback flag surface for `random` and `screensaver` is limited to `--instant` and `--streaming-speed <preset>`; those flags preserve explicit playback mode choice, but they do not by themselves evidence broader renderer simulation, overlays, or additional playback controls.
- TRUE: `.specs/download/**` consistently frames a much broader archive client, but present-tense constitutional truth stays pinned to the checked-in MVP rather than to the full spec program.
- TRUE: Current random artwork selection is backed by the `download` module's archive-database abstraction with a hardcoded implementation.
- TRUE: The only evidenced remote artwork source today is the single hardcoded `mist1025/CXC-STICK.ASC` entry in `src/download/database/hardcoded.zig`.
- TRUE: Current network download reality is HTTP-only behavior routed through `HttpClient.download`, which shells out to `curl` via `sh -c` instead of a native multi-protocol client.
- TRUE: Current storage reality resolves a platform-specific `16colors` root plus `random/`, `packs/`, and `local/` subdirectories, but the shipped command writes only the `random/` cache.
- TRUE: The governing storage distinction from `.specs/download/**` is binary: `packs/` is for official archive material and `local/` is for user-managed material, but checked-in download behavior does not yet populate either surface as archive-management reality.
- TRUE: Stage 1 local-first playback is current truth: `random`, `screensaver`, and the shared runtime first scan `random/` and `local/` for playable `.ans` or `.asc` files before any remote archive fallback is considered.
- TRUE: That local-first policy is asymmetric by command: `random-1` may fall back to the hardcoded remote source when the local pool is empty, while `random` and `screensaver` currently stop with `error.EmptyLocalArtworkPool` plus guidance instead of fetching remotely.
- TRUE: Minimal Stage 1 config loading is current truth only for `random` and `screensaver`: the runtime reads `config.toml` under the `16colors` root when present, otherwise uses built-in defaults, and only `playback.dwell_seconds` plus `source.mode = "auto"` are evidenced.
- TRUE: Spec references to `collections/`, `.index.db`, `patches/`, or tool-specific cache/config directories describe intended ecosystem structure, not current shipped guarantees, unless separate evidence is promoted here.
- TRUE: Current post-download display behavior for `16c random-1` is parser-and-renderer-based output through `ansilust.parsers.ansi.parse` plus `ansilust.renderToUtf8Ansi`, with `isatty` passed through to the renderer.
- TRUE: The broad archive workflows described in spec examples (`download`, `list`, `search`, `show`, `mirror`, `db`, `stats`, `local`) remain future-facing because the current constitutional CLI surface still exposes none of them.
- TRUE: Spec claims about a dual-CLI experience (`16c` archive-first and `ansilust --16colors` file-first integration) are design intent; only the standalone `16c` path is evidenced in current checked-in download reality.
- TRUE: `.specs/download/**` treats `.index.db` as the canonical search and metadata authority, but current checked-in download behavior relies on a hardcoded in-memory source list instead of a shipped archive database.
- TRUE: `.specs/download/**` repeatedly assumes download-side extraction, indexing, pack preservation, and metadata persistence, but none of those behaviors become constitutional truth without direct checked-in evidence.
- TRUE: Current checked-in download tests cover interface shape, hardcoded database selection, URL/path invariants, and compile-time API wiring more than end-to-end archive behavior; that evidence is the present validation floor.
- TRUE: `.specs/download/**` may describe future SQLite, mirror, search, archive-browsing, alias, and protocol work, but only assertions promoted here are constitutional truth for download reconciliation.

## States We Do Not Want

- FALSE: Dual-CLI behavior from spec prose, including `ansilust --16colors`, is treated as shipped download reality without matching checked-in evidence.
- FALSE: `16colors` and `16` aliases are treated as active guarantees while `build.zig` installs only the `16c` executable.
- FALSE: SQLite `.index.db`, FTS5 archive search, auto-updating metadata, patch downloads, or canonical `ansilust.com/16colors/` hosting are treated as present-tense obligations without implemented evidence.
- FALSE: FTP, RSYNC, protocol fallback, resumable downloads, ZIP extraction, mirror sync, pack listing, pack download by name, local-art management, or stats commands are treated as shipped behavior because they appear in `.specs/download/**`.
- FALSE: Storage-standard prose from `.specs/download/**` is read as proof that `collections/`, `patches/`, shared `.index.db`, or cross-tool interoperability already exist in the shipped download surface.
- FALSE: Database-centered search and metadata requirements from `.specs/download/**` are treated as current truth while the implementation still selects from hardcoded archive entries.
- FALSE: The presence of `screensaver`, playback flags, or minimal `config.toml` parsing is stretched into proof of broader local-library management, source filtering beyond `auto`, richer config schema, or post-MVP playback controls.
- FALSE: Acceptance-criteria examples that mention extraction, progress UI, integrity verification, background updates, alias executables, or broader archive workflows are promoted to shipped reality without checked-in evidence.
- FALSE: Stale claims that the public CLI exposes only `random-1` or that playback still shells out through raw `cat` override the current evidence in `src/cli/sixteenc.zig`, `src/download/lib.zig`, `src/download/commands/random.zig`, and `src/download/commands/random_test.zig`.
- FALSE: `packs/` or `local/` directory creation is mistaken for completed pack-management or user-content-management features.
- FALSE: Plan checklist progress or comments about future renderer integration override the actual behavior in checked-in code and tests.

## Required Governance Rules

- TRUE: Changes to the `16c` command surface, download backend, hardcoded archive source set, storage layout, or display handoff require updating this file in the same reconciliation loop.
- TRUE: Download completion claims must be backed by checked-in code, tests, or build wiring; spec intent and plan prose are not sufficient evidence.
- TRUE: Every new TRUE implementation claim in this file must cite at least one live checked-in code, test, build, or artifact path that demonstrates the claim.
- TRUE: Downstream orchestration may rely only on download/archive guarantees declared TRUE here.
- TRUE: Expanding download scope remains binary: a capability is either promoted here as current truth or it is still future, partial, or unevidenced.
