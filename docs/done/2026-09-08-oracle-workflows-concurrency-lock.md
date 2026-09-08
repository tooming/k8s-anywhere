# Add concurrency groups to the two oracle-cluster-apply workflows

Found live 2026-09-08 (cycle 24 of this autonomous run — a fresh lens: CI
workflow *safety*, not currency or config-hygiene like this run's earlier
`ci.yml` concurrency fix, cycle 19). `.github/workflows/
oracle-cluster-apply.yml` (manual `workflow_dispatch`, plan/apply against
either the `cluster` or `argocd` unit) and `.github/workflows/
oracle-cluster-apply-retry.yml` (hourly cron, hardcoded to `apply` against
`cluster` only, retrying past Oracle's Always Free host-capacity
exhaustion per issue #406) both run `terragrunt apply` against the same
`infra/live/oracle/` Terraform state — a separate off-cluster Garage S3
instance (RFC #377 item 3, ADR-0007's Re-evaluation log confirms this
backend is kept, unlike the local backend's own Garage which was removed).

Checked `infra/live/oracle/root.hcl`'s generated S3 backend block: no
`use_lockfile`/DynamoDB-style lock table is configured (Garage's S3 API
support doesn't extend to the locking primitives Terraform's native `s3`
backend would otherwise use for that). Neither workflow had a
`concurrency` group. That means nothing on the GitHub Actions side stops
two `terragrunt apply` runs against the same unit's state from actually
running concurrently — e.g. a maintainer manually dispatching a `cluster`
apply while the hourly retry happens to be mid-flight — with no state
lock to serialize them and no CI-level queuing either. Two interleaved
writes to the same remote state file is a real corruption risk, not a
hypothetical one, given the retry workflow fires unattended every hour
indefinitely (per its own header comment, "safe to leave running
indefinitely").

## What was done

Added a `concurrency` block to both workflows, keyed by unit
(`oracle-terragrunt-<unit>`) rather than by workflow name — the same group
string in both files, so GitHub Actions serializes runs across *either*
workflow when they target the same unit (`cluster`), while `argocd` runs
(only reachable via the manual workflow, never the retry cron) get their
own, unaffected group. `cancel-in-progress` was deliberately left at its
default `false` in both: cancelling a mid-flight `terragrunt apply` (as
opposed to queuing a new run behind a finished one) would itself risk the
exact interleaved-write corruption this change exists to prevent — this
is the opposite trade-off from `ci.yml`'s concurrency group (cycle 19),
where cancelling a superseded *test* run is free and desirable.

## Validation

`yamllint -c .yamllint.yml` and `yq eval '.'` both clean on the two edited
files. `make ci` — full local run, exit code 0, zero `not ok` lines (bats
+ kustomize + terraform + drift checks all green, including
`workflow-timeout-check.sh`, unaffected by this change since neither
file's `timeout-minutes` moved). This remote session cannot actually
dispatch either workflow against a real OCI tenancy (no cloud credentials
reachable from here) — the change is a pure GitHub Actions scheduling
constraint, verifiable by inspection and by GitHub's own well-documented
`concurrency:` semantics, not something a clusterless session could
integration-test further.

## PR

[#1537](https://github.com/tooming/k8s-anywhere/pull/1537) (autonomous
scheduled executor run, cycle 24 — a CI-workflow-safety lens distinct from
every currency/doc-drift lens tried earlier this run).
