#!/usr/bin/env bats
# Clusterless structural tests for Kyverno (admission policy engine, ADR-0019).
# Validates GitOps wiring (Application shape, namespace PSA labels, NetworkPolicy
# overlay), the Alloy metrics scrape job, and the Grafana dashboard — no running
# cluster required. Companion to tests/networkpolicy.bats (which covers the
# default-deny fan-out) and the auto/kyverno-engine PR's manifests.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # yqs(): yq-variant-robust scalar read (strips quoting differences).
  load lib/yq
}

# --- ArgoCD Application shape (always-on, auto-synced) ------------------------
@test "kyverno Application exists" {
  [ -f "$REPO/gitops/platform/kyverno.yaml" ]
}

@test "kyverno Application sources the kyverno chart from kyverno.github.io" {
  run grep -q 'repoURL: https://kyverno.github.io/kyverno/' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno Application pins chart version 3.8.2" {
  run grep -q 'targetRevision: 3.8.2' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno Application does not pin the pre-CVE-fix 3.3.4 version" {
  run grep -q 'targetRevision: 3.3.4' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -ne 0 ]
}

@test "kyverno Application does not pin the superseded 3.3.9 version" {
  run grep -q 'targetRevision: 3.3.9' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -ne 0 ]
}

@test "kyverno Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno Application targets the kyverno namespace" {
  run grep -q 'namespace: kyverno' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
}

# Found live 2026-08-11: the chart's startupProbe default omits timeoutSeconds
# entirely (falls back to Kubernetes' own 1s default) — same chart-default-too-tight
# footgun already fixed for Harbor's database/core/registry (PR #1040/#1102) and
# ArgoCD's repo-server (PR #1103). Observed both admissionController replicas'
# startup probes failing with "connection refused" hundreds of times over 3+ days.
# Because this webhook is fail-closed and kyverno has selfHeal:true, a live-only
# kubectl patch gets reverted on the next reconcile — must be fixed in git to hold.
@test "kyverno admissionController probes are generous enough for this host's latency (>=10s, not the 1s chart default)" {
  run grep -A45 '^          replicas: 2' "$REPO/gitops/platform/kyverno.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"startupProbe:"* ]]
  [[ "$output" == *"livenessProbe:"* ]]
  [[ "$output" == *"readinessProbe:"* ]]
  # exactly three timeoutSeconds occurrences (startup/liveness/readiness), all >= 10
  local count
  count=$(grep -c 'timeoutSeconds: 1[0-9]' <<<"$output")
  [ "$count" -ge 3 ]
}

@test "kyverno Application syncs with ServerSideApply (its policy CRDs exceed the client-side-apply cap)" {
  # clusterpolicies.kyverno.io / policies.kyverno.io are ~650 KB each, over the
  # 262144-byte client-side-apply annotation limit; without SSA repo-server can't
  # apply them and the admission controller crashloops. See scripts/argocd-crd-ssa-check.sh.
  [ "$(yqs '.spec.syncPolicy.syncOptions | contains(["ServerSideApply=true"])' "$REPO/gitops/platform/kyverno.yaml")" = "true" ]
}

# --- kyverno-extras (namespace pre-creation, wave 0) -------------------------
@test "kyverno-extras Application exists" {
  [ -f "$REPO/gitops/platform/kyverno-extras.yaml" ]
}

@test "kyverno-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/kyverno-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Namespace PSA labels (ADR-0017 / RFC #483: restricted, 2026-07-17) ------
@test "kyverno namespace manifest exists" {
  [ -f "$REPO/gitops/kyverno/namespace.yaml" ]
}

@test "kyverno namespace enforces PSA restricted (RFC #483)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/kyverno/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$REPO/gitops/kyverno/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$REPO/gitops/kyverno/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$REPO/gitops/kyverno/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno namespace does NOT enforce baseline or privileged (safety check)" {
  run grep -q 'pod-security.kubernetes.io/enforce: baseline' "$REPO/gitops/kyverno/namespace.yaml"
  [ "$status" -ne 0 ]
  run grep -q 'pod-security.kubernetes.io/enforce: privileged' "$REPO/gitops/kyverno/namespace.yaml"
  [ "$status" -ne 0 ]
}

