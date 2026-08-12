# dependency-register.md log-drift fix — three stale "Last reviewed" citations

(CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded cleanup
2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, this run's 9th
cycle, after the Now/next lane was re-confirmed fully gated and the planner,
architect, and doc-drift fallback roles all found nothing new this pass. **No
prerequisites — executor may pick up immediately.**)

`docs/dependency-register.md`'s own "Keeping this in sync" section already names the
exact failure mode this item closes: "this file's 'Last reviewed' column should be
updated in the same PR when it touches a row here, but nothing currently fails
`make ci` if it drifts." Wrote a small script cross-referencing every register row's
cited "Last reviewed" date against its linked ADR's own `## Re-evaluation log`
section, looking for any ADR whose latest dated entry postdates the register's row —
found three real, substantive mismatches (not false positives — verified each by
reading the actual ADR entry, ADR-0004):

- **Aiven Inkless** (ADR-0015): register cited `2026-07-24`, but the ADR's own log
  has a `2026-08-05` entry (holding the `postgres` batch-coordinator image at the
  `17.x` line, issue #1013) that the register never picked up.
- **Kyverno** (ADR-0019): register cited `2026-07-29`, but the ADR's own log has a
  `2026-08-06` entry (the `disallow-latest-tag` `argocd` carve-out's flip condition
  fired and the exclusion was removed, issue #999/PR #1037) that the register never
  picked up.
- **Argo Rollouts** (ADR-0020): register cited `2026-07-20`, but the ADR's own log
  has a `2026-08-06` entry (a real bugfix — the `success-rate` AnalysisTemplate's
  missing `count` field was crashlooping the controller, 145 restarts over 45 hours)
  that the register never picked up.

Updated all three rows to cite their real latest re-evaluation entry, matching the
same "date (one-line summary)" format every other row already uses. No other rows
had this drift — every other ADR's latest log entry date is at or before its
register row's cited date (checked programmatically across all 35 rows/ADRs, not
spot-checked).

This is a small, bounded, behavior-preserving fix (documentation only, no code/GitOps
surface touched) — exactly the "stale doc reference" class of cleanup
`routines/janitor.prompt.md` STEP 3 names as its third-priority target, picked up
here because no higher-priority footgun/duplication candidate was found this cycle.

## ADR-0004 caveat

This is documentation-only, clusterless work. Every date cited was read directly
from the ADR's own `## Re-evaluation log` section, not assumed or guessed.

## Rollback path

Revert the three row edits in `docs/dependency-register.md`. No other file depends
on this register.

## PR

https://github.com/tooming/k8s-anywhere/pull/1139
