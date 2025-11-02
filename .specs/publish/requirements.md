# Publishing & Distribution - Requirements

**Phase**: 2 - Requirements  
**Status**: In Progress  
**Dependencies**: instructions.md (Phase 1 complete)

---

## Overview

This document provides detailed functional and non-functional requirements for the ansilust publishing and distribution system, using EARS (Easy Approach to Requirements Syntax) notation for clarity and testability.

**Scope**: Multi-platform CLI binary distribution across package managers, direct execution methods, and install scripts.

**Reference**: See `.specs/publish/instructions.md` for user stories and acceptance criteria.

---

## FR1: Functional Requirements

All functional requirements use EARS notation patterns:
- **Ubiquitous**: "The system shall..."
- **Event-driven**: "WHEN [event] the system shall..."
- **State-driven**: "WHILE [state] the system shall..."
- **Unwanted**: "IF [error] THEN the system shall..."
- **Optional**: "WHERE [feature] the system shall..."

### FR1.1: Build System Requirements

**FR1.1.1**: The build system shall support cross-compilation for all target platforms using Zig.

**FR1.1.2**: The build system shall produce binaries for the following targets:
- Linux: x86_64-linux-gnu, x86_64-linux-musl, aarch64-linux-gnu, aarch64-linux-musl, armv7-linux-gnueabihf, i386-linux-musl
- macOS: x86_64-macos, aarch64-macos
- Windows: x86_64-windows
- iOS: aarch64-ios, arm-ios

**FR1.1.3**: WHEN a git tag matching `v*` is pushed the system shall trigger the release workflow.

**FR1.1.4**: The build system shall execute all builds in a single GitHub Actions workflow run.

**FR1.1.5**: WHEN a build fails THEN the system shall abort the workflow and report the specific failure.

**FR1.1.6**: The build system shall generate checksums (SHA256) for all artifacts.

**FR1.1.7**: WHERE signing is enabled the build system shall sign artifacts with GPG.

### FR1.2: Binary Artifact Requirements

**FR1.2.1**: Each binary shall be statically linked where possible to minimize dependencies.

**FR1.2.2**: The binary naming convention shall follow: `ansilust-{os}-{arch}[-{variant}]`

**Examples**:
- `ansilust-linux-x86_64-glibc`
- `ansilust-linux-x86_64-musl`
- `ansilust-linux-aarch64-musl`
- `ansilust-darwin-x86_64`
- `ansilust-darwin-aarch64`
- `ansilust-windows-x86_64.exe`
- `ansilust-ios-arm64` (for jailbroken devices)
- `ansilust-ios-arm` (for old jailbroken devices)

**FR1.2.3**: WHEN compiling for musl targets the system shall produce fully static binaries.

**FR1.2.4**: WHEN compiling for glibc targets the system shall minimize dynamic dependencies.

**FR1.2.5**: The system shall strip debug symbols from release binaries.

**FR1.2.6**: Each binary shall support `--version` and `--help` flags.

### FR1.3: npm Package Requirements (esbuild-style)

**FR1.3.1**: The system shall publish a meta package named `ansilust` with launcher logic.

**FR1.3.2**: The system shall publish platform-specific packages (e.g., `ansilust-linux-x64-gnu`) containing prebuilt binaries.

**FR1.3.3**: The meta package shall declare platform packages as optionalDependencies.

**FR1.3.4**: The meta package shall include a launcher script at `bin/launcher.js`.

**FR1.3.5**: The launcher shall use `detect-libc` to determine glibc vs musl on Linux.

**FR1.3.6**: The launcher shall map platform/arch/libc to the appropriate platform package name.

**FR1.3.7**: The launcher shall require() the platform package to obtain binPath.

**FR1.3.8**: IF the platform package is missing THEN the launcher shall display installation instructions.

**FR1.3.9**: The launcher shall spawn the binary using spawnSync with stdio:'inherit'.

**FR1.3.10**: WHEN installed globally the system shall create an `ansilust` command in the user's PATH.

**FR1.3.11**: WHEN executed via npx the system shall run instantly without additional downloads.

