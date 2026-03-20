# Screensaver OK

This file governs ansilust's current screensaver reality and its shortest-path delivery ladder. It translates `.specs/screensaver/` intent into binary constitutional truth anchored to checked-in CLI, download, and renderer evidence instead of promoting the full showcase spec as shipped behavior.

## Governing References

- Constitution source intent: `.specs/screensaver/instructions.md`, `.specs/screensaver/requirements.md`, `.specs/screensaver/design.md`, `.specs/screensaver/plan.md`
- Gap framing: `.tasks/artifacts/gaps-snapshot-20260320001837.md`
- Live CLI surface: `src/cli/sixteenc.zig`
- Live one-shot runtime path: `src/download/commands/random.zig`
- Neighbor constitutions: `.ok/download.ok.md`, `.ok/render-utf8ansi.ok.md`

## Live Checked-In Evidence

- The checked-in `16c` CLI surface currently exposes `random`, `random-1`, `--help`/`-h`, and `--version`/`-v` in `src/cli/sixteenc.zig`; the help text and test at `src/cli/sixteenc.zig` promote `16c random` as the primary looping command surface.
- `src/download/commands/random.zig` contains a real `RandomPlaybackLoop` used by `16c random`; it repeatedly calls `executeRandomOne` and therefore provides checked-in looping playback rather than a `random-1`-only runtime.
- `src/download/commands/random.zig` also shows that artwork display is now ansilust-owned: `displayArtwork` reads the saved file, parses it with `ansilust.parsers.ansi.parse`, renders it with `ansilust.renderToUtf8Ansi`, and writes the result to stdout.
- `src/download/commands/random_test.zig` contains a checked-in test asserting that playback routes artwork through the parser and UTF8ANSI renderer, so renderer-backed playback is repo evidence, not spec intent only.
- The active download constitution in `.ok/download.ok.md` still says random artwork selection comes from a hardcoded in-memory database entry, not a shipped `.index.db`, broad local-library selector, or mirror-query surface.
- `src/download/storage/files.zig` still marks random-cache cleanup as TODO, and the current looping path does not evidence config loading, dwell controls, alternate-screen handling, cursor management, input-exit behavior, or a dedicated `16c screensaver` command.

## Capability Ladder

- TRUE: The current baseline is no longer `random-1` alone. Checked-in runtime evidence now includes `16c random` plus renderer-backed playback through ansilust's parser and UTF8ANSI renderer.
- TRUE: The current loop is still only a partial Stage 1 runtime. `RandomPlaybackLoop` repeatedly reuses the same hardcoded-download path from `executeRandomOne`, so the playable source remains remote-entry-driven rather than a real local-pool selector over `random/`, `packs/`, or `local/`.
- TRUE: `16c random-1` remains the single-piece command: it fetches one artwork, stores it under `random/`, renders it through ansilust, and exits.
- TRUE: `16c random` currently gives the repo a real continuous playback path, but it does not yet evidence dwell flags, config loading, playback-mode flags, empty-local-pool policy, signal-aware session ownership, or bounded cleanup beyond the existing per-piece call sites.
- TRUE: A dedicated `16c screensaver` command is still not current truth; the repo does not currently evidence alternate-screen lifecycle handling, cursor hide/restore, exit-on-input behavior, or owned fullscreen session cleanup.
- FUTURE: Stage 1 shortest-path MVP is now the gap-closing layer on top of the shipped partial runtime: keep the existing loop and renderer path, but add local-pool-first selection, explicit dwell policy, playback/config loading, `16c screensaver`, and reliable terminal/session cleanup without making `.index.db`, mirror sync, bootstrap downloads, or desktop integration mandatory.
- FUTURE: Stage 2 is post-MVP art-source growth and remains dependent on future local archive inventory work from the download surface, including broader local cache or mirror enumeration and optional `.index.db`-backed selection, as described in `.specs/screensaver/requirements.md` and `.ok/download.ok.md`.
- FUTURE: Stage 3 is post-MVP config expansion and remains dependent on a future persisted screensaver config surface for duration, filters, overlays, and other playback policy controls; no such config surface is current truth in checked-in repo evidence.
- FUTURE: Stage 4 is post-MVP launch and packaging integration and remains dependent on future owned docs or artifacts for systemd user services, hypridle or swayidle hooks, packaging-time artwork availability, and other desktop-launch surfaces; `.ok/deployments.ok.md` does not currently promote those channels as shipped deployment guarantees.
- TRUE: The shortest path remains intentionally decomposed: the repo has already crossed from one-shot display into loop-plus-renderer reality, and the remaining Stage 1 work is now local source policy plus screensaver/session hardening rather than basic playback existence.

