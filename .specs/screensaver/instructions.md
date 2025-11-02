# 16c screensaver - BBS Art Terminal Screensaver

## Overview

The `16c` CLI provides built-in screensaver functionality through simple subcommands. Inspired by the Omarchy screensaver pattern (fullscreen Alacritty/Ghostty running custom ANSI script), but integrated with the ansilust/16c ecosystem for authentic retro BBS art display.

**Key Philosophy**: This screensaver showcases classic BBS art with streaming-style rendering that evokes the dialup modem experience. It reuses the existing `16c` CLI rather than creating a separate command.

**CLI Commands**:
- `16c` - Shows usage information
- `16c random` - Continuously streams random artwork (the heart of the screensaver)
- `16c random-1` - Prints one random artwork as fast as possible and exits
- `16c screensaver` - Like `16c random` but with fullscreen mode and exit-on-input handling

## Design Context

### Omarchy Screensaver Pattern

The reference implementation (Obsidian-OS/Omarchy screensaver) follows this pattern:
```bash
#!/bin/bash
# Loops terminal text effects (tte) with random effects
while true; do
  effect=$(tte 2>&1 | grep -oP '{\K[^}]+' | shuf -n1)
  echo "$LOGO" | tte --frame-rate 240 --canvas-width 0 \
    --canvas-height $(($(tput lines) - 2)) --anchor-canvas c --anchor-text c "$effect"
  if read -n 1 -t 3; then exit 0; fi
done
```

**Key Observations**:
- Fullscreen terminal application (run via Alacritty/Ghostty/etc in dedicated window)
- Loops indefinitely until keyboard input detected
- Uses `tte` (Terminal Text Effects) for animated rendering
- Canvas sizing handles terminal dimensions dynamically
- Exit on any user input (keyboard/mouse)

### Integration with Hyprland/systemd

**User Configuration**: `~/.config/hypr/hypridle.conf`
```
timeout 300
  on-timeout loginctl lock-session
timeout 360
  on-timeout hyprctl dispatch dpms off
on-resume hyprctl dispatch dpms on
```

**System Integration**:
- Works with existing idle detection (hypridle, swayidle, xautolock)
- Launched via systemd user service or idle handler
- Respects DPMS/power management
- Dismisses on keyboard/mouse activity

## Core Requirements (EARS Notation)

### FR1.1: CLI Command Interface
FR1.1.1: The system shall provide `16c random` to continuously stream random artwork.  
FR1.1.2: The system shall provide `16c random-1` to display one random artwork and exit.  
FR1.1.3: The system shall provide `16c screensaver` for fullscreen screensaver mode.  
FR1.1.4: WHEN `16c screensaver` is invoked the system shall enter fullscreen mode.  
FR1.1.5: WHEN `16c screensaver` is running the system shall exit on any keyboard input.  
FR1.1.6: The system shall exit cleanly on SIGINT/SIGTERM/SIGHUP/SIGQUIT signals.

### FR1.2: Artwork Selection and Display
FR1.2.1: WHEN `16c random` or `16c screensaver` is invoked the system shall randomly select artwork from the local mirror.  
FR1.2.2: WHERE the local mirror contains artwork the system shall display it immediately.  
FR1.2.3: WHERE the local mirror is empty the system shall display a helpful error and offer to bootstrap.  
FR1.2.4: The `16c random` command shall cycle through artworks with reasonable viewing time between pieces.  
FR1.2.5: The `16c random-1` command shall display one artwork at maximum speed and exit.  
FR1.2.6: WHEN displaying artwork the system shall use ansilust rendering (not raw ANSI dump).  
FR1.2.7: The system shall support all ansilust-compatible formats (ANS, ASC, XB, etc.).

### FR1.3: Screen Sizing and Layout
FR1.3.1: The screensaver shall automatically detect terminal dimensions.  
FR1.3.2: WHEN artwork is smaller than terminal the system shall center it without letterboxing.  
FR1.3.3: WHEN artwork is larger than terminal the system shall scale/crop to fit without distortion.  
FR1.3.4: The system shall handle terminal resize events gracefully.  
FR1.3.5: The system shall respect artwork aspect ratio and SAUCE metadata for display hints.

