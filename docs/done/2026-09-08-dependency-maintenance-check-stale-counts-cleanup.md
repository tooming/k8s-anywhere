# Correct `scripts/dependency-maintenance-check.sh`'s stale header comment

Found live 2026-09-08 (planner gap analysis, same "leftover rationale/count
from a removed component" class as this run's earlier ADR-0016/0017
(#1514), dead-Harbor-mirror (#1516), and coredns-host-alias.sh (#1519)
fixes): the script's header comment still claimed
`docs/dependency-register.md` has "33 rows" and that "Terraform/Terragrunt,
Oracle Cloud Infrastructure, Forgejo" are the rows with no `github.com`
upstream source, but the register is now down to 7 rows (2026-09-06/
2026-09-07 simplification) and Forgejo isn't a row at all any more
(removed, ADR-0035); of the current 7 rows, only Oracle Cloud
Infrastructure genuinely lacks a `github.com` source — Terraform/Terragrunt
now cites `github.com/hashicorp/terraform` too.

Verified directly before editing:
- `grep -c "^|" docs/dependency-register.md` → 7 real table rows.
- `grep -n "github.com" docs/dependency-register.md` → exactly 6 of those 7
  rows (Terraform/Terragrunt, ArgoCD, Traefik, Cilium, k3s, cert-manager)
  cite a `github.com/<owner>/<repo>` upstream — only Oracle Cloud
  Infrastructure (`cloud.oracle.com` only) has none.

This is a report-only script ("Report-only — deliberately NOT wired into
`make ci`", per its own header) — the stale comment didn't affect its
actual behavior/output, only its self-description; no test asserts the
exact stale text (`grep -rn "33 rows\|no github.com upstream" tests/*.bats`
confirmed zero hits before editing).

## What was done

- Rewrote the header's dependency-count claim to point at
  `docs/dependency-register.md` as the live source of truth instead of
  hardcoding a number that will drift again (matching the phrasing pattern
  other self-tracking docs in this repo already use), rather than just
  swapping "33" for "7" (which would only recreate the same drift class at
  the next simplification round).
- Rewrote the no-github-upstream-rows claim to name only Oracle Cloud
  Infrastructure (the one row that genuinely has none today), noting
  Terraform/Terragrunt now also cites a `github.com` source, and added a
  one-line note to re-check this claim whenever the register gains/loses a
  no-github-upstream row.
- Fixed the same section's stale "~30-repo sweep" claim (real count today
  is 6 github-backed rows) to a non-numeric "multi-repo sweep" phrasing,
  same anti-drift reasoning as the row-count fix above.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green), confirming this
comment-only edit broke no mechanical assertion (none existed against the
old text either, per the `tests/*.bats` grep above).

## PR

[#1521](https://github.com/tooming/k8s-anywhere/pull/1521) (autonomous
scheduled executor run, cycle 8: item picked directly from the
freshly-refilled "Now / next" lane after cycle 7's `plan/*` PR #1520).
