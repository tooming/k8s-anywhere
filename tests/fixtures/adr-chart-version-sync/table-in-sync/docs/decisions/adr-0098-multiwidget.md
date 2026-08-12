# ADR-0098 — MultiWidget stack (fixture)

## Decision

| Component | Deployment shape | Source | Version pin |
|---|---|---|---|
| **Sprocket** | Helm chart | `gitops/platform/sprocket.yaml`, `targetRevision: 3.4.0` | `3.4.0` |
| **Cog** | Raw manifests | ArgoCD `Application` `cog`, `targetRevision: main` | Image tag tracked via `context.md` |
