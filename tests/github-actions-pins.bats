#!/usr/bin/env bats
# Clusterless structural tests: every `uses:` step across .github/workflows/*.yml
# must be pinned to a full 40-character commit SHA, not a floating tag
# (@v4, @main, @latest) -- supply-chain hardening (GitHub's own security
# hardening guidance; a floating major tag can be re-pointed by the action's
# publisher, unlike a SHA). A trailing `# vX.Y.Z` comment keeps the pinned
# version human-readable. Chore cleanup: janitor fallback role.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WORKFLOWS="$REPO/.github/workflows"
}

@test "every 'uses:' step across .github/workflows/*.yml is pinned to a full commit SHA" {
  hits=""
  for f in "$WORKFLOWS"/*.yml; do
    while IFS= read -r line; do
      ref="${line#*uses: }"
      ref="${ref%% *}"
      sha="${ref#*@}"
      if ! [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then
        hits="$hits\n$f: $line"
      fi
    done < <(grep -E '^\s*(- )?uses: ' "$f")
  done
  [ -z "$hits" ] || { echo -e "$hits"; false; }
}

@test "every SHA-pinned 'uses:' step carries a trailing '# vX.Y.Z' human-readable comment" {
  hits=""
  for f in "$WORKFLOWS"/*.yml; do
    while IFS= read -r line; do
      echo "$line" | grep -qE '# v[0-9]+\.[0-9]+\.[0-9]+\s*$' || hits="$hits\n$f: $line"
    done < <(grep -E '^\s*(- )?uses: [^ ]+@[0-9a-f]{40}' "$f")
  done
  [ -z "$hits" ] || { echo -e "$hits"; false; }
}

# RFC #611 (Node-24 major bumps): pins the exact post-bump SHA/version for each
# of the four actions, so a future edit can't silently regress one back to a
# stale Node-20-era major. Mirrors this repo's other per-component pin-assertion
# pattern (argo-rollouts.bats, cilium.bats, k3s-version-pin.bats).
@test "actions/checkout is pinned to v7.0.0 (RFC #611)" {
  grep -rq 'actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0' "$WORKFLOWS"
}

@test "actions/cache is pinned to v6.1.0 (RFC #611)" {
  grep -rq 'actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0' "$WORKFLOWS"
}

@test "actions/github-script is pinned to v9.0.0 (RFC #611)" {
  grep -rq 'actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3 # v9.0.0' "$WORKFLOWS"
}

@test "hashicorp/setup-terraform is pinned to v4.0.1 (RFC #611)" {
  grep -rq 'hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1' "$WORKFLOWS"
}

@test "no workflow references a pre-RFC-#611 Node-20-era action pin" {
  hits=""
  for stale in \
    'actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5' \
    'actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830' \
    'actions/github-script@f28e40c7f34bde8b3046d885e986cb6290c5673b' \
    'hashicorp/setup-terraform@b9cd54a3c349d3f38e8881555d616ced269862dd'; do
    grep -rl "$stale" "$WORKFLOWS" >/dev/null 2>&1 && hits="$hits\n$stale"
  done
  [ -z "$hits" ] || { echo -e "$hits"; false; }
}
