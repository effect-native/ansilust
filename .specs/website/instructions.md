# Ansilust Website - Instructions

**Phase**: 1 - Instructions  
**Status**: Draft  
**Target Domain**: ansilust.com

---

## Overview

Create a fully static marketing and documentation website for ansilust, deployed via Kamal to a $5 VPS using Docker. The site will serve as the primary public presence for the project, providing:

- Project introduction and value proposition
- Installation instructions for all platforms
- Documentation and usage examples
- Live demo/playground for rendering ANSI art
- Download links and install scripts

## User Story

As a **potential user discovering ansilust**, I want to:
- Quickly understand what ansilust does
- See visual examples of rendered ANSI art
- Find installation instructions for my platform
- Try a live demo in my browser
- Access documentation and API reference

As a **developer integrating ansilust**, I want to:
- Find npm package documentation
- See code examples and API usage
- Access technical specifications
- Understand the project architecture

---

## Core Requirements

### CR1: Static Site Generation
The website shall be a fully static build with no server-side rendering at runtime.

### CR2: Technology Stack
- **Runtime**: Bun
- **Framework**: React 19.1+
- **Styling**: Tailwind CSS 4.x
- **Deployment**: Kamal to VPS via Docker
- **Build Output**: Fully static HTML/CSS/JS

### CR3: Key Pages

#### CR3.1: Homepage (`/`)
WHEN a visitor lands on the homepage the site shall display:
- Hero section with project tagline and ASCII/ANSI visual
- Quick install commands (npm, curl, nix)
- Feature highlights (parsers, renderers, animation support)
- Visual gallery of rendered ANSI art examples
- Call-to-action buttons (Get Started, View on GitHub)

#### CR3.2: Installation Page (`/install`)

**Cross-reference**: See `.specs/publish/instructions.md` for complete list of distribution methods and platform support.

The installation page shall provide:
- Platform detection with recommended install method
- Tabbed interface for all installation methods (per publish spec v1.0.0 scope):
  - npm (npx, global install)
  - Bash installer (curl | bash)
  - PowerShell installer
  - AUR (Arch Linux)
  - Nix flake
  - Docker/Podman (GHCR)
  - From source (Zig build)
- Verification commands to confirm installation
- Troubleshooting section

Note: Homebrew excluded per publish spec decision.

#### CR3.3: Documentation Pages (`/docs/*`)
The documentation section shall include:
- Getting Started guide
- CLI usage and options
- Supported formats reference
- SAUCE metadata documentation
- IR (Intermediate Representation) overview
- Contributing guide

#### CR3.4: Playground Page (`/playground`)
The playground page shall provide:
- Text area for pasting ANSI art
- File upload for .ans/.asc files
- Live preview rendering using WebAssembly or canvas
- Export options (PNG, copy rendered output)
- Sample files to load and experiment with

#### CR3.5: Gallery Page (`/gallery`)
The gallery shall showcase:
- Curated selection of classic ANSI art rendered through ansilust
- Before/after comparisons (original vs rendered)
- Filter by artpack, year, or artist
- Click-to-expand fullscreen view

### CR4: Install Script Hosting

**Cross-reference**: See `.specs/publish/` for install script specifications (FR1.7, FR1.8).

WHEN a user requests `/install` (with appropriate Accept header) or `/install.sh` the server shall return the bash install script.
WHEN a user requests `/install.ps1` the server shall return the PowerShell install script.

The install scripts are maintained in `scripts/install.sh` and `scripts/install.ps1` per the publish spec.

### CR5: Responsive Design
The website shall be fully responsive and accessible on:
- Desktop (1920px+)
- Laptop (1024px-1919px)
- Tablet (768px-1023px)
- Mobile (320px-767px)

### CR6: Dark Mode
The website shall default to dark mode (appropriate for ANSI art viewing) with optional light mode toggle.

### CR9: Visual Design Direction

**Inspiration**: FILE_ID.DIZ aesthetic crossed with 1997 print design student portfolio

The site shall embody the spirit of a talented print design student from 1997 who discovered the BBS scene:

