# `tests/frozen-monolith-lib.bats` — direct unit coverage for `scripts/lib/frozen-monolith-check.sh` + `frozen-monolith-sync-hook.sh`

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's bugfix-prevents-recurrence
rule; planner gap-analysis sweep 2026-07-31 — all three standing "Now / next" items are
still gated on unconfirmed maintainer-confirmation issues #631/#633 (checked directly
this run: neither issue has a comment confirming its ask; `gitops/kyverno/policies/
verify-image-signatures.yaml` still reads `validationFailureAction: Audit` /
`failurePolicy: Ignore`, so the gate is accurate, not stale), so this is rule #9
coverage/hardening filler, not CHARTER-objective progress. Verified directly (not
assumed, ADR-0004): every other shared `scripts/lib/*.sh` helper extracted from
repeated copy-paste (`colors.sh`, `hook-payload.sh`, `yq-variant.sh`, `budget-check.sh`)
has its own dedicated `tests/<name>-lib.bats` asserting the shared function's behavior
directly (`colors-lib.bats`, `hook-payload-lib.bats`, `lib-yq-variant.bats`,
`budget-check-lib.bats`) — `frozen-monolith-check.sh` and `frozen-monolith-sync-hook.sh`
were the only two `scripts/lib/*.sh` files with no bats file exercising them directly
(only exercised transitively through the four wrapper scripts they back via
`tests/drift-frozen-monolith-checks.bats`). Not a functional bug — behavior was already
covered indirectly — but it was the one lib extraction that skipped the pattern's own
direct-unit-test half.

## What changed

Added `tests/frozen-monolith-lib.bats` (20 assertions) mirroring `hook-payload-lib.bats`'s
shape:

1. Both lib files exist.
2. Both are valid, sourceable bash (`bash -n`).
3. `frozen-monolith-check.sh` defines `frozen_monolith_check()` and
   `frozen-monolith-sync-hook.sh` defines `frozen_monolith_sync_hook()`.
4. `frozen_monolith_check()` exercised directly against fixture files written at
   runtime under `$BATS_TEST_TMPDIR`: passes when the live `@test` title set matches
   the snapshot; fails and prints the "Add NEW tests in `<scope_hint>`" guidance when
   it drifts; is a no-op when the target bats file doesn't exist yet.
5. `frozen_monolith_sync_hook()` exercised directly with a synthetic JSON hook payload
   (via `hook_file_path`'s existing stdin contract): a no-op (exit 0) for an edit to a
   file other than the monolith; exit 2 with FROZEN guidance for an edit to the
   drifted monolith; exit 0 for an edit to the monolith that still matches its
   snapshot.
6. A recurrence guard: every `scripts/lib/*.sh` file must be referenced by name in at
   least one `tests/*.bats` file, so a future fifth lib extraction can't silently skip
   its own direct-unit-test half again.

Two implementation details worth recording for future fixture-writing sessions in this
repo:

- **Fixture bats files must never contain a literal line-leading `@test`.**
  bats-core's own test-collection preprocessor scans every `*.bats` file — including
  this one — line-by-line for `^@test`, with no heredoc awareness. A literal
  `@test "..." {` inside one of this file's own heredocs gets collected as a bogus
  extra test of `tests/frozen-monolith-lib.bats` itself (confirmed locally: bats threw
  "Duplicate test name(s)" / "unknown test name" errors on the first draft). Fixed by
  writing fixture content with an `AT_TEST` placeholder and fixing it up with `sed`
  immediately after each heredoc.
- **A JSON payload must never be re-embedded as literal text inside a nested
  `bash -c '...'` string.** The payload's own `"` characters break out of the
  reconstructed command's quoting (confirmed locally: silently corrupted the command,
  producing a false exit-0 pass instead of the expected exit-2 failure). Fixed by
  piping the payload into `frozen_monolith_sync_hook` via stdin redirection on a real
  shell variable (`<<< "$payload"`) instead.

No topology change, so no README/`docs/dependency-tree.md` update was needed.
`make ci` passes locally (2408 bats assertions, 0 failures, run against the real
`mikefarah/yq` "latest" binary matching what `.github/workflows/ci.yml` installs).

## PR

https://github.com/tooming/k8s-anywhere/pull/954
