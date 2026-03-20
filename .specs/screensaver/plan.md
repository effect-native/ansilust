# Screensaver Plan

This plan turns the screensaver spec into a staged delivery ladder that matches the current DotOK hierarchy: governance/spec decomposition first, then MVP runtime and presentation, then later art-source, config, and integration growth.

## Execution Baseline

- Current repository truth remains the `.ok/screensaver.ok.md` MVP: shipped behavior is still `16c random-1` only.
- The current `.tasks/` hierarchy completed the decomposition pass needed to break the monolith into governed slices.
- This file defines stable work packages for future delivery without treating spec-only behavior as shipped runtime truth.

## Legacy Tracker Translation

- `tracker/tasks/FEAT-SCREEN-001.md` is archival context only; it helps preserve useful intent from the pre-DotOK workflow but does not define current blockers, priority, or execution authority.
- `GAP-DL-001` is no longer treated as a single live gate for screensaver delivery. Its useful intent is translated into staged DotOK work instead: MVP local-art decoupling lives in `WP-RUN-001` and `WP-ART-001`, while later cache/bootstrap and integration growth live in `WP-CFG-001` and `WP-GROW-001`.
- `GAP-DB-001` is no longer treated as a single live gate for screensaver delivery. Its useful intent is translated into post-MVP metadata/index/config growth instead: database-backed selection and richer library management belong under `WP-ART-001`, `WP-CFG-001`, and `WP-GROW-001`, not the MVP runtime or renderer path.
- The old tracker acceptance stack now maps into the current sequence: looping playback and command surfaces land first (`WP-RUN-001`, `WP-RUN-002`), renderer-backed presentation next (`WP-DISP-001`, `WP-DISP-002`), then art-source/config boundaries (`WP-ART-001`, `WP-CFG-001`), with bootstrap, metadata growth, packaging, and environment-specific integration deferred to `WP-GROW-001`.
- Any future reference to legacy tracker IDs in this area should be read as historical rationale only and translated into `.tasks/` work under these work packages instead of being revived as active authority.

## Milestones

- [x] M1. Governance and spec decomposition
- [ ] M2. MVP runtime loop and command surface
- [ ] M3. MVP display and presentation pipeline
- [ ] M4. MVP art source and config foundation
- [ ] M5. Post-MVP growth, bootstrap, and launch integration

## Work Packages

### [WP-GOV-001] Screensaver Governance And Spec Stack

**Intent**: Establish the screensaver area as a staged DotOK-governed spec with explicit MVP versus post-MVP boundaries.

**Acceptance**:
- `.specs/screensaver/` includes the staged spec stack needed to drive implementation work.
- The screensaver ladder matches the four active high-level slices in `.tasks/`.
- Legacy RFC and tracker intent are translated into current DotOK surfaces without reviving older workflow authority.
- The constitution continues to describe only repository-evidenced present-tense runtime truth.

**Tasks**:
- `task-high-screensaver-governance-and-spec-decomposition`
- `task-med-author-screensaver-spec-stack`
- `task-med-translate-legacy-screensaver-intent-into-dotok`
- `task-low-author-screensaver-requirements-doc`
- `task-low-author-screensaver-design-doc`
- `task-low-author-screensaver-plan-doc`
- `task-low-update-screensaver-ok-capability-ladder`
- `task-low-reconcile-screensaver-rfc-inbox-status`
- `task-low-record-legacy-screensaver-tracker-dependencies`
- `task-med-rewrite-screensaver-constitution-for-staged-delivery`

**Status**: [x] Complete

### [WP-RUN-001] Continuous Random Command MVP

**Intent**: Add the first usable looping `16c random` runtime surface so screensaver delivery no longer stops at one-shot `random-1`.

**Acceptance**:
- `16c random` is a first-class CLI surface with dedicated command/module ownership.
- The runtime can rotate through multiple artworks using a defined dwell policy.
- MVP art selection works from a local pool without depending on the full `.index.db` mirror stack.
- Failure behavior is explicit when no playable local art is available.

