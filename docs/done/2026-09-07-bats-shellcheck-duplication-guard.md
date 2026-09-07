# JANITOR-fallback: remove tests/forgejo-repo-secret.bats's redundant direct `shellcheck` invocation + add a mechanical recurrence guard

**The footgun.** `tests/forgejo-repo-secret.bats` (added 2026-09-06) carried its
own one-off assertion:

```bash
@test "forgejo-repo-secret.sh passes shellcheck" {
  run shellcheck --severity=warning "$SCRIPT"
  [ "$status" -eq 0 ]
}
```

`make lint` (`scripts/lint.sh`, wired into `make ci`) already shellchecks
**every** file under `scripts/*.sh` — including this one — with the repo's one
established pattern: optional locally (skipped with a note when `shellcheck`
isn't installed), but hard-required in CI (`CI=true`) so the gate can't
silently no-op on a real run. This bats assertion duplicated that coverage for
one specific script, worse: it invoked `shellcheck` directly with no skip
guard at all, so it hard-failed `make ci` in any sandbox without `shellcheck`
on `PATH` — this clusterless remote sandbox included. It surfaced as a
`not ok` on every one of this run's first three PRs, each needing its own
explanation that the failure was pre-existing and unrelated to that PR's diff.

**The fix — bug + mechanical guard (CLAUDE.md's bugfix-recurrence rule):**

1. **Fix:** removed the redundant `@test` from `tests/forgejo-repo-secret.bats`.
   No coverage lost — `make lint` already shellchecks this exact file as part
   of its repo-wide sweep.
2. **Guard (structural, per "make it impossible by construction"):**
   `scripts/bats-shellcheck-duplication-check.sh` — a new `make ci` gate that
   fails if any `tests/*.bats` file invokes `shellcheck` directly. Wired into:
   - `make bats-shellcheck-duplication-check` (Makefile target).
   - `make ci`'s script list.
   - `.github/workflows/ci.yml`'s `drift` job (kept in parity — confirmed via
     `make ci-parity-check`).
   - Its own dedicated bats file, `tests/drift-bats-shellcheck-duplication-check.bats`
     (per `tests/drift-detectors.bats`'s "new coverage goes in its own file"
     convention), with golden (`in-sync`) and regression (`drift`) fixtures
     under `tests/fixtures/bats-shellcheck-duplication-check/`.

**Verification.** `make ci` ran **fully clean** for the first time this
session — exit 0, zero `not ok` lines, including the new guard's own test
confirming the real repo's `tests/` directory is clean post-fix. Behavior is
otherwise unchanged: no other test's assertions, `make lint`'s own shellcheck
coverage of `forgejo-repo-secret.sh`, or any gate's pass/fail set changed.

Found via the executor's STEP 6b JANITOR fallback (this run's third
consecutive gated "Now / next" cycle — PLANNER twice found nothing further to
groom, so this cycle tried a different lens per STEP 8's "widen it" guidance:
a footgun that had already bit this exact session three times in a row).

## PR

(filled in once the PR is opened)
