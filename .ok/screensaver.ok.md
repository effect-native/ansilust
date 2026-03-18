# Screensaver OK

This file governs ansilust's current screensaver and author-experience runtime reality. It translates `.specs/screensaver/` into binary constitutional truth so reconciliation stays anchored to checked-in CLI behavior rather than future showcase-flow ambitions.

## Governing References

- `.specs/screensaver/instructions.md`
- `build.zig`
- `src/cli/sixteenc.zig`
- `src/download/commands/random.zig`
- `.ok/download.ok.md`

## Ideal End State

- TRUE: `.specs/screensaver/` is an active spec area that now has constitutional coverage in this file.
- TRUE: `.specs/screensaver/instructions.md` describes a future `16c` random-rotation and fullscreen screensaver surface, and this file intentionally promotes only repository-evidenced facts into present-tense truth.
- TRUE: Current shipped `16c` CLI surface is limited to `random-1`, `--help`/`-h`, and `--version`/`-v`.
- TRUE: Current repository evidence supports single-artwork fetch-and-display via `16c random-1`; continuous `16c random` rotation and `16c screensaver` fullscreen mode are not current truth.
- TRUE: Current `16c random-1` behavior is download-first MVP behavior that stores one file in the `random/` cache and displays it by subprocessing `cat`.
- TRUE: Current repository evidence does not show screensaver-only input handling, alternate-screen management, cursor hiding, fullscreen window integration, config parsing from `~/.config/16c/config.toml`, filtering, metadata overlays, or systemd idle integration.
- TRUE: Current repository evidence does not show the spec-described mirror-query and pre-cache orchestration surfaces such as `.index.db`-backed random rotation, bundled curated artwork, post-install bootstrap, or background `16c download` expansion during screensaver use.
- TRUE: `.specs/screensaver/**` may describe future random rotation, streaming animation, fullscreen screensaver mode, pre-cache/bootstrap, and idle-manager integration, but only assertions promoted here are constitutional truth for screensaver reconciliation.

## States We Do Not Want

- FALSE: Spec-only commands `16c random` or `16c screensaver` are treated as shipped behavior without matching CLI and build evidence.
- FALSE: Download-spec aspirations such as `.index.db`, pack rotation, curated bootstrap, or local-mirror queries are treated as current screensaver guarantees without checked-in evidence in this surface.
- FALSE: Renderer aspirations such as streaming baud simulation, scaling modes, SAUCE-driven layout, or fullscreen terminal cleanup are treated as present-tense runtime truth without implemented evidence.
- FALSE: Example service files, Hyprland rules, or config snippets in `.specs/screensaver/**` are treated as installed or supported artifacts when they do not exist in the repository.
- FALSE: Spec-defined runtime affordances such as `--instant`, fit/fill/native render modes, metadata overlays, terminal resize handling, signal-driven cleanup, or exit-on-any-input are treated as current guarantees without checked-in implementation evidence.
- FALSE: Spec-defined user-environment integration such as `~/.config/16c/config.toml`, `~/.config/systemd/user/16c-screensaver.service`, hypridle hooks, DPMS-aware lifecycle handling, or multi-monitor launch flows are treated as shipped support without checked-in product artifacts or documentation owned by this surface.

## Required Governance Rules

- TRUE: Changes to the `16c` experience surface for random rotation, fullscreen behavior, config handling, or idle/system integration require updating this file in the same reconciliation loop.
- TRUE: Screensaver completion claims must be backed by checked-in CLI code, config artifacts, or tests; spec prose and examples are not sufficient evidence.
- TRUE: Claims about mirror-backed selection, pre-cache/bootstrap behavior, terminal-state management, config keys, or environment integration must be backed by checked-in command surfaces, owned docs, or validation artifacts rather than by spec examples alone.
- TRUE: Downstream orchestration may rely only on screensaver guarantees declared TRUE here.
- TRUE: Screensaver scope remains binary: a capability is either evidenced and governed here or it is still future, absent, or unevidenced.
