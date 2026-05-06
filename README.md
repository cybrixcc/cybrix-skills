# Cybrix — deploy from Claude Code

[![Version](https://img.shields.io/badge/version-0.1.2-orange)](https://github.com/cybrixcc/cybrix-skills/blob/master/plugins/cybrix-deploy/.claude-plugin/plugin.json)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-7c3aed)](https://claude.ai/code)
[![Free tier](https://img.shields.io/badge/free%20tier-no%20credit%20card-22c55e)](https://cybrix.cc)

**Tell Claude to deploy. Get a live HTTPS URL in under 60 seconds.**

Cybrix is a hosting service for static sites. This plugin adds a `cybrix-deploy` skill to [Claude Code](https://claude.ai/code) — Claude runs the build, packages the output, uploads it to Cloudflare's edge network, and hands you a live URL directly in the chat.

No config files. No CI setup. No dashboards. Just talk.

```
> Deploy this with cybrix

✓ Detected static site (Next.js export)
✓ Building... done in 8s
✓ Uploading to Cybrix... done
✓ Live at: https://my-site.cbrx.cc

  Your site is live. Connect a custom domain in dashboard.
```

---

## Quick start

**1. Install the skill** — run inside Claude Code:

```
/plugin marketplace add cybrixcc/cybrix-skills
/plugin install cybrix-deploy@cybrix-skills
```

**2. Get a free API token** at [app.cybrix.cc](https://app.cybrix.cc) — no credit card required.

**3. Set your token:**

```bash
export CYBRIX_TOKEN=vd_your_token_here
```

To persist across sessions:

```bash
mkdir -p ~/.config/cybrix && echo "vd_your_token_here" > ~/.config/cybrix/token
```

**4. Open Claude Code in your project and say:**

```
Deploy this with cybrix
```

---

## What Claude does

1. Detects your project type (Next.js, Astro, Vite, Hugo, Eleventy, plain HTML, and more)
2. Scans for environment variables your build needs — asks how to handle each one
3. Runs the build and locates the output directory
4. Uploads to Cybrix and polls until the site is live
5. Returns the live URL directly in the chat

Works in any language — *"deploy this"*, *"задеплой это"*, *"despliega esto"* — Claude understands the intent.

---

## Supported project types

Static sites only. Detection is heuristic — works with any framework that produces a static output folder.

| Result   | Examples                                                                            |
|----------|-------------------------------------------------------------------------------------|
| [deploy] | Next.js (`output: 'export'`), Astro, Vite, Hugo, Eleventy, Jekyll, Zola, plain HTML |
| [skip]   | Dockerfile present, Node/Go/Python/Ruby server entry points                         |

Output directories checked in order: `dist`, `out`, `public`, `_site`, `build`, `.output/public`.

---

## Environment variables

Before running the build, Claude scans your project for environment variables the build will need:

- Reads `.env`, `.env.local`, `.env.production`, `.env.example`
- Greps source files for `process.env.X` and `import.meta.env.X` references
- Shows you what it found and asks how to handle each:
  - **Paste here** — sent encrypted with the deploy
  - **Set later** — configure in the Cybrix dashboard after deploy
  - **Skip** — build may fail or the site may not work correctly

Claude warns if a variable is used in code but missing from your env files, and refuses to forward anything that looks like a private secret (`*_SECRET`, `*_PRIVATE_KEY`, `DATABASE_URL`) inside a client-bundle prefix (`NEXT_PUBLIC_*`, `VITE_*`) without your explicit confirmation.

---

## Token lookup order

The skill looks for your token in this order:

1. `$CYBRIX_TOKEN` environment variable
2. `~/.config/cybrix/token`
3. `.cybrix/token` in the project root

---

## Pricing

| Plan        | Projects | Domain        | History  |
|-------------|----------|---------------|----------|
| Free        | 1        | `*.cbrx.cc`   | 7 days   |
| Pro — $9/mo | 10       | Custom domain | 90 days + rollback |

Pro also includes Telegram deploy alerts.
→ [cybrix.cc/pricing](https://cybrix.cc/pricing)

---

## Troubleshooting

<details>
<summary><strong>"CYBRIX_TOKEN is not set"</strong></summary>

Set it with `export CYBRIX_TOKEN=vd_...` or save to `~/.config/cybrix/token` as shown above.
</details>

<details>
<summary><strong>"Output directory not found"</strong></summary>

Run your build manually first (`npm run build`, `hugo`, etc.) to confirm it works, then retry. If the output path is non-standard, tell Claude the correct path when prompted.
</details>

<details>
<summary><strong>"Build failed"</strong></summary>

Claude shows the last 40 lines of output. Fix the error (missing `node_modules`, missing env vars, TypeScript errors) then say "deploy again".
</details>

<details>
<summary><strong>"Free tier project limit reached"</strong></summary>

Free plan is limited to 1 project. Upgrade at [cybrix.cc/pricing](https://cybrix.cc/pricing) or delete an existing project from your [dashboard](https://app.cybrix.cc/dashboard).
</details>

<details>
<summary><strong>"Bundle too large"</strong></summary>

Gzipped output exceeds 100 MB. Common causes: source maps in production output, `node_modules` accidentally in `dist`, large unoptimised assets.
</details>

---

## Support

- Bug in the skill — [open an issue](https://github.com/cybrixcc/cybrix-skills/issues)
- Account or deploy problem — `support@cybrix.cc` or [app.cybrix.cc](https://app.cybrix.cc)
- Contributing a fix — see [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## License

MIT — see [LICENSE](./LICENSE).
