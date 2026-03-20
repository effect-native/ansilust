---
id: task-low-rewrite-download-ok-for-current-random-runtime
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Rewrite Download OK For Current Random Runtime

Update `.ok/download.ok.md` so its present-tense claims match `src/cli/sixteenc.zig`, `src/download/lib.zig`, and `src/download/commands/random.zig` as they exist now.

Targets: `.ok/download.ok.md`
Validation: `zig build`

## Evidence

- `src/cli/sixteenc.zig` dispatches both `random` and `random-1`, and its checked-in help text plus help test promote `16c random` as the public example while omitting `random-1` from help output.
- `src/download/lib.zig` publicly exports `database`, `commands.random`, `RandomPlaybackLoop`, `protocols.http`, `storage.paths`, and `storage.files`.
- `src/download/commands/random.zig` routes display through `ansilust.parsers.ansi.parse` and `ansilust.renderToUtf8Ansi`; `src/download/commands/random_test.zig` asserts playback no longer shells out through raw `cat`.
- Validation: `zig build` passed.
