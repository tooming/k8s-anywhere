# Dependency exit runbooks

Closes [`docs/dora-audit-readiness.md`](dora-audit-readiness.md) Q17's own named gap:
exit strategy per critical dependency is *implicit* (ADR-0001's GitOps-repointing
design — every workload is redeployable by changing one `Application` source) and
*demonstrated* once (the real, executed ADR-0011→ADR-0024 Artifactory→Harbor
migration), but until this file, no dependency had a **written** exit runbook in
advance of needing one. This file is that: pre-planned first-response steps, not a
new mitigation — the mitigation is already ADR-0001's design and the Artifactory→
Harbor precedent; this only writes the steps down before an exit is forced.

**Scope of this file.** [`docs/dependency-concentration.md`](dependency-concentration.md)
(Q16) named three upstream-org concentration groups, worst-first — this file covers
those three plus, as of 2026-09-02, the four highest-blast-radius of the eleven
single-tool rows in [`docs/dependency-register.md`](dependency-register.md) (Cilium —
the CNI every pod's traffic depends on; Garage — the only stateful S3-compatible
store; Traefik — the sole ingress path for every UI in this lab; cert-manager —
TLS issuance, a silent failure mode if it stops), and, as of 2026-09-03, the remaining
seven (Terraform/Terragrunt, RabbitMQ, Valkey, KEDA, Forgejo, kube-state-metrics,
node-exporter) — closing out full coverage of every single-tool row named in the
register's criticality column. Said plainly rather than silently narrowed (ADR-0004:
an unscoped "covers dependencies" title would itself overclaim completeness) even now
that coverage is complete — a future new row in the register (a new ADR naming a new
tool) would still need its own runbook added here, same as any new concentration
group.

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

