# Bump CI-pinned terraform 1.9.8 → 1.15.8

CHARTER **Core Values** §"Clusterless gates stay green" / general CI dependency
hygiene. `.github/workflows/ci.yml`'s `terraform` job pins the `terraform_version`
input to `hashicorp/setup-terraform`. Third and final bump from the cycle-7
sweep of `ci.yml`'s three explicit CI-tool version pins (kubeconform → PR #641,
kustomize → PR #642, both same sweep) — terraform was deliberately left for a
further cycle each time to respect the one-`upgrade/*`-PR-per-cycle WIP cap.

- Component: `hashicorp/terraform` (the binary `hashicorp/setup-terraform`
  downloads; this repo has no ADR pinning terraform's exact version — only a
  floor constraint, see below)
- From → To: `1.9.8` → `1.15.8` (6 minor releases; still major `1`, terraform's
  own compatibility promise holds within a major line, no RFC needed)
- Why this version: highest real stable release. Verified directly via
  `git ls-remote --tags https://github.com/hashicorp/terraform.git` — `v1.15.8`
  exists as a real tag (cross-checked against the intervening `v1.10.x`
  through `v1.15.x` releases also being real tags, not gaps).
- **Compatibility check:** every `infra/modules/*/main.tf` declares
  `required_version = ">= 1.5"` — a floor, never an exact pin, so `1.15.8` (which
  is `>= 1.5`) stays compatible without touching any module. Confirmed this
  holds for all four modules (`argocd`, `oracle-k3s-cluster`, `gitlab-config`,
  `k3d-cluster`) via a new bats assertion, not just asserted in prose.
  `scripts/validate-terraform.sh` only runs `terraform fmt -check` /
  `terraform validate` / `tflint` — none of which this repo's `.tf` files use
  any syntax/behavior removed across the 1.9→1.15 line for (no deprecated
  provider-block syntax, no removed `terraform {}` block features in this
  repo's modules). The `terraform` CI job itself (which runs `fmt`/`validate`
  against every real module) is the live end-to-end verification.

Updated the `terraform_version` input in `.github/workflows/ci.yml`. Extended
`tests/ci-tool-pins.bats` with the exact-pin assertion, a "no stale 1.9.8 pin"
guard, and the `required_version` floor-compatibility assertion described
above.

`make ci`-relevant checks: `bats tests/ci-tool-pins.bats` (8/8 ok),
`scripts/lint.sh` clean, `scripts/ci-parity-check.sh` green (no gate wiring
touched, only a tool-version pin).

This closes out the cycle-7 CI-tool-pin sweep — all three pins found behind
(kubeconform, kustomize, terraform) are now current as of 2026-07-21.

## PR

(filled in after PR creation)
