---
id: FEAT-KIOSK-001
title: Bootable kiosk ISO distribution
area: cli
status: pending
priority: low
spec_ref:
  - rfcs/inbox/bootable-kiosk-iso.md
code_refs: []
acceptance:
  - Bootable ISO/IMG for x86/ARM platforms
  - Zero-config boot into art rendering
  - Multiple rendering modes (shuffle, playlist, slideshow, scroll)
  - USB configuration file support
  - Web-based configuration interface
  - Read-only filesystem with writable overlay
  - Network content downloads from 16colo.rs
  - Works on Raspberry Pi, Intel NUC, old laptops
blocked_by:
  - GAP-DL-001
  - GAP-DB-001
labels:
  - distribution
  - kiosk
  - showcase
  - future
  - hardware
created: 2025-11-03
---

## Context

From `rfcs/inbox/bootable-kiosk-iso.md`:

A bootable operating system image that transforms any device into a dedicated ANSI art display appliance. Flash the ISO onto a device, plug into a TV or monitor, and get infinite scrolling art with zero configuration.

**Vision**: "Buy a Raspberry Pi, flash ansilust-kiosk.img, plug into your TV, turn it on, and enjoy infinite art."

## Use Cases

- **Art galleries**: Digital art displays running 24/7
- **Commercial displays**: Lobby/waiting room ambient displays
- **Home installations**: Living room ambient art
- **Maker spaces**: Community art displays

## Core Features

1. **Zero-config boot**: Auto-detect display, network config, immediate rendering
2. **Rendering modes**: Shuffle, playlist, single, slideshow, infinite scroll
3. **Configuration methods**:
   - USB configuration file (ansilust-config.toml)
   - Web interface (browser access)
   - Remote management (REST API)
4. **Content management**: Built-in collections, USB loading, network downloads

## Technical Architecture

**OS base**: Alpine Linux (minimal ~50MB) or Buildroot

**System components**:
- Bootloader (GRUB/U-Boot)
- Linux kernel with framebuffer
- Init system (OpenRC/systemd minimal)
- Ansilust kiosk service

**Filesystem**:
- Read-only root (prevent corruption)
- Writable overlay for config
- Separate data partition for artwork

**Display**: Direct framebuffer (no X11/Wayland), hardware accel where available

## Target Hardware

**Primary**: Raspberry Pi (Zero 2 W, 3/4/5), x86/x64 PCs (Intel NUC, old laptops, thin clients)

**Secondary**: Other ARM boards (Orange Pi, Rock Pi, Odroid), embedded devices

## Distribution Formats

- **ISO images** (x86/x64): Bootable USB/CD, UEFI/BIOS support
- **IMG images** (ARM): Raw disk images for SD cards, Balena Etcher compatible
- **VM images**: QEMU/KVM, VirtualBox, VMware

## Implementation Phases

1. **Proof of concept**: Minimal Alpine build, ansilust integration, auto-boot, USB config, test on Pi 4
2. **Core features**: Rendering modes, web config UI, content scanning, network downloads, read-only FS
3. **Polish & distribution**: Image building automation, multi-arch builds, docs, Balena Etcher verification, release
4. **Advanced features**: Remote management API, OTA updates, multi-display, HDMI-CEC, audio support

## Dependencies

- GAP-DL-001 (HTTP client)
- GAP-DB-001 (SQLite .index.db)
- Ansilust rendering engine (available)
- .specs/publish completion (CLI distribution)

## Notes

- Side quest / low priority (after core CLI complete)
- Requires ansilust feature-complete
- Community interest will drive priority
- Could be funded via hardware kit sales
- Security: read-only root, signed updates, SSH disabled by default
