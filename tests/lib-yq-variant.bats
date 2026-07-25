#!/usr/bin/env bats
# Clusterless behavioral tests for scripts/lib/yq-variant.sh's
# require_mikefarah_yq() — the shared guard sourced by
# helm-chart-pin-check.sh, argocd-crd-ssa-check.sh, and
# rollouts-plugin-list-check.sh to hard-fail in CI (rather than silently
# report "0 matches") when the wrong yq implementation is on PATH. Like
# lint.sh before tests/lint-script.bats, this function had zero direct bats
# coverage of its own branches despite gating three CI checks: a regression
# here (e.g. a dropped `${CI:-}` check, or a typo in the mikefarah grep) would
# silently turn all three callers' CI-required hard-fail into an always-green
# skip, exactly the "false pass instead of a skip" class of bug this guard's
# own header comment describes it as fixing.
#
# Mirrors tests/lint-script.bats's shim-PATH pattern: build a PATH with `yq`
# hidden but every other command still resolvable, so the "not installed"
# branch is exercised without breaking bash's own builtins.

setup_file() {
  SHIM="$BATS_FILE_TMPDIR/shim-bin"
  mkdir -p "$SHIM"
  printf '%s' "$PATH" | tr ':' '\n' | while read -r d; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      base="$(basename "$f")"
      [ "$base" = "yq" ] && continue
      [ -e "$SHIM/$base" ] && continue
      ln -s "$f" "$SHIM/$base" 2>/dev/null || true
    done
  done

  # A fake mikefarah/yq and a fake non-mikefarah yq (e.g. kislyuk/python-yq):
  # each only needs to answer --version the way the real binary does, since
  # require_mikefarah_yq() never invokes yq any other way. Built as fakes
  # (not "whatever yq happens to be on the ambient PATH") so these tests are
  # deterministic regardless of what's installed on the machine running
  # them — CI installs the real mikefarah/yq before the test suite runs
  # (.github/workflows/ci.yml), which would otherwise make a
  # PATH="$PATH"-based "wrong variant" test silently pass for the wrong
  # reason there while still working locally, or vice versa.
  MIKEFARAH_SHIM="$BATS_FILE_TMPDIR/mikefarah-bin"
  mkdir -p "$MIKEFARAH_SHIM"
  cat >"$MIKEFARAH_SHIM/yq" <<'EOF'
#!/usr/bin/env bash
echo "yq (https://github.com/mikefarah/yq/) version v4.44.1"
EOF
  chmod +x "$MIKEFARAH_SHIM/yq"

  WRONG_VARIANT_SHIM="$BATS_FILE_TMPDIR/wrong-variant-bin"
  mkdir -p "$WRONG_VARIANT_SHIM"
  cat >"$WRONG_VARIANT_SHIM/yq" <<'EOF'
#!/usr/bin/env bash
echo "yq 3.4.3"
EOF
  chmod +x "$WRONG_VARIANT_SHIM/yq"
}

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LIB="$REPO/scripts/lib/yq-variant.sh"
  STRIPPED_PATH="$BATS_FILE_TMPDIR/shim-bin"
  MIKEFARAH_PATH="$BATS_FILE_TMPDIR/mikefarah-bin:$BATS_FILE_TMPDIR/shim-bin"
  WRONG_VARIANT_PATH="$BATS_FILE_TMPDIR/wrong-variant-bin:$BATS_FILE_TMPDIR/shim-bin"
  source "$LIB"
}

@test "scripts/lib/yq-variant.sh exists" {
  [ -f "$LIB" ]
}

@test "yq-variant.sh is valid, sourceable bash (no syntax errors)" {
  run bash -n "$LIB"
  [ "$status" -eq 0 ]
}

@test "yq-variant.sh defines require_mikefarah_yq()" {
  run grep -q '^require_mikefarah_yq()' "$LIB"
  [ "$status" -eq 0 ]
}

@test "require_mikefarah_yq: skips (exit 0) locally when yq is not installed" {
  run env -u CI PATH="$STRIPPED_PATH" bash -c "source '$LIB'; require_mikefarah_yq 'a check'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yq not installed — skipping a check"* ]]
}

@test "require_mikefarah_yq: FAILS (exit 1) in CI when yq is not installed" {
  run env -u CI PATH="$STRIPPED_PATH" CI=true bash -c "source '$LIB'; require_mikefarah_yq 'a check'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"yq not installed (required in CI for a check)"* ]]
}

@test "require_mikefarah_yq: skips (exit 0) locally when yq on PATH is not mikefarah/yq" {
  run env -u CI PATH="$WRONG_VARIANT_PATH" bash -c "source '$LIB'; require_mikefarah_yq 'a check'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"yq on PATH is not mikefarah/yq — skipping a check"* ]]
}

@test "require_mikefarah_yq: FAILS (exit 1) in CI when yq on PATH is not mikefarah/yq" {
  run env -u CI PATH="$WRONG_VARIANT_PATH" CI=true bash -c "source '$LIB'; require_mikefarah_yq 'a check'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"yq on PATH is not mikefarah/yq (required in CI for a check"* ]]
}

@test "require_mikefarah_yq: returns silently (no output, exit 0) when mikefarah/yq is on PATH" {
  run env -u CI PATH="$MIKEFARAH_PATH" CI=true bash -c "source '$LIB'; require_mikefarah_yq 'a check'; echo AFTER"
  [ "$status" -eq 0 ]
  [ -z "$(echo "$output" | grep -v AFTER)" ]
  [[ "$output" == *"AFTER"* ]]
}

@test "require_mikefarah_yq: defaults caller name to 'this check' when no argument given" {
  run env -u CI PATH="$STRIPPED_PATH" bash -c "source '$LIB'; require_mikefarah_yq"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipping this check"* ]]
}

# --- recurrence guard: every mikefarah-only-syntax script still calls it --------
# yq-variant-guard-check.sh (tests/drift-yq-variant-checks.bats) already
# covers this structurally; re-asserted here as a same-file cross-check so
# this file alone documents the full contract of the shared guard.
@test "every known mikefarah-only-syntax caller sources scripts/lib/yq-variant.sh" {
  for f in helm-chart-pin-check.sh argocd-crd-ssa-check.sh rollouts-plugin-list-check.sh; do
    run grep -q 'lib/yq-variant\.sh' "$REPO/scripts/$f"
    [ "$status" -eq 0 ]
  done
}
