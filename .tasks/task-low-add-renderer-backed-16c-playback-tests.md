---
id: task-low-add-renderer-backed-16c-playback-tests
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Add Renderer Backed 16c Playback Tests

Add tests that prove `16c` playback uses the renderer path and preserves the expected terminal-control behavior.

## Red-phase completion

- Added `src/cli/sixteenc.zig` coverage that asserts the `16c` help surface exposes `random` instead of the current `random-1` command.
- Added `src/download/commands/random_test.zig` coverage that asserts playback no longer shells out via raw `cat` and instead wires parser + `renderToUtf8Ansi` + TTY-aware behavior.
- Wired `build.zig` and `src/download/lib.zig` so the 16c CLI and download-module tests are exercised by the test graph.

## Failure evidence

- `zig test --dep download -Mroot=src/cli/sixteenc.zig -Mdownload=src/download/lib.zig --test-filter "random command surface"`
  - Fails in `src/cli/sixteenc.zig:83` because help output still contains `random-1`.
- `zig test src/download/lib.zig --test-filter "16c playback"`
  - Fails in `src/download/commands/random_test.zig:7` because `src/download/commands/random.zig` still shells out to `"cat"`.
  - Fails in `src/download/commands/random_test.zig:13` because `src/download/commands/random.zig` does not yet reference parser/renderer/TTY playback wiring.
