# cybrix-skills

Claude Code entry point for contributors and AI agents working in this repo.

## What this repo is

Official Claude Code plugin marketplace from CYBRIX LLC. Ships one skill,
`cybrix-deploy`, that deploys static sites to the Cybrix hosted service.

## Structure

```
.claude-plugin/marketplace.json     — marketplace catalog (repo IS the marketplace)
plugins/cybrix-deploy/
  .claude-plugin/plugin.json        — plugin manifest
  skills/cybrix-deploy/SKILL.md     — model-invoked skill instructions
  scripts/deploy.sh                 — bash helper called by the skill
  scripts/test-mock-server.sh       — local mock for testing deploy.sh
  scripts/README.md                 — testing instructions
test-fixtures/static-site/          — 3-file HTML fixture for manual E2E tests
validate.sh                         — pre-commit check (shellcheck + JSON + YAML)
SPEC-SKILLS.md                      — canonical spec; fix implementation not spec
```

## Key rules

- **SPEC-SKILLS.md is canonical.** If code contradicts the spec, fix the code.
- **No pushes without review.** All commits stay local until the maintainer
  pushes manually.
- **Conventional commits.** `feat:`, `fix:`, `chore:`, `docs:` prefixes.
- **validate.sh must pass** before any commit.

## Running the end-to-end test

```bash
# Terminal 1
plugins/cybrix-deploy/scripts/test-mock-server.sh 18080

# Terminal 2
export VIBEDEPLOY_API_TOKEN=fake-token
export VIBEDEPLOY_API_URL=http://localhost:18080
plugins/cybrix-deploy/scripts/deploy.sh myproject test-fixtures/static-site
```

## Token lookup order (deploy.sh)

1. `$VIBEDEPLOY_API_TOKEN` env var
2. `~/.config/cybrix/token`
3. `.cybrix/token` in project root
