# envoy-gateway-system namespace — PSA baseline labels (RFC #230, ADR-0017)

**CHARTER Objective O2** (PSS-restricted fan-out, due 2026-09-30).

Applies Pod Security Admission `baseline` profile to the `envoy-gateway-system` namespace
per RFC #230 (architect decision 2026-06-19) and ADR-0017 §"Per-namespace profile".

The `baseline` profile is the documented carve-out for this namespace: the Gateway
controller pod is `restricted`-compatible, but Envoy proxy data-plane pods run as UID 0
in the upstream `gateway-helm` chart v1.8.0. Flipping to `restricted` would reject
north-south proxy pods. `baseline` blocks the highest-risk host-namespace controls
while permitting root UIDs.

Flip condition: when `gateway-helm` explicitly supports non-root proxy pods via
`EnvoyProxy.spec.provider.kubernetes.envoyDeployment.pod.securityContext` AND the
maintainer verifies north-south traffic unaffected after the label flip.

## Files delivered

| Path | Role |
|------|------|
| `gitops/envoy-gateway-system/namespace.yaml` | New Namespace manifest with all four PSA `baseline` labels |
| `gitops/platform/envoy-gateway-system-extras.yaml` | New ArgoCD `Application` (sync-wave 0, `ServerSideApply=true`, `CreateNamespace=false`) — SSA-patches labels onto the namespace before any pod is scheduled |
| `tests/securitycontext-envoy-gateway-system.bats` | 9 structural assertions in their own per-scope file (namespace file exists, four PSA baseline labels, enforce:restricted absent, extras Application exists, targets correct path, uses ServerSideApply) — kept out of the shared `securitycontext.bats` monolith to avoid the parallel-PR EOF-append merge conflict |
| `docs/dependency-tree.md` | Wave 0 table updated; new PSS baseline bullet added after envoy-gateway-system networkpolicy entry |
| `ROADMAP.md` | Item checked `[x]` |

## PR

PR #239 — https://github.com/tooming/k8s-lab/pull/239
