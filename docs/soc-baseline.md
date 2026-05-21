# SOC Baseline (Phase 1)

This baseline is the first practical step toward the proposed SOC split:

- Wazuh manager, indexer, and dashboard run as dedicated services.
- Suricata runs as a dedicated sensor.
- Suricata `eve.json` is forwarded into Wazuh manager over UDP `1514`.
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
Compose healthchecks gate startup ordering for manager, dashboard, and the Suricata forwarder.

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

On a fresh stack (`down -v`), initialize indexer security once:

```sh
./scripts/bootstrap-wazuh-security.sh
```

This command is safe to rerun; it reconciles security config and restarts manager/dashboard.

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

Option C: use the experimental Chainguard-transition analyst image.

Build in this repository:

```sh
DOCKERFILE=Dockerfile.xfce.amd64.chainguard TAG_SUFFIX=cg PUSH=0 ./build-amd64-image.sh
```

Then run with explicit override:

```sh
WEBTOP_ANALYST_IMAGE=phoenixvlabs/nexus-webtop-soc:amd64-cg-latest \
docker compose -f deploy/compose/soc-baseline.yml --profile analyst up -d webtop.analyst
```

## Access

Default local ports:

- Wazuh Dashboard: `http://localhost:5601`
- Wazuh Indexer (OpenSearch API): `https://localhost:9200`
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
- HTTPS and default local admin credentials are used for indexer and dashboard wiring.
- Dashboard credentials are local defaults in this baseline (`admin` or `kibanaserver` depending on image defaults).
- Suricata runs with packet capture capabilities (`NET_ADMIN`, `NET_RAW`) and should remain isolated to lab networks.
- Suricata event forwarding uses a lightweight `busybox` tail-and-forward pattern as a Phase 1 bridge.
- This stack does not yet include full agent enrollment automation or AI enrichment.

## Verify Suricata Event Forwarding

Check the forwarder container:

```sh
docker compose -f deploy/compose/soc-baseline.yml logs --tail=50 suricata.forwarder
```

Generate traffic from a container in `soc-net` and confirm Suricata writes events:

```sh
docker compose -f deploy/compose/soc-baseline.yml exec suricata.sensor \
  sh -c "tail -n 20 /var/log/suricata/eve.json"
```

Then inspect Wazuh manager logs:

```sh
docker compose -f deploy/compose/soc-baseline.yml logs --tail=100 wazuh.manager
```

## Analyst Image Smoke Check

After changing `WEBTOP_ANALYST_IMAGE`, verify:

```sh
docker compose -f deploy/compose/soc-baseline.yml ps webtop.analyst
curl -I --max-time 10 http://localhost:3000
docker exec webtop.analyst bash -lc 'git --version && curl --version | head -n 1'
```

## Next Milestone

After this baseline is stable:

1. Replace the bridge forwarder with explicit Suricata event parsing and normalized Wazuh mapping.
2. Add one Wazuh agent enrollment example.
3. Add AI triage as a separate service with versioned scoring metadata.
