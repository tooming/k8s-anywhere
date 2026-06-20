# Planner run 2026-06-20 — PSS O2 grooming (RFC #229 + #230)

## What this run did

**Intake groomed:** two `rfc`-labeled issues filed by the architect routine on 2026-06-19.

### RFC #229 — PSS `restricted` for `external-secrets` namespace

Groomed into one 🟢 executor item `auto/pss-external-secrets` in *Now / next*:
- `gitops/external-secrets/namespace.yaml` (four `restricted` PSA labels)
- `gitops/platform/external-secrets-extras.yaml` Application (sync-wave 0, ServerSideApply)
- `gitops/platform/external-secrets.yaml` `valuesObject` securityContext block
- ADR-0017 `external-secrets → restricted` row
- `tests/securitycontext.bats` extension

Issue #229 labeled `groomed` and closed.

### RFC #230 — PSS `baseline` for `envoy-gateway-system` namespace

Groomed into one 🟢 executor item `auto/pss-envoy-gateway-system` in *Now / next*:
- `gitops/envoy-gateway-system/namespace.yaml` (four `baseline` PSA labels)
- `gitops/platform/envoy-gateway-system-extras.yaml` Application (sync-wave 0, ServerSideApply)
- ADR-0017 `envoy-gateway-system → baseline` row with flip condition
- `tests/securitycontext.bats` extension

Issue #230 labeled `groomed` and closed.

## Lane status after this run

The two new 🟢 items give the executor two immediately buildable O2 items. The remaining
blocked items (ArgoCD PSS Phase 2, verifyImages Enforce flip) still require explicit
maintainer cluster confirmation before the executor may proceed.

## Gap analysis

No new gaps found. The `docs/roadmap/incoming/` directory is empty (no pending architect
items). O5 (External Secrets dashboard) is in-flight as PR #234.
