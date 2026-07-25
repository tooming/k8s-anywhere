# Direct bats coverage for scripts/lib/yq-variant.sh's require_mikefarah_yq()

(CLAUDE.md's coverage/hardening sweep — "a script with no bats coverage";
janitor-role finding, 2026-07-25, reached via `executor.prompt.md` STEP 6b's
fallback chain after planner/architect/upgrade-drafter/doc-drift-author all
came up empty this cycle — the "Now / next" lane's five remaining items are
all still gated on standing maintainer-confirmation issues #631/#632/#633,
and no ungroomed issues, pending architect items, or doc drift exist.)

`scripts/lib/yq-variant.sh` defines `require_mikefarah_yq()`, the shared
guard sourced by three CI drift checks — `helm-chart-pin-check.sh`,
`argocd-crd-ssa-check.sh`, and `rollouts-plugin-list-check.sh` — that all
rely on mikefarah/yq-only syntax (`eval-all`, `documentIndex`, `| tag`).
Other `yq` implementations on PATH (e.g. python-yq) don't recognise these
and exit non-zero, which each caller script consumes via `2>/dev/null`
inside a pipe — turning a wrong-variant PATH into a silent "0 matches"
false pass instead of an error. `require_mikefarah_yq()` exists specifically
to make that case loud (hard-fail in CI, skip with a clear message locally).

Verified directly against the repo (not assumed, per ADR-0004): grepping
every `tests/*.bats` file for a direct reference to `yq-variant.sh` or a
call to `require_mikefarah_yq(` turned up zero hits. The three caller
scripts have drift coverage (`tests/drift-yq-variant-checks.bats`,
`tests/hook-scripts-coverage.bats`) that checks *whether a script calls the
guard*, but nothing exercises the guard function's own branches — a
regression inside `require_mikefarah_yq()` itself (e.g. a dropped `${CI:-}`
check, or a typo in the `mikefarah` grep pattern) would silently turn all
three callers' CI-required hard-fail into an always-green skip, with no
test anywhere to catch it. Same class of previously-uncovered,
single-most-invoked-gate gap that `tests/lint-script.bats` closed for
`scripts/lint.sh`.

New `tests/lib-yq-variant.bats`, mirroring `tests/lint-script.bats`'s
shim-PATH pattern (hide `yq` from PATH while keeping every other command
resolvable) plus two purpose-built fake `yq` binaries — one reporting a
mikefarah-style `--version` string, one reporting a generic non-mikefarah
one — so the "wrong variant" and "correct variant" branches are exercised
deterministically regardless of what's actually installed on the machine
running the tests (a `PATH="$PATH"`-based version of this test would behave
differently locally vs. in GitHub Actions, since `.github/workflows/ci.yml`
installs the real mikefarah/yq before the suite runs — caught and fixed
during this same cycle by first writing the fragile version, confirming it
passed against this sandbox's own pre-existing non-mikefarah `/usr/bin/yq`,
then re-verifying against a freshly-installed real mikefarah/yq and
catching the false pass). Ten assertions: file exists; valid bash syntax;
function is defined; skip-locally + hard-fail-in-CI for both "yq not
installed" and "wrong variant on PATH"; silent pass-through when the real
variant is present; the default `caller` argument value; and a same-file
cross-check that all three known callers still source the guard.

Bounded, behavior-preserving — no production script changed, only new test
coverage added. `make ci` passes locally (all bats suites, all drift
checks) after installing the real mikefarah/yq (`/usr/local/bin/yq`,
matching `.github/workflows/ci.yml`'s own install step) to get a clean
local signal; this sandbox's stock `/usr/bin/yq` is a different, older,
non-mikefarah variant which the CI drift checks are explicitly designed to
detect and warn about.

## PR

(filled in once the PR is opened — see `chore/yq-variant-lib-coverage`)
