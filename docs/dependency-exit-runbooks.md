# Dependency exit runbooks

Closes [`docs/dora-audit-readiness.md`](dora-audit-readiness.md) Q17's own named gap:
exit strategy per critical dependency is *implicit* (ADR-0001's GitOps-repointing
design — every workload is redeployable by changing one `Application` source) and
*demonstrated* once (the real, executed ADR-0011→ADR-0024 Artifactory→Harbor
migration), but until this file, no dependency had a **written** exit runbook in
advance of needing one. This file is that: pre-planned first-response steps, not a
new mitigation — the mitigation is already ADR-0001's design and the Artifactory→
Harbor precedent; this only writes the steps down before an exit is forced.

**Scope of this slice.** [`docs/dependency-concentration.md`](dependency-concentration.md)
(Q16) named three upstream-org concentration groups, worst-first — this file covers
exactly those three, the lab's actual highest-blast-radius exit candidates. It does
**not** yet cover every remaining `always-on-core` single-tool row in
[`docs/dependency-register.md`](dependency-register.md) (Terraform/Terragrunt, Garage,
Envoy Gateway, RabbitMQ, Cilium, Valkey, cert-manager, KEDA, Forgejo,
kube-state-metrics, node-exporter — eleven more rows) — extending to those is real,
separately-scoped future work if wanted, not attempted here to keep this PR within
WAYS-OF-WORKING.md §3's per-PR size discipline. Said plainly rather than silently
narrowed (ADR-0004: an unscoped "covers dependencies" title would itself overclaim
completeness).

**How to read a runbook below.** Each names: what a real exit changes *mechanically*
in this repo's `gitops/`; whether a straight fork-and-repoint suffices or a
schema/data migration is also needed; and, honestly, whether any alternative has
actually been evaluated yet. A written runbook existing in advance doesn't make the
effort of a real exit smaller — it only means the first-response steps are already
identified, so a future session isn't starting from zero the way the Artifactory→
Harbor migration originally did.

---

## `github.com/grafana` — 6 tools (Grafana, Mimir, Loki, Tempo, Pyroscope, Alloy)

The largest concentration in the register: the entire observability pane (dashboards,
metrics, logs, traces, continuous profiling, and the unified collector feeding all of
them) is one upstream org, all `always-on-core`, all governed by
[ADR-0006](decisions/adr-0006-grafana-native-git-sync.md) (Grafana itself) or
[ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) (Mimir/Loki/Tempo/
Pyroscope/Alloy).

**Mechanically:** each is its own ArgoCD `Application` in `gitops/platform/
observability-*.yaml` (`observability-grafana.yaml`, `-mimir.yaml`, `-loki.yaml`,
`-tempo.yaml`, `-pyroscope.yaml`, `-alloy.yaml`) — a real exit means picking a
replacement per role (a dashboard UI, a metrics TSDB, a log store, a trace store, a
profiler, a collector) and repointing each `Application`'s chart `repoURL`/
`targetRevision` to the new source, one at a time, not a single-file flip.

**Fork-and-repoint, or a bigger migration?** Depends on the role. Grafana itself
(the UI) is the most fork-and-repoint-shaped — dashboards are plain JSON, portable
to most Grafana-compatible viewers. Mimir/Loki/Tempo are each a *storage format and
query-API* choice, not just a deployment target — replacing any one means a real data
migration or accepting a cold cutover (lose history), not a same-day repoint.
Pyroscope and Alloy are the least entangled (a stateless collector and a
still-developing profiling store, respectively).

**Alternative evaluated?** No — this lab has never run a bake-off against a
non-Grafana-org observability stack. The first step of any real exit would be the
same ADR-writing process [ADR-0002](decisions/adr-0002-garage-not-minio.md)/
[ADR-0018](decisions/adr-0018-valkey-not-redis.md)/
[ADR-0024](decisions/adr-0024-harbor-not-artifactory.md) already used to pick between
alternatives before committing — not assumed here as already decided.

## `github.com/argoproj` — 2 tools (ArgoCD, Argo Rollouts)

