---
id: FEAT-TUI-001
title: 16colo.rs TUI - BBS-style artpack viewer
area: cli
status: pending
priority: low
spec_ref:
  - rfcs/inbox/16colors-tui-bbs-viewer.md
code_refs: []
acceptance:
  - Main menu with BBS-style interface
  - Browse artpacks by year/group/artist
  - Full-screen art viewer with ansilust rendering
  - Baud rate emulation (2400-56K, instant)
  - Fast background downloads with slow UI rendering
  - Configuration for connection speed
blocked_by:
  - GAP-DL-001
  - GAP-DB-001
labels:
  - showcase
  - TUI
  - BBS
  - future
created: 2025-11-03
---

## Context

From `rfcs/inbox/16colors-tui-bbs-viewer.md`:

Build a terminal-based user interface that emulates the experience of visiting an old 1990s BBS to download and view artpacks. The application should feel authentically retro while leveraging modern technology.

## Core Concept

**Dual-speed architecture**:
- **Fast layer**: Download artpacks at full modern internet speeds in background
- **Slow layer**: Emulate 2400-9600 baud modem speeds for visual rendering (character-by-character)

## Key Features

1. **BBS-style menus** with CP437 box drawing
2. **Artpack browser** (by year, group, artist, format)
3. **Baud rate emulation** (300, 1200, 2400, 9600, 14400, 28800, 56K, instant)
4. **Download simulation** (instant background + animated progress)
5. **Full-screen art viewer** with line-by-line reveal
6. **Metadata overlay** (artist, date, pack, format)

## Technical Architecture

- TUI framework: vaxis or similar
- Backend: 16colo.rs API + local cache + SQLite metadata
- Speed emulation: Character output timing based on baud rate
- Multi-threaded: UI thread + download thread
- Ansilust integration for rendering

## Implementation Phases

1. **MVP**: Basic TUI, simple art viewer, API integration, browse by year
2. **Speed emulation**: Baud rate timing, download animation, ANSI reveal
3. **Full BBS experience**: Complete menus, search, favorites, effects
4. **Polish**: Sound effects, shortcuts, preferences, statistics

## Dependencies

- GAP-DL-001 (HTTP client)
- GAP-DB-001 (SQLite .index.db)
- Ansilust rendering engine (available)

## Notes

- Blocked until download infrastructure complete
- Showcase project to demonstrate ansilust capabilities
- Target audience: ANSI art enthusiasts, BBS nostalgia seekers
- Optional sound effects (modem handshake, key clicks)
