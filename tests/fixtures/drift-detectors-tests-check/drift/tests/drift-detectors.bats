#!/usr/bin/env bats
# Fixture: monolith whose @test set matches the snapshot → check passes.

@test "alpha check passes" {
  true
}

@test "beta check passes" {
  true
}

@test "gamma newly appended check" {
  true
}
