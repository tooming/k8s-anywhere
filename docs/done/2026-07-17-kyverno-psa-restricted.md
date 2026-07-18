# `kyverno` PSA `baseline` → `restricted` flip

CHARTER **Objective O2** hardening, RFC #483 — architect decision 2026-07-17, converting
audit #482. Kyverno's own official docs (`kyverno.io/docs/installation/platform-notes/`)
state the chart's default securityContext "conforms to the upstream Pod Security
Standards' restricted profile" (the only documented incompatibility is OpenShift SCCs,
irrelevant to this plain-k3d/k3s lab); independently verified against the actual pinned
`kyverno-chart-3.3.4` tag that all four controllers (admission/background/cleanup/
reports) already default to the full restricted container securityContext with no
hostPath/host-namespace usage. No chart bump needed.

Per RFC #483's higher-caution requirement (Kyverno is the cluster-wide admission
controller — higher blast radius than the vault flip), independently re-verified the
pinned chart's rendered manifests fresh before touching the namespace label: confirmed
`hostNetwork: false` and the `sigstoreVolume` default (`emptyDir: {}`) for all four
controllers, and no top-level securityContext override. Found one real question during
that re-verification: this repo's own `require-pod-security-restricted` ClusterPolicy
backstop checks `runAsNonRoot`/`seccompProfile` at the **pod** level, but the chart only
sets those at container level. Resolved by confirming Kyverno's own webhook
self-protection (`config.excludeKyvernoNamespace: true` in the pinned chart) excludes the
`kyverno` namespace from Kyverno's own generated webhooks entirely — so that policy never
evaluates against Kyverno's own pods regardless of level, and the actual mechanism being
flipped (the built-in Kubernetes PSA) already accepts container-level settings. No
`valuesObject` override was needed — matches this repo's existing `keda`/`cert-manager`
precedent (no carve-out when the chart already complies).

Flipped `gitops/kyverno/namespace.yaml`'s four PSA labels `baseline` → `restricted`.
Updated the `kyverno` row in both ADR-0017 and ADR-0019, and appended a dated
ADR-0017 §Re-evaluation log entry recording the verification and the self-protection
finding. Updated `tests/kyverno.bats` (flipped + extended the namespace-label assertions:
restricted, enforce-version, warn, audit, plus a baseline/privileged safety check) and
removed the now-stale `"kyverno namespace.yaml exists and enforces PSS baseline"` test
from the frozen `tests/securitycontext.bats` monolith (its sibling `enforce-version`
assertion there is untouched, still accurate). `make ci` passes.

**Caveat (ADR-0004).** This environment is remote and clusterless — whether Kyverno's
admission webhook stays healthy under `restricted` on a live cluster is not verifiable
here. The self-protection exclusion is documented Kyverno behavior (verified against the
pinned chart's real `values.yaml`), not an assumption, but the maintainer should watch
cluster admission health closely after this syncs, given Kyverno's blast radius as the
cluster-wide admission controller. Rollback: revert the namespace label commit — ArgoCD
self-heals within its sync interval; no other component changed.

## PR

https://github.com/tooming/k8s-anywhere/pull/486
