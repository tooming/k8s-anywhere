# [Action needed] Now/next still gated; full remaining chart-pin sweep found nothing actionable

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (this session started from a cold, locally-stale clone that had to be
reset to `origin/main` first): all three still open, still zero comments,
`updated_at` unchanged since 2026-07-21.

## This cycle's fresh angle

The immediately preceding cycle's record
(`docs/backlog/2026-07-22-action-needed-yq-guard-envoy-check.md`) swept
`cert-manager`, `keda`, `velero`, and `envoy-gateway`. This cycle swept every
remaining ArgoCD-managed chart pin in `gitops/platform/*.yaml` that no prior
cycle's recorded note had explicitly checked, via `git ls-remote --tags`
against each chart's real upstream repo (network-verified per ADR-0004):

| Component | Pinned | Latest upstream | Verdict |
|---|---|---|---|
| Kiali (`kiali-server`) | `1.89.8` | `1.89.8` | current |
| TiDB Operator | `1.6.5` | `1.6.5` | current |
| KRO | `0.9.2` | `0.9.2` | current |
| ACK S3 controller | `1.8.1` | `1.8.1` | current |
| prometheus-node-exporter | `4.56.1` | `4.56.1` | current |
| Trivy Operator chart | `0.34.0` | `0.34.0` | current |
| Istio (base/cni/istiod/ztunnel) | `1.30.3` | `1.30.3` (no `1.31.x` line yet) | current |
| Vault (`vault-helm`) | `0.34.0` | `0.34.0` | current |
| Harbor | `1.19.1` | `1.19.1` | current |
| Kargo | `1.10.9` | `1.10.9` | current |
| Longhorn | `1.11.3` | `1.12.0` available | **held — see below** |
| kube-state-metrics | `7.8.1` | `8.0.0` available | **held — see below** |
| Artifactory | `107.77.11` | `107.146.29` available | **not pursued — see below** |

### Longhorn `1.12.0` — held

Checked the real release (`github.com/longhorn/longhorn/releases/tag/v1.12.0`
via web search, since `api.github.com`/`github.com` HTML are proxy-blocked in
this environment but the release content is indexed). `1.12.0` is a feature
release (V2 Data Engine reaches GA) with three named bug fixes (replica
scheduling accumulation, an instance-manager panic during rebuild storms, a
replica auto-balance loop regression) — no CVE or security bulletin named
anywhere. This is the identical fact pattern this session already established
a precedent for with Valkey `8.1.0` (ADR-0018 audit #627) and Alloy `1.11.0`
(previous cycle in this run): "a newer minor exists" with no security/
critical-bug rationale is pure churn on a component with real blast radius
(distributed block storage — a live upgrade migrating an on-demand
StatefulSet's data plane is exactly the kind of change that shouldn't move
without cause). Held the pin at `1.11.3`.

### kube-state-metrics `8.0.0` — held

Sparse-cloned `prometheus-community/helm-charts` at both tags to compare
directly: `appVersion` is **identical** (`2.19.1`) between `7.8.1` and
`8.0.0` — the underlying kube-state-metrics binary is completely unchanged.
The chart-only major-version bump is `[kube-state-metrics] drop
CiliumNetworkPolicy support (#6183)`. Confirmed
`gitops/platform/observability-ksm.yaml`'s `valuesObject` never sets the
chart's `networkPolicy` key (this repo manages NetworkPolicy via its own
per-namespace overlay pattern, not chart-native `CiliumNetworkPolicy`
templating), so the breaking change is a genuine no-op for our config. Even
so, held rather than bumped: no security/critical-bug rationale exists either
(same bar as Longhorn above and the session's established Valkey/Alloy
precedent) — this would be a bump for its own sake, and CLAUDE.md's
"never fabricate make-work" / ROADMAP rule #9 apply to version churn exactly
as much as to invented code changes. Worth revisiting if a future sweep finds
an actual reason to move (a CVE, or the 7.x line being deprecated).

### Artifactory `107.77.11` vs `107.146.29` — not pursued

Artifactory is mid-decommission (ADR-0024: Harbor supersedes it; ROADMAP has
a queued, gated `Decommission Artifactory manifests` item). Bumping a pin on
a component already scheduled for removal, gated behind #632, would be
counter-productive churn on code with a known, better outcome already queued
(deletion) — correctly not pursued.

## Other lenses (also swept this cycle, came up empty)

- **Planner:** no ungroomed issues beyond the three standing trackers,
  `docs/roadmap/incoming/` empty.
- **Triager:** all three open issues (#631/#632/#633) already fully labeled.
- **Janitor:** verified every `scripts/*.sh` and `scripts/lib/*.sh` file has
  bats coverage (including the four `scripts/lib/` helpers, each covered by
  its own `tests/*-lib.bats` file). Fresh repo-wide TODO/FIXME/XXX grep
  turned up only the two already-adjudicated items (`ROADMAP.md`'s
  historical mention of a resolved harbor governance TODO, and
  `infra/modules/argocd/values.yaml`'s `image.tag: latest` override, both
  previously confirmed correct/non-actionable in earlier cycles' notes).

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631, #632, or #633; (b) a new upstream CVE/release firing a tracked flip
condition on Longhorn, kube-state-metrics, or any other pinned component;
(c) Envoy Gateway `v1.8.3`'s image artifact actually publishing (chart is
live on Docker Hub as of this cycle, but `gateway-dev:v1.8.3` still 404s —
re-check next cycle); (d) a new GitHub issue of any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
