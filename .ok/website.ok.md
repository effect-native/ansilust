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
- TRUE: Current repository reality includes install-script artifacts at `scripts/install.sh` and `scripts/install.ps1` that a future website may serve.
- TRUE: Current repository reality includes a root-level `Dockerfile` and `.dockerignore`, but no checked-in `website/` application directory or `website/config/deploy.yml`.
- TRUE: Current repository reality includes `.github/workflows/release.yml`, but no checked-in website-specific deployment workflow.
- TRUE: Current repository evidence does not show a static site implementation, homepage, install page, docs site, playground, gallery, or ansilust.com deployment surface.
- TRUE: `.specs/website/**` may describe a future static marketing and documentation site, but only assertions promoted here are constitutional truth for website reconciliation.

## States We Do Not Want

- FALSE: Spec-only website promises such as a root `website/` app, Kamal deploy flow, VPS hosting, homepage sections, `/install`, `/docs/*`, `/playground`, `/gallery`, or ansilust.com availability are treated as current reality without checked-in evidence.
- FALSE: Root deployment artifacts owned by other surfaces are mistaken for proof that the website spec is implemented end to end.
- FALSE: Install scripts existing in `scripts/` are treated as evidence that website routing, website hosting, or website UX is already shipped.
- FALSE: Design direction, Lighthouse targets, SEO goals, or responsive-layout requirements from `.specs/website/**` override the current repository state captured here.

## Required Governance Rules

- TRUE: Changes that add or remove a checked-in website app, website deployment wiring, website routes, or website-hosted install-script behavior require updating this file in the same reconciliation loop.
- TRUE: Website completion claims must be backed by checked-in application, config, workflow, or deployment artifacts; spec prose alone is not sufficient evidence.
- TRUE: Downstream orchestration may rely only on website guarantees declared TRUE here.
- TRUE: Website scope remains binary: a capability is either evidenced and governed here or it is still future, absent, or unevidenced.
