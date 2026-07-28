# [Action needed] Now/next still gated; Grafana dashboard integrity sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped sixteen real, merged deliverables (PRs
#789, #790, #792–#805), including two live-cluster bugfixes (#796, #797).

This cycle ran two structural checks across all 35 `grafana/dashboards/*.json` files,
both clean:

1. **Unique `uid` check.** Grafana's Git Sync provisioning silently conflicts if two
   dashboards share a `uid` (one would overwrite/fight the other). Parsed every
   dashboard's top-level `uid` field — all 35 are distinct, no collisions.
2. **Literal-constant `expr` sweep (ADR-0004).** Existing `tests/observability.bats`
   assertions already grep each dashboard for fabricated-data *keywords* (`fake`, `mock`,
   `placeholder`, `dummy`, `todo`, `fixme`); this cycle checked a different fabrication
   shape those keyword greps can't catch: a panel `expr` field that is a bare numeric
   literal (e.g. `"expr": "5"`) with no real metric name or PromQL function at all —
   effectively a hardcoded fake value disguised as a query. None found across any panel
   in any dashboard.

No actionable gap surfaced from either lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
