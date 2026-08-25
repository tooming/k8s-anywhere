#!/usr/bin/env bats
# RFC #1340 / ROADMAP "GitHub->Forgejo pull-based, fast-forward-only sync
# workflow" item: .forgejo/workflows/sync-from-github.yml must exist and carry
# the exact shape the RFC's binding Decision specifies -- same clusterless,
# structural (grep-based file-content) pattern tests/forgejo-ci.bats already
# uses for build-sign-push.yml, no live Forgejo/forgejo-runner instance needed
# to confirm the file is shaped correctly.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WF="$REPO/.forgejo/workflows/sync-from-github.yml"
}

@test "sync-from-github.yml exists under .forgejo/workflows/" {
  [ -f "$WF" ]
}

@test "sync-from-github.yml is triggered on a schedule, not push" {
  grep -q '^on:$' "$WF"
  grep -q '^  schedule:$' "$WF"
  run grep -A3 '^on:$' "$WF"
  [[ "$output" != *"push:"* ]]
}

@test "sync-from-github.yml sets an explicit timeout-minutes" {
  grep -q 'timeout-minutes:' "$WF"
}

@test "sync-from-github.yml fetches GitHub's main over plain HTTPS (no credential in the URL)" {
  run grep -oE 'git fetch https://github\.com/[^ ]+' "$WF"
  [ "$status" -eq 0 ]
  [[ "$output" != *"@github.com"* ]]
}

@test "sync-from-github.yml merges fast-forward-only (--ff-only present)" {
  grep -q -- '--ff-only' "$WF"
}

@test "sync-from-github.yml never force-pushes or force-merges" {
  # No --force/-f flag anywhere in the file, on any git command -- the whole
  # point of the --ff-only design is that this job can NEVER discard either
  # side's history (RFC #1340's binding Decision, ADR-0004).
  run grep -E '\-\-force\b|(^|[^A-Za-z0-9_-])-f\b' "$WF"
  [ "$status" -eq 1 ]
}

@test "sync-from-github.yml references CHECKOUT_TOKEN (no plaintext credential)" {
  grep -q 'secrets.CHECKOUT_TOKEN' "$WF"
}

@test "sync-from-github.yml contains no hardcoded credential values" {
  run grep -E '(CHECKOUT_TOKEN):\s*[^$ ]' "$WF"
  [ "$status" -eq 1 ]
}

@test "sync-from-github.yml sources the shared retry_cmd helper (Colima-VM egress flakiness class)" {
  grep -q 'scripts/lib/retry_cmd.sh' "$WF"
}

@test "sync-from-github.yml pushes to Forgejo's own remote, not GitHub" {
  run grep -q 'git push "http://lab-admin' "$WF"
  [ "$status" -eq 0 ]
}

@test "sync-from-github.yml does not name the rejected git host (ADR-0035 guard parity)" {
  ! grep -qi 'gitlab' "$WF"
}

@test "sync-from-github.yml does not declare a NetworkPolicy (the Forgejo runner is docker-compose, not in-cluster)" {
  # Structural guard against re-adding the inapplicable NetworkPolicy deliverable
  # RFC #1340's own text originally specified -- see sync-from-github.yml's own
  # header comment for why that was corrected. Checks for an actual `kind:`
  # declaration, not the word "NetworkPolicy" anywhere (the workflow's own
  # explanatory comment legitimately mentions it by name).
  ! grep -qE '^kind: NetworkPolicy' "$WF"
}
