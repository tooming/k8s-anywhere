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
