# Ansilust Screensaver for Omarchy Linux

> **Note**: Active screensaver planning now spans `.ok/screensaver.ok.md` and `.specs/screensaver/{requirements,design,plan}.md`.

## Concept

Create a screensaver for Omarchy Linux that continuously scrolls through classic ANSI art from the [16colo.rs](https://16colo.rs) BBS art archive, bringing retro computing aesthetics to modern Linux systems.

**Status**: Decomposed into a staged delivery ladder; shipped runtime truth remains Stage 0 only (`16c random-1`) while the active screensaver stack now lives in `.ok/screensaver.ok.md` plus `.specs/screensaver/requirements.md`, `.specs/screensaver/design.md`, and `.specs/screensaver/plan.md`.

## Core Features

### Art Display
- Continuously cycle through ANSI art from the 16colo.rs archive
- Smooth scrolling transitions between artworks
- Full-screen display optimized for various terminal sizes
- Support for all ansilust-compatible formats (ANSI, Binary, PCBoard, XBin, etc.)

### Screensaver Behavior
- Activate after configurable idle time
- Dismiss on any keyboard/mouse activity
- Low CPU/memory footprint during operation
- Respect system suspend/hibernation

### Art Selection
- Random selection from the entire archive
- Optional filtering by:
  - Year/era (1990s vs modern)
  - Art group (ACiD, iCE, Blocktronics, etc.)
  - Artist
  - Format type
- Favorite collections support
- "Best of" curated playlists

### Display Options
- Configurable transition effects:
  - Fade in/out
  - Scroll up/down/left/right
  - Instant switch
  - Slow reveal (line-by-line)
- Adjustable timing (seconds per artwork)
- Optional metadata overlay (artist, date, pack)
- Retro scan-line effect (optional)

## Technical Integration

### Omarchy Linux Integration
- Future launch/integration layer for Omarchy-friendly idle and fullscreen wiring
- Future Wayland/X11 launch documentation or wrappers
- Future systemd or idle-manager examples as owned artifacts
- Future configuration via documented launch surfaces rather than assumed desktop settings
- Future theme-awareness only after playback and launch stages exist

### Architecture
```
screensaver/
├── main.zig              # Screensaver entry point
├── idle_detector.zig     # System idle monitoring
├── art_loader.zig        # 16colo.rs API client
├── display_manager.zig   # Fullscreen rendering
├── transition.zig        # Transition effects
└── config.zig           # User preferences
```

### Data Management
- Local cache of downloaded artpacks
- Background sync with 16colo.rs
- Offline mode (use cached art)
- Bandwidth-friendly updates
- SQLite for metadata/favorites

### Rendering
- Use ansilust rendering engine
- Hardware-accelerated terminal rendering
- Support for modern terminal features (24-bit color)
- Fallback to 16-color for compatibility
- Adaptive sizing for different screen resolutions

## User Experience

### Installation
```bash
# Install ansilust-screensaver package
omarchy-pkg install ansilust-screensaver

# Configure via GUI or CLI
ansilust-screensaver --configure

# Test screensaver
ansilust-screensaver --preview
```

### Configuration Options
- Idle timeout duration
- Art source (full archive, favorites, specific groups)
- Transition style and speed
- Display metadata (on/off)
- Cache size limit
- Update frequency

## Delivery Ladder

### Stage 0: Current Repository Truth
- [x] `16c random-1` fetches one artwork, stores it locally, prints it once, and exits
- [x] Screensaver-adjacent behavior is limited to this one-shot path
- [ ] Continuous playback
- [ ] Dedicated `16c screensaver` session lifecycle
- [ ] Renderer-backed playback on the download surface

### Stage 1: Playable Loop MVP
- [ ] Add looping `16c random` playback from a local playable pool
- [ ] Add `16c screensaver` using the same loop with input-exit behavior
- [ ] Replace raw `cat` display with ansilust parser-to-renderer handoff
- [ ] Keep this stage independent of `.index.db`, mirror sync, bootstrap downloads, filters, and desktop integration

### Stage 2: Session And Source Growth
- [ ] Add alternate-screen, cursor lifecycle, and signal-safe cleanup for screensaver sessions
- [ ] Expand beyond the minimum playable pool into richer local archive selection
- [ ] Introduce metadata-backed or filesystem-backed rotation behind the same playback contract
- [ ] Preserve the Stage 1 command/runtime surface while source depth improves

### Stage 3: Config And Experience Expansion
- [ ] Add persistent config for duration, playback mode, and future selection controls
- [ ] Add filtering, metadata overlay, and richer presentation policies as additive features
- [ ] Keep these controls optional so the base loop stays usable without config

### Stage 4: Environment Integration
- [ ] Add owned docs or artifacts for systemd user services, hypridle/swayidle hooks, and launch surfaces
- [ ] Define packaging/bootstrap paths for making artwork available offline
- [ ] Document multi-monitor and desktop-environment behavior after the runtime exists

## Why This Matters

**Preservation**: Showcases classic BBS art to modern Linux users

**Aesthetics**: Brings retro computing culture into daily desktop experience

**Education**: Introduces new users to ANSI art history and scene culture

**Showcase**: Demonstrates ansilust rendering capabilities in a practical application

**Community**: Celebrates the work of scene artists past and present

**Nostalgia**: Delights those who remember the BBS era

## Implementation Notes

- Use ansilust for all art rendering
- Leverage Zig for low-level system integration
- Minimal dependencies for easy packaging
- Respect system power management
- Follow Linux screensaver conventions
- Open source (same license as ansilust)

## Inspiration

- XScreenSaver modules (phosphor, apple2, etc.)
- ACiDView.exe slideshow mode
- 16colo.rs website gallery
- Classic BBS welcome screens
- Flying toasters (but with ANSI art!)

## Future Enhancements

- Multi-monitor support
- Synchronized display across machines
- Community voting on featured art
- Artist of the day spotlight
- Integration with other scene archives
- ANSI music/MOD playback during display
- Virtual BBS experience mode

---

**Status**: Staged planning with Stage 0 current truth only (`16c random-1`)  
**Priority**: Low-Medium (fun showcase project)  
**Dependencies**: Stage 1 depends on local artwork enumeration plus ansilust-owned rendering; later stages add `.index.db`/mirror growth, config, packaging, and idle-manager integration only after the playable loop exists  
**Target Audience**: Omarchy Linux users, ANSI art enthusiasts, retro computing fans
