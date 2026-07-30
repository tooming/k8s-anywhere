# [Action needed] Now/next still gated; GitHub Actions security-hardening sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items, all gated on standing maintainer-confirmation issues [#631](https://github.com/tooming/k8s-anywhere/issues/631) and [#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-checked this cycle, no new confirmation.

## What this run already did

Eight real merged PRs this run (#918 architect ADR-0014 audit + RFC #917, #919 planner absorption, #920 Cilium `1.18.12` bump, #922 chart-pin sweep, #923 janitor `stale-prs-check` guard, #924 image-pin sweep, #925 ADR flip-condition sweep), plus three stale-PR recoveries (#914/#915/#921).

## This cycle's fresh angle (clean)

Per ROADMAP rule #9's coverage/hardening-sweep filler category, checked all six `.github/workflows/*.yml` files for two concrete security gaps:

1. **Least-privilege `permissions:` blocks.** Every workflow already has an explicit top-level `permissions:` block (none rely on the broad default): `auto-update-prs.yml` (`contents: write`, `pull-requests: read`), `ci.yml`/`oracle-cluster-apply-retry.yml`/`oracle-cluster-apply.yml`/`pr-up-to-date.yml` (`contents: read`), `delete-closed-pr-branch.yml` (`contents: write`) — all scoped to exactly what each workflow does.
2. **SHA-pinned actions (RFC #611 follow-through).** Grepped every `uses:` line across all six workflows for a non-SHA reference (a floating tag/branch). Zero found — every third-party action is pinned to a full commit SHA.

Both checks came back clean — this closes out the GitHub Actions security-hardening angle alongside this run's now-complete sweep of: architect-tracked components (#918), chart pins (#922), image pins (#924), and ADR flip conditions (#925).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release firing a tracked ADR flip condition.

This note is this cycle's honest record. The run continues to the next cycle per `executor.prompt.md` STEP 8; this is not a stopping point.
