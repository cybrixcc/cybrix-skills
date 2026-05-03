# cybrix-skills

Entry point for contributors and AI agents working in this repo.

## What this repo is

Official Claude Code plugin marketplace from CYBRIX LLC. Ships one skill,
`cybrix-deploy`, that deploys static sites to the Cybrix hosted service
(`api.cybrix.cc`). The hosted backend lives in `cybrix-app` (private). The
marketing site lives in `cybrix-web`. This repo is the only one a typical
end user ever interacts with.

## Install command (for reference)

```bash
claude plugin marketplace add cybrixcc/cybrix-skills
claude plugin install cybrix-deploy@cybrix-skills
```

## Structure

```
.claude-plugin/marketplace.json     — marketplace catalog (repo IS the marketplace)
plugins/cybrix-deploy/
  .claude-plugin/plugin.json        — plugin manifest (name, version, author)
  skills/cybrix-deploy/SKILL.md     — model-invoked skill instructions
  scripts/deploy.sh                 — bash helper called by the skill
  scripts/test-mock-server.sh       — local Python mock for E2E testing
  scripts/README.md                 — testing instructions
test-fixtures/static-site/          — 3-file HTML fixture for manual E2E tests
validate.sh                         — pre-commit: shellcheck + JSON + SKILL.md YAML
```

## Key rules

- **No pushes without review.** All commits stay local until the maintainer
  pushes manually.
- **Conventional commits.** `feat:`, `fix:`, `chore:`, `docs:` prefixes.
- **validate.sh must pass** before any commit.
- **spec is in the code.** The canonical behaviour is defined in SKILL.md and
  deploy.sh. CONTRIBUTING.md defines scope. There is no separate spec file.

## Versioning policy

`plugin.json` carries the semver version. Bump on every breaking change.
Past versions are installable by Git tag (`claude plugin install cybrix-deploy@cybrix-skills@v0.1.0`
is not yet supported by Claude Code, but the tag exists for future use).

When `cybrix-app` introduces a `/v2` API, bump this repo to `1.0.0` and note
the minimum API version in SKILL.md.

## Distribution channels

| Channel | How |
|---|---|
| Claude Code marketplace | This repo IS a marketplace. `claude plugin marketplace add cybrixcc/cybrix-skills` |
| Agensi | Submit listing manually after launch. |
| claudemarketplaces.com | Auto-aggregated from GitHub. No action needed. |
| SkillsMP | Auto-scraped from GitHub. No action needed. |
| Cybrix dashboard | Shows install command after signup at `app.cybrix.cc`. |

## Out of scope (do not add)

- Premium / paid skills.
- Skill telemetry (usage is measured server-side only).
- Skills that don't talk to the Cybrix backend — deferred to later.
- Env vars beyond `VIBEDEPLOY_API_TOKEN` and `VIBEDEPLOY_API_URL`.

## ADR-S-0001 — marketplace layout (2026-05-03)

The initial commit placed `SKILL.md`, `plugin.json`, and `scripts/` at the
repo root. The Claude Code marketplace spec requires plugins under
`plugins/<name>/` with `.claude-plugin/plugin.json` and skills under
`skills/<name>/SKILL.md`. Restructured before v0.1.0 — the flat layout
would have prevented `claude plugin install` from working.

## Running the end-to-end test

```bash
# Terminal 1
plugins/cybrix-deploy/scripts/test-mock-server.sh 18080

# Terminal 2
export VIBEDEPLOY_API_TOKEN=fake-token
export VIBEDEPLOY_API_URL=http://localhost:18080
plugins/cybrix-deploy/scripts/deploy.sh myproject test-fixtures/static-site
```

Expected: tar → POST → `deployment_id=test-123` → poll pending → poll live → JSON on stdout, exit 0.

## Token lookup order (deploy.sh)

1. `$VIBEDEPLOY_API_TOKEN` env var
2. `~/.config/cybrix/token`
3. `.cybrix/token` in project root
