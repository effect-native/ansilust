# Ansilust Kiosk - Bootable ISO Distribution

**Status**: Concept / Side Quest  
**Priority**: Low (after core CLI distribution complete)  
**Dependencies**: ansilust core, rendering engine, .specs/publish completion

---

## Concept

A bootable operating system image that transforms any device into a dedicated ANSI art display appliance. Flash the ISO onto a device, plug into a TV or monitor, and get infinite scrolling art with zero configuration.

### Vision

"Buy a Raspberry Pi, flash ansilust-kiosk.img, plug into your TV, turn it on, and enjoy infinite art."

---

## Use Cases

### Art Galleries & Exhibitions
- Digital art displays running 24/7
- Curated playlists of ANSI art collections
- No computer expertise required

### Commercial Displays
- Lobby/waiting room ambient displays
- Digital signage with retro aesthetics
- Conference room displays

### Home Installations
- Living room ambient art
- Home office background displays
- Retro gaming room displays

### Maker Spaces & Hackerspaces
- Community art displays
- Rotating member artwork showcases
- Event displays (conferences, meetups)

---

## Core Features

### Zero-Configuration Boot
- Auto-detect display resolution and capabilities
- Automatic network configuration (DHCP)
- Start rendering art immediately on boot
- No keyboard/mouse required for basic operation

### Art Rendering Modes
- **Shuffle**: Random selection from local collection
- **Playlist**: Ordered playback of art files
- **Single**: Loop a specific artwork
- **Slideshow**: Timed transitions between pieces
- **Infinite Scroll**: Continuous vertical scrolling

### Customization Options
- Color palette selection
- Scroll speed adjustment
- Transition effects (fade, wipe, dissolve)
- Display duration per artwork
- Brightness/contrast controls

### Configuration Methods

**Level 1: USB Configuration File**
- Place `ansilust-config.toml` on USB drive
- Boot with USB inserted
- Configuration auto-loaded

**Level 2: Web Interface**
- Connect to device's IP address
- Configure via browser (phone/tablet/computer)
- Live preview of changes

**Level 3: Remote Management**
- REST API for automation
- Playlist updates via network
- Status monitoring and logging

### Content Management

**Built-in Collections**:
- Pre-loaded curated ANSI art packs
- 16colo.rs archive subset
- Classic BBS art

**Local Content**:
- Load artwork from USB drive
- Automatic scanning and indexing
- Support for .ans, .asc, .nfo, .diz formats

**Network Content**:
- Download from 16colo.rs API
- Auto-update collections
- RSS/feed support for new art

---

## Technical Architecture

### Operating System Base

**Option 1: Alpine Linux** (Recommended)
- Minimal footprint (~50MB base)
- Fast boot time
- musl libc (ansilust already targets this)
- APK package manager for updates

**Option 2: Buildroot**
- Custom-built minimal system
- Absolute minimal size
- Complete control over components
- Longer build times

**Option 3: Raspberry Pi OS Lite**
- Familiar for Pi users
- Broader hardware support
- Larger footprint (~500MB)

### System Components

**Boot Process**:
1. Bootloader (GRUB/U-Boot)
2. Linux kernel with framebuffer support
3. Init system (OpenRC/systemd minimal)
4. Auto-start ansilust-kiosk service

**Ansilust Kiosk Service**:
- Display manager (kmscon or direct framebuffer)
- ansilust rendering engine
- Configuration daemon
- Web server (optional, for config UI)

**Filesystem Layout**:
- Read-only root filesystem (prevent corruption)
- Writable overlay for configuration
- Separate data partition for artwork

### Display Technology

**Framebuffer Rendering**:
- Direct framebuffer access (no X11/Wayland)
- Hardware acceleration where available
- Terminal emulation via kmscon or fbterm

**Resolution Handling**:
- Auto-detect via EDID
- Fallback to safe modes (1920x1080, 1280x720)
- Dynamic font scaling

---

## Target Hardware Platforms

### Primary Targets

**Raspberry Pi** (All Models):
- Pi Zero 2 W (minimal cost, WiFi)
- Pi 3/4/5 (better performance)
- Pi 400 (built-in keyboard for advanced config)

**x86/x64 PCs**:
- Intel NUC
- Old laptops (repurposed)
- Thin clients
- Mini PCs

### Secondary Targets

**Other ARM Boards**:
- Orange Pi
- Rock Pi
- Odroid
- Banana Pi

**Embedded Devices**:
- Steam Deck (desktop mode)
- Chromebooks (developer mode)

---

## Distribution Formats

### ISO Images (x86/x64)
- Bootable from USB or CD/DVD
- UEFI and BIOS support
- Hybrid ISO for USB boot

### IMG Images (ARM)
- Raw disk images for SD cards
- Compressed (xz, gz, zstd)
- Balena Etcher compatible
- Raspberry Pi Imager integration

### Virtual Machine Images
- QEMU/KVM qcow2
- VirtualBox OVA
- VMware VMDK

---

## Implementation Phases

