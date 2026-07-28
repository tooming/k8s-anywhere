#!/usr/bin/env bats
# Recurrence guard for issue #791 (architect decision, 2026-07-28): the argocd and
# oracle-k3s-cluster modules' `~>` pessimistic provider constraints had silently
# locked out a whole major version line each (hashicorp/helm stuck on 2.x,
# oracle/oci stuck on 7.x) with no CI signal, since a pessimistic constraint never
# fails `terraform validate` on its own — it just quietly never picks up the newer
# major. This asserts the widened constraints landed by that decision stay in
# place, so a future accidental narrowing (e.g. a copy-pasted older module) is
# caught mechanically instead of silently reintroducing the same gap.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

@test "argocd module's hashicorp/helm provider constraint allows the 3.x line" {
  run grep -q 'version = "~> 3.0"' "$REPO/infra/modules/argocd/main.tf"
  [ "$status" -eq 0 ]
}

@test "oracle-k3s-cluster module's oracle/oci provider constraint allows the 8.x line" {
  run grep -q 'version = "~> 8.0"' "$REPO/infra/modules/oracle-k3s-cluster/main.tf"
  [ "$status" -eq 0 ]
}
