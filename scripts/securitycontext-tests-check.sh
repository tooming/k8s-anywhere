#!/usr/bin/env bash
# securitycontext test drift check: tests/securitycontext.bats is FROZEN. New
# per-namespace / per-scope security-context (PSS) tests must go in their own
# tests/securitycontext-<scope>.bats file, NEVER appended to the shared monolith.
#
# Why: two parallel PSS fan-out PRs both appending a per-namespace @test block to
# the monolith's EOF (identical trailing `[ "$status" -eq 0 ]` / `}` context) is an
# unmergeable collision — it happened with #238 (external-secrets) vs #239
# (envoy-gateway-system). One scope = one file = no shared append anchor, so new
# files never conflict. This flags any change to the monolith's @test set
# mechanically, mirroring the readme-check / roadmap-check drift guards.
#
# Runs in CI (the 'drift' gates) and as a PostToolUse hook. Exit 0 = clean; 1 = drift.
# Intentional renames/edits to existing monolith tests: run `make securitycontext-tests-mark`.
# Shared check logic lives in scripts/lib/frozen-monolith-check.sh.
set -uo pipefail
# ROOT defaults to the repo; tests point SECCTX_TESTS_ROOT at a fixture tree.
ROOT="${SECCTX_TESTS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/frozen-monolith-check.sh"

frozen_monolith_check \
  "$ROOT/tests/securitycontext.bats" \
  "$ROOT/tests/.securitycontext-titles" \
  "securitycontext-tests-mark" \
  "tests/securitycontext-<scope>.bats" \
  "tests/securitycontext.bats"
exit "$?"
