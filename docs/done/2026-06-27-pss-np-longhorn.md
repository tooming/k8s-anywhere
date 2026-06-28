# PSS `privileged` labels + NetworkPolicy — `longhorn-system`

**PSS `privileged` labels + NetworkPolicy — `longhorn-system`** (CHARTER **Objective O2**,
due **2026-09-30**; O2 fan-out completion — ADR-0017 §"Per-namespace profile" already
lists `longhorn-system → privileged` (longhorn-manager and longhorn-csi-plugin require
`SYS_ADMIN`, mount propagation, host `/dev`; per ADR-0013) but no
`gitops/longhorn/namespace.yaml` with PSA labels exists yet. Two changes bundled:
(a) **PSA labels** — add `gitops/longhorn/namespace.yaml` with all four PSA labels at
`privileged` (`enforce: privileged`, `enforce-version: latest`, `warn: privileged`,
`audit: privileged`); convert `gitops/platform/longhorn-extras.yaml` to auto-synced
(sync-wave 0, `ServerSideApply=true`, `CreateNamespace=true` — the namespace with
privileged labels is created before `make longhorn-up` admits pods; harmless when
Longhorn is not running). (b) **NetworkPolicy** — add
`gitops/longhorn/networkpolicy/kustomization.yaml` referencing the two shared baseline
templates plus two allow files: `allow-longhorn-intra-namespace.yaml`
(intra-namespace `podSelector: {}` — covers longhorn-manager ↔ engine + csi-plugin
dense intra-cluster flows); `allow-longhorn-metrics-ingress.yaml` (ingress TCP 9500
from `observability` — Longhorn exposes Prometheus metrics at `:9500/metrics`). Added
`longhorn-networkpolicy` entry to `networkpolicy-appset.yaml` list generator
(`gitPath: gitops/longhorn/networkpolicy`, `destNamespace: longhorn-system`). New
`tests/securitycontext-longhorn.bats` and `tests/networkpolicy-longhorn.bats` (one
scope = one file — no shared append anchor). Added `LONGHORN_NP` path variable to
`tests/lib/networkpolicy-paths.bash`. Updated `docs/dependency-tree.md` with Longhorn
PSS + NP note.

## PR

[#284](https://github.com/tooming/k8s-lab/pull/284)
