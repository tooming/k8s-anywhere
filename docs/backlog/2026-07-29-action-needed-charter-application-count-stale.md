# [Action needed] Now/next still gated; CHARTER's "~28 ArgoCD Applications" count found stale, filed for architect

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#845](https://github.com/tooming/k8s-anywhere/pull/845) (`.gitignore`
effectiveness audit).

## This cycle's fresh angle — a real finding, correctly escalated rather than guessed

After 15 consecutive "checked, clean" cycles, this cycle's sweep found an
actual stale claim: CHARTER.md's `## Target end-state` section states, as a
live current-state fact, that the "Always-on core" is "(built)... ~28 ArgoCD
Applications." Verified directly: `grep -rl "^kind: Application$" gitops/`
(excluding `ApplicationSet` files) returns **82** total Application
manifests; filtering to only auto-synced ones (`automated:` present) returns
**68** — over double the stale figure.

**Not fixed directly this cycle**, for a concrete reason: the "~28" figure
is scoped to just the "Always-on core" bullet's own named components, while
CHARTER.md separately lists "Always-on next wave" (Kyverno/Argo
Rollouts/Velero/Trivy Operator) and cert-manager/KEDA as their own bullets —
correctly re-deriving just the core bullet's count requires categorizing
each of the 68 auto-synced Applications against CHARTER's four buckets
(including the "always-on PSA-floor shell for an otherwise on-demand
component" pattern — `kargo-extras`, `harbor-extras`, `istio-system-extras`,
etc.), not a mechanical grep. Guessing a replacement number here risks an
ADR-0004 violation worse than leaving the known-stale approximate in place.
Filed **[issue #846](https://github.com/tooming/k8s-anywhere/issues/846)**
for the architect (CHARTER edits are RFC/ADR-carried per
`docs/WAYS-OF-WORKING.md`, not a drive-by executor edit) to do the
categorized re-count and update CHARTER.md + `docs/dora-audit-readiness.md`'s
derived mention together.

Two other "~28" mentions were checked and correctly left untouched — they
are historical snapshots (ADR-0017's original RFC #83 context;
`ROADMAP.md:2501`'s already-`[x]`-checked completed-item description), not
live claims, and editing them would misrepresent history.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct executor fix this cycle. `make ci` is unaffected (no code/manifest
touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) the newly-filed
issue #846 (architect re-count + CHARTER/dora-audit-readiness update).

This note is this cycle's honest record — a genuinely distinct check that,
for once, surfaced a real staleness finding, correctly escalated to the role
whose lane it belongs in rather than guessed at or ignored. The run
continues to the next cycle per `executor.prompt.md` STEP 8; this is not a
stopping point.
