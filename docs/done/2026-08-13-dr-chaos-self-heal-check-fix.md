# Fix `dr-chaos.sh`'s self-heal check — it could report a false-positive instant pass

(CHARTER **Core Values** §"operational-resilience discipline"; JANITOR-fallback
bug found via code-correctness review 2026-08-13, reached via
`executor.prompt.md` STEP 6b — every currency-sweep angle this run had already
tried (dependency-register re-verification, sidecar images, floating tags,
Terraform-bootstrap seam, GitHub Actions pins, deprecated Kubernetes APIs, shell
strict-mode conventions, sync-hook duplication) came up empty this cycle (see
`docs/backlog/2026-08-13-action-needed-post-currency-sweep-fallback-chain-clean.md`).
This cycle's fresh angle: rather than another currency sweep, read
`scripts/dr-chaos.sh` (a relatively new script, added 2026-08-04, one of the
least-scrutinized in the repo) directly for logic correctness rather than
version currency.

## What was wrong

The self-heal poll had two compounding bugs, both of which let the drill report
"self-heal confirmed" almost instantly regardless of whether a real replacement
pod ever actually started:

1. **No exclusion of the deleted pod.** A Kubernetes Pod's `status.phase` stays
   `Running` throughout its `terminationGracePeriodSeconds` window — `kubectl
   get pods`' "Terminating" STATUS column is a client-side rendering based on
   `deletionTimestamp` being set, not a real value of the `phase` field itself.
   The poll's `--field-selector=status.phase=Running` therefore counted the
   just-deleted pod (still terminating) as evidence of a healthy replacement.
   For this drill's single-replica target, `PRE_COUNT=1`, so `READY_COUNT>=1`
   was very likely true on the very first loop iteration — before any
   replacement pod had even been scheduled.
2. **Phase, not readiness.** Even ignoring bug 1, `phase=Running` only means
   the pod has been scheduled and its containers created — it does not mean
   the container has actually passed its readiness gate (or, absent an
   explicit probe, that the container process has actually started serving).
   The check needed the container's real `ready` condition, not just the pod
   phase.

Net effect: this drill — whose entire purpose is to verify Kubernetes/the
Rollout genuinely self-heals — could not actually detect a self-heal failure.
It would report `PASS` in ~0-2 seconds essentially every time, whether or not a
real replacement pod ever came up.

## Fix

Captured the deleted pod's bare name (`OLD_NAME`) before deletion. The
polling `field-selector` now excludes `metadata.name!=${OLD_NAME}` in addition
to `status.phase=Running`, and counts pods via
`.status.containerStatuses[0].ready` (capstone's Rollout runs exactly one
container per pod, confirmed directly against `gitops/apps/capstone/rollout.yaml`)
rather than pod phase alone — so the check now only counts a genuinely new pod
whose container has actually reported ready.

## Mechanical guard (this bugfix's second deliverable)

Added three new `tests/dr-chaos.bats` assertions (clusterless, structural —
grep-based, matching this file's existing style, no live cluster needed):
the field-selector excludes the deleted pod's own name; `OLD_NAME` is captured
from `TARGET` before deletion; the readiness check uses
`containerStatuses[0].ready`, not phase alone. A future edit that reverts any
of these three would fail `make ci`.

## ADR-0004 caveat

This remote clusterless session cannot execute `dr-chaos.sh` against a live
cluster to observe the fixed check actually behave correctly end-to-end — the
fix is verified by direct code reading against documented Kubernetes Pod
lifecycle semantics (phase vs. `deletionTimestamp` vs. container readiness),
not by a live run.

## Rollback path

Revert this commit. The script's behavior when run (which requires a live
cluster and `make dr-chaos`, never invoked from `make up`/`make ci`/`make
dr-test`) is unaffected until the maintainer next runs it — no live-cluster
blast radius from this change alone.

## PR

https://github.com/tooming/k8s-anywhere/pull/1184
