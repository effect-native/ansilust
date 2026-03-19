---
id: task-low-mark-aur-files-as-aspirational-placeholder-surface
level: low
status: done
blocked_by: []
expires_at: 2026-03-26T23:35:25Z
---

# Mark AUR Files As Aspirational Placeholder Surface

Adjust `aur/PKGBUILD` and `aur/.SRCINFO` so placeholder release metadata is clearly treated as aspirational rather than current package reality.

Completed: marked the AUR metadata as future-facing placeholder state by switching the placeholder version to `0.0.0` and updating the package description language in both files to avoid implying an active released package.