## Dependency Boundaries

- TRUE: The shortest-path MVP is intentionally defined to depend only on future local artwork enumeration plus the already-shipped ansilust-owned playback wiring; `.specs/screensaver/requirements.md` records those MVP dependencies in `DEP6.1` and excludes `.index.db`, mirror bootstrap, and desktop-specific launch infrastructure in `TC3.2` and `TC3.3`.
- TRUE: Mirror, database, and richer local-library work are post-MVP dependencies, not MVP prerequisites; `.specs/screensaver/requirements.md` records them in `FR1.4`, `DEP6.2`, and `SC7.2`, and `.ok/download.ok.md` says the current repo still lacks shipped `.index.db`, mirror sync, and broader archive-management behavior.
- TRUE: Persistent config is a post-MVP dependency, not an MVP prerequisite; `.specs/screensaver/requirements.md` records config work in `FR1.5` and `DEP6.3`, while the current repo does not evidence a shipped screensaver config surface.
- TRUE: Launch, idle-manager, service, and packaging integration are post-MVP dependencies, not MVP prerequisites; `.specs/screensaver/requirements.md` records them in `FR1.6`, `DEP6.4`, and `SC7.4`, and `.ok/deployments.ok.md` says a channel is not supported just because a spec or script exists.
- TRUE: Because current checked-in runtime evidence stops at `16c random` plus reused hardcoded fetches and stdout renderer playback, every screensaver claim beyond that partial baseline remains FUTURE until code, tests, or owned artifacts explicitly promote it here.

## States We Do Not Want

- FALSE: Spec-only commands or behaviors are treated as shipped without matching CLI, runtime, and test evidence; `16c random` is now evidenced, but `16c screensaver` and its session behaviors are not.
- FALSE: The shortest-path looping MVP is treated as blocked on `.index.db`, mirror sync, curated bootstrap, systemd integration, or other later-stage infrastructure when local-loop playback can be delivered separately.
- FALSE: Stage 2 archive growth, Stage 3 config work, or Stage 4 launch and packaging work are collapsed into Stage 1 and then treated as proof that the MVP itself is blocked.
- FALSE: Renderer ambitions such as streaming baud simulation, scaling modes, SAUCE-driven layout, or metadata overlays are treated as current screensaver guarantees without checked-in implementation evidence on this surface.
- FALSE: Example service files, Hyprland rules, config snippets, or idle-manager examples in `.specs/screensaver/**` are treated as installed or supported artifacts when no owned repo artifacts or docs currently exist.
- FALSE: Later-stage ladder items override present-tense truth; until a stage is evidenced in checked-in code, tests, or owned artifacts, it remains future-facing here.

## Required Governance Rules

- TRUE: Changes to the `16c` command surface, playback path, fullscreen lifecycle, config handling, mirror selection, or idle-system integration require updating this file in the same reconciliation loop.
- TRUE: Screensaver advancement claims must identify which ladder stage became current truth and must be backed by checked-in code, tests, or owned artifacts; spec prose and examples are not sufficient evidence.
- TRUE: Every new TRUE implementation claim in this file must cite at least one live checked-in code, test, or artifact path that demonstrates the claim.
- TRUE: Downstream orchestration may rely only on screensaver guarantees declared TRUE here, not on FUTURE ladder stages.
- TRUE: Screensaver scope remains binary at each stage boundary: a capability is either evidenced and governed here as current truth or it remains future, partial, or unevidenced.
