# Governance LimitRange consolidation — shared base file

**Date:** 2026-07-02
**Branch:** chore/governance-limitrange-base
**Role:** Janitor (autonomous)

## What changed

The 17 standard-tier governance namespaces (argocd, capstone, kyverno, external-secrets,
velero, argo-rollouts, trivy-system, moto, ack-system, kro, kargo, lab-demo, data,
storage, vault, lab-gateway, kiali) each had a byte-for-byte identical `limitrange.yaml`
file. Every file differed only in a one-line header comment and `metadata.namespace`.

This cleanup:
- Created `gitops/governance/base/limitrange-standard.yaml` — a single shared LimitRange
  spec without `metadata.namespace` (Kustomize stamps the namespace from the overlay's
  `namespace:` field at build time)
- Updated all 17 `kustomization.yaml` files: replaced `- limitrange.yaml` with
  `- ../../base/limitrange-standard.yaml`
- Deleted all 17 per-namespace `limitrange.yaml` files
- Updated `tests/governance.bats`: three test blocks now reference the base file rather
  than per-namespace files; observability (heavy-tier) is unchanged

## Why this is behavior-preserving

Kustomize overlays inherit the shared spec, then stamp `metadata.namespace: <ns>` from
the `namespace:` field in each overlay's `kustomization.yaml`. The resulting manifests
applied by ArgoCD are identical to what was applied before — only the source of truth
changed from 17 copies to 1.

## What this prevents

Any future standard-tier namespace governance overlay added by copy-paste will
automatically reference the canonical spec and cannot silently diverge (wrong CPU/memory
limits, missing field). Previously, editing the standard profile required 17 synchronized
edits; now it's one file.
