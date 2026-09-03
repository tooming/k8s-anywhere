# Restore the silently-dropped `verify-rejection` CI job (O4 gate) + mechanical recurrence guard

Issue #1229 (`[Action required] Set the KUBECONFIG Forgejo Actions secret for
the O4 CI rejection-gate job`) turned up a deeper problem than a missing
secret while investigating it live: the `verify-rejection` job itself had
been **silently dropped in its entirety**. It was added 2026-08-17 (#1224),
then removed with no corresponding deletion commit during a later rewrite
(#1238, 2026-08-18) — `git show` on that commit shows a clean
`-  verify-rejection:` with no re-add anywhere else in the diff. No test
pinned the job's presence, so nothing caught the drop — the same failure
class this workflow file's own `retry_cmd` history had already hit once
(documented in the file's own comments).

Per ROADMAP rule #9's "split the gate" guidance: restoring the job's code and
adding the mechanical recurrence guard is fully clusterless and
executor-buildable. Setting the `KUBECONFIG` secret and watching a real run
complete is not — that stays gated on issue #1229, which remains **open**.

## What changed

- **`.forgejo/workflows/build-sign-push.yml`**: restored the `verify-rejection`
  job (pushes a deliberately unsigned test image, asserts Kyverno's
  `verifyImages` `ClusterPolicy` rejects it at admission), re-adapted to this
  file's post-rewrite conventions rather than pasted back verbatim:
  - Added the "Resolve `$REGISTRY`'s host via `/proc/net/route`" step every
    other job in this file now has (this job predates that fix landing
    elsewhere).
  - Added its own checkout step so it can source the shared
    `scripts/lib/retry_cmd.sh` instead of adding a third hand-copied inline
    copy (the existing two copies already caused one drift bug, PR
    #1276→#1277).
  - Wrapped every network-facing docker command (login, pull, push) in
    `retry_cmd`, matching `build-and-push`'s established convention for the
    same documented Docker Hub/Harbor flakiness.
- **`tests/forgejo-ci.bats`**: restored all 12 of the job's original
  assertions (mechanical recurrence guard against a third silent drop),
  updated one existing assertion's expected count (2→3, for the
  now-three-jobs host-resolution pattern), and added 3 new assertions
  covering the 2026-09-03 adaptations (checkout step, host resolution,
  retry_cmd wrapping).

## Verification

Full local bats run (bats installed via `apt-get` for this cycle, since the
usual clusterless environment doesn't have it): **2970/2970 tests pass**,
including all 41 in `tests/forgejo-ci.bats`. YAML syntax validated directly
(`python3 -c "import yaml; yaml.safe_load(...)"`) — 3 jobs parse cleanly.
`make ci` passes green.

## What this does NOT do

Does not set the `KUBECONFIG` secret and does not trigger or observe a real
run — issue #1229 stays open, unchanged, per ROADMAP rule #11's `[Action
required]` convention (a live-cluster/external-system action only the
maintainer can perform).

## PR

https://github.com/tooming/k8s-anywhere/pull/1402
