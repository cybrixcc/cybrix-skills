# Cybrix — Claude Code Skills

> Tell Claude to deploy. Get a live URL.

This is the official Claude Code skill collection from [Cybrix](https://cybrix.cc), a hosted deployment service for static sites.

## Available skills

### `cybrix-deploy`

Deploys the current project to a live HTTPS URL. Detects the project type (Next.js export, Astro, Vite, Hugo, plain HTML), runs the build, packages the output, and uploads it to the Cybrix hosted service. You get a live URL on `*.cbrx.cc` in under 60 seconds.

## Install

```bash
claude plugin marketplace add cybrixcc/cybrix-skills
claude plugin install cybrix-deploy
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

This MVP supports static sites only:

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

## License

MIT. See [`LICENSE`](./LICENSE).

## Source

This repo: [github.com/cybrixcc/cybrix-skills](https://github.com/cybrixcc/cybrix-skills).
The hosted backend that the skills talk to is closed-source and operated by CYBRIX LLC.

## Issues and support

- Bugs in the skill: open an issue here.
- Account or deploy problems: email `support@cybrix.cc` or open a ticket at [app.cybrix.cc](https://app.cybrix.cc).
