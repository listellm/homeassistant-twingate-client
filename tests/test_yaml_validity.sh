#!/usr/bin/env bash
# Validates all YAML files parse correctly.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

for f in "$REPO_ROOT"/repository.yaml "$REPO_ROOT"/twingate-client/config.yaml "$REPO_ROOT"/twingate-client/build.yaml; do
    if python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null; then
        echo "PASS: $f"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $f"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
