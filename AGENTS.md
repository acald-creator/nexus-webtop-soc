# Agent Instructions

Use `architecture.md` as the canonical architecture guide for this repository.

Codex-specific expectations:

- Treat this repository as the legacy SOC analyst webtop, not the final SOC runtime.
- Move detection services toward dedicated Wazuh, Suricata, optional Zeek, and AI triage workloads.
- Do not add new SOC control-plane services into the desktop image by default.
- Keep credentials and certificates out of images.
- Keep changes aligned with the Underground Nexus architecture in `core-nexus`.