> `github.com/pingcap` (TiDB Operator, TiDB) previously had a runbook here — removed
> 2026-09-06 alongside TiDB itself, which was dropped from the lab entirely (no
> replacement; see [ADR-0031](decisions/adr-0031-tidb-operator-version-policy.md)/
> [ADR-0032](decisions/adr-0032-tidb-version-policy.md)'s Status).

---

## Remaining single-tool rows (highest blast-radius four)

Unlike the three groups above, each of these is a single tool with no shared-org
sibling — so each entry below is one paragraph, not three, covering the same ground
(mechanically, fork-and-repoint-or-bigger, alternative evaluated) more tersely.

**Cilium** (CNI — [ADR-0014](decisions/adr-0014-cilium-not-flannel-policy.md)).
`gitops/platform/cilium.yaml` is Terraform-bootstrapped, not a `gitops/` `Application`
(ADR-0001's day-0 seam, like ArgoCD itself) — every pod's network path, and this
lab's entire default-deny `NetworkPolicy` posture (ADR-0016), depends on it. A real
exit is the single highest-blast-radius one in this file: swap the bootstrap CNI
install, then re-verify every existing `NetworkPolicy` manifest still expresses the
intended rules under the new CNI's policy engine (not guaranteed — policy dialects
differ). No alternative has been re-evaluated since ADR-0014 rejected Flannel +
Kubernetes' bundled NetworkPolicy controller at adoption time; a real exit starts
with a new ADR, same as every group above.

**Garage** (S3-compatible storage — [ADR-0002](decisions/adr-0002-garage-not-minio.md)/
[ADR-0007](decisions/adr-0007-off-cluster-garage-tfstate-backend.md)). The lab's only
stateful S3-compatible store — Velero backups, Mimir/Loki/Tempo chunks, and
Terraform state (off-cluster instance) all target it directly. `gitops/platform/
garage.yaml` is a normal auto-synced `Application`, but a real exit is a genuine
data migration (every bucket's real content), not a repoint — the S3 API surface is
portable, the data behind it is not. ADR-0002 rejected MinIO at adoption time; no
exit-direction alternative has been separately evaluated since.

**Traefik** (ingress — [ADR-0040](decisions/adr-0040-traefik-not-envoy-gateway.md),
supersedes [ADR-0008](decisions/adr-0008-envoy-gateway-not-traefik.md)). Bundled
with k3s itself (no separate `Application` to point at — `infra/modules/k3d-cluster/`
just leaves it enabled) and fronts every `IngressRoute` in this lab — the front door
for every UI in README.md's Endpoints table. A real exit means picking a replacement
ingress controller and re-authoring every existing `IngressRoute`/`TLSStore`/
`TraefikService` into the new tool's shape (`IngressRoute` is a Traefik-proprietary
CRD, not a portable spec the way Gateway API's `HTTPRoute` was under the prior Envoy
Gateway choice — ADR-0040 names this trade-off explicitly — so this exit is closer
to a full fork-and-repoint than Cilium's CNI-level exit). ADR-0040 itself supersedes
ADR-0008's choice of Envoy Gateway; no further exit-direction alternative has been
separately evaluated since.

**cert-manager** (TLS lifecycle — [ADR-0028](decisions/adr-0028-cert-manager-tls-lifecycle.md)).
`gitops/platform/cert-manager.yaml` + `cert-manager-root-ca.yaml` issue every
in-cluster TLS certificate; unlike the other three, its failure mode is silent
(existing certs keep working until they expire) rather than an immediate outage — a
real exit is closer to fork-and-repoint (`Certificate`/`Issuer` are cert-manager's
own CRDs, so a replacement means re-authoring those resources into the new tool's
CRD shape, not a data migration). ADR-0028 doesn't record a rejected alternative
(cert-manager was this lab's first and only TLS-lifecycle choice) — no exit-direction
alternative has ever been evaluated.

## Remaining single-tool rows (the other seven)

The four highest-blast-radius single-tool rows above were covered first, worst-first,
per this file's original scope. This section covers the remaining seven single-tool
rows in [`docs/dependency-register.md`](dependency-register.md) — closing the rest of
[Q17](dora-audit-readiness.md)'s named gap. Same terse, one-paragraph-per-tool shape.

**Terraform / Terragrunt** (day-0 bootstrap seam —
[ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md)). Two different upstream
orgs (`hashicorp`, `gruntwork-io`) sharing one register row. Neither is a `gitops/`
`Application` — both run only once, at cluster bootstrap, before ArgoCD exists to
reconcile anything (the same day-0 seam Cilium and ArgoCD itself occupy). A real exit
means rewriting `infra/modules/**/*.tf` and every `infra/live/**/*.hcl` against a
different IaC tool's own syntax and state model — every backend module, every
Terragrunt `inputs` block. Lowest ongoing blast radius of any row in this file (it
only runs at bootstrap, never touches steady-state reconciliation) but the highest
one-time rewrite cost, since literally every `.tf`/`.hcl` file in the repo would need
re-authoring, not just one Application's source. No alternative has been evaluated —
ADR-0001's decision was GitOps-over-imperative, not a bake-off among IaC tools for the
bootstrap seam itself.

**RabbitMQ** (message broker —
[ADR-0009](decisions/adr-0009-rabbitmq-message-broker.md)). `gitops/data/rabbitmq/` is
a normal auto-synced `Application`; KEDA's own `ScaledObject` demo and the `data`
namespace's queue-depth demo both depend on it as their real event source. A real exit
is a genuine data-loss risk for in-flight messages, not just a repoint — the AMQP
protocol surface is portable to most brokers, but queue state itself isn't. ADR-0009
doesn't record a rejected alternative (RabbitMQ was this lab's first and only message
broker choice) — no exit-direction alternative has ever been evaluated.

**Valkey** (cache / key-value store, supersedes Redis —
[ADR-0018](decisions/adr-0018-valkey-not-redis.md)). `gitops/data/valkey/` is a normal
auto-synced `Application`; the `data` namespace's demo load generator targets it
directly. Valkey speaks the Redis wire protocol, so a real exit to any
Redis-protocol-compatible target is close to fork-and-repoint; exiting to a
non-compatible store would be a real client-side rewrite everywhere Valkey is
addressed. ADR-0018 itself *is* an executed exit (away from Redis, over its license
change) — the most directly relevant precedent in this file, alongside the
Artifactory→Harbor migration, for what a real exit here would actually look like.

**KEDA** (event-driven autoscaling —
[ADR-0029](decisions/adr-0029-keda-event-driven-autoscaling.md)). Converted from
always-on-core to on-demand 2026-08-25 (`make keda-up`/`keda-down`) — the lowest blast
radius in this file of any row with an ADR of its own, since nothing runs continuously
against it between demos. `gitops/platform/keda.yaml` is a manual-sync `Application`;
a real exit means picking a different event-driven-autoscaling controller and
rewriting the capstone `ScaledObject` demo into its CRD shape — narrow (one demo
consumer) and closer to fork-and-repoint than any row above. No rejected alternative
is recorded in ADR-0029 (KEDA was this lab's first and only choice for this role).

**Forgejo** (self-hosted git source + CI runner —
[ADR-0035](decisions/adr-0035-forgejo-not-gitlab.md), supersedes
[ADR-0033](decisions/adr-0033-gitlab-git-source-and-ci.md)). Runs at the host level
(Docker Compose), outside the cluster entirely — every ArgoCD `Application`'s
`repoURL` and the CI pipeline that signs the capstone image both depend on it
directly. This lab has *already executed* one exit in this exact slot
(GitLab→Forgejo, PR #1205, live 2026-08-17) — the most recent, most directly
applicable precedent in this file: a real exit means standing up the replacement,
re-pointing all ~121 `Application` `repoURL`s, re-registering deploy keys/webhooks,
and porting `.forgejo/workflows/*.yml` to the new tool's own CI syntax — a
same-day-achievable repoint for the git-hosting role itself, but the CI-workflow port
is a real rewrite, not a value swap (demonstrated by that migration's own real
findings, e.g. the `GITEA__server__SSH_LISTEN_PORT` bug). No rejected alternative is
recorded for Forgejo specifically beyond GitLab (ADR-0035's own comparison).

**kube-state-metrics** (Kubernetes object-state exporter —
[ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md)). `gitops/platform/
observability-ksm.yaml` is a normal auto-synced `Application` feeding Mimir; several
Grafana dashboards (`lab-cloud-control-plane.json` among them) read its series
directly. A real exit means picking a different Kubernetes-object-state exporter and
re-mapping every PromQL query across those dashboards to its metric names — a metrics
schema migration, not a same-day repoint, since dashboard queries hardcode
`kube_state_metrics`'s own metric-naming convention. No rejected alternative is
recorded — ADR-0034 adopted the de-facto standard exporter with no bake-off.

**node-exporter** (node/host metrics exporter —
[ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md)). `gitops/platform/
observability-node-exporter.yaml` is a normal auto-synced `Application`; host-level
dashboards (CPU, memory, disk, network) depend on its `node_*` metric family. Same
shape as kube-state-metrics above: the metrics API surface, not the deployment
mechanism, is what a replacement would need to match — a real exit means re-mapping
every host-level dashboard panel to the new exporter's own metric names. No rejected
alternative is recorded — same de-facto-standard adoption as kube-state-metrics.

---

## Keeping this in sync

This file is a downstream consumer of two others: [`docs/dependency-
concentration.md`](dependency-concentration.md)'s three named concentration groups
(a new group appearing there should get a runbook section here) and
[`docs/dependency-register.md`](dependency-register.md)'s criticality column (a new
row there — a new ADR naming a new tool — should get a runbook section here too, same
as a new concentration group).

**The concentration-group half is mechanically guarded.** As of 2026-09-02/03,
`scripts/dependency-exit-runbooks-sync-check.sh` (`make
dependency-exit-runbooks-sync-check`, wired into `make ci`'s `drift` job) fails the
build if any `github.com/ORG` group named in `dependency-concentration.md` has no
matching `## \`github.com/ORG\`` section here — a new concentration group can no
longer silently go un-runbooked. **The register single-tool-row half is not** — as of
2026-09-03 this file covers all 11 single-tool rows (the Scope note above), but that
completeness is a point-in-time fact this session verified by hand, not something the
sync-check script enforces going forward: a future new register row (a new ADR naming
a new tool) can still silently go un-runbooked, same gap shape as before, just with a
currently-empty backlog instead of a seven-row one.
