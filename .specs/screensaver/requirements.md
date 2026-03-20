# Screensaver Requirements

## Scope and Staging

This document decomposes screensaver delivery into a shortest-path playable MVP plus deferred expansion layers. It is aligned with current constitutional truth in `.ok/screensaver.ok.md`, `.ok/download.ok.md`, and `.ok/render-utf8ansi.ok.md`: the repository does not currently ship continuous rotation, fullscreen screensaver mode, `.index.db`-backed selection, config parsing, bundled pre-cache, or idle-manager integration.

### Stage Boundaries

- **Stage 1 - Playable MVP**: deliver a usable local-loop runtime for `16c random` and `16c screensaver` without requiring `.index.db`, mirror bootstrap, package pre-cache, config parsing, or system integration.
- **Stage 2 - Art-Source Growth**: expand artwork selection beyond the MVP local pool into richer local archive and metadata-backed sources.
- **Stage 3 - Config Expansion**: add persistent user configuration and richer selection/display controls.
- **Stage 4 - Launch and Integration**: add service, idle-manager, packaging, and desktop-environment launch surfaces.

## FR1: Functional Requirements

### FR1.1: Stage 1 - Playable MVP Command Surface
FR1.1.1: The system shall provide a `16c random` command that continuously rotates artwork until stopped.
FR1.1.2: The system shall provide a `16c screensaver` command that runs the same artwork rotation in screensaver mode.
FR1.1.3: WHEN `16c screensaver` starts the system shall enter an isolated terminal presentation mode suitable for fullscreen artwork playback.
FR1.1.4: WHILE `16c screensaver` is active the system shall hide transient terminal chrome needed for artwork playback.
FR1.1.5: WHEN `16c screensaver` receives any keyboard input the system shall treat that input as an exit request and shall end the session promptly without requiring a confirmation step.
FR1.1.6: WHEN `16c screensaver` exits because of keyboard input the system shall restore the terminal presentation state it changed for screensaver playback before the process returns control to the caller.
FR1.1.7: WHEN `16c random` or `16c screensaver` receives `SIGINT`, `SIGTERM`, `SIGHUP`, or `SIGQUIT` the system shall begin an orderly shutdown path instead of leaving the terminal in its screensaver presentation state.
FR1.1.8: WHEN `16c random` or `16c screensaver` handles `SIGINT`, `SIGTERM`, `SIGHUP`, or `SIGQUIT` the system shall restore cursor visibility, input mode, alternate-screen usage, and other terminal state it changed before exiting.
FR1.1.9: IF terminal-state restoration cannot complete during signal-triggered shutdown THEN the system shall still attempt best-effort cleanup before exit.

### FR1.2: Stage 1 - Playable MVP Artwork Selection
FR1.2.1: The system shall select artwork from a local on-disk pool available at runtime.
FR1.2.2: WHEN the local artwork pool contains at least one supported file the system shall start playback without requiring network access.
FR1.2.3: IF the local artwork pool is empty THEN the system shall exit with a helpful message that explains how to obtain artwork.
FR1.2.4: The system shall support one-shot artwork viewing through the existing `random-1` command without changing its current MVP contract.
FR1.2.5: WHILE Stage 1 is the active delivery target the system shall not require `.index.db` or mirror-query infrastructure to select artwork.

### FR1.3: Stage 1 - Playable MVP Playback
FR1.3.1: The system shall render selected artwork through ansilust-owned rendering rather than by subprocessing raw `cat` output.
FR1.3.2: WHILE `16c random` is active the system shall display one artwork at a time for a defined viewing interval before rotating.
FR1.3.3: WHILE `16c screensaver` is active the system shall display one artwork at a time for a defined viewing interval before rotating.
FR1.3.4: WHEN artwork playback completes the system shall advance to another artwork without requiring process restart.
FR1.3.5: WHEN the terminal size changes during Stage 1 playback the system shall preserve a usable display and exit path.

### FR1.4: Stage 2 - Art-Source Growth
FR1.4.1: WHERE local archive browsing is enabled the system shall select artwork from local archive surfaces beyond the Stage 1 pool.
FR1.4.2: WHERE metadata-backed selection is enabled the system shall support random selection from indexed artwork records.
FR1.4.3: WHEN metadata-backed selection is active the system shall use `.index.db` as the authoritative artwork index.
FR1.4.4: IF `.index.db` is unavailable during a metadata-backed mode THEN the system shall fall back to a defined non-indexed local selection path or return a helpful error.
FR1.4.5: WHERE curated bootstrap is enabled the system shall offer an additive way to grow the local artwork pool.
FR1.4.6: WHERE bundled or downloaded artwork growth is enabled the system shall preserve the distinction between official archive material and user-managed local artwork.

