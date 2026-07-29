# CHARTER "~28 ArgoCD Applications" re-count (issue #846)

CHARTER **Core Values** §"Docs & dashboards don't drift". Executor-role
fallback sweep (`executor.prompt.md` STEP 6b) found CHARTER.md's
"Always-on core... (built)... ~28 ArgoCD Applications" claim stale, filed
issue #846, then (a distinct cycle) performed the categorized re-count that
issue asked for.

## Method

Enumerated every `kind: Application` manifest under `gitops/` with a real
`spec.syncPolicy.automated` block (verified via `yq '.spec.syncPolicy.automated'`
— a field read, not a text match; an earlier substring-match attempt had
produced false positives from comments merely mentioning the word
`automated`, corrected in a follow-up cycle). **63** files matched.

Categorized each of the 63 against CHARTER's own named buckets:

| Bucket | Count | Members |
|---|---|---|
| **Always-on core** | 33 | root-app, argocd-extras, envoy-gateway(+system-extras/-networkpolicy), lab-gateway(+certificate), vault(+extras), external-secrets(+extras/-config), garage, the 8 observability Applications (alloy/grafana/ksm/loki/mimir/node-exporter/pyroscope/tempo) + node-exporter-extras, moto, ack-s3, ack-resources, kro(+extras/-resources), rabbitmq, valkey, s3manager, demo, data-demo |
| **Always-on next wave** (Kyverno/Rollouts/Velero/Trivy) | 14 | kyverno ×4, argo-rollouts ×3, velero ×4, trivy ×3 |
| **cert-manager + KEDA** | 8 | cert-manager ×4, keda ×4 |
| **Capstone** (its own CHARTER bullet, not "core") | 3 | capstone, capstone-rollout, bluegreen/green-root |
| **PSA-floor shells for on-demand heavy components** (namespace scaffolding only — the actual workload is manual `make <name>-up`) | 5 | harbor-extras, istio-system-extras, longhorn-extras, artifactory-extras, kargo-extras |

33 + 14 + 8 + 3 + 5 = 63. ✓

**Cilium** is not mechanically counted (no `automated:` block — it bootstraps
manually before ArgoCD itself can run, per its own manifest comment) but is
conceptually part of "Always-on core"; noted as a footnote rather than
folded into the count, since ArgoCD doesn't actually auto-heal it.

## What changed

- `CHARTER.md` — "Always-on core... ~28 ArgoCD Applications" → "~33", with
  the re-count date, issue reference, and the Cilium footnote.
- `docs/dora-audit-readiness.md` — its derived "~28 Applications are
  load-bearing" mention (which was actually describing the broader
  always-on set — core + next-wave + cert-manager/KEDA + capstone, not just
  the core bucket) corrected to "~58" (33+14+8+3, excluding the 5
  namespace-only PSA-floor shells, which aren't themselves load-bearing
  workloads).
- No code/manifest change — pure prose accuracy, no behavior change.

`make ci` passes (full local run). Closes #846.

## PR

(this run's `arch/charter-application-count-recount` branch)
