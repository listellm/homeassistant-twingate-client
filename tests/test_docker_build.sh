#!/usr/bin/env bash
# Builds the Docker image to verify the Dockerfile is valid and Twingate installs.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_TAG="twingate-client-test:latest"
ARCH="${1:-amd64}"
BUILD_FROM="ghcr.io/home-assistant/${ARCH}-base-debian:bookworm"

echo "Building image for ${ARCH} from ${BUILD_FROM}..."
docker build \
    --build-arg "BUILD_FROM=${BUILD_FROM}" \
    -t "$IMAGE_TAG" \
    "$REPO_ROOT/twingate-client"

echo ""
echo "Verifying twingate binary exists in image..."
if docker run --rm "$IMAGE_TAG" which twingate >/dev/null 2>&1; then
    echo "PASS: twingate binary found"
else
    echo "FAIL: twingate binary not found in image"
    exit 1
fi

echo "Verifying twingate version..."
docker run --rm "$IMAGE_TAG" twingate --version

echo ""
echo "Cleaning up..."
docker rmi "$IMAGE_TAG" >/dev/null 2>&1 || true

echo "PASS: Docker build and verification complete"
