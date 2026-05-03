#!/usr/bin/env bash
# Tar a build output directory, POST it to the Cybrix API,
# poll for completion, print result as JSON.
#
# Usage:
#   deploy.sh <project_name> <output_dir>
#
# Required (one of):
#   VIBEDEPLOY_API_TOKEN   API token from app.cybrix.cc/dashboard
#   ~/.config/cybrix/token
#   .cybrix/token          in the project root (gitignored)
#
# Optional:
#   VIBEDEPLOY_API_URL     defaults to https://api.cybrix.cc

set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────

die() { echo "[cybrix] error: $*" >&2; exit 1; }

# ── args ─────────────────────────────────────────────────────────────────────

PROJECT_NAME="${1:?usage: deploy.sh <project_name> <output_dir>}"
OUTPUT_DIR="${2:?usage: deploy.sh <project_name> <output_dir>}"

# ── token resolution ─────────────────────────────────────────────────────────

if [[ -z "${VIBEDEPLOY_API_TOKEN:-}" ]]; then
  if [[ -r "${HOME}/.config/cybrix/token" ]]; then
    VIBEDEPLOY_API_TOKEN="$(cat "${HOME}/.config/cybrix/token")"
  elif [[ -r ".cybrix/token" ]]; then
    VIBEDEPLOY_API_TOKEN="$(cat ".cybrix/token")"
  else
    die "VIBEDEPLOY_API_TOKEN is not set.
  Set it with: export VIBEDEPLOY_API_TOKEN=<token>
  Or save your token to ~/.config/cybrix/token
  Get one free at https://app.cybrix.cc/dashboard"
  fi
fi

# ── config ───────────────────────────────────────────────────────────────────

API_URL="${VIBEDEPLOY_API_URL:-https://api.cybrix.cc}"

# ── preflight ────────────────────────────────────────────────────────────────

[[ -d "$OUTPUT_DIR" ]] || die "output directory not found: $OUTPUT_DIR"
command -v curl >/dev/null 2>&1 || die "curl is required but not found"
command -v tar  >/dev/null 2>&1 || die "tar is required but not found"

# ── package ──────────────────────────────────────────────────────────────────

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL="$TMP_DIR/bundle.tar.gz"

echo "[cybrix] packing $OUTPUT_DIR"
tar -czf "$TARBALL" -C "$OUTPUT_DIR" .

SIZE_BYTES="$(wc -c < "$TARBALL" | tr -d ' ')"
SIZE_MB=$(( SIZE_BYTES / 1024 / 1024 ))
if (( SIZE_MB > 100 )); then
  die "bundle too large: ${SIZE_MB} MB (limit 100 MB). Audit your output directory for large assets."
fi
echo "[cybrix] bundle: ${SIZE_MB} MB"

# ── upload ───────────────────────────────────────────────────────────────────

echo "[cybrix] uploading to $API_URL"
HTTP_RESPONSE="$(
  curl -sS --fail-with-body \
    -w '\n__HTTP_CODE__:%{http_code}' \
    -X POST "$API_URL/v1/deploys" \
    -H "Authorization: Bearer $VIBEDEPLOY_API_TOKEN" \
    -F "project_name=$PROJECT_NAME" \
    -F "tarball=@$TARBALL"
)" || true

HTTP_CODE="${HTTP_RESPONSE##*$'\n'__HTTP_CODE__:}"
RESPONSE_BODY="${HTTP_RESPONSE%$'\n'__HTTP_CODE__:*}"

case "$HTTP_CODE" in
  200|201|202) ;;
  401) die "authentication failed (401). Refresh your token at https://app.cybrix.cc/dashboard" ;;
  402) die "free tier project limit reached (402). Upgrade at https://cybrix.cc/pricing" ;;
  413) die "bundle too large (413). Audit your output directory for large assets." ;;
  429)
    echo "[cybrix] rate limited (429). Waiting 30s before retry..." >&2
    sleep 30
    HTTP_RESPONSE="$(
      curl -sS --fail-with-body \
        -w '\n__HTTP_CODE__:%{http_code}' \
        -X POST "$API_URL/v1/deploys" \
        -H "Authorization: Bearer $VIBEDEPLOY_API_TOKEN" \
        -F "project_name=$PROJECT_NAME" \
        -F "tarball=@$TARBALL"
    )" || true
    HTTP_CODE="${HTTP_RESPONSE##*$'\n'__HTTP_CODE__:}"
    RESPONSE_BODY="${HTTP_RESPONSE%$'\n'__HTTP_CODE__:*}"
    [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" || "$HTTP_CODE" == "202" ]] \
      || die "upload failed after retry (HTTP $HTTP_CODE): $RESPONSE_BODY"
    ;;
  5*) die "API returned a server error (HTTP $HTTP_CODE). Wait a moment and try again, or check https://app.cybrix.cc/dashboard for status. Response: $RESPONSE_BODY" ;;
  *)  die "unexpected response (HTTP $HTTP_CODE): $RESPONSE_BODY" ;;
esac

# ── extract deployment id ─────────────────────────────────────────────────────

# grep+cut avoids a jq dependency while remaining portable.
# The [^"]* pattern tolerates optional spaces around the colon (": " or ":").
DEPLOYMENT_ID="$(printf '%s' "$RESPONSE_BODY" \
  | grep -o '"deployment_id" *: *"[^"]*"' \
  | grep -o '"[^"]*"$' \
  | tr -d '"' \
  || true)"

[[ -n "$DEPLOYMENT_ID" ]] \
  || die "API response missing deployment_id. Response was: $RESPONSE_BODY"

echo "[cybrix] deployment_id=$DEPLOYMENT_ID"

# ── poll ─────────────────────────────────────────────────────────────────────

echo "[cybrix] waiting for deployment to go live..."

DEADLINE=$(( $(date +%s) + 300 ))

while true; do
  (( $(date +%s) <= DEADLINE )) || die "timed out after 5 minutes. Check logs at https://app.cybrix.cc/deployments/$DEPLOYMENT_ID"

  STATUS_RESPONSE="$(
    curl -sS "$API_URL/v1/deploys/$DEPLOYMENT_ID" \
      -H "Authorization: Bearer $VIBEDEPLOY_API_TOKEN"
  )"

  STATUS="$(printf '%s' "$STATUS_RESPONSE" \
    | grep -o '"status" *: *"[^"]*"' \
    | grep -o '"[^"]*"$' \
    | tr -d '"' \
    || true)"

  case "$STATUS" in
    live)
      echo "$STATUS_RESPONSE"
      exit 0
      ;;
    failed)
      printf '%s\n' "$STATUS_RESPONSE" >&2
      die "deployment failed. Logs: https://app.cybrix.cc/deployments/$DEPLOYMENT_ID"
      ;;
    pending|building|"")
      sleep 2
      ;;
    *)
      die "unknown deployment status '$STATUS'. Response: $STATUS_RESPONSE"
      ;;
  esac
done
