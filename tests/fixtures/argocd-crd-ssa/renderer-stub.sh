#!/usr/bin/env bash
# Test stub for argocd-crd-ssa-check's render seam (CRDSSA_RENDERER). Keys off the
# chart name so the size/SSA logic is exercised offline with no real chart pulls.
#   args: <repoURL> <chart> <version> <valuesfile>
#   stdout: rendered manifests | exit 0 = rendered, exit 2 = unrenderable (skip)
set -uo pipefail
chart="${2:-}"

case "$chart" in
  big-crd-chart)
    # ~300 KB description -> CRD JSON well over the 250000-byte client-side-apply cap.
    pad="$(head -c 300000 </dev/zero | tr '\0' 'x')"
    cat <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: bigthings.example.io
spec:
  group: example.io
  names:
    kind: BigThing
    plural: bigthings
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          description: "$pad"
EOF
    ;;
  small-crd-chart)
    cat <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: smallthings.example.io
spec:
  group: example.io
  names:
    kind: SmallThing
    plural: smallthings
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
EOF
    ;;
  *)
    exit 2 ;;  # unknown chart -> unrenderable, the check skips it
esac
