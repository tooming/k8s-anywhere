#!/usr/bin/env bats
# Guard for scripts/check-merged-pr-push.sh — the pre-push hook check that blocks
# pushing more commits onto a branch whose PR is already merged. We stub `gh` via
# GH_BIN so the test is hermetic (no network, no real repo).

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO/scripts/check-merged-pr-push.sh"
  WORK="$(mktemp -d)"
}
teardown() { rm -rf "$WORK"; }

# Write a fake gh that prints the merged-PR count for the requested --head branch.
# It treats any branch containing "merged" as having 1 merged PR, else 0.
make_stub_gh() {
  cat > "$WORK/gh" <<'STUB'
#!/usr/bin/env bash
# crude arg scan for --head <branch>
head=""
prev=""
for a in "$@"; do
  [[ "$prev" == "--head" ]] && head="$a"
  prev="$a"
done
if [[ "$head" == *merged* ]]; then echo 1; else echo 0; fi
STUB
  chmod +x "$WORK/gh"
}

@test "blocks a push to a branch with a merged PR" {
  make_stub_gh
  run env GH_BIN="$WORK/gh" bash "$SCRIPT" auto/already-merged
  [ "$status" -eq 1 ]
  [[ "$output" == *"MERGED pull request"* ]]
}

@test "allows a push to a branch with no merged PR" {
  make_stub_gh
  run env GH_BIN="$WORK/gh" bash "$SCRIPT" auto/active-open
  [ "$status" -eq 0 ]
}

@test "degrades to allow when gh is unavailable" {
  run env GH_BIN="$WORK/definitely-no-such-binary" bash "$SCRIPT" auto/already-merged
  [ "$status" -eq 0 ]
}

@test "degrades to allow when gh errors out" {
  printf '#!/usr/bin/env bash\nexit 3\n' > "$WORK/gh"
  chmod +x "$WORK/gh"
  run env GH_BIN="$WORK/gh" bash "$SCRIPT" auto/already-merged
  [ "$status" -eq 0 ]
}

@test "requires a branch argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}
