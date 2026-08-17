# Gemini Instructions

Use `architecture.md` as the canonical architecture guide for this repository.

## Strengths for This Repo

- Comparing SOC service image options and deployment patterns.
- Researching Wazuh, Suricata, Zeek, and dashboard deployment patterns.
- Reviewing Chainguard or other minimal image options for dedicated SOC services.
- Evaluating SOC dashboard options for filtering agent-generated vs real traffic.

## Current Pinned Versions

Evaluate upgrades and alternatives against these current pins:

| Component | Current image | Version |
|-----------|--------------|---------|
| Wazuh stack | `wazuh/wazuh-{indexer,manager,dashboard}` | `4.7.5` |
| Suricata | `jasonish/suricata` | `7.0` |
| Forwarder | `busybox` | `1.36` |
| Desktop base | `linuxserver/webtop` | `amd64-ubuntu-xfce` |
| Phase 2a base | `cgr.dev/chainguard/wolfi-base` | `latest` |

## Standing Research Questions

- Does Chainguard publish dedicated Wazuh application images?
- What is the latest stable Suricata release and does `jasonish/suricata` track it?
- Are there better alternatives to the `busybox` `tail -F | nc -u` forwarder pattern?
- What is the current Wazuh LTS/stable release track?
- What are minimal base image options for a web-accessible analyst desktop?
- How should SOC dashboards filter Athena stimulation traffic from production alerts?

## Output Expectations

- Cite sources and distinguish current facts from assumptions.
- Score alternatives against criteria in `docs/base-image-migration.md`.
