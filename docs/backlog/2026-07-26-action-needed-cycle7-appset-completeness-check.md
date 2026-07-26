# [Action needed] Now/next still gated; ApplicationSet/governance completeness check also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (seventh cycle of 2026-07-26): all three still open, zero comments.

## This cycle's fresh angle

Tried the doc-drift-author role's "broken pointer" check
(`routines/doc-drift-author.prompt.md` STEP 2) from a structural completeness
angle not tried fresh today: verified every `gitPath:` entry in
`networkpolicy-appset.yaml` and `governance-appset.yaml` resolves to a real
directory (all 20 + 23 entries do — no broken pointers), then checked the
*reverse* direction: does every `gitops/*/networkpolicy/` and
`gitops/governance/*/` directory appear in one of the two shared appsets?

Nine `networkpolicy/` directories and one `governance/` entry
(`gitops/governance/base`) initially looked like orphans by that check alone.
**Verified before reporting, per ADR-0004 — both turned out to be false
positives:**

- The nine (`trivy-system`, `argo-rollouts`, `envoy-gateway-system`, `velero`,
  `cert-manager`, `kyverno`, `kargo-project`, `keda`, `kargo`) are each
  registered via their own standalone `gitops/platform/<name>-networkpolicy.yaml`
  `Application` — a different, equally valid registration mechanism than the
  shared appset list-generator, not a gap. Confirmed by grepping for each
  path directly in `gitops/platform/*.yaml`.
- `gitops/governance/base/limitrange-standard.yaml` is a shared kustomize
  base other `gitops/governance/<namespace>/kustomization.yaml` files
  reference via a relative path — it's not meant to be its own top-level
  appset entry, by design.

No real completeness gap found. This is the same discipline this repo's own
history already models (e.g. the "lookalike `alloy-*` tags" and Kiali
red-herring notes in earlier cycles) — a plausible-looking finding that
doesn't survive direct verification isn't reported as a gap.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of any
size.

This note is this cycle's honest record — this run's seventh cycle today
(CVE research ×5, CHARTER re-audit + Actions currency, janitor duplication,
and now appset/governance completeness), all coming up clean after real
verification — not a stopping point. The run continues to the next cycle per
`executor.prompt.md` STEP 8.
