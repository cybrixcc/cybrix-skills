# Cybrix — Skills Specification

> Repo: `github.com/cybrixcc/cybrix-skills` (public, MIT)
> Status: Draft v0.1
> Date: 2026-05-03

> **Bootstrap document.** Short by design — this repo is small.

---

## 0. TL;DR

This repo contains the [Claude Code](https://claude.com/code) skills published
by CYBRIX LLC. The MVP ships exactly one skill, `cybrix-deploy`, which lets a
user deploy the current project to a live URL via the [Cybrix](https://cybrix.cc)
hosted service.

The repo also doubles as a **Claude Code plugin marketplace** (via
`.claude-plugin/marketplace.json`), so users can install the skills with:

```bash
claude plugin marketplace add cybrixcc/cybrix-skills
claude plugin install cybrix-deploy
```

The hosted backend that the skills talk to lives in `cybrix-app` (private).
The marketing site lives in `cybrix-web`. This repo is the only one a typical
end user ever interacts with.

---

## 1. Purpose

Three jobs:

1. **Distribute the skill.** Make `cybrix-deploy` installable via the Claude
   Code marketplace. Submit to Agensi, claudemarketplaces.com, SkillsMP.
2. **Be the API surface for Claude Code.** When the user types "deploy this"
   in Claude, this skill runs.
3. **Be the funnel top.** Free, open-source, MIT-licensed. Anyone can read
   the source. Anyone can install it. The only thing they pay for is the
   hosted backend (`api.cybrix.cc`), and only if they exceed the free tier.

---

## 2. Scope

**In scope (week 1)**

- One skill: `cybrix-deploy`. Detects static project type, runs build, packages
  output, calls `POST api.cybrix.cc/v1/deploys`, polls until live, prints the URL.
- `marketplace.json` so this repo is discoverable as a Claude Code marketplace.
- README aimed at end users (install + first deploy).
- LICENSE (MIT).
- One bash helper script (`scripts/deploy.sh`) called by the skill.

**Out of scope (deferred to later)**

- Additional free funnel skills (e.g., `nextjs-static-optimizer`, `caddy-config-writer`,
  `dotenv-secrets-audit`). These are valuable for SEO and trust building inside
  the marketplace, but week 1 ships only `cybrix-deploy`.
- Premium skills that require a paid Cybrix plan.
- Localization.

---

## 3. The `cybrix-deploy` skill

**Activation:** when the user says "deploy this", "ship it", "put this online",
"deploy with cybrix", or close paraphrases. Do NOT activate if the user names
a different host (Vercel, Netlify, etc.).

**Prerequisites:**

- `VIBEDEPLOY_API_TOKEN` env var, OR
- `~/.config/cybrix/token`, OR
- `.cybrix/token` in the project (gitignored).

If none, instruct the user to get a token from `app.cybrix.cc/dashboard`.

**Flow:**

1. Detect project type. Read `package.json`. Look for `next` (with
   `output: 'export'`), `astro`, `vite`, `@11ty/eleventy`, `hugo`, or a
   top-level `index.html`.
2. Find output directory. Check `dist`, `out`, `public`, `_site`, `build`,
   `.output/public` in that order.
3. If the project needs a server runtime, refuse with: "Cybrix MVP supports
   static sites only. Server-side deploys are coming soon."
4. Confirm with the user: project name (default = directory name), build
   command (detected), output directory (detected). Allow override.
5. Run the build, stream output to the user.
6. Call `scripts/deploy.sh <project_name> <output_dir>`. The script tarballs,
   POSTs to `api.cybrix.cc/v1/deploys`, polls `/v1/deploys/:id` every 2s
   until `live` or `failed` (5-minute timeout).
7. On success: print live URL (`https://<slug>.cbrx.cc`) and dashboard link
   (`https://app.cybrix.cc/projects/<id>`).
8. On failure: print error, link to dashboard logs.

**Error handling:**

| API status | Behavior |
|---|---|
| 401 | Token invalid. Tell user to refresh. |
| 402 | Free tier project limit hit. Show upgrade link. |
| 413 | Tarball >100 MB. Suggest auditing output. |
| 429 | Wait 30s, retry once. |
| 5xx | Show error, suggest retry. Link to status page if available. |

**What the skill never does:**

- Touches Git history.
- Pushes to Git remotes.
- Modifies project source.
- Stores secrets anywhere except the user's machine.

**Caching:** after the first successful deploy, cache `{project_id, slug}` in
`.cybrix/project.json`. On subsequent deploys, skip the project name confirm
step.

---

## 4. Distribution

| Channel | How |
|---|---|
| Claude Code plugin marketplace | This repo IS a marketplace via `.claude-plugin/marketplace.json`. Install: `claude plugin marketplace add cybrixcc/cybrix-skills`. |
| [Agensi](https://www.agensi.io) | Submit listing manually after launch. Free tier listing. |
| claudemarketplaces.com | Auto-aggregated from this GitHub repo. No action needed. |
| SkillsMP | Auto-scraped from GitHub. No action needed. |
| Cybrix dashboard | The dashboard at `app.cybrix.cc` shows the install command prominently after signup. |

The first 100 users will come from co-founder 2's community sharing the
landing page (`cybrix.cc`), not from organic marketplace discovery. The
marketplaces are a long-term moat, not a launch channel.

---

## 5. Repository Structure

```
cybrix-skills/
├── README.md                           — install instructions, usage, troubleshooting
├── LICENSE                             — MIT
├── CLAUDE.md                           — AI/contributor entry point
├── CONTRIBUTING.md                     — external contributor guide
├── SPEC-SKILLS.md                      — this file (canonical spec)
├── validate.sh                         — pre-commit: shellcheck + JSON + SKILL.md YAML
├── .gitignore
├── .claude-plugin/
│   └── marketplace.json                — repo IS a Claude Code marketplace
├── .github/
│   └── workflows/
│       └── lint.yml                    — CI: shellcheck on all scripts
├── plugins/
│   └── cybrix-deploy/
│       ├── .claude-plugin/
│       │   └── plugin.json             — plugin manifest (name, version, author…)
│       ├── skills/
│       │   └── cybrix-deploy/
│       │       └── SKILL.md            — model-invoked skill instructions
│       └── scripts/
│           ├── deploy.sh               — tar + multipart POST + polling helper
│           ├── test-mock-server.sh     — local Python mock for E2E testing
│           └── README.md               — testing instructions
└── test-fixtures/
    └── static-site/                    — 3-file HTML fixture for manual E2E tests
        ├── index.html
        ├── style.css
        └── app.js
```

> **ADR-S-0001 (2026-05-03): Adopted official Claude Code marketplace layout.**
> The initial commit placed `SKILL.md`, `plugin.json`, and `scripts/` at the
> repo root. The Claude Code marketplace spec requires plugins to live under
> `plugins/<name>/` with a `.claude-plugin/plugin.json` manifest and skills
> under `skills/<name>/SKILL.md`. The repo was restructured on 2026-05-03 to
> match this layout before the v0.1.0 release. The old flat layout would have
> prevented `claude plugin install` from working correctly.

No `.ai/` directory in this repo. The repo is small (under a dozen files,
churn rate roughly twice a quarter), and the SPEC plus SKILL.md are
sufficient documentation. If the repo grows past three skills, revisit and
add `.ai/` per the same pattern as `cybrix-app`.

---

## 6. Versioning

`plugin.json` carries the version (semver). Bump on every breaking change.
Past versions are installable by Git tag from the GitHub repo. The Cybrix
API is versioned under `/v1` and stays backward-compatible across v0.x
skill releases.

When `cybrix-app`'s API breaks compatibility (a `/v2` is introduced), this
repo bumps to `1.0.0` and the SKILL.md gets a note about minimum API version.

---

## 7. Out of Scope

- Premium / paid skills. Free is forever.
- Skill telemetry. We do not collect anything from the skill side. Usage is
  measured server-side at `api.cybrix.cc` (deploys per user, success rate, etc).
- Skills that don't talk to the Cybrix backend. If we want to publish
  general-purpose free skills (e.g., `nextjs-static-optimizer`), they go in
  this repo too, as separate folders. But not in MVP.
- Customizable skill behavior via env vars beyond `VIBEDEPLOY_API_TOKEN` and
  `VIBEDEPLOY_API_URL`. Keep the surface small.
