# Task Tracker

Legacy tracker reference only. Project-management authority lives in `.ok/project-management.ok.md`, and active execution state lives in `.tasks/`.

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

## Status

- Do not use `tracker/` as the live execution queue.
- Do not pick work from `tracker/index.md`.
- Keep this directory only as historical context until its contents are archived or migrated.

## Relationship to .specs/

- `.specs/**`: Long-term product truth; stable, version-controlled specification
- `.ok/project-management.ok.md`: Project-management authority
- `.tasks/`: Active ephemeral work tracking and execution state
- `tracker/`: Legacy historical reference; not authoritative for execution
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

- Prefer migrating or archiving tracker content instead of extending it.
- IDs are immutable; reuse only after archival.
