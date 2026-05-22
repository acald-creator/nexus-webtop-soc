# Changelog

All notable changes to this project are documented in this file.

## Unreleased

- Phase 2a candidate passing plumbing checks; desktop parity not yet achieved.
- Chainguard transition track (`cg`) passing all acceptance gate checks.

## 2026-05-21

### Added
- Phase 2 candidate matrix evaluation script (`scripts/evaluate-runtime-matrix.sh`).
- Generated evaluation report at `docs/reports/runtime-evaluation-latest.md`.
- Matrix evaluation command documented in README and Phase 2 migration doc.

## 2026-05-20

### Added
- SOC baseline compose stack (`deploy/compose/soc-baseline.yml`) with Wazuh manager, indexer, dashboard, Suricata sensor, and event forwarder.
- Suricata sensor configuration (`deploy/suricata/suricata.yaml`).
- Security bootstrap script (`scripts/bootstrap-wazuh-security.sh`).
- Analyst image acceptance gate (`scripts/validate-analyst-image.sh`).
- Phase 2 candidate build+validate wrapper (`scripts/run-runtime-candidate.sh`).
- Phase 2a candidate Dockerfile (`Dockerfile.runtime-a.amd64`) — first non-LinuxServer runtime baseline.
- Chainguard transition Dockerfile (`Dockerfile.xfce.amd64.chainguard`).
- Architecture proposal (`architecture.md`).
- SOC baseline operations guide (`docs/soc-baseline.md`).
- Phase 2 base image migration plan (`docs/base-image-migration.md`).

### Changed
- README.md rewritten to reflect SOC split architecture and legacy webtop role.
- Analyst desktop image: GitKraken installation made optional (`INSTALL_GITKRAKEN=0` default).

### Deprecated
- Suricata compilation inside the webtop image.
- SOC control-plane services inside the desktop image.
