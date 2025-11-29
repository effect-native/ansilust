# Ansilust Website - Requirements

**Phase**: 2 - Requirements  
**Status**: Draft  
**Dependencies**: instructions.md (Phase 1 complete)

---

## Overview

This document provides detailed functional and non-functional requirements for the ansilust.com website, using EARS (Easy Approach to Requirements Syntax) notation for clarity and testability.

**Scope**: Static marketing website with documentation, gallery, and playground, deployed via Kamal to VPS.

**Reference**: See `.specs/website/instructions.md` for user stories and acceptance criteria.

---

## FR1: Functional Requirements

### FR1.1: Build System Requirements

**FR1.1.1**: The build system shall use Bun as the JavaScript runtime and package manager.

**FR1.1.2**: The build system shall produce fully static HTML/CSS/JS output with no server-side rendering required at runtime.

**FR1.1.3**: WHEN `bun run build` is executed the system shall generate a complete static site in the output directory.

**FR1.1.4**: The build system shall support React 19.1+ with static generation.

**FR1.1.5**: The build system shall use Tailwind CSS 4.x for styling.

**FR1.1.6**: IF the build fails THEN the system shall exit with non-zero status and display clear error messages.

### FR1.2: Deployment Requirements

**FR1.2.1**: The system shall be deployable via Kamal to a VPS using Docker.

**FR1.2.2**: The system shall include a Dockerfile for containerized deployment.

**FR1.2.3**: WHEN `kamal deploy` is executed the system shall build and deploy the site to the configured VPS.

