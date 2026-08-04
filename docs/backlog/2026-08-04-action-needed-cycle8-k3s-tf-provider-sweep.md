# [Action needed] Now/next still gated; k3s + Terraform-provider currency sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane remains the same 3 unchecked `[ ]` items, all still
gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — unchanged since the
last check this run (see the cycle 7 note,
`docs/backlog/2026-08-04-action-needed-cycle7-coverage-hardening-sweep.md`).

## What this run already did

Six real merged PRs so far (3 plan→build pairs closing DORA audit readiness gaps
Q6/Q8, Q12, Q14 — see the cycle 7 note for the full list), plus one prior
`[Action needed]` cycle (#978) whose coverage/hardening-sweep lens (untested
scripts, doc TODO/FIXME, un-RFC'd 🟡 items) came up clean.

## This cycle's fresh angle (not a repeat)

Tried two angles not yet used this run:

1. **ADR-0030 (k3s version pin) currency** — verified `infra/modules/k3d-cluster/
   k3d-config.yaml.tftpl`'s `image: rancher/k3s:v1.36.2-k3s1` and
   `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s
   `INSTALL_K3S_VERSION=v1.36.2+k3s1` are both already implemented per the ADR's own
   Decision section (not an open gap — ADR-0030 itself is fully landed). Fetched
   `github.com/k3s-io/k3s/releases` directly (not training knowledge, ADR-0004):
   the newest **stable** tag is `v1.36.2+k3s1` (24 Jun) — exactly the current pin.
   Newer tags exist (`v1.36.3-rc1`/`-rc2`, 24–28 Jul) but are release candidates,
   not stable, matching this repo's established "stable tags only" bump discipline
   (same pattern as the kro/Kiali/Envoy Gateway precedent — never jump to a
   pre-release). No gap.
2. **Terraform provider version constraints** — checked every `required_providers`
   block across `infra/modules/*/main.tf` (argocd, gitlab-config, k3d-cluster,
   oracle-k3s-cluster). All four use pessimistic-constraint operators (`~>`), which
   already float within their compatible range automatically on the next
   `terraform init` — unlike the exact-pin-plus-audit-log pattern this repo uses for
   `gitops/` chart `targetRevision`s, there's no "stale exact pin" drift class here
   to check for. No gap (different pinning philosophy, not an oversight).

## Assessment

Between the three DORA-audit-readiness gap-fills, the prior coverage/hardening
sweep, and this cycle's k3s-pin + Terraform-provider check, this run has now swept
dependency currency, script/doc coverage, RFC backlog health, and the cluster-engine
pin itself — all came up clean or already-current. Further identical re-sweeps this
run would be diminishing-returns repeats rather than fresh signal.

## What would unblock further work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub
issue (ungroomed intake); (c) a new upstream CVE/release firing a tracked ADR flip
condition; (d) a k3s `v1.36.3` (or later) *stable* release actually shipping.

This note is this cycle's honest record — the run already shipped 6 real PRs
before reaching it. The run continues to the next cycle per `executor.prompt.md`
STEP 8; this is not a stopping point.
