# PSS-restricted hardening — `external-secrets` namespace (RFC #229, ADR-0017)

**CHARTER Objective O2** (PSS-restricted fan-out, due 2026-09-30).

Applies the PSS `restricted` Pod Security Admission profile to the
`external-secrets` namespace per RFC #229 (architect decision 2026-06-19) and
ADR-0017 §"Per-namespace profile". ESO 2.x controller-manager, cert-controller,
and webhook all run as UID 65534 (`nobody`) with no host volumes or special
capabilities — no carve-out from `restricted` is needed.

## Files delivered

| Path | Role |
|------|------|
| `gitops/external-secrets/namespace.yaml` | Namespace manifest with all four PSA labels at `restricted` |
| `gitops/platform/external-secrets-extras.yaml` | ArgoCD `Application` (sync-wave 0, SSA, `CreateNamespace=false`) that patches the namespace labels before the ESO Helm release deploys |
| `gitops/platform/external-secrets.yaml` | `valuesObject` patched with `global.podSecurityContext` + `global.containerSecurityContext` per RFC #229 §Decision |
| `tests/securitycontext.bats` | Eleven new bats assertions: namespace file exists, four PSA label assertions, extras Application exists + targets correct path + uses SSA, chart valuesObject sets `runAsNonRoot`/`readOnlyRootFilesystem`/`capabilities.drop` |

## Security context shape applied

`global.podSecurityContext`:
- `runAsNonRoot: true`
- `runAsUser: 65534` / `runAsGroup: 65534`
- `seccompProfile.type: RuntimeDefault`

`global.containerSecurityContext`:
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true`
- `capabilities.drop: ["ALL"]`

No `emptyDir` overlay was needed — the ESO chart's three controllers (controller-manager,
cert-controller, webhook) do not write to the container filesystem at runtime.

## PR

https://github.com/tooming/k8s-anywhere/pull/238
