# 2026-06-13 — Capstone Rollout overlay + success-rate AnalysisTemplate

**ROADMAP item:** Capstone Rollout overlay + success-rate AnalysisTemplate
(CHARTER Objective O1 + capstone "Argo Rollouts canaries on real Mimir SLOs → Envoy
routes it" vision, RFC #154 / ADR-0020 §"Capstone integration").
**Branch:** auto/capstone-rollout
**PR:** (see GitHub)

## Item description (verbatim from ROADMAP)

🟢 **Capstone Rollout overlay + success-rate AnalysisTemplate** (CHARTER **Objective O1**
+ the capstone "Argo Rollouts canaries on real Mimir SLOs → Envoy routes it" vision,
RFC #154). Wait for the Argo Rollouts controller PR above to merge first. Add
`gitops/argo-rollouts/analysistemplates/success-rate.yaml` (`AnalysisTemplate`
`success-rate` using the `prometheus` provider ...). Add
`gitops/apps/capstone/rollout.yaml` (`Rollout` resource — SEPARATE file from
`deployment.yaml` per RFC #154 ...). (auto/capstone-rollout)

## What landed

- `gitops/argo-rollouts/analysistemplates/success-rate.yaml` — `AnalysisTemplate`
  `success-rate` in namespace `capstone`; Mimir prometheus provider at
  `mimir-query-frontend.observability.svc.cluster.local:8080/prometheus` with
  `X-Scope-OrgID: lab`; `http_requests_total` success-rate query (2xx/total) scoped
  via `{{args.namespace}}`; success condition `>= 0.95`, interval 30s, failureLimit 3.
- `gitops/apps/capstone/rollout.yaml` — `Rollout` `capstone` in namespace `capstone`;
  6-step canary strategy: setWeight 10 → pause 60s → analysis (success-rate) →
  setWeight 50 → pause 60s → analysis (success-rate); `argoproj-labs/gatewayAPI`
  plugin targeting the existing capstone HTTPRoute; `capstone-stable` and
  `capstone-canary` Services defined in the same file (managed by the Rollout
  controller). Full pod template mirrors `deployment.yaml` (PSS-restricted
  securityContext, imagePullSecrets, OTEL env, readOnlyRootFilesystem + emptyDir).
- `gitops/platform/capstone-rollout.yaml` — auto-synced ArgoCD `Application`,
  sync-wave 5 (after argo-rollouts installs the AnalysisTemplate CRD at wave 1 and
  capstone namespace exists at wave 4); sources
  `gitops/argo-rollouts/analysistemplates/`; destination namespace `capstone` so the
  AnalysisTemplate is co-located with the Rollout that references it by templateName.
- `tests/capstone-rollout.bats` — 35 clusterless structural assertions: AnalysisTemplate
  file + kind + name + namespace + Mimir URL + X-Scope-OrgID header + success condition +
  query shape + namespace arg; Rollout file + kind + canary strategy + canaryService +
  stableService + gatewayAPI plugin + HTTPRoute ref + step ordering (setWeight 10, pause
  60s, analysis templateName, setWeight 50); Services defined; capstone-rollout
  Application path + namespace + auto-sync + sync-wave.

## Why

CHARTER Objective O1 (Tier 1 next-wave components by 2026-12-31) includes progressive
delivery via Argo Rollouts. The capstone Rollout is the first real canary in the lab,
closing the "Argo Rollouts canaries on real Mimir SLOs → Envoy routes the canary slice"
capstone vision. The success-rate AnalysisTemplate sources real Mimir metrics (ADR-0004
compliance); the gatewayAPI plugin rewrites the capstone HTTPRoute's backendRef weights
(ADR-0008 Envoy Gateway integration).

## Notes

- Clusterless: the Rollout and AnalysisTemplate are CRD instances — kubeconform skips
  them via `-ignore-missing-schemas`. All tests are structural YAML content checks.
- The existing `deployment.yaml` is NOT deleted in this PR (ROADMAP: "stays as the
  no-canary reference"). In a live cluster, scale the Deployment to 0 before activating
  the Rollout to avoid selector conflicts. A follow-up planner item will delete the
  Deployment once the Rollout is verified end-to-end.
- Traffic splits won't occur until the maintainer runs
  `kubectl argo rollouts set image capstone capstone=<new-image>` on a live cluster.
  This PR ships the shape; the verifier routine exercises it end-to-end on the
  maintainer's machine.

## PR

https://github.com/tooming/k8s-anywhere/pull/200