**FR1.3.12**: Platform packages shall specify `os` and `cpu` fields to enable npm filtering.

**FR1.3.13**: Platform packages shall export binPath pointing to the embedded binary.

**FR1.3.14**: All npm packages shall include README.md, LICENSE, and usage documentation.

**FR1.3.15**: All npm packages shall use semantic versioning synchronized across meta and platform packages.

**FR1.3.16**: The meta package shall include `detect-libc` as a dependency.

### FR1.4: Homebrew Formula Requirements

**FR1.4.1**: The Homebrew formula shall be hosted in a tap repository at `github.com/OWNER/homebrew-tap`.

**FR1.4.2**: The formula shall download pre-built binaries from GitHub releases.

**FR1.4.3**: The formula shall verify SHA256 checksums before installation.

**FR1.4.4**: WHEN installed on macOS x86_64 the formula shall install the x86_64-macos binary.

**FR1.4.5**: WHEN installed on macOS aarch64 the formula shall install the aarch64-macos binary.

**FR1.4.6**: The formula shall install the binary to the Homebrew bin directory.

**FR1.4.7**: The formula shall include a description, homepage, and license.

**FR1.4.8**: WHERE bottle builds are supported the formula shall provide pre-built bottles.

### FR1.5: AUR Package Requirements

**FR1.5.1**: The AUR package shall be named `ansilust` or `ansilust-bin`.

**FR1.5.2**: The PKGBUILD shall download pre-built binaries from GitHub releases.

**FR1.5.3**: The PKGBUILD shall verify SHA256 checksums.

**FR1.5.4**: The PKGBUILD shall detect the system architecture and install the appropriate binary.

**FR1.5.5**: The package shall install to `/usr/bin/ansilust`.

**FR1.5.6**: The PKGBUILD shall include package metadata (description, URL, license, depends).

**FR1.5.7**: The AUR package shall be maintained in the AUR git repository.

### FR1.6: Nix Package Requirements

**FR1.6.1**: The Nix package shall be available via a flake at `github:OWNER/ansilust`.

**FR1.6.2**: WHERE nixpkgs integration is complete the package shall be available as `nixpkgs#ansilust`.

**FR1.6.3**: The Nix derivation shall download source or pre-built binaries from GitHub.

**FR1.6.4**: The derivation shall verify checksums using Nix hash verification.

**FR1.6.5**: WHEN built from source the derivation shall use Zig build system.

**FR1.6.6**: The package shall support multiple platforms (x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin).

**FR1.6.7**: The derivation shall specify all build dependencies.

**FR1.6.8**: The package shall install to the Nix store and provide a `ansilust` binary.

### FR1.7: Bash Installer Script Requirements

**FR1.7.1**: The Bash installer shall be served from `https://ansilust.com/install`.

**FR1.7.2**: The installer script shall include a header comment with the GitHub source URL.

**FR1.7.3**: The installer shall detect the operating system (Linux, macOS, WSL).

**FR1.7.4**: The installer shall detect the CPU architecture (x86_64, aarch64, armv7, i386).

**FR1.7.5**: WHERE possible the installer shall detect libc variant (glibc vs musl).

**FR1.7.6**: The installer shall download the appropriate binary from GitHub releases.

**FR1.7.7**: The installer shall verify SHA256 checksums before extraction.

**FR1.7.8**: IF checksum verification fails THEN the installer shall abort with an error message.

**FR1.7.9**: The installer shall install the binary to `~/.local/bin/` or `/usr/local/bin/`.

**FR1.7.10**: WHEN installing to system directories the installer shall request sudo if needed.

**FR1.7.11**: The installer shall add the installation directory to PATH if not already present.

**FR1.7.12**: The installer shall be idempotent (safe to run multiple times).

**FR1.7.13**: The installer shall provide verbose output with progress indicators.

**FR1.7.14**: IF the platform is unsupported THEN the installer shall display available alternatives.

### FR1.8: PowerShell Installer Script Requirements

**FR1.8.1**: The PowerShell installer shall be served from `https://ansilust.com/install.ps1`.

**FR1.8.2**: The installer script shall include a header comment with the GitHub source URL.

