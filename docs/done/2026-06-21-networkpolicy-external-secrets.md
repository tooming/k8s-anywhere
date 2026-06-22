# 2026-06-21 — NetworkPolicy fan-out — `external-secrets` namespace

**Branch:** `auto/networkpolicy-external-secrets`
**ROADMAP item:** 🟢 NetworkPolicy fan-out — `external-secrets` namespace (CHARTER Objective O2, due 2026-09-30; ADR-0016 §4 fan-out completion)

## What was delivered

Closes the last always-on namespace without an ADR-0016 default-deny NetworkPolicy floor.

**`gitops/external-secrets/networkpolicy/kustomization.yaml`** — Kustomize overlay entrypoint pulling the two shared baseline templates (default-deny + allow-dns-and-apiserver) plus the two ESO-specific allow files.

**`gitops/external-secrets/networkpolicy/allow-eso-metrics-ingress.yaml`** — allows Alloy (in the `observability` namespace) to scrape ESO controller-runtime metrics on TCP 8080. Scoped to `app.kubernetes.io/name: external-secrets` pods.

**`gitops/external-secrets/networkpolicy/allow-eso-vault-egress.yaml`** — allows ESO controller to reach Vault on TCP 8200 for ClusterSecretStore token review calls (Vault k8s auth method). Scoped to `app.kubernetes.io/name: external-secrets` pods.

**`gitops/platform/networkpolicy-appset.yaml`** — `external-secrets-networkpolicy` entry added to the list generator (`gitPath: gitops/external-secrets/networkpolicy`, `destNamespace: external-secrets`). Auto-sync + prune + selfHeal via the appset template (same as all other appset entries).

**`gitops/observability/networkpolicy/allow-alloy-egress-external.yaml`** — added egress rule allowing Alloy to reach `external-secrets` namespace on TCP 8080. Required companion to the ingress rule: without this, the default-deny floor on observability blocks Alloy from scraping ESO even though ESO's ingress permits it.

**`tests/networkpolicy.bats`** — 16 new assertions covering the external-secrets overlay:
- kustomization.yaml exists; namespace set; both baseline refs present
- `allow-eso-metrics-ingress.yaml`: exists; port 8080; from observability; ESO pod label
- `allow-eso-vault-egress.yaml`: exists; port 8200; to vault namespace; Egress policyType
- appset has external-secrets-networkpolicy entry and correct gitPath
- observability egress to external-secrets on port 8080 present

**`docs/dependency-tree.md`** — wave-4 table updated: `external-secrets-networkpolicy` added to the generated AppSet list; note added that this closes the ADR-0016 §4 always-on fan-out gap.

## Why

CHARTER Objective O2 (due 2026-09-30) requires a default-deny NetworkPolicy floor on every always-on namespace (ADR-0016 §4). The `external-secrets` namespace received PSA `restricted` labels in `auto/pss-external-secrets` but had no NetworkPolicy overlay. This PR closes that gap and completes the always-on ADR-0016 fan-out.

The observability egress update was included because the external-secrets dashboard PR (`auto/external-secrets-dashboard`) added the Alloy scrape job but did not update the observability NetworkPolicy — adding the default-deny floor to external-secrets without the corresponding observability egress would have silently broken ESO metrics scraping.
