# Task Tracker

Single source of truth for atomic, ephemeral work items (gaps, tasks, bugs).

## Layout

```
tracker/
├── README.md          # This file
├── index.md           # Current open tasks by status
└── tasks/             # One .md file per task
    ├── GAP-PARS-001.md
    ├── GAP-IR-001.md
    └── ...
```

## Task Schema

Each `tasks/<ID>.md` file contains YAML frontmatter + optional notes.

### Required Fields

- **id**: Unique identifier (e.g., `GAP-PARS-001`)
- **title**: Short description
- **area**: One of `ir`, `parsers`, `renderers`, `download`, `db`, `cli`, `sauce`, `qa`, `nfr`, `docs`
- **status**: One of `pending`, `in_progress`, `blocked`, `done`, `wont_do`
- **priority**: One of `high`, `med`, `low`
- **spec_ref**: Array of spec pointers (e.g., `.specs/ir/plan.md#phase-3`)
- **code_refs**: Array of relevant source paths
- **acceptance**: Bullet list of verifiable completion criteria

### Optional Fields

- **blocked_by**: Array of task IDs
- **labels**: Free tags
- **owner**: Who's working on it
- **created**: ISO date
- **updated**: ISO date
- **notes**: Freeform markdown below frontmatter

## ID Scheme

Format: `<TYPE>-<AREA>-<NNN>`

**Types**:
- `GAP`: Feature gap (missing parser, renderer, IR capability)
- `BUG`: Defect in existing code
- `NFR`: Non-functional requirement (perf, docs, safety)
- `DEBT`: Technical debt / refactor

**Areas**:
- `IR`: Intermediate representation
- `PARS`: Parsers
- `REND`: Renderers
- `DL`: Download/protocols
- `DB`: Database/archive
- `CLI`: Command-line interface
- `SAUCE`: SAUCE metadata
- `QA`: Testing/quality
- `DOCS`: Documentation

**Numbers**: Zero-padded 3-digit sequence per area (001, 002, ...)

## Workflow

1. **Add task**: Create `tasks/<ID>.md` with frontmatter
2. **Update status**: Edit frontmatter `status` field
3. **Reference in commits**: Include ID in commit messages (e.g., `GAP-PARS-001(red): add binary parser tests`)
4. **Archive completed**: Move to `archive/` or delete when obsolete
5. **Query**: Use `rg`, `grep`, or editors to filter by status/area/priority

## Relationship to .specs/

- `.specs/**`: Long-term product truth; stable, version-controlled specification
- `tracker/`: Ephemeral work tracking; tasks reference specs via `spec_ref`
- Specs survive code loss; tracker is disposable once work is done

## Example Task

See `tasks/GAP-PARS-001.md` for a complete example.

## Querying Tasks

```bash
# All pending tasks
rg '^status: pending' tracker/tasks/

# High priority parsers
rg '^area: parsers' tracker/tasks/ -A1 | rg 'priority: high'

# Tasks blocked by GAP-IR-001
rg 'blocked_by:.*GAP-IR-001' tracker/tasks/
```

## Maintenance

- Keep `index.md` updated as tasks transition
- Archive or delete completed tasks regularly
- IDs are immutable; reuse only after archival
