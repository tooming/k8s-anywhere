# PSA `baseline` labels + NetworkPolicy — `artifactory` namespace

🟢 **PSA `baseline` labels + NetworkPolicy — `artifactory` namespace** (CHARTER
**Objective O2**, due **2026-09-30**; RFC #287 — architect decision 2026-06-27). O2
fan-out completion for the on-demand Artifactory namespace. Two changes bundled:
(a) **PSA labels** — add `gitops/artifactory/namespace.yaml` with all four PSA labels
at `baseline` (`enforce: baseline`, `enforce-version: latest`, `warn: baseline`,
`audit: baseline`). JVM init containers run as root UID 0 for `chown`; main JVM
process runs as UID 1030; `restricted` is not viable without upstream chart changes
(`jfrog/artifactory-oss`); `baseline` blocks privileged containers and host namespaces
while permitting the init root UID. Update `gitops/platform/artifactory-extras.yaml`:
add `automated: {prune: true, selfHeal: true}` to `syncPolicy` + `argocd.argoproj.io/sync-wave:
"0"` annotation (mirrors `longhorn-extras` / `istio-system-extras` — pre-creates the
namespace with PSA floor before `make artifactory-up` admits pods). (b) **NetworkPolicy** —
add `gitops/artifactory/networkpolicy/kustomization.yaml` referencing the two shared
baseline templates (`../../network/policies/default-deny.yaml`,
`../../network/policies/allow-dns-and-apiserver.yaml`) plus
`allow-artifactory-ingress.yaml` (ingress TCP 8082 from `namespaceSelector:
kubernetes.io/metadata.name: envoy-gateway-system` — Envoy HTTPRoute proxies to the
`artifactory-oss` Service on port 8082 per `gitops/artifactory/route.yaml`) and
`allow-artifactory-garage-egress.yaml` (egress TCP 3900 to `namespaceSelector:
kubernetes.io/metadata.name: storage` — Garage S3 binary store per ADR-0002). Add
`artifactory-networkpolicy` entry to `gitops/platform/networkpolicy-appset.yaml`
(`gitPath: gitops/artifactory/networkpolicy`, `destNamespace: artifactory`); sync
policy is `automated: {prune: true, selfHeal: true}` via the appset template. Add
`artifactory → baseline` row to ADR-0017 §"Per-namespace profile" table with RFC
citation and flip condition (when upstream `jfrog/artifactory-oss` chart documents
`restricted`-compatible initContainers). New `tests/securitycontext-artifactory.bats`:
`gitops/artifactory/namespace.yaml` exists; `enforce: baseline` present; `enforce:
restricted` absent (safety check); `artifactory-extras` Application has `automated:`
block (auto-sync present). New `tests/networkpolicy-artifactory.bats`: kustomization
exists; baseline templates referenced; `allow-artifactory-ingress.yaml` exists
targeting TCP 8082 from `envoy-gateway-system`; `allow-artifactory-garage-egress.yaml`
exists targeting TCP 3900 to `storage`; appset entry `artifactory-networkpolicy`
present. `make ci` must pass. (auto/pss-np-artifactory)

## PR

PR #298 — https://github.com/tooming/k8s-lab/pull/298
