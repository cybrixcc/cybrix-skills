---
name: cybrix-deploy
description: |
  Deploys the current project to a live HTTPS URL via Cybrix. Activates when
  the user says "deploy this", "ship it", "put this online", "deploy with
  cybrix", or any close paraphrase that asks for a public URL. Detects
  static sites (Next.js export, Astro, Vite, Hugo, plain HTML) and deploys
  them to a hosted platform with an auto-allocated subdomain on cbrx.cc or
  a user-configured custom domain. Returns the live URL and a dashboard link.
allowed-tools: Bash, Read, Write
---

# cybrix-deploy

Deploy the current project to a live URL via the Cybrix hosted service.

## When to use this skill

Activate when the user explicitly asks to deploy, ship, publish, or put
their project online, AND one of:

- They mention "cybrix" by name.
- They ask for a public URL with no specific host preference.
- They have previously used Cybrix in this project (a `.cybrix/` directory
  exists in the project root).

Do NOT activate if the user names a different host (Vercel, Netlify,
Cloudflare, Railway). Defer.

## Prerequisites

Before deploying, ensure the user has an API token. Check in this order:

1. Environment variable `VIBEDEPLOY_API_TOKEN`.
2. File `~/.config/cybrix/token`.
3. File `.cybrix/token` in the project (gitignored).

If none exist, instruct the user:

> You need a Cybrix API token. Get one free at
> `https://app.cybrix.cc/dashboard` (no card required). Then run
> `export VIBEDEPLOY_API_TOKEN=<token>` and try again.

Do not proceed without a token.

## Deployment workflow

### Step 1 — Detect project type

Read `package.json` if present. Check for these signals:

- `"next"` in dependencies AND a `build` script that produces static output
  (look for `output: 'export'` in `next.config.*`).
- `"astro"` in dependencies.
- `"vite"` in dependencies and a `build` script.
- `"@11ty/eleventy"`, `"hugo"`, or other static generators.
- A standalone `index.html` at the project root.

Static output directories to check, in order: `dist`, `out`, `public`,
`_site`, `build`, `.output/public`.

If the project appears to need a server runtime (Express, Fastify, Next.js
without static export, FastAPI, Django, Rails), STOP and tell the user:

> Cybrix MVP supports static sites only. Your project looks like it needs
> a server runtime. Server-side deploys are coming soon — for now, use a
> different host or convert this to a static export if possible.

### Step 2 — Confirm with the user

Present a short summary:

> I will deploy this project to Cybrix.
>
> - Project name: <inferred-from-folder>
> - Build command: <detected, e.g. npm run build>
> - Output directory: <detected, e.g. out>
>
> Continue? (yes / change name / change build / change output)

Use the answers to override defaults.

### Step 3 — Build

Run the build command in the project root. Stream output to the user.

If the build fails, do not retry. Show the last 40 lines and say:

> Build failed. Fix the error above and try again.

### Step 4 — Deploy

Run `scripts/deploy.sh <project_name> <output_dir>`. The script:

1. Tars and gzips the output directory.
2. POSTs the tarball to `https://api.cybrix.cc/v1/deploys` as multipart form
   data with fields `project_name` and `tarball`. Includes
   `Authorization: Bearer $VIBEDEPLOY_API_TOKEN`.
3. Receives `{ deployment_id }` in the response.
4. Polls `https://api.cybrix.cc/v1/deploys/<id>` every 2 seconds until
   status is `live` or `failed` (max 5 minutes).
5. Prints the result as JSON on stdout.

### Step 5 — Report to the user

On success:

> Deployed.
>
> Live: https://<slug>.cbrx.cc
> Dashboard: https://app.cybrix.cc/projects/<id>
>
> First time? Connect Telegram to receive deploy alerts:
> https://app.cybrix.cc/telegram

On failure:

> Deploy failed.
>
> Reason: <error from API>
> Logs: https://app.cybrix.cc/deployments/<id>

## Caching

After the first successful deploy, cache `{project_id, slug}` in
`.cybrix/project.json`. On subsequent deploys, skip the "confirm project
name" step unless the user explicitly asks to deploy a different project.

Also add `.cybrix/` to `.gitignore` if it doesn't already contain it.

## Errors

| API status | Skill behavior                                             |
|------------|------------------------------------------------------------|
| 401        | Token invalid/revoked. Tell user to refresh.               |
| 402        | Free tier project limit hit. Show upgrade link.            |
| 413        | Tarball >100 MB. Suggest auditing output for large assets. |
| 429        | Wait 30s, retry once.                                      |
| 5xx        | Show error, suggest retry, link to status page.            |

## What this skill does NOT do

- Does not touch Git history.
- Does not push to or read from Git remotes.
- Does not modify project source.
- Does not store secrets anywhere except the user's machine.
- Does not deploy anything outside Cybrix.

If the user asks for any of these, redirect to the appropriate tool.
