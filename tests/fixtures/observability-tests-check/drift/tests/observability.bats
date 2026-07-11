#!/usr/bin/env bats
# Fixture: a NEW @test ("tempo scrape block …") was appended to the frozen monolith
# but the snapshot wasn't updated → simulates the parallel-PR append → check must FAIL.

@test "alloy scrape block exists" {
  true
}

@test "kube-state-metrics Application exists" {
  true
}

@test "tempo scrape block exists" {
  true
}
