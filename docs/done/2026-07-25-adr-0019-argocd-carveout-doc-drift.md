# ADR-0019 doc drift — document the `argocd` carve-out in `disallow-latest-tag`

Janitor-fallback cleanup (executor's STEP 6b chain, JANITOR role — "stale doc
reference" category). The Now/next lane is fully gated on the three standing
maintainer-confirmation issues (#631/#632/#633, all still open/unconfirmed),
and the planner/architect/upgrade-drafter/doc-drift-author lenses found no
groomable intake, no un-RFC'd 🟡 item, no dependency gap, and no
README/dependency-tree/lab-UI drift this cycle (doc-drift-author is
explicitly barred from touching ADRs, so this fix falls to the janitor lane).

## What was stale

`gitops/kyverno/policies/disallow-latest-tag.yaml`'s `exclude.any[0].resources.namespaces`
list is `[capstone, argocd]` — the `argocd` carve-out was added today
(commit `1659b5e`, PR #722, part of the #632 live-cluster investigation into
an ArgoCD controller OOM crashloop + Kyverno bootstrap deadlock) and already
has a code comment explaining it plus dedicated `tests/kyverno.bats`
coverage (`"disallow-latest-tag excludes the argocd namespace (global.image.tag: latest pin)"`).

But [ADR-0019](../decisions/adr-0019-kyverno-admission-engine.md) — the
binding document this policy cites in its own `policies.kyverno.io/description`
annotation — still only documented the original `capstone` carve-out (issue
#498) in both the policy table and the "Scope & exceptions" section. A reader
consulting the ADR (the intended entry point per CLAUDE.md's "ADRs are
binding" rule) would not learn the `argocd` exclusion exists or why.

## Fix

Added the `argocd` carve-out to both ADR-0019 locations (policy table row +
Scope & exceptions bullet), mirroring the existing `capstone` carve-out's
structure: what's excluded, why (the `global.image.tag: latest` pin in
`infra/modules/argocd/values.yaml`, blocked on argoproj/argo-cd#26666
shipping in a stable release), and the flip condition (remove once a stable
argo-cd release ships that PR and the pin moves off `latest`). Text mirrors
the policy file's own code comment for accuracy — no new claim invented
(ADR-0004). Behavior-preserving: no code, test, or policy file touched, only
the ADR's prose brought in line with what already shipped today.

`make ci` passes unchanged (all existing checks, no new gate needed — this
is prose reconciliation, not a new invariant).

## PR

https://github.com/tooming/k8s-anywhere/pull/726
