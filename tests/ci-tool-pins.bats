#!/usr/bin/env bats
# Clusterless structural tests: the CLI tools .github/workflows/ci.yml installs
# by pinned version (kubeconform, kustomize, terraform) — as opposed to the
# `uses:` GitHub Actions steps, which tests/github-actions-pins.bats already
# covers. Without this, a version bump could edit the download URL but forget
# the cache key (or vice versa), silently drifting the two out of sync.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CI_YML="$REPO/.github/workflows/ci.yml"
}

@test "kubeconform is pinned to v0.8.0 (upgrade-drafter, 2026-07-21)" {
  grep -q 'yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz' "$CI_YML"
}

@test "kubeconform schema cache key matches the pinned kubeconform version" {
  grep -q 'key: kubeconform-schemas-v0.8.0-k8s1.30.0-' "$CI_YML"
  grep -q 'kubeconform-schemas-v0.8.0-k8s1.30.0-$' "$CI_YML"
}

@test "no workflow references the pre-bump kubeconform v0.6.7 pin or cache key" {
  ! grep -q 'kubeconform/releases/download/v0.6.7' "$CI_YML"
  ! grep -q 'kubeconform-schemas-v0.6.7' "$CI_YML"
}

@test "kustomize is pinned to v5.8.1 (upgrade-drafter, 2026-07-21)" {
  grep -q 'kustomize/releases/download/kustomize%2Fv5.8.1/kustomize_v5.8.1_linux_amd64.tar.gz' "$CI_YML"
}

@test "no workflow references the pre-bump kustomize v5.4.3 pin" {
  ! grep -q 'kustomize%2Fv5.4.3' "$CI_YML"
}

@test "terraform is pinned to 1.15.8 via hashicorp/setup-terraform (upgrade-drafter, 2026-07-21)" {
  grep -q 'terraform_version: "1.15.8"' "$CI_YML"
}

@test "no workflow references the pre-bump terraform 1.9.8 pin" {
  ! grep -q 'terraform_version: "1.9.8"' "$CI_YML"
}

@test "every infra/ terraform module's required_version floor still admits the pinned CI terraform version" {
  # required_version is a ">= X.Y" floor (never an exact pin), so a CI terraform
  # bump only needs to stay >= that floor, not match it exactly.
  for f in "$REPO"/infra/modules/*/main.tf; do
    grep -q 'required_version = ">= 1.5"' "$f" || { echo "missing/changed floor in $f"; return 1; }
  done
}
