# [Action needed] Now/next still gated; janitor monolith-recurrence check clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles today)

PR #769, #771, #775, #777, #779, #780, #782 (CVE/currency sweep across
every actively version-pinned ADR + KRO/TiDB Operator/`ack-s3`; PR #782 also
filed issue #781, a genuinely new argo-cd chart major-version-line finding).

## This cycle's fresh angle

Tried the **JANITOR** lens directly, with a different technique than the
prior janitor-check notes (`2026-07-26-action-needed-cycle6-janitor-*.md`,
`2026-07-27-action-needed-lgtmp-sweep-janitor-check.md`), which looked for
duplication and dead code by inspection. This cycle instead measured **how
many distinct commits have ever touched each `tests/*.bats` file** — a
mechanical proxy for "is this file a shared monolith multiple PRs keep
appending to" (the exact footgun class the `drift-detectors.bats` /
`securitycontext.bats` / `networkpolicy.bats` / `observability.bats` freeze
guards were built for):

- Every already-frozen monolith (`securitycontext.bats`, `networkpolicy.bats`,
  `observability.bats`, `drift-detectors.bats`) is correctly frozen — `make
  ci` enforces this and passed.
- No *other* `tests/*.bats` file shows a repeated-append pattern: the
  highest touch-counts among non-frozen files are `governance.bats` (3),
  `kyverno.bats` and `argocd-resources.bats` (2 each) — nowhere near the
  scale that justified freezing the four monoliths above, and each edit
  looks like a normal incremental extension, not runaway growth.
- Checked `scripts/*.sh` for size/duplication too: the largest scripts
  (`dora-metrics.sh` 192 lines, `garage-bootstrap.sh` 191, `rebase-open-prs.sh`
  170) are each single-purpose, not copy-pasted variants of each other.
- `tests/hook-scripts-coverage.bats` (495 lines, the largest non-frozen bats
  file) has been touched by exactly one commit ever — a large file, but
  single-origin, not an actively-appended-to monolith. Not yet the footgun
  class rule #10's freeze pattern targets; flagging here as a watch item,
  not acting on it (freezing pre-emptively, with no second PR having ever
  touched it, would be manufactured process for a problem that hasn't
  actually recurred).

No bounded, real, behavior-preserving cleanup qualified this cycle per the
janitor routine's own STEP 3 priority order (footgun-that-already-bit-us >
duplication > dead/stale matter) — the first and most valuable category is
already comprehensively addressed in this repo.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) an architect
decision on the new argo-cd chart major-line issue (#781); (c) a new
upstream CVE/release firing a tracked ADR flip condition; (d) a new GitHub
issue of any size; (e) `tests/hook-scripts-coverage.bats` crossing a second
PR's edit, at which point the freeze-and-split pattern becomes worth
applying to it too.

This note is this cycle's honest record — a distinct, mechanical
monolith-recurrence check, not a repeat of the two prior janitor-lens
notes' inspection technique — not a stopping point. The run continues to
the next cycle per `executor.prompt.md` STEP 8.
