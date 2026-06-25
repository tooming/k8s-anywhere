# ADR-0023 — Kargo for GitOps promotion pipelines (multi-stage, Warehouse-gated)

**Status.** Adopted. On-demand component (bring up with `make kargo-up`). Complements
Argo Rollouts (ADR-0020): Rollouts controls *how* a version lands in a stage (canary
steps, SLO gates); Kargo controls *which* version reaches each stage and *when* it is
cleared to move forward.

---

## Context

ADR-0020 added Argo Rollouts for SLO-gated canary delivery inside a single stage.
What it did not add is a multi-stage promotion layer:

- After the canary succeeds in `dev`, should the same image digest automatically flow
  to `prod`?  Who approves it?  Where is the audit trail?
- ArgoCD's auto-sync means every commit to `main` immediately changes every Application.
  There is no *gate* between environments.

The 2026 GitOps best-practice guidance from Akuity (Kargo's creator) identifies
**promotion orchestration** as the missing link between image build and production:
the Warehouse detects new artifact versions, Freight bundles them for promotion,
Stages define gates (automatic or manual), and the promotion pipeline connects them —
with full traceability in the Kargo UI.

---

## Decision

Adopt **Kargo** as the lab's promotion-orchestration layer.

### Chart + version

- **Helm repo:** `https://charts.kargo.io`
- **Chart:** `kargo`
- **Version:** `1.2.0` (pin; update to latest stable before `make kargo-up`)
- **Namespace:** `kargo` (new; PSA `restricted` — Kargo pods run as uid 65532)

### Footprint controls (ON-DEMAND)

```
api:        replicas: 1   memory limit: 256Mi
controller: replicas: 1   memory limit: 128Mi
webhooks:   replicas: 1   memory limit:  64Mi
```

Total: ~250–450 MiB. **ON-DEMAND only** — do not enable auto-sync; incompatible
with always-on budget (ADR-0005).

### Pipeline for the capstone app

```
Warehouse (capstone-pipeline)
  └─ image: artifactory.127.0.0.1.nip.io/docker-local/hello  (digest-tracked)
        │
        ▼ Freight (new digest detected)
   Stage: dev  ──[auto-promote]──► argocd-update capstone Application
        │
        ▼ Freight (promoted through dev)
   Stage: prod ──[manual gate]────► argocd-update capstone Application
```

- **Warehouse** subscription: `artifactory.127.0.0.1.nip.io/docker-local/hello`
  using `Digest` tag-selection strategy — every new image digest (regardless of tag)
  is a new Freight entry.
- **Stage `dev`**: `requestedFreight.sources.direct: true` — auto-promoted as soon
  as Freight exists.  Promotion step: `argocd-update` triggers an ArgoCD hard-refresh
  of the `capstone` Application with the new kustomize image override.
- **Stage `prod`**: `requestedFreight.sources.stages: [dev]` — only Freight that has
  successfully transited `dev` is eligible.  Promotion is **manual** (user clicks
  "Promote" in the Kargo UI or uses `kargo promote`).

### Admin credentials

Kargo's admin account password hash is stored in Vault (`secret/kargo/admin`,
property `password-hash`) and rendered into `kargo-admin-credentials` Secret via
ESO. Seed the Vault path before running `make kargo-up`:

```bash
vault kv put secret/kargo/admin password-hash='<bcrypt-hash>'
```

Generate a bcrypt hash: `htpasswd -bnBC 14 "" <password> | tr -d ':\n'`

### UI access

HTTPRoute: `http://kargo.127.0.0.1.nip.io:8000` → `kargo-api` Service port 80.
TLS terminated at Envoy Gateway (ADR-0008); Kargo API runs plain HTTP inside
the cluster (`api.tls.selfSignedCert.generate: false`).

### Kargo Project namespace

