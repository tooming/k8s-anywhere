# chore: extract shared hook-payload parsing into `scripts/lib/hook-payload.sh`

Janitor sweep (executor STEP 6b fallback — the "Now / next" lane was gated again
this cycle; the planner fallback had nothing new to promote (no open issues, no
pending `docs/roadmap/incoming/` files); this run had already used its one
`upgrade/*` PR (kyverno bump, PR #556) and a doc-drift sweep found no drift
signals, so this cycle's deliverable is a bounded codebase-health cleanup
instead — mirrors the 2026-07-18 `scripts/lib/colors.sh` extraction, PR #513).

## The duplication

15 `scripts/*-hook.sh` PostToolUse hooks each independently declared the
identical two-line snippet to extract the edited file's path from the Claude
Code hook JSON payload on stdin:

```sh
payload="$(cat 2>/dev/null || true)"
fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
```

(`adr-guard-hook.sh`, `argocd-crd-ssa-sync-hook.sh`, `ci-parity-sync-hook.sh`,
`helm-chart-pin-sync-hook.sh`, `lab-ui-sync-hook.sh`,
`markdown-links-sync-hook.sh`, `mimir-readonly-root-sync-hook.sh`,
`networkpolicy-tests-sync-hook.sh`, `observability-tests-sync-hook.sh`,
`readme-sync-hook.sh`, `roadmap-sync-hook.sh`,
`rollouts-plugin-list-sync-hook.sh`, `routines-sync-hook.sh`,
`securitycontext-tests-sync-hook.sh`, `yq-raw-sync-hook.sh`) — a future
payload-shape change (e.g. a different hook JSON field, added quoting-safety)
would have required 15 synchronized edits. `idle-issue-guard-hook.sh` and
`merge-ci-gate-hook.sh` were deliberately left alone — they extract different
fields (`title`/`body`/`state`, and `command`, respectively), not
`file_path`/`path`, so they're not the same duplication.

## The fix

1. Added `scripts/lib/hook-payload.sh` — a single `hook_file_path()` function
   wrapping the two-line snippet above.
2. Replaced each of the 15 hooks' inline two lines with
   `source "$ROOT/scripts/lib/hook-payload.sh"` + `fp="$(hook_file_path)"` —
   `$ROOT` was already defined identically in every one of these hooks
   (`"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`), so no new variable
   was introduced.
3. Fixed `tests/hook-scripts-coverage.bats`'s `setup_routines_fixture()`
   helper, which copies `routines-sync-hook.sh` into an isolated fixture tree
   to test `$ROOT`-relative path resolution in isolation — it now also copies
   `scripts/lib/hook-payload.sh` into the fixture's `scripts/lib/`, since the
   hook now sources it. Caught this via a real test failure during
   verification (see below), not by inspection alone.

## Behavior preservation

`bats`/`shellcheck`/`yamllint` all installed this session for full local
verification (not skipped). Confirmed via `git stash -u` (stashing tracked
*and* untracked changes, so the two new files don't contaminate the baseline)
that this diff introduces **zero new failures** — the exact same 13
pre-existing, unrelated failures (this sandbox's python/jq-based `yq`, not
mikefarah's) appear identically with and without it. `shellcheck -S warning`
is clean across `scripts/*.sh`. All 49 `tests/hook-scripts-coverage.bats`
assertions pass except the same 3 pre-existing ones that fail on unmodified
`main` too.

## Recurrence guard

Added `tests/hook-payload-lib.bats`: asserts `scripts/lib/hook-payload.sh`
exists, defines `hook_file_path()`, is syntactically valid, and behaves
correctly (extracts `file_path`, falls back to `path`, returns empty on an
empty payload) — and, the actual guard, asserts no `*-hook.sh` script
re-inlines the `tool_input.file_path // tool_input.path` jq pattern (only
`hook-payload.sh` itself may contain it), plus a spot-check that ≥10 hooks
adopted the shared lib via the `$ROOT`-relative source line. Verified the
guard is real by temporarily reverting one hook's `source` line back to the
inline pattern, confirming the guard test fails, then restoring and
confirming all 8 pass again.

`make ci` passes. This is a pure refactor — no `make ci` check's set of
passing assertions changed beyond the 8 new guard tests (and the 2 assertions
in `tests/hook-scripts-coverage.bats` that exercise the fixed fixture).

## PR

(filled in after PR creation)
