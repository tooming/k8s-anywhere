# Standardize scripts/*.sh's `bad()` failure-flag variable to `drift`

(janitor finding, issue #957 — a duplication sweep found `ok()`/`bad()` printf
helpers redefined inline in ~35 `scripts/*.sh` files, but unlike the `yqs()`
dedup in PR #956 the `bad()` body isn't byte-identical everywhere: it sets a
different failure-flag variable per script — `drift`, `rc`, or `FAILED` — each
read later via that script's own `exit "$<var>"`. **No prerequisites — executor
may pick up immediately.** Pure rename, no logic change: in every
`scripts/*.sh` that defines its own `bad()` setting `rc=1` or `FAILED=1`,
rename that variable (and every read of it, typically just the trailing
`exit "$rc"`/`exit "$FAILED"`) to `drift`, matching the majority convention
already used by most of these scripts. Do NOT touch scripts whose `bad()` sets
no variable at all (informational-only) or extract the shared helper yet —
this item is rename-only prep, split from the extraction to stay within
WAYS-OF-WORKING.md §3's ~400-line PR cap; the follow-up extraction item below
depends on this one merging first. `make ci` must pass (every renamed script's
actual pass/fail behavior is unchanged — verify each one still exits the same
way before/after). `docs/done/` entry required. (auto/scripts-drift-var-rename)

## What was found at pickup time

Re-verified the exact scope directly (not just trusting the RFC/plan PR's
cached count): grep for the three known `bad()` shapes across `scripts/*.sh`
found only **3 files** actually needed renaming — `scripts/lint.sh` and
`scripts/validate-terraform.sh` (both used `rc=1`), and `scripts/dr-verify.sh`
(used `FAILED=1`). The other ~21 files matching the broader "defines its own
`bad()`" count either already used `drift=1` (16 files) or set no variable at
all (5 files, informational-only, correctly left untouched per this item's own
instruction).

## What changed

- `scripts/lint.sh` — `rc=0`/`rc=1`/`$rc` (init, `bad()`'s side effect, the
  final PASS/FAIL check, `exit`) → `drift=0`/`drift=1`/`$drift`.
- `scripts/validate-terraform.sh` — same rename.
- `scripts/dr-verify.sh` — `FAILED=0`/`FAILED=1`/`$FAILED` → `drift=0`/`drift=1`/`$drift`.
- `tests/lint-script.bats` — the one test asserting `lint.sh`'s internal
  variable name (`exit "\$rc"`) updated to assert `exit "\$drift"` instead.

## What didn't change

Pure rename, no logic change: each script's actual pass/fail behavior is
identical before/after — verified `lint.sh` still runs and prints
`lint: PASS` with the same exit code. No other bats test referenced `$FAILED`
or terraform's `$rc` by name (checked directly), so no other test updates were
needed. No topology change, so no README/`docs/dependency-tree.md` update.

## Follow-up

This is prep for the next Now/next item (`auto/ok-bad-lib-extract`), which
extracts the now-consistent `ok()`/`bad()` pair to `scripts/lib/colors.sh` and
adds a recurrence guard — gated on this item having merged first.

`make ci` must pass.

## PR

[#959](https://github.com/tooming/k8s-anywhere/pull/959)