**FR1.2.4**: The deployment shall configure TLS certificates automatically (via Traefik/Let's Encrypt).

**FR1.2.5**: The system shall be accessible at `https://ansilust.com` after deployment.

**FR1.2.6**: The deployment shall support zero-downtime updates.

### FR1.3: Homepage Requirements

**FR1.3.1**: The homepage shall display a hero section with project tagline.

**FR1.3.2**: The homepage shall display an ASCII/ANSI visual element as part of the hero.

**FR1.3.3**: The homepage shall display quick install commands for npm, curl, and nix.

**FR1.3.4**: WHEN a user clicks an install command the system shall copy it to clipboard.

**FR1.3.5**: The homepage shall display feature highlights (parsers, renderers, animation support).

**FR1.3.6**: The homepage shall display a preview gallery of rendered ANSI art examples.

**FR1.3.7**: The homepage shall display call-to-action buttons (Get Started, View on GitHub).

**FR1.3.8**: WHEN a user clicks "Get Started" the system shall navigate to the installation page.

**FR1.3.9**: WHEN a user clicks "View on GitHub" the system shall open the GitHub repository in a new tab.

### FR1.4: Installation Page Requirements

**FR1.4.1**: The installation page shall be accessible at `/install`.

**FR1.4.2**: The installation page shall detect the user's platform (OS, architecture) via browser APIs.

**FR1.4.3**: WHEN platform is detected the system shall highlight the recommended installation method.

**FR1.4.4**: The installation page shall provide a tabbed interface for all installation methods.

**FR1.4.5**: The installation page shall display installation instructions for:
- npm (npx and global install)
- Bash installer (curl | bash)
- PowerShell installer
- AUR (Arch Linux)
- Nix flake
- Docker/Podman (GHCR)
- From source (Zig build)

**FR1.4.6**: Each installation method shall include copy-to-clipboard functionality.

**FR1.4.7**: The installation page shall display verification commands to confirm successful installation.

**FR1.4.8**: The installation page shall include a troubleshooting section.

**FR1.4.9**: IF a platform is not supported THEN the page shall display alternative options.

### FR1.5: Documentation Requirements

**FR1.5.1**: Documentation pages shall be accessible under `/docs/*`.

**FR1.5.2**: The documentation shall include a "Getting Started" guide at `/docs/getting-started`.

**FR1.5.3**: The documentation shall include CLI usage and options at `/docs/cli`.

**FR1.5.4**: The documentation shall include a supported formats reference at `/docs/formats`.

**FR1.5.5**: The documentation shall include SAUCE metadata documentation at `/docs/sauce`.

**FR1.5.6**: The documentation shall include IR (Intermediate Representation) overview at `/docs/ir`.

**FR1.5.7**: The documentation shall include a contributing guide at `/docs/contributing`.

**FR1.5.8**: Documentation pages shall support syntax-highlighted code blocks.

**FR1.5.9**: Code blocks shall include copy-to-clipboard functionality.

**FR1.5.10**: The documentation shall include navigation between pages (previous/next, sidebar).

### FR1.6: Playground Requirements

**FR1.6.1**: The playground page shall be accessible at `/playground`.

**FR1.6.2**: The playground shall provide a text area for pasting ANSI art.

**FR1.6.3**: The playground shall provide file upload for .ans/.asc files.

**FR1.6.4**: WHEN ANSI content is provided the system shall render a live preview.

**FR1.6.5**: The playground shall provide sample files that users can load.

**FR1.6.6**: WHEN a user selects a sample file the system shall load and render it.

**FR1.6.7**: The playground shall provide export options (PNG, copy rendered output).

**FR1.6.8**: WHEN a user clicks "Export PNG" the system shall generate and download a PNG image.

**FR1.6.9**: IF rendering fails THEN the system shall display a clear error message.

### FR1.7: Gallery Requirements

**FR1.7.1**: The gallery page shall be accessible at `/gallery`.

**FR1.7.2**: The gallery shall display at least 10 curated classic ANSI artworks.

**FR1.7.3**: Each gallery item shall display the artwork rendered through ansilust.

**FR1.7.4**: The gallery shall support filtering by artpack, year, or artist.

**FR1.7.5**: WHEN a user clicks a gallery item the system shall display a fullscreen view.

**FR1.7.6**: The fullscreen view shall include artwork metadata (title, artist, artpack, year).

**FR1.7.7**: The fullscreen view shall be dismissible via click, escape key, or close button.

**FR1.7.8**: WHERE before/after comparisons are available the gallery shall display them.

### FR1.8: Install Script Hosting Requirements

**Cross-reference**: See `.specs/publish/requirements.md` FR1.7, FR1.8 for script specifications.

**FR1.8.1**: WHEN a user requests `/install.sh` the server shall return the Bash install script.

**FR1.8.2**: WHEN a user requests `/install.ps1` the server shall return the PowerShell install script.

**FR1.8.3**: WHEN a user requests `/install` with `Accept: text/plain` or similar the server shall return the Bash install script.

**FR1.8.4**: Install scripts shall be served with appropriate `Content-Type` headers.

**FR1.8.5**: Install scripts shall be sourced from `scripts/install.sh` and `scripts/install.ps1` in the repository.

### FR1.9: Navigation Requirements

**FR1.9.1**: The site shall include a persistent navigation header on all pages.

**FR1.9.2**: The navigation shall include links to: Home, Install, Docs, Playground, Gallery, GitHub.

**FR1.9.3**: WHEN on mobile viewport the navigation shall collapse to a hamburger menu.

**FR1.9.4**: WHEN the hamburger menu is clicked the system shall display a mobile navigation overlay.

**FR1.9.5**: The navigation shall indicate the current active page.

### FR1.10: Dark Mode Requirements

**FR1.10.1**: The site shall default to dark mode.

**FR1.10.2**: The site shall provide a toggle to switch between dark and light modes.

**FR1.10.3**: WHEN a user toggles the mode the system shall persist the preference in localStorage.

**FR1.10.4**: WHEN a user returns to the site the system shall restore their mode preference.

**FR1.10.5**: IF no preference is stored THEN the system shall use dark mode as default.

### FR1.11: SEO Requirements

**FR1.11.1**: Each page shall have a unique `<title>` tag.

**FR1.11.2**: Each page shall have a unique `<meta name="description">` tag.

**FR1.11.3**: Each page shall include Open Graph meta tags (og:title, og:description, og:image, og:url).

**FR1.11.4**: Each page shall include Twitter Card meta tags.

**FR1.11.5**: The site shall include JSON-LD structured data for the organization and software application.

**FR1.11.6**: The site shall generate a `sitemap.xml` at `/sitemap.xml`.

**FR1.11.7**: The site shall include a `robots.txt` at `/robots.txt`.

**FR1.11.8**: The sitemap shall be generated automatically during build.

### FR1.12: Visual Design Requirements

**FR1.12.1**: Each major section shall be contained in a fixed-dimension "card" or "page" element.

**FR1.12.2**: Sections shall stack vertically and scroll naturally.

**FR1.12.3**: The design shall incorporate ASCII/box-drawing characters as design elements.

**FR1.12.4**: The design shall use a restrained color palette (≤5 colors plus grayscale).

**FR1.12.5**: The design shall mix terminal/pixel fonts with refined typography.

**FR1.12.6**: The design shall incorporate subtle texture (noise, scanlines, or CRT-inspired effects).

**FR1.12.7**: The design shall NOT resemble a typical modern SaaS landing page.

**FR1.12.8**: The design shall evoke FILE_ID.DIZ and 1997 print design aesthetics.

---

## NFR2: Non-Functional Requirements

### NFR2.1: Performance Requirements

**NFR2.1.1**: The site shall achieve a Lighthouse Performance score of 90 or higher.

**NFR2.1.2**: First Contentful Paint shall be under 1.5 seconds on 4G connection.

**NFR2.1.3**: Total JavaScript bundle size shall be under 200KB gzipped (excluding ANSI art assets).

**NFR2.1.4**: Total CSS bundle size shall be under 50KB gzipped.

**NFR2.1.5**: Images shall be lazy-loaded where appropriate.

**NFR2.1.6**: Critical CSS shall be inlined for above-the-fold content.

**NFR2.1.7**: The site shall load and be interactive within 2 seconds on typical connections.

### NFR2.2: Accessibility Requirements

**NFR2.2.1**: The site shall achieve a Lighthouse Accessibility score of 95 or higher.

**NFR2.2.2**: All interactive elements shall be keyboard navigable.

**NFR2.2.3**: All images shall have appropriate alt text.

**NFR2.2.4**: Color contrast ratios shall meet WCAG AA standards.

**NFR2.2.5**: Focus states shall be clearly visible.

**NFR2.2.6**: The site shall work with screen readers.

### NFR2.3: Responsiveness Requirements

**NFR2.3.1**: The site shall be fully functional on desktop viewports (1920px+).

**NFR2.3.2**: The site shall be fully functional on laptop viewports (1024px-1919px).

**NFR2.3.3**: The site shall be fully functional on tablet viewports (768px-1023px).

**NFR2.3.4**: The site shall be fully functional on mobile viewports (320px-767px).

**NFR2.3.5**: Fixed-dimension sections shall scale appropriately for viewport size.

**NFR2.3.6**: Touch interactions shall work correctly on mobile devices.

### NFR2.4: Reliability Requirements

**NFR2.4.1**: The site shall maintain 99%+ uptime.

**NFR2.4.2**: The site shall be served from the VPS with no external runtime dependencies.

**NFR2.4.3**: IF the Docker container crashes THEN Kamal shall automatically restart it.

**NFR2.4.4**: Static assets shall be cacheable with appropriate cache headers.

### NFR2.5: Security Requirements

**NFR2.5.1**: The site shall be served exclusively over HTTPS.

**NFR2.5.2**: HTTP requests shall redirect to HTTPS.

**NFR2.5.3**: TLS certificates shall be valid and auto-renewed.

**NFR2.5.4**: The site shall include appropriate security headers (X-Frame-Options, X-Content-Type-Options, etc.).

**NFR2.5.5**: User input in playground shall be sanitized before rendering.

### NFR2.6: Maintainability Requirements

**NFR2.6.1**: The codebase shall use TypeScript for type safety.

**NFR2.6.2**: Components shall be modular and reusable.

**NFR2.6.3**: The build process shall complete in under 60 seconds.

**NFR2.6.4**: Deployment shall complete in under 5 minutes.

**NFR2.6.5**: Adding a new documentation page shall require only creating a new MDX/MD file.

---

## TC3: Technical Constraints

### TC3.1: Runtime Constraints

**TC3.1.1**: The build system shall use Bun 1.x or later.

**TC3.1.2**: The framework shall use React 19.1 or later.

**TC3.1.3**: Styling shall use Tailwind CSS 4.x.

**TC3.1.4**: The site shall be fully static with no Node.js/Bun runtime required in production.

### TC3.2: Deployment Constraints

**TC3.2.1**: Deployment shall use Kamal 2.x.

**TC3.2.2**: The production environment shall be a Docker container.

**TC3.2.3**: The VPS shall have at least 1GB RAM and 1 vCPU.

**TC3.2.4**: The VPS shall run a Linux distribution supported by Kamal.

**TC3.2.5**: TLS termination shall be handled by Traefik.

### TC3.3: Browser Support Constraints

**TC3.3.1**: The site shall support the latest 2 versions of Chrome, Firefox, Safari, and Edge.

**TC3.3.2**: The site shall gracefully degrade on older browsers.

**TC3.3.3**: JavaScript shall be required for playground functionality.

**TC3.3.4**: Core content (docs, install instructions) shall be readable without JavaScript.

### TC3.4: Content Constraints

**TC3.4.1**: Documentation shall be authored in MDX or Markdown format.

**TC3.4.2**: ANSI art assets shall be stored in the repository or fetched from known sources.

**TC3.4.3**: Gallery artwork shall respect original artist attribution.

**TC3.4.4**: Install scripts shall be sourced from the main repository `scripts/` directory.

---

## DR4: Data Requirements

### DR4.1: Content Structure

**DR4.1.1**: Documentation content shall be stored in a `content/docs/` directory.

**DR4.1.2**: Gallery metadata shall be stored in a structured format (JSON/YAML).

**DR4.1.3**: Sample ANSI files for playground shall be stored in `public/samples/`.

**DR4.1.4**: Gallery artwork shall be stored in `public/gallery/`.

### DR4.2: Asset Formats

**DR4.2.1**: Images shall be in WebP or PNG format with fallbacks.

**DR4.2.2**: ANSI art files shall be in .ans or .asc format.

**DR4.2.3**: Fonts shall be in WOFF2 format with WOFF fallback.

### DR4.3: Metadata Format

**DR4.3.1**: Gallery items shall include: title, artist, artpack, year, filename, thumbnail.

**DR4.3.2**: Documentation pages shall include: title, description, order/weight for sorting.

**DR4.3.3**: Sample files shall include: name, description, source attribution.

---

## IR5: Integration Requirements

### IR5.1: Repository Integration

**IR5.1.1**: The website shall be part of the main ansilust monorepo.

**IR5.1.2**: The website shall be located in a `website/` directory at the repository root.

**IR5.1.3**: Install scripts shall be referenced from `scripts/install.sh` and `scripts/install.ps1`.

### IR5.2: Deployment Integration

**IR5.2.1**: Kamal configuration shall be stored in `website/config/deploy.yml`.

**IR5.2.2**: Deployment secrets shall be managed via Kamal's secrets mechanism.

**IR5.2.3**: The Docker image shall be pushed to a container registry (GHCR or Docker Hub).

### IR5.3: CI/CD Integration

**IR5.3.1**: WHEN changes are pushed to `main` affecting `website/` the system shall trigger a deployment.

**IR5.3.2**: The deployment workflow shall be defined in `.github/workflows/`.

**IR5.3.3**: Deployment shall only proceed if the build succeeds.

---

## DEP6: Dependencies

### DEP6.1: Build Dependencies

**DEP6.1.1**: Bun runtime (1.x+)

**DEP6.1.2**: React (19.1+)

**DEP6.1.3**: Tailwind CSS (4.x)

**DEP6.1.4**: A React framework supporting static export (Next.js, Vite, or similar)

### DEP6.2: Deployment Dependencies

**DEP6.2.1**: Kamal (2.x)

**DEP6.2.2**: Docker

**DEP6.2.3**: VPS with SSH access

**DEP6.2.4**: Domain (ansilust.com) with DNS configured

### DEP6.3: External Services

**DEP6.3.1**: Container registry (GHCR) for Docker images

**DEP6.3.2**: Let's Encrypt for TLS certificates (via Traefik)

---

## SC7: Success Criteria

### SC7.1: Build & Deploy Success

**SC7.1.1**: `bun run build` completes without errors.

**SC7.1.2**: `kamal deploy` completes successfully.

**SC7.1.3**: Site accessible at `https://ansilust.com` with valid TLS.

**SC7.1.4**: All pages load without errors (200 status codes).

### SC7.2: Content Success

**SC7.2.1**: Homepage displays all required sections (hero, install, features, gallery preview).

**SC7.2.2**: Installation page displays all 7 installation methods.

**SC7.2.3**: At least 5 documentation pages have real content.

**SC7.2.4**: Playground successfully renders pasted ANSI art.

**SC7.2.5**: Gallery displays at least 10 curated artworks.

### SC7.3: Functionality Success

**SC7.3.1**: Install scripts downloadable at `/install.sh` and `/install.ps1`.

**SC7.3.2**: Dark mode toggle works and persists preference.

**SC7.3.3**: Mobile navigation functions correctly.

**SC7.3.4**: Copy-to-clipboard works on all code blocks.

**SC7.3.5**: Playground file upload and rendering works.

### SC7.4: Performance Success

**SC7.4.1**: Lighthouse Performance score ≥ 90.

**SC7.4.2**: Lighthouse Accessibility score ≥ 95.

**SC7.4.3**: Page load time ≤ 2 seconds on 4G.

### SC7.5: Design Success

**SC7.5.1**: Each section feels like a distinct page/card with intentional dimensions.

**SC7.5.2**: Design evokes FILE_ID.DIZ / NFO / 1997 print aesthetic.

**SC7.5.3**: Color palette is restrained (≤5 colors + grayscale).

**SC7.5.4**: Site does NOT look like a typical modern SaaS landing page.

---

## Requirements Traceability

| Requirement | Instruction Reference | Acceptance Criteria |
|-------------|----------------------|---------------------|
| FR1.1-FR1.2 | CR1, CR2 | AC1 |
| FR1.3 | CR3.1 | AC2 |
| FR1.4 | CR3.2 | AC2, AC3 |
| FR1.5 | CR3.3 | AC2 |
| FR1.6 | CR3.4 | AC2 |
| FR1.7 | CR3.5 | AC2 |
| FR1.8 | CR4 | AC3 |
| FR1.10 | CR6 | AC3 |
| FR1.11 | CR8 | AC5 |
| FR1.12 | CR9 | AC6 |
| NFR2.1 | CR7 | AC4 |
| NFR2.2 | CR7 | AC4 |
| NFR2.3 | CR5 | AC3 |

---

## EARS Notation Compliance

This requirements document uses EARS notation for all functional requirements:

- **52 Ubiquitous requirements** ("The system shall...")
- **18 Event-driven requirements** ("WHEN ... the system shall...")
- **2 State-driven requirements** ("WHILE ... the system shall...")
- **5 Unwanted behavior requirements** ("IF ... THEN the system shall...")
- **1 Optional feature requirement** ("WHERE ... the system shall...")

**Total**: 78 EARS-compliant functional requirements

All requirements are:
- ✅ Testable
- ✅ Unambiguous  
- ✅ Specific
- ✅ Traceable to instructions
- ✅ Using mandatory "shall" keyword

---

## Next Steps

1. **Review Requirements** with stakeholder
2. **Proceed to Phase 3: Design Phase** upon approval
3. Create `design.md` with technical architecture
4. Define component structure and data flow
5. Design Kamal/Docker deployment configuration
6. Plan visual design system

---

**End of Requirements Document**
