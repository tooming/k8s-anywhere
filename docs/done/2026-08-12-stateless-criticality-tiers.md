# Stateless-surface criticality tiering — closes DORA audit Q2's named gap

(CHARTER **Core Values** §"Everything as code" / operational-resilience discipline;
planner-fallback gap analysis 2026-08-12, reached via `executor.prompt.md` STEP 6b
PLANNER role after this run's Now/next lane was found fully gated — all six
remaining items are either an explicit live-cluster-only flip (`auto/
forgejo-argocd-repo-secret`'s successor) or gated on the still-unconfirmed standing
`[Action required]` issues #631/#633 (re-checked this cycle: both still open, most
recent comments 2026-08-11, neither confirms the gate). A currency sweep this same
cycle (ArgoCD, Trivy Operator, Grafana, Loki/Tempo/Pyroscope, Kargo, RabbitMQ,
Cilium, cert-manager, Velero, KEDA all checked directly against upstream tags —
Longhorn deliberately held at `1.11.3` per ADR-0013's own binding flip condition,
re-confirmed unfired) found nothing stale enough to bump. **No prerequisites —
executor may pick up immediately.**) Verified directly (not assumed, ADR-0004):
`docs/dora-audit-readiness.md` Q2 ("Are critical functions/assets identified and
mapped to supporting ICT systems?") answers yes for the *stateful* surface only —
CHARTER Objective O3 names the six stateful namespaces (`data`, `tidb`, `capstone`,
`vault`, `observability`, `inkless`) as critical — and its own "Gap" line states
plainly: "no equivalent criticality tiering for the *stateless* surface (e.g., is
Envoy Gateway more critical than Kiali? Implicit from always-on/on-demand split,
never stated as a tier)." `docs/incident-log.md` already has a binding P0–P3
severity scheme (whole-lab-down/data-loss; single always-on component down/
security gap; on-demand component broken; cosmetic) used for every real incident
logged there — grepped directly, confirmed no existing doc maps each *component*
to which tier its own outage would trigger, only individual past incidents.

Added a "Stateless component criticality tiers" section to
`docs/dora-audit-readiness.md` directly under Q2, reusing `docs/incident-log.md`'s
existing P0–P3 scheme rather than inventing a new one. One row per always-on
stateless component (Cilium, Envoy Gateway, ArgoCD, Vault, External Secrets,
Kyverno, Garage, Alloy, GitLab, Grafana, Mimir/Loki/Tempo/Pyroscope/KSM/
node-exporter, cert-manager, KEDA, RabbitMQ/Valkey, moto/ACK/KRO, Argo Rollouts,
Velero, Trivy Operator) with a one-line justification grounded in what the
component's outage actually breaks — not a guess. On-demand heavy components
(Harbor, TiDB, Istio+Kiali, Longhorn, Kargo) are explicitly out of scope — they're
already covered by the severity scheme's own P2 "on-demand/heavy component broken"
row.

Two components are tiered P0 (whole-lab-down): Cilium (the only component with a
real documented P0 incident in `docs/incident-log.md` to date — the 2026-07-29
apiserver-connectivity loss) and Envoy Gateway (the sole north-south ingress front
door per ADR-0008 — an outage of the gateway itself, distinct from the two logged
P1 NetworkPolicy-gap incidents against it, means total external unreachability by
the scheme's own P0 definition, even though no incident has hit that exact failure
mode yet). Six components are tiered P1 (ArgoCD, Vault, External Secrets, Kyverno,
Garage, Alloy) — each justified against either a real documented incident (Vault's
4+-day-sealed outage, per `gitops/vault/unsealer.yaml`'s header comment) or a
structural property verified directly in the repo (Kyverno's `failurePolicy:
Ignore`, confirmed via `grep` against `verify-image-signatures.yaml`, meaning an
outage fails open rather than blocking deploys — a security gap, not a functional
one). The remaining components are tiered P2, individually justified against what
narrow, non-cascading impact their own outage causes.

Corrected Q2's "Gap" line to point at the new section instead of restating the gap
as open.

## Recurrence guard

New `tests/dora-audit-readiness.bats` (distinct from the pre-existing, unrelated
`tests/dora-metrics.bats`, which covers CHARTER O7's `make dora-metrics` delivery
metrics — a different feature): asserts the new section exists, names both P0-tier
components (Cilium, Envoy Gateway) by their exact table row, confirms the doc still
states it reuses the existing P0–P3 scheme (guards against a future edit quietly
inventing a second taxonomy), and confirms Q2's old open-gap sentence is gone.

## ADR-0004 caveat

This is documentation-only, clusterless work — no live-cluster verification is
needed or claimed. Every tier justification either cites a real, already-logged
incident (`docs/incident-log.md`, `gitops/vault/unsealer.yaml`'s header comment) or
a structural property verified directly against the live manifest in this repo
(e.g. Kyverno's `failurePolicy: Ignore`), never a guess presented as fact.

## Rollback path

Revert the `docs/dora-audit-readiness.md` section addition and Q2 Gap-line edit,
and delete `tests/dora-audit-readiness.bats`. No other file depends on either —
this is a pure documentation/test addition with no GitOps or code surface.

## PR

https://github.com/tooming/k8s-anywhere/pull/1133
