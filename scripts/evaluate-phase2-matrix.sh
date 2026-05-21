#!/usr/bin/env bash
#
# evaluate-phase2-matrix.sh
#
# Runs all Phase 2 candidate scenarios through the acceptance gate and
# generates a markdown report with pass/fail results.
#
# Usage:
#   ./scripts/evaluate-phase2-matrix.sh
#
# Environment:
#   REPORT_DIR       Output directory for report and logs (default: docs/reports)
#   REPORT_FILE      Report filename (default: docs/reports/phase2-evaluation-latest.md)
#   TIMEOUT_SECONDS  Healthcheck timeout per scenario (default: 180)
#
# Candidates:
#   Candidates are defined in the 'rows' array below. Each entry is:
#     scenario-name|image-reference|desktop-required-flag|expected-outcome
#
#   To add a new candidate:
#   1. Create a Dockerfile following the naming convention Dockerfile.<id>.amd64
#   2. Build it: DOCKERFILE=Dockerfile.<id>.amd64 TAG_SUFFIX=<id> PUSH=0 ./build-amd64-image.sh
#   3. Add a row entry to the 'rows' array in this script
#   4. Run this script to validate
#
# Output:
#   - Markdown report: ${REPORT_DIR}/phase2-evaluation-latest.md
#   - Per-scenario logs: ${REPORT_DIR}/<scenario-name>.log
#   - Exit code 0 if all scenarios match expected outcomes, 1 otherwise
#
set -euo pipefail

REPORT_DIR="${REPORT_DIR:-docs/reports}"
REPORT_FILE="${REPORT_FILE:-${REPORT_DIR}/phase2-evaluation-latest.md}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"

mkdir -p "${REPORT_DIR}"

rows=(
  "cg-desktop-active|phoenixvlabs/nexus-webtop-soc:amd64-cg-latest|1|1|pass"
  "phase2a-desktop-active|phoenixvlabs/nexus-webtop-soc:amd64-phase2a-latest|1|1|fail"
  "phase2a-plumbing|phoenixvlabs/nexus-webtop-soc:amd64-phase2a-latest|0|0|pass"
  "phase2b-desktop-active|phoenixvlabs/nexus-webtop-soc:amd64-phase2b-latest|1|1|pass"
  "phase2b-marker-only|phoenixvlabs/nexus-webtop-soc:amd64-phase2b-latest|1|0|pass"
)

{
  echo "# Phase 2 Candidate Evaluation"
  echo
  echo "- Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "- Host: $(hostname)"
  echo
  echo "| Scenario | Image | Desktop Required | Active Session Required | Expected | Actual | Result |"
  echo "| --- | --- | --- | --- | --- | --- | --- |"
} > "${REPORT_FILE}"

all_ok=1

for row in "${rows[@]}"; do
  IFS="|" read -r name image desktop_required active_required expected <<< "${row}"
  log_file="${REPORT_DIR}/${name}.log"

  echo "[matrix] running ${name} (image=${image}, desktop=${desktop_required}, active=${active_required}, expected=${expected})"

  set +e
  ANALYST_IMAGE="${image}" \
  DESKTOP_REQUIRED="${desktop_required}" \
  ACTIVE_DESKTOP_REQUIRED="${active_required}" \
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

  echo "| ${name} | \`${image}\` | \`${desktop_required}\` | \`${active_required}\` | \`${expected}\` | \`${actual}\` | **${verdict}** |" >> "${REPORT_FILE}"
done

echo >> "${REPORT_FILE}"
echo "Logs are stored in \`${REPORT_DIR}\`." >> "${REPORT_FILE}"

echo "[matrix] report written to ${REPORT_FILE}"

if [ $all_ok -ne 1 ]; then
  echo "[matrix] one or more scenarios mismatched expected outcomes" >&2
  exit 1
fi
