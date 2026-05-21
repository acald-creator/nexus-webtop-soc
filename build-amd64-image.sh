#!/usr/bin/env bash

set -euo pipefail

VERSION="${VERSION:-$(git rev-parse --short HEAD)}"
REPO="${REPO:-phoenixvlabs/nexus-webtop-soc}"
PUSH="${PUSH:-1}"
BUILD_TIMESTAMP="$(date '+%F_%H:%M:%S')"

AMD_VERSIONED_TAG="${REPO}:${VERSION}-amd64"
AMD_LATEST_TAG="${REPO}:amd64-latest"

BUILD_ARGS=(
  --platform linux/amd64
  -t "${AMD_VERSIONED_TAG}"
  -t "${AMD_LATEST_TAG}"
  --build-arg "VERSION=${VERSION}"
  --build-arg "BUILD_TIMESTAMP=${BUILD_TIMESTAMP}"
  --no-cache
  --pull
  -f Dockerfile.xfce.amd64
  .
)

if [[ "${PUSH}" == "1" ]]; then
  docker buildx build "${BUILD_ARGS[@]}" --push
else
  docker buildx build "${BUILD_ARGS[@]}" --load
fi
