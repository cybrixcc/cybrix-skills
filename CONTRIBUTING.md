# Contributing

Thanks for your interest. This is a small, focused repo — we welcome bug reports and small fixes.

## What belongs here

- Bug fixes in `plugins/cybrix-deploy/scripts/deploy.sh`
- Improvements to `plugins/cybrix-deploy/skills/cybrix-deploy/SKILL.md`
- Fixes to `README.md` or other documentation
- New skills that talk to the Cybrix backend (open an issue first)

## What does not belong here

- Changes to the hosted backend (`api.cybrix.cc`) — that is a separate private repo.
- Support for non-static project types in this version — coming in a future release.
- Anything that requires a paid Cybrix plan or adds telemetry to the skill.

## Setup

```bash
git clone https://github.com/cybrixcc/cybrix-skills.git
cd cybrix-skills
```

No build step. The skill is pure bash and markdown.

## Validate before opening a PR

```bash
./validate.sh
```

This runs shellcheck on all scripts, validates both JSON manifests, and checks
the SKILL.md frontmatter. All checks must pass.

## Testing the deploy script

See [`plugins/cybrix-deploy/scripts/README.md`](plugins/cybrix-deploy/scripts/README.md)
for instructions on running the mock server end-to-end test.

## Commit style

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(skill): add support for SvelteKit static adapter
fix(deploy.sh): handle 429 retry correctly on WSL
chore(ci): pin shellcheck to 0.10
docs: clarify token setup in README
```

## Opening a pull request

1. Fork the repo and create a branch from `master`.
2. Make your change and run `./validate.sh`.
3. Open a PR with a short description of what and why.
4. A maintainer will review within a few business days.

Small, focused PRs are reviewed faster than large ones.
