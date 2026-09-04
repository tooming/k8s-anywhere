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

## A third instance of the same bug (same PR)

A closer look at `infra/tfstate-oracle/cloud-init.yaml.tpl` (the template this
bootstrap script renders as instance user-data) found a third occurrence: its
`runcmd` had `until docker exec tfstate-garage /garage status; do sleep 2; done` with
**no bound at all** — an unstartable Garage container (bad image pull, a config parse
error in the rendered `garage.toml`) would hang that instance's cloud-init `runcmd`
forever. Bounded it to 300s with the same clear-error-on-timeout pattern. 18th bats
assertion added.

`shellcheck -S warning` clean, `yamllint -c .yamllint.yml` clean (the one warning —
"missing starting space in comment" on `#cloud-config` — is an expected false
positive: that string is cloud-init's own magic marker and must not have a space
after `#`, same as the other cloud-init file touched in PR #405). `make ci` passes
(same 7 pre-existing environment-only failures as prior PRs this session).

## PR

https://github.com/tooming/k8s-anywhere/pull/407
