#!/usr/bin/env bash
# Fake `helm` binary for the "v-prefix" fixture: exercises resolve_builtin's real
# jq-based comparison (HELM_BIN seam) without touching the network or the real helm
# CLI. Mimics the one real behavior this test cares about: a chart repo whose index
# lists versions with a "v" prefix (e.g. jetstack/cert-manager's "v1.21.1"), where
# `helm search repo --version <query>` still resolves a bare "<query>" against it and
# echoes the index's own v-prefixed string back in the JSON `.version` field.
set -uo pipefail
case "$1" in
  repo)
    case "$2" in
      add) exit 0 ;;
    esac
    ;;
  search)
    # search repo <alias>/<chart> --version <ver> -o json
    name="$3"
    chart="${name#*/}"
    echo "[{\"name\":\"${name}\",\"version\":\"v1.0.0\",\"app_version\":\"v1.0.0\",\"description\":\"fake ${chart}\"}]"
    exit 0
    ;;
esac
exit 0