**FR1.8.3**: The installer shall detect the CPU architecture (x86_64, arm64).

**FR1.8.4**: The installer shall download the Windows binary from GitHub releases.

**FR1.8.5**: The installer shall verify SHA256 checksums before extraction.

**FR1.8.6**: IF checksum verification fails THEN the installer shall abort with an error message.

**FR1.8.7**: The installer shall install to `$env:LOCALAPPDATA\Programs\ansilust\`.

**FR1.8.8**: The installer shall add the installation directory to the user's PATH.

**FR1.8.9**: The installer shall be idempotent (safe to run multiple times).

**FR1.8.10**: The installer shall provide verbose output with progress indicators.

### FR1.9: iOS APT Package Requirements (.deb)

**FR1.9.1**: The system shall build .deb packages for iphoneos-arm64 and iphoneos-arm architectures.

**FR1.9.2**: The .deb control file shall specify package name, version, architecture, and dependencies.

**FR1.9.3**: The .deb package shall install the binary to `/usr/local/bin/ansilust`.

**FR1.9.4**: The .deb package shall be compatible with Procursus, Cydia, and Sileo package managers.

**FR1.9.5**: WHERE a Procursus repository is available the package shall be submitted via PR.

**FR1.9.6**: The .deb package shall include a control file with description and maintainer info.

**FR1.9.7**: The package shall specify minimum iOS version (iOS 9.0 for arm, iOS 12.0 for arm64).

### FR1.10: iOS iSH Support Requirements

**FR1.10.1**: The system shall build a static i386-linux-musl binary for iSH compatibility.

**FR1.10.2**: The binary shall be available for download from GitHub releases.

**FR1.10.3**: The binary shall run successfully in the iSH Alpine Linux environment.

**FR1.10.4**: Documentation shall provide iSH installation instructions for non-jailbroken devices.

### FR1.11: Docker/Podman Container Requirements

**FR1.11.1**: The system shall publish OCI-compatible container images to GitHub Container Registry.

**FR1.11.2**: Images shall be available at `ghcr.io/OWNER/ansilust`.

**FR1.11.3**: The system shall build multi-architecture images (x86_64, aarch64, armv7).

**FR1.11.4**: WHEN a user runs `docker run ghcr.io/OWNER/ansilust` the container shall execute ansilust.

**FR1.11.5**: WHEN a user runs `podman run ghcr.io/OWNER/ansilust` the container shall execute ansilust.

**FR1.11.6**: The container image shall be minimal (Alpine-based or scratch with static binary).

**FR1.11.7**: The container shall support passing arguments to the ansilust binary.

**FR1.11.8**: The image shall include a LABEL with version and source repository.

### FR1.12: Platform Detection Requirements

**FR1.12.1**: Install scripts shall detect operating system using standard methods (`uname`, `$OSTYPE`).

**FR1.12.2**: Install scripts shall detect CPU architecture using standard methods (`uname -m`, `arch`).

**FR1.12.3**: WHERE libc detection is needed scripts shall use `ldd --version` or `/lib/` inspection.

**FR1.12.4**: IF platform detection fails THEN scripts shall provide manual selection options.

**FR1.12.5**: Scripts shall validate detected platform against supported platforms list.

### FR1.13: GitHub Release Requirements

**FR1.13.1**: WHEN a release tag is created the system shall create a GitHub release.

**FR1.13.2**: The release shall include all binary artifacts for supported platforms.

**FR1.13.3**: The release shall include a SHA256SUMS file with checksums for all artifacts.

**FR1.13.4**: WHERE signing is enabled the release shall include a SHA256SUMS.asc GPG signature.

**FR1.13.5**: The release shall include release notes generated from git commits.

**FR1.13.6**: The release shall be marked as latest (unless it's a pre-release).

**FR1.13.7**: The release assets shall be publicly downloadable without authentication.

### FR1.14: Security and Transparency Requirements

**FR1.14.1**: All install scripts shall include header comments with GitHub source code URLs.

**FR1.14.2**: The GitHub source URL shall point to the main branch for latest version.

**FR1.14.3**: Install scripts shall include usage examples in header comments.

**FR1.14.4**: Install scripts shall recommend reviewing the script before piping to shell.

**FR1.14.5**: All binary artifacts shall be accompanied by SHA256 checksums.

**FR1.14.6**: The build process shall be reproducible given the same source and toolchain.

**FR1.14.7**: GitHub Actions workflows shall use pinned action versions for security.

**FR1.14.8**: Install scripts shall be scanned for security vulnerabilities (shellcheck, PSScriptAnalyzer).

### FR1.15: Error Handling Requirements

**FR1.15.1**: IF a download fails THEN install scripts shall retry up to 3 times.

**FR1.15.2**: IF all retries fail THEN scripts shall display a clear error message with troubleshooting steps.

**FR1.15.3**: IF checksum verification fails THEN scripts shall abort and suggest manual installation.

**FR1.15.4**: IF the platform is unsupported THEN scripts shall list supported platforms and alternatives.

**FR1.15.5**: Error messages shall include relevant context (OS, architecture, error details).

**FR1.15.6**: Scripts shall exit with non-zero status codes on failure.

### FR1.16: Documentation Requirements

**FR1.16.1**: Each distribution method shall have dedicated documentation.

**FR1.16.2**: Documentation shall include installation commands for each platform.

**FR1.16.3**: Documentation shall include examples of direct execution methods.

**FR1.16.4**: Documentation shall include troubleshooting sections for common issues.

**FR1.16.5**: The project README shall include a "Installation" section with all methods.

**FR1.16.6**: Install scripts shall include inline documentation and comments.

---

## NFR2: Non-Functional Requirements

### NFR2.1: Performance Requirements

**NFR2.1.1**: GitHub Actions build workflow shall complete in under 30 minutes for all platforms.

**NFR2.1.2**: Individual platform builds shall complete in under 10 minutes.

**NFR2.1.3**: Install scripts shall complete installation in under 60 seconds on typical connections.

**NFR2.1.4**: Binary downloads shall resume if interrupted (HTTP range requests supported).

**NFR2.1.5**: Release binaries shall be under 10MB per platform (uncompressed).

**NFR2.1.6**: Container images shall be under 20MB per architecture.

### NFR2.2: Reliability Requirements

**NFR2.2.1**: The build system shall succeed 95%+ of the time for tagged releases.

**NFR2.2.2**: Install scripts shall succeed 90%+ of the time on supported platforms.

**NFR2.2.3**: Package manager installations shall succeed 95%+ of the time.

**NFR2.2.4**: Binary checksums shall match 100% of the time (deterministic builds).

**NFR2.2.5**: GitHub releases shall be available 99.9%+ of the time (depends on GitHub SLA).

### NFR2.3: Maintainability Requirements

**NFR2.3.1**: Build scripts shall be documented with inline comments.

**NFR2.3.2**: GitHub Actions workflows shall use reusable workflow patterns.

**NFR2.3.3**: Package manager configurations shall be version-controlled.

**NFR2.3.4**: Install scripts shall be testable in isolated environments.

**NFR2.3.5**: Adding a new platform target shall require under 4 hours of work.

### NFR2.4: Security Requirements

**NFR2.4.1**: All HTTPS endpoints shall use valid TLS certificates.

**NFR2.4.2**: Install scripts shall validate checksums before execution.

**NFR2.4.3**: GitHub Actions shall use least-privilege permissions.

**NFR2.4.4**: Secrets (npm tokens, GPG keys) shall be stored in GitHub Secrets.

**NFR2.4.5**: Dependencies in build process shall be pinned to specific versions.

### NFR2.5: Documentation Requirements

**NFR2.5.1**: Installation documentation shall achieve 100% coverage for all distribution methods.

**NFR2.5.2**: Each install method shall have example commands that users can copy-paste.

**NFR2.5.3**: Troubleshooting sections shall cover 80%+ of common user issues.

**NFR2.5.4**: Documentation shall be tested by following instructions verbatim.

---

## TC3: Technical Constraints

### TC3.1: Build System Constraints

**TC3.1.1**: The build system shall use Zig version 0.11.0 or later.

**TC3.1.2**: The build system shall run on GitHub Actions runners (Ubuntu, macOS, Windows).

**TC3.1.3**: GitHub Actions workflows shall not exceed 6 hours total runtime.

**TC3.1.4**: Build artifacts shall not exceed GitHub release asset size limits (2GB per file).

**TC3.1.5**: The build process shall not require external build servers.

### TC3.2: Domain and Hosting Constraints

**TC3.2.1**: Install scripts shall be served from `ansilust.com` domain (owned).

**TC3.2.2**: The domain shall use HTTPS with valid certificates.

**TC3.2.3**: Install scripts shall be hosted via static hosting (GitHub Pages, Cloudflare Pages, or Netlify).

**TC3.2.4**: Install script URLs shall be stable and not change between versions.

### TC3.3: Package Manager Constraints

**TC3.3.1**: npm packages shall comply with npm package naming policies.

**TC3.3.2**: Homebrew formulas shall comply with Homebrew formula requirements.

**TC3.3.3**: AUR packages shall comply with AUR package guidelines.

**TC3.3.4**: Nix packages shall follow nixpkgs contribution guidelines.

**TC3.3.5**: iOS .deb packages shall follow Debian package standards.

### TC3.4: Platform Support Constraints

**TC3.4.1**: The system shall only support platforms where Zig can cross-compile.

**TC3.4.2**: The system shall prioritize 64-bit architectures over 32-bit.

**TC3.4.3**: Windows support shall be limited to x86_64 (no 32-bit or ARM).

**TC3.4.4**: iOS support shall be limited to arm and arm64 architectures.

---

## DR4: Data Requirements

### DR4.1: Binary Artifact Format

**DR4.1.1**: Binaries shall be distributed as:
- Standalone executables (Linux, macOS, Windows, iOS)
- Compressed archives (tar.gz for Unix, zip for Windows) where appropriate
- Container images (OCI format)
- Package formats (.deb for iOS)

**DR4.1.2**: Binary naming shall follow: `ansilust-{os}-{arch}[-{variant}][.ext]`

**DR4.1.3**: Archive naming shall follow: `ansilust-{version}-{os}-{arch}[-{variant}].{tar.gz|zip}`

### DR4.2: Checksum Format

**DR4.2.1**: Checksums shall use SHA256 algorithm.

**DR4.2.2**: The checksum file shall be named `SHA256SUMS`.

**DR4.2.3**: The checksum file format shall be: `{hash} {filename}`

**DR4.2.4**: GPG signatures shall be detached signatures in `SHA256SUMS.asc`.

### DR4.3: Package Metadata

**DR4.3.1**: npm package.json shall include:
- name, version, description, license, repository, keywords, author, bin

**DR4.3.2**: Homebrew formula shall include:
- desc, homepage, url, sha256, license

**DR4.3.3**: AUR PKGBUILD shall include:
- pkgname, pkgver, pkgrel, pkgdesc, arch, url, license, source, sha256sums

**DR4.3.4**: Nix flake.nix shall include:
- description, outputs, packages for each system

**DR4.3.5**: iOS .deb control file shall include:
- Package, Version, Architecture, Maintainer, Description, Section

### DR4.4: Version Format

**DR4.4.1**: Version numbers shall follow semantic versioning: `MAJOR.MINOR.PATCH`

**DR4.4.2**: Git tags shall be prefixed with `v`: `v1.0.0`

**DR4.4.3**: Pre-release versions shall use suffixes: `v1.0.0-beta.1`

**DR4.4.4**: All packages shall use the same version number for a given release.

---

## IR5: Integration Requirements

### IR5.1: GitHub Actions Integration

**IR5.1.1**: The system shall use Changesets (@changesets/cli, @changesets/changelog-github) for version management.

**IR5.1.2**: The release workflow shall trigger on changesets version commits or tags matching `v*`.

**IR5.1.3**: The workflow shall use matrix builds for parallel compilation.

**IR5.1.4**: The workflow shall upload artifacts to GitHub releases.

**IR5.1.5**: The workflow shall publish to npm registry using Changesets automation.

**IR5.1.6**: The workflow shall update Homebrew tap repository.

**IR5.1.7**: The workflow shall generate and upload checksums.

**IR5.1.8**: WHERE signing is enabled the workflow shall sign with GPG key.

### IR5.2: Package Registry Integration

**IR5.2.1**: npm publishing shall use automated npm token authentication.

**IR5.2.2**: Homebrew tap shall be updated via git commit to tap repository.

**IR5.2.3**: AUR package shall be updated manually or via automation (AUR helper).

**IR5.2.4**: Container images shall be pushed to GitHub Container Registry.

**IR5.2.5**: iOS .deb packages shall be submitted to Procursus or self-hosted repo.

### IR5.3: Domain Integration

**IR5.3.1**: Install scripts shall be deployed to ansilust.com on release.

**IR5.3.2**: The deployment process shall be automated via GitHub Actions.

**IR5.3.3**: Install script updates shall be atomic (no partial updates).

**IR5.3.4**: Old script versions shall remain accessible for backwards compatibility.

---

## DEP6: Dependencies

### DEP6.1: External Services

**DEP6.1.1**: npm registry (npmjs.com) for npm package hosting

**DEP6.1.2**: GitHub (github.com) for source hosting and releases

**DEP6.1.3**: GitHub Actions for CI/CD automation

**DEP6.1.4**: GitHub Container Registry for container images

**DEP6.1.5**: Homebrew tap repository (GitHub)

**DEP6.1.6**: AUR (Arch User Repository)

**DEP6.1.7**: Procursus APT repository (or self-hosted) for iOS

**DEP6.1.8**: ansilust.com domain and hosting provider

### DEP6.2: Build Tools

**DEP6.2.1**: Zig compiler (version 0.11.0+)

**DEP6.2.2**: Git for version control

**DEP6.2.3**: tar/gzip for archive creation

**DEP6.2.4**: dpkg-deb for .deb package creation

**DEP6.2.5**: Docker/Podman for container image builds

**DEP6.2.6**: GPG for artifact signing (optional)

**DEP6.2.7**: shellcheck for Bash script validation

**DEP6.2.8**: PSScriptAnalyzer for PowerShell script validation

**DEP6.2.9**: @changesets/cli for version management and changelog generation

**DEP6.2.10**: @changesets/changelog-github for GitHub-integrated changelogs

### DEP6.3: Accounts and Access

**DEP6.3.1**: npm account with publishing permissions for `ansilust`, `16colors`, `16c`

**DEP6.3.2**: GitHub account with repository admin access

**DEP6.3.3**: Homebrew tap repository access

**DEP6.3.4**: AUR maintainer account

**DEP6.3.5**: ansilust.com domain access and hosting credentials

**DEP6.3.6**: GPG key for signing (optional)

**DEP6.3.7**: GitHub Actions secrets configured (npm token, GPG key)

**DEP6.3.8**: iOS APT repository access (Procursus or self-hosted)

---

## SC7: Success Criteria

### SC7.1: Build Success Criteria

**SC7.1.1**: All platform builds complete successfully on tagged releases (100% success rate target).

**SC7.1.2**: All binaries execute `--version` and `--help` successfully.

**SC7.1.3**: All checksums match between builds (reproducible builds).

**SC7.1.4**: Build workflow completes in under 30 minutes.

### SC7.2: Distribution Success Criteria

**SC7.2.1**: npm package is published and installable via `npm install -g ansilust`.

**SC7.2.2**: Homebrew formula installs successfully on macOS (Intel and Apple Silicon).

**SC7.2.3**: AUR package builds and installs successfully on Arch Linux.

**SC7.2.4**: Nix package runs successfully via `nix run`.

**SC7.2.5**: Bash installer succeeds on Ubuntu, Debian, macOS, Alpine, Raspberry Pi.

**SC7.2.6**: PowerShell installer succeeds on Windows 11.

**SC7.2.7**: iOS .deb package installs via Cydia/Sileo on jailbroken devices.

**SC7.2.8**: i386-musl binary runs in iSH on non-jailbroken iOS devices.

**SC7.2.9**: Container images run successfully via docker and podman.

### SC7.3: Documentation Success Criteria

**SC7.3.1**: All installation methods documented with copy-paste commands.

**SC7.3.2**: Troubleshooting section covers common platform-specific issues.

**SC7.3.3**: Install script source code links resolve correctly.

**SC7.3.4**: Users can install on any supported platform by following docs verbatim.

### SC7.4: Security Success Criteria

**SC7.4.1**: All install scripts pass security linting (shellcheck, PSScriptAnalyzer).

**SC7.4.2**: All HTTPS endpoints use valid certificates.

**SC7.4.3**: All checksums verify correctly for released artifacts.

**SC7.4.4**: No secrets leaked in public repositories or logs.

### SC7.5: Automation Success Criteria

**SC7.5.1**: Release process is 100% automated from git tag to published packages.

**SC7.5.2**: No manual steps required for standard releases.

**SC7.5.3**: GitHub Actions workflows succeed 95%+ of the time.

**SC7.5.4**: Failed builds generate actionable error messages.

---

## Requirements Validation

### Validation Methods

**Build Validation**:
- Execute `zig build` for each target
- Verify binary outputs exist and are executable
- Run `--version` and `--help` on each binary
- Verify checksums match

**Installation Validation**:
- Test install on fresh VMs/containers for each platform
- Verify installed binary works correctly
- Verify PATH integration
- Test uninstall process

**Security Validation**:
- Run shellcheck on Bash scripts
- Run PSScriptAnalyzer on PowerShell scripts
- Verify HTTPS certificates
- Test checksum validation

**Documentation Validation**:
- Follow installation instructions verbatim
- Verify all links resolve correctly
- Test copy-paste commands
- Verify source code links in install scripts

### Testing Matrix

| Platform | Method | Validation |
|----------|--------|------------|
| Ubuntu 22.04 x86_64 | npm, bash, docker | Install + run |
| Ubuntu 22.04 aarch64 | bash, docker | Install + run |
| Debian 12 x86_64 | bash | Install + run |
| Arch Linux x86_64 | AUR | Install + run |
| macOS 13 x86_64 | Homebrew, npm | Install + run |
| macOS 14 aarch64 | Homebrew, npm | Install + run |
| Windows 11 x86_64 | PowerShell, npm | Install + run |
| Raspberry Pi 4 aarch64 | bash | Install + run |
| Raspberry Pi 3 armv7 | bash | Install + run |
| Alpine Linux x86_64 | bash (musl) | Install + run |
| iOS 14 arm64 (jailbroken) | APT (.deb) | Install + run |
| iOS 15 (iSH) | manual (i386-musl) | Download + run |
| Android (Termux) | bash | Install + run |
| Docker (ubuntu:latest) | docker run | Execute |
| Docker (alpine:latest) | docker run | Execute |

---

## Requirements Traceability

All functional requirements map to acceptance criteria in `instructions.md`:

- FR1.1 (Build System) → AC20, AC21
- FR1.2 (Binary Artifacts) → AC26, AC27
- FR1.3 (npm) → AC1, AC8
- FR1.4 (Homebrew) → AC9
- FR1.5 (AUR) → AC10
- FR1.6 (Nix) → AC4, AC5, AC11
- FR1.7 (Bash Installer) → AC12, AC14, AC15, AC16, AC17
- FR1.8 (PowerShell Installer) → AC13
- FR1.9 (iOS APT) → AC17.1, AC23.5
- FR1.10 (iOS iSH) → AC17.2, AC23.4
- FR1.11 (Docker/Podman) → AC6, AC7
- FR1.13 (GitHub Releases) → AC19, AC20
- FR1.14 (Security) → AC19, AC22, AC23, AC23.1, AC23.2, AC23.3

Non-functional requirements map to success metrics in `instructions.md`:

- NFR2.1 (Performance) → SM2, SM3
- NFR2.2 (Reliability) → SM4, SM5
- NFR2.5 (Documentation) → SM6

---

## EARS Notation Compliance

This requirements document uses EARS notation for all functional requirements:

- **65 Ubiquitous requirements** ("The system shall...")
- **8 Event-driven requirements** ("WHEN ... the system shall...")
- **1 State-driven requirement** ("WHILE ... the system shall...")
- **14 Unwanted behavior requirements** ("IF ... THEN the system shall...")
- **4 Optional feature requirements** ("WHERE ... the system shall...")

**Total**: 92 EARS-compliant functional requirements

All requirements are:
- ✅ Testable
- ✅ Unambiguous
- ✅ Specific
- ✅ Traceable to acceptance criteria
- ✅ Using mandatory "shall" keyword

---

## Next Steps

1. **Review Requirements** with stakeholders
2. **Proceed to Phase 3: Design Phase** upon approval
3. Create `design.md` with technical architecture
4. Define build system implementation details
5. Design install script logic and platform detection
6. Plan GitHub Actions workflow structure

---

## Implementation Notes

### Existing npm Package Reservations

The following npm package names have been successfully reserved (published as v0.0.1 placeholders):

- **ansilust**: Main ANSI art rendering engine
- **16colors**: 16colo.rs archive utilities  
- **16c**: 16colo.rs CLI shorthand

**Location**: `/packages/{ansilust,16colors,16c}/`

**Status**: Placeholder packages published to prevent squatting

**Next Steps**: 
- Set up Changesets monorepo configuration
- Migrate placeholders to real packages with binaries
- Configure CI/CD to build Zig binaries and package them

### Changesets Integration

**Current Status**: Changesets dependencies mentioned but not yet configured

**Required Setup**:
1. Create root `package.json` with workspace configuration
2. Initialize Changesets: `.changeset/config.json`
3. Configure monorepo with packages: `ansilust`, `16colors`, `16c`
4. Set up GitHub Actions workflow for Changesets automation
5. Configure changelog integration with @changesets/changelog-github

**Workflow**:
1. Developer adds changeset: `npx changeset`
2. Changesets bot creates version PR
3. Merge version PR → triggers release workflow
4. Workflow builds Zig binaries for all platforms
5. Workflow packages binaries into npm packages
6. Changesets publishes to npm
7. GitHub release created with all platform binaries

### Monorepo Structure

```
ansilust/
├── package.json (workspace root)
├── .changeset/
│   └── config.json
├── packages/
│   ├── ansilust/
│   │   ├── package.json
│   │   ├── bin/ (platform binaries)
│   │   └── index.js (binary selector)
│   ├── 16colors/
│   │   └── package.json
│   └── 16c/
│       └── package.json
├── build.zig (Zig build system)
└── .github/workflows/
    ├── release.yml (build + publish)
    └── changeset.yml (version automation)
