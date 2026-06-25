# Planner run 2026-06-25 — docs gap fill

**Situation at run start:** the "Now / next" lane held a single unchecked item
(`auto/cosign-enforce-flip` — verifyImages Audit → Enforce flip) blocked by a
maintainer-confirmation prerequisite (can't verify `curl artifactory/.sig` returns 200
without a live cluster). Zero open PRs, zero open issues, nothing in
`docs/roadmap/incoming/`.

## Gap analysis findings

### `docs/00-architecture.md` drift (CHARTER Core Values §"Docs & dashboards don't drift")

The file is 70 lines, written when the platform had ~8 components. The "Who does what"
table lists only k3s, Terraform, GitLab, ArgoCD, Envoy, Vault, TiDB, Mimir, Loki,
Grafana — it omits every component added since then: Cilium, External Secrets, Garage,
s3manager, RabbitMQ, Valkey, Alloy, Tempo, Pyroscope, node-exporter, kube-state-metrics,
moto, ACK, KRO, Kyverno, Argo Rollouts, Velero, Trivy Operator, cosign. The learning
path still ends at "GitLab CI ties it together"; it omits supply-chain security,
progressive delivery, DR/restore, and continuous scanning. Groomed as a 🟢 item:
`auto/architecture-doc-rewrite`.

### ADR-0017 velero row says `baseline`; implementation is `restricted`

`docs/decisions/adr-0017-pod-security-standards-restricted.md` line 119 says
`velero | baseline`. The actual `gitops/velero/namespace.yaml` has `enforce: restricted`
and `tests/velero.bats` line 79 asserts `enforce: restricted`. The implementation used a
per-workload annotation on the node-agent DaemonSet for the hostPath carve-out (the same
approach as node-exporter in ADR-0017 §"Per-workload field carve-outs"), making
`restricted` viable — the ADR was set to `baseline` as an initial estimate and never
updated. Groomed into the `auto/adr0017-velero-row-depTree-fix` item.

### `docs/dependency-tree.md` stale notes

1. Line 83: `subgraph CAPSTONE["Capstone — build pipeline (steps 1–4 done; step 5
   pending)"]` — step 5 shipped in `auto/capstone-step-5` (see
   `docs/done/auto-capstone-step-5.md`).
2. Line 385 (argocd PSS Phase 1 note): `"Phase 2 (separate ROADMAP item, pending
   infra/modules/argocd/values.yaml securityContext overrides)"` — Phase 2 shipped in
   PR `auto/argocd-pss-enforce`. Groomed into the same `auto/adr0017-velero-row-depTree-fix`
   item.

### O4 measurement gate gap (surfaced; needs architect RFC)

CHARTER O4 is measured by "a CI step that pushes an unsigned image and asserts Kyverno
rejection." No such GitLab CI job exists. It depends on: (1) verifyImages flip to
Enforce mode (the blocked `auto/cosign-enforce-flip` item above); (2) an architect RFC
to define the job shape. Surfaced in the Cross-cutting section header as an O4 gap note
and in this plan PR body. Not groomed as an executor item — needs an RFC first.

## Items added to ROADMAP "Now / next"

1. `- [ ] 🟢 **docs/00-architecture.md — current-state rewrite**`
   (auto/architecture-doc-rewrite) — expand tool table + learning path + diagram.

2. `- [ ] 🟢 **ADR-0017 velero PSA row correction + dependency-tree stale notes**`
   (auto/adr0017-velero-row-depTree-fix) — correct ADR table + fix two stale
   dependency-tree notes.
