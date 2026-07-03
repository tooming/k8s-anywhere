# Planner run — 2026-07-03

## Why this run ran as planner

The executor's "Now / next" lane was empty: PR #324 (`auto/gitops-clusterip-bridge`) covers
the first unchecked item; the remaining unchecked items all carry human-confirmation
prerequisites the executor cannot satisfy clusterlessly:

- `verifyImages ClusterPolicy — Audit → Enforce flip` — needs maintainer to confirm a
  `.sig` tag exists in Artifactory after at least one CI build.
- `O4 CI gate — verify-image-rejection job` — blocked on `cosign-enforce-flip` merging.
- `Capstone pipeline re-wire — Artifactory → Harbor registry host` — needs maintainer to
  confirm on issue #297 that the Harbor minimal profile was measured on-cluster and fits
  the 12 GB budget.
- `Decommission Artifactory manifests` — blocked on `harbor-capstone-rewire` + the same
  maintainer gate.

Per WAYS-OF-WORKING.md §2 / the executor system prompt step 6b fallback chain, the
planner's job is to refill the lane so the next executor run has buildable 🟢 work.

## Gaps found

### Gap 1 — Harbor governance LimitRange (O2 + Core Values)

`gitops/platform/governance-appset.yaml` contains an explicit TODO comment:
> "A harbor governance overlay is added once its namespace lands."

The harbor namespace landed in `auto/harbor-application` (already merged). The governance
appset covers all standard-tier namespaces from RFC #294 **except** harbor. This item
closes that gap.

### Gap 2 — O5 dashboard-coverage bats (O5 measurement mechanism)

CHARTER O5 states: *"Measured by: a drift check wired into `make ci`."* The current CI
checks HTTPRoute ↔ stack-health panel sync (`lab-ui-check.sh`) but does NOT verify that
each always-on service app has a `lab-<name>.json` dashboard. This means O5 has no
mechanical measurement for the non-UI components (kyverno, velero, trivy, etc.). The
new bats assertions fill this gap using existing `scripts/test.sh` infrastructure — no
Makefile change needed (🟢 tier).

### Gap 3 — NP bats fan-out for Tier-1 wave overlays (O2 coverage)

Four Tier-1 next-wave namespaces (`kyverno`, `argo-rollouts`, `velero`, `trivy-system`)
have NetworkPolicy overlays but no dedicated `tests/networkpolicy-<ns>.bats` files.
Their NP assertions live in the component bats files, which is partial but not
structured to the per-scope bats pattern that every other namespace follows. O2's
measurement criterion says "per-scope files cover every namespace in gitops/" — this
item adds the four missing files, making O2 mechanically measurable for these namespaces.

Note: waits on PR #324 to merge first (adds the KYVERNO_NP etc. path vars to
`tests/lib/networkpolicy-paths.bash`).

## What needs a human decision (NOT added to ROADMAP — listing here for visibility)

Two human confirmation gates are blocking the O4 + Harbor capstone track:

1. **Cosign `.sig` confirmation**: Maintainer must check that at least one GitLab CI
   run has pushed a `.sig` OCI tag to Artifactory (run
   `curl http://artifactory.127.0.0.1.nip.io:8000/artifactory/docker-local/hello/.sig`
   and confirm HTTP 200). Once confirmed, the executor can pick up `cosign-enforce-flip`
   and `o4-ci-rejection-gate` on the next run.

2. **Harbor budget gate on issue #297**: Maintainer must confirm (comment on issue #297)
   that the Harbor minimal profile was measured on the live cluster and fits within the
   12 GB on-demand budget. Once confirmed, the executor can pick up
   `harbor-capstone-rewire` and `harbor-artifactory-decommission`.

These are 🔴 Red decisions (live-cluster measurement, maintainer discretion) that no
agent can make without cluster access.