**Tasks**:
- `task-high-screensaver-command-and-runtime-loop`
- `task-med-add-continuous-random-command-surface`
- `task-low-extend-16c-cli-for-random-command`
- `task-low-add-looping-random-command-module`
- `task-med-add-timing-and-rotation-policy`
- `task-low-define-artwork-dwell-defaults`
- `task-med-decouple-mvp-art-selection-from-full-mirror`
- `task-low-define-random-packs-and-local-rotation-surface`
- `task-low-define-fallback-order-before-index-db`
- `task-low-define-minimum-local-art-pool-strategy`

**Status**: [ ] Pending

### [WP-RUN-002] Screensaver Session Controls MVP

**Intent**: Layer a true `16c screensaver` session on top of the looping runtime with predictable input exit and terminal cleanup.

**Acceptance**:
- `16c screensaver` owns a distinct session lifecycle above `16c random`.
- Screensaver mode exits on user input and handles process signals cleanly.
- Alternate screen and cursor visibility behavior are defined and restored on exit.
- MVP fullscreen-session behavior is explicit even before window-manager integration lands.

**Tasks**:
- `task-med-add-screensaver-session-controls`
- `task-low-define-screensaver-input-exit-and-signal-cleanup`
- `task-low-define-alt-screen-cursor-lifecycle`

**Status**: [ ] Pending

### [WP-DISP-001] Renderer-Backed Playback MVP

**Intent**: Replace raw `cat` playback with ansilust-driven rendering so screensaver runtime can evolve on a real presentation path.

**Acceptance**:
- `16c` playback routes through the ansilust renderer rather than subprocess file dumping.
- The runtime can render supported art files through one shared display handoff.
- Playback behavior is covered by renderer-backed tests.
- The MVP rendering path is sufficient for rotation and screensaver session work.

**Tasks**:
- `task-high-screensaver-display-and-presentation-pipeline`
- `task-med-replace-cat-display-with-renderer-playback`
- `task-low-route-random-display-through-ansilust-renderer`
- `task-low-add-renderer-backed-16c-playback-tests`

**Status**: [ ] Pending

### [WP-DISP-002] MVP Layout And Streaming Policy

**Intent**: Define the first shippable presentation rules for sizing and pacing without blocking delivery on later visual polish.

**Acceptance**:
- MVP sizing, centering, and SAUCE-handling policy is defined for runtime playback.
- Resize behavior is explicit for MVP and future escalation is separated.
- Streaming defaults and instant mode are scoped as MVP-visible behavior.
- Transition effects and other polish remain clearly post-MVP.

**Tasks**:
- `task-med-define-layout-and-resize-behavior`
- `task-low-define-terminal-sizing-centering-and-sauce-policy`
- `task-low-define-resize-handling-and-render-mode-escalation`
- `task-med-scope-streaming-and-transition-effects`
- `task-low-isolate-mvp-streaming-behavior`
- `task-low-define-instant-and-streaming-speed-flags`
- `task-low-defer-nonessential-transition-effects`

**Status**: [ ] Pending

### [WP-ART-001] MVP Art Source Boundary

**Intent**: Keep the first shippable screensaver unblocked by full mirror/database ambitions while preserving a path to richer local libraries later.

**Acceptance**:
- MVP art source order is defined independently of `.index.db` availability.
- The minimum local art pool and random-selection boundary are explicit.
- Screensaver runtime can operate from local files before mirror/database maturity.
- The MVP may rely on a small curated preseeded local art set that ships in-repo or via other owned local assets, without requiring network fetch, background sync, or metadata indexing.
- The spec leaves room for later bootstrap and broader library growth without promising them in the MVP.

**Tasks**:
- `task-med-decouple-mvp-art-selection-from-full-mirror`
- `task-low-define-random-packs-and-local-rotation-surface`
- `task-low-define-fallback-order-before-index-db`
- `task-low-define-minimum-local-art-pool-strategy`
- `task-low-capture-screensaver-mvp-vs-post-mvp-dependencies`

**Status**: [ ] Pending

### [WP-CFG-001] Config And Launch Surface

**Intent**: Add the smallest durable config and launch boundary needed for screensaver use without overpromising packaging or desktop integration.

