# Screensaver Requirements

## Scope and Staging

This document decomposes screensaver delivery into a shortest-path playable MVP plus deferred expansion layers. It is aligned with current constitutional truth in `.ok/screensaver.ok.md`, `.ok/download.ok.md`, and `.ok/render-utf8ansi.ok.md`: the repository now ships narrow Stage 1 continuous rotation through `16c random`, a fullscreen-style `16c screensaver` terminal mode, and minimal config parsing from `config.toml` under the resolved `16colors` root, but it does not yet ship `.index.db`-backed selection, bundled pre-cache, or idle-manager integration.

### Stage Boundaries

- **Stage 1 - Playable MVP**: deliver a usable local-loop runtime for `16c random` and `16c screensaver` without requiring `.index.db`, mirror bootstrap, package pre-cache, system integration, or any persistent configuration beyond the shipped `config.toml` lookup under the resolved `16colors` root.
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
FR1.1.7: WHEN `16c random` or `16c screensaver` receives `SIGINT` or `SIGTERM` the system shall begin an orderly shutdown path instead of leaving the terminal in its screensaver presentation state.
FR1.1.8: WHEN `16c random` or `16c screensaver` handles `SIGINT` or `SIGTERM` the system shall restore cursor visibility, input mode, alternate-screen usage, and other terminal state it changed before exiting.
FR1.1.9: IF terminal-state restoration cannot complete during signal-triggered shutdown THEN the system shall still attempt best-effort cleanup before exit.
FR1.1.10: WHILE Stage 1 is the active delivery target the system shall treat cleanup on `SIGINT` and `SIGTERM` as the complete shipped signal-handling contract.
FR1.1.11: WHERE broader signal coverage is added in a later stage or hardening pass the system shall document that expansion as an additive change to the Stage 1 contract.

### FR1.2: Stage 1 - Playable MVP Artwork Selection
FR1.2.1: The system shall select artwork from a local on-disk pool available at runtime.
FR1.2.2: WHEN the local artwork pool contains at least one supported file the system shall start playback without requiring network access.
FR1.2.3: IF the local artwork pool is empty THEN the system shall exit with a helpful message that explains how to obtain artwork.
FR1.2.4: The system shall support one-shot artwork viewing through the existing `random-1` command without changing its current MVP contract.
FR1.2.5: WHILE Stage 1 is the active delivery target the system shall not require `.index.db` or mirror-query infrastructure to select artwork.
FR1.2.6: WHILE Stage 1 is the active delivery target the system shall treat the minimum local artwork pool as the union of the existing platform-managed `random/` cache and `local/` user-art directories under the 16colors data root.
FR1.2.7: WHEN `random-1` saves a supported artwork into the `random/` cache the system shall make that file eligible for subsequent `16c random` and `16c screensaver` selection without requiring any extra import step.
FR1.2.8: WHEN a user places a supported artwork into the `local/` directory the system shall make that file eligible for subsequent `16c random` and `16c screensaver` selection without requiring metadata sidecars or mirror provenance.
FR1.2.9: IF the minimum local artwork pool contains exactly one supported file THEN the system shall still allow Stage 1 playback by replaying that file on each rotation interval until more artwork is available or the session exits.
FR1.2.10: WHILE Stage 1 is the active delivery target the system shall not require enumeration of `packs/` or any full-mirror archive layout to make `16c random` and `16c screensaver` usable.

#### Stage 1 Minimum Local Art Pool Strategy

- The smallest usable offline pool is one playable ANSI file in either the existing `random/` cache or the existing `local/` drop folder under the platform-specific 16colors root.
- This stays aligned with current repo reality: `16c random-1` already writes downloaded artwork into `random/`, `PlatformPaths` already defines `random/`, `packs/`, and `local/`, and the shipped parser surface is ANSI-only today.
- Stage 1 therefore reuses what already exists instead of inventing a new bootstrap format, seed bundle, or metadata database.
- Empty-pool guidance should point users to the two concrete fill paths that already fit the repo: run `16c random-1` at least once, or copy supported ANSI art into `local/`.
- `packs/` remains a Stage 2 growth source because depending on mirror-shaped archive inventory would reintroduce the bootstrap work Stage 1 is explicitly avoiding.

