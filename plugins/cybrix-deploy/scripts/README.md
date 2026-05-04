# scripts/

## deploy.sh

Main deploy helper called by the `cybrix-deploy` skill.

```
deploy.sh <project_name> <output_dir>
```

**Required (one of):**
- `CYBRIX_TOKEN` env var, or
- `~/.config/cybrix/token`, or
- `.cybrix/token` in the project root

**Optional:**
- `CYBRIX_API_URL` — override API base URL (default: `https://api.cybrix.cc`)

The script tarballs `<output_dir>`, POSTs to `POST /v1/deploys`, then polls
`GET /v1/deploys/<id>` every 2 seconds until status is `live` or `failed`
(5-minute timeout). On success it prints the full API response JSON to stdout.

## test-mock-server.sh

A local netcat-based mock that simulates the Cybrix API for integration
testing without hitting a real endpoint.

### How to run the end-to-end mock test

**Terminal 1 — start the mock:**

```bash
scripts/test-mock-server.sh 18080
```

**Terminal 2 — run deploy against the mock:**

```bash
export CYBRIX_TOKEN=fake-token
export CYBRIX_API_URL=http://localhost:18080
scripts/deploy.sh my-test-site ../../test-fixtures/static-site
```

Expected output in terminal 2:
```
[cybrix] packing ../../test-fixtures/static-site
[cybrix] bundle: 0 MB
[cybrix] uploading to http://localhost:18080
[cybrix] deployment_id=test-123
[cybrix] waiting for deployment to go live...
{"status":"live","id":"test-123","slug":"test-abc","url":"https://test-abc.cbrx.cc"}
```

The mock returns `pending` on the first poll and `live` on the second, which
exercises the polling loop.

### Notes

- Requires `nc` (netcat). On macOS it is installed by default. On Debian/Ubuntu:
  `apt-get install netcat-openbsd`. On Alpine: `apk add netcat-openbsd`.
- The mock handles one request at a time (sequential, no concurrency).
- Run `shellcheck scripts/*.sh` (or let CI do it) to catch shell issues.
