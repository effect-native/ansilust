---
id: task-low-create-root-website-directory-and-build-scaffold
level: low
status: done
blocked_by: []
expires_at: 2026-04-15T19:41:46Z
---

# Create Root Website Directory And Build Scaffold

Add the first checked-in `website/` implementation scaffold so the website surface exists in repo reality.

## Red-Phase Acceptance Contract

- The repo shall contain a checked-in root `website/` directory.
- The root `package.json` workspace list shall include `website` so the scaffold is part of the monorepo surface.
- `website/package.json` shall exist and declare the minimum build scaffold contract: private app package, Bun package manager, and executable `dev` and `build` scripts.
- `website/package.json` shall declare React and Tailwind CSS so the future website stack has checked-in build evidence before route work begins.

## Failure Evidence

- Added executable spec check `scripts/website-root-scaffold.test.mjs` and root script `npm run test:website-scaffold`.
- Confirmed the new red test fails against current repository reality because `./website` does not exist.
- This failure is assertion-driven and isolates the highest-signal gap for the atomic scaffold task without implementing the scaffold.

## Green-Phase Completion Evidence

- Added the checked-in root `website/` directory by creating `website/package.json` as the minimal scaffold contract.
- Updated the root `package.json` workspace list to include `website` while preserving the existing `packages/*` workspace.
- Verified `npm run test:website-scaffold` passes once the scaffold exists with Bun, `dev`/`build`, React, and Tailwind CSS declared.
