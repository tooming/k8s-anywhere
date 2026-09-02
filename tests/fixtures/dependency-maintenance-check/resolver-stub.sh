#!/usr/bin/env bash
# Offline resolver stub for dependency-maintenance-check.sh's bats coverage — prints
# a deterministic "<days-since-last-commit>" or "UNREACHABLE" for "<owner> <repo>",
# so the suite never hits the network. Mirrors the helm-chart-pin-check.bats
# CHARTPIN_RESOLVER pattern.
case "$1/$2" in
  example-org/fresh-tool) echo 5 ;;
  example-org/stale-tool) echo 500 ;;
  example-org/gone-tool)  echo UNREACHABLE ;;
  *) echo UNREACHABLE ;;
esac
