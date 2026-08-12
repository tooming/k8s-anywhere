# Fix stale "unresolved" status for issue #1034 (k3d node disk pressure) in incident-log.md + DR.md runbook

(CHARTER **Core Values** §"Docs & dashboards don't drift" / ADR-0004; JANITOR-fallback
bounded cleanup 2026-08-12, reached via `executor.prompt.md` STEP 6b — the Now/next
lane was re-confirmed fully gated for the eighth cycle running this run. No
prerequisites — executor may pick up immediately.)

## What was wrong

While writing the previous cycle's Harbor pipeline-verification runbook
(`docs/done/2026-08-12-harbor-pipeline-verification-runbook.md`, PR #1168, merged
this same run), I cited issue [#1034](https://github.com/tooming/k8s-anywhere/issues/1034)
as "tracked separately and still open" — taken from `docs/incident-log.md`'s existing
row, which itself said "Unresolved... this log entry will be updated once a live
session confirms the node's disk pressure is resolved." Neither claim was re-verified
against the issue's actual live state before merging.

Checking directly this cycle (not assumed, ADR-0004): issue #1034 is **closed**
(`state_reason: completed`, `closed_at: 2026-08-10T22:46:38Z`). Its three comments
show real resolution work: a stopped-but-not-deleted DR green cluster
(`k8s-lab-green`) was found holding ~10GB of container volumes despite being fully
stopped — deleting it (2026-08-06) dropped node disk usage from 88% to 67%
immediately. A final live check on 2026-08-10 confirmed `DiskPressure: False` and 74%
usage (41G/59G, below the eviction threshold), and the issue was closed on that basis.

This means both `docs/incident-log.md`'s disk-pressure row and my own just-merged
`docs/DR.md` runbook entry were presenting stale, no-longer-true state as current —
exactly the class of drift ADR-0004 exists to prevent. Caught within the same run
that introduced the second instance, before it could mislead a live-cluster session
into treating a resolved issue as a live blocker.

## Fix

- `docs/incident-log.md`: the 2026-08-05 disk-pressure row's Fix/Time-to-resolve/
  Follow-up columns rewritten from "Unresolved" to the real resolution (root cause,
  fix commit-equivalent, and the 2026-08-10 confirmation), citing the issue's own
  three comments.
- `docs/DR.md`'s "Harbor signed-image-pipeline verification" runbook: item 6 and the
  "what's still needed" checklist's step 1 updated from "tracked separately and still
  open, check its status first" to "confirmed resolved 2026-08-10", with a note that a
  quick sanity re-check is still reasonable given time has passed, but it's no longer
  a standing gate.

## Recurrence prevention

This is a documentation-only fix with no mechanical guard to add (there's no `make
ci` check that could verify a GitHub issue's live open/closed state against prose in
a committed doc — that would need live GitHub API access at CI time, which this
repo's clusterless gate doesn't have). The actual prevention is procedural, already
demonstrated by this fix itself: when citing a GitHub issue's status in prose, check
the issue's current state directly (`issue_read`) rather than trusting a second-hand
description in another doc — the same discipline this repo already applies to
live-cluster claims generally (ADR-0004).

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration items;
`verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631; capstone
`Deployment` removal on unconfirmed issue #633) — re-checked directly, both still
open, no new comment since 2026-08-11.

## ADR-0004 caveat

The corrected text is grounded in issue #1034's actual GitHub state and its three
comments, read directly this cycle — not assumed or carried over from the prior
cycle's draft. This remote clusterless session cannot independently re-verify the
node's *current* disk usage today (two days after the 2026-08-10 confirmation); the
runbook's own "worth a quick sanity check" caveat reflects that honestly rather than
asserting current-moment freshness it can't observe.

## Rollback path

Revert this commit — two doc edits (one table row, one runbook subsection), no other
surface affected.

## PR

https://github.com/tooming/k8s-anywhere/pull/1169
