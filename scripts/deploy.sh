#!/usr/bin/env bash
# Tar a build output directory, POST it to the Cybrix API,
# poll for completion, print result as JSON.
#
# Usage:
#   deploy.sh <project_name> <output_dir>
#
# Required env:
#   VIBEDEPLOY_API_TOKEN   API token from app.cybrix.cc/dashboard
# Optional env:
#   VIBEDEPLOY_API_URL     defaults to https://api.cybrix.cc

set -euo pipefail

API_URL="${VIBEDEPLOY_API_URL:-https://api.cybrix.cc}"
PROJECT_NAME="${1:?usage: deploy.sh <project_name> <output_dir>}"
OUTPUT_DIR="${2:?usage: deploy.sh <project_name> <output_dir>}"

if [[ -z "${VIBEDEPLOY_API_TOKEN:-}" ]]; then
	echo "VIBEDEPLOY_API_TOKEN is not set." >&2
	echo "Get one at https://app.cybrix.cc/dashboard" >&2
	exit 1
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
	echo "Output directory not found: $OUTPUT_DIR" >&2
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "curl is required but not found." >&2
	exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
	echo "tar is required but not found." >&2
	exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL="$TMP_DIR/bundle.tar.gz"

echo "[cybrix] packing $OUTPUT_DIR"
tar -czf "$TARBALL" -C "$OUTPUT_DIR" .

SIZE_BYTES=$(wc -c < "$TARBALL" | tr -d ' ')
SIZE_MB=$(( SIZE_BYTES / 1024 / 1024 ))
if (( SIZE_MB > 100 )); then
	echo "Bundle too large: ${SIZE_MB}MB (max 100MB)." >&2
	exit 1
fi
echo "[cybrix] bundle size: ${SIZE_MB}MB"

echo "[cybrix] uploading to $API_URL"
RESPONSE="$(curl -sS -X POST "$API_URL/v1/deploys" \
	-H "Authorization: Bearer $VIBEDEPLOY_API_TOKEN" \
	-F "project_name=$PROJECT_NAME" \
	-F "tarball=@$TARBALL")"

DEPLOYMENT_ID="$(echo "$RESPONSE" | grep -o '"deployment_id":"[^"]*"' | cut -d'"' -f4 || true)"
if [[ -z "$DEPLOYMENT_ID" ]]; then
	echo "Failed to start deployment. API response:" >&2
	echo "$RESPONSE" >&2
	exit 1
fi

echo "[cybrix] deployment_id=$DEPLOYMENT_ID"
echo "[cybrix] polling for completion..."

DEADLINE=$(( $(date +%s) + 300 ))
while true; do
	if (( $(date +%s) > DEADLINE )); then
		echo "Timeout after 5 minutes." >&2
		exit 1
	fi

	STATUS_RESPONSE="$(curl -sS "$API_URL/v1/deploys/$DEPLOYMENT_ID" \
		-H "Authorization: Bearer $VIBEDEPLOY_API_TOKEN")"

	STATUS="$(echo "$STATUS_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || true)"

	case "$STATUS" in
		live)
			echo "$STATUS_RESPONSE"
			exit 0
			;;
		failed)
			echo "$STATUS_RESPONSE" >&2
			exit 1
			;;
		pending|building|"")
			sleep 2
			;;
		*)
			echo "Unknown status: $STATUS" >&2
			echo "$STATUS_RESPONSE" >&2
			exit 1
			;;
	esac
done
