# Screensaver OK

This file governs ansilust's current screensaver reality and its shortest-path delivery ladder. It translates `.specs/screensaver/` intent into binary constitutional truth anchored to checked-in CLI, download, and renderer evidence instead of promoting the full showcase spec as shipped behavior.

## Governing References

- Constitution source intent: `.specs/screensaver/instructions.md`
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
- FUTURE: Stage 1 shortest-path MVP is a local looping playback surface that promotes `random-1` into repeated artwork rotation without depending on fullscreen integration, `.index.db`, bootstrap downloads, filters, overlays, or user config.
- FUTURE: Stage 1 shortest-path MVP becomes current truth only when checked-in code and tests show a looped command surface plus a real playback handoff instead of the current one-shot `cat` path.
- FUTURE: Stage 2 builds on the looping MVP by adding a dedicated `16c screensaver` session lifecycle such as alternate-screen entry and restore, cursor hide and restore, exit on input, signal-safe cleanup, and terminal-sized presentation behavior.
- FUTURE: Stage 3 builds on the looping MVP by integrating broader archive selection and experience layers such as renderer-backed streaming presentation, richer local artwork pools, mirror or `.index.db` selection, config parsing, filtering, metadata overlays, and bootstrap or pre-cache growth.
- FUTURE: Stage 4 builds on the prior stages by adding external environment integration such as owned docs or artifacts for systemd user services, hypridle or swayidle hooks, DPMS-aware lifecycle behavior, and multi-monitor launch patterns.
- TRUE: The shortest path remains intentionally decomposed: local looping playback comes before fullscreen session management, and fullscreen session management comes before mirror, config, and desktop-environment integrations.
- TRUE: `.specs/screensaver/**` may describe all later stages together, but this constitution separates them so near-term execution can ship a looping MVP before the larger archive and system-integration program.

## States We Do Not Want

- FALSE: Spec-only commands `16c random` or `16c screensaver` are treated as shipped behavior without matching CLI, runtime, and test evidence.
- FALSE: The shortest-path looping MVP is treated as blocked on `.index.db`, mirror sync, curated bootstrap, systemd integration, or other later-stage infrastructure when local-loop playback can be delivered separately.
- FALSE: Renderer ambitions such as streaming baud simulation, scaling modes, SAUCE-driven layout, or metadata overlays are treated as current screensaver guarantees without checked-in implementation evidence on this surface.
- FALSE: Example service files, Hyprland rules, config snippets, or idle-manager examples in `.specs/screensaver/**` are treated as installed or supported artifacts when no owned repo artifacts or docs currently exist.
- FALSE: Later-stage ladder items override present-tense truth; until a stage is evidenced in checked-in code, tests, or owned artifacts, it remains future-facing here.

## Required Governance Rules

- TRUE: Changes to the `16c` command surface, playback path, fullscreen lifecycle, config handling, mirror selection, or idle-system integration require updating this file in the same reconciliation loop.
- TRUE: Screensaver advancement claims must identify which ladder stage became current truth and must be backed by checked-in code, tests, or owned artifacts; spec prose and examples are not sufficient evidence.
- TRUE: Every new TRUE implementation claim in this file must cite at least one live checked-in code, test, or artifact path that demonstrates the claim.
- TRUE: Downstream orchestration may rely only on screensaver guarantees declared TRUE here, not on FUTURE ladder stages.
- TRUE: Screensaver scope remains binary at each stage boundary: a capability is either evidenced and governed here as current truth or it remains future, partial, or unevidenced.
