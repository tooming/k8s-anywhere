# [Action needed] Now/next still gated; shell strict-mode consistency audit clean

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#853](https://github.com/tooming/k8s-anywhere/pull/853) (Grafana
datasource-UID-to-provisioning audit).

## This cycle's fresh angle (with a self-caught false alarm)

Checked whether every `scripts/*.sh` file declares a strict-mode `set -`
directive near its top. First pass (`grep "set -e"` in the first 5 lines)
flagged 76 of 81 scripts as missing one — before writing that up as a
finding, checked a few flagged files directly and found they all declare
`set -uo pipefail` (deliberately **without** `-e`), not `set -e` at all —
the first grep's pattern was simply too narrow, not a real gap.

Re-ran properly: `grep "^set -" scripts/*.sh` — **all 81 scripts** declare
a strict-mode directive, split into two deliberate variants:

- **`set -euo pipefail`** (14 scripts) — exit immediately on any error.
- **`set -uo pipefail`** (67 scripts, deliberately no `-e`) — mostly the
  drift-detector/`*-check.sh` scripts, which need to keep running past an
  individual check's failure to accumulate and report *every* finding
  before exiting non-zero overall, not abort at the first one.

Zero scripts have no strict-mode directive at all. Consistent, disciplined,
intentional split — not a gap.

No bounded, real, behavior-preserving cleanup or upgrade qualified for a
direct fix this cycle. `make ci` is unaffected (no code/manifest touched by
this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — including transparently
correcting its own first-pass false alarm before writing anything wrong
into the record (ADR-0004 discipline applied to the audit process itself,
not just its conclusions). The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
