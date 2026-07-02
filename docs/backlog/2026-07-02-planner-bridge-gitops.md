# Planner run — 2026-07-02 — ClusterIP bridge GitOps gap

## What triggered this run

The executor's "Now / next" lane was starved:
- `verifyImages ClusterPolicy — Audit → Enforce flip` — blocked on maintainer confirming a `.sig` tag in Artifactory
- `O4 CI gate — verify-image-rejection` — blocked on the enforce-flip merging
- `Lab — Harbor OCI registry dashboard` — already in open PR #316
- `Lab — Kargo promotion-pipeline dashboard` — already in open PR #317
- `Capstone pipeline re-wire — Artifactory → Harbor` — blocked on maintainer confirming Harbor budget on #297
- `Decommission Artifactory manifests` — blocked on the re-wire merging

The fallback chain reached the planner role with a starved lane.

## Intake groomed

### Issue #315 — GitOps drift: zz-dns-clusterip-bridge out-of-band in 15+ namespaces

**Decision:** groomable as 🟢 Green without an architect RFC. The harbor PR
(`auto/harbor-application`) already established the implementation shape —
`allow-harbor-clusterip-egress.yaml` is the exact body to promote to a shared template.
Bringing existing live state under GitOps is a Core Values §"Everything as code"
compliance item, not a new policy design decision.

**Groomed into:** one ROADMAP item `auto/gitops-clusterip-bridge`, added as the
topmost unchecked item in Now/next (before the blocked verifyImages item) so the
executor picks it up on the next run.

**Issue closed:** #315 (this run closes and labels it `groomed`).

## Gap analysis results

- O1 (Tier 1 next-wave): complete — all four components (Kyverno, Argo Rollouts, Velero,
  Trivy) are checked [x].
- O2 (default-deny + PSS everywhere): nearly complete; the ClusterIP bridge gap (#315)
  is the last significant out-of-band state; the bridge item above closes it.
- O3 (stateful DR): scripts done, waiting on a live cluster drill by the maintainer.
- O4 (image signing): blocked on maintainer confirming the first signed image in Artifactory.
- O5 (dashboards): being completed in open PRs #316 (harbor) and #317 (kargo).
- O6 (capstone demo): capstone-demo.sh is merged; waiting on live demo by maintainer.

## Lane health after this plan PR merges

One immediately-buildable 🟢 item at the top of Now/next: `auto/gitops-clusterip-bridge`.
The remaining unchecked items are either blocked on maintainer confirmation or in open PRs.
