# Kargo cross-file version drift fix + mechanical guard extension

(CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded cleanup
2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, this run's 12th
cycle, after the Now/next lane was re-confirmed fully gated. **No prerequisites —
executor may pick up immediately.**)

## What was wrong

PR #1101 (2026-08-11) bumped `gitops/platform/kargo.yaml`'s live `targetRevision`
from `1.11.0` to `1.11.1` (a real, verified routine currency bump — no CVE, nine
backported upstream fixes) but did not update three places that documented the
pre-bump `1.11.0` state, so they silently went stale the moment the live pin moved:

1. **`gitops/platform/kargo.yaml`'s own header-comment bump-history log** — every
   prior Kargo bump (1.2.3→1.6.4, 1.6.4→1.10.9, 1.10.9→1.11.0) has a dated log entry
   there; the 1.11.0→1.11.1 bump did not get one, breaking the file's own
   self-documentation convention.
2. **ADR-0023's Decision section `Version:` line and Re-evaluation log** — still
   said `1.11.0`, no dated log entry for the 1.11.1 bump.
3. **`docs/dependency-register.md`'s Kargo row** — still cited the `2026-07-25
   (chart bumped 1.10.9 → 1.11.0)` note.

Found by an Explore sub-agent cross-referencing `docs/dependency-register.md`'s
version claims against the live gitops manifests (a check distinct from cycle 9's
ADR-re-evaluation-log *date* cross-reference — this one compares actual version
numbers) — the same class of bug PR #1139 fixed for three other rows, but this time
on the *live gitops pin* side rather than the ADR's own log.

## Fix

- Added the missing 2026-08-11/#1101 bump-log entry to `gitops/platform/kargo.yaml`'s
  header comment, mirroring the format of every prior entry (real verification
  details from the original commit, not re-derived or guessed).
- Added a matching dated Re-evaluation log entry to ADR-0023, and updated its
  Decision section to state the live `1.11.1` pin.
- Updated `docs/dependency-register.md`'s Kargo row to the new date/version.

## Mechanical guard (this bugfix's second deliverable)

`scripts/adr-chart-version-sync-check.sh` already exists precisely to make this
class of drift impossible for ADRs using its "self-tracking" `**Chart:** ... pin
lives in ... targetRevision` phrasing (ADR-0020, ADR-0021) — but its own header
comment explicitly *excluded* ADR-0023, because ADR-0023 used a different,
non-machine-checked phrasing (`**Chart:**`/`**Version:**` as two separate bullets).
That's exactly why this drift went undetected by CI for a full day.

Rather than special-case ADR-0023 in the shared script (which has its own bats
fixture coverage and no ADR-0023-specific logic to add), migrated ADR-0023's
"Chart + version" section to the same self-tracking phrasing ADR-0020/0021 already
use — Kargo genuinely ships app+chart from one `Chart.yaml` per release tag (no
separate appVersion line, confirmed in PR #1101's own verification), so citing
`` `appVersion: 1.11.1` `` alongside the chart version is accurate, not fabricated.
Re-ran `adr-chart-version-sync-check.sh` against the real repo and confirmed it now
picks up ADR-0023 automatically (the script is explicitly designed as
"self-maintaining — no hardcoded list — as new ADRs adopt the same convention"; zero
script-logic changes were needed). Updated the script's own header comment (it
named ADR-0023 as a non-self-tracking example) and extended
`tests/drift-adr-sync-checks.bats`'s real-repo assertion to also require
`adr-0023` in the passing output, so a future regression (ADR-0023 reverting to the
unchecked phrasing) fails the recurrence-guard's own test suite.

This is "make the bug impossible by construction" (CLAUDE.md's bugfix hierarchy,
option (a)) rather than a new detect-only gate — the next Kargo chart bump that
forgets to update ADR-0023 will now fail `make adr-chart-version-sync-check`
(wired into `make ci`'s `drift` gates) exactly like an ADR-0020/0021 regression
already would.

## ADR-0004 caveat

All version/date claims re-added were taken directly from the real PR #1101 commit
message (`git show 787f379`) and the live `gitops/platform/kargo.yaml` file — not
re-derived, assumed, or guessed.

## Rollback path

Revert this commit. No other file depends on ADR-0023's Chart + version phrasing
format; the guard-script/bats changes are additive and independently revertible.

## PR

https://github.com/tooming/k8s-anywhere/pull/1142
