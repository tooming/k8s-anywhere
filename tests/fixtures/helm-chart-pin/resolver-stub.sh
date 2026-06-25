#!/usr/bin/env bash
# Offline resolver stub for helm-chart-pin-check.sh tests (CHARTPIN_RESOLVER seam).
# Maps a pin to a deterministic verdict WITHOUT touching the network, so the bats
# tests exercise the script's enumeration/classification/exit logic, not helm itself
# (helm's real "not found" vs "cannot be reached" strings are verified by hand).
#   args: <repoURL> <chart> <version>  ->  prints OK | MISSING | UNREACHABLE | OCI
set -uo pipefail
repo="$1"; ver="$3"
case "$repo" in
  http://*|https://*) ;;
  *) echo OCI; exit 0 ;;          # non-http repoURL == OCI registry
esac
case "$repo" in *unreachable*) echo UNREACHABLE; exit 0 ;; esac
case "$ver" in *-missing) echo MISSING; exit 0 ;; esac
echo OK
