# [Action needed] Now/next still gated; O2 namespace-coverage audit also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified
this cycle: all three still open, still zero comments.

## This cycle's fresh angle

A structural audit of CHARTER Objective O2 ("every namespace either enforces
default-deny NetworkPolicy and PSS-restricted labels, or has an ADR-cited
carve-out"), rather than another version/upstream sweep:

1. Every `gitops/*/namespace.yaml` directory (28 components) has a matching
   `gitops/*/networkpolicy/kustomization.yaml` overlay — 1:1, no gaps either
   direction.
2. Cross-checked each overlay's actual ArgoCD registration: 9 of the 28
   (`argo-rollouts`, `cert-manager`, `envoy-gateway-system`, `kargo`,
   `kargo-project`, `keda`, `kyverno`, `trivy-system`, `velero`) don't appear
   in `gitops/platform/networkpolicy-appset.yaml`'s shared list-generator —
   initially looked like a possible registration gap, but each instead has
   its own standalone `gitops/platform/<name>-networkpolicy.yaml`
   `Application` applying the same overlay independently (a second,
   intentional registration mechanism this repo uses alongside the shared
   appset). Verified each standalone Application carries `syncPolicy.
   automated` (or, for the two genuinely on-demand pairings — `kargo` and
   `kargo-project`, which mirror their parent Applications' on-demand,
   non-auto-synced state per rule #4's budget constraint — an explicit
   `ON-DEMAND: pairs with the kargo Application` comment documenting why).
   No orphaned or disabled overlay found.

Conclusion: O2 coverage is genuinely complete as ROADMAP's own "Now/next"
header note already claimed — this audit independently re-confirms it via a
different check (registration completeness, not just file presence) rather
than taking the prior claim at face value.

## Prior cycles this run (context, not idle)

PR #690 (ArgoCD Terraform-bootstrapped chart bump, found outside
`upgrade-drafter`'s previous scope), PR #691 (closed that scope gap), PR #692
(CI-tooling + Pyroscope-hold sweep, clean).

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition; (c) a new GitHub issue.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
