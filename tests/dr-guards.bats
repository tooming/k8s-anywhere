#!/usr/bin/env bats
# Unit tests for the safety guards on the DESTRUCTIVE scripts. These wipe the
# lab, so the two gates that stand between a typo and a wiped cluster matter:
#   1. an unknown SCOPE is rejected (exit 2) before anything is touched;
#   2. running non-interactively without DR_ASSUME_YES=1 refuses (exit 1).
# Both guards fire before any destroy step, so exercising them is safe here.
# DR_ASSUME_YES is stripped from the env so a stray value can't unlock a wipe.

setup() { REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; }

@test "dr-destroy.sh: unknown scope exits 2" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-destroy.sh" bogus </dev/null
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown SCOPE"* ]]
}

@test "dr-destroy.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-destroy.sh" cluster </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-test.sh: unknown scope exits 2" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-test.sh" bogus </dev/null
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown SCOPE"* ]]
}

@test "dr-test.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-test.sh" cluster </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-chaos-argocd.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-chaos-argocd.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-chaos-argocd.sh: with DR_ASSUME_YES, fails gracefully (no live cluster here) before deleting anything" {
  run env DR_ASSUME_YES=1 bash "$REPO/scripts/dr-chaos-argocd.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"no live argocd-application-controller pod found"* ]]
}

@test "dr-chaos-cert-manager.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-chaos-cert-manager.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-chaos-cert-manager.sh: with DR_ASSUME_YES, fails gracefully (no live cluster here) before deleting anything" {
  run env DR_ASSUME_YES=1 bash "$REPO/scripts/dr-chaos-cert-manager.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"no live cert-manager controller pod found"* ]]
}

@test "dr-chaos-traefik.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-chaos-traefik.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-chaos-traefik.sh: with DR_ASSUME_YES, fails gracefully (no live cluster here) before deleting anything" {
  run env DR_ASSUME_YES=1 bash "$REPO/scripts/dr-chaos-traefik.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"no live Traefik pod found"* ]]
}

@test "dr-chaos-lab-demo.sh: refuses non-interactively without DR_ASSUME_YES" {
  run env -u DR_ASSUME_YES bash "$REPO/scripts/dr-chaos-lab-demo.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing non-interactively"* ]]
}

@test "dr-chaos-lab-demo.sh: with DR_ASSUME_YES, fails gracefully (no live cluster here) before deleting anything" {
  run env DR_ASSUME_YES=1 bash "$REPO/scripts/dr-chaos-lab-demo.sh" </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"no live lab-demo (hello) pod found"* ]]
}

# scripts/lib/dr-chaos.sh consolidation guard (2026-09-14, JANITOR-fallback
# cleanup): the four dr-chaos-*.sh scripts above each hand-rolled a
# byte-identical retry()/fail() pair and a near-identical "capture
# BEFORE_UID, delete pod, poll for a new Ready pod" sequence before this
# extraction — mirrors the existing lib/kctx.sh / lib/confirm.sh consolidation
# pattern (see tests/kctx-lib.bats's own analogous guard).
@test "no script under scripts/*.sh re-inlines the dr-chaos retry()/fail() pattern (source lib/dr-chaos.sh instead)" {
  run grep -l '^retry() {' "$REPO"/scripts/dr-chaos-*.sh
  [ "$status" -ne 0 ]
}

@test "every dr-chaos-*.sh script sources lib/dr-chaos.sh" {
  for f in "$REPO"/scripts/dr-chaos-*.sh; do
    run grep -q 'lib/dr-chaos.sh' "$f"
    [ "$status" -eq 0 ]
  done
}
