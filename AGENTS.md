# Agent Instructions

Use `architecture.md` as the canonical architecture guide for this repository.

## Repository Role

Legacy SOC analyst webtop for Underground Nexus. Provides an XFCE-based analyst
workstation with pre-installed investigation tools. SOC runtime services (Wazuh,
Suricata, optional Zeek, AI triage) run as dedicated services, not inside the desktop image.
The `deploy/compose/soc-baseline.yml` stack wires everything together.

## Key References

- `architecture.md` — canonical architecture guide
- `deploy/compose/soc-baseline.yml` — full SOC baseline compose stack
- `scripts/validate-analyst-image.sh` — acceptance gate
- `docs/soc-baseline.md` — operations guide

## Agent Expectations

- Treat this repository as the legacy SOC analyst webtop, not the final SOC runtime.
- Do not add new SOC control-plane services into the desktop image.
- Keep credentials and certificates out of images and scripts.
- Always test changes with `validate-analyst-image.sh` before considering them complete.
- When working with the SOC baseline stack, be aware that Athena stimulation traffic
  will flow through Suricata/Wazuh — ensure dashboards can filter labeled traffic.
- Check `~/.kiro/skills/` for applicable skills (especially `blue-team-soc-analysis.md`).

## Build & Test Commands

```bash
# Build default image (local only)
PUSH=0 ./build-amd64-image.sh

# Start SOC baseline stack
docker compose -f deploy/compose/soc-baseline.yml up -d

# Bootstrap security (fresh stack after down -v)
./scripts/bootstrap-wazuh-security.sh

# Run acceptance gate
ANALYST_IMAGE=<image:tag> ./scripts/validate-analyst-image.sh
```

## Cross-Repo Context

| Repository | Relationship |
|------------|-------------|
| `core-nexus` | Architecture hub — this repo must stay aligned |
| `nexus-webtop-workbench` | Recommended analyst workbench (preferred over this repo's XFCE image) |
| `athena-agents` | LLM agent traffic source — labels must be filterable in SOC dashboards |

## Guardrails

- Do not modify cert paths in `bootstrap-wazuh-security.sh` without updating indexer layout.
- Do not hardcode credentials in Dockerfiles or scripts.
- When adding Phase 2 candidates: create Dockerfile, add to evaluation matrix, document in `docs/base-image-migration.md`.
- Keep changes aligned with the Underground Nexus architecture in `core-nexus`.
