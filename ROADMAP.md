# Nexus Webtop SOC Roadmap

Aligned with the [100 Days of Underground Nexus](../core-nexus/docs/100-days-challenge.md) challenge.

## Completed

- [x] SOC baseline compose stack (Wazuh Manager + Indexer + Dashboard + Suricata)
- [x] Dedicated Suricata sensor (not embedded in desktop image)
- [x] Bootstrap security script for fresh deployments
- [x] Analyst image validation gate (`validate-analyst-image.sh`)
- [x] Runtime candidate evaluation matrix (Phase 2 candidates)
- [x] Chainguard transition track Dockerfile
- [x] Agent instruction files updated for LLM workflow context

## Phase 1: Foundation (Days 1-20)

- [ ] Verify SOC stack starts cleanly alongside core-nexus dev compose
- [ ] Configure Suricata to monitor the `athena_lab` network bridge
- [ ] Verify Athena agent traffic appears in Wazuh with correct metadata
- [ ] Document the alert pipeline path: Athena → Suricata → Wazuh → API Gateway

## Phase 2: Detection Engineering (Days 21-40)

- [ ] Write custom Suricata rules to detect Athena SQLi patterns
- [ ] Write Suricata rules to detect Athena brute-force traffic
- [ ] Write Suricata rules to detect Modbus TCP enumeration
- [ ] Tune rules to reduce false positives for labeled (known-simulation) traffic
- [ ] Add alert field for `athena_scenario` so dashboards can filter
- [ ] Measure detection coverage (% of Athena actions generating alerts)
- [ ] Add Wazuh decoder for Athena ground-truth correlation

## Phase 3: Agent Intelligence (Days 41-60)

- [ ] Verify Wazuh API returns alerts in format consumable by API Gateway
- [ ] Add alert acknowledgment workflow (mark alerts as reviewed)
- [ ] Test full closed loop: agent runs → alerts appear → analyst triages in Console

## Phase 4: Hardening (Days 61-80)

- [ ] Move SOC stack into Kubernetes (Helm or kustomize)
- [ ] Add persistent volume claims for Wazuh indexer data
- [ ] Add NetworkPolicy restricting Suricata ingestion paths
- [ ] Evaluate Phase 2 runtime candidates for headless SOC (no desktop)
- [ ] Document production Wazuh deployment (HA indexer, multi-node)

## Phase 5: Advanced (Days 81-100)

- [ ] Add Zeek sensor alongside Suricata for protocol metadata
- [ ] Correlate Zeek + Suricata for richer detection context
- [ ] Integration with ICS-specific Suricata rulesets for Modbus/CAN detection
- [ ] Automated rule generation from Athena ground-truth patterns

## Deferred

- Production Chainguard Wazuh images (not yet published by Chainguard)
- Full Kubernetes HA deployment (requires dedicated infrastructure)
- Wazuh agent integration on host systems (beyond lab containers)
