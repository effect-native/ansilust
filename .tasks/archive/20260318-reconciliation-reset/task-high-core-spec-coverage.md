---
id: task-high-core-spec-coverage
level: high
status: done
blocked_by: []
expires_at: 2026-03-25T12:46:37-04:00
---

# Core Spec Coverage

Author the remaining constitutions for the core engine spec areas so `.specs/ir/` and `.specs/render-utf8ansi/` are governed by `.ok` files.

## Evidence

- `.tasks/task-med-author-ir-constitution.md`, `.tasks/task-low-derive-ir-ok-assertions-from-specs.md`, and `.tasks/task-low-link-ir-ok-to-live-evidence.md` are all `status: done`, showing the IR slice was authored, tightened into binary assertions, and anchored to checked-in evidence.
- `.tasks/task-med-author-render-utf8ansi-constitution.md`, `.tasks/task-low-derive-render-utf8ansi-ok-assertions.md`, and `.tasks/task-low-link-render-ok-to-live-evidence.md` are all `status: done`, showing the UTF8ANSI render slice was authored, tightened into binary assertions, and anchored to checked-in evidence.
- `.ok/project-management.ok.md` now lists both `.specs/ir/ -> .ok/ir.ok.md` and `.specs/render-utf8ansi/ -> .ok/render-utf8ansi.ok.md` under covered spec areas, satisfying the high-level requirement that the core engine spec areas are governed by `.ok` files.
- `.ok/ir.ok.md` and `.ok/render-utf8ansi.ok.md` both explicitly name their governing `.specs/**` references and distinguish live checked-in evidence from future or unevidenced scope, so the core-spec coverage slice is complete.
