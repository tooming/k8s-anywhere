#!/usr/bin/env bats
# Clusterless structural + functional tests for scripts/lib/kctx.sh — the
# shared KCTX-aware kubectl wrapper extracted from byte-identical inline
# copies in scripts/cosign-bootstrap.sh, scripts/dr-verify.sh,
# scripts/garage-bootstrap.sh, scripts/lab-health-check.sh, and
# scripts/vault-bootstrap.sh (scripts/grafana-gitsync-bootstrap.sh, a sixth
# caller, was removed 2026-09-06 alongside Grafana itself, ADR-0041 —
# janitor cleanup, mirrors the earlier scripts/lib/colors.sh / scripts/lib/
# budget-check.sh / scripts/lib/confirm.sh / scripts/lib/canary-probe.sh
# extractions). Guards against the duplicate pattern creeping back in as
# new bootstrap/check scripts get added.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "scripts/lib/kctx.sh exists" {
  [ -f "$REPO/scripts/lib/kctx.sh" ]
}

@test "kctx.sh defines KCTX (defaulted to empty) and a kubectl() wrapper" {
  run grep -q '^KCTX="\${KCTX:-}"' "$REPO/scripts/lib/kctx.sh"
  [ "$status" -eq 0 ]
  run grep -q '^kubectl()' "$REPO/scripts/lib/kctx.sh"
  [ "$status" -eq 0 ]
}

@test "kctx.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$REPO/scripts/lib/kctx.sh"
  [ "$status" -eq 0 ]
}

setup_fake_kubectl_on_path() {
  # kctx.sh's kubectl() calls `command kubectl`, which bypasses shell
  # functions/aliases and does a real PATH lookup — so a fake must be an
  # executable on PATH, not a shadowing shell function, to actually be
  # invoked. Stays clusterless: no real kubeconfig/cluster needed.
  FAKE_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$FAKE_BIN"
  cat > "$FAKE_BIN/kubectl" <<'FAKE'
#!/usr/bin/env bash
echo "REAL:$*"
FAKE
  chmod +x "$FAKE_BIN/kubectl"
}

@test "kubectl(): passes through to the real binary unchanged when KCTX is unset" {
  setup_fake_kubectl_on_path
  run env PATH="$FAKE_BIN:$PATH" bash -c '
    source "'"$REPO"'/scripts/lib/kctx.sh"
    kubectl get pods -n capstone
  '
  [ "$status" -eq 0 ]
  [ "$output" = "REAL:get pods -n capstone" ]
}

@test "kubectl(): injects --context when KCTX is set" {
  setup_fake_kubectl_on_path
  run env PATH="$FAKE_BIN:$PATH" KCTX=k3d-k8s-lab-green bash -c '
    source "'"$REPO"'/scripts/lib/kctx.sh"
    kubectl get pods -n capstone
  '
  [ "$status" -eq 0 ]
  [ "$output" = "REAL:--context k3d-k8s-lab-green get pods -n capstone" ]
}

# --- recurrence guard: no script re-inlines the duplicated pattern ----------
# scripts/*.sh only (not scripts/lib/*.sh, which is where the shared copy
# legitimately lives) — mirrors the non-recursive glob budget-check-lib.bats
# uses for the same reason.
@test "no script under scripts/*.sh re-inlines the KCTX/kubectl() wrapper pattern (source lib/kctx.sh instead)" {
  run grep -l '^kubectl() {' "$REPO"/scripts/*.sh
  [ "$status" -ne 0 ]
}

@test "all five known callers source lib/kctx.sh" {
  for f in cosign-bootstrap.sh dr-verify.sh garage-bootstrap.sh \
    lab-health-check.sh vault-bootstrap.sh; do
    run grep -q 'lib/kctx.sh' "$REPO/scripts/$f"
    [ "$status" -eq 0 ]
  done
}
