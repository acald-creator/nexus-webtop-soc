#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-deploy/compose/soc-baseline.yml}"
ANALYST_IMAGE="${ANALYST_IMAGE:-phoenixvlabs/nexus-webtop-soc:amd64-cg-latest}"
ANALYST_SERVICE="${ANALYST_SERVICE:-webtop.analyst}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"
DESKTOP_REQUIRED="${DESKTOP_REQUIRED:-1}"
ACTIVE_DESKTOP_REQUIRED="${ACTIVE_DESKTOP_REQUIRED:-0}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

wait_for_healthy() {
  local container="$1"
  local timeout="$2"
  local elapsed=0
  local status=""

  while [ "$elapsed" -lt "$timeout" ]; do
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || true)"
    if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
      echo "[validate] ${container} status: ${status}"
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  echo "[validate] ${container} did not become healthy/running in ${timeout}s (last status: ${status})" >&2
  return 1
}

echo "[validate] starting SOC baseline services..."
docker compose -f "${COMPOSE_FILE}" up -d

echo "[validate] bootstrapping indexer security..."
./scripts/bootstrap-wazuh-security.sh

echo "[validate] rolling analyst service with image: ${ANALYST_IMAGE}"
WEBTOP_ANALYST_IMAGE="${ANALYST_IMAGE}" \
  docker compose -f "${COMPOSE_FILE}" --profile analyst up -d "${ANALYST_SERVICE}"

wait_for_healthy "wazuh.indexer" "${TIMEOUT_SECONDS}"
wait_for_healthy "wazuh.manager" "${TIMEOUT_SECONDS}"
wait_for_healthy "wazuh.dashboard" "${TIMEOUT_SECONDS}"
wait_for_healthy "suricata.sensor" "${TIMEOUT_SECONDS}"
wait_for_healthy "${ANALYST_SERVICE}" "${TIMEOUT_SECONDS}"

echo "[validate] checking health endpoint..."
web_ok=0
for _ in $(seq 1 30); do
  if curl -fsSI --max-time 5 http://localhost:3000/healthz >/dev/null 2>&1; then
    web_ok=1
    break
  fi
  sleep 1
done
if [ "${web_ok}" != "1" ]; then
  echo "[validate] health endpoint did not become ready on http://localhost:3000/healthz" >&2
  exit 1
fi

echo "[validate] checking analyst tool availability..."
docker exec "${ANALYST_SERVICE}" bash -lc 'git --version >/dev/null && curl --version >/dev/null'

if [ "${DESKTOP_REQUIRED}" = "1" ]; then
  echo "[validate] checking desktop capability markers..."
  docker exec "${ANALYST_SERVICE}" bash -lc '
    command -v xfce4-session >/dev/null || command -v openbox >/dev/null
  '
else
  echo "[validate] DESKTOP_REQUIRED=0, skipping desktop capability marker checks."
fi

if [ "${ACTIVE_DESKTOP_REQUIRED}" = "1" ]; then
  echo "[validate] checking active desktop session process..."
  active_ok=0
  for _ in $(seq 1 30); do
    if docker exec "${ANALYST_SERVICE}" bash -lc 'pgrep -x xfce4-session >/dev/null || pgrep -x openbox >/dev/null' >/dev/null 2>&1; then
      active_ok=1
      break
    fi
    sleep 1
  done
  if [ "${active_ok}" != "1" ]; then
    echo "[validate] active desktop session process not detected in time" >&2
    exit 1
  fi
else
  echo "[validate] ACTIVE_DESKTOP_REQUIRED=0, skipping active desktop session checks."
fi

echo "[validate] candidate image passed acceptance gate checks."
