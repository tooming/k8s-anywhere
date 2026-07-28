# [Action needed] Now/next still gated; split-the-gate re-verification finds nothing further splittable

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on the standing
maintainer-confirmation issues #631, #632, #633 — re-verified this cycle (5th of this run):
all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles this run)

- PR #823 + #824 — planner gap-analysis fallback: real CHARTER Objective O5 gap-fill
  (Istio ambient mesh observability wiring).
- PR #825 — cycle 3's record (upgrade-drafter + janitor fallbacks clean).
- PR #826 — cycle 4's record (doc-drift-author broken-pointer sweep clean).

## This cycle's fresh angle

ROADMAP.md rule #9 directs trying to **split the gate** on a gated item before falling
back to filler — carve out any part that does not mutate live-synced cluster state from
the part that does. Re-examined all five gated items specifically for an unexplored
splittable slice (not just re-confirming the gate itself, which prior cycles already
did):

- **`verifyImages` Audit→Enforce flip** (#631-gated) — genuinely atomic: the entire item
  is flipping two `ClusterPolicy` enforcement fields. No prep slice exists to carve out.
- **O4 CI gate (`verify-image-rejection` job)** — gated on the flip above merging first,
  not directly on maintainer confirmation; no independent splittable part.
- **Harbor capstone rewire** (#632-gated) — re-verified directly (not assumed) that the
  two prep slices this item's own text claims are "already prepped" actually exist and do
  what they claim: `gitops/secrets/harbor-registry-externalsecret.yaml` exists, its header
  comment explicitly says "Prep-only ... NOT yet referenced by any Deployment/Rollout
  imagePullSecrets" (confirmed true — grepped `gitops/apps/capstone/` and no
  `imagePullSecrets: harbor-registry` reference exists yet), and
  `docs/done/2026-07-16-harbor-kargo-egress-prep.md` records the Kargo egress
  NetworkPolicy widen. Both real, both correctly scoped as non-mutating prep. No further
  slice remains — everything left is the live-state cutover itself (Warehouse `repoURL`,
  image refs, imagePullSecrets wiring), which is exactly what stays gated.
- **Decommission Artifactory manifests** — depends on the Harbor rewire above merging
  first; no independent splittable part until that lands.
- **Remove legacy capstone Deployment** (#633-gated) — genuinely atomic: the entire
  point is confirming live evidence that the Rollout is safe to rely on before deleting
  the Deployment rollback target. No non-mutating slice exists to carve out early — any
  partial deletion would itself be the gated action.

No further split-the-gate work survives scrutiny this cycle.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream CVE/release
firing a tracked ADR flip condition; (c) a new GitHub issue of any size to groom.

This is this cycle's honest record, following three real merged deliverables earlier this
run (PR #823/#824's feature work, plus cycles 3-4's own evidenced records) — not a
substitute for shipping work. The run continues to the next cycle per
`executor.prompt.md` STEP 8.
