# [Action needed] Now/next still gated; NetworkPolicy metrics-port consistency sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped nine real, merged deliverables (PRs #789,
#790, #792–#798), including two live-cluster bugfixes (#796, #797) found via a structural
cross-reference technique.

This cycle extended that technique once more: cross-checked every
`gitops/*/networkpolicy/allow-*metrics*.yaml` file's allowed port number against the
actual port the corresponding component exposes metrics on, per
`gitops/platform/observability-alloy.yaml`'s `prometheus.scrape` blocks (the second,
independent source of truth for "what port does this component's metrics endpoint
actually listen on"). Checked all 15 metrics-ingress NetworkPolicy files:
`inkless` (9308), `trivy-system` (8080), `argo-rollouts` (8090), `longhorn` (9500),
`velero` (8085), `cert-manager` (9402), `harbor` (9090), `kyverno` (8000), `keda` (8080),
`kargo` (8080), `external-secrets` (8080), `envoy-gateway-system` controller (19001) +
proxy (19000), `node-exporter` (9100), `istio-system` (15014). Every port matches the
Alloy scrape config exactly — no drift found (this is exactly the class of bug that
would silently break a Grafana dashboard's data without any `make ci` gate catching it,
since NetworkPolicy port mismatches only surface as "No data" panels on a live cluster,
which this remote clusterless session can't observe directly — hence checking it
structurally against the second source of truth instead).

No actionable gap surfaced from this lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
