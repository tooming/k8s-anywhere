# PSS-restricted fan-out — moto + ack-system + lab-gateway

**Date:** 2026-06-14
**Branch:** auto/pss-moto-ack-labgateway
**ROADMAP item:** PSS-restricted fan-out — `moto` + `ack-system` namespaces + `lab-gateway` labels
**CHARTER objective:** O2 (ADR-0017 §Staged rollout)

## What shipped

Three namespace PSA-label manifests + moto deployment securityContext hardening
+ Helm valuesObject security context patches for ACK S3 and KRO controllers:

| File | Change |
|------|--------|
| `gitops/moto/namespace.yaml` | New — PSA `restricted` labels for `moto` namespace |
| `gitops/moto/deployment.yaml` | Modified — pod + container securityContext (non-root uid 65534, RuntimeDefault seccomp, readOnlyRootFilesystem, drop ALL caps, /tmp emptyDir) |
| `gitops/ack/namespace.yaml` | New — PSA `restricted` labels for `ack-system` namespace |
| `gitops/platform/ack-s3.yaml` | Modified — `podSecurityContext` + `securityContext` added to Helm valuesObject |
| `gitops/platform/kro.yaml` | Modified — `deployment.podSecurityContext` + `deployment.containerSecurityContext` added to Helm valuesObject |
| `gitops/network/namespace.yaml` | New — PSA `restricted` labels for `lab-gateway` namespace |
| `tests/securitycontext-moto-ack-labgateway.bats` | New — 30 clusterless structural assertions |

## Notes

- `lab-gateway` holds no pods (Envoy proxy pods live in `envoy-gateway-system`); restricted PSA labels are trivially safe.
- `kro` controller namespace (where the KRO Helm chart lands) is separate from `ack-system`; pod-level securityContext patch to `kro.yaml` ensures compliance at the workload level. Namespace PSA label for `kro` controller namespace is a follow-up once a clean mechanism exists.
- `readOnlyRootFilesystem: true` for moto is backed by a `/tmp` emptyDir mount. For ACK S3 and KRO (Go controllers), the same flag is set in Helm valuesObject; if either controller writes outside `/tmp` at startup a follow-up item will add the necessary emptyDir.
