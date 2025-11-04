---
id: FEAT-SCREEN-001
title: Ansilust screensaver for Omarchy Linux
area: cli
status: pending
priority: low
spec_ref:
  - .specs/screensaver/instructions.md
  - rfcs/inbox/screensaver.md
code_refs: []
acceptance:
  - XScreenSaver/systemd integration
  - Random art display from 16colo.rs archive
  - Configurable transition effects (fade, scroll, instant)
  - Dismiss on keyboard/mouse activity
  - Local cache with offline mode
  - Configuration via GUI or file
  - Low CPU/memory footprint
blocked_by:
  - GAP-DL-001
  - GAP-DB-001
labels:
  - screensaver
  - showcase
  - omarchy
  - future
created: 2025-11-03
---

## Context

From `.specs/screensaver/instructions.md` and `rfcs/inbox/screensaver.md`:

Create a screensaver for Omarchy Linux that continuously scrolls through classic ANSI art from the 16colo.rs archive, bringing retro computing aesthetics to modern Linux systems.

## Core Features

1. **Art display**: Continuously cycle through ANSI art from archive
2. **Screensaver behavior**: Activate on idle, dismiss on activity
3. **Art selection**: Random or filtered (year, group, artist, format)
4. **Display options**: Transition effects, timing, metadata overlay
5. **Caching**: Local storage with background sync

## Technical Integration

**Omarchy Linux**:
- XScreenSaver module compatibility
- Wayland/X11 support
- systemd idle detection
- Standard Linux screensaver settings

**Architecture**:
- Idle detector (system monitoring)
- Art loader (16colo.rs API client)
- Display manager (fullscreen rendering)
- Transition engine (fade, scroll, reveal)
- Config system (user preferences)

**Data management**:
- Local cache of downloaded artpacks
- Background sync with 16colo.rs
- Offline mode (cached art only)
- SQLite for metadata/favorites

## Implementation Phases

1. **Basic screensaver**: XScreenSaver/systemd integration, random art, basic transitions, config file
2. **Art management**: API integration, local caching, offline mode, filtering
3. **Enhanced display**: Advanced transitions, metadata overlay, multiple backends, optimization
4. **User customization**: Favorites/playlists, theme integration, GUI config, statistics

## Dependencies

- GAP-DL-001 (HTTP client for downloads)
- GAP-DB-001 (SQLite .index.db for metadata)
- Ansilust rendering engine (available)
- Omarchy Linux packaging

## Notes

- Full spec available at `.specs/screensaver/instructions.md`
- Blocked until download infrastructure complete
- Showcase project for ansilust capabilities
- Preserves BBS art for modern Linux users
