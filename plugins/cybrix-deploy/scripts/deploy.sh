#!/usr/bin/env bash
# Tar a build output directory, POST it to the Cybrix API,
# poll for completion, print result as JSON.
#
# Usage:
#   deploy.sh <project_name> <output_dir>
#
# Required (one of):
#   CYBRIX_TOKEN   API token from app.cybrix.cc/dashboard
#   ~/.config/cybrix/token
#   .cybrix/token          in the project root (gitignored)
#
# Optional:
#   CYBRIX_API_URL     defaults to https://api.cybrix.cc
#   CYBRIX_PROJECT_ID  skip project creation, deploy to existing project

set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────

die() {
  echo "[cybrix] error: $*" >&2
  # Anonymous error report — no token, no code, no PII
  curl -sf -X POST "${API_URL:-https://api.cybrix.cc}/v1/skill-errors" \
    -H "Content-Type: application/json" \
    -d "{\"step\":\"${CURRENT_STEP:-unknown}\",\"error_code\":\"${LAST_HTTP_CODE:-0}\",\"http_status\":${LAST_HTTP_CODE:-0},\"os\":\"$(uname -s)\",\"version\":\"0.1.0\"}" \
    --max-time 3 > /dev/null 2>&1 || true
  exit 1
}

json_field() {
  # Extract a JSON string field value without requiring jq.
  local json="$1" field="$2"
  printf '%s' "$json" \
    | grep -o "\"${field}\" *: *\"[^\"]*\"" \
    | grep -o '"[^"]*"$' \
    | tr -d '"' \
    || true
}

# ── args ─────────────────────────────────────────────────────────────────────

PROJECT_NAME="${1:?usage: deploy.sh <project_name> <output_dir>}"
OUTPUT_DIR="${2:?usage: deploy.sh <project_name> <output_dir>}"

# ── token resolution ─────────────────────────────────────────────────────────

if [[ -z "${CYBRIX_TOKEN:-}" ]]; then
  if [[ -r "${HOME}/.config/cybrix/token" ]]; then
    CYBRIX_TOKEN="$(cat "${HOME}/.config/cybrix/token")"
  elif [[ -r ".cybrix/token" ]]; then
    CYBRIX_TOKEN="$(cat ".cybrix/token")"
  else
    die "CYBRIX_TOKEN is not set.
  Set it with: export CYBRIX_TOKEN=<token>
  Or save your token to ~/.config/cybrix/token
  Get one free at https://app.cybrix.cc/dashboard"
  fi
fi

# ── config ───────────────────────────────────────────────────────────────────

API_URL="${CYBRIX_API_URL:-https://api.cybrix.cc}"

# ── preflight ────────────────────────────────────────────────────────────────

[[ -d "$OUTPUT_DIR" ]] || die "output directory not found: $OUTPUT_DIR"
command -v curl >/dev/null 2>&1 || die "curl is required but not found"
command -v tar  >/dev/null 2>&1 || die "tar is required but not found"

# ── resolve project ID ───────────────────────────────────────────────────────

PROJECT_ID="${CYBRIX_PROJECT_ID:-}"
PROJECT_SLUG=""

CURRENT_STEP="init"
LAST_HTTP_CODE=0

if [[ -z "$PROJECT_ID" ]]; then
  CURRENT_STEP="project_creation"
  echo "[cybrix] creating project: $PROJECT_NAME"
  PROJ_RESPONSE="$(
    curl -sS --fail-with-body \
      -w '\n__HTTP_CODE__:%{http_code}' \
      -X POST "$API_URL/v1/projects" \
      -H "Authorization: Bearer $CYBRIX_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"$PROJECT_NAME\"}"
  )" || true

  PROJ_HTTP_CODE="${PROJ_RESPONSE##*$'\n'__HTTP_CODE__:}"
  PROJ_BODY="${PROJ_RESPONSE%$'\n'__HTTP_CODE__:*}"
  LAST_HTTP_CODE="$PROJ_HTTP_CODE"

  case "$PROJ_HTTP_CODE" in
    200|201)
      PROJECT_ID="$(json_field "$PROJ_BODY" "id")"
      PROJECT_SLUG="$(json_field "$PROJ_BODY" "slug")"
      [[ -n "$PROJECT_ID" ]] || die "project creation response missing id. Response: $PROJ_BODY"
      echo "[cybrix] project created: id=$PROJECT_ID slug=$PROJECT_SLUG"
      ;;
    401) die "authentication failed (401). Refresh your token at https://app.cybrix.cc/dashboard" ;;
    403) die "free tier project limit reached (403). Upgrade at https://cybrix.cc/pricing" ;;
    409) die "project name already taken (409). Choose a different name." ;;
    *)   die "project creation failed (HTTP $PROJ_HTTP_CODE): $PROJ_BODY" ;;
  esac
