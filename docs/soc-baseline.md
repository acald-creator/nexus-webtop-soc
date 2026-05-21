# SOC Baseline (Phase 1)

This baseline is the first practical step toward the proposed SOC split:

- Wazuh manager, indexer, and dashboard run as dedicated services.
- Suricata runs as a dedicated sensor.
- Webtop is only the analyst client.

This is a local lab baseline, not a production deployment.

## Compose Stack

Compose file:

```text
deploy/compose/soc-baseline.yml
```

Suricata config:

```text
deploy/suricata/suricata.yaml
```

Analyst webtop image reference:

- Default: `nexus-webtop-workbench:local`
- Override with `WEBTOP_ANALYST_IMAGE=<image:tag>`

## Start

From the repository root:

```sh
docker compose -f deploy/compose/soc-baseline.yml up -d
```

This starts the SOC core services only (indexer, manager, dashboard, and Suricata sensor).

Check status:

```sh
docker compose -f deploy/compose/soc-baseline.yml ps
```

## Enable Analyst Webtop

Use one of these options, then start the `analyst` profile.

Option A (recommended): use the dedicated workbench image from `nexus-webtop-workbench`.

Build in the `nexus-webtop-workbench` repository:

```sh
docker build -f Dockerfile.mate.amd64 -t nexus-webtop-workbench:local .
```

Then from this repository:

```sh
docker compose -f deploy/compose/soc-baseline.yml --profile analyst up -d
```

Option B: use this repository's XFCE SOC webtop image.

Build in this repository:

```sh
docker build -f Dockerfile.xfce.amd64 -t nexus-webtop-soc:local .
```

Then run with an explicit image override:

```sh
WEBTOP_ANALYST_IMAGE=nexus-webtop-soc:local \
docker compose -f deploy/compose/soc-baseline.yml --profile analyst up -d
```

## Access

Default local ports:

- Wazuh Dashboard: `http://localhost:5601`
- Wazuh Indexer (OpenSearch API): `http://localhost:9200`
- Wazuh Manager API: `https://localhost:55000`
- Analyst webtop: `http://localhost:3000` (when `analyst` profile is enabled)

## Stop

```sh
docker compose -f deploy/compose/soc-baseline.yml down
```

To remove volumes too:

```sh
docker compose -f deploy/compose/soc-baseline.yml down -v
```

## Notes and Constraints

- The indexer is configured for single-node local mode.
- TLS and security plugin hardening in the indexer are reduced for local startup simplicity.
- Dashboard credentials are local defaults in this baseline.
- Suricata runs with packet capture capabilities (`NET_ADMIN`, `NET_RAW`) and should remain isolated to lab networks.
- This stack does not yet include agent enrollment automation or AI enrichment.

## Next Milestone

After this baseline is stable:

1. Route Suricata `eve.json` into Wazuh ingestion with explicit parsing.
2. Add one Wazuh agent enrollment example.
3. Add AI triage as a separate service with versioned scoring metadata.
