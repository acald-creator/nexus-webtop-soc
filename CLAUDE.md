# Claude Instructions

Use `architecture.md` as the canonical architecture guide for this repository.

Claude is especially useful for:

- Reviewing the split between analyst desktop and SOC runtime.
- Finding places where Suricata or Wazuh responsibilities are mixed into the webtop.
- Checking security claims and credential handling.
- Clarifying what should move into dedicated SOC services.

Return findings with file references and avoid rewriting implementation unless explicitly asked.

### Credential and Secret Locations

When reviewing security, these are the current credential touchpoints:

- `deploy/compose/soc-baseline.yml` lines 40-43: indexer connection credentials (`admin`/`admin`)
- `deploy/compose/soc-baseline.yml` lines 74-80: dashboard credentials and SSL settings
- `scripts/bootstrap-wazuh-security.sh` lines 37-43: TLS certificate paths used for securityadmin
- Dockerfiles: should contain NO credentials (verify this)

### File-to-Concern Mapping

| Concern | Files |
|---------|-------|
| Analyst desktop | `Dockerfile.xfce.amd64`, `Dockerfile.xfce.amd64.chainguard`, `Dockerfile.phase2a.amd64` |
| SOC infrastructure | `deploy/compose/soc-baseline.yml`, `deploy/suricata/suricata.yaml` |
| Operations/bootstrap | `scripts/bootstrap-wazuh-security.sh`, `scripts/validate-analyst-image.sh` |
| Evaluation | `scripts/evaluate-phase2-matrix.sh`, `scripts/run-phase2-candidate.sh`, `docs/reports/` |
| Architecture decisions | `architecture.md`, `docs/phase2-base-image-migration.md` |

### Expected Output Format

When asked to review, return findings as:

1. File path and line range
2. What was found
3. Why it matters (security, architectural drift, or operational risk)
4. Suggested action (if applicable)
