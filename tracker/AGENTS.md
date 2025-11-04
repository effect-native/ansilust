# Tracker Directory - Agent Guidelines

**Purpose**: Single source of truth for atomic, ephemeral work items (gaps, tasks, bugs, technical debt).

## Directory Structure

```
tracker/
├── AGENTS.md          # This file - workflow and conventions
├── README.md          # Schema documentation and query examples
├── index.md           # Current open tasks by status/priority
└── tasks/             # One .md file per task
    ├── GAP-PARS-001.md
    ├── GAP-IR-001.md
    └── ...
```

## When to Use Tracker

**Use tracker/ for**:
- Missing features identified from gap analysis
- Bugs and defects in existing code
- Technical debt and refactoring needs
- Non-functional requirements (performance, docs, safety)
- Active work-in-progress tasks

**Don't use tracker/ for**:
- Long-term product vision (use `.specs/`)
- Completed work (archive or delete task files)
- General notes or research (use reference/ or TODO.md)

## Task Lifecycle

### 1. Creating Tasks

When you identify a gap or new work item:

```bash
# Create tasks/<ID>.md with YAML frontmatter
# ID format: <TYPE>-<AREA>-<NNN>
# Types: GAP (feature gap), BUG (defect), NFR (non-functional), DEBT (refactor)
# Areas: IR, PARS, REND, DL, DB, CLI, SAUCE, QA, DOCS
```

**Required fields**:
- `id`, `title`, `area`, `status`, `priority`
- `spec_ref` (array of paths into `.specs/**`)
- `code_refs` (array of `src/**` paths)
- `acceptance` (verifiable completion criteria)

**Example**:
```yaml
---
id: GAP-PARS-001
title: Binary parser (160x25, attr byte)
area: parsers
status: pending
priority: high
spec_ref:
  - .specs/ir/TEST_CASE_MAPPING.md#part-3
code_refs:
  - src/parsers/lib.zig
acceptance:
  - All tests in binary_test.zig pass
  - 160-col format parsing verified
blocked_by: []
labels: [classic, BBS]
created: 2025-11-03
---
```

### 2. Working on Tasks

**Pick task from `index.md`**:
1. Choose highest priority task matching your area
2. Update `status: in_progress` in task file
3. Only ONE task in_progress at a time

**During work**:
- Reference task ID in commit messages: `GAP-PARS-001(red): add binary parser tests`
- Update task notes/acceptance as you learn more
- Link to related issues/PRs if applicable

**Follow RED-GREEN-REFACTOR**:
- RED: Add failing tests, commit with `(red)` suffix
- GREEN: Make tests pass, commit with `(green)` suffix
- REFACTOR: Clean up, commit with `(refactor)` suffix

### 3. Completing Tasks

**Mark done**:
1. Verify all acceptance criteria met
2. Update `status: done` in task file
3. Update `tracker/index.md` status summary
4. Optional: Move to `tracker/archive/` or delete

**If blocked**:
1. Update `status: blocked`
2. Add `blocked_by: [GAP-IR-001, ...]`
3. Pick different task

### 4. Updating Index

After status changes, update `tracker/index.md`:
- Add/remove tasks from priority tables
- Update status summary counts
- Keep "Next Steps" section current

## Relationship to .specs/ and plan.md

**Critical principle**: `.specs/` is permanent product truth; `tracker/` is ephemeral work tracking.

**Specs survive code loss**:
- `.specs/**/*.md` contains enough detail to reimplement from scratch
- Specs are long-term, stable, version-controlled
- Specs define WHAT and WHY

**Tracker is disposable**:
- `tracker/tasks/*.md` tracks HOW and WHEN
- Tasks reference specs via `spec_ref` field
- Once work is done, tasks can be archived/deleted
- Tracker is short-term, dynamic, frequently changing

### Plan.md ↔ Tracker Contract

