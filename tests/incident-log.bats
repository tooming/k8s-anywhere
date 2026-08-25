#!/usr/bin/env bats
# Structural coverage for docs/incident-log.md (ROADMAP "Incident classification
# (severity) scheme + incident log" item, DORA audit readiness Q6/Q8). Clusterless —
# every assertion is a grep against real, committed doc content, never a live-cluster
# check.

setup() {
  REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  DOC="$REPO/docs/incident-log.md"
  AUDIT="$REPO/docs/dora-audit-readiness.md"
}

@test "docs/incident-log.md exists" {
  [ -f "$DOC" ]
}

@test "incident-log.md defines a P0-P3 severity scheme" {
  run grep -q '\*\*P0\*\*' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q '\*\*P1\*\*' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q '\*\*P2\*\*' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q '\*\*P3\*\*' "$DOC"
  [ "$status" -eq 0 ]
}

@test "incident-log.md names no-paging/no-escalation as an intentional non-goal" {
  run grep -qi 'non-goal' "$DOC"
  [ "$status" -eq 0 ]
}

@test "incident-log.md contains a log-entry template" {
  run grep -q 'How to log a new incident' "$DOC"
  [ "$status" -eq 0 ]
  run grep -q 'Root cause' "$DOC"
  [ "$status" -eq 0 ]
}

@test "incident-log.md backfills the real incidents found while working #631/#633" {
  for needle in '#884' '#968' 'Cilium' 'GitLab Runner'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the vault-unsealer wedged-loop incident (PR #884)" {
  for needle in 'vault-unsealer' 'sealed for' 'while true'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the harbor NetworkPolicy port-mismatch incident (PR #1054)" {
  for needle in 'allow-harbor-ingress.yaml' '#1054' 'port 80'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the kargo namespace-deadlock incident (PR #1055)" {
  for needle in 'capstone-pipeline' 'kargo-webhooks-server' '#1055' 'constraint: latest'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the harbor-registry extraEnvVarsSecret incident (PR #1114)" {
  for needle in 'extraEnvVarsSecret' '#1114' 'NoCredentialProviders'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the harbor-registry OOMKill incident (38cebf0/9fd14c8)" {
  for needle in 'OOMKilled' '38cebf0' '9fd14c8'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the kro chronic crash-loop incident (PR #1300)" {
  for needle in 'kro' '#1300' 'ResourceGraphDefinition caches to sync'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the 8-bug Forgejo CI signing incident (PR #1213)" {
  for needle in '#1213' 'signature.cosign' 'QEMU emulation' 'TUF signing config'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md logs the argo-rollouts sync-failure incident (issue #633)" {
  for needle in 'argo-rollouts' 'argoproj.github.io/argo-helm' 'Unresolved as of 2026-08-17'; do
    run grep -q -- "$needle" "$DOC"
    [ "$status" -eq 0 ]
  done
}

@test "incident-log.md has no fabricated/placeholder content (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy)"' "$DOC"
  [ "$status" -ne 0 ]
}

@test "dora-audit-readiness.md's Q6 answer is no longer 'No'" {
  # Isolate the Q6 block (up to the next "**Q" heading) and assert it doesn't
  # contain the old negative answer literal.
  q6_block=$(awk '/\*\*Q6\./{flag=1} flag{print} /\*\*Q7\./{exit}' "$AUDIT")
  [ -n "$q6_block" ]
  ! grep -q '\*\*Answer:\*\* No\.' <<<"$q6_block"
  grep -q 'incident-log.md' <<<"$q6_block"
}

@test "dora-audit-readiness.md's Q8 answer references the new incident log" {
  q8_block=$(awk '/\*\*Q8\./{flag=1} flag{print} /\*\*Q9\./{exit}' "$AUDIT")
  [ -n "$q8_block" ]
  grep -q 'incident-log.md' <<<"$q8_block"
}
