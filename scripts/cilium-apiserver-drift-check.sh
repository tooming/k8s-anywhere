#!/usr/bin/env bash
# Cilium kube-proxy-free apiserver-host drift check.
#
# `make cilium-up` (ADR-0014) hardcodes the control-plane node's CURRENT docker-bridge
# IP into Cilium's Helm values as `k8sServiceHost`/`k8sServicePort`, baked into every
# cilium-agent pod as the `KUBERNETES_SERVICE_HOST`/`KUBERNETES_SERVICE_PORT` env vars
# (Makefile's own comment explains why: kube-proxy-free mode has no kube-proxy to
# translate the `kubernetes` ClusterIP, so agents need the real host:port directly, and
# resolving it needs the apiserver already reachable — a chicken-and-egg only solvable
# by hardcoding a value valid at cilium-up time). That value is NOT re-derived
# automatically if the node container's IP later changes — e.g. Colima/k3d stop+start,
# a `docker restart k3d-<cluster>-server-0` remediation, or any other event that gets a
# fresh docker-bridge address. When it drifts, cilium-agent can never reach the
# apiserver again: no CNI, so no pod sandbox on that node can ever be created again —
# EVERY pod needing a fresh sandbox (i.e. anything restarted after the drift) is stuck
# retrying forever with `FailedCreatePodSandBox ... unable to connect to Cilium agent`,
# which look identical to generic cluster overload/host-capacity-ceiling symptoms.
#
# First found and fixed live 2026-07-29 (docs/incident-log.md), noted there as
# "non-persistent; re-check if it recurs" — it recurred 2026-09-06, this time
# discovered mid-investigation of issue #633's "host capacity ceiling", after a
# `colima start` resumed the cluster with a new server-node IP. This script exists so
# that recurrence is a five-second check instead of a re-derived diagnosis: it compares
# the LIVE value cilium-agent is actually configured with against the node's real
# current IP and reports drift plainly, the same role
# scripts/k3s-datastore-health-check.sh plays for the kine-compactor-stall class.
#
# Detection only, like its sibling on-demand/datastore checks — the fix itself is
# `make cilium-up` (already idempotent: it always re-derives the current IP and
# re-applies, whether Cilium was never installed or has been running for weeks), so
# this script doesn't duplicate that Helm invocation (a second copy would itself be a
# drift risk — e.g. a version-pin bump landing in one copy and not the other).
#
# Wired into scripts/lab-health-check.sh (informational — never flips PASS/FAIL, same
# reasoning as ondemand-budget-check.sh/k3s-datastore-health-check.sh: an unhealthy
# always-on pod is already caught there; this just gives the root cause instead of
# generic unreadiness). Also runnable standalone: `make cilium-drift-check`.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
note() { printf '      %s%s%s\n' "$Y" "$1" "$Z"; }

echo "Cilium apiserver-host drift check (kube-proxy-free mode, ADR-0014):"
echo

command -v kubectl >/dev/null 2>&1 || { echo "kubectl not installed"; exit 2; }
kubectl get nodes >/dev/null 2>&1 || { bad "cluster unreachable (kubectl get nodes failed)"; exit 2; }

CONFIGURED_HOST="$(kubectl -n kube-system get ds cilium -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="KUBERNETES_SERVICE_HOST")].value}' 2>/dev/null)"
if [ -z "$CONFIGURED_HOST" ]; then
  note "Cilium DaemonSet not found (not installed yet on this cluster) — nothing to check"
  exit 0
fi
CONFIGURED_PORT="$(kubectl -n kube-system get ds cilium -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="KUBERNETES_SERVICE_PORT")].value}' 2>/dev/null)"

# Same derivation cilium-up itself uses — the `kubernetes` Service's live Endpoints,
# authoritative regardless of which node currently holds the apiserver.
ACTUAL_HOST="$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)"
ACTUAL_PORT="$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].ports[0].port}' 2>/dev/null)"

if [ -z "$ACTUAL_HOST" ] || [ -z "$ACTUAL_PORT" ]; then
  bad "could not resolve the live kubernetes Endpoints — is the cluster healthy?"
  exit 2
fi

if [ "$CONFIGURED_HOST" = "$ACTUAL_HOST" ] && [ "$CONFIGURED_PORT" = "$ACTUAL_PORT" ]; then
  ok "cilium-agent's apiserver host:port ($CONFIGURED_HOST:$CONFIGURED_PORT) matches the live endpoint"
  exit 0
fi

bad "cilium-agent is configured for $CONFIGURED_HOST:$CONFIGURED_PORT but the live apiserver endpoint is $ACTUAL_HOST:$ACTUAL_PORT"
note "every pod needing a fresh sandbox on an affected node will hang forever in"
note "FailedCreatePodSandBox (\"unable to connect to Cilium agent\") until this is fixed"
note "fix: make cilium-up   (idempotent — safe to re-run any time, re-derives this value fresh)"
exit 1
