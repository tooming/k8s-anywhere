# Janitor fix — upgrade-drafter's chart sweep couldn't see infra/'s Terraform-pinned charts

CHARTER Core Values §"Everything as code" + CLAUDE.md's bugfix-prevents-recurrence
rule. Janitor fallback sweep (`executor.prompt.md` STEP 6b) after the "Now / next"
lane came up fully gated on standing maintainer-confirmation issues
#631/#632/#633, and this cycle's fresh angle (a full upgrade-drafter re-sweep,
including a genuinely new lens: infra/-hosted Terraform Helm chart pins rather
than only gitops/-hosted ArgoCD `Application` pins) turned up a real footgun in
the routine's own scope definition.

## The bug that already bit us

While bumping the ArgoCD chart pin this cycle
(`docs/done/2026-07-23-argocd-chart-bump-9-5-20-to-9-7-1.md`, PR #690), the pin
turned out to be two minor releases stale (`9.5.20` when `9.7.1` was current).
That's despite at least two prior full upgrade-drafter sweeps this session
explicitly listing ArgoCD as checked and "already current" (per
`docs/done/2026-07-23-tidb-version-bump-8-1-2-to-8-5-7.md`'s closing note and
`docs/backlog/2026-07-23-action-needed-cycle11-post-drift-split.md`'s "fresh
upstream sweep across Longhorn, Kyverno, cert-manager, Kargo, Vault, ArgoCD,
and Trivy Operator" line).

Root cause: `routines/upgrade-drafter.prompt.md`'s STEP 2 enumeration is
scoped to `Walk gitops/**/*.yaml for: ArgoCD Application resources...`. ArgoCD
itself is bootstrapped by Terraform (ADR-0001's seam), not deployed as a
gitops-managed `Application` — its chart pin lives in
`infra/modules/argocd/variables.tf` + each `infra/live/*/argocd/terragrunt.hcl`,
which the routine's own defined scope never looks at. Every "ArgoCD already
current" claim in this session's prior sweeps was checking something else
(most likely the app-version release feed) without ever actually reading this
file — the routine's contract structurally couldn't have caught it.

## Fix

Extended `routines/upgrade-drafter.prompt.md` STEP 2 with a second, explicit
enumeration pass over `infra/modules/**/*.tf` + `infra/live/**/*.hcl` for
Terraform-bootstrapped Helm chart version pins (a `helm_release` chart version
exposed as a `variable` and set via each `terragrunt.hcl`'s `inputs`), naming
this exact miss as the motivating precedent so a future run doesn't silently
drop it again. No `routines.yaml` edit — this is a `*.prompt.md`-only change,
so per CLAUDE.md's pointer-architecture rule it needs no `RemoteTrigger
update`/`make routines-mark-applied` apply step; it is live for the next
routine invocation the moment this PR merges.

This is a routine-prompt/process fix, not a code change — `make ci`'s
`routines-check` and `no executor-authored routine edits` guards both stay
green (they gate `routines.yaml` specifically, untouched here).

## Files changed

- `routines/upgrade-drafter.prompt.md` — STEP 2 enumeration scope extended.

## PR

[#691](https://github.com/tooming/k8s-anywhere/pull/691)
