# Task Index

**Last Updated**: 2025-11-03

## Open Tasks by Priority

### High Priority

| ID | Title | Area | Status |
|----|-------|------|--------|
| [GAP-PARS-001](tasks/GAP-PARS-001.md) | Binary parser (160x25, attr byte) | parsers | pending |
| [GAP-PARS-005](tasks/GAP-PARS-005.md) | ANSI SGR completeness (italic, faint, underline styles) | parsers | pending |
| [GAP-IR-001](tasks/GAP-IR-001.md) | Wide/CJK/combining grapheme handling | ir | pending |
| [GAP-DL-001](tasks/GAP-DL-001.md) | HTTP client with std.http | download | pending |
| [GAP-DB-001](tasks/GAP-DB-001.md) | SQLite .index.db with FTS5 | db | pending |

### Medium Priority

| ID | Title | Area | Status |
|----|-------|------|--------|
| [GAP-IR-002](tasks/GAP-IR-002.md) | OpenTUI bridge tests | ir | pending |
| [GAP-REND-002](tasks/GAP-REND-002.md) | iCE colors in renderer | renderers | pending |
| [NFR-QA-001](tasks/NFR-QA-001.md) | Eliminate catch unreachable | qa | pending |

### Low Priority

| ID | Title | Area | Status |
|----|-------|------|--------|
| [FEAT-TUI-001](tasks/FEAT-TUI-001.md) | 16colo.rs TUI - BBS-style artpack viewer | cli | pending |
| [FEAT-SCREEN-001](tasks/FEAT-SCREEN-001.md) | Ansilust screensaver for Omarchy Linux | cli | pending |
| [FEAT-KIOSK-001](tasks/FEAT-KIOSK-001.md) | Bootable kiosk ISO distribution | cli | pending |

## Status Summary

- **Pending**: 11
- **In Progress**: 0
- **Blocked**: 0
- **Done**: 0

## Areas

- **Parsers**: 2 tasks (GAP-PARS-001, GAP-PARS-005)
- **IR**: 2 tasks (GAP-IR-001, GAP-IR-002)
- **Renderers**: 1 task (GAP-REND-002)
- **Download**: 1 task (GAP-DL-001)
- **Database**: 1 task (GAP-DB-001)
- **QA**: 1 task (NFR-QA-001)
- **CLI/Future**: 3 tasks (FEAT-TUI-001, FEAT-SCREEN-001, FEAT-KIOSK-001)

## Quick Filters

```bash
# All parsers tasks
rg '^area: parsers' tracker/tasks/

# Blocked tasks
rg '^status: blocked' tracker/tasks/

# High priority only
rg '^priority: high' tracker/tasks/ -l
```

## Next Steps

1. Pick a high-priority task from the list above
2. Update status to `in_progress` in the task file
3. Follow RED-GREEN-REFACTOR cycle from `.specs/ir/plan.md`
4. Reference task ID in commit messages
5. Mark `done` when acceptance criteria met