### FR1.4: Streaming/BBS-Style Rendering
FR1.4.1: The system shall render artwork with streaming-style animation (line-by-line or character-by-character).  
FR1.4.2: The streaming speed shall be configurable (default: ~2400 baud simulation).  
FR1.4.3: The system shall support instant rendering mode via `--instant` flag.  
FR1.4.4: WHERE SAUCE metadata indicates specific rendering hints the system shall apply them.

### FR1.5: Configuration and Filtering
FR1.5.1: The system shall support a configuration file at `~/.config/16c/config.toml`.  
FR1.5.2: The configuration shall support artwork filters (year, group, artist, format).  
FR1.5.3: The configuration shall support timing settings (seconds per artwork, streaming speed).  
FR1.5.4: The configuration shall support metadata overlay (artist, pack, date) toggle.  
FR1.5.5: WHERE no configuration exists the system shall use sensible defaults.  
FR1.5.6: Configuration settings shall apply to `16c random`, `16c random-1`, and `16c screensaver`.

### FR1.6: Mirror Integration and Random Selection
FR1.6.1: WHEN selecting random artwork the system shall query `.index.db` for available artwork.  
FR1.6.2: WHERE the local mirror has artwork the system shall display it immediately (no waiting).  
FR1.6.3: WHERE the local mirror is empty the system shall display a helpful error message.  
FR1.6.4: The system shall select from both `packs/` (archive) and `local/` (user artwork) directories.  
FR1.6.5: The system shall respect mirror organization (packs by year).  
FR1.6.6: WHEN artwork is selected the system shall read metadata from `.index.db`.  
FR1.6.7: The system shall cache artwork file list for performance.  
FR1.6.8: WHERE `.index.db` does not exist the system shall fall back to filesystem scanning.

### FR1.7: Background Bootstrap (Optional Enhancement)
FR1.7.1: WHERE `16c random` detects an empty mirror the system may offer to bootstrap curated favorites.  
FR1.7.2: WHEN bootstrap is accepted the system shall download curated packs in background (reuses `16c download`).  
FR1.7.3: The background download shall not block artwork display.  
FR1.7.4: WHEN downloads complete the system shall trigger `.index.db` update (via download spec functionality).  
FR1.7.5: IF offline the system shall continue with available artwork and skip bootstrap.

### FR1.8: Systemd/Idle Integration
FR1.8.1: The system shall provide documentation for systemd user service integration.  
FR1.8.2: The service template shall launch `16c screensaver` in a dedicated terminal window.  
FR1.8.3: The service shall support activation via idle detection hooks (hypridle/swayidle).  
FR1.8.4: The service shall respect DPMS power management settings.

## Out of Scope (Dependencies)

These features are **explicitly out of scope** for this spec and rely on other ansilust features:

### Relies on: 16colors Download/Mirror (.specs/download/)
- `16c mirror sync` - Full archive mirroring (manual, advanced users)
- `16c download <pack>` - Individual pack downloads (can be used by bootstrap)
- Local mirror structure (`~/Pictures/16colors/packs/`, `local/`, `.index.db`)
- `.index.db` - Shared SQLite database with all artwork metadata
- SAUCE metadata extraction and database indexing
- Mirror location discovery (platform-specific paths)

**Note**: The screensaver **reuses** the download/mirror infrastructure and adds:
- Pre-cached artwork via post-install script
- Random artwork selection via `.index.db` queries
- Optional background bootstrap (calls `16c download` for curated packs)

### Relies on: Ansilust Rendering
- **Streaming-style rendering** - The exact implementation of line-by-line or character-by-character rendering with timing control
- **Format parsing** - ANS, ASC, XB, PCB, etc. parsers
- **SAUCE metadata handling** - Reading rendering hints from SAUCE records
- **Color/font handling** - CP437, palette, iCE colors mode
- **Aspect ratio** - Respecting DOS aspect ratio (1.35x) hints

