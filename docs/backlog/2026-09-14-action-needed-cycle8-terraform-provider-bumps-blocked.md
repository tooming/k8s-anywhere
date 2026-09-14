# [Action needed] Cycle 8 — three real Terraform provider bumps found, blocked by this environment's network policy

## This run so far

Cycles 1–7 already shipped: a DORA-metrics refresh
([#1588](https://github.com/tooming/k8s-anywhere/pull/1588)), a Traefik
full GHSA re-sweep finding and analyzing 5 new advisories
([#1589](https://github.com/tooming/k8s-anywhere/pull/1589)), two honest
records ([#1590](https://github.com/tooming/k8s-anywhere/pull/1590),
[#1594](https://github.com/tooming/k8s-anywhere/pull/1594)), the mandatory
weekly architect digest
([#1591](https://github.com/tooming/k8s-anywhere/pull/1591)), a full
upgrade-drafter source enumeration record
([#1592](https://github.com/tooming/k8s-anywhere/pull/1592)), and a real
JANITOR cleanup consolidating the `dr-chaos-*.sh` scripts
([#1593](https://github.com/tooming/k8s-anywhere/pull/1593)).

## This cycle's angle — Terraform PROVIDER versions (not the CLI, not Helm charts)

Every prior currency sweep this run checked the Terraform **CLI** version
and Helm **chart** versions (ArgoCD), but never the Terraform **provider**
versions Terraform itself resolves and locks in `.terraform.lock.hcl`. This
repo has two lock files:
`infra/live/local/argocd/.terraform.lock.hcl` and
`infra/live/local/cluster/.terraform.lock.hcl` (no lock file exists yet for
`infra/live/oracle/` — never applied, per CHARTER.md's own Status).

Live-checked each locked provider's real GitHub releases directly against
its lock-file pin:

| Provider | Constraint | Locked | Latest (within constraint) | Gap |
|---|---|---|---|---|
| `hashicorp/helm` | `~> 3.0` | `3.2.0` | `3.3.0` (2026-09-02 — "Upgrade Helm from 3.18.5 to 3.20.2") | one minor behind |
| `hashicorp/null` | `~> 3.2` | `3.3.0` | `3.3.2` (2026-09-10 — Go toolchain bump) | two patches behind |
| `hashicorp/local` | `~> 2.5` | `2.9.0` | `2.9.1` (2026-09-10 — Go toolchain bump) | one patch behind |

All three gaps are real, within each module's own version constraint (no
constraint edit needed), and none involve a breaking/major bump.

## Why this cycle can't execute the bump

A genuine version bump here means regenerating `.terraform.lock.hcl` via
`terraform init -upgrade` (or `terragrunt init -upgrade`) so the new
version's real per-platform package hashes are captured — hand-editing a
version number in a lock file without its real hashes would either break
`terraform init` for the next user or (worse) require disabling hash
verification, which this repo's own gate-integrity bar forbids outright.
Confirmed directly this cycle: `registry.terraform.io` is blocked by this
session's network egress policy (`curl -sS
https://registry.terraform.io/v1/providers/hashicorp/null/versions` →
`403` at the proxy's CONNECT tunnel; `terraform init -upgrade` cannot reach
the registry to resolve or hash a new provider version). This is the same
class of environment limit as "clusterless" (ROADMAP rule #2) — not a
permission boundary, a real network-reachability fact about this remote
session.

## Assessment

A real, verified, actionable finding — the first time this run (or, as far
as this session can tell, any recorded currency sweep) checked Terraform
provider versions specifically — but one this environment cannot safely
execute. Per ADR-0004, better to document the exact gap precisely than to
either fabricate a lock-file hash or silently skip reporting a real finding.

## What would open new work

- An interactive/live session with registry.terraform.io reachable running
  `terraform init -upgrade` (or `terragrunt init -upgrade`) in
  `infra/live/local/argocd/` and `infra/live/local/cluster/`, then
  committing the regenerated lock files.
- A future executor session, if this environment's network allowlist ever
  changes to include `registry.terraform.io`.
- A new GitHub issue (intake) from the maintainer.
- A later cycle in this same run, trying yet another lens.

This is cycle 8's honest record, per `executor.prompt.md` STEP 6b's last
resort. The run continues (STEP 8) — going back to STEP 1 immediately.
