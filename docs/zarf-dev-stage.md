# Zarf Dev Stage

This repository is ready to test Zarf in the **dev packaging stage**.

At this stage, Zarf is used to validate:

- image mirroring for SOC baseline dependencies
- packaging of compose baseline files and validation scripts
- offline transport workflow readiness

Current scope excludes private analyst image tags (`phoenixvlabs/nexus-webtop-soc:*`) to keep dev-stage packaging reproducible across environments.

At this stage, Zarf is **not yet** the runtime deployment method for SOC services in this repo.
Runtime remains compose-driven while Kubernetes manifests are prepared.

## When to Run This

Run this after Phase 2 candidate validation is stable (for example `cg` and `phase2b` image tracks) and before Kubernetes packaging.

## Commands

Create the package:

```sh
zarf package create deploy/zarf --confirm
```

Deploy the generated package:

```sh
zarf package deploy zarf-package-nexus-webtop-soc-dev-amd64-0.1.0.tar.zst --confirm
```

Deploy only the optional Phase 2 Kubernetes scaffold component:

```sh
zarf package deploy zarf-package-nexus-webtop-soc-dev-amd64-0.1.0.tar.zst --components phase2-kubernetes-scaffold --confirm
```

## What This Confirms

- Required images can be mirrored and bundled
- Core SOC baseline assets are bundled consistently
- Team can execute repeatable offline package create/deploy loops
- Kubernetes packaging flow is wired for Phase 2 using placeholder manifests

## Next Stage

Add Kubernetes manifests (or generated manifests) for SOC services and convert this package from dev packaging validation to deployable runtime packaging.
