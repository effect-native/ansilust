# Deployments OK

This file governs how ansilust reaches users. It intentionally constrains deployment truth to channels with end-to-end evidence that already exist, so deployment promises do not run ahead of working reality.

## Governing References

- `.specs/publish/requirements.md`
- `.specs/publish/design.md`
- `.specs/publish/PHASE4-IMPLEMENTATION.md`
- `.github/workflows/release.yml`
- `scripts/release.sh`
- `scripts/assemble-npm-packages.js`
- `scripts/install.sh`
- `scripts/install.ps1`
- `packages/ansilust/package.json`
- `aur/PKGBUILD`
- `flake.nix`

## Ideal End State

- TRUE: A version tag matching `v*` is the only automated release trigger for production deployments.
- TRUE: GitHub Releases is the canonical source of downloadable ansilust binaries and checksum manifests.
- TRUE: The release workflow publishes only the currently supported direct-download binary targets: `darwin-arm64`, `darwin-x64`, `linux-x64-gnu`, `linux-x64-musl`, `linux-arm64-gnu`, `linux-arm64-musl`, `linux-arm-gnu`, and `linux-arm-musl`.
- TRUE: Every promised downloadable binary has a matching entry in `SHA256SUMS`.
- TRUE: The `ansilust` npm package is promised only on platforms whose platform package exists on npm at the same version and corresponds to a current GitHub release artifact.
- TRUE: The npm-supported target set matches the current shipped binary target set exactly.
- TRUE: The only currently supported npm CLI entrypoint is `ansilust`; standalone `16c` and `16colors` packages remain placeholder reservations until separately promoted with end-to-end release evidence.
- TRUE: Container deployment is promised only through the tag-driven GitHub Actions workflow that successfully builds and pushes `ghcr.io/effect-native/ansilust` for the release.
- TRUE: Shell installer promises are limited to platforms with matching release artifacts and checksum verification.
- TRUE: `.specs/publish/**` may describe future channels, but a channel becomes a deployment promise only after this file is updated to declare it TRUE.

## States We Do Not Want

- FALSE: `packages/ansilust/package.json` references unpublished, placeholder, or mismatched-version platform packages as active deployment targets.
- FALSE: Placeholder `16c` or `16colors` package folders, namespace reservations, or package pages are mistaken for a supported delivery path for `npx 16c screensaver`.
- FALSE: Windows or `linux-i386-musl` are treated as supported deployment targets before matching GitHub release artifacts and matching npm packages exist at the current version.
- FALSE: `scripts/install.ps1` is treated as a production-ready installer while the release workflow does not ship a current Windows artifact.
- FALSE: AUR or Nix are presented as production-ready deployment channels while checked-in package definitions still rely on placeholders or skipped release steps.
- FALSE: A package channel is treated as supporting fresh-machine `16c screensaver` before it both launches the real `16c` binary and ensures first-use local artwork availability through repo-owned package or install artifacts.
- FALSE: README, specs, workflow files, and package manifests disagree about which deployment channels are actually supported.
- FALSE: A deployment channel is promised just because a spec, script, or placeholder package exists.

## Required Governance Rules

- TRUE: A deployment channel is considered supported only when the repository contains the automation or package definition and the latest successful release path proves it end to end.
- TRUE: The supported platform matrix stays synchronized across release assets, npm packages, installers, and user-facing docs.
- TRUE: Placeholder packages such as `16c` and `16colors` are namespace reservations, not ansilust deployment channels.
- TRUE: A deployment channel that promises fresh-machine `16c screensaver` must prove both launcher delivery for the real `16c` surface and repo-owned first-use artwork availability for that channel.
- TRUE: First-use artwork availability for a supported package or installer channel may be satisfied by shipped starter art or by a repo-owned install artifact that materializes starter art into the local playable pool before first launch, but placeholder or external instructions do not satisfy that gate.
- TRUE: AUR, Nix, domain-hosted installers, and other secondary channels remain aspirational until they are explicitly promoted into the TRUE set above.
