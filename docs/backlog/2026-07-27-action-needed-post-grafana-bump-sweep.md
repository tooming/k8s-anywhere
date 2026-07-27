# [Action needed] Now/next still gated; Grafana chart bump shipped, two fresh sweeps also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, `updated_at` unchanged since
2026-07-21.

## What this run already shipped

This run's first cycle worked the full STEP 6b fallback chain (planner and
architect passes found nothing new to groom or RFC — issues unchanged, no
`docs/roadmap/incoming/` files, no 🟡 items without an RFC) and landed as
upgrade-drafter: `gitops/platform/observability-grafana.yaml`'s chart
`targetRevision` bumped `12.8.0` → `12.8.1` (real, published 2026-07-26
patch release, CI/docs-only changes, no CVE — verified directly against the
chart's `Chart.yaml`, release notes, and `templates/_pod.tpl` at the new
tag). Merged as PR #758 with all 7 CI checks green (2299/2299 bats
assertions).

## This cycle's fresh angles

1. **Artifactory chart-pin re-check, correctly held.** The architect-role
   upstream sweep this run flagged `gitops/platform/artifactory.yaml`'s pin
   (`107.77.11`) as far behind upstream (`107.146.29`, published 2026-07-22,
   confirmed via the chart's `Chart.yaml` and GitHub release tag page — no
   CVE in the changelog). Before drafting the bump, checked prior history:
   `docs/backlog/2026-07-22-action-needed-chart-sweep-jul22.md` already
   evaluated this **exact** version pair five days ago and explicitly
   decided **not** to pursue it — Artifactory is mid-decommission (ADR-0024:
   Harbor supersedes it; ROADMAP's `Decommission Artifactory manifests` item
   is queued, gated behind #632) and bumping a pin on a component already
   scheduled for deletion is pure churn on code with a known, better outcome
   already queued. Nothing has changed since that decision (#632 still
   unconfirmed, decommission still queued) — correctly re-held, not bumped.
   (Caught this before committing — had drafted the bump, then reverted on
   finding the prior note.)
2. **O5 dashboard-coverage cross-check (new lens, full sweep).** Enumerated
   every ArgoCD `Application` under `gitops/platform/*.yaml` with a
   `spec.syncPolicy.automated` block (61 total, via `yq` over every file —
   not a sample) and cross-referenced each real workload component against
   `tests/dashboard-coverage.bats`'s enforced `MIMIR_DASHBOARDS` list (25
   entries) plus the three individually-tested LGTMP dashboards
   (logs/profiles/traces). Every real component maps to a dashboard (direct
   name match, or a documented aggregate like `lab-cloud-control-plane`
   covering `kro`/`moto`/`ack-s3`, or `lab-ksm` covering
   `kube-state-metrics`). The one questionable case, `lab-gateway` (the bare
   Gateway API `Gateway`/`GatewayClass` object in `gitops/network`), has no
   separate dashboard — correct: it's a configuration object, not a
   scrapeable component: its serving path (Envoy Gateway's data/control
   plane) is already covered by `lab-envoy.json`. No gap found.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
