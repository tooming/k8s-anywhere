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

Of the 39 ADRs indexed in [`docs/decisions/README.md`](decisions/README.md)
(ADR-0001–ADR-0039), two are **Superseded** and fully excluded per the index's own
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

Of the remaining 37, **eight decide a policy or architectural posture rather than a
single third-party product** — they're excluded from the table below because there's
no one upstream project to attach a criticality/upstream-source/last-reviewed row to:
ADR-0003 (decoupled/no-SPOF design principle), ADR-0004 (no-fabricated-content
policy), ADR-0005 (recreate-over-HA posture), ADR-0016 (default-deny NetworkPolicy
pattern — enforced via Cilium, which *is* in the table), ADR-0017 (Pod Security
Standards — a built-in Kubernetes admission feature, not a third-party dependency),
ADR-0025 (free/OSS-tier governance rule), ADR-0026 (cloud-agnostic architecture
policy), and ADR-0030 (k3s version-pinning governance — no separate row of its own,
but directly cited alongside ADR-0027 in the k3s row's ADR column since 2026-08-24,
once a gap-analysis pass found the row's "Last reviewed" cell citing only
ADR-0027's decision date and missing ADR-0030's own, much more current,
Re-evaluation log entirely). Of the remaining 29, all 29 now
have a row below — ADR-0035 (Forgejo) gained its own row 2026-08-17 once the live
cutover (PR #1205) made Forgejo, not GitLab, the actual live component the row
should describe (see the note above), ADR-0036 (External Secrets Operator)
gained its own row 2026-08-19 as a retroactive governance record for a mechanism
that predated it having any ADR at all, ADR-0037 (Vault) gained its own row
2026-09-03 for the same reason — a mechanism that predated it having any ADR at
all, whose version history had instead been living as inline `gitops/` YAML
comments — ADR-0038 (moto + ACK S3 + KRO) gained three rows the same day for
the identical reason, one per tool, and ADR-0039 (s3manager) gained its own row
the same day for the same reason again — collectively naming the table's 38
distinct third-party-tool rows: four ADRs each
decide on more than one tool at once (ADR-0001: Terraform/Terragrunt + ArgoCD;
ADR-0012: Istio + Kiali; ADR-0027: Oracle Cloud Infrastructure + k3s; ADR-0038:
moto + ACK S3 + KRO) and ADR-0034
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
| ArgoCD | always-on-core | argoproj.github.io, github.com/argoproj/argo-cd | [ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md) | 2026-09-03 (full GHSA sweep: all 8 published `argoproj/argo-cd` advisories checked — highest severity Critical (GHSA-3v3m-wc6v-x4x3/CVE-2026-42880, ServerSideDiff secret extraction, fixed `3.2.11`/`3.3.9`) — every affected range tops out at `3.4.2` or lower; current pin's appVersion `v3.5.2` is past every floor. Prior entry: 2026-09-01, chart `10.4.0`→`10.5.0`, appVersion `v3.5.1`→`v3.5.2`, routine currency) |
| Garage | always-on-core (in-cluster S3, ADR-0002) + bootstrap substrate (off-cluster Terraform-state backend, ADR-0007) | github.com/deuxfleurs-org/garage | [ADR-0002](decisions/adr-0002-garage-not-minio.md), [ADR-0007](decisions/adr-0007-off-cluster-garage-tfstate-backend.md) | 2026-08-19 (org-slug fix: the prior GitHub org named here was wrong/dead — see ADR-0002 §Re-evaluation log for the exact string and the fix, corrected here and in `routines/architect.prompt.md`; re-verified directly against the correct URL: `v2.3.0` still the newest tag, zero published security advisories) |
| Grafana | always-on-core (observability stack) | grafana.com, github.com/grafana/grafana | [ADR-0006](decisions/adr-0006-grafana-native-git-sync.md) | 2026-09-03 (security bump: `v13.0.8` release notes cite three named CVEs — CVE-2026-12704, CVE-2026-14199, CVE-2026-19475 — image tag bumped `13.0.7`→`13.0.8` same day; chart stays pinned at `12.10.4`, still current; see ADR-0006 Re-evaluation log for the per-CVE applicability analysis and the CVE-detail-domains-blocked honesty caveat) |
| Envoy Gateway | always-on-core | github.com/envoyproxy/gateway | [ADR-0008](decisions/adr-0008-envoy-gateway-not-traefik.md) | 2026-09-03 (full GHSA sweep: all 10 published advisories checked, every affected range tops out at `1.8.1` — current pin `v1.8.3` is past every floor, including the lone Critical (Lua `EnvoyExtensionPolicy` path-validation bypass, not exploitable here either way since this lab defines no such policy); `v1.8.3` kept for the same breaking-change reason as the 2026-08-18 entry, unaffected by this security-clean finding; see ADR-0008's own Re-evaluation log) |
| RabbitMQ | always-on-core | github.com/rabbitmq/rabbitmq-server | [ADR-0009](decisions/adr-0009-rabbitmq-message-broker.md) | 2026-08-19 (patch bumped `4.3.4`→`4.3.5`; corrected same run — the bump actually fixes 10 GHSAs disclosed 2026-08-18, 1 High/4 Moderate/5 Low, not "no CVE" as first recorded) |
| Istio (ambient mode) | heavy-on-demand (`make istio-up`/`istio-down`) | istio.io, github.com/istio/istio | [ADR-0012](decisions/adr-0012-istio-ambient-not-sidecar.md) | 2026-09-01 (bumped all four charts `1.30.3` → `1.30.4`, routine currency, no CVE — includes a real template-quoting hardening fix in istiod's injection templates; GHSA sweep from 2026-08-19 unaffected, `1.30.4` still past every floor) |
| Kiali | heavy-on-demand (`make kiali-up`/`kiali-down`) | kiali.io, github.com/kiali/kiali | [ADR-0012](decisions/adr-0012-istio-ambient-not-sidecar.md) | 2026-09-01 (bumped `2.30.0` → `2.31.0`: 5 named CVE fixes in `kiali/kiali`'s `git log` — axios/undici/immutable, OpenTelemetry-Go CVE-2026-41178, browserslist CVE-2026-73089/-73088, golang.org/x/text CVE-2026-56852, brace-expansion/ip-address/postcss; chart directory itself byte-for-byte unchanged between the two tags) |
| Longhorn | heavy-on-demand (`make longhorn-up`/`longhorn-down`) | github.com/longhorn/longhorn | [ADR-0013](decisions/adr-0013-longhorn-block-storage.md) | 2026-09-03 (currency re-check: `v1.12.1` went stable 2026-08-14, confirmed real via two independent sources; ADR's own flip condition still not triggered — `1.11.x` nowhere near its EOL window and no CVE filed against `1.11.3` — so kept at `1.11.3` per the ADR's own binding 2026-07-18 decision to stay one minor line behind `1.12.x`'s bigger behavioral surface. Prior entry: 2026-08-19 GHSA sweep, no new advisory) |
| Cilium | always-on-core (CNI — the network data plane itself) | github.com/cilium/cilium | [ADR-0014](decisions/adr-0014-cilium-not-flannel-policy.md) | 2026-09-03 (found a Critical advisory, GHSA-3fcv-jvfp-m4q9/CVE-2026-49445, unaudited in this ADR's log despite predating the 2026-08-19 entry — confirmed pin `1.18.13` is past its fix floor. Prior entry: 2026-08-19, 3 High GHSAs audited, patch bumped `1.18.12`→`1.18.13`) |
| Aiven Inkless | heavy-on-demand (`make inkless-up`/`inkless-down`) | github.com/aiven/inkless | [ADR-0015](decisions/adr-0015-inkless-diskless-kafka.md) | 2026-09-03 (broker image bumped `4.2.1-0.46` → `4.2.1-0.47`, no CVE — real bug fixes; DB migration caveat flagged, tracked via a `[Manual step]` issue — see ADR-0015's own Re-evaluation log) |
| TiDB Operator | heavy-on-demand (`make tidb-up`/`tidb-down`) | github.com/pingcap/tidb-operator | [ADR-0031](decisions/adr-0031-tidb-operator-version-policy.md) | 2026-08-12 (bumped `1.6.5` → `1.6.6`, same `1.6.x` line per ADR-0031's own in-scope patch-bump carve-out; real RBAC least-privilege hardening) |
| TiDB | heavy-on-demand (`make tidb-up`/`tidb-down`) | github.com/pingcap/tidb | [ADR-0032](decisions/adr-0032-tidb-version-policy.md) | 2026-09-01 (bumped `v8.5.7` → `v8.5.8`, same `v8.5.x` line per ADR-0032's own in-scope patch-bump carve-out; `v26.x` calendar-versioning scheme change still deferred) |
| Valkey (supersedes Redis, ADR-0010) | always-on-core | github.com/valkey-io/valkey | [ADR-0018](decisions/adr-0018-valkey-not-redis.md) | 2026-09-01 (bumped `8.1.9` → `8.1.10`, SECURITY release fixing GHSA-jcj7-v34w-v9vv — a use-after-free in RDMA connection handling — plus AOF/RDB/TLS/cluster-messaging bug fixes) |
| Kyverno | always-on-next-wave (Objective O1) | github.com/kyverno/kyverno | [ADR-0019](decisions/adr-0019-kyverno-admission-engine.md) | 2026-09-03 (chart bumped `3.8.2` → `3.9.0`, a minor bump taken because real fixes exist only on this line: CVE-2026-32280, CVE-2026-39836, GHSA-79gf-7frw-68m9, GHSA-gcjh-h69q-9w9g. Prior entry: 2026-08-27, `disallow-latest-tag` extended to cover `spec.initContainers`/`spec.ephemeralContainers`) |
| Argo Rollouts | always-on-next-wave (Objective O1) | github.com/argoproj/argo-rollouts | [ADR-0020](decisions/adr-0020-argo-rollouts-progressive-delivery.md) | 2026-09-01 (bumped chart `2.41.1` → `2.43.0`, appVersion `v1.9.1` → `v1.10.0`; routine currency, no CVE — zero published security advisories exist for this repo at all, unchanged since the 2026-08-19 sweep) |
| Velero | always-on-next-wave (Objective O1) | github.com/vmware-tanzu/velero | [ADR-0021](decisions/adr-0021-velero-backup-restore.md) | 2026-09-03 (full GHSA sweep: both published advisories checked — the second, GHSA-72xg-3mcq-52v4 Moderate (CVE-2020-3996, PV/PVC binding issue, affects `0.*`/`1.*` before `1.4.3`/`1.5.2`), had not been explicitly checked before — current pin (appVersion `1.18.1`, chart `12.1.0`) is many majors past. Prior entry: 2026-08-19, GHSA-j2g6-362q-6qc6 exactly at the fixed floor, confirmed via `v1.18.1`'s own changelog) |
| Trivy Operator | always-on-next-wave (Objective O1) | github.com/aquasecurity/trivy-operator | [ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md) | 2026-09-01 (bumped chart `0.35.0` → `0.36.0`, appVersion `0.33.0` → `0.34.0`, bundled Trivy scanner `0.73.0` → `0.74.0`; routine currency, no CVE — zero published security advisories exist for this repo at all, unchanged since the 2026-08-19 sweep) |
| Kargo | heavy-on-demand (`make kargo-up`/`kargo-down`) | github.com/akuity/kargo | [ADR-0023](decisions/adr-0023-kargo-promotion-pipeline.md) | 2026-09-01 (bumped `1.11.2` → `1.11.3`: real authz-bypass fix, "close cluster-scoped authorization bypass in generic resource writes" — not yet a formally filed GHSA/CVE; current pin `1.11.3` is the newest tag; no currency gap) |
| Harbor (supersedes Artifactory, ADR-0011) | heavy-on-demand (`make harbor-up`/`harbor-down`) | github.com/goharbor/harbor-helm | [ADR-0024](decisions/adr-0024-harbor-not-artifactory.md) | 2026-08-20 (GHSA sweep: 2 advisories published since the `1.19.2` chart bump — GHSA-prh4-vhfh-24mj Moderate (LDAP/OIDC secret not redacted in audit log) affects `>2.13.0,<2.14.3`/patched `2.13.5`,`2.14.3`,`2.15.0`, current appVersion `2.15.2` past the floor; GHSA-56j8-6qr5-cg75 Low (CVE-2026-4404) is disputed by the Harbor maintainers as not a legitimate vulnerability, no patched version listed — current chart `1.19.2` (Aug 3, 2026) reconfirmed the newest tag; no currency gap) |
| Oracle Cloud Infrastructure | cloud-backend (opt-in) | cloud.oracle.com | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) | not dated in ADR (no Re-evaluation log; decision date 2026-07-13) |
| k3s | cloud-backend (opt-in) | github.com/k3s-io/k3s | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) (backend choice) / [ADR-0030](decisions/adr-0030-pin-k3s-version-explicitly.md) (version pin + re-evaluation) | 2026-09-03 (bumped `v1.36.3+k3s1` → `v1.36.4+k3s1` on both backends, routine currency — a release-list summary claimed a CVE-2025-54410 mitigation but the release's own detailed notes don't confirm it and the CVE describes Docker Engine behavior k3s doesn't run, so treated as unconfirmed rather than asserted; see ADR-0030's own Re-evaluation log, which tracks k3s's real version-currency history across both backends; ADR-0027 itself has no Re-evaluation log, decision date 2026-07-13) |
| cert-manager | always-on-core | github.com/cert-manager/cert-manager | [ADR-0028](decisions/adr-0028-cert-manager-tls-lifecycle.md) | 2026-09-03 (full GHSA sweep: all 3 published advisories checked — the third, GHSA-r4pg-vg54-wxx4 Low (PEM-parsing DoS, patched `1.16.2`/`1.15.4`/`1.12.14`), had not been explicitly checked before — current pin `1.21.1` past every floor. Prior entry: 2026-08-19, GHSA-8rvj-mm4h-c258/GHSA-gx3x-vq4p-mhhv both past floor, no currency gap) |
| KEDA | on-demand (`make keda-up`/`keda-down`, converted from always-on-core 2026-08-25, ADR-0029 — lighter-weight than CHARTER's heavy-on-demand tier, not tracked in `ondemand-budget-check.sh`'s budget maps) | github.com/kedacore/keda | [ADR-0029](decisions/adr-0029-keda-event-driven-autoscaling.md) | 2026-09-03 (full GHSA sweep: all 3 published advisories checked — the third, GHSA-w92x-gx4w-j5f2 Low, is a command-injection bug in KEDA's own `pr-e2e.yml` CI workflow, not the deployed operator image; not applicable regardless of version. Prior entries: GHSA-c4p6-qg4m-9jmr High and GHSA-6w3m-4hhp-775q Moderate both past floor at `2.20.2`, no currency gap) |
| External Secrets Operator | always-on-core | github.com/external-secrets/external-secrets | [ADR-0036](decisions/adr-0036-external-secrets-vault-sync.md) | 2026-09-01 (bumped `2.9.0` → `2.10.0`: purely additive TLS-config schema change, real fixes incl. an AWS credential-log-redaction fix; no CVE. Current pin past every floor from the 2026-08-19 GHSA sweep and is the newest tag) |
| Forgejo | always-on-core (self-hosted git source + CI runner, host-level Docker Compose, outside the cluster) — **the live, running component as of 2026-08-17** (PR #1205's accelerated cutover); supersedes GitLab, whose `docker-compose.yml`/`infra/modules/gitlab-config` are still in the repo, stopped but kept for rollback until ROADMAP's remaining migration items (script/Makefile rename, full decommission) land | codeberg.org/forgejo/forgejo, code.forgejo.org/forgejo/runner | [ADR-0035](decisions/adr-0035-forgejo-not-gitlab.md) (supersedes [ADR-0033](decisions/adr-0033-gitlab-git-source-and-ci.md)) | 2026-08-17 (live cutover, PR #1205; image pins — `forgejo:16.0.2`, `runner:13.0.0` — independently reconfirmed current the same day, this run's own earlier currency check) |
| Mimir | always-on-core (observability — metrics store) | github.com/grafana/mimir | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-20 (image tag bumped `3.1.4` → `3.1.5`, Go stdlib CVE bump; `3.2.0` deliberately deferred — needs live-cluster coordinated-upgrade verification) |
| Loki | always-on-core (observability — log store) | github.com/grafana/loki | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-09-03 (image tag bumped `3.7.6` → `3.7.7`, security-relevant dependency bumps — see [ADR-0006](decisions/adr-0006-grafana-native-git-sync.md)'s own Re-evaluation log, which tracks Loki's real bump history; `2026-08-07` was only when ADR-0034 itself was authored, not a currency check) |
| Tempo | always-on-core (observability — trace store) | github.com/grafana/tempo | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-13 (image tag bumped `2.10.7` → `2.10.8`, Go stdlib + grpc/otel/x-net/x-text/compress security fixes — see [ADR-0006](decisions/adr-0006-grafana-native-git-sync.md)'s own Re-evaluation log, which tracks Tempo's real bump history; `2026-08-07` was only when ADR-0034 itself was authored, not a currency check) |
| Pyroscope | always-on-core (observability — continuous profiling) | github.com/grafana/pyroscope | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-08-10 (chart bumped `2.2.0` → `2.2.1`, upstream security release — `grpc-go`/`golang.org/x/text`/`golang.org/x/net`/`kin-openapi` CVE fixes) |
| Alloy | always-on-core (observability — unified collector) | github.com/grafana/alloy | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-09-01 (bumped `1.11.1` → `1.12.1`, appVersion `v1.18.1`→`v1.19.2`; chart templates/values.yaml byte-identical, none of v1.19.0's three breaking changes apply to this lab's River config; see ADR-0034's own Re-evaluation log) |
| kube-state-metrics | always-on-core (observability — Kubernetes object-state exporter) | github.com/kubernetes/kube-state-metrics | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-09-01 (chart bumped `8.4.0` → `8.4.1`, purely additive opt-in collectors, appVersion unchanged `2.20.0`; see ADR-0034's own Re-evaluation log) |
| node-exporter | always-on-core (observability — node/host metrics exporter) | github.com/prometheus/node_exporter | [ADR-0034](decisions/adr-0034-lgtmp-observability-stack.md) | 2026-09-01 (chart bumped `4.56.1` → `4.56.3`, real default `extraArgs` change filtering pseudo-filesystems from `node_filesystem_*` metrics, appVersion unchanged `1.12.1`; verified no dashboard panel affected; see ADR-0034's own Re-evaluation log) |
| Vault | always-on-core (secrets backend) | helm.releases.hashicorp.com, github.com/hashicorp/vault | [ADR-0037](decisions/adr-0037-vault-secrets-management.md) | 2026-09-03 (ADR-0037 authored as a retroactive governance record — Vault previously had no ADR and its version history lived only as inline `gitops/platform/vault.yaml` comments, now migrated; server image bumped `2.0.4`→`2.1.0` in the same cycle, two real Go-vulnerability-database dependency fixes, no GitHub-native advisories exist for this repo; see ADR-0037's own Re-evaluation log) |
| moto | always-on-core (AWS emulator) | github.com/getmoto/moto | [ADR-0038](decisions/adr-0038-ack-kro-moto-cloud-control-plane.md) | 2026-09-03 (ADR-0038 authored as a retroactive governance record — moto previously had no ADR; image bumped `5.2.2`→`5.2.3` in the same cycle, confirmed via Docker Hub's tags API (`last_updated: 2026-08-22`), routine patch, no CVE — zero published GHSA advisories exist for this repo at all; see ADR-0038's own Re-evaluation log) |
| ACK S3 controller | always-on-core (cloud-control-plane demo) | public.ecr.aws/aws-controllers-k8s, github.com/aws-controllers-k8s/s3-controller | [ADR-0038](decisions/adr-0038-ack-kro-moto-cloud-control-plane.md) | 2026-09-03 (ADR-0038 authored as a retroactive governance record — ACK S3 previously had no ADR, its version history lived only as inline `gitops/platform/ack-s3.yaml` comments, now migrated; current pin `1.11.0` reconfirmed the newest tag (`1.11.1` 404s); zero published GHSA advisories exist for this repo) |
| KRO | always-on-core, currently suspended (cluster-load reduction, 2026-08-24) | ghcr.io/kro-run/kro, github.com/kubernetes-sigs/kro | [ADR-0038](decisions/adr-0038-ack-kro-moto-cloud-control-plane.md) | 2026-09-03 (ADR-0038 authored as a retroactive governance record — KRO previously had no ADR; current pin `0.9.3` reconfirmed the newest tag via the real GitHub releases list; project moved orgs to `kubernetes-sigs/kro` since the original pin, noted but not action-requiring; zero published GHSA advisories exist for this repo) |
| s3manager | always-on-core (Garage browser UI) | github.com/cloudlena/s3manager | [ADR-0039](decisions/adr-0039-s3manager-garage-browser-ui.md) | 2026-09-03 (ADR-0039 authored as a retroactive governance record — s3manager previously had no ADR, its version history lived only as inline `gitops/storage/s3manager/deployment.yaml` comments, now migrated; bumped `v0.8.0`→`v0.9.0` in the same cycle, confirmed via Docker Hub's tags API and a real commit diff (CSS-framework migration, dependency bumps, no CVE) — zero published GHSA advisories exist for this repo; see ADR-0039's own Re-evaluation log) |

## Keeping this in sync

**"Last reviewed" staleness is now mechanically guarded.** As of 2026-08-24,
`scripts/dependency-register-check.sh` (`make dependency-register-check`, wired into
`make ci`'s `drift` job) fails the build if any row's "Last reviewed" date is older
than the newest Re-evaluation-log entry of the ADR(s) cited in that row's ADR column —
the exact gap this section used to name ("nothing currently fails `make ci` if it
drifts"), closed after it bit real rows twice (Inkless/TiDB Operator/cert-manager,
2026-08-12; the k3s row, 2026-08-24 — see the script's own header comment for both).
Two honest limits remain, stated there rather than overclaimed: it can't check an ADR
that has no Re-evaluation log at all, and it can't invent a review date for an ADR
that never recorded one — both are gaps in the underlying ADR, not something this
guard could paper over.

**Register → concentration.md sync is now mechanically guarded too.** As of
2026-09-02/03, `scripts/dependency-concentration-sync-check.sh` (`make
dependency-concentration-sync-check`, also wired into `make ci`) counts how many rows
above share each `github.com` upstream org and fails if any org backing 2+ rows isn't
named in [`docs/dependency-concentration.md`](dependency-concentration.md) — the
"future row add/remove/rename here should prompt a look there too" caveat this section
used to state as a manual-only expectation is now enforced, not just hoped for. It
checks one direction only (a real concentration point missing from concentration.md);
it does not check the reverse (a concentration.md entry with no matching register
rows) — a real, separately-scoped gap, same partial-coverage shape as this repo's
other drift guards (e.g. `adr-chart-version-sync-check.sh` only checks ADRs that
self-declare a chart-version note).

[`docs/dependency-concentration.md`](dependency-concentration.md) is a downstream
consumer of the table above (grouped by upstream GitHub org, closing
[`docs/dora-audit-readiness.md`](dora-audit-readiness.md) Q16's gap) — see that file's
own "Keeping this in sync" section for how its sync to
[`docs/dependency-exit-runbooks.md`](dependency-exit-runbooks.md) (Q17) is guarded.
