---
id: task-low-add-red-tests-for-screensaver-cli-surface
level: low
status: done
blocked_by: []
expires_at: 2026-04-03T01:51:31Z
---

# Add Red Tests For Screensaver CLI Surface

Add failing tests that require `16c screensaver` to appear in CLI help and route through a distinct command path.

Targets: `src/cli/sixteenc.zig`, CLI test coverage
Validation: targeted failing test run

## Evidence

- Failing command: `zig test src/cli/sixteenc.zig`
- Failure reason: `16c usage and help expose screensaver command surface` fails because `writeUsage`/`writeHelp` do not mention `screensaver`; `16c includes distinct screensaver command dispatch path` fails because `src/cli/sixteenc.zig` has no `std.mem.eql(u8, command, "screensaver")` branch.
