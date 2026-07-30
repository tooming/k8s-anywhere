# [Action needed] Now/next still gated; kro bump shipped, securityContext key-nesting audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items
(`verifyImages ClusterPolicy — Audit → Enforce flip`, `O4 CI gate —
verify-image-rejection job`, `Remove legacy capstone Deployment`) — all gated
on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633). Re-checked this
cycle: both still open, no new comments since the verification-command fixes
posted 2026-07-29/30. No live-cluster-safe slice of either gated item exists
to split off (rule #9's split-the-gate test — both are atomic
enforcement/removal flips).

## What this run already did

Two real merged PRs this run, via a fresh planner-fallback angle not yet
tried today: a currency sweep against every ADR'd/pinned Helm chart **not
already covered by yesterday's sweeps** (Cilium, RabbitMQ, cert-manager,
KEDA, ArgoCD, ack-resources, Grafana, TiDB Operator, Trivy Operator, Vault
were all checked 2026-07-29/30) — specifically Kyverno, Longhorn, Istio,
External Secrets, Velero, Harbor, `kro`, `ack-s3`, Pyroscope, and
kube-state-metrics, verified via `git ls-remote --tags` against each chart's
real GitHub source repo (this sandbox's proxy 403s the Helm-index HTTPS
hosts directly — confirmed via `$HTTPS_PROXY/__agentproxy/status` — but
git's own protocol to `github.com` is unblocked).

Everything checked out current except `kro`: pinned `0.9.2`, real upstream
`v0.9.3` existed (bug fixes — nil-pointer fix, stuck-deletion fix, panic
recovery — plus an OpenTelemetry dependency bump addressing a CVE in that
dependency, no breaking changes). Landed as
[#900](https://github.com/tooming/k8s-anywhere/pull/900) (planner: added the
item to Now/next) then
[#901](https://github.com/tooming/k8s-anywhere/pull/901) (executor: the
actual bump, `context.md` sync, and a tightened bats assertion). Also
checked Longhorn (`v1.11.3` → `v1.12.0` exists but is a minor bump with real
breaking changes — V2 Backing Images removed, a Kubernetes-version floor
raise — and no security driver behind it, so correctly kept per this repo's
smallest-safe-delta convention, not built) and Istio/RabbitMQ (both already
at the newest stable tag, no action).

## This cycle's fresh angle (clean)

A **securityContext/containerSecurityContext key-nesting audit**, not yet
attempted today: the exact bug class PR #493 found and fixed in
`kube-state-metrics` (a value silently nested under the wrong, ignored key —
`securityContext` where the chart expects `containerSecurityContext`, or vice
versa) was re-checked against every other Application file in
`gitops/platform/` that sets an explicit securityContext override:
`ack-s3.yaml`, `external-secrets.yaml`, `kargo.yaml`, `kro.yaml`,
`kyverno.yaml`, `observability-alloy.yaml`, `observability-pyroscope.yaml`,
and `vault.yaml` (in addition to `kube-state-metrics`/`grafana`/
`node-exporter`, already covered by path-aware bats assertions per the prior
audit). Every one already carries an inline comment citing direct
verification against that chart's real `values.yaml`/template source at the
pinned tag — `kyverno.yaml`'s admissionController block, `pyroscope.yaml`'s
explicit "does NOT use the dead containerSecurityContext key" bats
assertion, `alloy.yaml`'s per-component `securityContext:` placement with a
verified-against-chart-source comment. No mismatch found — the prior
`auto/kro-bump-0-9` session's fix was thorough, not a one-off.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 (a real CI run
signing + pushing to Harbor) or #633 (a real Kargo promotion observed); (b) a
new GitHub issue of any size (ungroomed intake); (c) a new upstream
CVE/release firing a tracked ADR flip condition.

This note is this cycle's honest record — two genuinely fresh angles (an
upstream currency sweep across ten previously-unchecked charts, which found
and shipped a real fix, and an independent securityContext key-nesting audit
across every chart with an explicit override) rather than a repeat of a check
already logged today. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
