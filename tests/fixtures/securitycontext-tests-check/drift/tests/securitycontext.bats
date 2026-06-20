#!/usr/bin/env bats
# Fixture: a NEW @test ("gamma …") was appended to the frozen monolith but the
# snapshot wasn't updated → simulates the parallel-PR append → check must FAIL.

@test "alpha namespace exists" {
  true
}

@test "beta namespace exists" {
  true
}

@test "gamma namespace exists" {
  true
}
