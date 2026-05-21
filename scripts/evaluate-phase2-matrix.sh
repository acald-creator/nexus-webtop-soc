#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="${REPORT_DIR:-docs/reports}"
REPORT_FILE="${REPORT_FILE:-${REPORT_DIR}/phase2-evaluation-latest.md}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"

mkdir -p "${REPORT_DIR}"

rows=(
  "cg-desktop-required|phoenixvlabs/nexus-webtop-soc:amd64-cg-latest|1|pass"
  "phase2a-desktop-required|phoenixvlabs/nexus-webtop-soc:amd64-phase2a-latest|1|fail"
  "phase2a-plumbing|phoenixvlabs/nexus-webtop-soc:amd64-phase2a-latest|0|pass"
)

{
  echo "# Phase 2 Candidate Evaluation"
  echo
  echo "- Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "- Host: $(hostname)"
  echo
  echo "| Scenario | Image | Desktop Required | Expected | Actual | Result |"
  echo "| --- | --- | --- | --- | --- | --- |"
} > "${REPORT_FILE}"

all_ok=1

for row in "${rows[@]}"; do
  IFS="|" read -r name image desktop_required expected <<< "${row}"
  log_file="${REPORT_DIR}/${name}.log"

  echo "[matrix] running ${name} (image=${image}, desktop=${desktop_required}, expected=${expected})"

  set +e
  ANALYST_IMAGE="${image}" \
  DESKTOP_REQUIRED="${desktop_required}" \
  TIMEOUT_SECONDS="${TIMEOUT_SECONDS}" \
    ./scripts/validate-analyst-image.sh > "${log_file}" 2>&1
  rc=$?
  set -e

  if [ $rc -eq 0 ]; then
    actual="pass"
  else
    actual="fail"
  fi

  if [ "${actual}" = "${expected}" ]; then
    verdict="ok"
  else
    verdict="mismatch"
    all_ok=0
  fi

  echo "| ${name} | \`${image}\` | \`${desktop_required}\` | \`${expected}\` | \`${actual}\` | **${verdict}** |" >> "${REPORT_FILE}"
done

echo >> "${REPORT_FILE}"
echo "Logs are stored in \`${REPORT_DIR}\`." >> "${REPORT_FILE}"

echo "[matrix] report written to ${REPORT_FILE}"

if [ $all_ok -ne 1 ]; then
  echo "[matrix] one or more scenarios mismatched expected outcomes" >&2
  exit 1
fi
