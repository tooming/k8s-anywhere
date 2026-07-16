# New drift gate — ci-parity-check (make ci vs. GitHub Actions script parity)

**Coverage/hardening fallback run**, continuing this session's lane. Follows the same
new-mechanical-guard pattern as PR #436 (`markdown-links-check`) rather than another
missing-bats pickup, which is now fully closed.

## Gap found

CLAUDE.md states, in prose, that GitHub Actions' `drift` job is "kept in parity with
`make ci` — if you add a check to one, add it to the other," because the local
pre-push hook only runs the fast lint gate now; GitHub Actions is the actual full
backstop. Nothing mechanical enforced that rule — a PR could wire a new
`scripts/*-check.sh` gate into only one side (forgetting the other) and nothing would
catch it: `make ci` would be green locally while CI silently never ran the new check,
or vice versa. A spot check this run found the two currently in perfect sync (20
scripts each), but that's an artifact of this session manually keeping `markdown-links-check.sh`
wired into both — a real, recurring risk for any future change, not a one-off finding.

## What shipped

- **`scripts/ci-parity-check.sh`**: extracts the `scripts/*.sh` references from the
  Makefile's `ci:` target recipe (scoped to that target only — a `Makefile` fixture
  case asserts an unrelated target's script never leaks in) and from
  `.github/workflows/ci.yml`, diffs the two sets, and fails naming exactly which
  script is missing from which side. `CIPARITY_ROOT` env-var override for
  fixture-tree testing, matching the established `READMECHECK_ROOT`/`MDLINKS_ROOT`
  convention.
- **`make ci-parity-check`** target; wired into `make ci` and the GitHub Actions
  `drift` job (added to *both*, closing the loop on the very rule it now enforces).
- **`scripts/ci-parity-sync-hook.sh`**: PostToolUse companion, fires on edits to
  `Makefile` or `.github/workflows/ci.yml`, wired into `.claude/settings.json`.
- New `tests/fixtures/ci-parity-check/{in-sync,drift}/` fixture trees and four new
  `tests/drift-detectors.bats` cases (in-sync passes, drift names the missing script
  and direction, unrelated Makefile targets are never scanned, real repo passes) plus
  four new `tests/hook-scripts-coverage.bats` cases for the sync-hook.

## Verification

`make ci` passes (full toolchain installed this session — see PR #431's `docs/done/`
entry). `shellcheck -S warning` clean on both new scripts. Manually verified the check
actually catches drift in both directions (script-only-in-Makefile,
script-only-in-workflow) with an ad hoc fixture before relying on it.

## PR

Autonomous session run — see the `claude/work-until-credits-exhausted-b828b2` branch.
