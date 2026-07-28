# [Action needed] Now/next still gated; Kyverno mutate policies + NetworkPolicy coverage recheck clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped eight real, merged deliverables (PRs
#789, #790, #792, #793, #794, #795, #796, #797) — the last two being genuine live-cluster
bugfixes found via a structural cross-reference technique (comparing a hardcoded
Kyverno exclude-list against actual `:latest` image usage across `gitops/`): PR #796
pinned two floating-tag images (`lab-demo`, `storage`), and PR #797 added a documented
`inkless` carve-out to `disallow-latest-tag.yaml` (no stable upstream tag exists to pin
to instead).

This cycle extended that same cross-reference technique to two more places, both
came up clean:

1. **The other two Kyverno mutate `ClusterPolicy` files** (`add-default-runasnonroot.yaml`,
   `add-default-seccomp.yaml`) — checked whether either carries a hardcoded namespace
   exclude-list vulnerable to the same drift class as `disallow-latest-tag.yaml` before
   this run's fix. Both use a dynamic `namespaceSelector` matching the
   `pod-security.kubernetes.io/enforce` PSA label (the same self-maintaining pattern
   `require-pod-security-restricted.yaml` uses) rather than a hardcoded list — structurally
   immune to this bug class already. `add-default-seccomp.yaml` has no exclude block at
   all (mutate-only, additive, no admission-blocking risk).
2. **NetworkPolicy/Governance ApplicationSet namespace-coverage cross-check** — diffed
   every `gitops/*/namespace.yaml`-declared namespace against `networkpolicy-appset.yaml`'s
   and `governance-appset.yaml`'s list generators. The governance-side gaps found
   (`artifactory`, `inkless`, `istio-system`, `longhorn-system`, `tidb`, `tidb-admin`) are
   all documented, intentional on-demand-heavy exclusions (RFC #294's own mapping table).
   The NetworkPolicy-side gaps found (`argo-rollouts`, `capstone-pipeline`, `cert-manager`,
   `envoy-gateway-system`, `kargo`, `keda`, `kyverno`, `trivy-system`, `velero`) were all
   false positives from this check's own blind spot — each has NetworkPolicy coverage via
   its own dedicated per-component `gitops/<name>/networkpolicy/` directory + Application
   (a different, older wiring pattern than the shared appset, not a gap). Verified this
   directly for `capstone-pipeline` (the least obviously-covered one, since its directory
   lives under `gitops/kargo-project/networkpolicy/` rather than a name matching the
   namespace) against `tests/networkpolicy-capstone-pipeline.bats`'s existing 9 passing
   assertions and `gitops/platform/kargo-project-networkpolicy.yaml`.

No further actionable gap surfaced from either lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
