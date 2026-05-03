#!/usr/bin/env bash
# Pre-commit / CI validation: shellcheck, JSON syntax, SKILL.md frontmatter.
# Run from the repo root: ./validate.sh
# Exits non-zero on first failure.

set -euo pipefail

PASS=0
FAIL=0

ok()   { echo "  [ok]  $*"; PASS=$(( PASS + 1 )); }
fail() { echo "  [FAIL] $*" >&2; FAIL=$(( FAIL + 1 )); }

section() { echo; echo "── $* ──"; }

# ── shellcheck ────────────────────────────────────────────────────────────────

section "shellcheck"

if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r -d '' script; do
    if shellcheck "$script"; then
      ok "$script"
    else
      fail "$script"
    fi
  done < <(find plugins -name "*.sh" -print0)
else
  echo "  [skip] shellcheck not installed (will run in CI)"
fi

# ── JSON validation ───────────────────────────────────────────────────────────

section "JSON files"

validate_json() {
  local file="$1"
  if python3 -c "import sys,json; json.load(open(sys.argv[1]))" "$file" 2>/dev/null; then
    ok "$file"
  else
    fail "$file — invalid JSON"
  fi
}

validate_json ".claude-plugin/marketplace.json"
validate_json "plugins/cybrix-deploy/.claude-plugin/plugin.json"

# ── SKILL.md frontmatter ──────────────────────────────────────────────────────

section "SKILL.md frontmatter"

validate_skill() {
  local file="$1"
  # Extract YAML between the first pair of --- delimiters and parse it.
  if python3 - "$file" <<'PYEOF'
import sys, re

with open(sys.argv[1]) as f:
    content = f.read()

m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if not m:
    print(f"  no frontmatter found in {sys.argv[1]}", file=sys.stderr)
    sys.exit(1)

try:
    import yaml
    yaml.safe_load(m.group(1))
except ImportError:
    # PyYAML not available — do a basic key-presence check instead
    fm = m.group(1)
    required = ["name", "description", "allowed-tools"]
    missing = [k for k in required if k + ":" not in fm]
    if missing:
        print(f"  missing keys: {missing}", file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print(f"  YAML parse error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
  then
    ok "$file"
  else
    fail "$file — invalid frontmatter"
  fi
}

validate_skill "plugins/cybrix-deploy/skills/cybrix-deploy/SKILL.md"

# ── summary ───────────────────────────────────────────────────────────────────

echo
echo "── result: $PASS passed, $FAIL failed ──"
(( FAIL == 0 ))
