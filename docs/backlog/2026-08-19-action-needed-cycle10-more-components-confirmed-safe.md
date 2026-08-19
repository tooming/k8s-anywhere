# [Action needed] Now/next still gated; more components confirmed safe, JANITOR sweep clean (cycle 10)

**Date:** 2026-08-19
**Cycle:** 10th cycle this run

## What was tried this cycle

Continued the direct security-advisory-page sweep (cycle 9's method) against
two more always-on components, plus a fresh JANITOR-lens structural check:

- **Valkey** (`8.1.9-alpine` pin) — checked the two newest advisories
  (GHSA-mvcj-73cw-22m4, GHSA-53mc-f3m3-99vh, both High, published
  2026-07-22): both affect `≤8.1.8` and are patched at exactly `8.1.9` —
  the current pin already carries the fix (matches
  `docs/dependency-register.md`'s existing 2026-08-17 note; this cycle
  independently re-verified the version-range claim rather than trusting it
  secondhand).
- **Harbor** (on-demand, chart `1.19.2`) — 10 advisories total, none above
  High severity and the two High ones date to 2022/2023, long predating the
  current pin. Nothing recent or unaddressed.
- **JANITOR structural sweep** — re-checked for oversized scripts/bats files
  and scripts with no bats coverage: largest script is still 282 lines
  (`scripts/probe-timeout-check.sh`), largest bats file still 576 lines
  (`tests/observability.bats`), both within this repo's established
  freeze-and-split convention. Every `scripts/*.sh` file has at least one
  reference in `tests/*.bats`. Unchanged from cycle 1's identical check
  earlier this run — no new drift.

## What's blocked

Unchanged: the "Now / next" lane holds the same three items (two
GitLab→Forgejo migration items un-picked-up per their own investigation
notes; capstone `Deployment` removal gated on issue #633, re-checked —
still 2026-08-17T18:50:01Z, no new confirmation).

## Why this is the honest deliverable

Two more real security checks and a structural re-sweep, all confirming the
lab's current state is safe/current rather than turning up a new gap. No
code shipped this cycle. Not a stopping point — the run continues from
STEP 1.