### Phase 1: Proof of Concept
- [ ] Minimal Alpine Linux build
- [ ] Ansilust static binary integration
- [ ] Auto-boot to rendering
- [ ] Basic USB configuration
- [ ] Test on Raspberry Pi 4

### Phase 2: Core Features
- [ ] Multiple rendering modes
- [ ] Web-based configuration UI
- [ ] Content scanning and indexing
- [ ] Network content downloads
- [ ] Read-only filesystem with overlay

### Phase 3: Polish & Distribution
- [ ] Image building automation (GitHub Actions)
- [ ] Multi-architecture builds
- [ ] Documentation and guides
- [ ] Balena Etcher verification
- [ ] Release via ansilust.com

### Phase 4: Advanced Features
- [ ] Remote management API
- [ ] Over-the-air updates
- [ ] Multi-display support
- [ ] HDMI-CEC control
- [ ] Audio support (chiptune/tracker music)

---

## Configuration File Format

**Example: ansilust-config.toml**

```toml
[display]
mode = "shuffle"              # shuffle, playlist, single, slideshow, scroll
duration = 30                 # seconds per artwork
transition = "fade"           # fade, wipe, dissolve, none

[colors]
palette = "default"           # default, vibrant, pastel, monochrome
brightness = 100              # 0-100

[content]
collections = ["classics", "demoscene", "16colors-2023"]
local_path = "/media/usb0/ansi-art"
download_enabled = true

[network]
enabled = true
wifi_ssid = "MyNetwork"
wifi_password = "secret"
api_enabled = false

[advanced]
scroll_speed = 10             # lines per second
font_size = "auto"            # auto, small, medium, large
hardware_accel = true
```

---

## Build System

### Image Builder Script

```bash
#!/bin/bash
# build-ansilust-kiosk.sh

# Target: alpine-x86_64, alpine-aarch64, alpine-armv7
TARGET=$1

# Download Alpine base
# Install ansilust binary
# Configure auto-boot
# Setup read-only filesystem
# Build ISO/IMG
# Compress and checksum
```

### GitHub Actions Workflow

- Build on release tags
- Matrix build for all architectures
- Upload ISO/IMG to GitHub Releases
- Update ansilust.com download page

---

## User Documentation Outline

### Quick Start Guide
1. Download image for your device
2. Flash to USB/SD card (Balena Etcher)
3. Boot device
4. Enjoy infinite art

### Advanced Configuration
- USB configuration file
- Web interface access
- Network setup
- Custom artwork loading

### Hardware Guides
- Raspberry Pi setup
- Intel NUC setup
- Thin client conversion
- Display compatibility

### Troubleshooting
- Boot issues
- Display problems
- Network connectivity
- Performance optimization

---

## Integration Points

### With Ansilust Core
- Use ansilust rendering engine
- Leverage UTF8ANSI renderer
- Parse .ans, .asc files
- Apply color transformations

### With 16colo.rs
- Download artpacks via API
- Browse collections
- Metadata integration
- Artist attribution

### With Existing Projects
- Screensaver mode integration
- BBS viewer integration
- OpenTUI rendering backend

---

## Security Considerations

### Read-Only Root
- Prevent corruption from power loss
- Immutable system files
- Configuration in overlay

### Update Mechanism
- Signed updates only
- Atomic update process
- Rollback on failure

### Network Security
- Optional firewall
- SSH disabled by default
- Web UI with basic auth
- API token authentication

---

## Business Model (Optional)

### Free Distribution
- Open source ISO images
- Community support
- Documentation wiki

### Premium Options
- Pre-configured hardware kits
- Commercial support
- Custom artwork curation
- Installation services

### Partnerships
- Art gallery integrations
- Digital signage vendors
- Raspberry Pi resellers
- Maker space collaborations

---

## Success Metrics

- Number of downloads
- Active installations (telemetry opt-in)
- Community contributions
- Hardware compatibility reports
- User satisfaction surveys

---

## Related Projects for Research

### Existing Kiosk Systems
- **PiSignage**: Digital signage for Raspberry Pi
- **Screenly**: Open source digital signage
- **Yodeck**: Cloud-based signage solution

### Bootable Art Systems
- **Electric Sheep**: Distributed screensaver
- **Processing**: Visual art platform
- **Pure Data**: Audio/visual programming

### Minimal Linux Distributions
- **Tiny Core Linux**: Minimal desktop
- **Puppy Linux**: Small, fast Linux
- **Alpine Linux**: Security-focused minimal

---

## Next Steps

1. Create `.specs/bootable-kiosk/` specification directory
2. Research Alpine Linux customization
3. Build proof-of-concept for Raspberry Pi
4. Test ansilust static binary boot-to-render
5. Design web configuration UI
6. Draft full specification document

---

## Notes

- This project is independent of `.specs/publish` (CLI distribution)
- Requires ansilust core to be feature-complete
- Consider as post-v1.0 enhancement
- Community interest will drive priority
- Could be funded via hardware kit sales
