#!/usr/bin/env bash
# Verifies run.sh exits with an error when no service key is configured.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN_SCRIPT="$REPO_ROOT/twingate-client/rootfs/etc/services.d/twingate-client/run"

echo "Checking run.sh handles missing service key..."
if grep -q 'bashio::log.fatal' "$RUN_SCRIPT" && grep -q 'exit 1' "$RUN_SCRIPT"; then
    echo "PASS: run.sh exits fatally when service_key is empty"
else
    echo "FAIL: run.sh should exit with fatal error when service_key is missing"
    exit 1
fi

echo "Checking run.sh creates TUN device..."
if grep -q '/dev/net/tun' "$RUN_SCRIPT"; then
    echo "PASS: run.sh handles TUN device creation"
else
    echo "FAIL: run.sh should create /dev/net/tun if missing"
    exit 1
fi

echo "Checking run.sh starts twingate and monitors daemon..."
if grep -q 'twingate start' "$RUN_SCRIPT" && grep -q 'twingate status' "$RUN_SCRIPT"; then
    echo "PASS: run.sh starts twingate and monitors daemon health"
else
    echo "FAIL: run.sh should start twingate and monitor via twingate status"
    exit 1
fi

echo ""
echo "PASS: run.sh validation complete"
