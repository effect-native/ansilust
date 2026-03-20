# Screensaver Design

## Architecture Overview

The screensaver surface should be built as a thin orchestration layer around already-governed download, IR, and renderer capabilities instead of as a new monolithic subsystem. The current repository reality is that `16c` already ships `random` and `random-1`, selection is still backed by a hardcoded remote source list, and playback now routes downloaded files through ansilust parsing plus UTF8ANSI rendering. This design therefore treats the repo as having a partial Stage 1 runtime and isolates the remaining gaps needed for a usable local-pool screensaver baseline.

The staged target flow is:

```text
16c random | 16c screensaver
    -> load runtime defaults and optional config
    -> resolve playable artwork source set
    -> select next artwork
    -> parse artwork into ansilust IR
    -> hand IR to UTF8ANSI renderer
    -> manage session timing and exit conditions
```

## Staged Delivery Model

### Stage 0: Current Baseline

- `16c` supports both `random-1` and looping `random`.
- Artwork selection is still effectively one hardcoded remote entry reused on each loop iteration.
- Downloaded output is parsed into ansilust IR and rendered through the UTF8ANSI renderer instead of being displayed by subprocess `cat`.
- No `16c screensaver` command, no alternate-screen lifecycle, no config loading, and no local-pool-first selector are shipped.

### Stage 1: Playable MVP

The first useful screensaver milestone is no longer "make a loop exist." The loop and renderer handoff already exist. The remaining Stage 1 work is to make that runtime usable as a local-first screensaver baseline without depending on `.index.db`, mirror sync, curated bootstrap, or desktop integration.

- Keep the existing looping `16c random` runtime, but change its source contract from repeated hardcoded fetches to a local-pool-first selector with explicit empty-pool behavior.
- Add `16c screensaver` as the same playback core plus screensaver-only terminal lifecycle.
- Preserve the parser-to-IR-to-renderer handoff that is already checked in, rather than reintroducing raw file passthrough.
- Add a small dwell policy and playback defaults, with built-in fallbacks plus the minimal shipped `config.toml` lookup under the resolved `16colors` root.
- Keep art source boundaries simple: Stage 1 treats `random/` plus `local/` as the shipped playable local pool, with `random/` covering runtime-fetched intake and `local/` covering user-supplied files, without making `.index.db` mandatory.

Stage 1 therefore ships one intentionally narrow truth: the runtime knows how to pick from a small local pool made of `random/` and `local/`, and it exits with explicit empty-pool behavior when no local playable file exists. That truth must remain stable even after later pack-aware work ships; future growth expands the selector behind the same local-first contract instead of redefining what the shipped runtime already means.

### Stage 2: Local Pool Growth

Once the loop exists, expand source selection without changing the runtime contract.

- Add broader local cache and mirror enumeration.
- Introduce pack-aware local selection by letting the selector recognize `packs/` and other managed archive roots as additional local-library surfaces behind the same selector boundary.
- Preserve Stage 1 compatibility by treating pack-aware inventory as an expansion of the local pool, not as a replacement for the shipped `random/` plus `local/` behavior.
- Preserve the same renderer handoff and session lifecycle.

### Stage 3: User Configuration and Integration

After runtime playback is stable, add user-facing controls and environment integration.

- Config file parsing for duration, instant/streaming mode, metadata overlay, and filtering.
- systemd, hypridle, fullscreen-terminal, and multi-monitor documentation or wrappers.
- Better source filtering and presentation policies.

### Stage 4: Deferred Enhancements

The following remain intentionally outside MVP architecture:

- Background bootstrap downloads and curated pack seeding.
- `.index.db` as a required runtime dependency.
- Theme integration, GUI setup, statistics, playlists, and advanced transitions.
- XScreenSaver or broader desktop-specific packaging promises.

## Module Organization

The screensaver feature should stay decomposed into small orchestration units rather than one large command implementation.

### Command Surface

- `16c random-1` remains the single-artwork command.
- `16c random` already owns repeated playback for normal terminal use, but today it is only a thin loop over the one-shot fetch path.
- `16c screensaver` is still future and should reuse the same playback core while adding screensaver-only session rules.

### Runtime Coordinator

The runtime coordinator owns the main loop and timing decisions.

- Current checked-in behavior: repeatedly invokes the one-shot fetch-and-render path.
- Stage 1 completion target: load built-in defaults plus the minimal shipped `config.toml` lookup under the resolved `16colors` root, request the next artwork from a source provider, invoke parse-plus-render playback, apply per-piece dwell timing, and stop on explicit exit conditions.

