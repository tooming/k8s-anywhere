#!/usr/bin/env bats
# Fixture: monolith whose @test set matches the snapshot → check passes.

@test "alpha namespace exists" {
  true
}

@test "beta namespace exists" {
  true
}
