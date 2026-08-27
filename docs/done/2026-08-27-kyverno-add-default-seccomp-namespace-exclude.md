# Give `add-default-seccomp` the same namespace carve-out as its sibling PSS policies

Bugfix, not a ROADMAP item: reached via `executor.prompt.md` STEP 6b /
ROADMAP rule #9 — this run's fifth cycle, same adversarial-Kyverno-read lens
that found and fixed the `disallow-latest-tag` gap earlier this run (PR
#1352), continued one policy further: a direct diff of every Pod-Security
`ClusterPolicy` against every other, not just each against its own header
comment's claims.

## Finding

`gitops/kyverno/policies/add-default-seccomp.yaml` was the only one of the
three Pod-Security-related `ClusterPolicy`s
(`require-pod-security-restricted`, `add-default-runasnonroot`,
`add-default-seccomp`) with **no `exclude` block at all** — despite its own
header comment describing it as "defence-in-depth alongside the
require-pod-security-restricted validate policy," which *does* carve out
`kube-system`/`kube-public`/`kube-node-lease` and any
`baseline`/`privileged`-PSA-labelled namespace (vault, istio-system, tidb,
…). Those namespaces deliberately run root/privileged workloads
PSS-restricted was never meant to reach. Without a matching exclude,
`add-default-seccomp` would still try to mutate `seccompProfile` into pods
in those same exempted namespaces whenever they omit it — which could
restrict syscalls a privileged workload (Cilium's own eBPF agent, Vault's
`mlock`) genuinely needs.

## Fix

Copied the identical `exclude.any` block from
`require-pod-security-restricted.yaml` into `add-default-seccomp.yaml`
verbatim. This is the **conservative** direction — the policy now mutates
fewer pods, not more — and brings it in line with the carve-out its own
comment already implies it should share. Verified directly (ADR-0004):
no manifest under `gitops/` currently sets `seccompProfile` itself in any
of the newly-excluded namespaces, so nothing in this repo relies on the
removed mutation having fired there.

Added `tests/kyverno.bats` regression coverage: a test asserting
`add-default-seccomp`'s `exclude` block is byte-identical (via `yq -o=json`
comparison) to `require-pod-security-restricted`'s, so the two policies
can't silently drift apart again. Also updated ADR-0019's policy table row
and added a Re-evaluation log entry documenting the finding and the
conservative-direction reasoning.

## ADR-0004 caveat

Unverified against a live cluster whether any already-running pod in an
excluded namespace was depending on the removed mutation. No evidence of
that in this repo's own tracked manifests (Cilium's own agent is
chart-managed and doesn't declare `seccompProfile` in this repo's config
either way). A live-cluster session should confirm nothing regresses.

## Verification

`bats tests/kyverno.bats` — 64/64 pass (new test included). Full `make ci`
with the real `mikefarah/yq` binary on `PATH` — zero `not ok`, exit 0.

## PR

auto/kyverno-add-default-seccomp-namespace-exclude