**plan.md defines work packages (WP)**:
- Each plan work package gets a stable anchor: `WP-<AREA>-<NNN>`
- Includes brief intent + acceptance at spec level
- Example: `[WP-PARS-001] Binary parser: implement 160x25, attr byte`
- Lists linked tasks: `Tasks: GAP-PARS-001, GAP-PARS-005`

**Tracker owns executable status**:
- For every WP, create one or more `tracker/tasks/*.md`
- Each task includes `spec_ref: [.specs/<domain>/plan.md#wp-pars-001]`
- Tasks carry granular acceptance criteria
- Tracker is single source of truth for status (pending/in_progress/done)

**Status ownership**:
- `plan.md` does NOT mirror per-task state
- Only update phase/milestone checkboxes in plan when ALL linked tasks complete
- Never duplicate task status in plan.md; link to tracker instead

**Example flow**:
1. Plan defines WP: `.specs/ir/plan.md#wp-pars-001` (Binary parser)
2. Create task: `GAP-PARS-001.md` with `spec_ref: [.specs/ir/plan.md#wp-pars-001, .specs/ir/TEST_CASE_MAPPING.md#part-3]`
3. Work completes, task marked done, plan WP checkbox checked
4. Task archived/deleted; plan WP remains as milestone record

## Querying Tasks

```bash
# All pending tasks
rg '^status: pending' tracker/tasks/

# High priority parsers
rg '^area: parsers' tracker/tasks/ -A1 | rg 'priority: high'

# Tasks blocked by GAP-IR-001
rg 'blocked_by:.*GAP-IR-001' tracker/tasks/

# All tasks with specific label
rg 'labels:.*\bBBS\b' tracker/tasks/

# Count by status
rg '^status: ' tracker/tasks/ --no-filename | sort | uniq -c
```

## ID Conventions

**Format**: `<TYPE>-<AREA>-<NNN>`

**Types**:
- `GAP`: Feature gap (missing parser, renderer, capability)
- `BUG`: Defect in existing code
- `NFR`: Non-functional requirement (perf, docs, safety)
- `DEBT`: Technical debt / refactoring
- `FEAT`: Future feature (low priority, showcase)

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
- `TUI`: Terminal user interface

**Numbering**: Zero-padded 3-digit sequence per area (001, 002, ...)

**IDs are immutable**: Once assigned, never reuse until archived

## Commit Message Convention

Reference task IDs in commit messages:

```
GAP-PARS-001(red): add binary parser tests
GAP-PARS-001(green): implement binary parser
GAP-PARS-001(refactor): extract attribute parsing helper
NFR-QA-001: justify unreachable in cell grid iterator
```

## Common Workflows

### Gap Analysis → Tasks

After identifying gaps (e.g., from comparing .specs to src):

1. Create task file per gap
2. Prioritize (high/med/low)
3. Identify blocking dependencies
4. Update `index.md`
5. Pick highest priority unblocked task

### Bug Report → Task

1. Create `BUG-<AREA>-<NNN>.md`
2. Include reproduction steps in notes
3. Link to spec if behavior violates requirement
4. Add acceptance: "Bug no longer reproduces"

### Refactoring → Task

1. Create `DEBT-<AREA>-<NNN>.md`
2. Explain technical debt in notes
3. Reference code smells or violations
4. Add acceptance: "Code meets quality standard"

## Maintenance

**Weekly**:
- Archive or delete completed tasks
- Update `index.md` priorities
- Check for stale in_progress tasks

**After major milestones**:
- Review pending tasks for relevance
- Update blocked_by dependencies
- Reprioritize based on project phase

**Keep tracker/ lean**:
- Don't let pending tasks accumulate indefinitely
- If task sits >1 month without progress, consider:
  - Lower priority
  - Mark wont_do
  - Break into smaller tasks
  - Merge with related tasks

## Integration with TODO.md

**TODO.md** (root):
- Historical context
- Long-term vision
- Completed work log
- Points to `tracker/` for active tasks

**tracker/** (this directory):
- Active work only
- Atomic, actionable tasks
- Current priorities
- Single source of truth

Users should check `tracker/index.md` first for "what to work on next."
