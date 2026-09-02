# Add `make dependency-exit-runbooks-sync-check` — mechanical drift guard between `docs/dependency-concentration.md` and `docs/dependency-exit-runbooks.md`

`docs/dependency-register.md`, `docs/dependency-concentration.md`, and
`docs/dependency-exit-runbooks.md` each carried a "no mechanical drift guard yet, kept
in sync by hand" caveat in their own "Keeping this in sync" sections. This run's fifth
cycle (2026-09-02, `auto/dependency-concentration-sync-check`,
[docs/done/2026-09-02-dependency-concentration-sync-check.md](2026-09-02-dependency-concentration-sync-check.md))
closed the first half of that gap — register-row concentration counts vs. named groups
in `docs/dependency-concentration.md` — but left the second half open: nothing checked
that every concentration group `docs/dependency-concentration.md` names actually has a
matching runbook section in `docs/dependency-exit-runbooks.md`. This cycle closes that
remaining half.

`scripts/dependency-exit-runbooks-sync-check.sh` parses every `**\`github.com/ORG\`**`
concentration-group header out of `docs/dependency-concentration.md` (currently three:
the CNCF-graduated-project, HashiCorp, and Grafana Labs groups) and fails if
`docs/dependency-exit-runbooks.md` has no section mentioning that same
`` `github.com/ORG` `` string. It deliberately does **not** require 100% coverage of
every single-tool row in `docs/dependency-exit-runbooks.md` — the file's own "Scope of
this slice" note already documents that as an intentional, honestly-labeled partial
slice (most recently narrowed by the fourth cycle's Cilium/Garage/Envoy
Gateway/cert-manager addition,
[docs/done/2026-09-02-dependency-exit-runbooks-single-tool-slice.md](2026-09-02-dependency-exit-runbooks-single-tool-slice.md)),
not drift — so the check's scope is the three named concentration *groups* only,
matching what `docs/dependency-concentration.md` actually asserts must exist elsewhere.

Pure text-parsing over two already-committed docs, no network calls — fast and
deterministic, so (like `dependency-concentration-sync-check.sh`, unlike the
network-dependent `dependency-maintenance-check.sh`) it's wired directly into
`make ci` and `.github/workflows/ci.yml`'s `drift` job. Added a matching
`scripts/dependency-exit-runbooks-sync-hook.sh` PostToolUse nudge (mirrors
`dependency-concentration-sync-hook.sh`, fires on edits to either
`docs/dependency-concentration.md` or `docs/dependency-exit-runbooks.md`) plus bats
coverage: `tests/dependency-exit-runbooks-sync-check.bats` (in-sync/drift fixtures +
a real-repo pass-through test) and
`tests/hook-scripts-dependency-exit-runbooks-sync.bats` (hook-script coverage, per the
`hook-scripts-coverage-tests-check` convention that new hook-script tests live in their
own `tests/hook-scripts-<scope>.bats` file rather than the frozen
`tests/hook-scripts-coverage.bats`). Registered the new check in both `Makefile`'s `ci:`
target and `.github/workflows/ci.yml`'s `drift` job in the same commit, keeping
`scripts/ci-parity-check.sh` green throughout (its sync-hook caught and flagged the
initial single-sided addition immediately, as designed).

`make ci` passes locally: lint (shellcheck + yamllint), the full bats suite including
the new/updated tests above, and `scripts/ci-parity-check.sh`.

## PR

[#1380](https://github.com/tooming/k8s-anywhere/pull/1380)
