# [Action needed] Now/next gated again after this run's Harbor cycle; three fresh lenses came up clean

## What's blocked

ROADMAP.md's *Now / next* lane is back to the same 3 unchecked `[ ]` items,
all still gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle (fetched both issues' comment threads directly): both still open, no
new confirmation since the last check.

## What this run already did

Two real merged PRs so far this run:
[#962](https://github.com/tooming/k8s-anywhere/pull/962) (planner: ran the
architect fallback's own weekly upstream-release sweep against all 17
ADR'd-component checklist entries plus Harbor/Garage — 16 of 17 already
current, added the one real delta, a Harbor chart currency bump, as a new
Now/next item) and [#963](https://github.com/tooming/k8s-anywhere/pull/963)
(executor: built that item — Harbor chart `1.19.1` → `1.19.2`, plus a
bonus fix for a pre-existing `docs/dependency-tree.md` inaccuracy about
Harbor's cache found while verifying the bump).

## This cycle's fresh angles (not repeats)

Three lenses not yet used this run, tried back-to-back after the Harbor item
merged and the lane went dry again:

1. **Duplicated-function-across-scripts sweep** (janitor lens) — grepped every
   `scripts/*.sh` for identically-named top-level function definitions
   appearing in more than one file. Found `bad()` still locally defined in
   two files (`mimir-readonly-root-check.sh`, `rollouts-plugin-list-check.sh`)
   — checked both bodies directly: both are informational-only (`printf`
   only, no `drift`-flag variable set), exactly the carve-out this run's own
   earlier `ok-bad-lib-extract` work (issue #957, PRs #959/#960) documented as
   intentionally out of scope. No real gap. (`cleanup`/`g`/`skip` also showed
   >1 file each but are unrelated small per-script helpers, not a shared
   pattern worth centralizing.)
2. **doc-drift-author's own drift signals** — `make ci`'s `readme-check` and
   `lab-ui-check` both reported clean (no drift lines) after this run's Harbor
   PR merged; no `sync/*` work available.
3. **Cross-cutting hardening & quality section re-read** — confirmed every
   item there is either checked or struck-through-and-groomed; the one
   candidate that looked live (Longhorn `1.11.3`→`1.12.0`, spotted during
   this run's architect sweep) turns out to already have a documented
   precedent for exactly this situation: RFC #708's Kafka major-bump "Hold"
   decision explicitly cites "mirrors ADR-0013's Longhorn `1.12.0` hold" —
   i.e. the architect has already, elsewhere, treated a Longhorn `1.12.0`
   bump as a held major-behavior change needing a go/no-go RFC, not a
   mechanical executor pickup. Not a fresh gap; already accounted for.

All three came up genuinely clean — a third consecutive empty pass after
different angles, not a repeat of a prior cycle's search.

## What would unblock further Now/next work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
firing one of the tracked ADR flip conditions; (d) an architect RFC deciding
the Longhorn `1.12.0` go/no-go (if the maintainer wants that pursued now
rather than left held).

This note is this cycle's honest record — the run already shipped 2 real PRs
before reaching it. The run continues to the next cycle per
`executor.prompt.md` STEP 8; this is not a stopping point.
