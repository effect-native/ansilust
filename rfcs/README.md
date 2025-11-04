# RFCs - Request for Comments

**Purpose**: Capture, evaluate, and decide on proposals before they become committed specs.

## Directory Structure

```
rfcs/
├── README.md           # This file - process and conventions
├── TEMPLATE.md         # RFC template
├── inbox/              # Untriaged ideas (rough notes)
└── RFC-NNN.md          # Accepted proposals (numbered)
```

## Workflow

### 1. Capture Ideas

Drop raw ideas into `inbox/<slug>.md`:
- No format required, just capture the thought
- Problem statement + why now + rough scope
- Any constraints or risks you can think of

### 2. Weekly Triage

Review `inbox/` weekly:
- **Accept**: Promote to `RFC-NNN.md` using template
- **Close**: Archive or delete if not viable
- **Defer**: Leave in inbox with note

### 3. RFC Development

For accepted proposals:
- Copy `TEMPLATE.md` → `RFC-NNN.md`
- Fill in context, options, decision criteria
- Discuss with team/community if applicable
- Document decision and rationale

### 4. Implementation

When RFC is accepted:
- Create/update `.specs/<domain>/` with requirements
- Seed tasks in `tracker/` with `spec_ref: [rfcs/RFC-NNN.md]`
- Link RFC in `.specs/<domain>/decisions.md`
- Close RFC or mark "Implemented"

## RFC States

- **Draft**: In development, seeking feedback
- **Proposed**: Ready for decision
- **Accepted**: Approved, ready for implementation
- **Rejected**: Not proceeding, rationale documented
- **Implemented**: Completed and merged
- **Superseded**: Replaced by newer RFC

## RFC Numbering

- Sequential: RFC-001, RFC-002, etc.
- No reuse of numbers
- Gaps are okay (rejected RFCs still count)

## What Goes in an RFC

**DO write RFCs for**:
- New features or major changes
- Architectural decisions
- Breaking changes
- Cross-cutting concerns
- Design trade-offs requiring discussion

**DON'T write RFCs for**:
- Bug fixes (use BUG-* tasks)
- Minor refactoring (use DEBT-* tasks)
- Documentation updates (just do it)
- Obvious improvements (just implement)

## RFC Template Fields

See `TEMPLATE.md` for full structure. Key sections:
- **Context**: Problem and background
- **Options**: Alternatives considered
- **Decision Criteria**: How to evaluate
- **Recommendation**: Preferred approach
- **Impact**: Consequences and trade-offs
- **Implementation**: High-level plan

## Integration with Specs and Tracker

**RFC → Spec**:
- Accepted RFC becomes basis for `.specs/<domain>/requirements.md`
- Link RFC in spec frontmatter or decisions.md
- Spec formalizes with EARS notation

**RFC → Tasks**:
- Seed `tracker/tasks/` with `spec_ref: [rfcs/RFC-NNN.md]`
- Tasks execute the implementation
- Close RFC when implementation complete

## Examples

**Good RFC topics**:
- "RFC-001: Binary parser architecture"
- "RFC-002: SQLite vs custom database format"
- "RFC-003: Zig/TypeScript hybrid build system"
- "RFC-004: iCE colors rendering strategy"

**Bad RFC topics** (just do it):
- "RFC-XXX: Fix typo in docs"
- "RFC-XXX: Add test for edge case"
- "RFC-XXX: Rename variable for clarity"

## Cadence

- **Weekly**: Triage inbox
- **As needed**: Review/discuss active RFCs
- **On acceptance**: Create specs and tasks
- **On completion**: Mark implemented and archive

## Archive

Completed RFCs can be moved to `rfcs/archive/` to keep root clean, or left in place with "Implemented" status.
