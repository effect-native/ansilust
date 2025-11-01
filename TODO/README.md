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

### curl.md
Integration specification for seamless curl piping to ansilust. Features include:
- Single file streaming: `curl url/to/ansi.ans | ansilust`
- Artpack archive support: `curl url/to/artpack.zip | ansilust --speed 9600`
- Smart caching with hash-based deduplication
- Baud rate simulation for authentic retro BBS experience
- Automatic format detection (ANSI, ZIP, RAR, 7z)
- Cache management commands for repeated artpack viewing

### 16colors-tui-bbs-viewer.md
A BBS-style terminal user interface for browsing the 16colo.rs ANSI art archive. Features include:
- Authentic 1990s BBS experience with configurable modem speed emulation
- Fast background downloads with slow retro rendering feel
- Full artpack browsing and viewing capabilities
- Integration with ansilust rendering engine

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
