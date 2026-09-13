# [Action needed] Cycle 3 — fallback chain exhausted, ArgoCD full GHSA re-sweep clean

## This run so far

1. Cycle 1 ([#1583](https://github.com/tooming/k8s-anywhere/pull/1583)):
   found the backlog empty; while validating, discovered and fixed a real
   CI break in [#1584](https://github.com/tooming/k8s-anywhere/pull/1584)
   (`tflint`'s upstream `install_linux.sh` convenience script was retired).
2. Cycle 2 ([#1585](https://github.com/tooming/k8s-anywhere/pull/1585)):
   a different set of checks (GitHub Actions pin currency, DORA-audit gap
   re-scan, file-size sweep, markdown links) also came up empty.

## This cycle's checks — two more angles

- **Full ArgoCD GHSA re-sweep** (the register's last full sweep was
  2026-09-03, 10 days old — the longest-since-last-full-sweep of the four
  pinned sources): live-checked `argoproj/argo-cd`'s published advisories
  again, specifically the two dated closest to the last sweep
  (GHSA-h98r-wv3h-fr38, High, XSS; GHSA-rg3g-4rw9-gqrp, Moderate, secret
  extraction via ServerSideDiff). Both fixed at `3.2.12`/`3.3.10`/`3.4.2` —
  the current pin (`appVersion v3.5.2`) is past every floor, consistent
  with the register's existing entry. No new advisory since the last
  sweep.
- **Orphaned remote branches**: `git branch -r` after this run's three
  merges shows zero branches besides `main` — every branch this run
  created was cleanly deleted on merge (`--delete-branch`), and no stale
  branch from an earlier run lingers.

## Assessment

Three independently-different verification passes this run (cycles 1, 2,
3) all confirm the same steady state: the backlog is empty, every pinned
dependency (four version-pinned sources + four GitHub Actions) is current,
no new GHSA applies, governance docs are in sync, and the repo has no
lingering cleanup debt. The one real, substantive finding this run was the
CI break, already fixed and merged.

## What would open new work

- A new GitHub issue (intake) from the maintainer.
- A new upstream release/GHSA against any pinned source.
- A later cycle in this same run, trying yet another lens once real time
  has passed for upstream state to actually change.
