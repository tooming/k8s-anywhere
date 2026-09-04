# De-duplicate the frozen-monolith test-drift check/hook scripts

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's mechanical-
guard-over-skills principle. Janitor fallback cleanup (`executor.prompt.md`
STEP 6b) after the "Now / next" lane came up fully gated this run: all three
unblocked/blockable items (`auto/cosign-enforce-flip`,
`auto/o4-ci-rejection-gate`, `auto/capstone-deployment-removal`) are still
waiting on the standing maintainer-confirmation issues #631/#633 (checked
directly this run — both re-confirmed "still outstanding" as of their latest
2026-07-29 comments), and the remaining two "Now / next" items
(`auto/harbor-capstone-rewire`, `auto/harbor-artifactory-decommission`) are
already covered by open PR #885. A planner-lens pass found no ungroomed
issues, no un-RFC'd 🟡 items, and nothing new to promote — the backlog has
already been swept from dozens of angles today (43+ prior `[Action needed]`
audits on 2026-07-29 alone), so this run looked for a genuine cleanup instead
of filing yet another audit note.

## The footgun

Four of this repo's five "frozen monolith" bats-drift guards —
`scripts/securitycontext-tests-check.sh`, `scripts/observability-tests-check.sh`,
`scripts/drift-detectors-tests-check.sh`, and
`scripts/hook-scripts-coverage-tests-check.sh` (plus their four
`*-tests-sync-hook.sh` PostToolUse companions) — were independently
copy-pasted from each other every time a new monolith got frozen. Diffing them
confirmed each pair was ~90% byte-identical, differing only in the bats file
path, snapshot path, `*_TESTS_ROOT` env var name, and a few words of
diagnostic text. This is the same "duplicated guard implementation" shape
`scripts/lib/colors.sh` and `scripts/lib/hook-payload.sh` were already
extracted to fix (their own header comments record: "Duplicated identically
across 15+ scripts ... before this extraction; consolidated so a future
[change] only needs one edit") — the four `-tests-check.sh` /
`-tests-sync-hook.sh` pairs never got the same treatment, so the next monolith
to freeze (there have been five since #238/#239 first forced this pattern)
would mean copy-pasting another ~70 lines instead of writing a 5-line wrapper.

## The fix

Two new shared library files (sourced, not executed — mirroring
`scripts/lib/colors.sh` / `scripts/lib/hook-payload.sh`):

- `scripts/lib/frozen-monolith-check.sh` — `frozen_monolith_check()`, the
  snapshot-diff logic shared by all four CI-side check scripts.
- `scripts/lib/frozen-monolith-sync-hook.sh` — `frozen_monolith_sync_hook()`,
  the shared PostToolUse-hook logic (file-path filter + delegate-to-check +
  diagnostic message).

Each of the eight `scripts/<scope>-tests-check.sh` /
`scripts/<scope>-tests-sync-hook.sh` files is now a thin wrapper (its own
header comment preserved verbatim) that sources the shared lib and calls the
function with its own file/snapshot/label. `tests/networkpolicy.bats`'s guard
(`scripts/networkpolicy-tests-check.sh`) is structurally different — a
content-pattern guard, not a snapshot diff — and was left untouched rather
than forced into a shape that doesn't fit it.

**Behavior-preserving:** every `make <scope>-tests-check` / PostToolUse hook
keeps the same exit codes (0 clean / 1 or 2 drift) and every message still
contains the literal substrings the existing bats coverage
(`tests/drift-frozen-monolith-checks.bats`, `tests/drift-detectors.bats`,
`tests/hook-scripts-coverage.bats`, `tests/hook-scripts-coverage-guard.bats`)
asserts on (`FROZEN`, `namespace overlay`). No `@test` was added, moved, or
renamed; no Makefile target changed (`make <scope>-tests-check`/`-mark` still
just shell out to the same script paths). Verified directly: all four
refactored check scripts pass against the real repo state, `shellcheck -S
warning scripts/*.sh` is clean, and the full targeted bats coverage for these
scripts is green (the only bats failures in a full local run —
`argocd-crd-ssa-sync-hook`, `helm-chart-pin-sync-hook`,
`rollouts-plugin-list-sync-hook`'s "drift" cases — are pre-existing,
network-dependent, and reproduce identically on unmodified `main`; confirmed
via `git stash` before/after).

## PR

https://github.com/tooming/k8s-anywhere/pull/886
