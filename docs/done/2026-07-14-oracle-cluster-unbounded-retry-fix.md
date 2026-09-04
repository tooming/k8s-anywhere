# Fix unbounded retry loops in the Oracle cloud backend module

Per user direction to prioritize actually pushing the cloud-agnostic goal forward
(verifying the Oracle backend) over further doc/test sweeps, did a manual correctness
review of `infra/modules/oracle-k3s-cluster/` — the same kind of read-the-actual-logic
review that caught the `mimir-readonly-root-check.sh` bug earlier this session — since
`terraform apply` verification against a real account isn't possible from this session
(see below).

## Bugs found

Two `until` polling loops with **no timeout or retry bound**:

1. `infra/modules/oracle-k3s-cluster/main.tf`'s `null_resource.kubeconfig`
   provisioner: `until ssh ... 'test -f /etc/rancher/k3s/k3s.yaml'; do sleep 5; done`.
   If the instance never becomes SSH-reachable with a ready k3s.yaml (OCI
   out-of-capacity, a cloud-init failure, a wrong SSH key), this hangs
   `terraform apply` **forever** with no diagnostic.
2. `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s `runcmd`:
   `until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 2; done`. Same failure class on
   the instance side — if the k3s install silently failed, cloud-init's `runcmd`
   would hang forever.

Also found: the destroy-time `null_resource` provisioner cleaned up the kubeconfig's
`context` and `cluster` entries but not the `users` entry, even though the create-time
`sed` renames all three (cluster, context, user) to the same `oracle-<name>` string —
leaving a stale credential entry in `~/.kube/config` after every destroy.

## Fix

- Bounded both loops (300s budget each: 60×5s for the SSH wait, 150×2s for the
  cloud-init wait), each exiting non-zero with a clear, diagnosable error message on
  timeout — matching the `retry()` + budget-constant pattern already used elsewhere in
  this repo (`scripts/dr-verify.sh`'s `T_ARGO`/`T_VAULT`/etc.).
- Added `kubectl config unset users.oracle-<name>` to the destroy-time cleanup.
- 4 new `tests/oracle-cluster.bats` assertions (16 total, up from 12) covering both
  bounded-retry fixes and the destroy cleanup fix.

## Why not full `terraform apply` verification

Confirmed two independent, hard environment blockers in this session:

1. **No OCI account or credentials exist in this environment** (per
   `infra/live/README.md`'s existing status note).
2. **This sandbox's egress proxy blocks both `registry.terraform.io`** (confirmed via
   `terraform init`, which failed with `Forbidden` fetching the `oracle/oci` provider)
   **and Oracle Cloud's own API endpoints** (confirmed directly:
   `curl https://identity.us-ashburn-1.oraclecloud.com` returns a 403 CONNECT-tunnel
   failure from the proxy, independent of any credentials).

So even with real OCI credentials, this session could not run `terraform init`
(provider download) or make a single OCI API call. `terraform fmt -check` (no network
needed) passes clean. Actual end-to-end verification needs either a different
environment with a network policy permitting `registry.terraform.io` +
`*.oraclecloud.com`, or the maintainer running `terragrunt apply` on their own machine.

`make ci` passes (same 7 pre-existing environment-only failures as prior PRs this
session — unrelated `yq`/`helm` tooling gaps).

## PR

https://github.com/tooming/k8s-anywhere/pull/405
