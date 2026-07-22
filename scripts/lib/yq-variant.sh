# Shared mikefarah/yq variant guard — sourced, not executed.
#
# scripts/helm-chart-pin-check.sh, scripts/argocd-crd-ssa-check.sh, and
# scripts/rollouts-plugin-list-check.sh all rely on mikefarah/yq-only features
# (`eval-all`, `documentIndex`, `| tag`) to enumerate/inspect Applications. Other
# `yq` implementations on PATH (e.g. python-yq, a jq wrapper) don't recognise
# `eval-all` as a subcommand and exit non-zero — which these scripts consume via
# `2>/dev/null` inside a `< <(...)` pipe, so the loop silently sees zero results
# instead of erroring. Each script's own "0 matches" branch then reports a clean
# "nothing to check" — a false pass, not a skip: exactly the class of bug
# tests/lib/yq.bash's yqs() helper (and the cpu_millis regression it documents)
# already fixed for bats tests, recurring here because these three scripts read
# structured multi-field records via `eval-all`/`@tsv` instead of the single
# scalar reads yqs() handles.
#
# require_mikefarah_yq() makes the wrong-variant case loud instead of silent:
# hard-fail in CI (a gate must not silently no-op there), skip with a clear
# message locally — mirrors the missing-tool precedent already used inline in
# these same scripts for absent `helm`/`jq`.
require_mikefarah_yq() {
  local caller="${1:-this check}"
  if ! command -v yq >/dev/null 2>&1; then
    if [ "${CI:-}" = "true" ]; then
      echo "yq not installed (required in CI for $caller)"
      exit 1
    fi
    echo "yq not installed — skipping $caller (install to check locally)"
    exit 0
  fi
  if ! yq --version 2>&1 | grep -qi mikefarah; then
    if [ "${CI:-}" = "true" ]; then
      echo "yq on PATH is not mikefarah/yq (required in CI for $caller — it uses eval-all/documentIndex/tag, which other yq variants silently no-op on)"
      exit 1
    fi
    echo "yq on PATH is not mikefarah/yq — skipping $caller (install https://github.com/mikefarah/yq to check locally; other variants under-report here instead of erroring)"
    exit 0
  fi
}
