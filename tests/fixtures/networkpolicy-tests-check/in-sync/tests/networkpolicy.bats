#!/usr/bin/env bats
# Golden fixture: baseline-only monolith (shared templates, $POLICIES only).
setup() { load lib/networkpolicy-paths; }

# --- Shared baseline templates -----------------------------------------------
@test "default-deny.yaml exists" {
  [ -f "$POLICIES/default-deny.yaml" ]
}
