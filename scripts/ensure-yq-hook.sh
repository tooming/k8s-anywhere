#!/usr/bin/env bash
# SessionStart hook: install mikefarah/yq to /usr/local/bin/yq (ahead of
# /usr/bin on PATH) if the yq already on PATH isn't the mikefarah variant, so
# make ci's mikefarah-yq-only gates actually run instead of silently
# soft-skipping in a remote/autonomous session with no other backstop.
#
# Same footgun class as scripts/ensure-bats-hook.sh,
# scripts/ensure-lint-tools-hook.sh, and scripts/ensure-manifest-tools-hook.sh
# (see their own header comments for the original findings, 2026-09-06):
# scripts/lib/yq-variant.sh's require_mikefarah_yq() deliberately soft-skips
# (exit 0) when the yq on PATH isn't mikefarah's build and CI!=true -- a fair
# convenience for a human contributor without it installed. But an autonomous
# executor session's *entire* self-review is `make ci` (per
# executor.prompt.md, WAYS-OF-WORKING.md §0.1's self-merge model) -- there is
# no separate human reviewer to catch what a locally green-but-actually-skipped
# `make ci` missed.
#
# Found live 2026-09-06 (same run as the three sibling fixes): this sandbox's
# apt-installed `/usr/bin/yq` is the Python/jq-wrapper variant (`yq 0.0.0`,
# no "mikefarah" in its version string), not mikefarah/yq -- so
# tests/ingressroute-web-tls-check.bats's own "fails when one object combines
# web + tls" assertion failed locally (the check script silently skipped
# instead of detecting the violation) even though the identical commit's real
# GitHub Actions run reported success -- confirmed by checking .github/
# workflows/ci.yml's own "Install yq + helm" step, which installs this exact
# mikefarah/yq binary to this exact path already. This is a local-sandbox
# validation gap only, not a bug on main.
#
# Uses the identical install command .github/workflows/ci.yml's own "Install
# yq + helm" step uses (minus `sudo`, since this session already runs as
# root), so a local pass means the same thing CI's pass means.
#
# Best-effort only: never blocks or fails the session. If the download fails
# (no network, egress-proxy block, GitHub releases unreachable), this
# silently no-ops (same behavior as before this hook existed) rather than
# erroring out.
set -uo pipefail

if command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -qi mikefarah; then
  echo "mikefarah/yq already on PATH ($(command -v yq)) — make ci's mikefarah-yq-only steps will run for real"
  exit 0
fi

if curl -fsSL -m 60 -o /usr/local/bin/yq \
    "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq \
    && yq --version 2>&1 | grep -qi mikefarah; then
  echo "mikefarah/yq installed to /usr/local/bin/yq (takes precedence over any other yq later on PATH) — make ci's mikefarah-yq-only steps will run for real this session"
else
  echo "mikefarah/yq install failed (no network, or GitHub releases unreachable) — make ci will soft-skip its mikefarah-yq-only steps locally; the real backstop remains GitHub Actions' ci.yml, which installs it the same way"
fi
exit 0