fi

# ── package ──────────────────────────────────────────────────────────────────

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL="$TMP_DIR/bundle.tar.gz"

echo "[cybrix] packing $OUTPUT_DIR"
tar -czf "$TARBALL" -C "$OUTPUT_DIR" .

SIZE_BYTES="$(wc -c < "$TARBALL" | tr -d ' ')"
echo "[cybrix] bundle size: $SIZE_BYTES bytes"

SIZE_MB=$(( SIZE_BYTES / 1024 / 1024 ))
if (( SIZE_MB > 100 )); then
  die "bundle too large: ${SIZE_MB} MB (limit 100 MB). Audit your output directory for large assets."
fi

# ── upload ───────────────────────────────────────────────────────────────────

CURRENT_STEP="upload"
echo "[cybrix] uploading to $API_URL"
HTTP_RESPONSE="$(
  curl -sS --fail-with-body \
    -w '\n__HTTP_CODE__:%{http_code}' \
    -X POST "$API_URL/v1/deploys" \
    -H "Authorization: Bearer $CYBRIX_TOKEN" \
    -F "project_id=$PROJECT_ID" \
    -F "file=@$TARBALL"
)" || true

HTTP_CODE="${HTTP_RESPONSE##*$'\n'__HTTP_CODE__:}"
RESPONSE_BODY="${HTTP_RESPONSE%$'\n'__HTTP_CODE__:*}"
LAST_HTTP_CODE="$HTTP_CODE"

case "$HTTP_CODE" in
  200|201|202) ;;
  401) die "authentication failed (401). Refresh your token at https://app.cybrix.cc/dashboard" ;;
  402|403) die "free tier deploy limit reached. Upgrade at https://cybrix.cc/pricing" ;;
  413) die "bundle too large (413). Audit your output directory for large assets." ;;
  429)
    echo "[cybrix] rate limited (429). Waiting 30s before retry..." >&2
    sleep 30
    HTTP_RESPONSE="$(
      curl -sS --fail-with-body \
        -w '\n__HTTP_CODE__:%{http_code}' \
        -X POST "$API_URL/v1/deploys" \
        -H "Authorization: Bearer $CYBRIX_TOKEN" \
        -F "project_id=$PROJECT_ID" \
        -F "file=@$TARBALL"
    )" || true
    HTTP_CODE="${HTTP_RESPONSE##*$'\n'__HTTP_CODE__:}"
    RESPONSE_BODY="${HTTP_RESPONSE%$'\n'__HTTP_CODE__:*}"
    [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" || "$HTTP_CODE" == "202" ]] \
      || die "upload failed after retry (HTTP $HTTP_CODE): $RESPONSE_BODY"
    ;;
  5*) die "API returned a server error (HTTP $HTTP_CODE): $RESPONSE_BODY" ;;
  *)  die "unexpected response (HTTP $HTTP_CODE): $RESPONSE_BODY" ;;
esac

# ── extract deployment id ─────────────────────────────────────────────────────

DEPLOYMENT_ID="$(json_field "$RESPONSE_BODY" "id")"
[[ -n "$DEPLOYMENT_ID" ]] \
  || die "API response missing id. Response was: $RESPONSE_BODY"

# Extract slug and project_id from deploy response if not already set
[[ -n "$PROJECT_ID" ]] || PROJECT_ID="$(json_field "$RESPONSE_BODY" "project_id")"

echo "[cybrix] deployment_id=$DEPLOYMENT_ID"

# ── poll ─────────────────────────────────────────────────────────────────────

CURRENT_STEP="polling"
echo "[cybrix] waiting for deployment to go live..."

DEADLINE=$(( $(date +%s) + 300 ))

while true; do
  (( $(date +%s) <= DEADLINE )) || die "timed out after 5 minutes."

  STATUS_RESPONSE="$(
    curl -sS "$API_URL/v1/deploys/$DEPLOYMENT_ID" \
      -H "Authorization: Bearer $CYBRIX_TOKEN"
  )"

  STATUS="$(json_field "$STATUS_RESPONSE" "status")"
  DEPLOYED_URL="$(json_field "$STATUS_RESPONSE" "deployed_url")"

  case "$STATUS" in
    live)
      # Emit final JSON for the skill to parse
      printf '{"id":"%s","project_id":"%s","status":"live","deployed_url":"%s","slug":"%s"}\n' \
        "$DEPLOYMENT_ID" "$PROJECT_ID" "$DEPLOYED_URL" "$PROJECT_SLUG"
      exit 0
      ;;
    failed)
      printf '%s\n' "$STATUS_RESPONSE" >&2
      die "deployment failed."
      ;;
    pending|building|"")
      sleep 2
      ;;
    *)
      die "unknown deployment status '$STATUS'. Response: $STATUS_RESPONSE"
      ;;
  esac
done