### FR1.3: Stage 1 - Playable MVP Playback And Minimal Config
FR1.3.1: The system shall render selected artwork through ansilust-owned rendering rather than by subprocessing raw `cat` output.
FR1.3.2: WHILE `16c random` is active the system shall display one artwork at a time for a default viewing interval of 20 seconds before rotating.
FR1.3.3: WHILE `16c screensaver` is active the system shall display one artwork at a time for a default viewing interval of 20 seconds before rotating.
FR1.3.4: WHILE Stage 1 is the active delivery target the system shall use a fixed-duration pacing policy with no per-artwork heuristics, transitions, or adaptive timing.
FR1.3.5: The system shall expose instant playback for `16c random` and `16c screensaver` through an explicit `--instant` command-line flag.
FR1.3.6: WHERE `--instant` is enabled the system shall render each selected artwork as a fully drawn frame immediately and shall keep the same rotation interval policy used by default Stage 1 playback.
FR1.3.7: The system shall expose streaming-speed control for `16c random` and `16c screensaver` through a dedicated `--streaming-speed <preset>` command-line option.
FR1.3.8: WHERE `--streaming-speed <preset>` is enabled the system shall use that preset for progressive Stage 1 playback and shall reject unsupported preset names with a helpful error.
FR1.3.9: WHILE Stage 1 is the active delivery target the system shall treat `--instant` and `--streaming-speed` as the only MVP playback-style controls and shall not require a broader presentation-mode abstraction.
FR1.3.10: IF `--instant` and `--streaming-speed` are both provided THEN the system shall reject the invocation with a clear mutual-exclusivity error.
FR1.3.11: WHEN a 20-second viewing interval ends the system shall replace the current artwork immediately with the next selected artwork.
FR1.3.12: WHEN artwork playback completes the system shall advance to another artwork without requiring process restart.
FR1.3.13: WHEN the terminal size changes during Stage 1 playback the system shall preserve a usable display and exit path.
FR1.3.14: The system shall load the shipped Stage 1 config file for `16c random` and `16c screensaver` from `config.toml` under the resolved `16colors` data root.
FR1.3.15: IF that `config.toml` file is missing THEN the system shall fall back to built-in Stage 1 defaults.
FR1.3.16: WHILE Stage 1 is the active delivery target the system shall treat the `16colors`-root `config.toml` path as the explicit shipped config-path contract and shall not require or imply `~/.config/16c/config.toml`.

### FR1.4: Stage 2 - Art-Source Growth
FR1.4.1: WHERE local archive browsing is enabled the system shall select artwork from local archive surfaces beyond the Stage 1 pool.
FR1.4.2: WHERE metadata-backed selection is enabled the system shall support random selection from indexed artwork records.
FR1.4.3: WHEN metadata-backed selection is active the system shall use `.index.db` as the authoritative artwork index.
FR1.4.4: IF `.index.db` is unavailable during a metadata-backed mode THEN the system shall fall back to a defined non-indexed local selection path or return a helpful error.
FR1.4.5: WHERE curated bootstrap is enabled the system shall offer an additive way to grow the local artwork pool.
FR1.4.6: WHERE bundled or downloaded artwork growth is enabled the system shall preserve the distinction between official archive material and user-managed local artwork.
FR1.4.7: WHERE the first additive Stage 2 source mode is introduced the system shall expose it as `source.mode = "local_archive"`.
FR1.4.8: WHERE `source.mode = "local_archive"` is active the system shall derive selection candidates only from local filesystem state beneath the resolved 16colors root.
FR1.4.9: WHERE `source.mode = "local_archive"` is active the system shall treat `packs/` as the primary managed archive surface while preserving `random/` and `local/` as eligible local fallback roots.
FR1.4.10: IF `source.mode = "local_archive"` cannot derive richer archive metadata from local files or paths THEN the system shall still admit filesystem-derived local archive candidates without requiring `.index.db`.
FR1.4.11: WHILE `source.mode = "local_archive"` is active the system shall not require remote fetch, mirror sync, bootstrap, or background growth to keep playback selection working.
FR1.4.12: WHILE `source.mode = "auto"` remains the shipped default the system shall preserve the Stage 1 local-pool contract unless a later evidenced revision explicitly promotes a broader default policy.

#### Stage 2 First Additive Source Mode Contract

- `local_archive` is the first post-Stage-1 source-mode addition because it widens playback only to other already-local material and therefore does not smuggle in remote, mirror, or bootstrap promises.
- `local_archive` is intentionally opt-in. Keeping `auto` as the shipped default preserves current Stage 1 truth instead of silently redefining the meaning of existing configs.
- The `local_archive` ladder is local-only: prefer filesystem-derived candidates rooted in `packs/`, then continue to honor already-local playable material from `random/` and `local/`.
- `.index.db` remains a later optional authority layer. If it exists before a later stage promotes it, `local_archive` still resolves from filesystem-derived local state rather than treating the database as required.
- Mirror manifests, remote catalog metadata, and first-run growth remain out of scope for this source mode; they need separate later-stage evidence.

