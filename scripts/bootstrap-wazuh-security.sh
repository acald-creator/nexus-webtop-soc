#!/usr/bin/env bash
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-deploy/compose/soc-baseline.yml}"
INDEXER_CONTAINER="${INDEXER_CONTAINER:-wazuh.indexer}"
MANAGER_SERVICE="${MANAGER_SERVICE:-wazuh.manager}"
DASHBOARD_SERVICE="${DASHBOARD_SERVICE:-wazuh.dashboard}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

echo "[bootstrap] waiting for ${INDEXER_CONTAINER} to be running..."
until docker ps --format '{{.Names}}' | grep -qx "${INDEXER_CONTAINER}"; do
  sleep 2
done

echo "[bootstrap] waiting for ${INDEXER_CONTAINER} health status..."
for _ in $(seq 1 90); do
  status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${INDEXER_CONTAINER}" 2>/dev/null || true)"
  if [ "${status}" = "healthy" ] || [ "${status}" = "none" ]; then
    break
  fi
  sleep 2
done
if [ "${status}" != "healthy" ] && [ "${status}" != "none" ]; then
  echo "[bootstrap] indexer did not become healthy in time (status: ${status})" >&2
  exit 1
fi

echo "[bootstrap] reconciling OpenSearch security configuration in ${INDEXER_CONTAINER}..."
docker exec "${INDEXER_CONTAINER}" bash -lc '
  export OPENSEARCH_JAVA_HOME=/usr/share/wazuh-indexer/jdk
  export JAVA_HOME=/usr/share/wazuh-indexer/jdk
  export PATH=$JAVA_HOME/bin:$PATH
  bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
    -cd /usr/share/wazuh-indexer/opensearch-security/ \
    -icl \
    -nhnv \
    -cacert /usr/share/wazuh-indexer/certs/root-ca.pem \
    -cert /usr/share/wazuh-indexer/certs/admin.pem \
    -key /usr/share/wazuh-indexer/certs/admin-key.pem
'

echo "[bootstrap] restarting manager and dashboard..."
docker compose -f "${COMPOSE_FILE}" restart "${MANAGER_SERVICE}" "${DASHBOARD_SERVICE}"

echo "[bootstrap] done."
