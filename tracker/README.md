# Task Tracker Archive

`tracker/` is a legacy archive. It is preserved so older task references still make sense, but it is not part of the active operating workflow.

## Current Authority

- `.ok/project-management.ok.md` holds project-management authority.
- `.tasks/` holds live execution state.
- `tracker/` should not be used to create, update, complete, or query current tasks.

## Archived Layout

```
tracker/
├── README.md          # Archive overview
├── AGENTS.md          # Archive handling notes
├── index.md           # Historical snapshot of legacy task status
└── tasks/             # Archived legacy task files
```

## Historical Schema Reference

Legacy `tracker/tasks/*.md` files typically used YAML frontmatter plus optional notes.

- Common fields included `id`, `title`, `area`, `status`, `priority`, `spec_ref`, `code_refs`, and `acceptance`.
- Optional fields often included `blocked_by`, `labels`, `owner`, `created`, `updated`, and freeform notes.
- Those field definitions are kept only to help read archived files.

## How To Read This Directory

- Treat all statuses, priorities, and summaries here as stale historical data.
- Use it to interpret old links, references, and commit messages.
- Migrate any still-relevant ideas into DotOK-managed files instead of extending this archive.

## Relationship To Other Directories

- `.specs/**`: long-term product truth.
- `.ok/project-management.ok.md`: current project-management authority.
- `.tasks/`: current task execution state.
- `tracker/`: historical tracker material retained for context only.
