# tfstate-oracle-bootstrap.sh — fail loudly instead of silently on a readiness timeout

Continuing the Oracle backend hardening from PR #405: reviewed
`scripts/tfstate-oracle-bootstrap.sh` (the off-cluster Terraform-state Garage
bootstrap for the oracle backend) for the same class of bug found in
`infra/modules/oracle-k3s-cluster/main.tf`.

## What was wrong

The SSH/Garage-readiness poll loop was already correctly bounded (60 × 5s = 300s,
unlike the two truly-unbounded loops fixed in PR #405), but nothing checked
afterward whether it actually succeeded. On timeout it silently fell through into
the layout-assignment / key-import / bucket-creation steps. Those steps are guarded
by `if`/`!` conditions, which bash's `set -e` does not apply to — so an instance that
never became reachable didn't abort the script there. It looked like the layout step
was just skipped (a normal idempotency no-op), and the script only actually died
later, at the first *unconditional* `g` call (`g key import`), with a raw, unexplained
SSH/command failure instead of a clear "instance never came up" diagnostic.

## Fix

Added an explicit `ready` flag set inside the loop and checked immediately after it;
on timeout, exits 1 with a clear, diagnosable error pointing at the OCI console's
instance serial console — matching the pattern used in PR #405's
`main.tf`/`cloud-init.yaml` fixes. New `tests/oracle-cluster.bats` assertion (17
total, up from 16).

`shellcheck -S warning` clean. `make ci` passes (same 7 pre-existing environment-only
failures as prior PRs this session).

## PR

(this session's branch)
