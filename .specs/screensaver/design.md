# Screensaver Design

## Architecture Overview

The screensaver surface should be built as a thin orchestration layer around already-governed download, IR, and renderer capabilities instead of as a new monolithic subsystem. The current repository reality is that `16c` only ships `random-1`, selection is backed by a hardcoded source list, and display still hands the downloaded file to `cat`. This design therefore splits the work into a shortest-path MVP and explicitly deferred post-MVP layers.

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

- `16c` supports `random-1` only.
- Artwork selection is effectively one hardcoded remote entry.
- Downloaded output is displayed by subprocess `cat`.
- No looping runtime, no alternate-screen lifecycle, and no config surface are shipped.

### Stage 1: Playable MVP

The first useful screensaver milestone is a local runtime loop that can repeatedly display artwork without depending on `.index.db`, mirror sync, curated bootstrap, or desktop integration.

- Add a looping `16c random` runtime for repeated playback.
- Add `16c screensaver` as the same loop plus screensaver-only terminal lifecycle.
- Replace raw `cat` display with parser-to-IR-to-renderer handoff.
- Keep art source boundaries simple: use whatever playable local or fetched artwork set the current download surface can provide.
- Keep configuration minimal and optional; hardcoded defaults are acceptable for MVP.

### Stage 2: Local Pool Growth

Once the loop exists, expand source selection without changing the runtime contract.

- Add broader local cache and mirror enumeration.
- Introduce database-backed or filesystem-backed rotation as an art-source provider behind the same selector boundary.
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
- `16c random` owns repeated playback for normal terminal use.
- `16c screensaver` reuses the same playback core but adds screensaver-only session rules.

### Runtime Coordinator

The runtime coordinator owns the main loop and timing decisions.

- Loads defaults and optional config.
- Requests the next artwork from a source provider.
- Invokes parse-plus-render playback.
- Applies per-piece dwell timing.
- Stops on explicit exit conditions.

### Artwork Source Provider

The source provider isolates selection policy from playback.

- MVP: may choose from current downloadable/cacheable artwork without assuming `.index.db`.
- Later: may query mirror inventory, filesystem scans, or `.index.db`.
- The runtime loop should see only a small contract such as "give me the next playable artwork descriptor."

### Playback Pipeline

The playback pipeline converts a selected artwork into terminal output.

- Read artwork bytes from disk.
- Parse into ansilust IR using the appropriate parser.
- Hand the IR document to the UTF8ANSI renderer.
- Emit bytes to stdout or an owned terminal session.

### Session Manager

The session manager exists only for looping and screensaver commands.

- For `16c random`, manage timing between pieces and clean interruption.
- For `16c screensaver`, also enter and restore alternate screen, cursor visibility, and input-exit behavior.

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
- Session cleanup must run even on signal or input-driven exit.

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
- Graceful handling for interruption signals.

### `screensaver`

- Same repeated playback core as `random`.
- Adds alternate-screen entry and restoration.
- Hides and restores cursor.
- Exits on user input and normal termination signals.
- Owns final cleanup even if playback fails mid-piece.

This separation keeps the fullscreen/session-specific behavior additive instead of infecting the base loop.

## Config Boundaries

Configuration should remain an optional policy layer above runtime playback.

### MVP Defaults

- sensible dwell time
- optional instant-vs-streaming toggle placeholder
- default source selection behavior
- metadata overlay disabled by default unless implemented later

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

- command dispatch for `random` and `screensaver`
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

- The playback loop is the MVP center of gravity; mirror/database completeness is not.
- Art-source discovery is a provider boundary so the runtime can ship before `.index.db` exists.
- Renderer handoff is explicit so screensaver work advances real ansilust playback instead of extending `cat` output.
- Fullscreen and exit-on-input behavior belong only to the screensaver session layer, not to every display command.
- Config, overlays, bootstrap, and desktop integration are deferred to preserve a shortest-path usable runtime.