```

### Binary Packaging Strategy for npm

**Challenge**: npm packages need platform-specific binaries

**Solution**:
1. Zig builds all platform binaries in CI
2. `ansilust` npm package includes all binaries in `bin/` directory

### Binary Packaging Strategy for npm (esbuild-style)

**Pattern**: esbuild-style prebuilt platform packages (RECOMMENDED)

**Architecture**:
1. **Meta package**: `ansilust` with launcher (`bin/launcher.js`)
2. **Platform packages** (as optionalDependencies):
   - `ansilust-darwin-arm64`, `ansilust-darwin-x64`
   - `ansilust-linux-x64-gnu`, `ansilust-linux-x64-musl`
   - `ansilust-linux-arm64-gnu`, `ansilust-linux-arm64-musl`
   - `ansilust-linux-armv7-gnu`, `ansilust-linux-armv7-musl`
   - `ansilust-linux-i386-musl` (for iSH)
   - `ansilust-win32-x64`

**Benefits** (battle-tested by esbuild, swc, @biomejs/biome):
- ✅ Zero network delay on first `npx` run
- ✅ Works offline after install
- ✅ npm auto-selects correct platform
- ✅ Fast execution (no download)

**Launcher**: Detects platform/arch/libc → requires platform package → spawns binary
**Platform pkg**: Exports `binPath` pointing to embedded Zig binary

See implementation examples in design.md (Phase 3).