**Design Decision**: The screensaver spec focuses on **new functionality** (random selection, pre-caching, screensaver mode) while **reusing existing infrastructure** from `.specs/download/` (mirror structure, `.index.db`, download client). This maintains clean separation of concerns and avoids duplicating specifications.

### Zero-Wait Design Philosophy

**Problem**: Traditional screensavers fail if artwork isn't available (missing mirror, offline, fresh install).

**Solution**: Progressive enhancement with pre-cached artwork:

```
Install Package
    ↓
Post-install script runs
    ↓
    Extract pre-cached artwork to mirror location
    ↓
    Update .index.db with pre-cached metadata
    ↓
    User ready to run immediately
    ↓
Run `16c random` or `16c screensaver`
    ↓
┌─────────────────────────────────────┐
│ Mirror has artwork?                 │
├─────────────────────────────────────┤
│ YES → Display immediately           │
│ NO  → Show helpful error + bootstrap│
└─────────────────────────────────────┘
    ↓
Display artwork immediately (NO WAIT)
    ↓
IF user wants more artwork:
    ↓
    Run `16c random` (starts background sync automatically)
        ↓
        Background Thread: Download curated packs
        ↓
        Download favorites (async)
        ↓
        Extract and index
        ↓
        Add to rotation seamlessly
    ↓
    Background Thread: Continue mirror sync
        ↓
        Download additional packs (throttled)
        ↓
        Build full mirror over time
```

**Key Principles**:
1. **Never block the user** - Post-install pre-caches artwork
2. **Standard mirror location** - Pre-cached art lives in normal mirror structure
3. **Progressive enhancement** - Download more artwork in background during use
4. **Offline resilient** - Works indefinitely with pre-cached artwork
5. **Seamless growth** - Mirror expands transparently while viewing

## Technical Specifications

### Canvas Sizing Strategy

**Goal**: Avoid letterboxing while preserving artwork integrity.

**Approach**:
- Detect terminal dimensions
- Read artwork dimensions from SAUCE metadata (or auto-detect)
- Center artwork if smaller than terminal
- Scale to fit if larger than terminal (preserve aspect ratio)

**Rendering Modes**:
1. **Fit Mode** (default): Scale to fit, preserve aspect ratio, center
2. **Fill Mode**: Crop to fill screen
3. **Native Mode**: Display at original size, crop if needed

**Note**: Sizing and rendering implementation details are in ansilust rendering system (out of scope).

### Streaming Rendering

**Design Dependency**: Streaming rendering is implemented by the ansilust rendering system (out of scope for this spec).

**Screensaver Responsibility**: 
- Configure streaming speed (instant, 1200 baud, 2400 baud, etc.)
- Pass terminal dimensions for centering
- Invoke renderer with selected artwork path

### Configuration File Format

**Location**: `~/.config/16c/config.toml`

**Format**: TOML
```toml
[display]
artwork_duration = 30          # Seconds per artwork (16c random/screensaver)
streaming_speed = "2400baud"   # "instant", "1200baud", "2400baud", "9600baud"
show_metadata = true           # Display artist/pack overlay
render_mode = "fit"            # "fit", "fill", "native"

[filters]
# Limit to specific years (null = no limit)
year_min = 1990
year_max = 2025

# Limit to specific groups (empty = all groups)
groups = ["mistigris", "blocktronics"]

# Limit to specific formats (empty = all formats)
formats = ["ans", "asc"]

# Exclude NSFW content
exclude_nsfw = true

[advanced]
# Cache artwork list for performance
cache_artwork_list = true
cache_ttl_seconds = 3600

# Refresh mirror check interval
mirror_check_interval = 300    # Seconds
```

### Metadata Overlay

