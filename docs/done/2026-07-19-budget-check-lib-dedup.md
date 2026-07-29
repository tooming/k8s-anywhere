# Extract shared scripts/lib/budget-check.sh from dr-restore.sh + capstone-demo.sh

(CLAUDE.md's mechanical-guard/dedup ethos; janitor fallback role, invoked via
`executor.prompt.md` STEP 6b — the executor's own Now/next lane was fully
gated this run, and the planner/upgrade-drafter/doc-drift-author/triager
fallback roles above janitor in the chain each yielded no real deliverable
this cycle.)

`scripts/dr-restore.sh` (CHARTER Objective O3, < 600 s budget) and
`scripts/capstone-demo.sh` (Objective O6, < 900 s budget) each hand-rolled
near-identical wall-clock budget-check logic: a mid-run "did we blow the
budget" warning (`BUDGET EXCEEDED: ...`) and an end-of-run "Total elapsed ...
OVER BUDGET" report, differing only in the Objective tag (O3 vs O6) and minor
wording. This is the same class of duplication already extracted twice before
in this repo — `scripts/lib/colors.sh` (ANSI color setup, 15+ scripts) and
`scripts/lib/hook-payload.sh` (PostToolUse payload parsing, 15+ hooks) — so
this mirrors that precedent rather than inventing a new pattern.

## What changed

- New `scripts/lib/budget-check.sh`: `budget_warn_if_exceeded <elapsed> <budget> <tag>`
  (mid-run warning, returns 1 if exceeded) and
  `budget_final_line <elapsed> <budget> <tag>` (end-of-run report line, returns
  1 if exceeded). Both take the objective tag as a parameter instead of
  hardcoding "O3"/"O6".
- `scripts/dr-restore.sh` / `scripts/capstone-demo.sh`: source the new lib;
  replaced their inline budget-check blocks with calls to the two functions.
  `capstone-demo.sh`'s existing `budget_check()` wrapper (called at 4 step
  boundaries) now delegates to `budget_warn_if_exceeded` instead of
  reimplementing it — its 4 call sites are unchanged.
- `tests/budget-check-lib.bats` (new): structural + functional coverage for
  the lib, mirroring `tests/colors-lib.bats` / `tests/hook-payload-lib.bats` —
  including a recurrence guard asserting every script that defines
  `BUDGET_S=` also sources `lib/budget-check.sh`.
- `tests/dr-restore.bats` / `tests/capstone-demo.bats`: the "budget exceeded"
  and "total elapsed" structural assertions grepped the script file directly;
  since those literal strings now live in the shared lib, updated them to grep
  `scripts/lib/budget-check.sh` instead, and added a new assertion that each
  script actually sources the lib.

Behavior-preserving: the printf output shape and both scripts' 4/2 call sites
are unchanged; only the "BUDGET EXCEEDED" mid-run message's word order was
minorly normalized to one canonical phrasing (previously "budget (O3)" vs
"(O6 budget)" — an inconsistency, now unified) — the tests only assert the
looser `BUDGET EXCEEDED|OVER BUDGET` pattern, not exact wording, so this is
safe. Verified by installing `bats` in-sandbox and running the full suite:
all budget-check/dr-restore/capstone-demo cases pass; confirmed via `git
stash` that the sandbox's pre-existing 13 unrelated failures (broken local
`yq` binary, no network access — `helm-chart-pin-check`,
`argocd-crd-ssa-check`, `rollouts-plugin-list-check`, and their downstream
tests) are identical before and after this change. `make ci` passes.

## PR

[#602](https://github.com/tooming/k8s-anywhere/pull/602)
