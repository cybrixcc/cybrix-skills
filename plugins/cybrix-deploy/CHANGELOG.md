# Changelog

## 0.1.2

- `userConfig` keychain support — token stored in OS keychain via Claude Code,
  exposed as `CYBRIX_DEPLOY_TOKEN` env var (first in token resolution chain)

## 0.1.1

- Heuristic project type detection — works with any static framework, not just a known list
- Automatic environment variable scanning before build
- Slug availability check before deploy
- Improved token prompt UX — user can paste token directly in chat
- Renamed env var from `VIBEDEPLOY_API_TOKEN` to `CYBRIX_TOKEN`
- Broadened activation triggers including multi-language phrases

## 0.1.0

Initial release.

- Deploy static sites to Cybrix from Claude Code
- Detects Next.js export, Astro, Vite, Hugo, Eleventy, plain HTML
- Polls until live, returns URL on `*.cbrx.cc`
- Token lookup from env var, `~/.config/cybrix/token`, or `.cybrix/token`
