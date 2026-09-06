#!/usr/bin/env bash
# SessionStart hook: install `shellcheck` and `yamllint` (the tools scripts/lint.sh
# needs) if either is missing, so a remote/autonomous session's own `make ci`
# actually exercises the `lint` gate instead of silently soft-skipping it.
#
# Same footgun class as scripts/ensure-bats-hook.sh (see that script's own header
# comment for the original finding, 2026-09-06): scripts/lint.sh deliberately
# soft-skips (exit 0) each tool that's missing and CI!=true — a fair convenience
# for a human contributor without them installed. But an autonomous executor
# session's *entire* self-review is `make ci` (per executor.prompt.md,
# WAYS-OF-WORKING.md §0.1's self-merge model) — there is no separate human
# reviewer to catch what a locally green-but-actually-skipped `make ci` missed.
# Found live 2026-09-06 (same session as the bats fix): neither `shellcheck` nor
# `yamllint` was installed in this sandbox either, so every shell-script/YAML lint
# finding in this session's own diffs would have gone unchecked locally the same
# way the bats unit-test gate did.
#
# Best-effort only: never blocks or fails the session. If `apt-get` isn't
# available, there's no network, or the session lacks package-install
# permissions, this silently no-ops (same behavior as before this hook existed)
# rather than erroring out.
set -uo pipefail

install_if_missing() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    echo "$tool already installed ($(command -v "$tool")) — make ci's lint step will check it for real"
    return 0
  fi
  if command -v apt-get >/dev/null 2>&1 && apt-get install -y "$tool" >/dev/null 2>&1; then
    echo "$tool installed — make ci's lint step will check it for real this session"
    return 0
  fi
  echo "$tool still not installed (no apt-get, no network, or no install permission) — make ci will soft-skip this part of the lint step locally; the real backstop remains GitHub Actions' ci.yml"
  return 0
}

install_if_missing shellcheck
install_if_missing yamllint
exit 0
