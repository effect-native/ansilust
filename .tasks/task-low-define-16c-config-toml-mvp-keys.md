---
id: task-low-define-16c-config-toml-mvp-keys
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Define 16c Config Toml MVP Keys

Define the minimum `~/.config/16c/config.toml` keys and defaults required for the first usable screensaver release.

## Evidence

- Updated `.specs/screensaver/design.md` to define the MVP `config.toml` key set as `playback.dwell_seconds = 20` and `source.mode = "auto"`.
- Documented why the MVP omits render-mode, overlay, filter, and session-lifecycle toggles to stay aligned with current Stage 1 boundaries.