### FR1.5: Stage 3 - Config Expansion
FR1.5.1: WHERE expanded persistent user configuration is enabled the system shall read screensaver settings from a documented config surface that extends or supersedes the minimal Stage 1 `config.toml`-in-`16colors`-root runtime contract.
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
NFR2.2: The Stage 1 MVP shall leave the terminal in a recoverable state after normal exit, input-triggered exit, or signal-triggered exit, including on `SIGINT` and `SIGTERM`.
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
DR4.2.1: The Stage 1 local artwork pool abstraction shall enumerate supported ANSI artwork from `random/` and `local/` before any later-stage archive or database source is considered.
DR4.2.2: The Stage 1 pool descriptor shall require only file path, basename, and format suitability for playback; archive pack metadata, year, group, and artist fields shall remain optional until Stage 2 metadata-backed selection exists.
DR4.2.3: The Stage 1 empty-pool message shall name `random/` and `local/` as the concrete directories the user can populate.
DR4.3: Stage 2 metadata-backed selection shall define the indexed artwork fields required for random selection and filtering.
DR4.3.1: The first additive Stage 2 source-mode literal shall be `local_archive`.
DR4.3.2: The `local_archive` mode shall require only filesystem-derived local identity for archive candidates, including enough path information to resolve playable files beneath `packs/` without requiring `.index.db` records.
DR4.3.3: The `local_archive` mode shall preserve `random/` and `local/` as valid already-local fallback roots when `packs/` is absent, sparse, or temporarily non-playable.
DR4.3.4: The shipped default config literal shall remain `auto` until a later evidenced revision intentionally changes that default contract.
DR4.4: The Stage 1 MVP shall define a default playback duration of 20 seconds per artwork and a fixed immediate-cut rotation policy.
DR4.4.1: The Stage 1 MVP shall define `--instant` as a boolean command override for immediate full-frame playback.
DR4.4.2: The Stage 1 MVP shall define `--streaming-speed <preset>` as a command override that selects from a documented preset set rather than arbitrary free-form timing input.
DR4.4.3: The Stage 1 MVP shall keep playback-style overrides ephemeral to the current command invocation; persisted playback-mode configuration remains a Stage 3 concern.
DR4.4.4: The Stage 1 MVP shall treat `config.toml` in the resolved `16colors` root as the shipped shared config file for `16c random` and `16c screensaver`.
DR4.4.5: The Stage 1 MVP shall limit its evidenced persisted config surface to built-in defaults plus the minimal values currently parsed from that file, while broader config schema work remains a Stage 3 concern.
DR4.5: Stage 3 configuration shall define defaults for playback duration, selection behavior, and display options.

## IR5: Integration Requirements

IR5.1: Stage 1 playback shall integrate with ansilust rendering instead of relying on raw file dumping.
IR5.2: Stage 2 art-source growth shall integrate with the download surface only through evidenced local storage and indexing contracts.
IR5.3: Stage 4 launch surfaces shall integrate with external desktop tools through documented artifacts owned by the screensaver surface.

## DEP6: Dependencies

DEP6.1: Stage 1 depends on a local artwork enumeration path and ansilust-owned artwork rendering.
DEP6.1.1: The minimum usable Stage 1 pool depends only on the already-defined 16colors data-root directories `random/` and `local/`, plus at least one supported ANSI file in either location.
DEP6.2: Stage 2 depends on future download-surface work that produces local archive inventory and, if enabled, `.index.db` indexing.
DEP6.3: Stage 3 depends on future config-surface work beyond the shipped Stage 1 `config.toml` contract in the resolved `16colors` root.
DEP6.4: Stage 4 depends on future packaging and external-launch documentation or artifacts.

## SC7: Success Criteria

SC7.1: Stage 1 is complete when a user with local artwork can run `16c random` for continuous playback and `16c screensaver` for input-dismissible playback, and both commands restore terminal state on input exit and on `SIGINT` and `SIGTERM`, without needing mirror, database, or desktop-integration setup.
SC7.2: Stage 2 is complete when the artwork pool can grow beyond the MVP local source through defined local archive and optional metadata-backed selection paths.
SC7.3: Stage 3 is complete when persistent configuration can control selection and playback behavior without redefining the Stage 1 command contract.
SC7.4: Stage 4 is complete when documented launch and idle-integration surfaces can start and dismiss the screensaver in supported environments.
