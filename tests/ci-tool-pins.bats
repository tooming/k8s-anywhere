#!/usr/bin/env bats
# Clusterless structural tests: the CLI tools .github/workflows/ci.yml installs
# by pinned version (kubeconform, kustomize, terraform) — as opposed to the
# `uses:` GitHub Actions steps, which tests/github-actions-pins.bats already
# covers. Without this, a version bump could edit the download URL but forget
# the cache key (or vice versa), silently drifting the two out of sync.
#
# 2026-07-28: the "no workflow references the pre-bump ... pin" checks below
# used to grep only ci.yml — which is exactly how oracle-cluster-apply.yml and
# oracle-cluster-apply-retry.yml silently kept `terraform_version: "1.9.8"` and
# terragrunt v0.67.0 for a week after ci.yml bumped to 1.15.8, despite
# oracle-cluster-apply-retry.yml's own comment declaring intent to "keep in
# sync with oracle-cluster-apply.yml / ci.yml". Broadened to check every
# workflow file, closing the exact gap that let that drift go undetected.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  CI_YML="$REPO/.github/workflows/ci.yml"
  WORKFLOWS="$REPO/.github/workflows"
  ORACLE_APPLY="$WORKFLOWS/oracle-cluster-apply.yml"
  ORACLE_RETRY="$WORKFLOWS/oracle-cluster-apply-retry.yml"
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

@test "terraform is pinned to 1.15.9 via hashicorp/setup-terraform (upgrade-drafter, 2026-08-19, CVE-2026-14978)" {
  grep -q 'terraform_version: "1.15.9"' "$CI_YML"
}

@test "no workflow references the pre-bump terraform 1.9.8 pin" {
  ! grep -rq 'terraform_version: "1.9.8"' "$WORKFLOWS"/*.yml
}

@test "no workflow references the pre-bump terraform 1.15.8 pin" {
  ! grep -rq 'terraform_version: "1.15.8"' "$WORKFLOWS"/*.yml
}

@test "every infra/ terraform module's required_version floor still admits the pinned CI terraform version" {
  # required_version is a ">= X.Y" floor (never an exact pin), so a CI terraform
  # bump only needs to stay >= that floor, not match it exactly.
  for f in "$REPO"/infra/modules/*/main.tf; do
    grep -q 'required_version = ">= 1.5"' "$f" || { echo "missing/changed floor in $f"; return 1; }
  done
}

# --- oracle-cluster-apply.yml / oracle-cluster-apply-retry.yml tool pins ------

@test "oracle-cluster-apply.yml and oracle-cluster-apply-retry.yml pin terraform_version 1.15.9 (2026-08-19, in sync with ci.yml)" {
  grep -q 'terraform_version: "1.15.9"' "$ORACLE_APPLY"
  grep -q 'terraform_version: "1.15.9"' "$ORACLE_RETRY"
}

@test "oracle-cluster-apply.yml and oracle-cluster-apply-retry.yml pin terragrunt v1.1.1 (2026-07-28)" {
  grep -q 'gruntwork-io/terragrunt/releases/download/v1.1.1/terragrunt_linux_amd64' "$ORACLE_APPLY"
  grep -q 'gruntwork-io/terragrunt/releases/download/v1.1.1/terragrunt_linux_amd64' "$ORACLE_RETRY"
}

@test "no workflow references the pre-bump terragrunt v0.67.0 pin" {
  ! grep -rq 'terragrunt/releases/download/v0.67.0' "$WORKFLOWS"/*.yml
}
