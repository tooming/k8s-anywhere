#!/usr/bin/env bash
# SessionStart hook: install `bats` (the unit-test runner `make ci`/`scripts/test.sh`
# needs) if it isn't already on PATH, so a remote/autonomous session's own `make ci`
# actually exercises tests/*.bats instead of silently skipping the whole unit-test
# gate.
#
# Why this matters here specifically (not just "nice to have locally"): scripts/test.sh
# deliberately soft-skips (exit 0) when `bats` is missing and CI!=true — a fair
# convenience for a human contributor without it installed. But an autonomous executor
# session's *entire* self-review is `make ci` (per executor.prompt.md, WAYS-OF-WORKING.md
# §0.1's self-merge model) — there is no separate human reviewer to catch what a locally
# green-but-actually-skipped `make ci` missed. Found live 2026-09-06: two upgrade/*
# version-bump PRs in the same run (`upgrade/kro-0.9.3-to-0.9.4`,
# `upgrade/grafana-...`) both passed a local `make ci` that silently skipped
# tests/securitycontext-kro.bats's hard-coded "chart pin is exactly <old version>"
# assertion (bats wasn't installed in that sandbox), then failed CI on push — caught
# and fixed reactively both times, but a `make ci` that quietly skips its own unit
# gate in exactly the environment with no other backstop is a real recurrence risk,
# not a one-off. This hook removes the footgun by construction: best-effort install at
# session start, so `command -v bats` succeeds and scripts/test.sh's existing
# CI-vs-local branch naturally takes the "run the real suite" path for the rest of the
# session — no change needed to test.sh's own local/CI distinction.
#
# Best-effort only: never blocks or fails the session. If `apt-get` isn't available,
# there's no network, or the session lacks package-install permissions, this silently
# no-ops (same behavior as before this hook existed) rather than erroring out.
set -uo pipefail

if command -v bats >/dev/null 2>&1; then
  echo "bats already installed ($(command -v bats)) — make ci's unit-test step will run for real"
  exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  if apt-get install -y bats >/dev/null 2>&1; then
    echo "bats installed — make ci's unit-test step will run for real this session"
    exit 0
  fi
fi

echo "bats still not installed (no apt-get, no network, or no install permission) — make ci will soft-skip the unit-test step locally; the real backstop remains GitHub Actions' ci.yml"
exit 0
