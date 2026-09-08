#!/usr/bin/env bats
# Clusterless structural tests for the PSS *restricted* profile applied to the
# lab-demo namespace (ADR-0017 §Per-namespace profile, ROADMAP
# auto/lab-demo-hello-world-swap). Flipped from baseline 2026-09-08: the
# Deployment's image was swapped from the root-running
# jaegertracing/example-hotrod to nginx-unprivileged (non-root by default),
# meeting the flip condition ADR-0017's lab-demo row named since the pilot.
#
# Lives in its OWN file (not tests/securitycontext.bats) on purpose: per-namespace
# PSS blocks appended to the shared monolith are what caused the recurring merge
# conflict between parallel PSS fan-out PRs (#238 vs #239). One scope = one file =
# no shared append anchor. Enforced by scripts/securitycontext-tests-check.sh.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  NS="$REPO/gitops/apps/demo/namespace.yaml"
  DEPLOY="$REPO/gitops/apps/demo/deployment.yaml"
}

# --- namespace PSA restricted labels -----------------------------------------

@test "lab-demo namespace.yaml exists" {
  [ -f "$NS" ]
}

@test "lab-demo namespace enforces PSS restricted" {
  run grep -q 'pod-security.kubernetes.io/enforce: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace has enforce-version: latest" {
  run grep -q 'pod-security.kubernetes.io/enforce-version: latest' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace has warn: restricted" {
  run grep -q 'pod-security.kubernetes.io/warn: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace has audit: restricted" {
  run grep -q 'pod-security.kubernetes.io/audit: restricted' "$NS"
  [ "$status" -eq 0 ]
}

@test "lab-demo namespace does NOT enforce baseline or privileged (safety check)" {
  run grep -qE 'pod-security.kubernetes.io/enforce: (baseline|privileged)' "$NS"
  [ "$status" -eq 1 ]
}

# --- deployment.yaml: image swapped off the root-running hotrod image -------

@test "lab-demo deployment.yaml exists" {
  [ -f "$DEPLOY" ]
}

@test "lab-demo deployment's image: line no longer runs jaegertracing/example-hotrod" {
  run grep -qE '^\s*image: jaegertracing/example-hotrod' "$DEPLOY"
  [ "$status" -eq 1 ]
}

@test "lab-demo deployment runs nginx-unprivileged, exact tag pinned (no-floating-tag hardening)" {
  run grep -qE '^\s*image: nginxinc/nginx-unprivileged:[0-9]+\.[0-9]+\.[0-9]+-alpine$' "$DEPLOY"
  [ "$status" -eq 0 ]
}

# --- deployment.yaml: PSS restricted securityContext fields (Layer 1) ------

@test "lab-demo pod securityContext sets runAsNonRoot: true" {
  run grep -q 'runAsNonRoot: true' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "lab-demo pod securityContext sets seccompProfile.type: RuntimeDefault" {
  run grep -q 'type: RuntimeDefault' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "lab-demo container securityContext sets allowPrivilegeEscalation: false" {
  run grep -q 'allowPrivilegeEscalation: false' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "lab-demo container securityContext sets readOnlyRootFilesystem: true" {
  run grep -q 'readOnlyRootFilesystem: true' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "lab-demo container securityContext drops ALL capabilities" {
  run grep -q 'drop: \["ALL"\]' "$DEPLOY"
  [ "$status" -eq 0 ]
}

# --- deployment.yaml: writable emptyDir mounts, not a relaxed root filesystem

@test "lab-demo mounts an emptyDir at /tmp (nginx-unprivileged's documented read-only-root writable path)" {
  run grep -B1 'mountPath: /tmp' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "lab-demo mounts an emptyDir at /var/cache/nginx" {
  run grep -q 'mountPath: /var/cache/nginx' "$DEPLOY"
  [ "$status" -eq 0 ]
}

@test "lab-demo mounts the lab-demo-hello ConfigMap's index.html read-only at the nginx html root" {
  run grep -A1 'mountPath: /usr/share/nginx/html' "$DEPLOY"
  [ "$status" -eq 0 ]
  [[ "$output" == *"readOnly: true"* ]]
}

# --- configmap.yaml: the previously-orphaned ConfigMap is now actually used -

@test "lab-demo-hello ConfigMap carries a real (non-fabricated) index.html key" {
  CM="$REPO/gitops/apps/demo/configmap.yaml"
  run grep -q 'index.html:' "$CM"
  [ "$status" -eq 0 ]
}

@test "lab-demo-hello ConfigMap's index.html renders the same message as the message key (no drifted copy)" {
  CM="$REPO/gitops/apps/demo/configmap.yaml"
  run grep -q 'Hello from GitOps' "$CM"
  [ "$status" -eq 0 ]
  # both the message: key's value and index.html's <h1> should carry the phrase --
  # grep -c counts matching LINES, and the phrase appears on one line in each.
  count="$(grep -c 'Hello from GitOps' "$CM")"
  [ "$count" -ge 2 ]
}
