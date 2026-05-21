#!/usr/bin/env bash

set -euo pipefail

VERSION="${VERSION:-$(git rev-parse --short HEAD)}"
REPO="${REPO:-phoenixvlabs/nexus-webtop-soc}"
PUSH="${PUSH:-1}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.xfce.amd64}"
TAG_SUFFIX="${TAG_SUFFIX:-}"
INSTALL_GITKRAKEN="${INSTALL_GITKRAKEN:-0}"
BUILD_TIMESTAMP="$(date '+%F_%H:%M:%S')"

if [[ -n "${TAG_SUFFIX}" && "${TAG_SUFFIX:0:1}" != "-" ]]; then
  TAG_SUFFIX="-${TAG_SUFFIX}"
fi

if [[ ! -f "${DOCKERFILE}" ]]; then
  echo "Dockerfile not found: ${DOCKERFILE}" >&2
  exit 1
fi

AMD_VERSIONED_TAG="${REPO}:${VERSION}${TAG_SUFFIX}-amd64"
AMD_LATEST_TAG="${REPO}:amd64${TAG_SUFFIX}-latest"

BUILD_ARGS=(
  --platform linux/amd64
  -t "${AMD_VERSIONED_TAG}"
  -t "${AMD_LATEST_TAG}"
  --build-arg "VERSION=${VERSION}"
  --build-arg "BUILD_TIMESTAMP=${BUILD_TIMESTAMP}"
  --build-arg "INSTALL_GITKRAKEN=${INSTALL_GITKRAKEN}"
  --no-cache
  --pull
  -f "${DOCKERFILE}"
  .
)

if [[ "${PUSH}" == "1" ]]; then
  docker buildx build "${BUILD_ARGS[@]}" --push
else
  docker buildx build "${BUILD_ARGS[@]}" --load
fi
