# [Action needed] Now/next still gated; steady state re-confirmed, no new intake or maintainer signal

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633).

Re-confirmed this cycle via a full open-issues search (`is:issue is:open`,
not just the standing-issue list): exactly 3 open issues exist in this
repo, all three of the above/#999, no new comment on any since 2026-08-04,
no ungroomed intake. [#980](https://github.com/tooming/k8s-anywhere/pull/980)
(maintainer's own in-progress GitLab-runner PR) is unchanged.

## This run's real deliverables — 12 merged PRs + 1 closed issue

`ack-s3` chart bump, Vault image bump (real CVE fixes), an ADR-0015 audit
(Postgres major-version hold), Inkless-Postgres explicit-pin hygiene, a
stale dashboard-count doc fix, plus honest cycle records at each point a
fresh lens came up clean or too ambiguous to safely act on. Full list in
[#1020](https://github.com/tooming/k8s-anywhere/pull/1020)'s body.

## Assessment

This run has swept every cheap, clusterless verification angle repeatedly
available to it: chart currency, image-tag currency (pinned and floating),
Terraform chart/provider pins, GitHub Actions pins, an ADR major-version
audit, two doc-precision counts, Makefile hygiene, and now a full
open-issue re-scan. All come back to the same steady state: the three
gated Now/next items are blocked on live-cluster facts (a real GitLab CI
pipeline run, a real Kargo promotion) that only the maintainer's own
in-progress work (#980) or a future live-cluster session can supply.
Repeating the identical checks again without a new external signal
(a fresh issue, a #631/#633/#999 comment, #980 merging, a new upstream
release) would not surface anything this pass hasn't already found — the
honest thing is to say so plainly rather than manufacture another
distinct-sounding sweep over the same ground.

## What would unblock further work

(a) a maintainer-confirmation comment on #631, #633, or #999; (b) #980
merging; (c) a new GitHub issue; (d) a new upstream CVE/release firing one
of this repo's tracked flip conditions; (e) simple time passing — today's
clean chart/image currency sweeps are worth re-running on a future cycle,
since "current today" isn't "current forever."

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8
this is not a stopping point — the run continues to the next cycle.
