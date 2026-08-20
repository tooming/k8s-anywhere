#!/usr/bin/env bats
# Clusterless structural tests for Kargo (promotion-orchestration engine, ADR-0023).
# Validates GitOps wiring (Application shape, chart pin, ON-DEMAND guard for the Helm
# release, ALWAYS-ON for kargo-extras namespace pre-creation), namespace PSA labels,
# HTTPRoute, NetworkPolicy overlay, Kargo Project/Warehouse/Stage shape, and admin
# ExternalSecret — no running cluster required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  load lib/yq
}

# --- ArgoCD Application shape (ON-DEMAND, no auto-sync) ----------------------
@test "kargo Application exists" {
  [ -f "$REPO/gitops/platform/kargo.yaml" ]
}

@test "kargo Application sources the chart from the OCI registry (charts.kargo.io is dead)" {
  # https://charts.kargo.io was retired upstream (NXDOMAIN) — the chart now
  # lives at oci://ghcr.io/akuity/kargo-charts/kargo (repoURL omits the oci://
  # scheme per ArgoCD's OCI Helm convention).
  run grep -q 'repoURL: ghcr.io/akuity/kargo-charts' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'repoURL: https://charts.kargo.io' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 1 ]
}

@test "kargo Application pins a specific chart version" {
  run grep -qE 'targetRevision: [0-9]+\.[0-9]+\.[0-9]+' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application pins chart version 1.11.2" {
  run grep -q 'targetRevision: 1.11.2' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application does not pin the pre-bump 1.11.1, 1.11.0, 1.10.9, 1.6.4, or 1.2.3 versions" {
  run grep -q 'targetRevision: 1.11.1' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -ne 0 ]
  run grep -q 'targetRevision: 1.11.0' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -ne 0 ]
  run grep -q 'targetRevision: 1.10.9' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -ne 0 ]
  run grep -q 'targetRevision: 1.6.4' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -ne 0 ]
  run grep -q 'targetRevision: 1.2.3' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -ne 0 ]
}

@test "kargo Application is ON-DEMAND (no automated sync block)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 1 ]
}

@test "kargo Application targets the kargo namespace" {
  run grep -q 'namespace: kargo' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

# api.tls.selfSignedCert is a plain boolean in the chart's real schema
# (verified against charts/kargo/values.yaml at both the previous and new
# pinned tags), NOT an object with a nested `generate` key. The old
# `generate: false` shape was a silent no-op (Helm would template the
# non-empty map as truthy, generating a cert-manager Certificate the lab's
# ADR-0008 Envoy Gateway TLS termination never needed). Path-aware via
# yqs() so a regression back to the dead shape fails this test.
@test "kargo Application disables TLS self-signed cert (plain HTTP inside cluster)" {
  P="$REPO/gitops/platform/kargo.yaml"
  [ "$(yqs '.spec.source.helm.valuesObject.api.tls.selfSignedCert' "$P")" = "false" ]
}

@test "kargo Application does not use the dead selfSignedCert.generate key" {
  P="$REPO/gitops/platform/kargo.yaml"
  # selfSignedCert is a boolean (see the test above) — indexing .generate past it is
  # a type error under python-yq (jq semantics), not the null the `//` default
  # expects; mikefarah/yq tolerates it. Real CI always has mikefarah/yq.
  require_mikefarah_yq_or_skip
  [ "$(yqs '.spec.source.helm.valuesObject.api.tls.selfSignedCert.generate // "absent"' "$P")" = "absent" ]
}

@test "kargo Application sets controller memory limit" {
  run grep -q 'memory: 128Mi' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application sets api memory limit to 256Mi" {
  run grep -q 'memory: 256Mi' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo Application wires admin creds via api.secret.name (chart has no secretKeyRef field)" {
  # The kargo chart has no adminAccount.passwordHashSecretKeyRef-style field —
  # api.secret.name is the only supported way to point at a pre-existing
  # Secret (ADMIN_ACCOUNT_PASSWORD_HASH / ADMIN_ACCOUNT_TOKEN_SIGNING_KEY keys).
  run grep -A1 '          secret:' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"name: kargo-admin-credentials"* ]]
  run grep -q 'passwordHashSecretKeyRef' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 1 ]
}

@test "kargo Application references the kargo-admin-credentials Secret" {
  run grep -q 'kargo-admin-credentials' "$REPO/gitops/platform/kargo.yaml"
  [ "$status" -eq 0 ]
}

# --- kargo-extras Application (namespace + route pre-creation, wave 0) -------
@test "kargo-extras Application exists" {
  [ -f "$REPO/gitops/platform/kargo-extras.yaml" ]
}

