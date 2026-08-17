# [Action needed] Now/next still gated; noted a minor local-dev-only yq-variant gap in bats tests

**Date:** 2026-08-17
**Cycle:** 8th cycle this run (after PR #1203/#1204/#1206/#1207/#1208/#1209/#1211/#1210,
eight merged PRs total this run, including a real CI-breaking-bug fix in cycle 7)

## What's blocked

The "Now / next" lane holds the same six items as every prior cycle this run — see
PR #1206/#1208/#1210's own records for the full standing detail. No change since the
last check: issues [#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) both unchanged.

## What was tried this cycle

With `bats` actually installed locally this run (first time this session bats wasn't
silently skipped), ran the full local suite (`bash scripts/test.sh`) end-to-end and
diffed the failures against the four already-known, already-explained local-only
`yq`-variant gaps (`helm-chart-pin-check`/`argocd-crd-ssa-check`/
`rollouts-plugin-list-check`, documented in PR #1211). Found four more failures, all
tracing to the same single root cause: `tests/argo-rollouts.bats`,
`tests/kargo.bats` (×3 assertions) call the shared `yqs()` helper with
mikefarah-only filter syntax (`| tag`, `select(...)`  chains) that this sandbox's
installed `yq` (a Python/jq wrapper, not mikefarah/yq) doesn't support the same way.

**Not a real bug, not actioned this cycle:** `scripts/*.sh` already has a mechanical
guard for this exact class (`require_mikefarah_yq`, checked by `make
yq-variant-guard-check`) — but that guard covers check *scripts*, not `tests/*.bats`
files that call `yqs()` directly with mikefarah-only syntax. GitHub Actions CI (the
real gate) always installs the correct mikefarah/yq, so this never fires there —
confirmed by every `unit`/`drift` job passing green on every PR this run. Extending
the guard (or `yqs()` itself) to bats tests would touch a shared helper used across
dozens of test files repo-wide; verifying such a change is *actually* correct would
require testing against **both** yq variants, and this sandbox only has the wrong
one — exactly the kind of change ADR-0004's "verify before asserting" bar says not
to ship blind. Noting it here as a possible future JANITOR candidate rather than
attempting it uninformed.

PLANNER/ARCHITECT/TRIAGER re-checked: no ungroomed issues, no un-RFC'd 🟡 items, both
open issues correctly labeled — unchanged from every prior cycle this run.

## Why this is the honest deliverable

A real (if minor, non-CI-affecting) observation, investigated and correctly not
acted on without the ability to verify a fix's correctness. This cycle's honest
deliverable is this record. Going straight back to STEP 1 per STEP 8 — this is not
a stopping point.
