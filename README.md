# Cybrix — Claude Code Skills

> Tell Claude to deploy. Get a live URL.

Official Claude Code skills from [Cybrix](https://cybrix.cc) — a hosted deployment service for static sites.

## Available skills

### `cybrix-deploy`

Deploys the current project to a live HTTPS URL. Detects your project type (Next.js export, Astro, Vite, Hugo, Eleventy, or plain HTML), runs the build, and uploads the output to Cybrix. You get a live URL on `*.cbrx.cc` in under 60 seconds.

## Install

```bash
claude plugin marketplace add cybrixcc/cybrix-skills
claude plugin install cybrix-deploy@cybrix-skills
```

## First deploy

1. Sign up free at [cybrix.cc](https://cybrix.cc) — no credit card required.
2. Copy your API token from [app.cybrix.cc/dashboard](https://app.cybrix.cc/dashboard).
3. Set it in your shell:
   ```bash
   export VIBEDEPLOY_API_TOKEN=vd_...
   ```
   Or save it permanently to `~/.config/cybrix/token`.
4. Open `claude` in your project directory and say:
   > Deploy this with cybrix

That's it. Claude detects the project type, runs the build, and gives you a live URL.

## Supported project types

Static sites only in this version:

| Framework | Detection |
|---|---|
| Next.js | `"next"` in deps + `output: 'export'` in `next.config.*` |
| Astro | `"astro"` in deps |
| Vite | `"vite"` in deps |
| Hugo | `hugo` binary present |
| Eleventy | `"@11ty/eleventy"` in deps |
| Plain HTML | `index.html` at project root |

Output directories checked in order: `dist`, `out`, `public`, `_site`, `build`, `.output/public`.

Server-side rendering, API routes, and dynamic backends are coming soon.

## Pricing

| Plan | Projects | Domain | Deploys |
|---|---|---|---|
| **Free** | 1 | `*.cbrx.cc` | 50/month |
| **Pro — $9/mo** | 10 | Custom domain | Unlimited |

Pro also includes password protection and Telegram deploy alerts. See [cybrix.cc/pricing](https://cybrix.cc/pricing).

## Troubleshooting

### "VIBEDEPLOY_API_TOKEN is not set"

The skill could not find your API token. Options:

```bash
# Option A — shell export (current session only)
export VIBEDEPLOY_API_TOKEN=vd_...

# Option B — persist to file (all sessions)
mkdir -p ~/.config/cybrix
echo "vd_your_token_here" > ~/.config/cybrix/token
```

Get a free token at [app.cybrix.cc/dashboard](https://app.cybrix.cc/dashboard).

### "Output directory not found"

The build output directory could not be located. Common causes:

- Build has not run yet — run it manually first (`npm run build`, etc.).
- Non-standard output path — tell Claude the exact directory when prompted.
- Wrong working directory — make sure you are in your project root.

Cybrix checks these paths in order: `dist`, `out`, `public`, `_site`, `build`, `.output/public`.

### "Build failed. Fix the error above and try again."

The build command exited with an error. The skill shows the last 40 lines.
Fix the underlying error first, then re-trigger the deploy.

Common causes: missing `node_modules` (`npm install`), unset env vars, type errors.

### "Free tier project limit reached (402)"

You have hit the free plan's 1-project limit. Upgrade at [cybrix.cc/pricing](https://cybrix.cc/pricing) or delete an existing project from your [dashboard](https://app.cybrix.cc/dashboard).

### "Bundle too large"

The gzipped output exceeds 100 MB. Common causes: source maps in production output, `node_modules` accidentally copied to `dist`, unoptimised images or videos. Audit your build config and output directory.

## License

MIT. See [`LICENSE`](./LICENSE).

## Issues and support

- **Skill bugs** — open an issue in this repo.
- **Account / deploy problems** — email `support@cybrix.cc` or open a ticket at [app.cybrix.cc](https://app.cybrix.cc).
- **Contributing** — see [`CONTRIBUTING.md`](./CONTRIBUTING.md).
