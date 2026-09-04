# scripts/lint.sh — bats coverage gap closed

**Coverage/hardening fallback run**, continuing the same lane as PR #431
(`tests/validate-scripts.bats`). ROADMAP.md's `Now / next` lane was fully gated this
run (every item needs a live-cluster maintainer confirmation, or a prerequisite that is
itself gated the same way), and the two doc-drift items found this session already
shipped (PR #433). The coverage/hardening lane found one more real gap.

## Gap found

`scripts/lint.sh` — the gate that runs on **every** commit (`make lint`, the
`.githooks/pre-push` hook) and in CI's `lint` job — had **zero** dedicated bats
coverage of its own behavior, despite being the single most-invoked quality gate in the
repo. It shares the exact local-skip-vs-CI-required pattern
(`if [ "${CI:-}" = "true" ]; then ... exit 1; else ... skip ... exit 0; fi`) that PR
#431 closed for `validate-kustomize.sh`/`validate-manifests.sh`/`validate-terraform.sh`
— a dropped `${CI:-}` check here would silently turn the CI `lint` job into an
always-green no-op with nothing catching the regression.

## What shipped

New `tests/lint-script.bats` (14 assertions):

- **Existence + executable bit.**
- **Real behavioral coverage of the tool-missing branch** for *both* `shellcheck` and
  `yamllint` together (the script gates each independently but both share the same
  `need()` helper) — local (`CI` unset) exits 0 with both "not installed" skip
  messages; `CI=true` exits 1 with both "required in CI" messages.
- **A correctness fix caught while writing the tests**: the natural approach —
  stripping any `PATH` directory that contains `shellcheck`/`yamllint` (the same
  technique PR #431 used for `kustomize`/`kubeconform`/`terraform`) — breaks here,
  because apt installs `shellcheck`/`yamllint` into `/usr/bin`, the *same* directory
  that holds `bash`, `grep`, and the rest of coreutils on both this session's sandbox
  and GitHub Actions' `ubuntu-latest` runners. Dropping that whole directory produces an
  unrelated `127 command not found` instead of exercising the script's actual
  "tool not installed" branch — the earlier PR's technique happened to be safe only
  because `kustomize`/`kubeconform`/`terraform` are installed into directories (Go's
  `$GOPATH/bin`, `hashicorp/setup-terraform`'s toolcache) that don't also hold `bash`.
  Fixed by shadowing only the two named binaries: a shim directory goes first in
  `PATH`, symlinking every other entry from each real `PATH` directory. Built once per
  file (`setup_file` + `BATS_FILE_TMPDIR`, not per-test `setup()`) — walking the whole
  `PATH` 14 times added visible runtime for no benefit.
- **`SHELLCHECK_SEVERITY` override coverage** — asserts the default (`warning`) and
  that the env var actually overrides it (a regression hardcoding the default would
  silently stop CI from ever tightening the gate).
- **Structural regression guards** for the behaviors the script's own header comment
  documents as load-bearing: shellcheck runs over all of `scripts/*.sh`; yamllint runs
  with `-c .yamllint.yml` and only over directories that actually exist
  (`gitops`/`infra`/`.github`); the `lint: PASS`/`lint: FAIL` exit-code contract.
- **One real end-to-end assertion** (skipped if the tools aren't installed) that
  `lint.sh` actually passes against this repo's current scripts + manifests — catches
  an actual shellcheck/yamllint regression, not just the gate's plumbing.
- **Makefile + pre-push wiring**: `make lint` and `make ci` both invoke `lint.sh`;
  `.githooks/pre-push` runs the fast `make -C "$ROOT" lint` gate (not the full `make
  ci`), matching the documented pre-push/CI split in CLAUDE.md.

## Verification

`make ci` passes (full toolchain — `mikefarah/yq`, `kustomize`, `kubeconform`,
`terraform`, `tflint`, `helm` — installed this session; see PR #431's `docs/done/`
entry for how). `tests/lint-script.bats` run in isolation: 14/14 pass in ~13s.

## PR

https://github.com/tooming/k8s-anywhere/pull/434
