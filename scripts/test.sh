#!/usr/bin/env bash
# Run the clusterless unit tests (bats) under tests/. These exercise pure logic
# only — probe math, destructive-script guards, drift detectors — so they need
# no cluster, network, or Colima. Fast enough to run on every commit / in CI.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

if ! command -v bats >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then printf '  %s✗%s bats not installed (required in CI)\n' "$R" "$Z"; exit 1; fi
  printf '  %s·%s bats not installed — skipping unit tests (install: apt-get install bats)\n' "$Y" "$Z"; exit 0
fi

exec bats tests/
