# CI fix: tflint's `install_linux.sh` convenience script was retired upstream

Found live 2026-09-13 (executor.prompt.md STEP 1c, discovered while `make ci`
verifying the day's `[Action needed]` cycle-1 PR): the `terraform` job's
"Install tflint" step —
`curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash`
— failed with a real `404`, not a transient network blip. Confirmed live:
neither `terraform-linters/tflint`'s `master` nor `main` branch serves
`install_linux.sh` any more; the repo's own README Installation section no
longer mentions it at all, listing only direct release-asset download,
Homebrew/WinGet, `go install`, and Docker as supported methods. The prior
main-branch CI run (2026-09-12, commit `9270060`) still passed with the old
step — this broke silently between the two, external to any diff in this
repo. `scripts/ensure-manifest-tools-hook.sh`'s own header comment for this
exact install step had already flagged the risk ("the upstream script itself
warns it may be retired") — it has now actually happened.

## Scope

Same-source fix, not a new dependency: switched `.github/workflows/ci.yml`'s
"Install tflint" step and `scripts/ensure-manifest-tools-hook.sh`'s
`install_tflint()` from the retired curl-pipe-bash installer to the same
pinned direct-binary-download pattern this workflow already uses for
kustomize/kubeconform — `curl` the exact release asset
(`tflint_linux_amd64.zip`, verified live to exist and extract to a single
`tflint` binary that runs and reports its version), unzip, `install` to
`/usr/local/bin`. Pinned to `v0.64.0` — verified live as the current
newest stable tag (`v0.63.1`, `v0.63.0` etc. precede it; no unreleased/rc
tags ahead of it).

**Mechanical guard (CLAUDE.md's "every bugfix prevents recurrence"):** added
two tests to `tests/ci-tool-pins.bats` — one asserting the new pinned-download
line is present (same pattern as the existing kustomize/kubeconform/terraform
pin tests), one asserting no workflow or script references the retired
`install_linux.sh` URL under either branch name. A future accidental revert
back to the convenience script (e.g. a well-meaning "simplify this" edit)
now fails `make ci` immediately instead of silently reintroducing the same
footgun the next time upstream changes its repo layout again.

## Verification

- Downloaded the pinned `v0.64.0` release asset directly, confirmed it
  extracts a single `tflint` binary, confirmed `tflint --version` reports
  `TFLint version 0.64.0`.
- `bash scripts/validate-terraform.sh` — all three modules (`argocd`,
  `k3d-cluster`, `oracle-k3s-cluster`) pass `tflint`.
- `shellcheck scripts/ensure-manifest-tools-hook.sh` — clean.
- `yamllint .github/workflows/ci.yml` — clean.
- `bats tests/ci-tool-pins.bats` — all 18 tests pass (16 pre-existing + 2
  new).
- Full `make ci` — green.

Not an ADR-worthy decision (a CI tooling install-method swap, not an
architecture choice); no version-pinning ADR touches tflint.

## PR

auto/ci-fix-tflint-install-script-retired
