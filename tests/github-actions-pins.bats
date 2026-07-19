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
