# Cybrix — deploy from Claude Code

Cybrix is a hosting service for static sites. This repo adds a `/cybrix-deploy`
skill to [Claude Code](https://claude.ai/code) so you can deploy by saying
**"deploy this with cybrix"** in the chat — Claude runs the build, packages the
output, uploads it, and hands you a live HTTPS URL in under 60 seconds.

No config files. No CI setup. Just talk to Claude.

---

## Prerequisites

- [Claude Code](https://claude.ai/code) installed (`npm install -g @anthropic-ai/claude-code`)
- A Cybrix account — free at [cybrix.cc](https://cybrix.cc), no credit card required

---

## Install the skill

```bash
claude plugin marketplace add cybrixcc/cybrix-skills
claude plugin install cybrix-deploy@cybrix-skills
```

---

## First deploy

**Step 1.** Get your API token from [app.cybrix.cc/dashboard](https://app.cybrix.cc/dashboard).

**Step 2.** Add it to your shell (once):

```bash
export VIBEDEPLOY_API_TOKEN=vd_your_token_here
```

To persist it across sessions, save it to a file instead:

```bash
mkdir -p ~/.config/cybrix
echo "vd_your_token_here" > ~/.config/cybrix/token
```

**Step 3.** Go to your project directory and open Claude Code:

```bash
cd my-project
claude
```

**Step 4.** Say:

> Deploy this with cybrix

Claude will detect the project type, confirm the build command and output
directory with you, run the build, and deploy. You get back:

```
Deployed.

Live:      https://my-project-abc123.cbrx.cc
Dashboard: https://app.cybrix.cc/projects/abc123
```

---

## Supported project types

Static sites only in this version:

| Framework  | How Cybrix detects it                                          |
|------------|----------------------------------------------------------------|
| Next.js    | `"next"` in package.json + `output: 'export'` in next.config   |
| Astro      | `"astro"` in package.json                                      |
| Vite       | `"vite"` in package.json                                       |
| Hugo       | `hugo` binary in PATH                                          |
| Eleventy   | `"@11ty/eleventy"` in package.json                             |
| Plain HTML | `index.html` at the project root                               |

Output directories checked in order: `dist`, `out`, `public`, `_site`, `build`, `.output/public`.

If your project needs a server runtime (Next.js without static export, Express,
FastAPI, etc.) Claude will tell you — server-side deploys are coming soon.

---

## Pricing

| Plan            | Projects | Domain        | Deploys/month |
|-----------------|----------|---------------|---------------|
| **Free**        | 1        | `*.cbrx.cc`   | 50            |
| **Pro — $9/mo** | 10       | Custom domain | Unlimited     |

Pro also includes password protection and Telegram deploy alerts.
Full details at [cybrix.cc/pricing](https://cybrix.cc/pricing).

---

## Troubleshooting

### Token not found — "VIBEDEPLOY_API_TOKEN is not set"

The skill looks for your token in three places, in order:
1. The `VIBEDEPLOY_API_TOKEN` environment variable
2. `~/.config/cybrix/token`
3. `.cybrix/token` in the project root

If none are found, set it with `export VIBEDEPLOY_API_TOKEN=vd_...` or save
it to `~/.config/cybrix/token` as shown in the install steps above.

### "Output directory not found"

The build output could not be located. Most common causes:

- **Build hasn't run yet** — run it manually first (`npm run build`, `hugo`, etc.) to confirm it works, then let Claude retry.
- **Non-standard output path** — when Claude asks to confirm the output directory, type the correct path.
- **Wrong working directory** — make sure you opened Claude Code from your project root, not a subdirectory.

### "Build failed. Fix the error above and try again."

The build command returned an error. Claude shows the last 40 lines.
Fix the error first, then say "deploy again".

Common causes: missing `node_modules` (run `npm install`), missing env vars in `.env`, TypeScript errors.

### "Free tier project limit reached"

You're on the free plan (1 project). Either upgrade at [cybrix.cc/pricing](https://cybrix.cc/pricing)
or delete an existing project from your [dashboard](https://app.cybrix.cc/dashboard).

### "Bundle too large"

The gzipped output exceeds 100 MB. Common causes: source maps in production output,
`node_modules` accidentally in `dist`, large unoptimised images or videos.
Check your build config and audit the output directory.

---

## License

MIT. See [`LICENSE`](./LICENSE).

## Issues and support

| Type                      | Where                                                         |
|---------------------------|---------------------------------------------------------------|
| Bug in the skill          | Open an issue in this repo                                    |
| Account or deploy problem | `support@cybrix.cc` or [app.cybrix.cc](https://app.cybrix.cc) |
| Contributing a fix        | See [CONTRIBUTING.md](./CONTRIBUTING.md)                      |
