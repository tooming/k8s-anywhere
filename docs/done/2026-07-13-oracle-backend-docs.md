# `infra/live/README.md` — document the `oracle` backend

RFC #377 item 5, the last acceptance-criteria item. `infra/live/README.md`'s intro
and "Status" section updated: `oracle/` (Oracle Cloud Always Free + k3s, ADR-0027) is
now listed alongside `local/`, explicitly marked **"unverified against a real
account"** — every file was written and locally validated as far as this
environment's tooling allowed (real `terraform fmt`/`validate` against the actual
registry for the module; every `tests/oracle-cluster.bats` assertion executed for
real in CI), but no OCI account or credentials exist in this environment, so
`terraform apply` and the OCI-CLI-driven bootstrap script have never actually run
against real infrastructure.

`docs/dependency-tree.md` intentionally **not** touched: that doc reflects the
*actual running* localhost lab's integration and day-0 bootstrap graph. The `oracle`
backend has never been deployed, so adding it there would misrepresent reviewed-but-
unexercised code as live system state (ADR-0004).

This closes out RFC #377 (all 5 acceptance-criteria items merged):
1. Module — #379
2. Live units — #382
3. Tfstate backend — #381
4. Bats tests — #383
5. Docs — this PR

## PR

https://github.com/tooming/k8s-anywhere/pull/384
