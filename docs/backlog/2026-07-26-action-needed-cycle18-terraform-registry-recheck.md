# [Action needed] Now/next still gated; terraform provider-registry reachability test also confirms existing skip design

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (eighteenth cycle of 2026-07-26): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC.

## This cycle's fresh angle

The previous cycle
([`2026-07-26-action-needed-cycle17-full-local-ci-run.md`](2026-07-26-action-needed-cycle17-full-local-ci-run.md))
installed the full `make ci` toolchain locally for the first time and ran
`terraform fmt` clean, but `validate-terraform.sh` itself only runs `fmt`
locally — its own `tflint`/`terraform validate`-with-providers step is
explicitly gated to CI (`tests/drift-...bats` coverage: "requires tflint in
CI but only skips it locally... treats an unreachable provider registry as a
local skip, not a hard failure"). This cycle tested that exact skip
condition for real rather than assuming it: ran `terraform init -backend=false`
directly against `infra/modules/k3d-cluster`.

Result: `registry.terraform.io` returns **403 Forbidden** through this
session's egress proxy (`could not connect to registry.terraform.io: ...
Get "https://registry.terraform.io/.well-known/terraform.json": Forbidden`) —
the same organization-level network policy already documented for the Helm
chart-index hosts in prior cycles, now confirmed to also cover the Terraform
provider registry. Per the proxy's own README ("do not retry organization
policy denials — report them"), did not retry or attempt a workaround.

This confirms `validate-terraform.sh`'s existing "unreachable provider
registry → local skip, not a failure" design is the *correct* behavior for
this environment, not a gap — a genuinely deeper terraform validation
(`terraform validate` with real provider schemas, `tflint`) is exactly as
infeasible from this remote clusterless session as the Helm chart-index
checks already found to be, for the identical proxy-policy reason. No script
change is warranted: the gate already does the right thing when the registry
is unreachable.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size; (d) proxy/network access to `registry.terraform.io` or the
Helm chart-index hosts (both denied by the same org egress policy).

This note is this cycle's honest record — closing out the one remaining
untested tool (terraform, beyond `fmt`) from yesterday's toolchain
installation — not a stopping point. The run continues per
`executor.prompt.md` STEP 8.
