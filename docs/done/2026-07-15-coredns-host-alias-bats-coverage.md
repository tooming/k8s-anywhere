# tests/coredns-host-alias.bats — close a coverage/hardening gap

ROADMAP rule #9's coverage/hardening fallback lane names "a script under `scripts/`
with no `tests/*.bats` coverage" as always-real, always-available work. With the
Alloy/Grafana/Pyroscope readOnlyRootFilesystem item now fully closed
(`auto/observability-readonlyrootfs-{alloy,grafana,pyroscope}`) and every other
Now/next 🟢 item gated on a live-cluster maintainer confirmation this run can't
verify, and no open GitHub issues to triage, swept `scripts/*.sh` for exactly this
gap.

Excluding the Makefile/tooling wrappers (`validate-manifests.sh`,
`validate-kustomize.sh`, `validate-terraform.sh`, `lint.sh`, `test.sh` — thin
wrappers around external binaries) and the `*-sync-hook.sh` PostToolUse wrappers
(which by established convention stay thin/untested — the `*-check.sh` script they
call carries the bats coverage instead), one genuine gap remained:
`scripts/coredns-host-alias.sh` — the script wired into `make coredns-host-alias`
(and `make up`) that teaches CoreDNS to resolve `host.k3d.internal` to the docker
network gateway, required for every ArgoCD `Application` (whose `repoURL` points at
the local GitLab) to keep syncing under Colima/Docker on macOS. `tests/cilium.bats`
only asserted this script's position in the `make up` recipe relative to
`cilium-up`; nothing exercised its own declared behavior.

New `tests/coredns-host-alias.bats` (8 assertions, clusterless/structural — no
docker/kubectl execution): script exists and is executable; fails clearly with
`exit 1` when the docker network gateway can't be resolved; targets the
`k3d-k8s-lab` network; writes the `coredns-custom` ConfigMap in `kube-system`;
aliases `host.k3d.internal` via the `host-k3d-internal.server` key; is idempotent
(skips the apply when the ConfigMap already matches the desired state); restarts
CoreDNS and waits for the rollout to complete.

`make ci` passes (bats/lint locally; full suite in GitHub Actions).

(auto/coredns-host-alias-bats-coverage)

## PR

<!-- filled in after opening the PR -->
