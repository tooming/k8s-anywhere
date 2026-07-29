# [Action needed] Now/next still gated; Terraform variable-to-Terragrunt-input wiring audit clean (another false alarm caught)

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 5 unchecked `[ ]` items,
all gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-verified this
cycle: all three still open, zero comments, unchanged since 2026-07-21.

## What this cycle already did

Merged [#854](https://github.com/tooming/k8s-anywhere/pull/854) (shell
strict-mode consistency audit).

## This cycle's fresh angle (another self-caught near-miss)

Checked every Terraform module (`infra/modules/*/variables.tf`) for a
variable with **no default** that's also never set by any unit-level
`terragrunt.hcl` — a real correctness gap that would fail `terragrunt plan`
outright if it existed. First pass flagged: `k3d-cluster`'s and
`oracle-k3s-cluster`'s `cluster_name` variable.

**Checked before writing it up as a finding**: `cluster_name` *is* set —
via `infra/live/{local,oracle}/root.hcl`'s own `locals.cluster_name` +
`inputs.cluster_name = local.cluster_name` block, which Terragrunt's
`include` mechanism merges down into every child unit automatically. My
script's search scope (`infra/live/*/*/terragrunt.hcl`, unit-level files
only) simply never looked at `root.hcl` one directory up, where the value
actually lives — the same class of miss as this run's earlier Terragrunt
consistency check (which *did* correctly account for `root.hcl`) would have
caught, had this check reused that scope instead of a narrower glob.

No real gap: every variable is wired correctly, either via a module default
or via `root.hcl`'s shared inputs. No bounded, real, behavior-preserving
cleanup or upgrade qualified for a direct fix this cycle. `make ci` is
unaffected (no code/manifest touched by this audit).

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631/#632/#633; (b) a new
upstream CVE/release firing a tracked ADR flip condition; (c) a new GitHub
issue of any size (ungroomed intake).

This note is this cycle's honest record — a genuinely distinct check
(Terraform variable defaulting vs. Terragrunt input wiring) that, once
again, caught its own first-pass false positive (missing `root.hcl` from
the search scope) before it could be written up as a wrong finding. The run
continues to the next cycle per `executor.prompt.md` STEP 8; this is not a
stopping point.
