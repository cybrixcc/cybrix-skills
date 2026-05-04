# Cybrix — deploy from Claude Code

Cybrix is a hosting service for static sites. This repo adds a
**cybrix-deploy** skill to [Claude Code](https://claude.ai/code) so you can
deploy by saying **"deploy this with cybrix"** in the chat — Claude runs the
build, packages the output, uploads it, and hands you a live HTTPS URL in
under 60 seconds.

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
export CYBRIX_TOKEN=vd_your_token_here
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

Claude detects the project type, scans for environment variables the build
needs, confirms everything with you, runs the build, and deploys. You get
back:

```
Deployed.

Live:      https://my-project-abc123.cbrx.cc
Dashboard: https://app.cybrix.cc/projects/abc123
```

---

## Supported project types

Static sites only. Claude uses heuristic detection — it looks for signals
rather than matching against a fixed list of frameworks, so it works with
any static site generator.

**Detected as static** (deploys automatically): Next.js with
`output: 'export'`, Astro, Vite, Hugo, Eleventy, Jekyll, Zola, plain HTML
directories, and anything else that produces a static output folder.

**Detected as server** (refused with explanation): projects with a
`Dockerfile`, Go/Python/Rust/Ruby/Java/C# server entry points, or a
`package.json` `start` script that runs a Node server. Claude names the
specific signal it found and suggests alternatives.

**Not sure?** You can always tell Claude to deploy anyway — the detection
is a heuristic, not a hard gate.

Output directories checked in order: `dist`, `out`, `public`, `_site`, `build`, `.output/public`.

## Environment variables

Before running the build, Claude scans your project for environment
variables the build will need:

- Reads `.env`, `.env.local`, `.env.production`, `.env.example`
- Greps source files for `process.env.X` and `import.meta.env.X` references
- Shows you what it found and asks how to handle it:
  - **Paste here** — values are sent encrypted with the deploy
  - **Set later** — configure in the Cybrix dashboard after deploy
  - **Skip** — build may fail or the site may not work correctly

Claude warns you if a variable is used in code but missing from your `.env`
files, and refuses to forward anything that looks like a private secret
(`*_SECRET`, `*_PRIVATE_KEY`, `DATABASE_URL`) inside a client-bundle prefix
(`NEXT_PUBLIC_*`, `VITE_*`, etc.) without your explicit confirmation.

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

### Token not found — "CYBRIX_TOKEN is not set"

The skill looks for your token in three places, in order:
1. The `CYBRIX_TOKEN` environment variable
2. `~/.config/cybrix/token`
3. `.cybrix/token` in the project root

If none are found, set it with `export CYBRIX_TOKEN=vd_...` or save
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
