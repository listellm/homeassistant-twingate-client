#!/usr/bin/env bash
# Validates the add-on config.yaml contains required HA add-on fields.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$REPO_ROOT/twingate-client/config.yaml"
PASS=0
FAIL=0

check_field() {
    local field="$1"
    if grep -q "^${field}:" "$CONFIG"; then
        echo "PASS: config.yaml has '${field}'"
        PASS=$((PASS + 1))
    else
        echo "FAIL: config.yaml missing '${field}'"
        FAIL=$((FAIL + 1))
    fi
}

check_field "name"
check_field "version"
check_field "slug"
check_field "description"
check_field "arch"
check_field "startup"
check_field "options"
check_field "schema"

# Verify host_network is enabled (required for Twingate tunnel)
if grep -q "host_network: true" "$CONFIG"; then
    echo "PASS: host_network is true"
    PASS=$((PASS + 1))
else
    echo "FAIL: host_network must be true"
    FAIL=$((FAIL + 1))
fi

# Verify NET_ADMIN privilege is declared
if grep -q "NET_ADMIN" "$CONFIG"; then
    echo "PASS: NET_ADMIN privilege declared"
    PASS=$((PASS + 1))
else
    echo "FAIL: NET_ADMIN privilege required for TUN interface"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
