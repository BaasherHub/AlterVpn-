#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# AlterVPN deploy-time smoke tests
#
# Usage:
#   scripts/smoke_test.sh [BASE_URL]
#
# If BASE_URL is omitted, defaults to the production Railway deployment.
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BASE_URL="${1:-https://altervpn-production.up.railway.app}"
PASS=0
FAIL=0

# Required directives that every served .ovpn profile must contain.
REQUIRED_DIRECTIVES=("client" "dev" "proto" "remote" "remote-cert-tls")

# ── helpers ───────────────────────────────────────────────────────────────────
pass() { echo "  ✓ $*"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $*" >&2; FAIL=$((FAIL + 1)); }

check_directive() {
  local profile_text="$1"
  local directive="$2"
  # Match directive at the start of a line (allow leading whitespace, case-insensitive).
  if echo "$profile_text" | grep -qiE "^\s*${directive}[[:space:]]"; then
    pass "profile contains '$directive'"
  else
    fail "profile missing required directive '$directive'"
  fi
}

# ── Test 1: /api/iphone/ returns valid JSON with required keys ────────────────
echo ""
echo "── Test 1: GET ${BASE_URL}/api/iphone/"

API_RESPONSE=$(curl -sf \
  -H "Accept: application/json" \
  -H "User-Agent: AlterVPN-SmokeTest/1.0" \
  "${BASE_URL}/api/iphone/") || {
  fail "/api/iphone/ request failed (curl exit code $?)"
  echo ""
  echo "Results: ${PASS} passed, ${FAIL} failed"
  exit 1
}

# Validate JSON structure
if echo "$API_RESPONSE" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
  pass "/api/iphone/ returned valid JSON"
else
  fail "/api/iphone/ response is not valid JSON"
fi

# Validate required top-level keys
REQUIRED_API_KEYS=("servers")
for key in "${REQUIRED_API_KEYS[@]}"; do
  if echo "$API_RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); assert '$key' in d" 2>/dev/null; then
    pass "/api/iphone/ JSON contains key '$key'"
  else
    fail "/api/iphone/ JSON missing required key '$key'"
  fi
done

# Validate required server-object keys
REQUIRED_SERVER_KEYS=("id" "name" "countryShort" "ovpn_url")
for key in "${REQUIRED_SERVER_KEYS[@]}"; do
  if echo "$API_RESPONSE" | python3 -c \
    "import json,sys; servers=json.load(sys.stdin).get('servers',[]); assert len(servers)>0 and '$key' in servers[0]" 2>/dev/null; then
    pass "server object contains key '$key'"
  else
    fail "server object missing key '$key'"
  fi
done

# ── Test 2: Each ovpn_url resolves with HTTP 200 ─────────────────────────────
echo ""
echo "── Test 2: ovpn_url reachability"

OVP_URLS=$(echo "$API_RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
servers = data.get('servers', [])
urls = []
for s in servers:
    if s.get('ovpn_url'):
        urls.append(s['ovpn_url'])
    if s.get('ovpn_url_tcp'):
        urls.append(s['ovpn_url_tcp'])
print('\n'.join(urls))
" 2>/dev/null || true)

if [ -z "$OVP_URLS" ]; then
  fail "no ovpn_url values found in API response"
else
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    HTTP_CODE=$(curl -so /dev/null -w "%{http_code}" \
      -H "User-Agent: AlterVPN-SmokeTest/1.0" \
      "$url" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
      pass "GET $url → HTTP $HTTP_CODE"
    else
      fail "GET $url → HTTP $HTTP_CODE (expected 200)"
    fi
  done <<< "$OVP_URLS"
fi

# ── Test 3: Each profile contains required directives ────────────────────────
echo ""
echo "── Test 3: profile directive validation"

while IFS= read -r url; do
  [ -z "$url" ] && continue
  echo "  Checking profile: $url"
  PROFILE_TEXT=$(curl -sf \
    -H "User-Agent: AlterVPN-SmokeTest/1.0" \
    "$url" 2>/dev/null || true)
  if [ -z "$PROFILE_TEXT" ]; then
    fail "could not fetch profile from $url"
    continue
  fi
  for directive in "${REQUIRED_DIRECTIVES[@]}"; do
    check_directive "$PROFILE_TEXT" "$directive"
  done
done <<< "$OVP_URLS"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────"
echo "Smoke test results: ${PASS} passed, ${FAIL} failed"
echo "─────────────────────────────────────────────────"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
