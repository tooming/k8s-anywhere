#!/usr/bin/env bats
# Clusterless structural tests for Harbor on-demand OCI registry (ADR-0024, RFC #297).
# Validates GitOps wiring (Application shape, namespace PSA labels, HTTPRoute, ExternalSecret),
# the Garage bootstrap seam, and the Grafana Lab UIs panel — no running cluster required.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
}

# --- ArgoCD Application shape (on-demand, no automated sync) ------------------
@test "harbor Application exists" {
  [ -f "$REPO/gitops/platform/harbor.yaml" ]
}

@test "harbor Application sources the goharbor chart from helm.goharbor.io (ADR-0024)" {
  run grep -q 'repoURL: https://helm.goharbor.io' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application pins chart harbor (not artifactory-oss)" {
  run grep -q 'chart: harbor' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application pins chart version 1.19.2" {
  run grep -qE 'targetRevision: 1\.19\.2' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application has NO automated sync block (on-demand, ADR-0024)" {
  run grep -q 'automated:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -ne 0 ]
}

@test "harbor Application targets the harbor namespace" {
  run grep -q 'namespace: harbor' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

# --- Minimal profile (ADR-0024 §"Minimal profile") ----------------------------
@test "harbor Application disables bundled trivy (Trivy Operator covers scanning, ADR-0022)" {
  run grep -q 'enabled: false' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application sets trivy.enabled: false" {
  run grep -A1 'trivy:' "$REPO/gitops/platform/harbor.yaml"
  [[ "$output" == *"enabled: false"* ]]
}

@test "harbor Application sets notary.enabled: false (out of scope first cut)" {
  run grep -A1 'notary:' "$REPO/gitops/platform/harbor.yaml"
  [[ "$output" == *"enabled: false"* ]]
}

@test "harbor Application uses clusterIP expose type (Envoy fronts ingress, ADR-0008)" {
  run grep -q 'type: clusterIP' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application disables TLS (Envoy HTTPRoute fronts plain HTTP, ADR-0008)" {
  run grep -q 'tls:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application sets externalURL to harbor.127.0.0.1.nip.io:8000" {
  run grep -q 'externalURL: http://harbor.127.0.0.1.nip.io:8000' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

# --- Garage S3 backend (ADR-0002 binding) ------------------------------------
@test "harbor Application configures S3 storage type (ADR-0002)" {
  run grep -q 'type: s3' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application configures Garage S3 endpoint (ADR-0002)" {
  run grep -q 'regionendpoint: http://garage.storage.svc.cluster.local:3900' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor Application uses harbor-registry bucket" {
  run grep -q 'bucket: harbor-registry' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

# `extraEnvVarsSecret` is NOT a real field in goharbor/harbor 1.19.2 — checked directly
# against the chart's own templates (grep -rn extraEnvVarsSecret templates/registry/
# on `helm pull goharbor/harbor --version 1.19.2` finds zero matches). A prior version
# of harbor.yaml used that field and Helm silently ignored it, so the registry
# container never actually received S3 credentials — the real root cause of #631's
# push failures (`s3aws: NoCredentialProviders`), found live 2026-08-11. The chart only
# wires `registry.registry.extraEnvVars` (a literal list); this asserts the two S3 key
# env vars are present there via `valueFrom.secretKeyRef` against harbor-s3-creds, and
# that the broken field name doesn't silently creep back in.
@test "harbor Application references harbor-s3-creds secret for S3 credentials (never inline)" {
  run grep -q '^\s*extraEnvVarsSecret:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 1 ]
  run grep -A40 '^        registry:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"name: REGISTRY_STORAGE_S3_ACCESSKEY"* ]]
  [[ "$output" == *"name: REGISTRY_STORAGE_S3_SECRETKEY"* ]]
  [[ "$output" == *"name: harbor-s3-creds"* ]]
}

# --- Namespace PSA labels (ADR-0017: restricted target) ----------------------
@test "harbor namespace manifest exists" {
  [ -f "$REPO/gitops/harbor/namespace.yaml" ]
}

@test "harbor namespace enforces PSA restricted (ADR-0017 + ADR-0024 Go runtime target)" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$REPO/gitops/harbor/namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$REPO/gitops/harbor/namespace.yaml"
  [ "$status" -eq 0 ]
}

# --- harbor-extras (auto-synced wave 0, pre-creates namespace + route) --------
@test "harbor-extras Application exists" {
  [ -f "$REPO/gitops/platform/harbor-extras.yaml" ]
}

@test "harbor-extras runs at sync-wave 0" {
  run grep -q 'argocd.argoproj.io/sync-wave: "0"' "$REPO/gitops/platform/harbor-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-extras Application is auto-synced (always-on PSA floor)" {
  run grep -q 'automated:' "$REPO/gitops/platform/harbor-extras.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-extras Application sources the gitops/harbor path" {
  run grep -q 'path: gitops/harbor' "$REPO/gitops/platform/harbor-extras.yaml"
  [ "$status" -eq 0 ]
}

# --- Envoy HTTPRoute (ADR-0008) -----------------------------------------------
@test "harbor HTTPRoute manifest exists" {
  [ -f "$REPO/gitops/harbor/route.yaml" ]
}

@test "harbor HTTPRoute uses host harbor.127.0.0.1.nip.io" {
  run grep -q '"harbor.127.0.0.1.nip.io"' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor HTTPRoute backendRef targets harbor service port 80" {
  run grep -q 'port: 80' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor HTTPRoute parentRef targets the lab-gateway (eg)" {
  run grep -q 'namespace: lab-gateway' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
}

# Found live 2026-08-13 (#631): every `docker push` blob-upload session
# consistently 504'd on its first POST to /v2/<repo>/blobs/uploads/ — Envoy
# Gateway's ~15s default request timeout is too tight for harbor-core proxying
# to a cold registry connection under this host's real load. Recurrence guard
# for a fix that landed as a direct live-verified commit (no PR) — without this
# assertion, a future edit could silently drop the `timeouts:` block and
# reintroduce the near-100%-failure-rate push timeout with no gate catching it.
@test "harbor HTTPRoute sets a 60s request/backendRequest timeout (chart default too tight under load)" {
  run grep -q 'timeouts:' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'request: 60s' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
  run grep -q 'backendRequest: 60s' "$REPO/gitops/harbor/route.yaml"
  [ "$status" -eq 0 ]
}

# --- ExternalSecret for S3 credentials (ESO Vault→K8s pattern) ---------------
@test "harbor-s3 ExternalSecret exists" {
  [ -f "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml" ]
}

@test "harbor-s3 ExternalSecret references Vault path harbor/s3" {
  run grep -q 'key: harbor/s3' "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-s3 ExternalSecret renders harbor-s3-creds Secret" {
  run grep -q 'name: harbor-s3-creds' "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-s3 ExternalSecret renders REGISTRY_STORAGE_S3_ACCESSKEY env key" {
  run grep -q 'REGISTRY_STORAGE_S3_ACCESSKEY' "$REPO/gitops/secrets/harbor-s3-externalsecret.yaml"
  [ "$status" -eq 0 ]
}

# --- Garage bootstrap seam (harbor-key + harbor-registry bucket) --------------
@test "garage-bootstrap.sh creates harbor-key access key" {
  run grep -q 'harbor-key' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh creates harbor-registry bucket" {
  run grep -q 'harbor-registry' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

@test "garage-bootstrap.sh stores harbor S3 creds at secret/harbor/s3 in Vault" {
  run grep -q 'secret/harbor/s3' "$REPO/scripts/garage-bootstrap.sh"
  [ "$status" -eq 0 ]
}

# --- Grafana Lab UIs panel (stack-health.json drift check) --------------------
@test "harbor.127.0.0.1.nip.io is present in the Grafana Lab UIs panel" {
  run grep -q 'harbor.127.0.0.1.nip.io' "$REPO/grafana/dashboards/stack-health.json"
  [ "$status" -eq 0 ]
}

@test "harbor Lab UIs panel URL uses the :8000 front-door port" {
  run grep -q 'harbor.127.0.0.1.nip.io:8000' "$REPO/grafana/dashboards/stack-health.json"
  [ "$status" -eq 0 ]
}

# --- NetworkPolicy overlay (ADR-0016 §4 fan-out) ------------------------------
@test "harbor networkpolicy kustomization exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/kustomization.yaml" ]
}

@test "harbor networkpolicy kustomization references default-deny baseline" {
  run grep -q 'default-deny.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor networkpolicy kustomization references allow-dns-and-apiserver baseline" {
  run grep -q 'allow-dns-and-apiserver.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor networkpolicy kustomization references the ClusterIP egress bridge" {
  # The bridge is the shared baseline template (gitops/network/policies/), not the
  # per-namespace allow-harbor-clusterip-egress.yaml copy — referencing both would
  # duplicate metadata.name zz-dns-clusterip-bridge and break the Kustomize build.
  run grep -q 'network/policies/zz-dns-clusterip-bridge.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-clusterip-egress.yaml does not exist (superseded by the shared zz-dns-clusterip-bridge template)" {
  # The per-namespace copy was dropped from kustomization.yaml's resources: list
  # (see the "references the ClusterIP egress bridge" test above) but the file
  # itself was left on disk and kept being edited as if live for a month (PR
  # #716) — kustomize builds ignore it silently, so nothing caught the drift
  # until scripts/kustomize-orphan-check.sh started checking for it. Its
  # CiliumNetworkPolicy content is already covered by
  # tests/networkpolicy.bats's zz-dns-clusterip-bridge assertions.
  [ ! -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-clusterip-egress.yaml" ]
}

@test "harbor allow-harbor-ingress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-ingress.yaml" ]
}

@test "harbor ingress allow targets port 80 from envoy-gateway-system" {
  run grep -q 'kubernetes.io/metadata.name: envoy-gateway-system' \
    "$REPO/gitops/harbor/networkpolicy/allow-harbor-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor ingress allow is on port 80 (unified clusterIP expose)" {
  run grep -q 'port: 80' "$REPO/gitops/harbor/networkpolicy/allow-harbor-ingress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-garage-egress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-garage-egress.yaml" ]
}

@test "harbor garage egress allow targets port 3900 to storage namespace" {
  run grep -q 'kubernetes.io/metadata.name: storage' \
    "$REPO/gitops/harbor/networkpolicy/allow-harbor-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor garage egress allow uses port 3900" {
  run grep -q 'port: 3900' "$REPO/gitops/harbor/networkpolicy/allow-harbor-garage-egress.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor allow-harbor-intra-namespace.yaml exists (internal DB + component traffic)" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-intra-namespace.yaml" ]
}

@test "harbor intra-namespace allow has podSelector ingress" {
  run grep -q 'podSelector: {}' "$REPO/gitops/harbor/networkpolicy/allow-harbor-intra-namespace.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-networkpolicy entry present in networkpolicy-appset.yaml" {
  run grep -q 'harbor-networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor-networkpolicy appset entry uses gitops/harbor/networkpolicy path" {
  run grep -q 'gitPath: gitops/harbor/networkpolicy' "$REPO/gitops/platform/networkpolicy-appset.yaml"
  [ "$status" -eq 0 ]
}

# --- Makefile harbor-up / harbor-down targets (auto/harbor-make-targets) ------
@test "harbor-up .PHONY target exists in Makefile" {
  run grep -q '\.PHONY: harbor-up' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "harbor-up syncs the harbor Application" {
  run grep -A5 '\.PHONY: harbor-up' "$REPO/Makefile"
  [[ "$output" == *"argocd-sync,harbor)"* ]]
}

@test "harbor-up syncs harbor-extras (namespace PSA floor + route)" {
  run grep -A5 '\.PHONY: harbor-up' "$REPO/Makefile"
  [[ "$output" == *"argocd-sync,harbor-extras)"* ]]
}

@test "harbor-down .PHONY target exists in Makefile" {
  run grep -q '\.PHONY: harbor-down' "$REPO/Makefile"
  [ "$status" -eq 0 ]
}

@test "harbor-down deletes harbor-extras before harbor" {
  run grep -A5 '\.PHONY: harbor-down' "$REPO/Makefile"
  [[ "$output" == *"argocd-delete,harbor-extras)"* ]]
}

@test "harbor-down deletes harbor Application" {
  run grep -A5 '\.PHONY: harbor-down' "$REPO/Makefile"
  [[ "$output" == *"argocd-delete,harbor)"* ]]
}

# --- Observability — metrics + scrape + dashboard (auto/harbor-observability-dashboard) ---
@test "harbor Application has metrics.enabled: true (exposes harbor-metrics Service)" {
  run grep -q 'enabled: true' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor networkpolicy kustomization references allow-harbor-metrics-ingress.yaml" {
  run grep -q 'allow-harbor-metrics-ingress.yaml' "$REPO/gitops/harbor/networkpolicy/kustomization.yaml"
  [ "$status" -eq 0 ]
}

@test "allow-harbor-metrics-ingress.yaml exists" {
  [ -f "$REPO/gitops/harbor/networkpolicy/allow-harbor-metrics-ingress.yaml" ]
}

@test "allow-harbor-metrics-ingress.yaml targets port 9090 from observability namespace" {
  F="$REPO/gitops/harbor/networkpolicy/allow-harbor-metrics-ingress.yaml"
  run grep -q 'port: 9090' "$F"
  [ "$status" -eq 0 ]
  run grep -q 'kubernetes.io/metadata.name: observability' "$F"
  [ "$status" -eq 0 ]
}

@test "observability-alloy.yaml contains harbor scrape block" {
  run grep -q 'prometheus.scrape "harbor"' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "harbor scrape target uses harbor-metrics.harbor.svc.cluster.local:9090" {
  run grep -q 'harbor-metrics.harbor.svc.cluster.local:9090' "$REPO/gitops/platform/observability-alloy.yaml"
  [ "$status" -eq 0 ]
}

@test "lab-harbor.json dashboard exists" {
  [ -f "$REPO/grafana/dashboards/lab-harbor.json" ]
}

@test "lab-harbor.json references the real harbor_project_artifact_total metric, not the nonexistent harbor_artifact_total (ADR-0004)" {
  run grep -q 'harbor_project_artifact_total' "$REPO/grafana/dashboards/lab-harbor.json"
  [ "$status" -eq 0 ]
}

@test "lab-harbor.json contains no fabricated or placeholder data (ADR-0004)" {
  run grep -qi 'placeholder\|TODO\|FIXME\|fake\|dummy\|fabricat' "$REPO/grafana/dashboards/lab-harbor.json"
  [ "$status" -ne 0 ]
}

# --- Probe timeouts (found live 2026-08-06) -----------------------------------
# The chart's own default timeoutSeconds: 1 (every component) is too tight for a
# resource-constrained host under any real load — exec healthchecks routinely took
# longer than 1s here, causing a self-inflicted crashloop-on-every-recreation with
# nothing to do with actual component health. Every component gets at least a 5s
# override (database.internal specifically needs more — see the next test).
@test "harbor Application overrides component probe timeoutSeconds to >= 5s" {
  run grep -c 'timeoutSeconds: 5' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [ "$output" -ge 6 ]
}

# Found live 2026-08-11: even 5s wasn't enough for database.internal under sustained
# host latency — killing the exec'd healthcheck mid-script produced a SIGPIPE the
# postgres supervisor treated as a fatal crash, triggering a full crash-recovery
# cycle roughly every minute. That's what was actually root-causing harbor-core's
# endless connection failures this whole investigation, not a DNS or core bug.
# Bumped to 15s (matching the convention already used for Kyverno/ArgoCD) — verified
# live this let the database run stable for 7+ minutes straight, versus under a
# minute before.
@test "harbor Application overrides database.internal probe timeoutSeconds to 15s (5s wasn't enough)" {
  run grep -A40 '^        database:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"timeoutSeconds: 15"* ]]
  local count
  count=$(grep -c 'timeoutSeconds: 15' <<<"$output")
  [ "$count" -ge 2 ]
}

@test "harbor Application overrides core probe timeouts (startup/liveness/readiness)" {
  run grep -A20 '^        core:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"startupProbe"* ]]
  [[ "$output" == *"livenessProbe"* ]]
  [[ "$output" == *"readinessProbe"* ]]
}

@test "harbor Application overrides exporter probe timeouts" {
  run grep -A5 '^        exporter:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"timeoutSeconds: 5"* ]]
}

# 2026-08-10: this host is arm64 (Apple Silicon); goharbor/harbor-core and
# harbor-jobservice publish amd64-only images, so both run under QEMU x86_64
# emulation. Under real multi-core parallelism (the chart's default GOMAXPROCS,
# unset -> visible host cores) this repeatedly produced genuine Go runtime
# memory-safety panics (`concurrent map writes`, `growslice: len out of range`,
# a different one each crash -- the signature of an emulation-induced data
# race, not app logic) that crashlooped both components indefinitely across
# multiple sessions, while every other Harbor component (also emulated, but
# far less concurrent) stayed stable. GOMAXPROCS=1 forces single-threaded Go
# scheduling, eliminating the race window -- verified live: both went from
# perpetual CrashLoopBackOff to stable within seconds of setting this.
@test "harbor core sets GOMAXPROCS=1 (arm64 host runs amd64 image under QEMU emulation)" {
  run grep -A60 '^        core:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GOMAXPROCS"* ]]
  [[ "$output" == *'value: "1"'* ]]
}

# 2026-08-11: GOMAXPROCS=1 reduced but did not eliminate the QEMU-emulation crash
# class -- core kept segfaulting (`fatal error: fault` / SIGSEGV) inside
# encoding/gob while decoding the embedded OpenAPI spec at startup, same fault
# address every time. That's single-threaded work, so not a data race between
# goroutines -- it's Go's async-preemption signal landing mid-instruction while
# QEMU's x86_64 emulation is mid-translation, corrupting in-flight state.
# GODEBUG=asyncpreemptoff=1 disables that signal-based preemption entirely.
# Verified live: core went from crashing every 1-5 min to stable 3h45m+ straight.
@test "harbor core sets GODEBUG=asyncpreemptoff=1 (QEMU async-preemption SIGSEGV)" {
  run grep -A60 '^        core:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GODEBUG"* ]]
  [[ "$output" == *'value: "asyncpreemptoff=1"'* ]]
}

@test "harbor jobservice sets GOMAXPROCS=1 (same emulated-host root cause as core)" {
  run grep -A30 '^        jobservice:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GOMAXPROCS"* ]]
  [[ "$output" == *'value: "1"'* ]]
}

# 2026-08-18: registry-photon (also amd64-only, same QEMU-emulation host as core/
# jobservice) never got this mitigation because it never crashed under startup —
# it crashed the first time it did real, sustained S3 blob-upload I/O to Garage,
# which had never actually happened before this session's storage/networkpolicy
# fix (gitops/storage/networkpolicy/allow-garage-s3-from-harbor.yaml: the
# ingress-side rule allowing harbor -> garage traffic was missing, silently
# dropping every upload). Once that NetworkPolicy gap was fixed and blob uploads
# actually reached Garage, registry hit the identical Go-runtime-panic-under-
# emulation class core/jobservice were fixed for on 2026-08-10/11.
@test "harbor registry sets GOMAXPROCS=1 (same emulated-host root cause as core/jobservice, exposed once NetworkPolicy let it do real S3 I/O)" {
  # -A50: the pre-existing extraEnvVars comment block (explaining the
  # extraEnvVarsSecret / S3 credential fix) runs long before GOMAXPROCS appears.
  run grep -A50 '^          registry:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GOMAXPROCS"* ]]
  [[ "$output" == *'value: "1"'* ]]
}

@test "harbor registry sets GODEBUG=asyncpreemptoff=1 (same QEMU async-preemption class as core)" {
  run grep -A50 '^          registry:' "$REPO/gitops/platform/harbor.yaml"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GODEBUG"* ]]
  [[ "$output" == *'value: "asyncpreemptoff=1"'* ]]
}
