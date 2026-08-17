# Fix `scripts/git-fixture-isolation-check.sh` false-positive on `tests/forgejo-ci.bats`, breaking `main`'s CI

(bugfix, found live 2026-08-17, seventh cycle this run, while validating a routine
docs-only PR — `make ci`'s `drift` job turned up red for a reason unrelated to that
PR's own diff. **No prerequisites — found live, fixed immediately, same cycle.**

Root cause: a separate, concurrent live-cluster session's commit
("fix(forgejo-ci): replace actions/checkout@v4 with a plain git clone") added
`tests/forgejo-ci.bats`'s `@test "build-and-push checks out via a plain git clone,
not actions/checkout@v4"`, which asserts
`.forgejo/workflows/build-sign-push.yml`'s *text content* contains the shell command
`git clone --no-checkout` via `grep -q 'git clone --no-checkout' "$WF"` — it never
actually runs `git clone` itself, so it needs no `GIT_DIR` isolation.
`scripts/git-fixture-isolation-check.sh`'s detection regex
(`git[[:space:]]+(init|clone)([[:space:]]|$)` against the file with `#` comments
stripped) couldn't tell "a test that runs git clone" apart from "a test that greps
for the string git clone," so it flagged `forgejo-ci.bats` as a leaky fixture — a
false positive that made `main`'s `drift` CI job fail. Verified directly: `bash
scripts/git-fixture-isolation-check.sh` reproduced the failure against the
unmodified checked-out `main`, and `bats tests/forgejo-ci.bats` on its own passes
cleanly (16/16) — the target test file itself is correct; only the drift check's
detection was wrong.

Fix: exclude any matching line that also contains `grep` from the fixture-build
classification (a `grep` line is a content search, not an executed git command) —
`scripts/git-fixture-isolation-check.sh`'s existing real-fixture cases
(`tests/prune-stale-branches.bats`, `tests/rebase-open-prs.bats`) have no `grep` on
their `git init`/`git clone` lines, so this doesn't weaken the check for the case it
exists to catch.

**Mechanical guard (CLAUDE.md's "every bugfix must prevent recurrence"):** added
`tests/fixtures/git-fixture-isolation-check/in-sync/tests/grep-only.bats` (a golden
fixture mirroring the real-world `forgejo-ci.bats` shape) and a new
`tests/drift-git-fixture-isolation-check.bats` (split into its own scope per the
`tests/drift-detectors.bats` frozen-monolith convention) asserting the check does
NOT flag it.

`make ci` passes — bats was actually installed and run this cycle (not just skipped
locally as in prior cycles this run), confirming both the fix itself and that every
*other* currently-failing local test (`helm-chart-pin-check`/`argocd-crd-ssa-check`/
`rollouts-plugin-list-check`, failing against this sandbox's non-mikefarah `yq`)
reproduces identically on an unmodified `main` via `git stash` — pre-existing,
environment-only, and unrelated to this fix, not a regression it introduces.

## PR

https://github.com/tooming/k8s-anywhere/pull/1211
