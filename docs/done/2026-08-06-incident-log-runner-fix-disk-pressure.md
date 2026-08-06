# Reconcile `docs/incident-log.md` with the real #631/#633 investigation history + file the missing disk-pressure tracking issue

Third cycle of this run. Now/next's three 🟢 items remain gated on unconfirmed
maintainer-confirmation issues #631/#633 (re-checked this cycle, unchanged).
PLANNER/ARCHITECT fallback passes earlier this run found nothing further to groom
or audit; this cycle's angle (JANITOR-shaped — "stale doc references," CLAUDE.md's
bugfix-prevents-recurrence philosophy applied to a doc-drift gap rather than a code
bug) was reading the full #631/#633 comment history closely enough to compare it
against `docs/incident-log.md`'s own "Real incident history" table.

## What was found

Two real, verifiable gaps:

1. **Stale row.** The `GitLab CI (no runner ever registered)` row was still marked
   `**Unresolved**` / "in progress", but per #631/#633's own 2026-08-05 comments the
   runner fix landed in PR #1026 and was verified live (`GET /runners` shows
   `lab-docker-runner`, `status: online`; a triggered pipeline's `build-and-push`
   job actually executes). The log hadn't been updated to reflect that.
2. **Missing tracking issue.** That same 2026-08-05 comment found a *new*, more
   fundamental P1 blocker — the underlying k3d node under real disk pressure
   (88% overlay filesystem usage, `kubelet` unable to free space, `NodeNotReady`
   flapping 17+ times) — and stated an intent to "file a separate issue... see
   #999." But #999 is a distinct, unrelated issue (ArgoCD image-tag confirmation,
   filed earlier the same day) — no disk-pressure tracking issue was ever actually
   created. This is exactly the kind of finding `docs/incident-log.md` exists to
   capture (Pillar 2, Q6/Q8) and exactly the kind of standing gate ROADMAP rule #11
   uses for a live-cluster fact only a future live session can confirm.

## What changed

- `docs/incident-log.md`: updated the GitLab CI runner row to `Fix: PR #1026`
  with the live verification details; added a new row for the k3d node
  disk-pressure incident (2026-08-05, P1, unresolved), citing the real comment
  history and the untracked-issue gap honestly rather than silently omitting it.
- New GitHub issue [#1034](https://github.com/tooming/k8s-anywhere/issues/1034)
  (`[Action required] Confirm k3d node disk pressure is resolved before retrying
  #631/#633`) — the standing tracking record the 2026-08-05 comment intended but
  never created. Labeled `priority:p1`, `domain:bootstrap`, mirroring #631/#633/#999's
  own labeling.

Behavior-preserving: no code, manifest, test, or ADR content changed — only
`docs/incident-log.md`'s own table content, reconciled against the real GitHub
issue history already on record. `make ci` stays green on the same set of checks.

`docs/decisions/adr-0004-no-fabricated-content.md` compliance: every fact in the
updated rows and the new issue is cited directly against the real #631/#633 comment
history (linked), not invented or assumed.

(chore/incident-log-runner-fix-disk-pressure)

## PR

https://github.com/tooming/k8s-anywhere/pull/1035
