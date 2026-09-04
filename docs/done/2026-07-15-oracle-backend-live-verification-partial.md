# Verify the Oracle cloud backend end-to-end (partial — network + tfstate layer confirmed, instance launch blocked by transient capacity)

Per issue #406, ran the Oracle backend against a real OCI Always Free tenancy from a
local session (real network egress, real credentials) — the two things a remote/cloud
session structurally cannot do.

## What was verified against the real account

- Generated an OCI API signing keypair and an SSH keypair locally (private keys never
  left the machine), walked through the OCI Console API-key upload, wrote
  `~/.oci/config`, and confirmed auth (`oci iam region list`, `oci iam tenancy get`).
- `make tfstate-oracle-up` (`scripts/tfstate-oracle-bootstrap.sh`) ran successfully
  end-to-end: created the VCN/IGW/security-list/subnet, launched the Always Free AMD
  Micro instance, and brought up the Garage container with a real S3-compatible
  endpoint and a `tfstate` bucket.
- `terragrunt init` under `infra/live/oracle/cluster/` connected to that real Garage S3
  backend and downloaded the `oracle/oci` provider — the exact two calls a remote
  session's egress proxy blocks (per issue #406), both worked fine here.
- `terragrunt apply` on the `cluster/` unit created the VCN, subnet, security list, and
  internet gateway cleanly (`terraform plan`: 7 to add, 0 to change/destroy — all
  network resources succeeded; only the compute instance resource failed, see below).

## Bugs found and fixed (only findable via a real API)

1. **`infra/tfstate-oracle/cloud-init.yaml.tpl`: `ubuntu` was never added to the
   `docker` group.** Every `docker exec` over SSH (the script's readiness poll and the
   `g()` helper for layout/key/bucket setup) failed with "permission denied while
   trying to connect to the docker API" until fixed with `usermod -aG docker ubuntu`
   in `runcmd`.
2. **`infra/modules/oracle-k3s-cluster/main.tf`: VCN `dns_label` exceeded OCI's 15-char
   limit.** `replace(var.cluster_name, "-", "")` on `"k8s-anywhere-oracle"` produces
   `"k8sanywhereoracle"` (17 chars); `CreateVcn` 400s with `dnsLabel size must be
   between 1 and 15`. `terraform validate` can't catch this — it's a live API rule, not
   a syntax constraint. Fixed with `substr(..., 0, 15)`.
3. **`scripts/tfstate-oracle-bootstrap.sh`: AD selection for the tfstate instance
   picked `data[0]` from the plain availability-domain list, not an AD with actual
   quota.** Confirmed via `oci limits value list` that `vm-standard-e2-1-micro-count`
   (the Always Free AMD Micro shape) was `0` in AD-1 and AD-2, `2` in AD-3 — Oracle
   grants this specific quota to one AD per tenancy, not uniformly. Fixed by querying
   the limits API for an AD with `value > 0` instead of blindly using AD-1.

18 `tests/oracle-cluster.bats` assertions pass (up from 16 — two new ones landed
independently via #407 while this session was in flight; both are compatible with the
fixes here, reconciled via a straightforward rebase). `terraform fmt`/`validate`,
`shellcheck`, and `yamllint` all clean.

## What's still not verified: the k3s instance itself

The `cluster/` unit's `oci_core_instance` resource (the Ampere A1.Flex VM the k3s node
runs on) failed with `500 Out of host capacity` on every one of the tenancy's 3
availability domains in `eu-frankfurt-1`. This is Oracle's well-documented Always Free
Ampere A1 capacity scarcity — a transient, external, region-wide constraint, not a bug
in this repo. `standard-a1-core-count` quota itself is fine (41 cores available per AD,
41 far above the 2 OCPU the module requests) — the failure is host capacity, not quota.

A bounded retry loop (20 attempts, 60s apart, rotating AD) was left running to catch
capacity freeing up; if it succeeds this doc and `infra/live/README.md`'s status row
will be updated again with the final `kubectl get nodes` confirmation. If it doesn't,
the tfstate Garage instance (Always Free, no cost) can stay up for a future session to
retry via the same `make tfstate-oracle-up` (idempotent, already applied) +
`terragrunt apply` (unblocked once Oracle frees capacity) without repeating any of the
setup above.

## Out of scope

Multi-cloud active-active remains out of scope per issue #406 — this is still about
verifying the single Oracle backend swap-in, not building failover between clouds.

## PR

https://github.com/tooming/k8s-anywhere/pull/409
