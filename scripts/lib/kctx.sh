# Shared KCTX-aware kubectl wrapper — sourced, not executed.
# scripts/dr-verify.sh, scripts/lab-health-check.sh, and
# scripts/ondemand-budget-check.sh each hand-rolled a byte-identical copy of
# this two-line pair; consolidated here so a future format tweak only needs
# one edit, mirroring the colors.sh / budget-check.sh / confirm.sh extraction
# precedent. Past consumers, each removed alongside the component it
# bootstrapped, no replacement: scripts/cosign-bootstrap.sh (Kyverno,
# ADR-0019), scripts/garage-bootstrap.sh (Garage, ADR-0002),
# scripts/grafana-gitsync-bootstrap.sh (observability stack, ADR-0041),
# scripts/vault-bootstrap.sh (Vault, ADR-0042).
#
# KCTX optionally targets a specific cluster context (e.g.
# KCTX=k3d-k8s-lab-green) — unset (the default) means "current context".
# Every `kubectl` call a caller makes after sourcing this file transparently
# picks up `--context "$KCTX"` when set.
KCTX="${KCTX:-}"
kubectl() { command kubectl ${KCTX:+--context "$KCTX"} "$@"; }
