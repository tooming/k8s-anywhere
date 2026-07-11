#!/usr/bin/env bats
# Fixture: monolith whose @test set matches the snapshot → check passes.

@test "alloy scrape block exists" {
  true
}

@test "kube-state-metrics Application exists" {
  true
}
