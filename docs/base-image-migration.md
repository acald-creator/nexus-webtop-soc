# Runtime Base Image Migration Plan

This document defines how to move the analyst image from the current LinuxServer runtime toward a hardened base strategy with repeatable acceptance checks.

## Goal

Replace the desktop image runtime base in a controlled way while preserving analyst usability in the SOC baseline.

## Current State

- Primary baseline runtime: `linuxserver/webtop:amd64-ubuntu-xfce`
- Current default analyst image in compose: `phoenixvlabs/nexus-webtop-soc:amd64-cg-latest`
- Current `cg` track is a transition path, not yet a true non-LinuxServer runtime replacement.

## Decision Scope

Pick one Phase 2 target path:

1. Keep LinuxServer runtime temporarily and harden supply-chain + package policy.
2. Replace runtime with a custom minimal desktop stack on a hardened base.
3. Split analyst UI runtime and tooling into separate sidecar-style services.

## Current Decision

The runtime-a candidate (`Dockerfile.runtime-a.amd64`) follows **Option 2**: replace runtime with a custom minimal desktop stack on a hardened base.

The `runtime-a` candidate uses `cgr.dev/chainguard/wolfi-base` as the runtime base with nginx serving a placeholder page on port 3000. It validates the build, publish, and compose integration path without claiming desktop parity.

Matrix evaluation results (`docs/reports/runtime-evaluation-latest.md`) confirm:

- `runtime-a` passes plumbing checks (`DESKTOP_REQUIRED=0`)
- `runtime-a` correctly fails desktop-required checks (`DESKTOP_REQUIRED=1`)
- The Chainguard transition track (`cg`) passes all checks including desktop markers

Next step: build a `runtime-b` candidate that adds a minimal web desktop session to the wolfi-base runtime.

## Candidate Evaluation Criteria

Every candidate must be scored against:

- Analyst UX parity: web desktop responsiveness, clipboard, browser access, terminals.
- Compatibility: compose profile behavior and mounted volumes (`/config`, `/soc-shared`, `/nexus-bucket`).
- Security posture: package footprint, provenance/attestation path, default privileges.
- Operational simplicity: build complexity and local bootstrap friction.
- Reproducibility: deterministic build tags and repeatable smoke checks.

## Minimum Acceptance Gate

A candidate passes only if all checks pass:

1. `docker compose -f deploy/compose/soc-baseline.yml --profile analyst up -d` works with explicit image override.
2. `curl -I http://localhost:3000` returns `200`.
3. In-container checks succeed: `git --version`, `curl --version`.
4. SOC core services remain healthy during analyst rollout:
   - `wazuh.indexer` healthy
   - `wazuh.manager` healthy
   - `wazuh.dashboard` healthy
   - `suricata.sensor` healthy
5. `./scripts/bootstrap-wazuh-security.sh` still succeeds after a fresh `down -v`.

Run these checks with:

```sh
ANALYST_IMAGE=<candidate-image:tag> ./scripts/validate-analyst-image.sh
```

Desktop parity check is enabled by default (`DESKTOP_REQUIRED=1`).
For runtime-plumbing candidates that intentionally do not include desktop session components yet, run with:

```sh
DESKTOP_REQUIRED=0 ANALYST_IMAGE=<candidate-image:tag> ./scripts/validate-analyst-image.sh
```

To require an active desktop session process (not just installed marker binaries):

```sh
ACTIVE_DESKTOP_REQUIRED=1 ANALYST_IMAGE=<candidate-image:tag> ./scripts/validate-analyst-image.sh
```

To run the current candidate matrix and generate a report:

```sh
./scripts/evaluate-runtime-matrix.sh
```

Generated report:

- `docs/reports/runtime-evaluation-latest.md`

## Implementation Checklist

- Add candidate Dockerfile and keep existing Dockerfile unchanged.
- Build with `build-amd64-image.sh` using:
  - `DOCKERFILE=<candidate>`
  - `TAG_SUFFIX=<candidate-id>`
  - `PUSH=0` for local validation first
- Validate against the acceptance gate.
- Capture deltas: image size, startup behavior, known regressions.
- Promote only after passing the gate twice in clean local runs.

## Adding a New Candidate

To add a new Phase 2 candidate:

1. Create a new Dockerfile following the naming convention: `Dockerfile.<candidate-id>.amd64`
2. Add an entry to the `rows` array in `scripts/evaluate-runtime-matrix.sh` with scenario name, image reference, desktop-required flag, and expected outcome
3. Test locally: `DOCKERFILE=Dockerfile.<id>.amd64 TAG_SUFFIX=<id> PUSH=0 ./scripts/run-runtime-candidate.sh`
4. Run the full matrix: `./scripts/evaluate-runtime-matrix.sh`
5. Document findings in this file under a new subsection

## Recommended Immediate Next Step

Create the first true non-LinuxServer candidate Dockerfile and run the acceptance gate using a dedicated tag suffix (for example `runtime-a`).

Current scaffold:

- Candidate Dockerfile: `Dockerfile.runtime-a.amd64`
- Candidate Dockerfile: `Dockerfile.runtime-b.amd64`
- Build + gate wrapper: `scripts/run-runtime-candidate.sh`

Run:

```sh
DOCKERFILE=Dockerfile.runtime-a.amd64 TAG_SUFFIX=runtime-a PUSH=0 ./scripts/run-runtime-candidate.sh
```

Note: `runtime-a` is currently a runtime-plumbing candidate and does not claim XFCE analyst parity yet. The wrapper sets `DESKTOP_REQUIRED=0` by default.

`runtime-b` adds an explicit desktop marker package (`openbox`) for strict desktop-capability gate validation.
