---
id: task-low-author-omarchy-systemd-and-packaging-boundary
level: low
status: done
blocked_by: []
expires_at: 2026-03-27T00:18:37Z
---

# Author Omarchy Systemd And Packaging Boundary

Document the MVP Omarchy and systemd launch surface, separate X11 or XScreenSaver follow-on work, and fence packaging promises to what the repo can actually support.

## Evidence

- Updated `.specs/screensaver/plan.md` to define the MVP launch boundary around ansilust-owned command surfaces plus future in-repo Omarchy-adjacent `systemd --user` or idle-manager examples.
- Split X11/XScreenSaver and broader cross-desktop integration into post-MVP follow-on work under the growth package.
- Aligned packaging language with `.ok/deployments.ok.md` so the screensaver plan does not promise unsupported channels or artifacts.