### Artwork Source Provider

The source provider isolates selection policy from playback.

- MVP: chooses from the shipped local pool of `random/` plus `local/`, with descriptive empty-pool failure when neither root contains playable art, without assuming `.index.db`.
- Later: may query pack inventory, mirror inventory, filesystem scans, or `.index.db`.
- The runtime loop should see only a small contract such as "give me the next playable artwork descriptor."

### Playback Pipeline

The playback pipeline converts a selected artwork into terminal output.

- Current checked-in path already reads artwork bytes from disk, parses them into ansilust IR, renders via UTF8ANSI, and emits bytes to stdout.
- Stage 1 and later should preserve that same seam whether artwork came from `random-1`, local-pool `random`, or future `screensaver` mode.

### Session Manager

The session manager exists only for looping and screensaver commands.

- For current `16c random`, the session manager is only a bare loop and does not yet evidence dwell policy, interruption handling, or explicit terminal cleanup.
- For future `16c screensaver`, also enter and restore alternate screen, cursor visibility, and input-exit behavior.

## Runtime Loop

The runtime loop should be intentionally simple.

```text
initialize session
load defaults and optional config
while session is active:
    select next artwork
    if no artwork is available: show helpful message and exit
    play artwork through parser and renderer
    if mode == random-1: exit success
    wait for dwell interval or exit event
cleanup session state
```

Key boundaries:

- Selection failure is a source problem, not a renderer problem.
- Parse or render failure should fail the current artwork cleanly and either advance or exit based on command policy.
- Session cleanup must run even on keyboard-driven exit and on the shipped Stage 1 signal path of `SIGINT` and `SIGTERM`.

## Art Selection Boundaries

The art-selection layer should answer only three questions:

- What artworks are currently eligible?
- Which one should play next?
- What metadata is safe to hand downstream right now?

To keep MVP unblocked:

- The selector must not require `.index.db`.
- The selector must not require full mirror sync.
- The selector may operate on a small local playable set, even if that set is narrow at first.

Post-MVP selector growth can add:

- mirror-backed random rotation
- metadata filters by year, group, artist, or format
- exclusion rules and curated playlists
- cache invalidation and inventory refresh policies

### Pre-`.index.db` Fallback Order

Before `.index.db` exists, the selector should use a strict local-first ladder that matches the repo's current evidence and MVP-first constraints.

1. In shipped Stage 1, scan only `random/` first and `local/` second, because those two roots define the actual local playable pool that exists without new pack machinery.
2. If both Stage 1 roots are empty, stop with a descriptive local-only failure instead of silently fetching or inventing another runtime source.
3. In Stage 2+, keep the same local-first contract but widen the scan to include pack-aware managed roots such as `packs/` between `random/` and `local/`, or alongside them under a selector mode that still resolves to local playable files before any later optional growth flow.
4. If a curated seed set or explicit bootstrap helper is later introduced, treat it as one way to populate the managed local library surface rather than as a different runtime contract.

This fallback order keeps Stage 1 unblocked:

- It prefers already-local artwork over any network dependency.
- It preserves the shipped truth that `random/` plus `local/` are enough to define the local pool before pack support exists.
- It preserves compatibility with current `random-1` evidence, where the repo can still fetch one hardcoded remote file and save it under `random/`.
- It lets Stage 2 add managed packs as another local tier without breaking the Stage 1 runtime contract.
- It does not promise `.index.db`, full mirror enumeration, or metadata-aware ranking before those surfaces actually ship.

### Selection Policy Within Local Tiers

- The selector may stop at the first non-empty tier in the fallback ladder instead of merging all roots into one global ranked pool.
- Within a chosen tier, selection may be simple random choice over playable files discovered by filename and parser support.
- If a file fails to parse or render, the runtime should skip it, continue within the same tier when possible, and advance to the next fallback tier only if the tier proves effectively empty or unusable.
- `random-1` remains compatible with its current hardcoded-fetch contract; the new ladder primarily governs looping `random` and future `screensaver` behavior before `.index.db` arrives.

### Transition From Stage 1 Pool To Pack-Aware Local Selection

The growth path should be additive and selector-driven:

- Step 1, shipped Stage 1: define the local pool as `random/` plus `local/`. `random/` is the runtime-owned intake cache and `local/` is the user-owned drop zone.
- Step 2, early Stage 2: allow the selector to detect `packs/` as another local root, but keep the same playback contract and keep `random/` and `local/` fully valid even when `packs/` is absent.
- Step 3, later Stage 2: let pack-aware selection understand extracted archives, pack boundaries, or remembered rotation state, but only inside the source-provider layer.
- Step 4, post-MVP: add `.index.db` or richer metadata on top of those same roots to improve ranking and filtering, not to redefine what counts as playable local artwork.

This transition keeps the shipped runtime stable because the runtime loop still asks for the next playable local artwork descriptor, while the source provider quietly grows from a two-root scan into a pack-aware local archive selector.

### Growth Roles For `random/`, `packs/`, And `local/`

As the library grows past MVP, these three roots should remain distinct surfaces with different retention and rotation responsibilities rather than collapsing into one undifferentiated directory.

- `random/` is the short-horizon intake surface. It remains the first playable local root for shipped Stage 1 compatibility because current `random-1` behavior already lands fetched artwork there. In Stage 2+, newly fetched or opportunistically downloaded pieces should enter rotation here first so the runtime can surface fresh material quickly without requiring pack curation or index rebuilds.
- `packs/` is the managed durable library surface. In Stage 2+, downloaded archives, extracted collections, and future curated bundle material should accumulate here for long-term rotation. This directory is the default home for broad library growth once the system has more than one-off `random-1` fetches.
- `local/` is the user-owned durable surface. It is always eligible for playback, but it stays conceptually separate from managed downloads because files here are user-supplied and should not be reorganized, deleted, or silently rewritten by the runtime.

Pack-aware selection should therefore be understood as "local archive selection" rather than a separate remote mode. `packs/` joins the local pool as a managed archive surface, while `random/` and `local/` keep their shipped meanings intact.

### Retention Policy By Surface

- `random/` should be treated as disposable cache-like inventory. The runtime may rely on it for immediate playback and short-horizon replay prevention, but Stage 2+ design should not require indefinite retention there once artwork has been promoted into broader managed inventory elsewhere.
- `packs/` should be treated as the default retained library. Stage 2+ growth work may add pack extraction, inventory refresh, or deduplication here, but the screensaver contract should assume files in `packs/` persist across sessions unless the user or a future explicit maintenance command removes them.
- `local/` should be treated as fully retained and user-controlled. The runtime may read and rotate these files, but it shall not prune them as part of cache cleanup or managed-library maintenance.

### Rotation Policy Beyond MVP

- The MVP fallback ladder remains the cold-start and recovery rule: local discovery preferring `random/`, then `packs/` once that stage exists, then `local/`, then a descriptive empty-pool stop.
- Once Stage 2+ introduces remembered rotation state, `random/` should function as the recency queue: newly arrived playable files there should be attempted before the runtime settles back into the broader durable library.
- After the current `random/` intake set has been attempted, the steady-state rotation pool should favor `packs/` as the main long-lived source and include `local/` as an always-eligible secondary source.
- If both `packs/` and `local/` have unseen playable files, the default auto policy should prefer `packs/` first so managed library growth becomes the main screensaver body without displacing user-owned art from eligibility.
- When all currently eligible files in the active rotation surface have been seen, the runtime may reset seen-state and continue, but it should preserve the same ordering bias: fresh `random/` arrivals first, then `packs/`, then `local/`.
- Future config or index-backed policies may expose more explicit weighting or filtering, but the default auto policy should preserve this directory-role model so Stage 2+ growth does not invalidate the MVP-first fallback story.

## Renderer Handoff

Renderer integration is the architectural seam that replaces the current `cat` behavior.

### Required Handoff Contract

- Input to playback is a resolved artwork path plus enough format context to choose a parser.
- Parser output is an ansilust IR `Document`.
- Renderer input is that IR document plus session-level render options.
- Renderer output is UTF-8/ANSI bytes written to the active terminal surface.

### Why This Boundary Matters

- It lets download and source selection evolve independently from terminal presentation.
- It keeps screensaver logic from owning format parsing details.
- It aligns with current repo reality, where parser and renderer capabilities live in separate governed surfaces.

### MVP Renderer Scope

- Use existing UTF8ANSI renderer behavior as-is.
- Ship only one explicit Stage 1 presentation mode: render the parsed document into the current terminal cell viewport using the renderer's existing natural output behavior.
- Avoid promising fit, fill, native-size toggles, zoom, pan, SAUCE-perfect layout, or streaming simulation until those capabilities are actually implemented.
- Treat metadata overlays and richer transitions as separate later layers, not part of the core handoff.

