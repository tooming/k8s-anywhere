# KEDA event-driven autoscaling engine (new CHARTER Goal)

**Genuinely new architect-tier feature work**, found via the coverage/hardening
fallback pass after every gated `Now / next` item and every doc-drift/coverage gap
(#442, #443) turned up empty this round. Rather than defaulting to smaller filler,
re-read CHARTER's Vision/Goals for a genuinely uncovered CNCF pattern — same discipline
that found cert-manager (`docs/done/2026-07-16-cert-manager-engine.md`).

## Gap found

Every workload in the lab scales exactly one way: not at all, or by hand — no HPA, no
queue-depth-driven scaling, nothing demonstrating "scale on a real signal, not a timer."
The lab already runs both ingredients that make that pattern real rather than synthetic
(RabbitMQ, ADR-0009; Prometheus-compatible metrics via Mimir), but nothing consumes
them for autoscaling. Against the CHARTER Vision and the existing "progressive
delivery" Goal (Argo Rollouts already teaches *which version*; nothing teaches *how
many replicas*), this is a real, substantial gap.

## What shipped

**New `docs/decisions/adr-0029-keda-event-driven-autoscaling.md`** (architect
decision, self-authorizing per WAYS-OF-WORKING.md §0.1/§2 — new ground): adopts KEDA,
chart `keda` v2.18.0 from `https://kedacore.github.io/charts`. Verified directly
against the pinned chart's real `values.yaml` (fetched via the sparse-clone technique
this ROADMAP documents for proxy-blocked Helm indexes — the chart's newer releases
live on per-version branches, not tags, so `git clone --branch release/v2.18 --sparse`)
that operator/metricServer/webhooks **all default to the full PSS `restricted`
profile** — the second always-on component after cert-manager to need zero carve-out.
Confirmed the `scaledjobs` CRD is ~634 KB (needs `ServerSideApply=true`, same failure
class as Kyverno/cert-manager). Verified the admission webhook port (9443) and the
real Prometheus metric names (`keda_scaler_active`, `keda_scaled_object_paused`,
`keda_scaler_metrics_value`, ...) against the pinned tag's actual Go source
(`pkg/metricscollector/prommetrics.go`), not guessed from docs — same
verify-before-asserting discipline ADR-0004 requires for dashboards, extended to
architecture research.

**New CHARTER.md content**: a Goal ("event-driven autoscaling") and a Target end-state
entry, both citing ADR-0029.

**Built now (this PR)**: the KEDA engine itself — auto-synced Application, namespace
with zero-carve-out `restricted` PSA, default-deny NetworkPolicy overlay, Alloy scrape
job, Grafana dashboard, and (unlike the cert-manager PR) the O5 dashboard-coverage
sweep entry landed in the *same* PR rather than as a follow-up — closing the exact
class of gap #442 had to fix retroactively for cert-manager, immediately this time.

**Explicitly deferred** (ADR-0029 §"Scope & exceptions", follow-up ROADMAP items):
wiring the admission webhook's TLS to cert-manager's `k8s-lab-ca` ClusterIssuer (the
chart supports this natively via `certificates.certManager` — confirmed in
`values.yaml` — which would give cert-manager a second real consumer beyond the
Gateway); and a real `ScaledObject` demo scaling a workload on the `data` namespace's
RabbitMQ queue depth (the actual pedagogical payoff — installed vs. demonstrated).

**Manifests**: `gitops/platform/keda.yaml` (+`-extras`, `-networkpolicy`),
`gitops/keda/namespace.yaml`, `gitops/keda/networkpolicy/`. `gitops/platform/observability-alloy.yaml`
new `keda` scrape job (targets the operator Service specifically — where all the
interesting reconciliation metrics are actually emitted, not metricServer/webhooks).
`grafana/dashboards/lab-keda.json` (9 panels, real `keda_*` series only, ADR-0004).

**Bats coverage**: `tests/keda.bats` (27 cases: Application shape, chart pin, CRD
install mode, footprint limits, ServerSideApply, PSA labels, NetworkPolicy overlay,
scrape job, dashboard, and an "additive-only" proof that no `ScaledObject`/`ScaledJob`
references any workload yet). Plus the two O2 recurrence-guard files:
`tests/securitycontext-keda.bats` and `tests/networkpolicy-keda.bats`, and the new
`KEDA_NP` path in `tests/lib/networkpolicy-paths.bash`.

**Docs**: `docs/dependency-tree.md` (wave table rows 0/1/4 + a full component
description paragraph), `docs/decisions/adr-0017-pod-security-standards-restricted.md`
(new `keda: restricted` row, zero carve-out), `docs/decisions/README.md` (ADR index
entry), `README.md` (new "Autoscaling" stack-table row).

## Real findings caught during research (before any manifest was written)

- The chart index (`kedacore.github.io/charts`) is proxy-blocked in this sandbox, same
  as `charts.jetstack.io`; the chart's git repo publishes recent versions on
  `release/vX.Y` branches rather than tags — a different sparse-checkout shape than
  cert-manager's tag-per-release convention, discovered by checking `git ls-remote`
  before assuming the same pattern applied.
- The chart supports native cert-manager integration
  (`certificates.certManager.enabled` + a custom `issuer.name`/`kind`/`group`) —
  found by reading the full `values.yaml`, not just the sections needed for this PR's
  scope, which directly shaped the "wire to `k8s-lab-ca`" follow-up item instead of a
  vaguer "improve webhook TLS someday" placeholder.
- Verified the real metric names against Go source rather than assuming from the
  project's docs pages (which this sandbox can't reliably fetch anyway) — same
  ADR-0004-extended-to-research discipline the cert-manager PR established for the
  webhook port number.

## Verification

Full local `make ci` green (see PR CI status). `bash scripts/validate-manifests.sh`
(kubeconform) and `validate-kustomize.sh` both pass, including the new
`gitops/keda/networkpolicy` overlay. `shellcheck`/`yamllint` clean.
`kedacore.github.io/charts` is proxy-blocked in this sandbox (same class as other Helm
repo indexes noted earlier in this ROADMAP) — `helm-chart-pin-check.sh` and
`argocd-crd-ssa-check.sh` both degrade to a tolerant skip for this one chart, exactly
as designed; the chart version itself (2.18.0) was confirmed to exist via the chart
repo's `release/v2.18` branch, which is reachable via git.

## PR

Autonomous session run — see the `claude/work-until-credits-exhausted-b828b2` branch.
