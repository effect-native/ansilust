# Website OK

This file governs ansilust's current website reality. It translates `.specs/website/` into binary constitutional truth so reconciliation stays anchored to checked-in repository evidence instead of aspirational product and deployment prose.

## Governing References

- `.specs/website/instructions.md`
- `.specs/website/requirements.md`
- `scripts/install.sh`
- `scripts/install.ps1`
- `Dockerfile`
- `.dockerignore`
- `.github/workflows/release.yml`

## Ideal End State

- TRUE: `.specs/website/` is an active spec area that now has constitutional coverage in this file.
- TRUE: `.specs/website/instructions.md` and `.specs/website/requirements.md` describe a broader future website, and this file promotes only checked-in repository evidence into present-tense truth.
- TRUE: Current repository reality includes a checked-in `website/` application directory with `website/package.json` declaring Bun as the package manager plus placeholder `dev` and `build` scripts that currently shell out to `bun --version`.
- TRUE: Current repository reality includes checked-in route files at `website/app/page.tsx`, `website/app/install/page.tsx`, and `website/app/docs/page.tsx`, each rendering a minimal text baseline for `/`, `/install`, and `/docs` rather than the full spec-defined experience.
- TRUE: Current repository reality includes owned website crawl assets at `website/public/robots.txt` and `website/public/sitemap.xml`, and the sitemap currently lists only `/`, `/docs`, and `/install`.
- TRUE: Current repository reality includes repository-owned sample and gallery asset baselines at `website/public/samples/index.json`, `website/public/samples/owned/hello-ansilust.ans`, `website/public/gallery/index.json`, and `website/public/gallery/owned/gallery-title-card.ans`.
- TRUE: Current repository reality includes `website/seo-baseline.test.ts`, which asserts the minimum owned `robots.txt` and `sitemap.xml` crawl baseline and explicitly excludes `/samples/` and `/gallery/` from sitemap publication.
- TRUE: Current repository reality still includes install-script artifacts at `scripts/install.sh` and `scripts/install.ps1` that a website may surface.
- TRUE: Current repository reality includes a root-level `Dockerfile`, `.dockerignore`, and `.github/workflows/release.yml`, but no checked-in website-specific deployment workflow or `website/config/deploy.yml`.
- TRUE: Current repository evidence still does not show checked-in website docs content trees such as `website/content/docs/**`, a checked-in `/playground` route, or ansilust.com deployment/runtime evidence.
- TRUE: `.specs/website/**` may describe a future static marketing and documentation site, but only assertions promoted here are constitutional truth for website reconciliation.

## States We Do Not Want

- FALSE: The website is described as absent or pre-app now that a checked-in `website/` app, minimal routes, public assets, and crawl baseline files exist in the repository.
- FALSE: Root deployment artifacts owned by other surfaces are mistaken for proof that the website spec is implemented end to end.
- FALSE: Install scripts existing in `scripts/` are treated as evidence that website hosting, install UX, or script download flows are fully shipped.
- FALSE: Checked-in Bun, React, Tailwind, app-route, sample-asset, or sitemap artifacts are overstated as proof that spec-defined design, content depth, docs IA, gallery UX, or deployment topology are complete.
- FALSE: Spec-defined routes and content promises such as homepage hero/install/gallery sections, `/docs/getting-started`, `/docs/cli`, `/docs/formats`, `/docs/sauce`, `/docs/ir`, `/docs/contributing`, `/playground`, `/gallery`, or ansilust.com availability are treated as present-tense capabilities without matching checked-in implementation evidence.
- FALSE: Sample and gallery assets being present under `website/public/**` are treated as evidence that those routes are published, indexed, or included in the current sitemap baseline.
- FALSE: Spec-defined behavior and quality targets such as platform detection, copy-to-clipboard, mobile navigation, dark-mode persistence, SEO metadata breadth, Lighthouse thresholds, or responsive card/page design are treated as current guarantees without matching checked-in implementation evidence.
- FALSE: Design direction, Lighthouse targets, SEO goals, or responsive-layout requirements from `.specs/website/**` override the current repository state captured here.

## Required Governance Rules

- TRUE: Changes that add or remove checked-in website app files, website deployment wiring, website routes, crawl-baseline files, or website-hosted asset inventories require updating this file in the same reconciliation loop.
- TRUE: Website completion claims must be backed by checked-in application, config, workflow, test, or deployment artifacts; spec prose alone is not sufficient evidence.
- TRUE: Claims about website build stack, page inventory, asset locations, install-script hosting routes, sitemap publication, robots policy, SEO surfaces, or deployment topology must be backed by checked-in website-specific files rather than cross-surface root artifacts.
- TRUE: Downstream orchestration may rely only on website guarantees declared TRUE here.
- TRUE: Website scope remains binary: a capability is either evidenced and governed here or it is still future, partial, absent, or unevidenced.
