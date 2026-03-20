---
id: task-low-route-random-display-through-ansilust-renderer
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Route Random Display Through Ansilust Renderer

Replace the `cat` subprocess display path with ansilust renderer-backed playback suitable for looping screensaver use.

Evidence: `displayArtwork` now reads the saved file, parses via `ansilust.parsers.ansi.parse`, renders with `renderToUtf8Ansi`, and writes renderer output to stdout using `isatty` mode detection.