@test "kargo-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/kargo-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-extras sources the gitops/kargo git path" {
  run grep -q 'path: gitops/kargo' "$REPO/gitops/platform/kargo-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-extras is ALWAYS-ON (has automated sync block; PSA floor before make kargo-up)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- kargo-networkpolicy Application (wave 4) --------------------------------
@test "kargo-networkpolicy Application exists" {
  [ -f "$REPO/gitops/platform/kargo-networkpolicy.yaml" ]
}

@test "kargo-networkpolicy runs at sync-wave 4" {
  run grep -q 'argocd.argoproj.io/sync-wave: "4"' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-networkpolicy is ON-DEMAND (no automated sync block)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo-networkpolicy.yaml"
  [ "$status" -eq 1 ]
}

# --- kargo-project Application (wave 6) -------------------------------------
@test "kargo-project Application exists" {
  [ -f "$REPO/gitops/platform/kargo-project.yaml" ]
}

@test "kargo-project runs at sync-wave 6 (after kargo installs CRDs)" {
  run grep -q 'argocd.argoproj.io/sync-wave: "6"' "$REPO/gitops/platform/kargo-project.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project is ON-DEMAND (no automated sync block)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kargo-project.yaml"
  [ "$status" -eq 1 ]
}

# --- Namespace PSA labels ----------------------------------------------------
@test "kargo namespace.yaml exists" {
  [ -f "$REPO/gitops/kargo/namespace.yaml" ]
}

@test "kargo namespace enforces PSA restricted (ADR-0017)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/kargo/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline namespace.yaml exists (ADR-0017 defense-in-depth)" {
  [ -f "$REPO/gitops/kargo-project/namespace.yaml" ]
}

@test "capstone-pipeline namespace carries all four PSA restricted labels" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/kargo-project/namespace.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$REPO/gitops/kargo-project/namespace.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$REPO/gitops/kargo-project/namespace.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$REPO/gitops/kargo-project/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone-pipeline namespace carries the kargo.akuity.io/project adoption label" {
  # Without this label, Kargo's Project controller refuses to adopt a
  # namespace some other agent (ArgoCD's CreateNamespace=true, or this very
  # manifest) created first — verified live: every Stage/Warehouse in the
  # namespace gets rejected at admission with "namespace already exists and
  # is not labeled as a Project namespace" until this label is present.
  run grep -q 'kargo.akuity.io/project: "true"' "$REPO/gitops/kargo-project/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- HTTPRoute ---------------------------------------------------------------
@test "kargo HTTPRoute exists" {
  [ -f "$REPO/gitops/kargo/route.yaml" ]
}

@test "kargo HTTPRoute exposes kargo.127.0.0.1.nip.io" {
  run grep -q 'kargo.127.0.0.1.nip.io' "$REPO/gitops/kargo/route.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo HTTPRoute targets the kargo-api Service on port 80" {
  run grep -q 'name: kargo-api' "$REPO/gitops/kargo/route.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'port: 80' "$REPO/gitops/kargo/route.yaml"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay ---------------------------------------------------
@test "kargo NetworkPolicy kustomization.yaml exists" {
  [ -f "$REPO/gitops/kargo/networkpolicy/kustomization.yaml" ]
}

@test "kargo NetworkPolicy kustomization references the shared default-deny template" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/kargo/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo NetworkPolicy kustomization references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/kargo/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo NetworkPolicy allows Envoy Gateway ingress to API server" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-api-from-gateway.yaml" ]
}

@test "kargo NetworkPolicy allows kube-apiserver webhook callbacks" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-webhook-from-apiserver.yaml" ]
}

@test "kargo webhook policy allows TCP 9443 from the apiserver's remote-node identity" {
  run grep -q 'port: "9443"' "$REPO/gitops/kargo/networkpolicy/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
  # fromEntities remote-node, not ipBlock: k3s embeds the apiserver in the server
  # node's own process, so its outbound webhook call carries Cilium's remote-node
  # identity + the node's real pod-network IP as source, never the apiserver's
  # Service ClusterIP (verified live with `cilium monitor --type drop`).
  run grep -q 'remote-node' "$REPO/gitops/kargo/networkpolicy/allow-kargo-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo NetworkPolicy allows egress to ArgoCD" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-egress-argocd.yaml" ]
}

@test "kargo NetworkPolicy allows egress to image registry" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-egress-registry.yaml" ]
}

# --- Kargo Project / Warehouse / Stage resources ----------------------------
@test "kargo-project manifest exists" {
  [ -f "$REPO/gitops/kargo-project/project.yaml" ]
}