## Terminal Sizing And Presentation Policy

Stage 1 needs a presentation policy that is usable in ordinary terminals without inventing resize math or visual modes the repo does not yet evidence. The MVP should therefore treat the active terminal size as a hard viewport, center only when that can be done with straightforward padding, and use SAUCE as a source of parser or renderer hints rather than as a promise of full-screen layout correction.

### Terminal Size Detection

- Detect terminal rows and columns at playback start for each artwork presentation.
- Treat the detected size as the current viewport limit for that render pass.
- For `screensaver`, detect size after entering the alternate screen so layout uses the active presentation surface.
- If terminal size cannot be determined, fall back to rendering without extra centering logic rather than failing the session.

### MVP Sizing Rules

- The MVP render target is the current terminal cell grid; there is no fit, fill, zoom, or aspect-correct scaling mode yet.
- If artwork fits within the current viewport, it may be positioned with simple whole-cell offsets.
- If artwork exceeds the viewport in either dimension, the MVP may show only the renderer's natural visible region for that terminal instead of shrinking or reflowing the art.
- Oversized artwork is therefore acceptable as clipped-by-viewport in Stage 1 as long as playback remains legible enough to view and exit cleanly.

### Resize Handling In Stage 1

- Terminal resize during playback is handled at artwork boundaries, not as a live relayout contract.
- The runtime should sample terminal size before each new artwork begins, so the next piece uses the latest viewport.
- If the terminal is resized while a piece is already being shown, Stage 1 does not guarantee immediate re-centering, redraw, or replay of that piece.
- It is acceptable for the active frame to remain visually imperfect until the next artwork, as long as the session stays usable and terminal cleanup still works on exit.
- A later implementation may choose to clear and redraw on resize, but MVP design must not depend on SIGWINCH-driven recomposition being available.

### MVP Centering Rules

- Centering is a presentation nicety, not a correctness requirement for Stage 1 playback.
- When artwork dimensions are smaller than the terminal and whole-cell padding is cheap to compute, center it horizontally and vertically using blank-space margins.
- When exact centering would require capabilities outside the current renderer handoff, prefer top-left anchored playback over inventing partial layout state.
- Do not promise sub-cell alignment, animated repositioning, or per-frame re-centering during streaming playback in the MVP.

### SAUCE-Aware Presentation Hints

- Preserve and parse SAUCE metadata because it can contain width and classic rendering hints that affect how the artwork should be interpreted.
- In Stage 1, SAUCE may influence parser or renderer inputs that are already part of ansilust's document model, such as declared columns or classic flags like iCE colors.
- In Stage 1, SAUCE shall not be treated as a guarantee of aspect-ratio correction, font emulation, metadata overlays, or automatic fullscreen layout policy.
- If SAUCE conflicts with the current terminal viewport, prefer a playable terminal render over attempting unsupported correction passes.

### Practical MVP Outcomes

- Small artwork in a larger terminal should usually appear centered when that only requires blank padding.
- Large artwork may render from its natural origin and be clipped by the terminal viewport.
- SAUCE-aware width and classic mode hints may improve interpretation, but they do not create new scaling or presentation modes in Stage 1.
- Mid-piece terminal resize may leave the current image anchored or clipped until the next artwork starts.

### Explicitly Deferred Render Modes

- `fit`: shrink or relayout art to fully fit the current terminal in both dimensions.
- `fill`: scale or crop deliberately to cover the viewport as a presentation mode.
- `native`: preserve source dimensions as a user-selectable policy distinct from the default Stage 1 behavior.
- any user-selectable render-mode switch or config that toggles among these policies.
- aspect-correct presentation modes that emulate DOS pixel geometry, font metrics, or fullscreen correction passes.

These modes are deferred because current evidence supports parser-to-IR-to-UTF8ANSI playback, not a complete resize-aware presentation engine with multiple policy-specific layout passes.

## Session Lifecycle

The session lifecycle differs by command mode.

### `random-1`

- No persistent loop.
- No alternate screen requirement.
- Parse and render one piece, then exit.

### `random`

- Repeated selection and playback.
- Normal terminal mode by default.
- Stage 1 completion should add graceful handling for `SIGINT` and `SIGTERM`, with any broader signal coverage treated as later hardening.

### `screensaver`