**Display Format** (bottom-left corner):
```
┌──────────────────────────────────────┐
│                                      │
│    [Artwork rendered here]           │
│                                      │
│                                      │
└──────────────────────────────────────┘
  Artist: Cthulu | Pack: MIST1025 | 2025
```

**Positioning**:
- Bottom-left corner, 1 line from bottom
- Dimmed/subtle color (e.g., dark gray)
- Automatically hide if `show_metadata = false`

**Content**:
- **Artist**: From SAUCE author field or filename heuristics
- **Pack**: Pack name (e.g., mist1025)
- **Year**: Pack year or SAUCE date

### Exit Handling (Screensaver Mode Only)

**Requirements**:
- Register signal handlers for SIGINT/SIGTERM/SIGHUP/SIGQUIT
- Poll for keyboard input (non-blocking)
- Exit immediately on any input
- Restore terminal state on exit (cursor visible, alternate screen off)

### Fullscreen Mode (Screensaver Only)

**Requirements**:
- Detect terminal dimensions
- Enter alternate screen buffer (preserve user's terminal state)
- Hide cursor during display
- Restore cursor and exit alternate screen on exit

### Systemd Integration

**User Service Example**: `~/.config/systemd/user/16c-screensaver.service`
```ini
[Unit]
Description=16colors BBS Art Screensaver
After=graphical-session.target

[Service]
Type=simple
# Launch in dedicated terminal window
ExecStart=/usr/bin/alacritty --class screensaver -e 16c screensaver
# Or Ghostty:
# ExecStart=/usr/bin/ghostty --class screensaver -e 16c screensaver

Restart=no

[Install]
WantedBy=default.target
```

**Idle Detection Integration** (hypridle example):
```
timeout 300
  on-timeout systemctl --user start 16c-screensaver.service
on-resume systemctl --user stop 16c-screensaver.service
```

**Shell Script Wrapper** (like omarchy-launch-screensaver):
```bash
#!/bin/bash
# Exit early if 16c not installed
command -v 16c &>/dev/null || exit 1

# Exit if already running
pgrep -f "alacritty --class screensaver.*16c screensaver" && exit 0

# Launch on each monitor
for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
  hyprctl dispatch focusmonitor $m
  hyprctl dispatch exec -- alacritty --class screensaver -e 16c screensaver
done
```

**Hyprland Window Rules** (for fullscreen):
```
# In ~/.config/hypr/hyprland.conf
windowrulev2 = fullscreen, class:^(screensaver)$
windowrulev2 = noblur, class:^(screensaver)$
windowrulev2 = noshadow, class:^(screensaver)$
```

## CLI Usage Examples

### Basic Usage
```bash
# Show usage information
16c

# Display one random artwork (fast) and exit
16c random-1

# Continuously stream random artwork (reasonable viewing pace)
16c random

# Fullscreen screensaver mode (exits on any input)
16c screensaver
```

### Configuration Options
All configuration is shared across `16c random`, `16c random-1`, and `16c screensaver` via `~/.config/16c/config.toml`.

```bash
# Example config file
cat > ~/.config/16c/config.toml << 'EOF'
[display]
artwork_duration = 30
streaming_speed = "2400baud"
show_metadata = true

[filters]
year_min = 1990
year_max = 2025
groups = ["mistigris", "blocktronics"]
formats = ["ans", "asc"]
exclude_nsfw = true
EOF

# Test with random artwork
16c random-1

# Run screensaver with config
16c screensaver
```

### Systemd Service Setup
```bash
# Create user service directory
mkdir -p ~/.config/systemd/user

# Create service file
cat > ~/.config/systemd/user/16c-screensaver.service << 'EOF'
[Unit]
Description=16colors BBS Art Screensaver
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/alacritty --class screensaver -e 16c screensaver
Restart=no

[Install]
WantedBy=default.target
EOF

# Reload systemd
systemctl --user daemon-reload

# Test the service
systemctl --user start 16c-screensaver.service
# Press any key to exit
```

## Installation Guide

### Prerequisites
```bash
# Install 16c (part of ansilust)
# Build from source or install package

# Ensure 16colors mirror is set up
16c mirror sync --since 2020

# Install terminal (Alacritty or Ghostty recommended)
# Alacritty: pacman -S alacritty
# Ghostty: yay -S ghostty-git

# Test basic functionality
16c random-1  # Should display one random artwork
```

### Systemd Setup (Manual)
```bash
# Create service file (see example above)
mkdir -p ~/.config/systemd/user
$EDITOR ~/.config/systemd/user/16c-screensaver.service

# Configure hypridle (for Hyprland users)
cat >> ~/.config/hypr/hypridle.conf << 'EOF'
timeout 300
  on-timeout systemctl --user start 16c-screensaver.service
on-resume systemctl --user stop 16c-screensaver.service
EOF

# Reload and test
systemctl --user daemon-reload
systemctl --user start 16c-screensaver.service
```

### Configuration
```bash
# Create config directory
mkdir -p ~/.config/16c

# Edit config (create if doesn't exist)
$EDITOR ~/.config/16c/config.toml

# Test config
16c random-1
```

## User Stories

### Story 1: Retro Computing Enthusiast
**As a** retro computing enthusiast  
**I want** my idle terminal to showcase classic BBS art with authentic dialup-style rendering  
**So that** I can enjoy the nostalgia and share the art scene with others

**Acceptance Criteria**:
- Fresh install works immediately with bundled artwork (no setup required)
- Screensaver activates after 5 minutes idle
- Artwork streams line-by-line at configurable speed
- Displays artist and pack name subtly
- Exits cleanly on any keyboard input
- Background downloads curated favorites without disrupting viewing

### Story 2: Art Collector
**As a** text art collector  
**I want** to curate a custom selection of artwork for my screensaver  
**So that** I can showcase my favorite pieces from specific groups or eras

**Acceptance Criteria**:
- Fresh install shows curated bundled artwork immediately (no manual download)
- Configuration file supports year/group/artist filters
- Only artwork matching filters is displayed (bundled + mirror)
- Artwork list is cached for instant startup
- Configuration changes take effect on next run
- Background bootstrap expands collection transparently

### Story 3: Hyprland User
**As a** Hyprland user  
**I want** the screensaver to integrate with hypridle  
**So that** it activates automatically and respects power management

**Acceptance Criteria**:
- Systemd service installs easily
- Hypridle configuration provided in docs
- Fullscreen window rules work out of box
- DPMS events are respected

### Story 4: Minimal Distractions
**As a** minimalist user  
**I want** the screensaver to display artwork without overlays or animations  
**So that** I can enjoy clean, unmodified artwork

**Acceptance Criteria**:
- `--instant` flag disables streaming animation
- `--no-metadata` hides artist/pack overlay
- Native mode displays artwork at original size
- No unnecessary visual effects or borders

## Acceptance Criteria (EARS Patterns)

### AC1: Basic Commands Operation
- WHEN the user runs `16c random-1` the system shall display one random artwork and exit
- WHEN the user runs `16c random` the system shall continuously stream random artwork
- WHEN the user runs `16c screensaver` the terminal shall enter fullscreen mode
- The system shall display random artwork from the local mirror
- WHEN in screensaver mode AND the user presses any key the system shall exit cleanly
- The terminal state shall be fully restored on screensaver exit

### AC2: Artwork Sizing and Centering
- WHEN artwork is smaller than terminal the artwork shall be centered without black bars
- WHEN artwork is larger than terminal the artwork shall scale to fit (maintaining aspect ratio)
- SAUCE metadata width/height shall override auto-detection
- Aspect ratio hints from SAUCE shall be applied
- Terminal resize events shall trigger re-centering

### AC3: Configuration and Filtering
- WHEN `~/.config/16c/config.toml` exists the settings shall be applied
- Configuration shall apply to `16c random`, `16c random-1`, and `16c screensaver`
- Year/group/artist filters shall limit artwork selection
- Streaming speed setting shall control render timing
- Metadata overlay toggle shall show/hide artist information
- Missing config shall use sensible defaults

### AC4: Systemd Integration
- The documentation shall provide systemd user service template
- The service template shall launch `16c screensaver` in a dedicated terminal window
- Hypridle integration shall activate/deactivate the service
- DPMS events shall be respected
- Service shall stop cleanly when `16c screensaver` exits on user input

### AC5: Zero-Wait Pre-cache
- WHEN package is installed the post-install script shall pre-cache curated artwork
- Pre-cached artwork shall be placed in standard mirror location (`packs/YYYY/packname/`)
- Post-install script shall update `.index.db` with pre-cached artwork metadata
- WHEN first run the system shall query `.index.db` and display artwork immediately
- Random selection shall use `.index.db` for instant queries (no filesystem scanning)
- Artwork list shall be cached in memory for performance during runtime

### AC6: Offline Resilience  
- WHEN offline the system shall work indefinitely with pre-cached artwork
- WHERE pre-cache failed AND offline the system shall display helpful error with manual setup instructions
- Network failures shall not interrupt artwork display
- WHERE `.index.db` exists the system shall function fully offline

## Success Metrics

### SM1: User Experience
- Screensaver activates within 1 second of invocation
- Artwork selection feels random and varied
- Streaming animation speed matches configured baud rate simulation
- Exit is instant on any keyboard input
- No visual glitches or artifacts during rendering

### SM2: Integration Quality
- Systemd service installs without errors
- Hypridle/swayidle integration works out of box
- Fullscreen window rules apply correctly
- DPMS power management is respected
- Configuration changes take effect without restart

### SM3: Performance
- Artwork list cache loads in < 100ms
- Mirror discovery completes in < 200ms
- Terminal resize handling is smooth (no flicker)
- Memory usage remains stable during long runs
- CPU usage is minimal when idle between artworks

### SM4: Flexibility
- Users can filter to specific years/groups/artists
- Streaming speed is adjustable from instant to slow dialup
- Metadata overlay can be toggled on/off
- Render modes support different artwork sizes
- Configuration is easy to understand and modify

## Testing Requirements

### Unit Tests
- Artwork selection algorithm (random, filtered)
- Configuration file parsing (TOML)
- Terminal size detection
- Canvas sizing calculations (fit/fill/native modes)
- SAUCE metadata extraction
- Cache invalidation logic

### Integration Tests
- End-to-end screensaver run (spawn, display, exit)
- Configuration file application
- Mirror discovery and artwork enumeration
- Systemd service installation
- Signal handling (SIGINT, SIGTERM)
- Terminal state restoration

### Manual Tests
- Visual inspection of artwork centering
- Streaming animation timing verification
- Metadata overlay positioning
- Fullscreen behavior in different terminals
- Hypridle integration testing
- Long-running stability test

## Implementation Notes

### High-Level Architecture
```
16c random|random-1|screensaver
    ↓
1. Load config (~/.config/16c/config.toml)
    ↓
2. Query .index.db for available artwork (download spec)
    ↓
3. Apply filters (year/group/artist from config)
    ↓
4. IF screensaver: Enter fullscreen mode
    ↓
5. Loop (or once for random-1):
    a. Select random artwork from filtered list
    b. Render via ansilust (streaming speed from config)
    c. Show metadata overlay (if enabled)
    d. IF random|screensaver: Wait (artwork_duration seconds)
    e. IF screensaver: Poll for input (exit on any key)
    f. IF random-1: Exit after one
    ↓
6. IF screensaver: Restore terminal state
```

**Key Abstraction Layers**:
- **Download Spec** (.specs/download/): Mirror management, `.index.db` queries, downloads
- **Rendering System**: ANSI rendering, streaming speed, canvas sizing
- **This Spec**: Random selection, fullscreen mode, timing, exit handling

### Technology Stack
- **Language**: Zig (consistency with ansilust)
- **Config**: TOML parsing (zig-toml or similar)
- **Terminal**: ANSI escape sequences, termios
- **Rendering**: Ansilust renderer (dependency)
- **Mirror**: 16colors standard directory structure

### Phase 1: Pre-cache and Basic Display
- [ ] Create curated artwork archive for pre-caching (~50-100 pieces, 1-2MB compressed)
- [ ] Post-install script to extract pre-cache to standard mirror location
- [ ] Package manager integration (Debian, Arch, Homebrew post-install hooks)
- [ ] CLI command `16c random-1` - Display one random artwork and exit
- [ ] CLI command `16c random` - Continuously stream random artwork
- [ ] CLI command `16c screensaver` - Fullscreen mode with exit-on-input
- [ ] Random artwork selection from mirror (includes pre-cached)
- [ ] Helpful error message when no artwork available
- [ ] Fullscreen terminal mode (screensaver only)
- [ ] Exit on keyboard input (screensaver only)
- [ ] Basic ANSI rendering (via ansilust)
- [ ] Terminal size detection

### Phase 2: Bootstrap and Background Sync
- [ ] Optional bootstrap prompt when mirror is empty
- [ ] Background spawning of `16c download <packs>` (reuses download spec)
- [ ] List of curated pack names for bootstrap
- [ ] Periodic `.index.db` refresh to pick up new downloads
- [ ] Offline detection and graceful handling
- [ ] Progress indication (subtle, non-intrusive)

### Phase 3: Configuration and Filtering
- [ ] TOML config file support (~/.config/16c/config.toml)
- [ ] Year/group/artist filtering
- [ ] Streaming speed configuration
- [ ] Metadata overlay toggle
- [ ] Artwork list caching
- [ ] Mirror discovery and preference

### Phase 4: Systemd Integration
- [ ] Systemd user service documentation and templates
- [ ] Hypridle integration docs
- [ ] Fullscreen window rules (Hyprland/Sway)
- [ ] DPMS awareness
- [ ] Multi-monitor support examples

### Phase 5: Advanced Features
- [ ] Multiple render modes (fit/fill/native)
- [ ] Full mirror background sync (after bootstrap)
- [ ] Transition effects between artworks
- [ ] Playlist support (curated sequences)
- [ ] Statistics tracking (most displayed artwork)
- [ ] Download progress UI (optional, configurable)

## Dependencies

### Spec Dependencies
- **.specs/download/** - All mirror and download functionality:
  - `.index.db` database and queries
  - `16c download <pack>` command
  - `16c mirror` commands
  - `16c db` commands
  - Mirror location discovery
  - SAUCE metadata extraction

### External Dependencies
- **Ansilust renderer**: ANSI rendering with streaming support
- **Terminal emulator**: Alacritty, Ghostty (for fullscreen mode)
- **systemd**: User service management (optional, Linux only)
- **Idle detector**: hypridle, swayidle (optional, for auto-activation)

## Security Considerations

- **Input validation**: Sanitize paths from `.index.db` queries and config values
- **Resource limits**: Prevent excessive memory usage from large artwork
- **Signal safety**: Proper signal handler cleanup
- **File permissions**: Config file should be user-readable only
- **Network isolation**: Random/screensaver commands only read local mirror (bootstrap is optional, separate background process)

## Future Enhancements

### Advanced Rendering
- **Shader effects**: CRT scan lines, phosphor glow
- **Color cycling**: Animate palette shifts (classic BBS trick)
- **Music integration**: Play SID/MOD files from packs

### Community Features
- **Voting**: Mark favorite artwork during display
- **Statistics**: Track most viewed/favorite pieces
- **Sharing**: Generate social media posts of artwork

### Multi-Monitor
- **Span mode**: Single artwork across multiple displays
- **Independent mode**: Different artwork per monitor
- **Sync mode**: Synchronized transitions

---

**Status**: Specification Phase  
**Priority**: Medium (showcase feature)  
**Dependencies**: 16colors mirror (.specs/download/), ansilust rendering  
**Target Audience**: Linux/Hyprland users, BBS art enthusiasts, retro computing fans

### FR1.9: Pre-cached Artwork (Package Integration)
FR1.9.1: The installation package shall include a curated selection of artwork for pre-caching.  
FR1.9.2: The pre-cached artwork shall represent high-quality pieces across different eras and styles.  
FR1.9.3: The pre-cached artwork shall be hand-picked favorites suitable for first impression.  
FR1.9.4: WHEN the package is installed a post-install script shall populate the local mirror with pre-cached artwork.  
FR1.9.5: The pre-cached artwork shall be placed in the standard mirror location (`~/Pictures/16colors/packs/` or `~/.local/share/16colors/packs/`).  
FR1.9.6: The pre-cached artwork shall be sufficient for indefinite offline usage.  
FR1.9.7: WHEN pre-cache completes the post-install script shall update `.index.db` with pre-cached artwork metadata.

### FR1.10: Background Bootstrap (Optional)
FR1.10.1: WHERE mirror is empty the system may offer to download curated favorites.  
FR1.10.2: WHEN bootstrap is accepted the system shall spawn `16c download <packs>` in background.  
FR1.10.3: The background download shall not block artwork display.  
FR1.10.4: WHEN downloads complete `.index.db` updates automatically (download spec handles this).  
FR1.10.5: The newly available artwork shall appear in rotation on next random selection.  
FR1.10.6: IF download fails the system shall continue with available artwork.

### Pre-cached Artwork (Post-Install)

**Purpose**: Ship curated favorites with package for instant first-run experience.

**Approach**:
```bash
# Post-install script (simplified)
MIRROR_BASE=$(16c mirror path)  # Reuses download spec
tar -xf /usr/share/ansilust/precache/favorites.tar.zst -C "$MIRROR_BASE/packs"
16c db rebuild  # Reuses download spec database
```

**Curated Selection** (~50-100 pieces, 1-2MB compressed):
- High-quality classics: ACiD, iCE, Blocktronics, Mistigris
- Diverse eras: 1990s and modern (2010s-2020s)
- Safe content: No NSFW
- Standard structure: `packs/YYYY/packname/` (matches download spec)

**Note**: All details about mirror structure, database updates, and SAUCE extraction are in `.specs/download/`. Post-install just extracts artwork and calls `16c db rebuild`.

### Background Bootstrap (Optional)

**Purpose**: Download more artwork in background if mirror is empty.

**Approach**:
```
IF mirror empty:
    Show helpful error
    Offer: "Download favorites? (y/n)"
    IF yes:
        Spawn background: 16c download pack1 pack2 pack3
        Continue displaying current artwork
        .index.db updates automatically (download spec)
        New artwork appears in next random selection
```

**Pack List** (hardcoded): mist1025, bloc0524, fire-96, impure90

**Note**: All download functionality delegated to `.specs/download/`. Bootstrap just spawns `16c download` commands.

### Random Selection

**Algorithm**:
```
1. Query .index.db for all artwork (download spec provides database)
2. Apply config filters (year, group, artist)
3. SELECT random entry
4. Return file path
5. Render via ansilust
```

**Note**: `.index.db` schema and queries defined in `.specs/download/`.

## Scope Clarification

### NEW in This Spec
- `16c random`, `16c random-1`, `16c screensaver` commands
- Random selection algorithm (queries `.index.db`)
- Pre-cache post-install script and curated pack selection
- Fullscreen mode (alternate screen, cursor hiding, exit-on-input)
- Config keys: `artwork_duration`, `streaming_speed`, `show_metadata`
- Systemd/hypridle integration docs

### REUSED from .specs/download/
- `.index.db` database (schema, queries, auto-updates)
- `16c download`, `16c mirror`, `16c db` commands
- Mirror structure and platform paths
- SAUCE extraction and metadata indexing
- All network/download functionality

