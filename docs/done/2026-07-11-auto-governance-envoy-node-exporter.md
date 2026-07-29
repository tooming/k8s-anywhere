# Governance gap — add `envoy-gateway-system` and `node-exporter` to the platform governance ApplicationSet

**CHARTER Core Values** §"Resource limits everywhere"; RFC #294 execution gap — both
namespaces are always-on, carry PSA labels, and have full NP overlays, but neither
appeared in `gitops/platform/governance-appset.yaml` and no explicit exclusion for them
existed in RFC #294's rationale; no LimitRange was applied to either namespace.

Three deliverables:
1. Added two entries in the `# standard tier` block of `gitops/platform/governance-appset.yaml`:
   `appName: envoy-gateway-system-governance` and `appName: node-exporter-governance`.
2. Created `gitops/governance/envoy-gateway-system/kustomization.yaml` and
   `gitops/governance/node-exporter/kustomization.yaml`, each referencing
   `../base/limitrange-standard.yaml` (same pattern as all other standard-tier namespaces).
3. Extended `tests/governance.bats` with four assertions (two per namespace):
   kustomization file exists + references the shared base limitrange.
4. Updated `docs/dependency-tree.md` to include both namespaces in the governance AppSet
   generated-applications list.

## PR

[#362](https://github.com/tooming/k8s-anywhere/pull/362)
