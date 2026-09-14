# [Action needed] Cycle 23 — CI tool binary pin currency re-check, clean

## This run so far

Twenty-two PRs shipped this run (#1588–#1609). See prior
`docs/backlog/2026-09-14-*.md` files for each cycle's detail.

## This cycle

Live-checked every direct-download binary tool version pinned in
`.github/workflows/ci.yml` against its real upstream release feed:

- `kubeconform` (pinned `v0.8.0`) — `github.com/yannh/kubeconform/releases`
  confirms `v0.8.0` is still the newest tag.
- `tflint` (pinned `v0.64.0`) — `github.com/terraform-linters/tflint/releases`
  confirms `v0.64.0` is still the newest tag.
- `kustomize` (pinned `kustomize/v5.8.1`) —
  `github.com/kubernetes-sigs/kustomize/releases` confirms `kustomize/v5.8.1`
  is still the newest tag on the `kustomize/` (as opposed to `api/` or
  `cmd/config/`) release line.

All three pins are current. No bump due.

## Assessment

This closes out a comprehensive sweep, across cycles 19–23, of every
externally-tracked version pin this repo carries: Helm charts (ArgoCD,
cert-manager, Traefik-via-k3s), the cluster runtime (k3s, evaluated and
deliberately held at `v1.36.4+k3s1` per PR #1607), infra tooling
(Terraform, Terragrunt), CI Actions (`actions/checkout`, `actions/cache`,
`hashicorp/setup-terraform`, `actions/github-script`), and now the CI
job's own direct-download lint/validate binaries (kubeconform, tflint,
kustomize). Every single one is current as of today.

## What would open new work

- A new GitHub issue (intake) from the maintainer.
- A new release/GHSA against any pinned source — every category above is
  now confirmed current as a baseline, so the next actionable finding is
  whichever one moves first.
- k3s `v1.37.1+` shipping (ADR-0030's own flip condition, PR #1607).
- Oracle's Always Free capacity actually freeing up.
- A later cycle in this same run, once meaningfully more time has passed
  — a full pin sweep just completed, so a repeat this soon would add no
  information; the next cycle should pick a non-currency angle (a fresh
  doc-content read, a script-duplication scan, or similar).

This is cycle 23's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
