# [Action needed] Now/next still gated; PSA namespace-label completeness audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#871](https://github.com/tooming/k8s-anywhere/pull/871) (verified the
concurrent session's two merged fixes actually landed correctly).

## This cycle's fresh angle

Cross-checked every `gitops/**/namespace.yaml` manifest's Pod Security
Admission labels against ADR-0017's per-namespace table directly (`yq` field
reads of `metadata.labels`, not text matching):

- All 28 namespace manifests carry all four required labels
  (`enforce`/`enforce-version`/`warn`/`audit`) — no namespace has a partial
  label set (e.g. `enforce` present but `warn`/`audit` missing, which would
  leave a live cluster silently unaudited on the other two PSA levels even
  though admission enforcement itself would still work).
- Every manifest's `enforce` value (`restricted`/`baseline`/`privileged`)
  matches ADR-0017's table exactly — including the two cases where the
  directory name and the actual `metadata.name` differ
  (`gitops/network/namespace.yaml` → `lab-gateway`; `gitops/kargo-project/
  namespace.yaml` → `capstone-pipeline`), which could otherwise look like an
  undocumented namespace on a naive directory-name-only cross-reference.
- Checked whether any ArgoCD `Application` using `CreateNamespace=true`
  (69 files) creates a namespace that lacks a corresponding explicit
  `namespace.yaml` with PSA labels — all of them have one; `CreateNamespace`
  here is a same-name safety net, not a bypass around the label manifests.

**Conclusion: zero gaps.** Every namespace is labelled, every label value
matches the ADR's documented decision, and no ArgoCD-created namespace
bypasses the PSA labelling layer.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct completeness
check (PSA namespace-label coverage, cross-referenced against ADR-0017's own
table rather than assumed) that came back clean. The run continues to the
next cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
