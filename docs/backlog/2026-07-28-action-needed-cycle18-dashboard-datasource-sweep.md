# [Action needed] Now/next still gated; dashboard datasource-reference sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped seventeen real, merged deliverables (PRs
#789, #790, #792–#806), including two live-cluster bugfixes (#796, #797).

This cycle extended last cycle's dashboard-integrity checks with a datasource-reference
sweep: parsed every `grafana/dashboards/*.json` panel's `datasource.uid` field and
checked it resolves to one of the four datasources actually defined in
`gitops/platform/observability-grafana.yaml`'s `datasources.datasources.yaml` block
(`mimir`, `loki`, `tempo`, `pyroscope`) — a real correctness constraint, since a
dashboard referencing an unknown datasource UID renders as a broken panel on a live
cluster (a class of drift `make ci`'s existing checks don't catch, and this remote
session can't observe directly since it's clusterless). All 35 dashboards' datasource
references resolve cleanly; no unknown UID found.

No actionable gap surfaced from this lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