- **Fixed-size page sections**: Each major section shall be contained in a fixed-dimension "card" or "page" (like FILE_ID.DIZ's 45x22 character constraint, but scaled for web)
- **Natural scroll**: Pages stack vertically and scroll naturally, but each section feels like a discrete, intentionally-sized artifact
- **Print design sensibility**: Strong grid, deliberate whitespace, typography as art, asymmetric balance
- **BBS/demoscene flavor**: ASCII borders, box-drawing characters as design elements, monospace where it matters
- **Restrained color palette**: Limited colors used with intention (like a 2-color print job with spot color)
- **Texture and grain**: Subtle noise, scanlines, or CRT-inspired effects (tasteful, not overwhelming)
- **Typography mix**: Contrast between pixel/terminal fonts and refined serif/sans-serif
- **Information density**: Dense but organized, like a well-designed NFO file or artpack FILE_ID.DIZ

**Anti-patterns to avoid**:
- Modern "SaaS landing page" feel
- Excessive gradients or glassmorphism
- Generic hero sections with stock illustrations
- Overly clean/sterile minimalism

### CR7: Performance
- Lighthouse Performance score shall be 90+
- First Contentful Paint shall be under 1.5s
- Total bundle size shall be under 200KB gzipped (excluding ANSI art assets)

### CR8: SEO & Metadata
The site shall include:
- Proper Open Graph tags for social sharing
- Twitter Card metadata
- JSON-LD structured data
- Sitemap.xml
- robots.txt

---

## Acceptance Criteria

### AC1: Build & Deploy
- [ ] Site builds successfully with Bun
- [ ] Site deploys to VPS via Kamal
- [ ] Site accessible at https://ansilust.com with valid TLS
- [ ] All pages accessible via their routes

### AC2: Content
- [ ] Homepage displays hero, features, and gallery preview
- [ ] Installation page shows all 7+ install methods
- [ ] At least 5 documentation pages exist with real content
- [ ] Playground renders pasted ANSI art correctly
- [ ] Gallery displays at least 10 curated artworks

### AC3: Functionality
- [ ] Install scripts downloadable at `/install.sh` and `/install.ps1`
- [ ] Dark mode toggle works and persists preference
- [ ] Mobile navigation works correctly
- [ ] Code blocks have copy-to-clipboard functionality

### AC4: Performance
- [ ] Lighthouse Performance score >= 90
- [ ] Lighthouse Accessibility score >= 95

### AC6: Design
- [ ] Each section feels like a distinct "page" or "card" with intentional dimensions
- [ ] Design evokes FILE_ID.DIZ / NFO aesthetic without being a parody
- [ ] Typography mixes terminal/pixel fonts with refined type
- [ ] Color palette is restrained (≤5 colors + grayscale)
- [ ] Site does NOT look like a typical modern SaaS landing page

### AC5: SEO
- [ ] All pages have unique titles and descriptions
- [ ] Open Graph images generated for key pages
- [ ] sitemap.xml accessible at `/sitemap.xml`

---

## Out of Scope

The following are explicitly NOT included in v1:
- User authentication or accounts
- Server-side rendering or API routes
- Comments or community features
- Blog functionality
- Internationalization (i18n)
- Analytics dashboard (use simple solution like Plausible or GoatCounter)
- CMS integration
- SSH/CLI access to website (e.g., `ssh ansilust.com`) - future spec: `.specs/website-ssh/`

---

## Success Metrics

1. **Discoverability**: Site ranks on first page for "ansi art renderer" and "ansilust"
2. **Engagement**: Average session duration > 2 minutes
3. **Conversion**: 10% of visitors click an install command
4. **Performance**: Sub-2-second load time (VPS has adequate global latency for static content)
5. **Uptime**: 99%+ availability on $5 VPS

---

## Future Considerations

For v2 and beyond:
- **SSH/TUI website** (`ssh ansilust.com`) - Browse gallery, view docs, run playground from terminal (separate spec)
- WebAssembly-based playground with full ansilust functionality
- API endpoint for programmatic rendering (separate service)
- User-uploaded gallery submissions
- Animation playback in playground
- Real-time collaborative viewing
- Integration with 16colors.net API for browsing archives

---

## Testing Requirements

### Manual Testing
- [ ] Test all install methods documented actually work
- [ ] Verify playground renders standard ANSI art correctly
- [ ] Check responsive design on real mobile devices
- [ ] Validate dark/light mode transitions

### Automated Testing
- [ ] Playwright e2e tests for critical paths
- [ ] Visual regression tests for gallery items
- [ ] Accessibility audit with axe-core
- [ ] Link checker for broken links

---

## Related Specifications

- **`.specs/publish/`** - Publishing & distribution infrastructure
  - Install script specifications (FR1.7 Bash, FR1.8 PowerShell)
  - Platform support matrix and v1.0.0 scope decisions
  - npm package structure (esbuild-style meta + platform packages)
  - GitHub releases and checksums
- **`.specs/render-utf8ansi/`** - UTF8ANSI renderer (for playground rendering)
- **`.specs/ir/`** - Intermediate representation (for documentation content)

---

## References

- **Kamal 2**: https://kamal-deploy.org/
- **React 19**: https://react.dev/blog/2024/12/05/react-19
- **Tailwind CSS 4**: https://tailwindcss.com/blog/tailwindcss-v4
- **Bun**: https://bun.sh/
- **Traefik (via Kamal)**: https://doc.traefik.io/traefik/
- **ANSI Art Rendering**: See `reference/libansilove/AGENTS.md` for format details
