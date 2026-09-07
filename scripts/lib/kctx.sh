# Shared KCTX-aware kubectl wrapper — sourced, not executed.
# scripts/dr-verify.sh, scripts/lab-health-check.sh,
# scripts/ondemand-budget-check.sh, and scripts/vault-bootstrap.sh each
# hand-rolled a byte-identical copy of this two-line pair
# (scripts/cosign-bootstrap.sh and scripts/garage-bootstrap.sh were two more
# consumers, both removed 2026-09-07 in the same aggressive-simplification
# change (#1497) that dropped Garage and the container-signing pipeline
# entirely; scripts/grafana-gitsync-bootstrap.sh was another, removed
# 2026-09-06 alongside Grafana's native Git Sync, ADR-0041);
# consolidated here so a future format tweak only needs one edit, mirroring
# the colors.sh / budget-check.sh / confirm.sh extraction precedent.
#
# KCTX optionally targets a specific cluster context (e.g.
# KCTX=k3d-k8s-lab-green) — unset (the default) means "current context".
# Every `kubectl` call a caller makes after sourcing this file transparently
# picks up `--context "$KCTX"` when set.
KCTX="${KCTX:-}"
kubectl() { command kubectl ${KCTX:+--context "$KCTX"} "$@"; }
