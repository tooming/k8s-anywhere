#!/usr/bin/env bats
# Fixture: monolith whose @test set matches the snapshot -> check passes.

@test "alpha hook: exits 0" {
  true
}

@test "beta hook: exits 0" {
  true
}
