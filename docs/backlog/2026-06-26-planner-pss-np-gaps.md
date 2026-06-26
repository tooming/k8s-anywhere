# Planner run 2026-06-26 — O2 fan-out gaps: on-demand namespace PSS + NP

**Run date:** 2026-06-26  
**Produced by:** executor fallback to planner role (Now / next lane empty: only
`auto/cosign-enforce-flip` unchecked and blocked on maintainer confirmation; two
other open items already in PRs #273 + #274).

## What was done this run

No open GitHub issues (intake queue empty). No pending architect items in
`docs/roadmap/incoming/`. Gap analysis against CHARTER + repo state produced five
new ROADMAP items.

## Gap analysis findings

**O2 status (default-deny + PSS-restricted everywhere, due 2026-09-30):**  
All 20 namespaces with `namespace.yaml` files have PSA labels. However, two
on-demand namespaces already catalogued in ADR-0017 as `privileged` are missing
their `namespace.yaml` and NetworkPolicy overlays:

- `longhorn-system` — ADR-0017 says `privileged` (ADR-0013); no
  `gitops/longhorn/namespace.yaml` exists.
- `istio-system` — ADR-0017 says `privileged` (ADR-0012); no
  `gitops/istio-system/namespace.yaml` exists.

Two further on-demand namespaces have no PSA profile row in ADR-0017 at all:

- `artifactory` — no `namespace.yaml`, no NP overlay, no ADR-0017 row. PSA
  level not yet decided → 🟡 (needs architect RFC to audit Artifactory chart
  securityContext).
- `kiali` — same situation. PSA level not yet decided → 🟡.

**O4 status (every image signed + verified, due 2026-12-31):**  
CHARTER O4 completion requires "a CI step that pushes an unsigned image and asserts
Kyverno rejection." This does not exist; the existing cross-cutting prose note was
promoted to a formal `- [ ] 🟡` item so the architect has an actionable target.
Prerequisite: `auto/cosign-enforce-flip` must merge first.

## Items added to ROADMAP.md

**Added to "Now / next" (🟢 — executor-ready once prior PRs merge):**

1. `auto/pss-np-longhorn` — PSS privileged + NP for `longhorn-system` (ADR-0017
   profile already decided; straightforward namespace.yaml + extras Application +
   NP overlay + appset entry + bats).

2. `auto/pss-np-istio-system` — PSS privileged + NP for `istio-system` (ADR-0017
   profile already decided; same pattern).

**Added to "Cross-cutting" (🟡 — architect RFC needed):**

3. `O4 completion gate — CI rejection test for unsigned images` (formalised from
   existing prose note; architect must decide CI job shape + unsigned-image source +
   rejection-assertion method).

4. `PSS profile decision + NP spec — artifactory namespace` (architect must audit
   chart securityContext and spec NP allow-list before executor can build).

5. `PSS profile decision + NP spec — kiali namespace` (same; architect must confirm
   PSA level and spec NP allow-list).

## What was NOT changed

- CHARTER.md (goals unchanged — O2 deadline 2026-09-30 is still achievable).
- ADRs (decisions unchanged; ADR-0017 profile edits belong in the executor items
  that implement namespace.yaml, not in this plan PR).
- Any feature code or manifests.