### FR1.5: Stage 3 - Config Expansion
FR1.5.1: WHERE persistent user configuration is enabled the system shall read screensaver settings from a documented config surface.
FR1.5.2: WHERE selection filters are enabled the system shall support filtering by archive metadata fields such as year, group, artist, or format.
FR1.5.3: WHERE display controls are enabled the system shall support configurable artwork duration and playback mode selection.
FR1.5.4: WHERE metadata overlays are enabled the system shall support showing and hiding artwork metadata during playback.
FR1.5.5: IF configuration input is invalid THEN the system shall report the problem and continue with safe defaults or exit clearly.

### FR1.6: Stage 4 - Launch and Integration
FR1.6.1: WHERE desktop launch integration is enabled the system shall provide a documented way to start screensaver mode from an external launcher.
FR1.6.2: WHERE idle-manager integration is enabled the system shall support dismissal on resumed user activity.
FR1.6.3: WHERE service-manager integration is enabled the system shall provide documented service templates or equivalent launch artifacts.
FR1.6.4: WHERE package integration is enabled the system shall provide a defined installation-time or first-run path for making artwork available offline.
FR1.6.5: WHERE multi-monitor integration is enabled the system shall document the supported launch behavior per monitor topology.

## NFR2: Non-Functional Requirements

NFR2.1: The Stage 1 MVP shall start playback from a non-empty local artwork pool without requiring network access.
NFR2.2: The Stage 1 MVP shall leave the terminal in a recoverable state after normal exit, input-triggered exit, or signal-triggered exit, including on `SIGINT`, `SIGTERM`, `SIGHUP`, and `SIGQUIT`.
NFR2.3: The Stage 1 MVP shall keep its runtime dependency surface smaller than the full mirror, database, and desktop-integration program.
NFR2.4: Later-stage features shall be additive and shall not be prerequisites for the Stage 1 playable loop.
NFR2.5: Requirement boundaries shall remain explicit so MVP completion is not blocked on post-MVP growth work.

## TC3: Technical Constraints

TC3.1: The requirements shall remain consistent with `.ok/screensaver.ok.md`, `.ok/download.ok.md`, and `.ok/render-utf8ansi.ok.md` until those constitutions are updated with new evidence.
TC3.2: Stage 1 shall not depend on unshipped `.index.db`, mirror bootstrap, or package pre-cache behavior.
TC3.3: Stage 1 shall not depend on hypridle, systemd user services, XScreenSaver, or desktop-specific launch infrastructure.
TC3.4: Stage 1 shall preserve the existing shipped `16c random-1` behavior until a separately implemented and reconciled change updates that contract.

## DR4: Data Requirements

DR4.1: The Stage 1 MVP shall define a local artwork pool abstraction that can enumerate supported artwork files from disk.
DR4.2: The Stage 1 MVP shall define the minimum artwork metadata needed for rotation, such as file path and format suitability.
DR4.3: Stage 2 metadata-backed selection shall define the indexed artwork fields required for random selection and filtering.
DR4.4: Stage 3 configuration shall define defaults for playback duration, selection behavior, and display options.

## IR5: Integration Requirements

IR5.1: Stage 1 playback shall integrate with ansilust rendering instead of relying on raw file dumping.
IR5.2: Stage 2 art-source growth shall integrate with the download surface only through evidenced local storage and indexing contracts.
IR5.3: Stage 4 launch surfaces shall integrate with external desktop tools through documented artifacts owned by the screensaver surface.

## DEP6: Dependencies

DEP6.1: Stage 1 depends on a local artwork enumeration path and ansilust-owned artwork rendering.
DEP6.2: Stage 2 depends on future download-surface work that produces local archive inventory and, if enabled, `.index.db` indexing.
DEP6.3: Stage 3 depends on a future config surface for persisted screensaver settings.
DEP6.4: Stage 4 depends on future packaging and external-launch documentation or artifacts.

## SC7: Success Criteria

SC7.1: Stage 1 is complete when a user with local artwork can run `16c random` for continuous playback and `16c screensaver` for input-dismissible playback, and both commands restore terminal state on input exit and on `SIGINT`, `SIGTERM`, `SIGHUP`, and `SIGQUIT`, without needing mirror, database, or desktop-integration setup.
SC7.2: Stage 2 is complete when the artwork pool can grow beyond the MVP local source through defined local archive and optional metadata-backed selection paths.
SC7.3: Stage 3 is complete when persistent configuration can control selection and playback behavior without redefining the Stage 1 command contract.
SC7.4: Stage 4 is complete when documented launch and idle-integration surfaces can start and dismiss the screensaver in supported environments.
