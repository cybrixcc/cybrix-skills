#!/usr/bin/env bash
# Minimal HTTP mock server for testing deploy.sh without a real API.
#
# Requires Python 3 (standard on macOS 12+, most Linux distros, and WSL).
# Falls back to a usage message if Python 3 is not available.
#
# Simulates:
#   POST /v1/deploys              → { "deployment_id": "test-123" }
#   GET  /v1/deploys/test-123     → "pending" on first poll, "live" on second
#
# Usage:
#   scripts/test-mock-server.sh [port]
#
# In another terminal:
#   export CYBRIX_TOKEN=fake-token
#   export CYBRIX_API_URL=http://localhost:18080
#   scripts/deploy.sh myproject ./test-fixtures/static-site

set -euo pipefail

PORT="${1:-18080}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 is required for the mock server but was not found." >&2
  exit 1
fi

echo "[mock] starting on http://localhost:${PORT}"

# Python handles HTTP correctly (Content-Length, chunked, binary bodies).
# The poll_count file lets bash track state across requests without a
# persistent Python process holding global state.
POLL_STATE="$(mktemp)"
echo 0 > "$POLL_STATE"
export POLL_STATE PORT

python3 - "$PORT" "$POLL_STATE" <<'PYEOF'
import http.server
import json
import sys
import os

port = int(sys.argv[1])
state_file = sys.argv[2]

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[mock] {fmt % args}", file=sys.stderr)

    def send_json(self, body, code=200):
        payload = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_POST(self):
        # Consume body so the connection closes cleanly
        length = int(self.headers.get("Content-Length", 0))
        self.rfile.read(length)
        if self.path == "/v1/deploys":
            self.send_json({"deployment_id": "test-123"})
        else:
            self.send_json({"error": "not found"}, 404)

    def do_GET(self):
        if self.path == "/v1/deploys/test-123":
            with open(state_file) as f:
                count = int(f.read().strip())
            count += 1
            with open(state_file, "w") as f:
                f.write(str(count))
            if count < 2:
                self.send_json({"status": "pending", "id": "test-123"})
            else:
                self.send_json({
                    "status": "live",
                    "id": "test-123",
                    "slug": "test-abc",
                    "url": "https://test-abc.cbrx.cc"
                })
                # Shutdown after serving the final live response
                import threading
                threading.Timer(0.1, server.shutdown).start()
        else:
            self.send_json({"error": "not found"}, 404)

server = http.server.HTTPServer(("127.0.0.1", port), Handler)
print(f"[mock] listening on port {port} — will exit after deploy completes", file=sys.stderr)
server.serve_forever()
PYEOF

rm -f "$POLL_STATE"
