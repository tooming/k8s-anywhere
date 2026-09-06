#!/usr/bin/env bash
# SessionStart hook: install kustomize/terraform/tflint/kubeconform (the tools
# scripts/validate-kustomize.sh, scripts/validate-terraform.sh, and
# scripts/validate-manifests.sh need) if missing, so a remote/autonomous
# session's own `make ci` actually exercises those gates instead of silently
# soft-skipping them.
#
# Same footgun class as scripts/ensure-bats-hook.sh and
# scripts/ensure-lint-tools-hook.sh (see their own header comments for the
# original findings, 2026-09-06): each of these validate-*.sh scripts
# deliberately soft-skips (exit 0) when its tool is missing and CI!=true — a
# fair convenience for a human contributor without it installed. But an
# autonomous executor session's *entire* self-review is `make ci` (per
# executor.prompt.md, WAYS-OF-WORKING.md §0.1's self-merge model) — there is
# no separate human reviewer to catch what a locally green-but-actually-skipped
# `make ci` missed. None of kustomize/terraform/tflint/kubeconform was
# installed in this sandbox either, so all three of validate-kustomize.sh's,
# validate-terraform.sh's, and validate-manifests.sh's real checks had been
# silently skipped the entire run, on every prior PR this session opened.
#
# Versions are pinned to match .github/workflows/ci.yml's own pins exactly, so
# a local pass means the same thing CI's pass means (not just "some version
# happened to work"). Re-check ci.yml's pins if this drifts.
#
# helm is deliberately NOT covered here: its official binaries are hosted
# exclusively on get.helm.sh (verified: even its GitHub release pages link
# there, not to a GitHub-hosted release asset), and that host is blocked by
# this sandbox's egress proxy (organization policy) — confirmed by testing the
# official get-helm-3 install script live, which failed with
# "connect_rejected". scripts/validate-kustomize.sh no longer needs helm as of
# 2026-09-06 (ADR-0040's Envoy Gateway removal deleted the only kustomization
# that vendored a Helm chart via the helmCharts inflator), so this only leaves
# scripts/helm-chart-pin-check.sh's chart-pin verification unexercisable
# locally in this specific sandbox — that gate's own soft-skip message already
# says so, and GitHub Actions' ci.yml remains the real backstop for it.
#
# Best-effort only: never blocks or fails the session. If a download fails
# (no network, egress-proxy block, GitHub/HashiCorp releases unreachable), this
# silently no-ops for that tool (same behavior as before this hook existed)
# rather than erroring out.
set -uo pipefail

KUSTOMIZE_VERSION="v5.8.1"   # matches .github/workflows/ci.yml's kustomize job
KUBECONFORM_VERSION="v0.8.0" # matches .github/workflows/ci.yml's manifests job
TERRAFORM_VERSION="1.16.1"   # matches .github/workflows/ci.yml's terraform job

install_kustomize() {
  command -v kustomize >/dev/null 2>&1 && { echo "kustomize already installed ($(command -v kustomize))"; return 0; }
  local tmp; tmp="$(mktemp -d)" || return 0
  if curl -fsSL -m 60 -o "$tmp/kustomize.tar.gz" \
      "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
      && tar -xzf "$tmp/kustomize.tar.gz" -C "$tmp" kustomize \
      && install "$tmp/kustomize" /usr/local/bin/kustomize; then
    echo "kustomize $KUSTOMIZE_VERSION installed — make ci's kustomize step will run for real this session"
  else
    echo "kustomize install failed (no network, or GitHub releases unreachable) — make ci will soft-skip this step locally"
  fi
  rm -rf "$tmp"
}

install_kubeconform() {
  command -v kubeconform >/dev/null 2>&1 && { echo "kubeconform already installed ($(command -v kubeconform))"; return 0; }
  local tmp; tmp="$(mktemp -d)" || return 0
  if curl -fsSL -m 60 -o "$tmp/kc.tar.gz" \
      "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
      && tar -xzf "$tmp/kc.tar.gz" -C "$tmp" kubeconform \
      && install "$tmp/kubeconform" /usr/local/bin/kubeconform; then
    echo "kubeconform $KUBECONFORM_VERSION installed — make ci's manifests step will run for real this session"
  else
    echo "kubeconform install failed (no network, or GitHub releases unreachable) — make ci will soft-skip this step locally"
  fi
  rm -rf "$tmp"
}

install_terraform() {
  command -v terraform >/dev/null 2>&1 && { echo "terraform already installed ($(command -v terraform))"; return 0; }
  local tmp; tmp="$(mktemp -d)" || return 0
  if curl -fsSL -m 90 -o "$tmp/terraform.zip" \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
      && (cd "$tmp" && unzip -q terraform.zip) \
      && install "$tmp/terraform" /usr/local/bin/terraform; then
    echo "terraform $TERRAFORM_VERSION installed — make ci's terraform step will run for real this session"
  else
    echo "terraform install failed (no network, or releases.hashicorp.com unreachable) — make ci will soft-skip this step locally"
  fi
  rm -rf "$tmp"
}

install_tflint() {
  command -v tflint >/dev/null 2>&1 && { echo "tflint already installed ($(command -v tflint))"; return 0; }
  # Mirrors .github/workflows/ci.yml's own install method exactly (the
  # upstream script itself warns it may be retired, but ci.yml still relies on
  # it as of this writing — if it ever stops working there, update both).
  if curl -fsSL -m 60 https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh 2>/dev/null | bash >/dev/null 2>&1; then
    echo "tflint installed — make ci's terraform step will lint for real this session"
  else
    echo "tflint install failed (no network, or the upstream install script is unreachable/retired) — make ci will soft-skip this part locally"
  fi
}

install_kustomize
install_kubeconform
install_terraform
install_tflint
echo "helm intentionally skipped — get.helm.sh is blocked by this sandbox's egress proxy; validate-kustomize.sh no longer needs it (ADR-0040), only helm-chart-pin-check.sh's local run is affected"
exit 0
