# Nexus Webtop SOC Proposed Architecture

This document proposes a revised architecture for `nexus-webtop-soc`. The current image is a single XFCE webtop container that installs GitKraken and builds Suricata from source. That design works as an analyst desktop, but it makes the SOC runtime harder to secure, update, scale, and observe.

The proposed direction is to split the SOC into purpose-built services and use Chainguard images where they are available.

## 1. Current Image

```mermaid
graph TD
    A[linuxserver/webtop:amd64-ubuntu-xfce] --> B[XFCE Desktop]
    A --> C[GitKraken]
    A --> D[Suricata Built From Source]
    D --> E[Local SOC Tooling]
    B --> F[Browser-Based Analyst Desktop]
```

Current characteristics:

- Based on `linuxserver/webtop:amd64-ubuntu-xfce`.
- Installs desktop support packages with `apt`.
- Downloads and installs GitKraken as a `.deb`.
- Downloads Suricata source and compiles it inside the image.
- Builds only for `linux/amd64`.
- Mixes analyst desktop tooling and SOC detection runtime in one container.

## 2. Target Architecture

```mermaid
graph TD
    subgraph "Analyst Workspace"
        W[Webtop Analyst Workbench]
    end

    subgraph "SOC Control Plane"
        M[Wazuh Manager]
        I[Wazuh Indexer]
        D[Wazuh Dashboard]
    end

    subgraph "Detection Sensors"
        S[Suricata Sensor]
        Z[Optional Zeek Sensor]
        A[Wazuh Agents]
    end

    subgraph "AI Triage Layer"
        N[Python / NumPy Classifier]
    end

    S --> M
    Z --> M
    A --> M
    M --> I
    I --> D
    M --> N
    N --> I
    W --> D
```

Target characteristics:

- **Wazuh manager** handles rules, alert processing, API access, and agent management.
- **Wazuh indexer** stores and searches security events.
- **Wazuh dashboard** provides the SOC analyst interface.
- **Wazuh agents** collect host and container telemetry.
- **Suricata** runs as a dedicated network sensor instead of being embedded in the desktop image.
- **Optional Zeek** provides protocol metadata for richer network investigation.
- **Webtop** remains an analyst workbench for browser access, notes, terminals, and optional GUI tools.
- **AI triage** consumes normalized alerts and enriches them with a threat score or false-positive probability.

## 3. Chainguard Image Strategy

Prefer Chainguard application images for SOC services when available. The main goal is to reduce custom package installation and avoid compiling production security tooling inside a GUI image.

Recommended image ownership:

| Component | Preferred approach | Notes |
| --- | --- | --- |
| Wazuh manager | Chainguard Wazuh manager image | Primary SOC event processor |
| Wazuh indexer | Chainguard Wazuh indexer image | Persistent event search layer |
| Wazuh dashboard | Chainguard Wazuh dashboard image | Analyst UI |
| Wazuh agent | Chainguard Wazuh agent image | Host and workload telemetry |
| Suricata | Dedicated minimal sensor image | Use Chainguard if available; otherwise build a minimal sensor image separately |
| Webtop | Separate analyst workbench image | Do not embed the SOC control plane in the desktop image |

## 4. What Changes From the Current Dockerfile

The current `Dockerfile.xfce.amd64` should not be directly converted into a single Chainguard image. Instead, the rewrite should separate concerns.

Remove from the SOC runtime image:

- XFCE desktop dependencies.
- GitKraken installation.
- Build toolchain packages used only to compile Suricata.
- Suricata source compilation inside the final runtime image.

Move into dedicated components:

- Wazuh services as the SOC control plane.
- Suricata as a network sensor.
- Analyst desktop tooling into a separate webtop/workbench image.
- AI scoring into a small Python service that reads Wazuh or Suricata events.

## 5. Proposed Service Flow

1. Suricata observes approved lab network traffic and emits `eve.json` events.
2. Wazuh agents collect host, container, and workload telemetry.
3. Wazuh manager receives and normalizes alerts.
4. Wazuh indexer stores searchable events.
5. Wazuh dashboard presents SOC views for analysts.
6. The AI triage service reads normalized alerts and writes enriched scores back to the event stream.
7. The webtop workbench gives analysts a browser-based desktop for investigation, documentation, and controlled tooling.

## 6. Open Design Decisions

| Decision | Recommended default | Rationale |
| --- | --- | --- |
| Primary SOC platform | Wazuh manager, indexer, dashboard, and agents | Gives the SOC a real control plane instead of a desktop image. |
| Suricata event route | Send Suricata events to Wazuh first; optionally mirror to Vector/Loki | Wazuh should own security investigation data, while Loki should remain operational logging. |
| Packet capture model | Start with Docker lab capture on `Inner-Athena`; design Kubernetes capture separately | Avoid pretending one capture model works across Docker, Kubernetes, and Istio. |
| Zeek | Later enhancement | Suricata + Wazuh is enough for the first SOC baseline. |
| Wazuh persistence | Persistent volume for indexer data | Security events need searchable retention. |
| Certificates and secrets | Vault HA or selected platform secret manager | Do not bake credentials or certificates into images. |
| AI triage schema | Require `source_event_id`, `model_version`, `score`, `label`, and `reason` | Makes enrichment traceable and testable. |
| Existing webtop image | Move to client/workbench role only | Analyst GUI should not host the SOC runtime. |

## 7. First Implementation Milestone

The first implementation should create a working SOC baseline before adding AI enrichment.

Milestone scope:

- Wazuh manager, indexer, and dashboard running as separate services.
- One Wazuh agent connected to the manager.
- One Suricata sensor generating events.
- Dashboard access from the webtop workbench.
- Documented storage, credentials, and network ports.

After that baseline is stable, add the AI triage service as a separate workload.
