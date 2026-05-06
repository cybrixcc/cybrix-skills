# Changelog

All notable changes to cybrix-deploy are documented here.
Format: version, date, changes. Most recent first.

---

## 0.1.3 — 2026-05-06

- CHANGELOG updated with accurate history for all versions

## 0.1.2 — 2026-05-06

- `userConfig` keychain support — token stored in OS keychain via Claude Code plugin system,
  exposed as `CYBRIX_DEPLOY_TOKEN` (first in lookup chain)
- `deploy.sh` reads `CYBRIX_DEPLOY_TOKEN` before `CYBRIX_TOKEN` and file-based sources
- SKILL.md updated to document all 4 token sources in priority order

## 0.1.1 — 2026-05-04

- **Fixed field names**: `project_id` + `file` (was `project_name` + `tarball` — API never accepted the old names)
- **Project creation before deploy**: script now calls `POST /v1/projects` to get a project_id, then deploys
- **Slug availability check**: API call before deploy confirms the slug is available
- **Dashboard URL fixed**: now points to `/dashboard/projects/<id>` (was `/projects/<id>` — 404)
- **Deployed URL fixed**: shows `slug.cbrx.cc` (was CF Pages `*.pages.dev` URL)
- **Token prompt improved**: user can paste token directly in chat without re-running deploy command
- **Error reporting**: anonymous error reports sent to `POST /v1/skill-errors` on `die()`
- **Anonymous error report** on failure — step + HTTP code, no PII
- Removed `/telegram` link from success message (page didn't exist)

## 0.1.0 — 2026-05-03

Initial release.

- Deploy static sites to Cybrix from Claude Code
- Detects Next.js export, Astro, Vite, Hugo, Eleventy, plain HTML
- Polls until live, returns URL on `*.cbrx.cc`
- Token lookup from `CYBRIX_TOKEN` env var, `~/.config/cybrix/token`, `.cybrix/token`