@test "kargo-project declares a Kargo Project named capstone-pipeline" {
  run grep -q 'kind: Project' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'name: capstone-pipeline' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project declares a Warehouse for the capstone image" {
  run grep -q 'kind: Warehouse' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'harbor.127.0.0.1.nip.io/library/hello' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "Warehouse uses Digest image-selection strategy (imageSelectionStrategy, not tagSelectionStrategy)" {
  run grep -q 'imageSelectionStrategy: Digest' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "Warehouse does NOT use the dead tagSelectionStrategy key" {
  run grep -q 'tagSelectionStrategy:' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -ne 0 ]
}

# Found live 2026-08-06/07 (#633): Kargo 1.11.0's admission webhook rejects a
# Digest-strategy image subscription with no constraint --
# "spec.subscriptions[0].image.constraint: Invalid value: \"\": must be set
# when imageSelectionStrategy is Digest" -- Digest strategy still needs to
# know which tag's digest to watch. Verified live that adding this field
# lets the Warehouse actually create.
@test "Warehouse sets an explicit constraint for the Digest strategy (required by Kargo's admission webhook)" {
  run grep -q 'constraint: latest' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo-project declares dev and prod Stages" {
  run grep -q 'name: dev' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'name: prod' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "dev Stage subscribes directly to the Warehouse (auto-promote)" {
  run grep -q 'direct: true' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "prod Stage subscribes to Freight from dev Stage (manual gate)" {
  run grep -c 'stages:' "$REPO/gitops/kargo-project/project.yaml"
  [ "$output" -ge 1 ]
  run grep -q '\- dev' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "Stage promotion template uses argocd-update step" {
  run grep -q 'uses: argocd-update' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

@test "argocd-update step targets the capstone Application in argocd namespace" {
  run grep -q 'name: capstone' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'namespace: argocd' "$REPO/gitops/kargo-project/project.yaml"
  [ "$status" -eq 0 ]
}

# --- argocd-update image override: kustomize.images, not bare sources.images -
# The argocd-update step's config schema (verified against
# pkg/promotion/runner/builtin/schemas/argocd-update-config.json -- this file
# moved from internal/ to pkg/ between the 1.6.4 and 1.10.9 tags -- at both
# the previous and new Kargo tags) has no bare `images` field directly under
# `sources[]` -- image overrides must nest under `sources[].kustomize.images[]`
# with a `repoURL` + `digest`/`tag` pair, and the digest must come from the
# `imageFrom()` expression function, not a literal enum value. Path-aware via
# yqs() (multi-document file -- select each Stage by name) so a regression
# back to the dead shape fails these tests instead of a bare grep passing.
@test "dev Stage argocd-update step nests the image override under kustomize.images" {
  P="$REPO/gitops/kargo-project/project.yaml"
  # The digest value has literal embedded double quotes (imageFrom("...")) —
  # python-yq JSON-escapes them (\"), which yqs()'s leading/trailing-quote strip
  # doesn't unescape, so the comparison below mismatches under that variant even
  # though the query itself succeeds. Real CI always has mikefarah/yq (raw output,
  # no escaping to undo).
  require_mikefarah_yq_or_skip
  [ "$(yqs 'select(.kind == "Stage" and .metadata.name == "dev") | .spec.promotionTemplate.spec.steps[0].config.apps[0].sources[0].kustomize.images[0].repoURL' "$P")" = "harbor.127.0.0.1.nip.io/library/hello" ]
  [ "$(yqs 'select(.kind == "Stage" and .metadata.name == "dev") | .spec.promotionTemplate.spec.steps[0].config.apps[0].sources[0].kustomize.images[0].digest' "$P")" = '${{ imageFrom("harbor.127.0.0.1.nip.io/library/hello").Digest }}' ]
}

@test "dev Stage argocd-update step does NOT use the dead bare sources.images key" {
  P="$REPO/gitops/kargo-project/project.yaml"
  [ "$(yqs 'select(.kind == "Stage" and .metadata.name == "dev") | .spec.promotionTemplate.spec.steps[0].config.apps[0].sources[0].images // "absent"' "$P")" = "absent" ]
}

@test "prod Stage argocd-update step nests the image override under kustomize.images" {
  P="$REPO/gitops/kargo-project/project.yaml"
  # Same embedded-quote escaping mismatch as the dev Stage test above.
  require_mikefarah_yq_or_skip
  [ "$(yqs 'select(.kind == "Stage" and .metadata.name == "prod") | .spec.promotionTemplate.spec.steps[0].config.apps[0].sources[0].kustomize.images[0].repoURL' "$P")" = "harbor.127.0.0.1.nip.io/library/hello" ]
  [ "$(yqs 'select(.kind == "Stage" and .metadata.name == "prod") | .spec.promotionTemplate.spec.steps[0].config.apps[0].sources[0].kustomize.images[0].digest' "$P")" = '${{ imageFrom("harbor.127.0.0.1.nip.io/library/hello").Digest }}' ]
}

@test "prod Stage argocd-update step does NOT use the dead bare sources.images key" {
  P="$REPO/gitops/kargo-project/project.yaml"
  [ "$(yqs 'select(.kind == "Stage" and .metadata.name == "prod") | .spec.promotionTemplate.spec.steps[0].config.apps[0].sources[0].images // "absent"' "$P")" = "absent" ]
}

# --- Admin credentials ExternalSecret ----------------------------------------
@test "kargo admin ExternalSecret exists" {
  [ -f "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml" ]
}

@test "kargo admin ExternalSecret targets kargo-admin-credentials Secret" {
  run grep -q 'kargo-admin-credentials' "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo admin ExternalSecret references Vault path kargo/admin" {
  run grep -q 'key: kargo/admin' "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo admin ExternalSecret is in the kargo namespace" {
  run grep -q 'namespace: kargo' "$REPO/gitops/secrets/kargo-admin-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- Capstone kustomization.yaml (enables Kargo image override) --------------
@test "capstone kustomization.yaml exists (enables kustomize mode for Kargo)" {
  [ -f "$REPO/gitops/apps/capstone/kustomization.yaml" ]
}

@test "capstone kustomization.yaml includes deployment.yaml" {
  run grep -q 'deployment.yaml' "$REPO/gitops/apps/capstone/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization.yaml includes rollout.yaml" {
  run grep -q 'rollout.yaml' "$REPO/gitops/apps/capstone/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "capstone kustomization.yaml excludes networkpolicy directory (managed separately)" {
  run grep -q '^\s*- networkpolicy' "$REPO/gitops/apps/capstone/kustomization.yaml"
  [ "$status" -eq 1 ]
}

# --- Observability: Alloy scrape + Grafana dashboard (auto/kargo-observability-dashboard) ---
@test "observability-alloy.yaml has kargo scrape block" {
  run grep -q 'prometheus.scrape "kargo"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo scrape target points to kargo-api on port 8080" {
  run grep -q 'kargo-api.kargo.svc.cluster.local:8080' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "kargo NetworkPolicy overlay includes allow-kargo-metrics-ingress.yaml" {
  run grep -q 'allow-kargo-metrics-ingress.yaml' "$REPO/gitops/kargo/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-kargo-metrics-ingress.yaml exists" {
  [ -f "$REPO/gitops/kargo/networkpolicy/allow-kargo-metrics-ingress.yaml" ]
}

@test "allow-kargo-metrics-ingress.yaml targets TCP 8080 from observability namespace" {
  run grep -q 'port: 8080' "$REPO/gitops/kargo/networkpolicy/allow-kargo-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'kubernetes.io/metadata.name: observability' "$REPO/gitops/kargo/networkpolicy/allow-kargo-metrics-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-kargo.json dashboard exists" {
  [ -f "$REPO/grafana/dashboards/lab-kargo.json" ]
}

@test "lab-kargo.json dashboard references controller_runtime_reconcile_total" {
  run grep -q 'controller_runtime_reconcile_total' "$REPO/grafana/dashboards/lab-kargo.json"
  [ "$status" -eq 0 ]
}

@test "lab-kargo.json has no panel targeting a nonexistent freight controller (2026-08-12: Kargo v1.11.1 has no dedicated Freight controller — Freight objects are produced by warehouse; the redundant former 'Freight creation rate' panel was removed, keeping the one real Stage + Warehouse reconcile-rate panel pair)" {
  run grep -q 'controller=~\\"freight' "$REPO/grafana/dashboards/lab-kargo.json"
  [ "$status" -eq 1 ]
  run grep -q 'controller=~\\"warehouse.\*\\"' "$REPO/grafana/dashboards/lab-kargo.json"
  [ "$status" -eq 0 ]
}

@test "lab-kargo.json has no fabricated/placeholder data (ADR-0004)" {
  run grep -iE '"(fake|mock|placeholder|dummy|todo|fixme)"' "$REPO/grafana/dashboards/lab-kargo.json"
  [ "$status" -eq 1 ]
}

@test "docs/dependency-tree.md documents kargo, kargo-extras, and kargo-project in the apply-order table" {
  run grep -q '| — | kargo \*(on-demand)\* |' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
  run grep -q '| — | kargo-extras \*(auto-synced, wave 0)\* |' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
  run grep -q '| — | kargo-project \*(on-demand, wave 6)\* |' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}

@test "docs/dependency-tree.md's kargo chart-version citation matches the live Application pin (found stale 2026-08-20: doc said v1.11.0, live pin was already 1.11.2)" {
  live_version="$(yqs '.spec.source.targetRevision' "$REPO/gitops/platform/kargo.yaml")"
  run grep -q "chart \`kargo\` \`${live_version}\` from" "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
  # The stale citation used a "v"-prefixed, unquoted style — guard against both
  # the specific stale value and the wrong format coming back.
  run grep -qE 'chart `kargo` v[0-9]' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 1 ]
}
