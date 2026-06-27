# Planner run 2026-06-27 — kargo ADR row + governance items

## Trigger

Executor fallback: "Now / next" lane was empty of buildable 🟢 items. The two
remaining unchecked 🟢 items (`auto/pss-np-longhorn` → PR #284,
`auto/pss-np-istio-system` → PR #285) already have open `auto/*` PRs (taken). The
`verifyImages` flip requires maintainer confirmation of a live `.sig` tag in
Artifactory — unverifiable this run. Fallback chain reached PLANNER step.

## Gap analysis

Scanned CHARTER objectives vs. actual repo state:

- **O2 (`kargo` row missing from ADR-0017)**: `gitops/kargo/namespace.yaml` carries
  `enforce: restricted` labels and `gitops/kargo/networkpolicy/` has a full
  default-deny overlay, but `kargo` is absent from the per-namespace profile table
  in `docs/decisions/adr-0017-pod-security-standards-restricted.md`. All other PSA-
  labelled namespaces appear in the table; `kargo` was silently skipped. Groomed
  into a new 🟢 "Now / next" item `auto/adr-0017-kargo-row`.

- **O2 remaining gaps**: `artifactory` (🟡, existing) and `kiali` (🟡, existing)
  still need architect RFCs — unchanged from last run.

- **O5**: Confirmed complete — all auto-synced always-on Applications have a
  `grafana/dashboards/lab-<name>.json`. Cilium is manually-synced (bootstrap
  ordering constraint per its YAML comment) and uses no standard controller-runtime
  metrics endpoint; prior planner already scoped it out of O5.

## Intake grooming — issue #283 "platform of platform"

Issue opened by maintainer 2026-06-26. Four suggestions processed:

1. **`fix/pre-push-fast-ci`**: Maintainer's own in-progress branch — not a ROADMAP
   item (no planner action needed).

2. **`remove-trivy`**: Contradicts ADR-0022 (Trivy Operator as continuous
   scanner — a binding decision) and CHARTER O1 (Trivy Operator is one of the four
   Tier 1 next-wave components; O1 is explicitly measured by Trivy's presence).
   Cannot groom as an executor item without first revising the CHARTER and
   superseding ADR-0022. **Not groomed.** The suggestion and the ADR conflict are
   flagged in the PR body and in the issue comment for the maintainer's attention;
   if the maintainer wants to remove Trivy, the path is: (a) edit CHARTER.md to
   remove Trivy from O1; (b) open an arch/* PR that supersedes ADR-0022; (c) the
   planner will then groom a removal item.

3. **Platform Governance layer**: Groomed into a new 🟡 Cross-cutting item
   `arch/platform-governance`. Architect RFC needed to decide directory layout,
   whether to introduce LimitRanges/ResourceQuotas, and how this interacts with
   ADR-0019.

4. **Namespace Resource Profiles**: Groomed into a new 🟡 Cross-cutting item
   `arch/namespace-resource-profiles`. Depends on Platform Governance RFC. Architect
   RFC needed to decide tier values and enforcement mechanism.

Issue #283 labeled `groomed` and closed.

## What landed in ROADMAP.md

- **"Now / next"**: new `[ ] 🟢` item `auto/adr-0017-kargo-row` (after
  `auto/pss-np-istio-system`).
- **Cross-cutting**: two new `[ ] 🟡` items `arch/platform-governance` and
  `arch/namespace-resource-profiles` (after the `kiali` item).
