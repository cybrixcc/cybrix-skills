# Cybrix — Claude Code Skills

> Tell Claude to deploy. Get a live URL.

This is the official Claude Code skill collection from [Cybrix](https://cybrix.cc), a hosted deployment service for static sites.

## Available skills

### `cybrix-deploy`

Deploys the current project to a live HTTPS URL. Detects the project type (Next.js export, Astro, Vite, Hugo, plain HTML), runs the build, packages the output, and uploads it to the Cybrix hosted service. You get a live URL on `*.cbrx.cc` in under 60 seconds.

## Install

```bash
claude plugin marketplace add cybrixcc/cybrix-skills
claude plugin install cybrix-deploy@cybrix-skills
```

## Usage

1. Sign up free at [cybrix.cc](https://cybrix.cc). No credit card required.
2. Copy your API token from [app.cybrix.cc/dashboard](https://app.cybrix.cc/dashboard).
3. Set it in your shell:
   ```bash
   export VIBEDEPLOY_API_TOKEN=vd_...
   ```
   Or save it to `~/.config/cybrix/token`.
4. In your project directory, run `claude` and say:
   > Deploy this project with cybrix

That's it.

## Supported project types

This version supports static sites only:

- Next.js with `output: 'export'`
- Astro
- Vite static builds
- Hugo
- Eleventy
- Plain HTML (any directory with an `index.html`)

Server-side rendering, API routes, and dynamic backends are coming soon.

## Pricing

- **Free** — 1 project, `*.cbrx.cc` subdomain, 50 deploys/month.
- **Pro $9/month** — 10 projects, custom domain, password protection, Telegram deploy alerts, unlimited deploys.

See [cybrix.cc/pricing](https://cybrix.cc/pricing) for details.

## Troubleshooting

### "VIBEDEPLOY_API_TOKEN is not set"

The skill could not find your API token. Set it with:

```bash
export VIBEDEPLOY_API_TOKEN=vd_...
```

Or save it permanently to `~/.config/cybrix/token` (the file should contain
just the token, no newlines except a trailing one):

```bash
mkdir -p ~/.config/cybrix
echo "vd_your_token_here" > ~/.config/cybrix/token
```

Get a free token at [app.cybrix.cc/dashboard](https://app.cybrix.cc/dashboard).

### "Output directory not found"

The script could not locate your build output. Common causes:

- The build has not run yet — run it manually first (e.g. `npm run build`).
- The output directory has a non-standard name. Cybrix checks `dist`, `out`,
  `public`, `_site`, `build`, `.output/public` in that order.
- You are running from the wrong directory. Make sure you are in your project
  root.

When prompted, you can tell Claude the exact output directory name.

### "Build failed. Fix the error above and try again."

The build command returned a non-zero exit code. The skill prints the last 40
lines of build output. Fix the underlying build error first, then re-trigger
the deploy.

Common build errors:

- Missing dependencies — run `npm install` (or `yarn`, `pnpm install`).
- Environment variables not set — check your `.env` file.
- Type errors — fix them or confirm that the build command tolerates them
  (`tsc --noEmit false`, `next build --no-lint`, etc.).

### "Free tier project limit reached (402)"

You have hit the free plan's 1-project limit. Either upgrade at
[cybrix.cc/pricing](https://cybrix.cc/pricing) or delete an existing project
in your [dashboard](https://app.cybrix.cc/dashboard).

### "Bundle too large (413 / local check)"

The gzipped tarball of your output directory exceeds 100 MB. Common causes:

- Source maps included in production output — disable them in your build config.
- Node modules accidentally included — make sure your build does not copy
  `node_modules` into the output directory.
- Large static assets (videos, unoptimised images) — compress or move to a CDN.

## License

MIT. See [`LICENSE`](./LICENSE).

## Source

This repo: [github.com/cybrixcc/cybrix-skills](https://github.com/cybrixcc/cybrix-skills).
The hosted backend that the skills talk to is closed-source and operated by CYBRIX LLC.

## Issues and support

- Bugs in the skill: open an issue here.
- Account or deploy problems: email `support@cybrix.cc` or open a ticket at [app.cybrix.cc](https://app.cybrix.cc).
