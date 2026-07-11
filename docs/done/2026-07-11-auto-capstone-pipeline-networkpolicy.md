# NetworkPolicy overlay — `capstone-pipeline` namespace

**NetworkPolicy overlay — `capstone-pipeline` namespace** (**blocked
on PR #354 `auto/capstone-pipeline-psa` merging first** — the
`capstone-pipeline` `namespace.yaml` must exist before this NP overlay is
applied; skip to the next item until #354 merges; CHARTER **Objective O2**,
due **2026-09-30**; ADR-0016 defense-in-depth gap — the `capstone-pipeline`
namespace created by Kargo's Project CRD (ADR-0023) currently has no
default-deny NetworkPolicy overlay; Kargo promotion-step pods run in this
namespace during pipeline executions). Add
`gitops/kargo-project/networkpolicy/kustomization.yaml` referencing the
shared baseline templates (`default-deny.yaml` + `allow-dns-and-apiserver.yaml`
+ `zz-dns-clusterip-bridge.yaml`) plus the allow rules needed by promotion
jobs (verify at executor pickup against actual Kargo promotion-pod egress
requirements — at minimum: DNS, apiserver, and egress to the `kargo`
namespace for the Kargo controller callback). Add a new Application
`gitops/platform/kargo-project-networkpolicy.yaml` (non-auto-synced, wave
4, `LoadRestrictionsNone`; pairs with `kargo-project.yaml`). Add
`tests/networkpolicy-capstone-pipeline.bats` covering the three shared
baseline template references (mirrors the pattern of any existing per-scope
bats file). The O2 NP coverage loop in `tests/networkpolicy.bats` will
guard this namespace automatically once the overlay exists. `make ci` must
pass. `docs/done/` entry required.
(auto/capstone-pipeline-networkpolicy)

## PR

#TODO — filled in after PR is opened.
