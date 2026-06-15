# Backlog footer migration — accreted grooming notes (through 2026-06-14)

This file preserves the per-run grooming commentary that had accreted in the
`ROADMAP.md` `## Backlog` footer paragraph before it was externalized to
`docs/backlog/` (the conflict-prevention change in PR #209). No content is lost;
new runs add their own dated file here instead of editing the shared footer.

- The four 2026-W23 RFCs (Kyverno → #153 / ADR-0019; Argo Rollouts → #154 /
  ADR-0020; Velero → #155 / ADR-0021; Trivy Operator → #156 / ADR-0022) were
  groomed into 🟢 single-PR items in *Now / next* (planner run 2026-06-11). All
  four ADRs (0019-0022) are merged on `main`, so the executor builds top-down
  without waiting for further architect input.
- The two prior 🟡 entries (NetworkPolicy default-deny, securityContext
  hardening) remain groomed into the 🟢 fan-out items in *Now / next* (ADR-0016
  and ADR-0017 are adopted).
- The ADR-0010 Redis→Valkey swap (issue #94) landed as ADR-0018 in PR #106 and
  is in *Done*.
- The two remaining 🟡 O2 gaps (PSS argocd, NP envoy-gateway-system) received
  architect RFCs #205 and #206 on 2026-06-14; the planner will split them into
  🟢 executor items on its next run.
- The 🟡 entries O4 cosign-CI + O6 capstone-demo target were surfaced by the
  2026-06-14 gap analysis; they await architect RFCs to unlock the
  Makefile/CI/security-adjacent work they require.

## PR

PR #209 — https://github.com/tooming/k8s-lab/pull/209
