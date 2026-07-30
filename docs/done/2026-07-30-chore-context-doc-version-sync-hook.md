# Wire the missing PostToolUse hook for context-doc-version-sync-check.sh

`scripts/context-doc-version-sync-check.sh`'s own header explicitly documented a gap:
"Run by `make context-doc-version-sync-check` and the CI 'drift' gate (no PostToolUse
hook yet — this is a CI-time gate only)." Every other self-tracking-doc drift check in
this repo (`adr-chart-version-sync-check.sh`, `adr-image-pin-sync-check.sh`,
`docs-done-pr-link-check.sh`, `kustomize-orphan-check.sh`, ...) already has a
companion PostToolUse hook that nudges at edit time instead of waiting for the next
`make ci`/CI run — this one was the sole exception, an acknowledged but unfilled gap.

This matters because the exact recurrence this check guards against (Grafana/
Pyroscope/KRO version citations in `docs/decisions/context.md` going stale after a
bump landed elsewhere, found 2026-07-28) is precisely the kind of drift a live
edit-time nudge catches before it ever reaches CI.

## Fix

Added `scripts/context-doc-version-sync-hook.sh`, mirroring the existing
`adr-chart-version-sync-hook.sh` pattern exactly: reacts to an edit under
`docs/decisions/` or `gitops/`, re-runs `context-doc-version-sync-check.sh`, and
prints a reminder on drift. Wired into `.claude/settings.json`'s PostToolUse hooks
array. Updated the check script's header comment to say it's now hook-covered.
New `tests/hook-scripts-context-doc-version-sync.bats` (per the
`hook-scripts-coverage.bats` frozen-monolith convention — new hook coverage goes in
its own scope file): empty payload, unrelated file, and gitops-file-edit-while-clean
all exit 0; the real repo's `context.md` (currently clean) exits 0; a synthetic
drifted fixture exits 2 with the expected message.

No behavior change to the check itself — purely additive (new hook + wiring + tests).

`make ci` passes (2345 assertions, 0 failures — verified locally with `bats`/`jq`/a
fetched `mikefarah/yq` binary, none present by default in this sandbox).

## PR

(filled in after PR creation)
