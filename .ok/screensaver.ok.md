# Screensaver OK

This file governs ansilust's current screensaver reality and its shortest-path delivery ladder. It translates `.specs/screensaver/` intent into binary constitutional truth anchored to checked-in CLI, download, and renderer evidence instead of promoting the full showcase spec as shipped behavior.

## Governing References

- Constitution source intent: `.specs/screensaver/instructions.md`, `.specs/screensaver/requirements.md`, `.specs/screensaver/design.md`, `.specs/screensaver/plan.md`
- Gap framing: `.tasks/artifacts/gaps-snapshot-20260320001837.md`
- Live CLI surface: `src/cli/sixteenc.zig`
- Live runtime, config, and session path: `src/download/commands/random.zig`, `src/download/commands/stage1_config.zig`
- Live test evidence: `src/cli/sixteenc.zig`, `src/download/commands/random_test.zig`
- Neighbor constitutions: `.ok/download.ok.md`, `.ok/render-utf8ansi.ok.md`

## Live Checked-In Evidence

- The checked-in `16c` CLI surface currently exposes `random`, `screensaver`, `random-1`, `--help`/`-h`, and `--version`/`-v` in `src/cli/sixteenc.zig`; the help text and tests there promote `16c random` and `16c screensaver` as the public looping/session command surfaces.
- `src/download/commands/random.zig` contains both `RandomPlaybackLoop` and `ScreensaverPlaybackLoop`; `random` loops playback in-place and `screensaver` wraps the same playback path in a dedicated session lifecycle.
- The shared Stage 1 playback path in `src/download/commands/random.zig` is local-pool-first and local-only for looping modes: it scans `random/` and `local/` for playable `.ans` and `.asc` files before any remote fallback point, and `random` plus `screensaver` return `error.EmptyLocalArtworkPool` with guidance instead of fetching remotely when no local file exists.
- Minimal Stage 1 config loading is evidenced in `src/download/commands/random.zig` and `src/download/commands/stage1_config.zig`: `random` and `screensaver` load `config.toml` from the `16colors` root, missing files fall back to defaults, and the shipped config surface is limited to `[playback] dwell_seconds` plus `[source] mode = "auto"`.
- `src/download/commands/random.zig` also shows that artwork display is ansilust-owned: `displayArtwork` reads the selected file, parses it with `ansilust.parsers.ansi.parse`, renders it with `ansilust.renderToUtf8Ansi`, and writes the result to stdout.
- `src/download/commands/random.zig` and `src/download/commands/random_test.zig` evidence current session cleanup behavior for `screensaver`: alternate-screen enter/leave, cursor hide/restore, stdin-driven exit during dwell, and best-effort SIGINT/SIGTERM cleanup are implemented, while random-cache file cleanup still remains a TODO in `src/download/storage/files.zig`.

## Capability Ladder

- TRUE: The current baseline is no longer `random-1` alone. Checked-in runtime evidence now includes looping `16c random`, dedicated `16c screensaver`, and renderer-backed playback through ansilust's parser and UTF8ANSI renderer.
- TRUE: The current Stage 1 playback source policy is local-pool-first for looping modes: `random` and `screensaver` scan `random/` plus `local/`, replay a playable local file when found, and do not fetch remotely when the local pool is empty.
- TRUE: `16c random-1` remains the single-piece bridge command: it can still seed `random/` by falling back to the hardcoded remote source, stores the fetched artwork under `random/`, renders it through ansilust, and exits.
- TRUE: The current standard dwell default is 20 seconds, and `random` plus `screensaver` can override that only through the minimal Stage 1 config surface in `config.toml`; `--instant` and `--streaming-speed <preset>` remain the only shipped playback flags.
- TRUE: The current `screensaver` session surface owns basic terminal lifecycle cleanup when stdout is a TTY: it enters and leaves the alternate screen, hides and restores the cursor, exits when input arrives during dwell, and restores signal handlers on best-effort SIGINT/SIGTERM cleanup.
- TRUE: This is still a narrow Stage 1 surface. The repo does not yet evidence pack-based local pools, richer source modes, metadata overlays, `.index.db` selection, desktop idle-manager integration, or a broader persisted screensaver config schema.
- FUTURE: Stage 1 shortest-path MVP beyond the current shipped surface is limited to hardening and finishing what is already present, not to expanding scope into Stage 2+ archive or desktop integration work.
- FUTURE: Stage 2 is post-MVP art-source growth and remains dependent on future local archive inventory work from the download surface, including broader local cache or mirror enumeration and optional `.index.db`-backed selection, as described in `.specs/screensaver/requirements.md` and `.ok/download.ok.md`.
- FUTURE: Stage 3 is post-MVP config expansion and remains dependent on a future persisted screensaver config surface for duration, filters, overlays, and other playback policy controls; no such config surface is current truth in checked-in repo evidence.
- FUTURE: Stage 4 is post-MVP launch and packaging integration and remains dependent on future owned docs or artifacts for systemd user services, hypridle or swayidle hooks, packaging-time artwork availability, and other desktop-launch surfaces; `.ok/deployments.ok.md` does not currently promote those channels as shipped deployment guarantees.
- TRUE: The shortest path remains intentionally decomposed: the repo has already crossed into local-pool-first loop playback plus dedicated screensaver-session reality, so later stages stay optional and future-facing until separately evidenced.

