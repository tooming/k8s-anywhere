#!/usr/bin/env bats
# Fixture: monolith with a newly appended @test -> check fails.

@test "alpha hook: exits 0" {
  true
}

@test "beta hook: exits 0" {
  true
}

@test "gamma hook: newly appended" {
  true
}
