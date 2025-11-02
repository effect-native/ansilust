# TODO - Future Project Ideas

This directory contains detailed specifications and ideas for future projects and features related to ansilust.

## Purpose

The TODO folder serves as a collection of:
- **Project Ideas**: Potential applications and tools that could be built using ansilust
- **Feature Concepts**: Detailed specifications for features not yet implemented
- **Design Documents**: Technical architecture and implementation plans
- **Research Notes**: Exploration of related technologies and approaches

## Structure

Each idea is documented in its own markdown file with:
- Concept overview
- Core features and requirements
- Technical architecture
- Implementation phases
- Dependencies and prerequisites

## Current Ideas

### 16colors-tui-bbs-viewer.md
A BBS-style terminal user interface for browsing the 16colo.rs ANSI art archive. Features include:
- Authentic 1990s BBS experience with configurable modem speed emulation
- Fast background downloads with slow retro rendering feel
- Full artpack browsing and viewing capabilities
- Integration with ansilust rendering engine

### screensaver.md
An ansilust-powered screensaver for Omarchy Linux. Features include:
- Continuously scrolls through classic ANSI art from the 16colo.rs archive
- Configurable transition effects and display options
- Local caching with offline mode support
- XScreenSaver/systemd integration for Linux desktop environments

### bootable-kiosk-iso.md
A bootable operating system image that transforms any device into a dedicated ANSI art display appliance. Features include:
- Zero-configuration boot directly into art rendering mode
- Support for Raspberry Pi, Intel NUC, old laptops, and thin clients
- Multiple display modes (shuffle, playlist, slideshow, infinite scroll)
- USB/web-based configuration interface
- Network content downloads from 16colo.rs
- Read-only filesystem for reliability and power-loss protection
- Perfect for art galleries, digital signage, and home installations

## Contributing Ideas

When adding new project ideas to this folder:
1. Create a descriptive filename (e.g., `project-name.md`)
2. Include comprehensive sections: concept, features, architecture, phases
3. List dependencies and integration points with existing ansilust components
4. Specify priority and development status
5. Update this README with a brief description

## Relationship to TODO.md

The root `TODO.md` file tracks:
- Implementation status of current features
- Active development tasks
- Critical issues and bugs
- Short-term priorities

This `TODO/` directory focuses on:
- Long-term vision and future projects
- Detailed specifications for complex features
- Exploratory ideas that may or may not be implemented
- Reference documentation for potential work

Think of `TODO.md` as the sprint backlog and `TODO/` as the product roadmap.