# --- NetworkPolicy overlay structure (ADR-0016 §4 fan-out) -------------------
@test "kyverno NetworkPolicy kustomization references the default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno NetworkPolicy kustomization references the allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno NetworkPolicy kustomization references the webhook allow file" {
  run grep -q 'allow-kyverno-webhook-from-apiserver.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno NetworkPolicy kustomization references the metrics allow file" {
  run grep -q 'allow-kyverno-metrics-from-observability.yaml' "$REPO/gitops/kyverno/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

# --- Webhook allow rule (apiserver -> admission webhook :9443) ----------------
@test "webhook allow file opens TCP 9443" {
  run grep -q 'port: "9443"' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# fromEntities remote-node, not ipBlock: k3s embeds the apiserver in the server
# node's own process, so its outbound webhook call carries Cilium's remote-node
# identity + the node's real pod-network IP as source, never the apiserver's
# Service ClusterIP (verified live with `cilium monitor --type drop`).
@test "webhook allow file scopes ingress to the apiserver via fromEntities remote-node" {
  run grep -q 'remote-node' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-webhook-from-apiserver.yaml"
  [ "$status" -eq 0 ]
}

# --- Metrics allow rule (observability Alloy -> metrics :8000) ----------------
@test "metrics allow file opens TCP 8000" {
  run grep -q 'port: 8000' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

@test "metrics allow file admits the observability namespace" {
  run grep -q 'kubernetes.io/metadata.name: observability' "$REPO/gitops/kyverno/networkpolicy/allow-kyverno-metrics-from-observability.yaml"
  [ "$status" -eq 0 ]
}

# --- Alloy scrape job --------------------------------------------------------
@test "Alloy has a kyverno scrape job" {
  run grep -q 'prometheus.scrape "kyverno"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "Alloy kyverno scrape targets a kyverno metrics Service on :8000" {
  run grep -qE 'kyverno-.*-controller-metrics\.kyverno\.svc\.cluster\.local:8000' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

# --- Grafana dashboard (ADR-0004 real metrics) -------------------------------
@test "Grafana dashboard file lab-kyverno.json exists" {
  [ -f "$REPO/grafana/dashboards/lab-kyverno.json" ]
}

@test "lab-kyverno.json is valid JSON" {
  if ! command -v python3 >/dev/null 2>&1; then skip "python3 not installed"; fi
  run python3 -c "import json,sys; json.load(open('$REPO/grafana/dashboards/lab-kyverno.json'))"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json uid is lab-kyverno" {
  run grep -q '"uid": "lab-kyverno"' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json has a stat-row pod-running panel" {
  run grep -q 'kube_pod_status_phase{namespace=\\"kyverno\\"' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json charts kyverno_policy_results_total by validation/background mode" {
  run grep -q 'kyverno_policy_results_total' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
  run grep -q 'policy_validation_mode' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json charts admission review p95 latency" {
  run grep -q 'kyverno_admission_review_duration_seconds_bucket' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

@test "lab-kyverno.json filters policy execution results to non-pass" {
  run grep -q 'rule_result!=\\"pass\\"' "$REPO/grafana/dashboards/lab-kyverno.json"
  [ "$status" -eq 0 ]
}

# --- ADR documentation -------------------------------------------------------
@test "ADR-0019 (Kyverno) document exists" {
  run sh -c "ls $REPO/docs/decisions/adr-0019-*.md"
  [ "$status" -eq 0 ]
}

# --- kyverno-policies Application (sync-wave 5, after engine CRDs) -----------
@test "kyverno-policies Application exists" {
  [ -f "$REPO/gitops/platform/kyverno-policies.yaml" ]
}

@test "kyverno-policies Application runs at sync-wave 5" {
  run grep -q 'argocd.argoproj.io/sync-wave: "5"' "$REPO/gitops/platform/kyverno-policies.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno-policies Application is auto-synced (always-on)" {
  run grep -q 'automated:' "$REPO/gitops/platform/kyverno-policies.yaml"
  [ "$status" -eq 0 ]
}

@test "kyverno-policies Application sources gitops/kyverno/policies" {
  run grep -q 'path: gitops/kyverno/policies' "$REPO/gitops/platform/kyverno-policies.yaml"
  [ "$status" -eq 0 ]
}

# --- Four ClusterPolicy files exist ------------------------------------------
@test "require-pod-security-restricted ClusterPolicy file exists" {
  [ -f "$REPO/gitops/kyverno/policies/require-pod-security-restricted.yaml" ]
}

@test "disallow-latest-tag ClusterPolicy file exists" {
  [ -f "$REPO/gitops/kyverno/policies/disallow-latest-tag.yaml" ]
}

# --- capstone carve-out (issue #498) ------------------------------------------
@test "disallow-latest-tag excludes the capstone namespace" {
  P="$REPO/gitops/kyverno/policies/disallow-latest-tag.yaml"
  [ "$(yqs '.spec.rules[0].exclude.any[0].resources.namespaces[0]' "$P")" = "capstone" ]
}

# argocd carve-out REMOVED 2026-08-06 (issue #999 confirmed: live terraform apply
# picked up the v3.5.0 pin, every ArgoCD Pod verified running v3.5.0, not :latest).

# --- inkless carve-out (found 2026-07-28, structural sweep) --------------------
@test "disallow-latest-tag excludes the inkless namespace (no stable release tag upstream)" {
  P="$REPO/gitops/kyverno/policies/disallow-latest-tag.yaml"
  [ "$(yqs '.spec.rules[0].exclude.any[0].resources.namespaces[1]' "$P")" = "inkless" ]
}

@test "disallow-latest-tag exclude block is scoped to named namespaces only (not a blanket exclusion)" {
  P="$REPO/gitops/kyverno/policies/disallow-latest-tag.yaml"
  [ "$(yqs '.spec.rules[0].exclude.any[0].resources.namespaces | length' "$P")" = "2" ]
}

# Regression: issue #999 confirmed live and the carve-out was removed 2026-08-06 —
# pin this so a future edit can't silently reintroduce it without a matching new gate.
@test "disallow-latest-tag no longer excludes the argocd namespace (issue #999 resolved)" {
  P="$REPO/gitops/kyverno/policies/disallow-latest-tag.yaml"
  run grep -q 'argocd' <(yqs '.spec.rules[0].exclude.any[0].resources.namespaces' "$P")
  [ "$status" -eq 1 ]
}

@test "add-default-seccomp ClusterPolicy file exists" {
  [ -f "$REPO/gitops/kyverno/policies/add-default-seccomp.yaml" ]
}

@test "verify-image-signatures ClusterPolicy file exists" {
  [ -f "$REPO/gitops/kyverno/policies/verify-image-signatures.yaml" ]
}

# --- PSS backstop policy structural checks -----------------------------------
@test "PSS backstop skips namespaces labelled pod-security.kubernetes.io/enforce=baseline" {
  run grep -q 'pod-security.kubernetes.io/enforce' "$REPO/gitops/kyverno/policies/require-pod-security-restricted.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'baseline' "$REPO/gitops/kyverno/policies/require-pod-security-restricted.yaml"
  [ "$status" -eq 0 ]
}

@test "PSS backstop skips namespaces labelled pod-security.kubernetes.io/enforce=privileged" {
  run grep -q 'privileged' "$REPO/gitops/kyverno/policies/require-pod-security-restricted.yaml"
  [ "$status" -eq 0 ]
}

@test "PSS backstop is in Enforce mode (backstops ADR-0017)" {
  run grep -q 'validationFailureAction: Enforce' "$REPO/gitops/kyverno/policies/require-pod-security-restricted.yaml"
  [ "$status" -eq 0 ]
}

@test "PSS backstop checks runAsNonRoot at the POD level (matches every lab manifest; kubelet-enforced)" {
  # The pattern must require runAsNonRoot at the pod securityContext — that's where PSS,
  # the PSA enforce=restricted label, and every plain-manifest workload set it. Demanding
  # it at the CONTAINER level (which no lab workload does) makes the Enforce policy reject
  # mimir/loki/tempo/moto/rabbitmq/valkey/… the instant the admission controller is healthy.
  P="$REPO/gitops/kyverno/policies/require-pod-security-restricted.yaml"
  [ "$(yqs '.spec.rules[0].validate.pattern.spec.securityContext.runAsNonRoot' "$P")" = "true" ]
  [ "$(yqs '.spec.rules[0].validate.pattern.spec.containers[0].securityContext.runAsNonRoot // "absent"' "$P")" = "absent" ]
}

# --- seccomp mutation structural checks --------------------------------------
@test "add-default-seccomp uses patchStrategicMerge shape" {
  run grep -q 'patchStrategicMerge' "$REPO/gitops/kyverno/policies/add-default-seccomp.yaml"
  [ "$status" -eq 0 ]
}

@test "add-default-seccomp injects RuntimeDefault via conditional anchor" {
  run grep -q 'seccompProfile' "$REPO/gitops/kyverno/policies/add-default-seccomp.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'RuntimeDefault' "$REPO/gitops/kyverno/policies/add-default-seccomp.yaml"
  [ "$status" -eq 0 ]
}

# --- verifyImages policy structural checks -----------------------------------
@test "verify-image-signatures references the Harbor registry pattern" {
  run grep -q 'harbor.127.0.0.1.nip.io' "$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  [ "$status" -eq 0 ]
}

@test "verify-image-signatures is in Audit mode until cosign CI is wired" {
  run grep -q 'validationFailureAction: Audit' "$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  [ "$status" -eq 0 ]
}

@test "verify-image-signatures has failurePolicy: Ignore (lab functional before cosign CI lands)" {
  run grep -q 'failurePolicy: Ignore' "$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  [ "$status" -eq 0 ]
}

@test "verify-image-signatures references the cosign-public-key Secret in kyverno namespace" {
  run grep -q 'cosign-public-key' "$REPO/gitops/kyverno/policies/verify-image-signatures.yaml"
  [ "$status" -eq 0 ]
}

@test "docs/dependency-tree.md wave-0 row lists kyverno-extras with the current restricted PSA level" {
  run grep -q 'kyverno-extras (namespace PSA restricted labels' "$REPO/docs/dependency-tree.md"
  [ "$status" -eq 0 ]
}
