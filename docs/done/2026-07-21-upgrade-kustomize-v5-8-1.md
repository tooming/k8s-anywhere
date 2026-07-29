# Bump kustomize v5.4.3 → v5.8.1 (CI overlay-build validation tool)

CHARTER **Core Values** §"Clusterless gates stay green" / general CI dependency
hygiene. `.github/workflows/ci.yml`'s `kustomize` job pins `kubernetes-sigs/kustomize`
(the overlay-build validator behind `scripts/validate-kustomize.sh`) by explicit
version. Follow-up to `auto/upgrade-kubeconform-v0.8.0` (2026-07-21, same cycle
7 sweep of `ci.yml`'s three CI-tool version pins) — that PR deliberately left
kustomize and terraform for a following cycle to respect upgrade-drafter's
one-PR-per-cycle WIP cap; this is that following cycle.

- Component: `kubernetes-sigs/kustomize` (GitHub releases; tags are prefixed
  `kustomize/vX.Y.Z` since the repo hosts multiple Go modules — `api/`,
  `cmd/config/`, `kyaml/`, etc. — under one release stream)
- From → To: `kustomize/v5.4.3` → `kustomize/v5.8.1` (4 minor releases;
  still major `v5`, no architect RFC needed)
- Why this version: highest stable release, same major line, no
  version-pinning ADR. Verified directly via
  `git ls-remote --tags https://github.com/kubernetes-sigs/kustomize.git`,
  filtered to the `kustomize/v*` prefix specifically (not `api/`/`kyaml/`
  tags) — confirmed the full real intervening tag sequence
  (`v5.5.0`, `v5.6.0`, `v5.7.0`, `v5.7.1`, `v5.8.0`, `v5.8.1`), not just the
  endpoints. `scripts/validate-kustomize.sh`'s only kustomize invocation is
  `kustomize build --load-restrictor LoadRestrictionsNone`, a long-standing
  stable flag present well before `v5.4.3` — no script change needed. The
  `kustomize` CI job itself (which builds every real `kustomization.yaml`
  under `gitops/`) is the live end-to-end verification.

Updated the download URL in `.github/workflows/ci.yml`. Extended
`tests/ci-tool-pins.bats` (added by the prior kubeconform bump) with the
kustomize pin assertion + a "no stale v5.4.3 pin" guard, matching that file's
existing pattern.

terraform (`1.9.8` → real latest `1.15.8`) was also found behind in the
cycle-7 sweep but is deliberately **not** bumped here either — still one
`upgrade/*` PR per cycle; left for a further following cycle.

`make ci`-relevant checks: `bats tests/ci-tool-pins.bats` (5/5 ok),
`scripts/lint.sh` clean, `scripts/ci-parity-check.sh` green (no gate wiring
touched, only a tool-version pin).

## PR

[#642](https://github.com/tooming/k8s-anywhere/pull/642)
