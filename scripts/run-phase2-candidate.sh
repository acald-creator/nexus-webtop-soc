#!/usr/bin/env bash
set -euo pipefail

DOCKERFILE="${DOCKERFILE:-Dockerfile.phase2a.amd64}"
TAG_SUFFIX="${TAG_SUFFIX:-phase2a}"
REPO="${REPO:-phoenixvlabs/nexus-webtop-soc}"
PUSH="${PUSH:-0}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"
DESKTOP_REQUIRED="${DESKTOP_REQUIRED:-0}"

DOCKERFILE="${DOCKERFILE}" TAG_SUFFIX="${TAG_SUFFIX}" REPO="${REPO}" PUSH="${PUSH}" \
  ./build-amd64-image.sh

ANALYST_IMAGE="${REPO}:amd64-${TAG_SUFFIX}-latest" \
TIMEOUT_SECONDS="${TIMEOUT_SECONDS}" \
DESKTOP_REQUIRED="${DESKTOP_REQUIRED}" \
./scripts/validate-analyst-image.sh
