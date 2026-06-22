#!/usr/bin/env bats
# Drift fixture: a per-namespace overlay test leaked back into the monolith.
setup() { load lib/networkpolicy-paths; }

# --- Shared baseline templates -----------------------------------------------
@test "default-deny.yaml exists" {
  [ -f "$POLICIES/default-deny.yaml" ]
}

# --- data namespace overlay --------------------------------------------------
@test "data overlay kustomization exists" {
  [ -f "$DATA_NP/kustomization.yaml" ]
}
