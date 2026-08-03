# Extract shared `ok()`/`bad()` helpers to `scripts/lib/colors.sh`; add a recurrence guard

(janitor finding, issue #957; **pick up ONLY after
`auto/scripts-drift-var-rename` merges** — every `scripts/*.sh` defining its
own `bad()` must already use `drift` as the failure-flag variable name before
this extraction is safe, since the shared version below writes to the
sourcing script's own `drift` variable). Add `ok()`/`bad()` function
definitions to `scripts/lib/colors.sh` (which already centralizes the
`$G`/`$R`/`$Z` color codes these two functions use); remove each script's own
inline `ok()`/`bad()` copy, replacing with (or confirming) a
`source .../lib/colors.sh` line. New `scripts/ok-bad-lib-check.sh` (+ `make
ok-bad-lib-check`, wired into `make ci` and the GitHub Actions `drift` job,
plus a PostToolUse sync hook) mirroring `scripts/yqs-lib-check.sh`'s pattern
(PR #956): fails if any `scripts/*.sh` still defines its own local
`ok()`/`bad()` instead of sourcing the shared copy. Add matching bats coverage
(`tests/drift-<scope>.bats` + `tests/hook-scripts-<scope>.bats` conventions —
the relevant monoliths are frozen). `make ci` must pass. `docs/done/` entry
required. (auto/ok-bad-lib-extract)

## What was found at pickup time

Re-verified the exact scope directly (not just trusting the plan PR's cached
~24-file estimate): of the scripts defining their own `bad()`, **19** now use
the `drift=1` side effect consistently (16 already did, plus the 3 renamed by
`auto/scripts-drift-var-rename` — PR #959) and were extracted. The other
**5** (`argocd-crd-ssa-check.sh`, `helm-chart-pin-check.sh`,
`lab-health-check.sh`, `mimir-readonly-root-check.sh`,
`rollouts-plugin-list-check.sh`) define a `bad()` with **no side effect** —
they track failure via their own separately-managed `fail` variable instead,
set explicitly at each call site. These 5 were deliberately left untouched:
forcing them onto the shared drift-setting `bad()` would add an incidental,
unused `drift` variable to their scope — a small but real behavior wrinkle
this extraction avoids by design. The recurrence guard only flags the
drift-setting shape, so it correctly never flags these 5.

## What changed

- `scripts/lib/colors.sh` — added `ok()`/`bad()` (the shared copy; `bad()`
  sets the sourcing script's own `drift` variable via a plain global
  assignment, exactly matching every extracted script's prior inline
  behavior).
- 19 scripts (`adr-chart-version-sync-check.sh`, `adr-followup-check.sh`,
  `adr-image-pin-sync-check.sh`, `context-doc-version-sync-check.sh`,
  `docs-done-pr-link-check.sh`, `dr-verify.sh`, `git-fixture-isolation-check.sh`,
  `kustomize-orphan-check.sh`, `lab-ui-check.sh`, `lint.sh`,
  `networkpolicy-tests-check.sh`, `readme-check.sh`, `roadmap-check.sh`,
  `routines-author-check.sh`, `routines-check.sh`, `validate-terraform.sh`,
  `yq-raw-check.sh`, `yq-variant-guard-check.sh`, `yqs-lib-check.sh`) — removed
  their own inline `ok()`/`bad()` definitions; all already sourced
  `lib/colors.sh` for the `$G`/`$R`/`$Z` color codes, so no new `source` line
  was needed.
- New `scripts/ok-bad-lib-check.sh` (+ `make ok-bad-lib-check`, wired into
  `make ci` and the GitHub Actions `drift` job) — flags any `scripts/*.sh`
  defining its own drift-setting `bad()` (matched by shape: a `bad()` body
  ending in `drift=1;`), deliberately never flagging a no-side-effect `bad()`
  or `ok()` in isolation (see rationale above and the script's own header).
- New `scripts/ok-bad-lib-sync-hook.sh` (wired into `.claude/settings.json`'s
  `PostToolUse` hooks) — the local, immediate-feedback companion to the CI
  gate above.
- New bats coverage: extended `tests/colors-lib.bats` (already the dedicated,
  non-frozen coverage file for `scripts/lib/colors.sh`) with direct unit tests
  for `ok()`/`bad()`'s printing and drift-setting behavior; new
  `tests/drift-ok-bad-lib.bats` (the new drift guard's own tests, fixture-based,
  `tests/drift-<scope>.bats` convention — `tests/drift-detectors.bats` is
  frozen); new `tests/hook-scripts-ok-bad-lib.bats` (the new sync hook's
  coverage, `tests/hook-scripts-<scope>.bats` convention —
  `tests/hook-scripts-coverage.bats` is frozen); three small fixture scripts
  under `tests/fixtures/ok-bad-lib-check/{in-sync,drift}/` (including one
  exercising the legitimate no-side-effect exemption).

## What didn't change

Behavior-preserving only: every extracted script's `ok()`/`bad()` body is
byte-for-byte identical to what it carried inline before, so each script's
actual pass/fail behavior against the live repo is unchanged — spot-verified
directly (`lint.sh`, `readme-check.sh`, `adr-chart-version-sync-check.sh`,
`roadmap-check.sh`, `yqs-lib-check.sh` all still produce identical output).
No topology change, so no README/`docs/dependency-tree.md` update.

`make ci` must pass.

## PR

[#960](https://github.com/tooming/k8s-anywhere/pull/960)
