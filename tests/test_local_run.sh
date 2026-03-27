#!/usr/bin/env bash
# Local integration test: builds the image and runs the Twingate client.
# Bypasses bashio (not available outside HA Supervisor) by injecting
# the service key directly and using a simplified entrypoint.
#
# Usage: ./tests/test_local_run.sh /path/to/service_key.json
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_TAG="twingate-client-local:test"
KEY_FILE="${1:?Usage: $0 /path/to/service_key.json}"

if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Service key file not found: $KEY_FILE"
    exit 1
fi

echo "Building image..."
docker build \
    --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm \
    -t "$IMAGE_TAG" \
    "$REPO_ROOT/twingate-client"

echo ""
echo "Starting Twingate client (Ctrl+C to stop)..."
docker run --rm -it \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    -v "$KEY_FILE":/etc/twingate/service_key.json:ro \
    --entrypoint /bin/bash \
    "$IMAGE_TAG" \
    -c '
        set -e
        hostname_val=$(hostname)
        if ! getent hosts "$hostname_val" > /dev/null 2>&1; then
            echo "127.0.0.1 $hostname_val" >> /etc/hosts
        fi
        echo "Configuring Twingate..."
        twingate setup --headless /etc/twingate/service_key.json
        echo "Starting Twingate..."
        twingate start
        echo "Waiting for connection..."
        sleep 10
        twingate status || true
        echo ""
        echo "Monitoring daemon (Ctrl+C to stop)..."
        while pgrep -f twingate > /dev/null 2>&1; do
            twingate status 2>/dev/null || true
            sleep 15
        done
        echo "Twingate daemon exited"
    '
