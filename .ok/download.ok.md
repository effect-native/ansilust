# Download OK

This file governs ansilust's current download and archive-surface reality. It translates `.specs/download/` into binary constitutional truth so reconciliation stays anchored to checked-in behavior and tests rather than aspirational client and mirror plans.

## Governing References

- `.specs/download/instructions.md`
- `.specs/download/requirements.md`
- `.specs/download/design.md`
- `.specs/download/plan.md`
- `build.zig`
- `src/cli/sixteenc.zig`
- `src/download/lib.zig`
- `src/download/commands/random.zig`
- `src/download/database/interface.zig`
- `src/download/database/hardcoded.zig`
- `src/download/protocols/http.zig`
- `src/download/storage/paths.zig`
- `src/download/storage/files.zig`
- `src/download/database/interface_test.zig`
- `src/download/protocols/http_test.zig`
- `src/download/storage/paths_test.zig`
- `src/download/storage/files_test.zig`

## Ideal End State

- TRUE: The current shipped download surface is an MVP centered on the standalone `16c` executable and its `random-1` command.
- TRUE: The current `16c` CLI contract includes only `random-1`, `--help`/`-h`, and `--version`/`-v`.
- TRUE: Current random artwork selection is backed by the `download` module's archive-database abstraction with a hardcoded implementation.
- TRUE: The only evidenced remote artwork source today is the single hardcoded `mist1025/CXC-STICK.ASC` entry in `src/download/database/hardcoded.zig`.
- TRUE: Current network download reality is HTTP-only behavior routed through `HttpClient.download`, which shells out to `curl` via `sh -c` instead of a native multi-protocol client.
- TRUE: Current storage reality resolves a platform-specific `16colors` root plus `random/`, `packs/`, and `local/` subdirectories, but the shipped command writes only the `random/` cache.
- TRUE: Current post-download display behavior for `16c random-1` is subprocess-based file output via `cat`; renderer integration is not current download-surface truth.
- TRUE: Current checked-in download tests cover interface shape and path construction more than end-to-end archive behavior; compile-time/API evidence is the present validation floor.
- TRUE: `.specs/download/**` may describe future SQLite, mirror, search, archive-browsing, alias, and protocol work, but only assertions promoted here are constitutional truth for download reconciliation.

## States We Do Not Want

- FALSE: Dual-CLI behavior from spec prose, including `ansilust --16colors`, is treated as shipped download reality without matching checked-in evidence.
- FALSE: `16colors` and `16` aliases are treated as active guarantees while `build.zig` installs only the `16c` executable.
- FALSE: SQLite `.index.db`, FTS5 archive search, auto-updating metadata, patch downloads, or canonical `ansilust.com/16colors/` hosting are treated as present-tense obligations without implemented evidence.
- FALSE: FTP, RSYNC, protocol fallback, resumable downloads, ZIP extraction, mirror sync, pack listing, pack download by name, local-art management, or stats commands are treated as shipped behavior because they appear in `.specs/download/**`.
- FALSE: `packs/` or `local/` directory creation is mistaken for completed pack-management or user-content-management features.
- FALSE: Plan checklist progress or comments about future renderer integration override the actual behavior in checked-in code and tests.

## Required Governance Rules

- TRUE: Changes to the `16c` command surface, download backend, hardcoded archive source set, storage layout, or display handoff require updating this file in the same reconciliation loop.
- TRUE: Download completion claims must be backed by checked-in code, tests, or build wiring; spec intent and plan prose are not sufficient evidence.
- TRUE: Downstream orchestration may rely only on download/archive guarantees declared TRUE here.
- TRUE: Expanding download scope remains binary: a capability is either promoted here as current truth or it is still future, partial, or unevidenced.
