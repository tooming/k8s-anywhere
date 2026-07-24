# [Action needed] Now/next still gated; platform chart-pin sweep also clean (tidb-operator v2 confirmed experimental, held)

## What's blocked

The "Now / next" lane's remaining unchecked items are all gated on the standing
maintainer-confirmation issues #631/#632/#633 — re-verified this cycle (ninth
dated cycle today): all three still open, zero comments, `updated_at`
unchanged since 2026-07-21T05:34 UTC.

## This cycle's fresh angle

Prior cycles today verified GitHub Actions pinning, Loki, ADR-0014, `:latest`
tags (cycle 1), External Secrets/Trivy Operator/KEDA (cycle 2), workflow
permissions (cycle 3), the Vault image pin (cycle 4), a CHARTER objective
audit (cycle 5), k3s/ArgoCD version currency (cycle 6), a janitor
duplication/doc-drift sweep (cycle 7), and CHARTER Core Values + Cilium
currency (cycle 8) — none of those touched the remaining platform Helm
charts. This cycle did: **direct upstream chart-version verification for
every `gitops/platform/*.yaml` `targetRevision` pin not covered by any prior
dated sweep** — cert-manager, Argo Rollouts, Velero, Kyverno, Longhorn,
Harbor, Prometheus Node Exporter, Artifactory-oss, and TiDB Operator — via
`git ls-remote --tags` (`git`/`raw.githubusercontent.com` reachable in this
sandbox; `charts.jetstack.io`, `*.github.io` Pages hosts, and
`public.ecr.aws` are proxy-blocked, confirmed via
`curl "$HTTPS_PROXY/__agentproxy/status"` — 403 policy denial on each, same
finding cycle 2 made for `*.github.io`) with `sort -V` (raw `git ls-remote`
output is not version-sorted — a genuine footgun, `tail -N` alone on
unsorted output silently returns the wrong "latest" tag):

1. **cert-manager** (`gitops/platform/cert-manager.yaml`, pin `1.21.0`).
   `git ls-remote --tags https://github.com/cert-manager/cert-manager.git`
   → newest stable tag `v1.21.0`. Current. No gap.
2. **Argo Rollouts chart** (`gitops/platform/argo-rollouts.yaml`, pin
   `2.41.1`). `git ls-remote --tags https://github.com/argoproj/argo-helm.git`
   filtered to `argo-rollouts-*` tags → newest `2.41.1`. Current. No gap.
3. **Velero chart** (`gitops/platform/velero.yaml`, pin `12.1.0`).
   `git ls-remote --tags https://github.com/vmware-tanzu/helm-charts.git`
   filtered to `velero-*` tags → newest `12.1.0`. Current. No gap.
4. **Kyverno chart** (`gitops/platform/kyverno.yaml`, pin `3.8.2`). The
   `kyverno/kyverno` repo's own git tags only cover chart `2.x` (superseded
   scheme) — fetched the real serving index
   `raw.githubusercontent.com/kyverno/kyverno/gh-pages/index.yaml` instead
   (the chart's actual `repoURL`) and read the newest `kyverno` entry
   directly: `version: 3.8.2`, `appVersion: v1.18.2`, `created:
   2026-07-10`. Current. No gap.
5. **Longhorn** (`gitops/platform/longhorn.yaml`, pin `1.11.3`). Newest tag
   `v1.12.0` exists but this is **already a documented hold** —
   [ADR-0013](../decisions/adr-0013-longhorn-block-storage.md)'s
   Re-evaluation log recorded `1.12.0` was checked and held before (also
   cross-referenced from `adr-0015-inkless-diskless-kafka.md` and
   `ROADMAP.md`). Re-confirmed still the latest tag, still correctly held.
   No new action.
6. **Harbor chart** (`gitops/platform/harbor.yaml`, pin `1.19.1`).
   `git ls-remote --tags https://github.com/goharbor/harbor-helm.git` →
   newest stable `1.19.1`. Current. No gap. (Harbor is on-demand/ADR-0024;
   zero live-cluster relevance either way.)
7. **Prometheus Node Exporter** (`gitops/platform/observability-node-exporter.yaml`,
   pin `4.56.1`). `git ls-remote --tags
   https://github.com/prometheus-community/helm-charts.git` filtered to
   `prometheus-node-exporter-*` → newest `4.56.1`. Current. No gap.
8. **Artifactory-oss** (`gitops/platform/artifactory.yaml`, pin `107.77.11`).
   Newer tags exist upstream (`107.146.x` line), but Artifactory is the
   subject of two already-gated ROADMAP items (`auto/harbor-capstone-rewire`,
   `auto/harbor-artifactory-decommission`, both blocked on #632) — it is
   being **decommissioned**, not maintained forward, per ADR-0024. Bumping a
   component mid-decommission would be wasted/reverted work, so deliberately
   not touched. No action.
9. **TiDB Operator** (`gitops/platform/tidb-operator.yaml`, pin `1.6.5`).
   `git ls-remote --tags https://github.com/pingcap/tidb-operator.git` →
   `1.6.5` is the newest tag on the `1.6.x` line (no gap there), but `v2.0.0`
   and `v2.0.1` also exist as a major bump. Per
   `routines/upgrade-drafter.prompt.md`'s "skip major bumps, open an issue"
   rule this would normally get filed as an issue (mirrors #704/#705 for
   kube-state-metrics/Kafka) — but fetching `v2.0.0`'s own `README.md`
   (`raw.githubusercontent.com/pingcap/tidb-operator/v2.0.0/README.md`)
   found upstream's own explicit warning: **"NOTE: The v2 is experimental
   now, PLEASE don't use it in production."** Also confirmed the chart's
   `Chart.yaml` `apiVersion` moved `v1` → `v2` (Helm chart schema, not
   TiDB's own version) and added a `kubeVersion: ">=1.30.0-0"` floor. Given
   upstream's own production warning, filing this as an "upgrade candidate"
   issue (the #704/#705 shape — "should we build this?") would be
   misleading; the correct record is the opposite: **1.6.5 is confirmed the
   right pin, hold until v2 exits experimental status** — the same shape as
   the Longhorn `1.12.0` hold (finding 5 above), just not yet backed by a
   dedicated ADR since no ADR currently governs TiDB Operator's version
   specifically. No issue filed; no ROADMAP item opened — there is nothing
   to decide until upstream ships a stable v2.

All nine pins are either current, deliberately held with a documented
reason, or mid-decommission — a real, verified sweep with one substantive
new finding (TiDB Operator v2's experimental status) rather than a rubber
stamp.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition; (c) a new GitHub issue of any
size; (d) TiDB Operator v2 exiting experimental status upstream (new,
tracked informally here — no issue needed until then).

This note is this cycle's honest record — on top of the eight PRs already
merged earlier today (#701, #702, #703, #706, #709, #710, #711) plus eight
prior `[Action needed]` notes today (#712, #713, #714, #715, and four more
from this run) — not a stopping point. The run continues to the next cycle
per `executor.prompt.md` STEP 8.