**Acceptance**:
- MVP `~/.config/16c/config.toml` keys are limited to the runtime controls needed for early delivery.
- Launch guidance defines only the first owned Omarchy-friendly boundary: ansilust owns the `16c screensaver` command surface plus example user-level launch artifacts, not idle detection or desktop policy.
- MVP launch examples are limited to Omarchy-adjacent Wayland/user-service surfaces such as `systemd --user` units or idle-manager wiring examples once they exist in-repo.
- Packaging guidance cleanly separates owned artifacts from environment-specific examples and stays fenced to channels the repository can actually prove.
- Config/configuration work stays decoupled from mirror/database and transition-polish expansion.
- X11, XScreenSaver, and broader cross-desktop launch compatibility remain post-MVP follow-on work under later integration packages.

**Tasks**:
- `task-high-screensaver-art-source-config-and-integration`
- `task-med-design-config-launch-and-packaging-surface`
- `task-low-define-16c-config-toml-mvp-keys`
- `task-low-author-omarchy-systemd-and-packaging-boundary`

**Status**: [ ] Pending

### [WP-GROW-001] Library Growth, Bootstrap, And Integration Expansion

**Intent**: Stage later enhancements after the MVP works: richer local pools, optional bootstrap behavior, and deeper environment integration.

**Acceptance**:
- Bootstrap behavior is defined as post-MVP and does not block the first playable loop.
- Curated preseeded art is treated separately from bootstrap: preseed provides the first local playable pool, while bootstrap is only an optional later flow for pulling or unpacking additional art.
- Any bootstrap flow is user-invoked or otherwise explicit; it is not a promised always-on sync service.
- Bootstrap scope stops at obtaining more playable local art. Full background sync, broad remote catalog management, and metadata indexing remain later follow-on work unless the repo gains direct implementation evidence.
- The growth path from minimum local pool to larger library is explicit.
- Later system integration remains separated from runtime truth until owned artifacts exist; this includes Omarchy idle wiring beyond the initial launch boundary plus any X11/XScreenSaver-specific adapters.
- Packaging promises remain aligned with `.ok/deployments.ok.md`: future channels may be described here, but nothing becomes a supported deployment claim until the repository ships the artifact and deployment governance promotes it.
- Post-MVP work can extend the MVP without rewriting the earlier command and playback surfaces.

**Tasks**:
- `task-med-plan-cache-bootstrap-and-library-growth`
- `task-low-define-bootstrap-and-preseed-behavior`
- `task-low-capture-screensaver-mvp-vs-post-mvp-dependencies`
- `task-low-author-omarchy-systemd-and-packaging-boundary`

**Status**: [ ] Pending

## Validation Checkpoints

- **Governance**: `.ok/screensaver.ok.md` remains present-tense and evidence-based after each milestone.
- **CLI**: `zig build` succeeds once new `16c` command surfaces are added.
- **Tests**: `zig build test` covers runtime loop, playback handoff, and session cleanup before MVP completion claims.
- **Formatting**: `zig fmt` runs on every modified Zig source file during implementation phases.
- **Docs**: `.specs/screensaver/plan.md` stays aligned with generated `.tasks/` execution slices and spec stack changes.

## Risk Mitigation

- Keep `.index.db`, mirror sync, background library sync, and optional bootstrap out of the MVP critical path; allow only a small curated preseeded local pool to satisfy first-run playback.
- Treat renderer-backed playback as the non-negotiable replacement for raw `cat` before adding presentation polish.
- Separate `16c random` delivery from `16c screensaver` session controls so loop playback can land first.
- Hold transitions, advanced render modes, overlays, X11/XScreenSaver adapters, and broader desktop-specific integration until the base loop is usable.
- Treat Omarchy/systemd launch material as examples or owned user-service artifacts only; do not promise package-manager, installer, AUR, Nix, or other deployment channels unless `.ok/deployments.ok.md` says they are TRUE.
- Update constitutional truth only after code, tests, or owned artifacts exist in-repo.

## Success Criteria Validation

- MVP is complete when `16c random` and `16c screensaver` exist as real CLI surfaces, playback uses the ansilust renderer, local art rotation works without full mirror coupling, and session cleanup behavior is tested.
- MVP Omarchy launch scope is complete only when the repo owns the command surface and any promised user-level launch artifacts; idle-manager policy, X11/XScreenSaver support, and extra packaging channels stay outside MVP until separately implemented.
- Post-MVP expansion is complete only when config growth, optional bootstrap/library expansion, environment integration, and any new deployment channels are backed by owned implementation and evidence rather than spec prose; background sync and metadata indexing stay non-promised until that evidence exists.