- Same repeated playback core as `random`.
- Adds alternate-screen entry and restoration.
- Hides and restores cursor.
- Exits on keyboard input plus `SIGINT` and `SIGTERM`.
- Owns final cleanup even if playback fails mid-piece.

Stage 1 should treat keyboard exit plus best-effort cleanup on `SIGINT` and `SIGTERM` as the complete shipped session contract. Broader signal handling remains future-facing and should be documented as additive hardening if it lands later.

This separation keeps the fullscreen/session-specific behavior additive instead of infecting the base loop.

## Config Boundaries

Configuration should remain an optional policy layer above runtime playback.

### MVP Defaults

- The runtime shall work with no config file present by using built-in defaults.
- The MVP config surface is `config.toml` under the resolved `16colors` root, and it should stay intentionally tiny by defining only the keys needed to tune loop timing and source resolution policy.

### Stage 1 Completion `config.toml` Keys

The first usable screensaver completion recognizes exactly these top-level tables and keys from `config.toml` under the resolved `16colors` root:

```toml
[playback]
dwell_seconds = 20

[source]
mode = "auto"
```

Target key meanings and defaults:

- `playback.dwell_seconds = 20`: target default number of seconds to keep each artwork visible before advancing in `16c random` and `16c screensaver`, matching the Stage 1 default defined in requirements.
- `source.mode = "auto"`: target built-in local-first ladder over the shipped playable roots, with descriptive empty-pool failure when no local artwork is available.

MVP key constraints:

- Keep `dwell_seconds` as a positive integer in seconds; sub-second timing is out of scope for the first release.
- Keep `source.mode` limited to `"auto"` in MVP so the config format exists without prematurely committing to filters, playlists, or source-specific selectors.
- Omit render-mode, metadata-overlay, transition, fullscreen-layout, and filtering keys until those features actually exist.
- Omit screensaver-only lifecycle toggles such as alternate-screen or exit-on-input because Stage 1 treats those as fixed command behavior, not user policy.

Current gap note:

- The checked-in runtime loads only this minimal `config.toml` surface under the resolved `16colors` root; it does not yet expose a broader screensaver config schema.
- The checked-in runtime does not currently expose dwell flags or playback-mode flags on the CLI.

### Post-MVP Config Surface

- artwork duration
- selection filters
- overlay toggles
- render-mode preferences
- source-preference and refresh tuning

Config must not become a prerequisite for a working loop. The runtime should always start with built-in defaults when no config file exists.

## Deferred Integrations

The following integrations should be documented as future attachments to the architecture rather than prerequisites for MVP:

- `.index.db` inventory queries from the download system
- curated pre-cache and post-install extraction
- background `16c download` bootstrap during runtime
- metadata overlays sourced from richer archive records
- hypridle/systemd wrappers and desktop-specific launchers
- multi-monitor orchestration
- transition effects beyond simple clear-and-render playback

Each deferred integration should plug into an existing boundary:

- inventory and bootstrap attach to the artwork source provider
- overlays and transitions attach to playback policy
- idle-manager and fullscreen launchers attach to the session manager
- config growth attaches to the runtime coordinator

## Error Handling Strategy

Error handling should follow boundary ownership.

- Source errors report unavailable artwork or empty inventory.
- Parse errors report unsupported or unreadable artwork.
- Renderer errors report terminal-output failure.
- Session errors always attempt terminal-state restoration before exit.

For MVP, user-facing behavior should prefer concise actionable failures over recovery complexity.

## Testing Approach

The design expects tests to follow the staged architecture.

### MVP-Focused Tests

- command dispatch for current `random` and future `screensaver`
- loop termination after signal or input event
- renderer handoff from selected artwork to parsed IR to emitted bytes
- terminal cleanup on normal exit and failure exit
- helpful failure when no playable artwork is available

### Post-MVP Tests

- source-provider behavior for mirror or database-backed inventories
- config parsing and default fallback
- filter application
- overlay and integration wiring

## Design Decisions

- The playback loop is already checked-in and remains the MVP center of gravity; mirror/database completeness is not.
- Art-source discovery is a provider boundary so the runtime can ship before `.index.db` exists.
- Renderer handoff is already explicit so screensaver work can extend real ansilust playback instead of regressing to raw file output.
- Fullscreen and exit-on-input behavior belong only to the screensaver session layer, not to every display command.
- Config, overlays, bootstrap, and desktop integration are deferred to preserve a shortest-path usable runtime.
