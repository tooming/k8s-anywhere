# Third-party dependency register

A single, queryable register of this lab's third-party dependencies — closing
[`docs/dora-audit-readiness.md`](dora-audit-readiness.md)'s Q14 ("Is there a register
of ICT third-party dependencies?"), which named this exact gap as "real but cheap to
close... without gathering new information." Every row below is pure re-indexing of
content that already exists in [`docs/decisions/`](decisions/) (the ADRs) — no new
dependency-risk judgment was made in producing this file.

**How this relates to the other two dependency docs** (they answer different
questions, not duplicates of each other):
- [`docs/decisions/`](decisions/) — the **why**: the full reasoning, rejected
  alternatives, and re-evaluation history behind each choice.
- [`docs/dependency-tree.md`](dependency-tree.md) — the **topology**: how components
  wire together in GitOps (namespaces, sync waves, NetworkPolicy paths).
- **This file** — the **third-party-risk rollup**: at a glance, which upstream
  projects the lab depends on, how critical each is, and when it was last reviewed.

## Scope note

Of the 35 ADRs indexed in [`docs/decisions/README.md`](decisions/README.md)
(ADR-0001–ADR-0035), two are **Superseded** and fully excluded per the index's own
convention (only their replacement is listed): ADR-0010 (Redis, superseded by
ADR-0018/Valkey) and ADR-0011 (Artifactory, superseded by ADR-0024/Harbor). A third,
ADR-0033 (GitLab, superseded by ADR-0035/Forgejo), was **not** excluded the same way
for most of its life: unlike the other two's fully-decommissioned predecessors,
GitLab stayed the live, running component through most of the migration. That
changed 2026-08-17 — an accelerated, live-cluster cutover (PR #1205) flipped every
`repoURL` to Forgejo and stopped GitLab (`make gitlab-down`) ahead of the two
remaining ROADMAP migration steps (script/Makefile rename, full decommission), so
the table below now rows **Forgejo** (citing ADR-0035) as the live component,
matching the Redis/Artifactory pattern one step early — GitLab's own row is retired
even though `gitlab/docker-compose.yml` and `infra/modules/gitlab-config` are still
in the repo (kept for rollback until the decommission item lands; see ADR-0035's own
migration-execution list, items 5–6, and ROADMAP.md's Now/next Forgejo-migration
list for the current status of that follow-up).

Of the remaining 33, **eight decide a policy or architectural posture rather than a
single third-party product** — they're excluded from the table below because there's
no one upstream project to attach a criticality/upstream-source/last-reviewed row to:
ADR-0003 (decoupled/no-SPOF design principle), ADR-0004 (no-fabricated-content
policy), ADR-0005 (recreate-over-HA posture), ADR-0016 (default-deny NetworkPolicy
pattern — enforced via Cilium, which *is* in the table), ADR-0017 (Pod Security
Standards — a built-in Kubernetes admission feature, not a third-party dependency),
ADR-0025 (free/OSS-tier governance rule), ADR-0026 (cloud-agnostic architecture
policy), and ADR-0030 (k3s version-pinning governance — enforced via k3s, whose
backend choice ADR-0027 already covers in the table, the same "policy enforced via
an already-listed tool" shape as ADR-0016/Cilium). Of the remaining 25, all 25 now
have a row below — ADR-0035 (Forgejo) gained its own row 2026-08-17 once the live
cutover (PR #1205) made Forgejo, not GitLab, the actual live component the row
should describe (see the note above) — collectively naming the table's 32 distinct
third-party-tool rows: three ADRs each
decide on more than one tool at once (ADR-0001: Terraform/Terragrunt + ArgoCD;
ADR-0012: Istio + Kiali; ADR-0027: Oracle Cloud Infrastructure + k3s) and ADR-0034
alone names seven (the LGTMP observability internals — Mimir, Loki, Tempo, Pyroscope,
Alloy, kube-state-metrics, node-exporter); one tool, Garage, is named by two ADRs
(ADR-0002, ADR-0007) for two different roles and gets one merged row; ADR-0031/
ADR-0032 each name one — TiDB Operator and TiDB itself are distinct products with
distinct version lines, so they get separate rows, same shape as Istio/Kiali under
ADR-0012.

**Gap closed 2026-08-07 (was: "Real gap, distinct from the policy-ADR exclusions
above").** This register's construction rule (every row cites the ADR that decided
it) used to leave two real, always-on dependency groups un-rowable: **GitLab** (the
git source of truth + CI runner, referenced by name across many ADRs but never itself
the *subject* of one) and the observability pipeline's internals **Mimir, Loki, Tempo,
Pyroscope, Alloy, kube-state-metrics, and node-exporter** (only Grafana, the
pane-of-glass on top of all of them, had its own ADR-0006). An architect-fallback
cycle (RFC #1073) closed the gap by authoring
[ADR-0033](decisions/adr-0033-gitlab-git-source-and-ci.md) (GitLab, its own ADR — a
distinct axis from ADR-0001's GitOps-vs-imperative decision) and
[ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) (one combined ADR for the
seven observability-internals tools, mirroring ADR-0012's Istio+Kiali
one-ADR-two-tools precedent). All eight tools now have rows in the table below.

**Criticality** reuses CHARTER's own "Target end-state" groupings rather than
inventing a new scheme: **always-on-core** (part of the always-on base stack),
**always-on-next-wave** (the four CHARTER Objective O1 components), **heavy-on-demand**
(manual `make <name>-up`/`-down`, never auto-synced), or **cloud-backend (opt-in)**
(ADR-0027's alternate Oracle Cloud infra path — not part of the localhost budget
tiers at all, since it's an operator-chosen alternative to the default backend, not
a component running alongside it).

**Last reviewed** is the most recent dated entry in the ADR's own "Re-evaluation log"
section where one exists; where an ADR has no such section *and* states no explicit
decision date in its `Status` line either, this is marked **"not dated in ADR"**
rather than guessed (ADR-0004 — never fabricate a date not actually in the source).

| Tool | Criticality | Upstream source | ADR | Last reviewed |
|---|---|---|---|---|
| Terraform / Terragrunt | always-on-core (day-0 bootstrap only, ADR-0001) | terraform.io, terragrunt.gruntwork.io | [ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md) | not dated in ADR (no Re-evaluation log) |
| ArgoCD | always-on-core | argoproj.github.io, github.com/argoproj/argo-cd | [ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md) | 2026-08-18 (Terraform-bootstrapped `argo-cd` chart bumped `10.3.3` → `10.4.0`, packaging-only — appVersion unchanged at `v3.5.1`; upstream added a per-component `vpa.recommenders` field and bumped the bundled `argo-workflows` sub-chart dependency to `4.1.1`, neither touching any key this module's `values.yaml` sets) |
| Garage | always-on-core (in-cluster S3, ADR-0002) + bootstrap substrate (off-cluster Terraform-state backend, ADR-0007) | github.com/Deuxfleurs/garage | [ADR-0002](decisions/adr-0002-garage-not-minio.md), [ADR-0007](decisions/adr-0007-off-cluster-garage-tfstate-backend.md) | 2026-07-28 (ADR-0002 audit #776, `v2.3.0` kept) |
| Grafana | always-on-core (observability stack) | grafana.com, github.com/grafana/grafana | [ADR-0006](decisions/adr-0006-grafana-native-git-sync.md) | 2026-08-18 (image tag bumped `13.0.5`→`13.0.6`, upgrade-drafter fallback — routine currency patch, no CVE; chart stays pinned at `12.10.4`, still current) |
| Envoy Gateway | always-on-core | github.com/envoyproxy/gateway | [ADR-0008](decisions/adr-0008-envoy-gateway-not-traefik.md) | 2026-08-07 (`provider.kubernetes.leaderElection.disable: true` set on the single-replica control plane — chronic front-door 502 fix, 17+ restarts/~2h observed 2026-08-07; ADR-0005 already accepted the single-replica posture, this closes the self-inflicted-restart gap it left) |
| RabbitMQ | always-on-core | github.com/rabbitmq/rabbitmq-server | [ADR-0009](decisions/adr-0009-rabbitmq-message-broker.md) | 2026-08-19 (patch bumped `4.3.4`→`4.3.5`, upgrade-drafter fallback — routine maintenance release, no CVE) |
| Istio (ambient mode) | heavy-on-demand (`make istio-up`/`istio-down`) | istio.io, github.com/istio/istio | [ADR-0012](decisions/adr-0012-istio-ambient-not-sidecar.md) | 2026-08-04 (kiali-server bump audit, shared ADR) |
| Kiali | heavy-on-demand (`make kiali-up`/`kiali-down`) | kiali.io, github.com/kiali/kiali | [ADR-0012](decisions/adr-0012-istio-ambient-not-sidecar.md) | 2026-08-04 (`kiali-server` 2.29.0 → 2.30.0, CVE fix floor) |
| Longhorn | heavy-on-demand (`make longhorn-up`/`longhorn-down`) | github.com/longhorn/longhorn | [ADR-0013](decisions/adr-0013-longhorn-block-storage.md) | 2026-07-28 (flip condition re-checked, `1.11.3` kept) |
| Cilium | always-on-core (CNI — the network data plane itself) | github.com/cilium/cilium | [ADR-0014](decisions/adr-0014-cilium-not-flannel-policy.md) | 2026-08-19 (3 High GHSAs audited, pin already past fix floor; patch bumped `1.18.12`→`1.18.13`) |
| Aiven Inkless | heavy-on-demand (`make inkless-up`/`inkless-down`) | github.com/aiven/inkless | [ADR-0015](decisions/adr-0015-inkless-diskless-kafka.md) | 2026-08-18 (broker image pinned `:latest` → `:4.2.1-0.46`, a real stable named release line now exists; Kyverno `disallow-latest-tag` carve-out removed) |
| TiDB Operator | heavy-on-demand (`make tidb-up`/`tidb-down`) | github.com/pingcap/tidb-operator | [ADR-0031](decisions/adr-0031-tidb-operator-version-policy.md) | 2026-08-12 (bumped `1.6.5` → `1.6.6`, same `1.6.x` line per ADR-0031's own in-scope patch-bump carve-out; real RBAC least-privilege hardening) |
| TiDB | heavy-on-demand (`make tidb-up`/`tidb-down`) | github.com/pingcap/tidb | [ADR-0032](decisions/adr-0032-tidb-version-policy.md) | 2026-08-06 (new ADR authored; held at the `v8.5.x` line, `v26.x` calendar-versioning scheme change deferred) |
| Valkey (supersedes Redis, ADR-0010) | always-on-core | github.com/valkey-io/valkey | [ADR-0018](decisions/adr-0018-valkey-not-redis.md) | 2026-08-17 (bumped `8.0.10` → `8.1.9`, RCE-severity CVE-2026-56684/CVE-2026-63639 wording found on the `8.1.x` line for the same two CVE IDs the `8.0.10` pin's own notes described as crash-only) |
| Kyverno | always-on-next-wave (Objective O1) | github.com/kyverno/kyverno | [ADR-0019](decisions/adr-0019-kyverno-admission-engine.md) | 2026-08-06 (`disallow-latest-tag`'s `argocd` carve-out flip condition met, exclusion removed, issue #999/PR #1037) |
| Argo Rollouts | always-on-next-wave (Objective O1) | github.com/argoproj/argo-rollouts | [ADR-0020](decisions/adr-0020-argo-rollouts-progressive-delivery.md) | 2026-08-06 (`success-rate` AnalysisTemplate missing `count` crashlooped the controller, bugfix) |
| Velero | always-on-next-wave (Objective O1) | github.com/vmware-tanzu/velero | [ADR-0021](decisions/adr-0021-velero-backup-restore.md) | 2026-07-29 (`inkless-daily` schedule added) |
| Trivy Operator | always-on-next-wave (Objective O1) | github.com/aquasecurity/trivy-operator | [ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md) | 2026-08-07 (chart bumped `0.34.0` → `0.35.0`, appVersion `0.32.0` → `0.33.0`, bundled Trivy scanner `0.72.0` → `0.73.0`) |
| Kargo | heavy-on-demand (`make kargo-up`/`kargo-down`) | github.com/akuity/kargo | [ADR-0023](decisions/adr-0023-kargo-promotion-pipeline.md) | 2026-08-18 (chart bumped `1.11.1` → `1.11.2`, upgrade-drafter fallback — routine backport patch, no CVE) |
| Harbor (supersedes Artifactory, ADR-0011) | heavy-on-demand (`make harbor-up`/`harbor-down`) | github.com/goharbor/harbor-helm | [ADR-0024](decisions/adr-0024-harbor-not-artifactory.md) | 2026-08-03 (chart bumped `1.19.1` → `1.19.2`) |
| Oracle Cloud Infrastructure | cloud-backend (opt-in) | cloud.oracle.com | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) | not dated in ADR (no Re-evaluation log; decision date 2026-07-13) |
| k3s | cloud-backend (opt-in) | github.com/k3s-io/k3s | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) | not dated in ADR (no Re-evaluation log; decision date 2026-07-13) |
| cert-manager | always-on-core | github.com/cert-manager/cert-manager | [ADR-0028](decisions/adr-0028-cert-manager-tls-lifecycle.md) | 2026-07-31 (chart bumped `1.21.0` → `1.21.1`, audit #931/RFC #933) |
| KEDA | always-on-core | github.com/kedacore/keda | [ADR-0029](decisions/adr-0029-keda-event-driven-autoscaling.md) | 2026-08-03 (chart bumped `2.20.1` → `2.20.2`) |
| Forgejo | always-on-core (self-hosted git source + CI runner, host-level Docker Compose, outside the cluster) — **the live, running component as of 2026-08-17** (PR #1205's accelerated cutover); supersedes GitLab, whose `docker-compose.yml`/`infra/modules/gitlab-config` are still in the repo, stopped but kept for rollback until ROADMAP's remaining migration items (script/Makefile rename, full decommission) land | codeberg.org/forgejo/forgejo, code.forgejo.org/forgejo/runner | [ADR-0035](decisions/adr-0035-forgejo-not-gitlab.md) (supersedes [ADR-0033](decisions/adr-0033-gitlab-git-source-and-ci.md)) | 2026-08-17 (live cutover, PR #1205; image pins — `forgejo:16.0.2`, `runner:13.0.0` — independently reconfirmed current the same day, this run's own earlier currency check) |
| Mimir | always-on-core (observability — metrics store) | github.com/grafana/mimir | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| Loki | always-on-core (observability — log store) | github.com/grafana/loki | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| Tempo | always-on-core (observability — trace store) | github.com/grafana/tempo | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| Pyroscope | always-on-core (observability — continuous profiling) | github.com/grafana/pyroscope | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-10 (chart bumped `2.2.0` → `2.2.1`, upstream security release — `grpc-go`/`golang.org/x/text`/`golang.org/x/net`/`kin-openapi` CVE fixes) |
| Alloy | always-on-core (observability — unified collector) | github.com/grafana/alloy | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| kube-state-metrics | always-on-core (observability — Kubernetes object-state exporter) | github.com/kubernetes/kube-state-metrics | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-17 (chart bumped `8.3.0` → `8.3.1`, packaging-only release — `appVersion` unchanged, fixes autosharding-only Service rendering this lab's config doesn't exercise) |
| node-exporter | always-on-core (observability — node/host metrics exporter) | github.com/prometheus/node_exporter | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |

## Keeping this in sync

This register has no mechanical drift guard yet — it's a manual, best-effort snapshot
as of 2026-08-07 (the ArgoCD and Trivy Operator rows were updated that day, and eight
new rows — GitLab plus the seven LGTMP observability-internals tools — were added the
same day once ADR-0033/ADR-0034 closed the gap that used to leave them un-rowable; see
above). Every future
chart/image-version bump PR already updates its own
ADR's Re-evaluation log (an existing, enforced convention); this file's "Last
reviewed" column should be updated in the same PR when it touches a row here, but
nothing currently fails `make ci` if it drifts. A future item could add a mechanical
check (e.g. flag when an ADR's Re-evaluation log has a newer entry than this file's
corresponding row) if staleness here proves to be a real recurring problem —
premature to build before it's shown to actually drift.

[`docs/dependency-concentration.md`](dependency-concentration.md) is a downstream
consumer of the table above (grouped by upstream GitHub org, closing
[`docs/dora-audit-readiness.md`](dora-audit-readiness.md) Q16's gap) — a future row
add/remove/rename here should prompt a look there too, same manual-sync caveat as
above.
