# Add bats coverage for scripts/idle-issue-guard-hook.sh

(CHARTER **Core Values** §"Everything as code" + general hardening; executor-fallback
test-coverage sweep 2026-08-20, sixth pass this run — reached via
`executor.prompt.md` STEP 6b after five earlier passes this run (kube-state-metrics
chart bump PR #1290; Harbor/Kiali register sweep PR #1291; docs/DR.md, dependency-
concentration.md, and platform-products.md Forgejo caveats/fixes, PRs #1292/#1293/
#1294, all merged) still left the "Now / next" lane fully gated (re-checked: issues
#633/#1229 both re-read, no new comments). **No prerequisites — executor may pick up
immediately.**

A genuinely different angle this cycle: ROADMAP rule #9's fallback chain names "a
script with no bats coverage" as one of the always-real filler categories. Enumerated
every `scripts/*-hook.sh`/`scripts/*-sync-hook.sh` PostToolUse/SessionStart hook script
(34 distinct hooks) and cross-checked each against every `tests/hook-scripts-*.bats`
file plus the other hook-test files (`tests/adr-guard.bats`,
`tests/commit-reminder-hook.bats`, `tests/merge-ci-gate-hook.bats`,
`tests/drift-idle-issue-guard.bats`). One gap: `scripts/idle-issue-guard-hook.sh` —
`tests/drift-idle-issue-guard.bats` covers the underlying
`scripts/idle-issue-guard-check.sh` thoroughly (8 tests, direct `IDLEGUARD_*` env-var
calls), but the hook wrapper's own JSON-payload-parsing adapter logic (the `jq` field
paths pulling `.tool_input.title`/`.tool_input.body`/`.tool_input.state`, the env-var
forwarding, and the "close it" reminder text appended on a block) was never exercised
by any test — exactly the class of gap `tests/hook-scripts-coverage.bats`'s own header
comment already describes for the 16 hooks it originally covered ("a broken case/esac
filter or a wrong jq path would silently stop nudging without make ci ever catching
it").

Added `tests/hook-scripts-idle-issue-guard.bats` (new file — `tests/hook-scripts-
coverage.bats` is frozen, new hook coverage goes in its own `tests/hook-scripts-
<scope>.bats` per that file's own enforced convention), 7 tests: empty payload,
unrelated title/body, a real idle declaration (block + exact BLOCKED/forbidden text),
the hook-specific "close it" reminder appended after the check script's own output,
`state=closed` bypass (verifies the hook forwards `.tool_input.state` correctly, not
just title/body), and a `[self-review]`-prefixed comment payload with no `title` field
(exercises `add_issue_comment`'s real payload shape). Every expectation was manually
verified against the real script's actual behavior via `jq`+`bash` before being written
into the bats file (not assumed — ADR-0004).

`make ci` confirmed green (including the `hook-scripts-coverage-tests-check` gate,
which only guards the frozen monolith itself — a new file needs no registration).

## PR

(filled in after PR creation)
