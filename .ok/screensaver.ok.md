# Screensaver OK

This file governs ansilust's current screensaver reality and its shortest-path delivery ladder. It translates `.specs/screensaver/` intent into binary constitutional truth anchored to checked-in CLI, download, and renderer evidence instead of promoting the full showcase spec as shipped behavior.

## Governing References

- Constitution source intent: `.specs/screensaver/instructions.md`, `.specs/screensaver/requirements.md`, `.specs/screensaver/design.md`, `.specs/screensaver/plan.md`
- Gap framing: `.tasks/artifacts/gaps-snapshot-20260320001837.md`
- Live CLI surface: `src/cli/sixteenc.zig`
- Live one-shot runtime path: `src/download/commands/random.zig`
- Neighbor constitutions: `.ok/download.ok.md`, `.ok/render-utf8ansi.ok.md`

## Live Checked-In Evidence

- The checked-in `16c` CLI surface is currently limited to `random-1`, `--help`/`-h`, and `--version`/`-v` in `src/cli/sixteenc.zig`.
- The only evidenced artwork-display flow for this surface is `16c random-1` in `src/download/commands/random.zig`, which creates platform directories, asks the hardcoded archive database for one file, downloads it, stores it in `random/`, and displays it by subprocessing `cat`.
- The active download constitution in `.ok/download.ok.md` says the current source of random artwork is still a hardcoded in-memory database entry, not a shipped `.index.db` or mirror-query surface.
- The active renderer constitution in `.ok/render-utf8ansi.ok.md` says renderer-backed UTF8ANSI output exists in the repo, but `.ok/download.ok.md` also says that renderer integration is not the current download-surface display path.
- The screensaver gap snapshot in `.tasks/artifacts/gaps-snapshot-20260320001837.md` says the remaining problem is decomposition: the repo still lacks a staged ladder from `random-1` to a usable looping screensaver MVP.

## Capability Ladder

- TRUE: Stage 0 current reality is `16c random-1`: one random artwork is fetched, cached under `random/`, printed once, and the process exits.
- TRUE: Stage 0 is the only current screensaver-adjacent runtime truth evidenced by `src/cli/sixteenc.zig`, `src/download/commands/random.zig`, and `.ok/download.ok.md`.
- TRUE: A shortest-path screensaver MVP is not current truth yet; the repo does not currently evidence a looping `16c random`, a `16c screensaver` command, alternate-screen lifecycle handling, cursor hiding, exit-on-input behavior, or renderer-backed playback.
- FUTURE: Stage 1 shortest-path MVP is the smallest playable local-loop surface described in `.specs/screensaver/requirements.md`: `16c random` continuous rotation plus `16c screensaver` playback on a local on-disk pool, ansilust-owned rendering, bounded terminal-session cleanup, and explicit empty-pool failure without requiring `.index.db`, mirror queries, config parsing, bootstrap downloads, or desktop integration.
- FUTURE: Stage 1 shortest-path MVP becomes current truth only when checked-in code and tests replace the current one-shot `cat` path with a looped command surface and renderer-backed playback path.
- FUTURE: Stage 2 is post-MVP art-source growth and remains dependent on future local archive inventory work from the download surface, including broader local cache or mirror enumeration and optional `.index.db`-backed selection, as described in `.specs/screensaver/requirements.md` and `.ok/download.ok.md`.
- FUTURE: Stage 3 is post-MVP config expansion and remains dependent on a future persisted screensaver config surface for duration, filters, overlays, and other playback policy controls; no such config surface is current truth in checked-in repo evidence.
- FUTURE: Stage 4 is post-MVP launch and packaging integration and remains dependent on future owned docs or artifacts for systemd user services, hypridle or swayidle hooks, packaging-time artwork availability, and other desktop-launch surfaces; `.ok/deployments.ok.md` does not currently promote those channels as shipped deployment guarantees.
- TRUE: The shortest path remains intentionally decomposed: local looping playback comes before fullscreen session management, and fullscreen session management comes before mirror, config, and desktop-environment integrations.
- TRUE: `.specs/screensaver/**` may describe all later stages together, but this constitution separates them so near-term execution can ship a looping MVP before the larger archive and system-integration program.

## Dependency Boundaries

- TRUE: The shortest-path MVP is intentionally defined to depend only on future local artwork enumeration plus ansilust-owned playback wiring; `.specs/screensaver/requirements.md` records those MVP dependencies in `DEP6.1` and excludes `.index.db`, mirror bootstrap, and desktop-specific launch infrastructure in `TC3.2` and `TC3.3`.
- TRUE: Mirror, database, and richer local-library work are post-MVP dependencies, not MVP prerequisites; `.specs/screensaver/requirements.md` records them in `FR1.4`, `DEP6.2`, and `SC7.2`, and `.ok/download.ok.md` says the current repo still lacks shipped `.index.db`, mirror sync, and broader archive-management behavior.
- TRUE: Persistent config is a post-MVP dependency, not an MVP prerequisite; `.specs/screensaver/requirements.md` records config work in `FR1.5` and `DEP6.3`, while the current repo does not evidence a shipped screensaver config surface.
- TRUE: Launch, idle-manager, service, and packaging integration are post-MVP dependencies, not MVP prerequisites; `.specs/screensaver/requirements.md` records them in `FR1.6`, `DEP6.4`, and `SC7.4`, and `.ok/deployments.ok.md` says a channel is not supported just because a spec or script exists.
- TRUE: Because current checked-in runtime evidence stops at `16c random-1` plus subprocess `cat`, every screensaver claim beyond that baseline remains FUTURE until code, tests, or owned artifacts explicitly promote it here.

## States We Do Not Want

- FALSE: Spec-only commands `16c random` or `16c screensaver` are treated as shipped behavior without matching CLI, runtime, and test evidence.
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
