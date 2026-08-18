# [Action needed] Now/next still gated; six real PRs shipped this run, kro OCI probe inconclusive

**Date:** 2026-08-18
**Cycle:** 6th cycle this run (after PR #1214 `upgrade/s3manager-digest-to-v0-8-0`,
PR #1215 `chore/bats-yq-variant-skip-guard`, PR #1216 (a prior cycle's honest
record), PR #1217 `auto/inkless-latest-tag-pin-kyverno-exclusion-removal`, PR #1218
and PR #1219 (both small backfill/sync fixes), all merged)

## What's blocked

Unchanged: the two GitLab→Forgejo migration items remain sequentially blocked on
each other, and `verifyImages` Enforce flip / O4 CI gate / legacy capstone
`Deployment` removal remain gated on
[#631](https://github.com/tooming/k8s-anywhere/issues/631)/
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — both re-checked this
cycle, unchanged since 2026-08-17 18:49/18:50 UTC.

## What was tried this cycle

Re-ran PLANNER/ARCHITECT/DOC-DRIFT-AUTHOR/TRIAGER fresh — all found nothing new
(same state as every prior cycle this run: zero ungroomed issues, zero un-RFC'd 🟡
items, no doc drift, both open issues already fully labeled). UPGRADE-DRAFTER's
one-PR-per-run cap was spent early this run (#1214).

This cycle's fresh angle: having found real work in the last cycle by reading
`gitops/kyverno/policies/disallow-latest-tag.yaml`'s own flip conditions (closed
the `inkless` carve-out, PR #1217), tried the same "OCI-registry chart currency"
angle that worked earlier this run for the `kargo` chart (`ghcr.io/akuity/
kargo-charts` — confirmed current at `1.11.1` via a full, un-paginated
`ghcr.io/v2/.../tags/list` fetch) against the `kro` chart
(`ghcr.io/kro-run/kro`, pinned `0.9.3`).

**Inconclusive, not actioned (ADR-0004 — don't assert without solid verification).**
An anonymous-token fetch of `ghcr.io/v2/kro-run/kro/kro/tags/list` returned only 8
tags topping at `0.4.1` — inconsistent with the live pin (`0.9.3`, presumably
correct since ArgoCD would otherwise be unable to render this always-synced-at-
startup Application). A direct manifest HEAD for `0.9.3` at that exact path
404'd. `scripts/helm-chart-pin-check.sh` (run directly, with the real
mikefarah/yq + helm this session has installed) explicitly labels its own probe
of this exact source "anonymous version probe unreliable, skipped" — the same
documented ceiling this script's header comment already names for every
OCI-sourced chart (`kargo`, `envoy-gateway`, `ack-s3`, `kro`): "anonymous pulls
403 on ghcr/ecr/docker.io, so existence can't be probed." The `kargo` check
earlier this run happening to return a clean, complete-looking answer was not
proof the method is reliable for every OCI source — GHCR's anonymous-pull
behavior appears to vary per-package (rate limits, partial catalog visibility,
or something else this session can't diagnose from outside). Recording this
finding rather than guessing at (or worse, "fixing") a pin this session cannot
actually verify is wrong.

**Not a real gap, just a probe limitation:** nothing suggests `kro`'s pin is
actually stale — the live Application syncs (or would fail loudly and visibly if
it couldn't), and `helm-chart-pin-check.sh`'s own documented skip is working as
designed, not silently swallowing a real drift.

## Why this is the honest deliverable

Six real PRs already shipped this run before this cycle. This cycle's honest
outcome is a specific, concrete finding (a probe limitation, not a repo bug)
recorded rather than acted on without adequate verification. Going straight back
to STEP 1 — this is not a stopping point.
