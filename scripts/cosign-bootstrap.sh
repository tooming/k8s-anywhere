#!/usr/bin/env bash
# Day-0 seam: generate a cosign keypair and seed the public key into the
# 'cosign-public-key' ConfigMap in the 'kyverno' namespace.
# ADR-0019 §"Cosign keypair management". Safe to re-run (idempotent).
# Wired into 'make up' after garage-bootstrap (kyverno namespace is synced
# by ArgoCD by then; RFC #214 §Decision).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COSIGN_DIR="$ROOT_DIR/infra/secrets/cosign"
NS=kyverno
CM_NAME=cosign-public-key

# Optionally target a specific cluster (e.g. KCTX=k3d-k8s-lab-green).
source "$(dirname "${BASH_SOURCE[0]}")/lib/kctx.sh"

mkdir -p "$COSIGN_DIR"

if [ ! -f "$COSIGN_DIR/cosign.key" ] || [ ! -f "$COSIGN_DIR/cosign.pub" ]; then
  echo "[cosign] generating keypair under infra/secrets/cosign/ ..."
  ( cd "$COSIGN_DIR" && COSIGN_PASSWORD="" cosign generate-key-pair )
  echo "[cosign] keypair generated"
else
  echo "[cosign] keypair already exists — skipping generation"
fi

# Seed the public key into the kyverno namespace as a ConfigMap.
# --dry-run=client | kubectl apply makes this idempotent on re-runs
# (same pattern as vault-bootstrap.sh and garage-bootstrap.sh).
echo "[cosign] seeding ConfigMap $CM_NAME in namespace $NS ..."
kubectl create configmap "$CM_NAME" \
  --namespace "$NS" \
  --from-file=cosign.pub="$COSIGN_DIR/cosign.pub" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[cosign] bootstrap complete"
