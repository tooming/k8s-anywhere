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

Of the 32 ADRs indexed in [`docs/decisions/README.md`](decisions/README.md)
(ADR-0001–ADR-0032), two are **Superseded** and excluded per the index's own
convention (only their replacement is listed): ADR-0010 (Redis, superseded by
ADR-0018/Valkey) and ADR-0011 (Artifactory, superseded by ADR-0024/Harbor).

Of the remaining 30, **eight decide a policy or architectural posture rather than a
single third-party product** — they're excluded from the table below because there's
no one upstream project to attach a criticality/upstream-source/last-reviewed row to:
ADR-0003 (decoupled/no-SPOF design principle), ADR-0004 (no-fabricated-content
policy), ADR-0005 (recreate-over-HA posture), ADR-0016 (default-deny NetworkPolicy
pattern — enforced via Cilium, which *is* in the table), ADR-0017 (Pod Security
Standards — a built-in Kubernetes admission feature, not a third-party dependency),
ADR-0025 (free/OSS-tier governance rule), ADR-0026 (cloud-agnostic architecture
policy), and ADR-0030 (k3s version-pinning governance — enforced via k3s, whose
backend choice ADR-0027 already covers in the table, the same "policy enforced via
an already-listed tool" shape as ADR-0016/Cilium). The remaining 22 ADRs name 24
distinct third-party tools (two ADRs — ADR-0001 and ADR-0012 — each decide on two
tools at once; one tool, Garage, is named by two ADRs for two different roles and
gets one merged row; ADR-0031/ADR-0032 each name one — TiDB Operator and TiDB itself
are distinct products with distinct version lines, so they get separate rows, same
shape as Istio/Kiali under ADR-0012).

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
| ArgoCD | always-on-core | argoproj.github.io, github.com/argoproj/argo-cd | [ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md) | 2026-08-07 (Terraform-bootstrapped `argo-cd` chart bumped `10.2.3` → `10.3.0`, same-appVersion `v3.5.0` chart repackage) |
| Garage | always-on-core (in-cluster S3, ADR-0002) + bootstrap substrate (off-cluster Terraform-state backend, ADR-0007) | github.com/Deuxfleurs/garage | [ADR-0002](decisions/adr-0002-garage-not-minio.md), [ADR-0007](decisions/adr-0007-off-cluster-garage-tfstate-backend.md) | 2026-07-28 (ADR-0002 audit #776, `v2.3.0` kept) |
| Grafana | always-on-core (observability stack) | grafana.com, github.com/grafana/grafana | [ADR-0006](decisions/adr-0006-grafana-native-git-sync.md) | 2026-08-06 (Grafana image tag bumped `13.0.3`→`13.0.5`, real CVE fix GHSA-mpwr-8vm7-h73f; Loki bumped `3.7.4`→`3.7.5`→`3.7.6`, real fixes each hop; Tempo pin `2.10.7` reconfirmed current, ADR-0006 log-drift corrected) |
| Envoy Gateway | always-on-core | github.com/envoyproxy/gateway | [ADR-0008](decisions/adr-0008-envoy-gateway-not-traefik.md) | 2026-07-23 (`v1.8.2` → `v1.8.3` bump) |
| RabbitMQ | always-on-core | github.com/rabbitmq/rabbitmq-server | [ADR-0009](decisions/adr-0009-rabbitmq-message-broker.md) | 2026-07-27 (CVE-2026-44839/CVE-2026-57219 audit #761, kept) |
| Istio (ambient mode) | heavy-on-demand (`make istio-up`/`istio-down`) | istio.io, github.com/istio/istio | [ADR-0012](decisions/adr-0012-istio-ambient-not-sidecar.md) | 2026-08-04 (kiali-server bump audit, shared ADR) |
| Kiali | heavy-on-demand (`make kiali-up`/`kiali-down`) | kiali.io, github.com/kiali/kiali | [ADR-0012](decisions/adr-0012-istio-ambient-not-sidecar.md) | 2026-08-04 (`kiali-server` 2.29.0 → 2.30.0, CVE fix floor) |
| Longhorn | heavy-on-demand (`make longhorn-up`/`longhorn-down`) | github.com/longhorn/longhorn | [ADR-0013](decisions/adr-0013-longhorn-block-storage.md) | 2026-07-28 (flip condition re-checked, `1.11.3` kept) |
| Cilium | always-on-core (CNI — the network data plane itself) | github.com/cilium/cilium | [ADR-0014](decisions/adr-0014-cilium-not-flannel-policy.md) | 2026-07-30 (RFC #917, `1.17.18` → `1.18.12`) |
| Aiven Inkless | heavy-on-demand (`make inkless-up`/`inkless-down`) | github.com/aiven/inkless | [ADR-0015](decisions/adr-0015-inkless-diskless-kafka.md) | 2026-07-24 (`apache/kafka` client held at `3.9.2`, RFC #708) |
| TiDB Operator | heavy-on-demand (`make tidb-up`/`tidb-down`) | github.com/pingcap/tidb-operator | [ADR-0031](decisions/adr-0031-tidb-operator-version-policy.md) | 2026-08-05 (new ADR authored; held at the `1.6.x` line, `v2.0.0` major rewrite deferred) |
| TiDB | heavy-on-demand (`make tidb-up`/`tidb-down`) | github.com/pingcap/tidb | [ADR-0032](decisions/adr-0032-tidb-version-policy.md) | 2026-08-06 (new ADR authored; held at the `v8.5.x` line, `v26.x` calendar-versioning scheme change deferred) |
| Valkey (supersedes Redis, ADR-0010) | always-on-core | github.com/valkey-io/valkey | [ADR-0018](decisions/adr-0018-valkey-not-redis.md) | 2026-07-29 (Redis AGPLv3 re-check, Valkey kept, audit #829) |
| Kyverno | always-on-next-wave (Objective O1) | github.com/kyverno/kyverno | [ADR-0019](decisions/adr-0019-kyverno-admission-engine.md) | 2026-07-29 (`admissionController` bumped to 2 replicas) |
| Argo Rollouts | always-on-next-wave (Objective O1) | github.com/argoproj/argo-rollouts | [ADR-0020](decisions/adr-0020-argo-rollouts-progressive-delivery.md) | 2026-07-20 (flip condition met, chart bumped to `2.41.1`) |
| Velero | always-on-next-wave (Objective O1) | github.com/vmware-tanzu/velero | [ADR-0021](decisions/adr-0021-velero-backup-restore.md) | 2026-07-29 (`inkless-daily` schedule added) |
| Trivy Operator | always-on-next-wave (Objective O1) | github.com/aquasecurity/trivy-operator | [ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md) | 2026-08-07 (chart bumped `0.34.0` → `0.35.0`, appVersion `0.32.0` → `0.33.0`, bundled Trivy scanner `0.72.0` → `0.73.0`) |
| Kargo | heavy-on-demand (`make kargo-up`/`kargo-down`) | github.com/akuity/kargo | [ADR-0023](decisions/adr-0023-kargo-promotion-pipeline.md) | 2026-07-25 (chart bumped `1.10.9` → `1.11.0`) |
| Harbor (supersedes Artifactory, ADR-0011) | heavy-on-demand (`make harbor-up`/`harbor-down`) | github.com/goharbor/harbor-helm | [ADR-0024](decisions/adr-0024-harbor-not-artifactory.md) | 2026-08-03 (chart bumped `1.19.1` → `1.19.2`) |
| Oracle Cloud Infrastructure | cloud-backend (opt-in) | cloud.oracle.com | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) | not dated in ADR (no Re-evaluation log; decision date 2026-07-13) |
| k3s | cloud-backend (opt-in) | github.com/k3s-io/k3s | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) | not dated in ADR (no Re-evaluation log; decision date 2026-07-13) |
| cert-manager | always-on-core | github.com/cert-manager/cert-manager | [ADR-0028](decisions/adr-0028-cert-manager-tls-lifecycle.md) | 2026-07-31 (chart bumped `1.21.0` → `1.21.1`, audit #931/RFC #933) |
| KEDA | always-on-core | github.com/kedacore/keda | [ADR-0029](decisions/adr-0029-keda-event-driven-autoscaling.md) | 2026-08-03 (chart bumped `2.20.1` → `2.20.2`) |
| GitLab | always-on-core (self-hosted git source + CI runner, host-level Docker Compose, outside the cluster) | about.gitlab.com, gitlab.com/gitlab-org/gitlab | [ADR-0033](decisions/adr-0033-gitlab-git-source-and-ci.md) | 2026-08-07 (ADR-0033 authored; `gitlab-ce`/`gitlab-runner` also pinned to explicit versions the same day, see the `k3s`-style pin precedent) |
| Mimir | always-on-core (observability — metrics store) | github.com/grafana/mimir | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| Loki | always-on-core (observability — log store) | github.com/grafana/loki | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| Tempo | always-on-core (observability — trace store) | github.com/grafana/tempo | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| Pyroscope | always-on-core (observability — continuous profiling) | github.com/grafana/pyroscope | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| Alloy | always-on-core (observability — unified collector) | github.com/grafana/alloy | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
| kube-state-metrics | always-on-core (observability — Kubernetes object-state exporter) | github.com/kubernetes/kube-state-metrics | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-07 (ADR-0034 authored) |
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
