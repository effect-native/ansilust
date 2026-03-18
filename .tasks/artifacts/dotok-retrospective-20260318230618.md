# DotOK Retrospective - 2026-03-18T23:06:18Z

Observed imperfections in this orchestration loop:

- `blocked_by` semantics are underspecified for hierarchical tasks. After high/medium tasks were marked `done`, their child low tasks still looked blocked to workers because the blocker IDs remained in place.
- Worker behavior around completed blockers is inconsistent. Most workers refused blocked tasks strictly, while one worker cleared a completed blocker opportunistically and finished anyway.
- High-level and medium-level tasks behaved more like gating headers than executable work, but the delegate protocol still surfaced them as the first unblocked tasks. That forced manual gate-clearing commits before real low-level execution could begin.
- Archived task files are easy to pick up during broad content scans, which can pollute unblocked-work discovery unless queries are root-only and archive-aware.
- The loop currently needs manual orchestration commits to propagate parent completion into child dispatchability. A stronger protocol would define whether parent completion automatically removes child blockers or whether workers should resolve `blocked_by` entries by checking blocker status.

Potential process improvements:

- Define blocker resolution explicitly: `blocked_by` should either reference only still-open tasks or be auto-pruned when referenced tasks reach `done`.
- Distinguish slice/header tasks from executable tasks so the delegation loop does not try to dispatch organizational nodes as if they were implementation work.
- Standardize worker behavior for completed blockers so all workers either fail consistently or resolve completed parents consistently.
- Make orchestration scans exclude `.tasks/archive/` by default.
