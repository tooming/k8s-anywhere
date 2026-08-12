# ACK s3-controller context.md drift fix + mechanical guard extension

(CHARTER **Core Values** §"Everything as code"; JANITOR-fallback bounded cleanup
2026-08-12, reached via `executor.prompt.md` STEP 6b JANITOR role, this run's 15th
cycle, after the Now/next lane was re-confirmed fully gated. **No prerequisites —
executor may pick up immediately.**)

## What was wrong

`docs/decisions/context.md`'s ACK s3-controller citation ("chart 1.8.1") was two
real chart bumps behind the live pin (`gitops/platform/ack-s3.yaml`'s
`targetRevision: 1.9.0`): `1.8.1 → 1.8.2` (PR #859) and `1.8.2 → 1.9.0` (PR #1009)
both landed without this file being updated.

Found by continuing this run's chain of "self-tracking doc citation" audits (PR
#1142 fixed ADR-0023's chart-version citation; PR #1144 fixed ADR-0018's image-pin
citation) — after those two, checked `scripts/context-doc-version-sync-check.sh`'s
own real-repo coverage and found it only tracks 3 of context.md's several inline
version citations (Grafana, Pyroscope, KRO) — unlike the ADR guards, this script's
list is hardcoded, not self-maintaining, so any citation added to context.md after
the script was written is silently uncovered. Manually checked every other version
citation in context.md against its live gitops pin and found the ACK mismatch
directly (`git log -- gitops/platform/ack-s3.yaml` confirms the two bump commits).

## Fix

Corrected context.md's ACK citation to `1.9.0`.

## Mechanical guard (this bugfix's second deliverable)

Added a fourth `check_one` call to `scripts/context-doc-version-sync-check.sh` for
the ACK s3-controller citation, so a future ACK chart bump that forgets to update
context.md now fails `make context-doc-version-sync-check` (wired into `make ci`'s
`drift` gates) — same "make the bug impossible by construction" pattern as PR
#1142/#1144, applied to this script's own (non-self-maintaining, explicitly
hardcoded) citation list. Updated the script's header comment to record this as the
second real staleness incident this file has had. Extended both the real-repo bats
assertion and the two fixture trees (`tests/fixtures/context-doc-version-sync/{in-sync,drift}`)
with a matching ACK citation + `gitops/platform/ack-s3.yaml`, so the synthetic
pass/fail tests stay meaningful now that a 4th citation is tracked (confirmed
locally: `bats tests/drift-adr-sync-checks.bats` 16/16).

## ADR-0004 caveat

The corrected version (`1.9.0`) was read directly from the live
`gitops/platform/ack-s3.yaml` manifest and cross-checked against its `git log`
bump-commit history — not re-derived or guessed.

## Rollback path

Revert this commit. The fixture additions are self-contained test data with no
effect outside `tests/drift-adr-sync-checks.bats`.

## PR

https://github.com/tooming/k8s-anywhere/pull/1145