## Dependency Boundaries

- TRUE: The shortest-path MVP is intentionally defined to depend on the already-shipped ansilust-owned playback wiring plus the now-shipped local artwork enumeration over `random/` and `local/`; `.specs/screensaver/requirements.md` records the broader MVP boundary in `DEP6.1` and excludes `.index.db`, mirror bootstrap, and desktop-specific launch infrastructure in `TC3.2` and `TC3.3`.
- TRUE: Mirror, database, and richer local-library work are post-MVP dependencies, not MVP prerequisites; `.specs/screensaver/requirements.md` records them in `FR1.4`, `DEP6.2`, and `SC7.2`, and `.ok/download.ok.md` says the current repo still lacks shipped `.index.db`, mirror sync, and broader archive-management behavior.
- TRUE: Broader persistent config is a post-MVP dependency, not an MVP prerequisite; `.specs/screensaver/requirements.md` records config work in `FR1.5` and `DEP6.3`, while the current repo only evidences the narrow Stage 1 `config.toml` surface for dwell seconds and `source.mode = "auto"`.
- TRUE: Launch, idle-manager, service, and packaging integration are post-MVP dependencies, not MVP prerequisites; `.specs/screensaver/requirements.md` records them in `FR1.6`, `DEP6.4`, and `SC7.4`, and `.ok/deployments.ok.md` says a channel is not supported just because a spec or script exists.
- TRUE: Because current checked-in runtime evidence stops at local-pool-first looping playback, minimal config loading, and basic screensaver terminal cleanup, every broader screensaver claim remains FUTURE until code, tests, or owned artifacts explicitly promote it here.

## States We Do Not Want

- FALSE: Spec-only commands or behaviors are treated as shipped without matching CLI, runtime, and test evidence; `16c random` and `16c screensaver` are now evidenced, but later-stage archive growth, config expansion, and desktop integration are not.
- FALSE: The shortest-path looping MVP is treated as blocked on `.index.db`, mirror sync, curated bootstrap, systemd integration, or other later-stage infrastructure when local-loop playback can be delivered separately.
- FALSE: Stage 2 archive growth, Stage 3 config work, or Stage 4 launch and packaging work are collapsed into Stage 1 and then treated as proof that the MVP itself is blocked.
- FALSE: The current Stage 1 config and playback surface is overstated into support for filters, richer source selection, overlays, or other controls that the checked-in parser and loader do not yet implement.
- FALSE: Renderer ambitions such as streaming baud simulation, scaling modes, SAUCE-driven layout, or metadata overlays are treated as current screensaver guarantees without checked-in implementation evidence on this surface.
- FALSE: Example service files, Hyprland rules, config snippets, or idle-manager examples in `.specs/screensaver/**` are treated as installed or supported artifacts when no owned repo artifacts or docs currently exist.
- FALSE: Later-stage ladder items override present-tense truth; until a stage is evidenced in checked-in code, tests, or owned artifacts, it remains future-facing here.

## Required Governance Rules

- TRUE: Changes to the `16c` command surface, playback path, fullscreen lifecycle, config handling, mirror selection, or idle-system integration require updating this file in the same reconciliation loop.
- TRUE: Screensaver advancement claims must identify which ladder stage became current truth and must be backed by checked-in code, tests, or owned artifacts; spec prose and examples are not sufficient evidence.
- TRUE: Every new TRUE implementation claim in this file must cite at least one live checked-in code, test, or artifact path that demonstrates the claim.
- TRUE: Downstream orchestration may rely only on screensaver guarantees declared TRUE here, not on FUTURE ladder stages.
- TRUE: Screensaver scope remains binary at each stage boundary: a capability is either evidenced and governed here as current truth or it remains future, partial, or unevidenced.
