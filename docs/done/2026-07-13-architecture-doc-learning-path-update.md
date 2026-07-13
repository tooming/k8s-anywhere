# `docs/00-architecture.md` — add learning-path steps for DR/blue-green and GitOps promotion (Kargo)

CHARTER **Goals** gap — "DR / blue-green on a single host" is an explicit Goal that did
not appear in the learning-path steps 0–9; Kargo promotion pipelines are deployed and
documented in the Who-does-what table but were absent from the learning-path narrative.
Two additions to the `## Suggested learning path` section:

(a) **Step 10 — DR / blue-green**: explains `make dr-bluegreen` (second k3d "green"
cluster sourcing the same `gitops/` repo, Envoy Gateway traffic cutover, service
continuity verification, `make dr-bluegreen-promote` to retire blue), cross-referencing
`docs/DR.md §Zero-downtime blue/green`. Notes steps 8 and 10 test two distinct recovery
modes: Velero restores data on the same cluster; blue-green rebuilds the whole platform
on a fresh cluster under live traffic.

(b) **Step 11 — GitOps promotion pipelines**: describes Kargo's `Warehouse`/`Stage`
promotion flow (dev auto-promote, prod manual gate), the Kargo UI and Grafana dashboard,
cites ADR-0023, and explains how it complements Argo Rollouts (traffic shaping vs.
promotion-stage gating).

Docs-only, no code changes.

## PR

https://github.com/tooming/k8s-anywhere/pull/385
