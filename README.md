# Nexus Webtop SOC

Nexus Webtop SOC is the legacy analyst desktop image for the Underground Nexus SOC environment.

The proposed architecture moves SOC runtime services out of this webtop image. Wazuh, Suricata, optional Zeek, and AI triage should run as dedicated services. The webtop should become a client workspace for analysts, not the place where detection infrastructure is compiled and hosted.

## Current Status

The current image is based on `linuxserver/webtop:amd64-ubuntu-xfce`, installs GitKraken, and builds Suricata from source inside the image. That works for experimentation, but it mixes analyst desktop tooling with SOC detection runtime.

See [architecture.md](architecture.md) for the proposed architecture.

## Target Role

The webtop SOC image is responsible for:

- Analyst desktop access.
- Browser access to Wazuh Dashboard, Grafana, and documentation.
- Notes, terminals, and controlled investigation tooling.
- Optional GUI utilities for local lab investigation.

The webtop SOC image is not responsible for:

- Running Wazuh manager, indexer, or dashboard services.
- Running Suricata as an embedded desktop process.
- Compiling production SOC tools inside a GUI image.
- Storing SOC events.
- Hosting AI triage services.

## Target SOC Split

| Component | Target location |
| --- | --- |
| Wazuh manager | Dedicated SOC service |
| Wazuh indexer | Dedicated persistent event store |
| Wazuh dashboard | Dedicated dashboard service |
| Wazuh agents | Host and workload telemetry collectors |
| Suricata | Dedicated network/protocol sensor |
| Optional Zeek | Later protocol metadata sensor |
| AI triage | Dedicated enrichment service |
| Webtop | Analyst client workspace |

## Image

Current image:

```sh
docker pull phoenixvlabs/nexus-webtop-soc:amd64-latest
```

Current build asset:

```text
Dockerfile.xfce.amd64
```

Current build helper:

```text
build-amd64-image.sh
```

Experimental Chainguard transition build:

```sh
DOCKERFILE=Dockerfile.xfce.amd64.chainguard TAG_SUFFIX=cg PUSH=0 ./build-amd64-image.sh
```

## First Milestone: Local SOC Baseline

The first practical milestone is now captured in:

- [docs/soc-baseline.md](docs/soc-baseline.md)

This baseline runs:

- Wazuh manager
- Wazuh indexer
- Wazuh dashboard
- Suricata sensor
- Suricata event forwarder into Wazuh manager
- Analyst webtop client (optional `analyst` profile)

Start it with:

```sh
docker compose -f deploy/compose/soc-baseline.yml up -d
```

The compose stack now uses healthchecks and dependency conditions for deterministic service startup ordering.

For a fresh stack (`down -v`), initialize indexer security:

```sh
./scripts/bootstrap-wazuh-security.sh
```

If you have built the workbench image locally, enable the analyst profile:

```sh
docker compose -f deploy/compose/soc-baseline.yml --profile analyst up -d
```

By default, the analyst profile now uses `phoenixvlabs/nexus-webtop-soc:amd64-cg-latest`.  
To use a different analyst image (workbench local or classic XFCE), override `WEBTOP_ANALYST_IMAGE` as documented in [docs/soc-baseline.md](docs/soc-baseline.md).

## Local-Only and Deprecated Direction

| Item | Status | Direction |
| --- | --- | --- |
| Suricata built inside the webtop image | Deprecated direction | Move Suricata into a dedicated sensor image. |
| GitKraken in SOC desktop | Optional | Keep only if needed by analyst workflow; prefer browser or CLI Git workflows. |
| SOC control plane inside a desktop image | Deprecated direction | Split Wazuh services into dedicated workloads. |
| Single `amd64` image only | Current limitation | Add architecture strategy if this image remains in use. |
| Credentials or certificates in image | Not allowed | Use Vault HA or selected platform secret manager. |

## Supply Chain

This repository includes:

```text
soc-admin-webtop-amd64-latest.spdx
```

Historical Cosign, Syft, and attestation examples should move into dedicated supply-chain documentation if they need to be preserved. The README should stay focused on role, build path, architecture direction, and what is being moved out of the image.

## AI Collaboration

AI assistants should use these entrypoints:

- [AGENTS.md](AGENTS.md) for Codex-style coding agents.
- [CLAUDE.md](CLAUDE.md) for architecture critique and threat modeling.
- [GEMINI.md](GEMINI.md) for research and platform comparison.
- [architecture.md](architecture.md) as the source of truth for the proposed SOC split.

## License

See [LICENSE](LICENSE).
