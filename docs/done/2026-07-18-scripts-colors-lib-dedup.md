# chore: extract shared ANSI color setup into `scripts/lib/colors.sh`

Janitor sweep (executor STEP 6b fallback — the "Now / next" lane was gated again
this cycle, and a fresh CVE/compatibility sweep across the remaining unchecked
on-demand components — KEDA's ScaledObject/TriggerAuthentication, GitLab CI,
`docs/DR.md` vs `scripts/dr-restore.sh`, Trivy Operator chart currency — came back
clean, so this cycle's deliverable is a bounded codebase-health cleanup instead).

## The duplication

15 scripts under `scripts/` each independently declared the identical (or a
same-behavior subset) one-liner:

```sh
if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'; else G=; R=; Y=; B=; Z=; fi
```

(`argocd-crd-ssa-check.sh`, `ci-parity-check.sh`, `dr-bluegreen-promote.sh`,
`dr-bluegreen.sh`, `dr-test.sh`, `dr-verify.sh`, `helm-chart-pin-check.sh`,
`lab-health-check.sh`, `lint.sh`, `markdown-links-check.sh`,
`mimir-readonly-root-check.sh`, `rollouts-plugin-list-check.sh`,
`validate-kustomize.sh`, `validate-manifests.sh`, `validate-terraform.sh`) — a
future style tweak (e.g. adding a color, changing the TTY-detection logic) would
have required 15 synchronized edits, with a high chance of drifting subtly out of
sync (as this sweep found: 3 different variants already existed — full 5-variable,
a 4-variable subset without `Y`, and a minimal 3-variable subset without `Y`/`B`).

## The fix

1. Added `scripts/lib/colors.sh` — the canonical, full 5-variable version (safe
   for every caller: an unused shell variable has no effect, so scripts that only
   ever reference a subset of `G`/`R`/`Y`/`B`/`Z` are unaffected by the other
   variables also being set).
2. Replaced each of the 15 scripts' inline color-setup line with
   `source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"` — resolves relative to
   the sourcing script's own location regardless of the caller's cwd, matching
   this repo's existing `ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`
   idiom used throughout `scripts/`.
3. Each script's own `ok()`/`bad()`/`skip()`/`note()` function definitions (which
   have legitimate per-script variance — some set `rc=1`/`FAILED=1` as a side
   effect, some don't) were left untouched — only the byte-identical color-variable
   setup was extracted, not the divergent per-script logic layered on top of it.

## Behavior preservation

Verified with `shellcheck`/`yamllint`/`bats` all actually installed this session
(not skipped locally) — `make ci` fully green, zero new failures, zero new
shellcheck findings (the dynamic `source` is SC1091-info-level, below this repo's
`warning` severity gate). Spot-ran `scripts/lint.sh` and
`scripts/helm-chart-pin-check.sh` directly to confirm colored/plain output is
unchanged.

## Recurrence guard

Added `tests/colors-lib.bats`: asserts `scripts/lib/colors.sh` exists and defines
all five variables, and — the actual guard — asserts no script under `scripts/`
re-inlines the `if [ -t 1 ]; then G=...` pattern (only `colors.sh` itself may
contain it). Verified the guard is real by temporarily reverting one script's
`source` line back to the inline pattern and confirming the test fails, then
restoring and confirming all 5 pass again.

`make ci` passes. This is a pure refactor — no `make ci` check's set of passing
assertions changed beyond the 5 new guard tests.

## PR

https://github.com/tooming/k8s-anywhere/pull/513