The Kargo `Project` named `capstone-pipeline` creates and manages the
`capstone-pipeline` namespace (separate from the application's `capstone` namespace).
`Warehouse` and `Stage` resources live in `capstone-pipeline`; the `capstone`
application namespace is unchanged.

### NetworkPolicy + PSS

- Default-deny overlay at `gitops/kargo/networkpolicy/` (ADR-0016).
  Allows: ingress TCP 80 from `envoy-gateway-system` (Kargo UI);
  ingress TCP 9443 from kube-apiserver (admission webhooks);
  egress TCP 80 to `argocd` (argocd-update step);
  egress TCP 443 to `capstone` app registry (image digest discovery);
  egress to kube-apiserver via baseline.
- PSA label `restricted` — no carve-out needed (Kargo pods run uid 65532, non-root).

---

## Why Kargo (not Flux / Argo Workflows)

| Concern | Kargo |
|---------|-------|
| Artifact source agnosticism | Warehouse subscribes to images, Helm charts, or git commits — no single-source lock-in |
| ArgoCD-native | Kargo's `argocd-update` step talks to the existing ArgoCD API; no second GitOps engine |
| First-class UI | Kargo UI shows Freight lineage, stage health, and promotion history — the learning artifact |
| CNCF ecosystem fit | Akuity (Kargo's creator) also maintains Argo; ADR-0020's Rollouts + ADR-0023's Kargo cover the full CI→CD→progressive delivery chain |

---

## Scope & exceptions

**In scope** — the Kargo controller + API + webhooks; the `capstone-pipeline` Project
with one Warehouse (image-based) and two Stages (dev auto, prod manual); the Kargo UI
HTTPRoute; admin-credentials ExternalSecret.

**Out of scope (this ADR):**

- Git-commit subscriptions (the lab's capstone CI uses `:latest`; add once tagged
  images are in use).
- Kargo RBAC (`ProjectRole`) — single-user lab; follow-up ADR/PR.
- Kargo notifications (Slack/webhook on promotion failure) — follow-up.
- Promotion steps beyond `argocd-update` (git-clone → kustomize-set-image →
  git-commit → git-push) — deferred until the capstone pipeline uses versioned tags.

---

## Files this work touches

| Path | Role |
|------|------|
| `docs/decisions/adr-0023-kargo-promotion-pipeline.md` | This ADR |
| `gitops/platform/kargo-extras.yaml` | Namespace pre-creation (wave 0, ON-DEMAND) |
| `gitops/platform/kargo.yaml` | Kargo Helm Application (wave 1, ON-DEMAND) |
| `gitops/platform/kargo-networkpolicy.yaml` | NetworkPolicy Application (wave 4, ON-DEMAND) |
| `gitops/platform/kargo-project.yaml` | Kargo Project/Warehouse/Stage Application (wave 6, ON-DEMAND) |
| `gitops/kargo/namespace.yaml` | Namespace + PSA restricted labels |
| `gitops/kargo/route.yaml` | HTTPRoute `kargo.127.0.0.1.nip.io` |
| `gitops/kargo/networkpolicy/` | Default-deny + allow rules |
| `gitops/kargo-project/project.yaml` | Kargo Project, Warehouse, Stage resources |
| `gitops/apps/capstone/kustomization.yaml` | Enables kustomize mode (Kargo image override) |
| `gitops/secrets/kargo-admin-externalsecret.yaml` | ESO ExternalSecret for admin credentials |
| `tests/kargo.bats` | Clusterless structural tests |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Kargo lands as ArgoCD-synced manifests; `argocd-update` step calls back into ArgoCD — no second GitOps engine. |
| [ADR-0003](adr-0003-decoupled-no-spof.md) | Single-replica components per ADR-0005; production runs HA. |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Single-replica per component; ON-DEMAND to stay within budget. |
| [ADR-0008](adr-0008-envoy-gateway-not-traefik.md) | Kargo UI routed via HTTPRoute `kargo.127.0.0.1.nip.io`. |
| [ADR-0016](adr-0016-default-deny-networkpolicy.md) | `kargo` and `capstone-pipeline` namespaces get default-deny during fan-out. |
| [ADR-0017](adr-0017-pod-security-standards-restricted.md) | PSA `restricted`; no carve-out needed. |
| [ADR-0020](adr-0020-argo-rollouts-progressive-delivery.md) | Kargo controls stage promotion; Rollouts controls canary progression inside a stage. They compose: Kargo promotes Freight to dev → Rollouts runs the canary → health check passes → Kargo eligible to promote to prod. |
