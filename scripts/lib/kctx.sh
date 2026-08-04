# Shared KCTX-aware kubectl wrapper — sourced, not executed.
# scripts/cosign-bootstrap.sh, scripts/dr-verify.sh, scripts/garage-bootstrap.sh,
# scripts/grafana-gitsync-bootstrap.sh, scripts/lab-health-check.sh, and
# scripts/vault-bootstrap.sh each hand-rolled a byte-identical copy of this
# two-line pair; consolidated here so a future format tweak only needs one
# edit, mirroring the colors.sh / budget-check.sh / confirm.sh extraction
# precedent.
#
# KCTX optionally targets a specific cluster context (e.g.
# KCTX=k3d-k8s-lab-green) — unset (the default) means "current context".
# Every `kubectl` call a caller makes after sourcing this file transparently
# picks up `--context "$KCTX"` when set.
KCTX="${KCTX:-}"
kubectl() { command kubectl ${KCTX:+--context "$KCTX"} "$@"; }