Couples the GitOps control plane itself ([ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md),
`always-on-core`) to the progressive-delivery layer built on top of it
([ADR-0020](decisions/adr-0020-argo-rollouts-progressive-delivery.md),
`always-on-next-wave`, CHARTER Objective O1). Lower blast radius than the Grafana-org
cluster (2 rows vs. 6), but ArgoCD is this lab's actual deployment mechanism — every
other exit runbook in this file assumes ArgoCD exists to execute the repoint.

**Mechanically:** ArgoCD is Terraform-bootstrapped (`infra/modules/argocd/`), not a
`gitops/` `Application` itself (ADR-0001's day-0 seam) — a real exit means swapping
the bootstrap module for a different GitOps controller's Terraform/Helm bootstrap,
then re-authoring every `gitops/**/*.yaml` `Application` manifest into the new
tool's own CRD shape (a real schema migration, not a repoint — different controllers
don't share one CRD API). Argo Rollouts is a normal auto-synced `Application`
(`gitops/platform/argo-rollouts.yaml`) with its own CRDs (`Rollout`,
`AnalysisTemplate`) consumed by `gitops/apps/capstone/rollout.yaml` — exiting it
means picking a different progressive-delivery controller and rewriting the
capstone `Rollout` object into that tool's canary/analysis shape.

**Fork-and-repoint, or a bigger migration?** Exiting ArgoCD itself is this lab's
single largest possible dependency exit — every `Application` manifest in the repo
is written in its CRD's vocabulary. Exiting Argo Rollouts alone is narrower: one
consumer (`capstone`), one CRD family to rewrite.

**Alternative evaluated?** No — ADR-0001 chose ArgoCD/GitOps as the deployment model
itself, not as a like-for-like tool pick among GitOps controllers, so no rejected
alternative is on record for ArgoCD specifically. Argo Rollouts likewise has no
recorded rejected alternative in ADR-0020. Same conclusion as the Grafana group: a
real exit starts with a new ADR, not an assumed replacement.

## `github.com/pingcap` — 2 tools (TiDB Operator, TiDB)

Both `heavy-on-demand` only (`make tidb-up`/`tidb-down`, never auto-synced,
[ADR-0031](decisions/adr-0031-tidb-operator-version-policy.md)/
[ADR-0032](decisions/adr-0032-tidb-version-policy.md)) — the lowest blast radius of
the three groups, since nothing in the always-on baseline depends on this org; the
always-on stack keeps running unaffected regardless of TiDB's fate.

**Mechanically:** `gitops/platform/tidb-cluster.yaml` (the Operator) and
`gitops/platform/tidb-demo.yaml`/`tidb-admin-extras.yaml` (the cluster + admin UI) are
each their own manual-sync `Application` — a real exit means repointing these to a
different distributed-SQL operator/database's own chart, plus migrating any real
data via that database's own dump/restore tooling (TiDB speaks the MySQL wire
protocol, so a MySQL-compatible target is the most fork-and-repoint-shaped
replacement; a non-MySQL-compatible target is a real schema/query migration).

**Fork-and-repoint, or a bigger migration?** Since this component is on-demand and
this lab's only workload against it is a demo, an exit here is closer to
fork-and-repoint than either group above — no always-on consumer depends on it, and
the demo data itself is disposable.

**Alternative evaluated?** No — no rejected alternative is recorded in ADR-0031/
ADR-0032 for the distributed-SQL choice itself (both ADRs are version-pin policies,
not the original tool selection). Same first step as the other two groups: a new ADR
before assuming a replacement.

---

## Keeping this in sync

This file is a downstream consumer of two others: [`docs/dependency-
concentration.md`](dependency-concentration.md)'s three named concentration groups
(a new group appearing there should get a runbook section here) and
[`docs/dependency-register.md`](dependency-register.md)'s criticality column (an
`always-on-core` single-tool row not yet covered here — see the Scope note above).
No mechanical drift guard connects these files today, matching the register's and
concentration file's own honestly-stated "no mechanical drift guard yet" limitation.
