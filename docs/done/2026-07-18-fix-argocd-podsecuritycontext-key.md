# Fix `podSecurityContext` key mismatch in ArgoCD's own Terraform-bootstrapped chart

Bugfix discovered continuing this run's key-path-mismatch audit (PR #493 fixed the same
bug class across four observability Applications). CHARTER **Objective O2** hardening /
ADR-0017 correctness — no new architectural decision, this corrects enforcement of RFC
#205's already-decided posture.

## The bug

`infra/modules/argocd/values.yaml` (RFC #205 Phase 2, `auto/argocd-pss-enforce`) set
`global.podSecurityContext` and `global.containerSecurityContext` intending to configure
ArgoCD's pod- and container-level `securityContext` for PSA `restricted` compliance —
this is the highest-blast-radius component in the lab (the GitOps control plane itself),
and its namespace already carries `pod-security.kubernetes.io/enforce: restricted`.

Verified against the pinned chart (`argo-cd` v9.5.20, `argoproj/argo-helm`):

- **Pod-level:** the chart's templates (e.g.
  `templates/argocd-application-controller/deployment.yaml`) read
  `.Values.global.securityContext` — NOT `global.podSecurityContext`, which does not
  exist in this chart's schema at all. Since the chart's own `global.securityContext`
  default is `{}` (empty) and Helm's `{{- with .Values.global.securityContext }}` skips
  the entire pod `securityContext:` block when the value is empty, **no pod-level
  securityContext was being applied to any ArgoCD component at all** under the old key.
- **Container-level:** the chart has no `global.containerSecurityContext` key either — it
  configures each component's container securityContext individually
  (`controller.containerSecurityContext`, `server.containerSecurityContext`,
  `repoServer.containerSecurityContext`, `applicationSet.containerSecurityContext`, plus
  the bundled session-cache sub-chart's own key). Our single `global.containerSecurityContext`
  was a no-op there too.

## Why this wasn't a live outage

Checked every component's own chart-default `containerSecurityContext` directly: all of
them (`controller`, `server`, `repoServer`, `applicationSet`, `dex`, and the bundled
session-cache sub-chart) already default to `runAsNonRoot: true`,
`readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`,
`seccompProfile.type: RuntimeDefault`, `capabilities.drop: [ALL]` at the container level —
independent of anything this repo's values file sets. Kubernetes PSA `restricted` accepts
`seccompProfile`/`runAsNonRoot` enforcement at either the pod level OR every container's
own level; since every container already satisfied it, ArgoCD was never actually blocked
from scheduling by this bug. The gap this fix closes is a genuine but previously-invisible
one: no pod-level defense-in-depth layer, and a container-level override this repo
believed it was setting explicitly but wasn't.

## The fix

1. Renamed `global.podSecurityContext` → `global.securityContext`, keeping the exact
   intended values (this is the one functional change — pod-level enforcement is now
   real where it previously did nothing).
2. Removed the dead `global.containerSecurityContext` block rather than expanding it into
   four-plus redundant per-component blocks that would only restate values the chart
   already defaults to identically — verified this is genuinely redundant, not a
   regression, by checking every component's actual chart-default `containerSecurityContext`
   directly (see above).
3. **Recurrence guard**: rewrote `tests/securitycontext-argocd-pss2.bats`'s pod-level
   assertions as path-aware `yqs()` checks against `.global.securityContext.*` (this
   repo's yq-variant-robust bats helper), plus two explicit negative assertions that the
   dead `global.podSecurityContext` and `global.containerSecurityContext` keys are absent.
   The old tests were bare `grep -q 'value'` checks that would have kept passing purely
   because this fix's own explanatory comment contains the literal strings
   `readOnlyRootFilesystem: true` / `allowPrivilegeEscalation: false` — verified this by
   confirming those exact strings only appear in the comment now, not as functional YAML,
   and that the old test style would have silently masked that.

## Verification

Checked the pinned chart's actual `templates/` and `values.yaml` at the pinned version
(`argo-cd-9.5.20`) directly via `raw.githubusercontent.com`, not assumed from RFC #205's
original (pre-verification) design intent. `bats tests/securitycontext-argocd-pss2.bats`:
6/6 pass. `python3 -c "import yaml; yaml.safe_load(...)"`: valid YAML syntax (terraform CLI
not installed in this session; content validity was the relevant risk for this text-only
values-file change, not a `terraform validate` schema check).

## What this does NOT claim

Per ADR-0004: this is a clusterless environment, so whether the corrected pod-level
`securityContext` actually applies cleanly on a live cluster is not verifiable here.
ArgoCD was already running successfully under PSA `restricted` before this fix (via
container-level chart defaults, as established above) — this fix adds a defense-in-depth
layer and fixes a misleading configuration, it does not fix an outage. Rollback: revert
this commit — the key reverts atomically, and since the chart's own container-level
defaults were carrying real enforcement the whole time, there is no functional regression
risk either way.

## PR

https://github.com/tooming/k8s-anywhere/pull/496
