# Agent Instructions

Use `architecture.md` as the canonical architecture guide for this repository.

---

## Repository Purpose

This repository contains the **legacy SOC analyst webtop** for Underground Nexus.
The desktop image provides an XFCE-based analyst workstation with pre-installed
investigation tools. SOC runtime services — Wazuh, Suricata, optional Zeek, and
AI triage workloads — run as **dedicated services**, not inside the desktop image.
The `deploy/compose/soc-baseline.yml` stack wires the analyst webtop alongside
those services for a full SOC baseline environment.

---

## File Layout

| Path | Purpose |
|------|---------|
| `Dockerfile.xfce.amd64` | Primary analyst desktop image (LinuxServer XFCE base) |
| `Dockerfile.xfce.amd64.chainguard` | Experimental Chainguard transition track (still LinuxServer base) |
| `Dockerfile.runtime-a.amd64` | Phase 2a candidate: first non-LinuxServer runtime (wolfi-base, nginx placeholder, no desktop) |
| `build-amd64-image.sh` | Build helper for all Dockerfiles |
| `deploy/compose/soc-baseline.yml` | Full SOC baseline compose stack (Wazuh + Suricata + analyst webtop) |
| `deploy/suricata/suricata.yaml` | Suricata sensor configuration |
| `scripts/bootstrap-wazuh-security.sh` | Initializes OpenSearch security config in indexer after a fresh `down -v` |
| `scripts/validate-analyst-image.sh` | Acceptance gate: healthchecks, curl, tool availability, optional desktop markers |
| `scripts/run-runtime-candidate.sh` | Build + validate wrapper for Phase 2 candidates |
| `scripts/evaluate-runtime-matrix.sh` | Runs all candidate scenarios and generates report to `docs/reports/` |
| `architecture.md` | Canonical architecture guide (**source of truth**) |
| `docs/soc-baseline.md` | SOC baseline operations guide |
| `docs/base-image-migration.md` | Phase 2 migration plan and candidate evaluation |
| `docs/reports/runtime-evaluation-latest.md` | Latest matrix evaluation results |

---

## Key Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WEBTOP_ANALYST_IMAGE` | `phoenixvlabs/nexus-webtop-soc:amd64-cg-latest` | Override analyst image in compose |
| `DOCKERFILE` | `Dockerfile.xfce.amd64` | Which Dockerfile to build |
| `TAG_SUFFIX` | *(empty)* | Suffix for image tags (e.g., `cg`, `runtime-a`) |
| `PUSH` | `1` | Whether to push built image (`0` for local-only) |
| `INSTALL_GITKRAKEN` | `0` | Include GitKraken in analyst image |
| `DESKTOP_REQUIRED` | `1` | Whether to check desktop capability markers during validation |
| `TIMEOUT_SECONDS` | `180` | Healthcheck wait timeout for validation |

---

## Build & Test Commands

**Build default image (local only):**

```bash
PUSH=0 ./build-amd64-image.sh
```

**Build Chainguard track:**

```bash
DOCKERFILE=Dockerfile.xfce.amd64.chainguard TAG_SUFFIX=cg PUSH=0 ./build-amd64-image.sh
```

**Start SOC baseline stack:**

```bash
docker compose -f deploy/compose/soc-baseline.yml up -d
```

**Bootstrap security (fresh stack after `down -v`):**

```bash
./scripts/bootstrap-wazuh-security.sh
```

**Run acceptance gate:**

```bash
ANALYST_IMAGE=<image:tag> ./scripts/validate-analyst-image.sh
```

**Run full Phase 2 evaluation matrix:**

```bash
./scripts/evaluate-runtime-matrix.sh
```

---

## Naming Conventions

| Category | Pattern | Example |
|----------|---------|---------|
| Dockerfiles | `Dockerfile.<desktop>.<arch>[.variant]` | `Dockerfile.xfce.amd64.chainguard` |
| Compose services | Dotted names | `wazuh.manager`, `suricata.sensor`, `webtop.analyst` |
| Image tags (latest) | `<repo>:amd64[-suffix]-latest` | `phoenixvlabs/nexus-webtop-soc:amd64-cg-latest` |
| Image tags (versioned) | `<repo>:<version>[-suffix]-amd64` | `phoenixvlabs/nexus-webtop-soc:1.0.0-cg-amd64` |

---

## Guardrails

### Codex-specific expectations

- Treat this repository as the legacy SOC analyst webtop, not the final SOC runtime.
- Move detection services toward dedicated Wazuh, Suricata, optional Zeek, and AI triage workloads.
- Do not add new SOC control-plane services into the desktop image by default.
- Keep credentials and certificates out of images.
- Keep changes aligned with the Underground Nexus architecture in `core-nexus`.

### Additional guardrails

- Do **not** modify cert paths in `bootstrap-wazuh-security.sh` without updating the
  indexer container layout to match.
- Do **not** hardcode credentials in Dockerfiles or scripts.
- Always test changes with `validate-analyst-image.sh` before considering them complete.
- When adding a new Phase 2 candidate:
  1. Create a new `Dockerfile.<desktop>.<arch>.<variant>`.
  2. Add an entry to the `rows` array in `scripts/evaluate-runtime-matrix.sh`.
  3. Document the candidate in `docs/base-image-migration.md`.

---

## Cross-Repo References

| Repository | Relationship |
|------------|-------------|
| `core-nexus` | Underground Nexus architecture — this repo **must** stay aligned |
| `nexus-webtop-workbench` | Dedicated analyst workbench image (recommended over this repo's XFCE image for the analyst profile) |
