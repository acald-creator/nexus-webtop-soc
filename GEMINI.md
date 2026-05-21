# Gemini Instructions

Use `architecture.md` as the canonical architecture guide for this repository.

Gemini is especially useful for:

- Comparing SOC service image options.
- Researching Wazuh, Suricata, Zeek, and dashboard deployment patterns.
- Reviewing Chainguard or other minimal image options for dedicated SOC services.

When using external information, cite sources and distinguish current facts from assumptions or future design ideas.

### Current Pinned Versions

Evaluate upgrades and alternatives against these current pins:

| Component | Current image | Version |
|-----------|--------------|--------|
| Wazuh stack | `wazuh/wazuh-{indexer,manager,dashboard}` | `4.7.5` |
| Suricata | `jasonish/suricata` | `7.0` |
| Forwarder | `busybox` | `1.36` |
| Desktop base | `linuxserver/webtop` | `amd64-ubuntu-xfce` |
| Phase 2a base | `cgr.dev/chainguard/wolfi-base` | `latest` |

### Evaluation Criteria

When comparing image options, score against the criteria defined in `docs/phase2-base-image-migration.md`:

- Analyst UX parity
- Compose profile compatibility
- Security posture and package footprint
- Operational simplicity
- Reproducibility

### Standing Research Questions

- Does Chainguard publish dedicated Wazuh application images (manager, indexer, dashboard, agent)?
- What is the latest stable Suricata release and does `jasonish/suricata` track it?
- Are there better alternatives to the `busybox` `tail -F | nc -u` forwarder pattern for Suricata-to-Wazuh event forwarding?
- What is the current Wazuh LTS/stable release track?
- What are minimal base image options for a web-accessible analyst desktop (alternatives to LinuxServer webtop)?
