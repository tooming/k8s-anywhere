# Disaster Recovery / from-scratch bootstrap

This lab is **recreate-from-code**, not backup/restore. Everything lives in this
repo (manifests, Terraform, scripts); secrets are *generated* during bootstrap.
To rebuild the whole thing on a clean machine: `make up`.

```sh
make preflight   # check tools (brew install: colima k3d helm terragrunt kustomize argocd yq mkcert)
make up          # bootstrap everything, in order
make status      # VM RAM + per-namespace usage + unhealthy pods
```

## The order (what `make up` does, and why)

The only **imperative** steps are the day-0 seam (you can't GitOps the GitOps
engine or its git source into existence). Everything after the root app-of-apps
is reconciled by ArgoCD from GitLab.

| # | Step | `make` target | Imperative? | Why this order |
|---|------|---------------|-------------|----------------|
| 1 | Colima VM | `colima-up` | yes | container runtime |
| 2 | k3d cluster | `cluster-up` | yes (Terraform) | the substrate |
| 3 | ArgoCD | `argocd` | yes (Terraform/Helm) | the GitOps engine — must exist before GitOps |
| 4 | GitLab omnibus | `gitlab-up` | yes (docker) | the git **source** — can't be created by ArgoCD (chicken-and-egg, ADR-0001) |
| 5 | GitLab project + repo secret + push | `gitlab-configure` | yes (Terraform + git) | mints root token (`scripts/gitlab-pat.sh`), creates the project + ArgoCD repo deploy-token, pushes the repo |
| 6 | App-of-apps | `root-app` | yes (`kubectl apply`) | the single seed; ArgoCD now syncs **everything else** |
| 7 | Vault bootstrap | `vault-bootstrap` | yes (`scripts/vault-bootstrap.sh`) | init/unseal, store keys in `vault-keys`, enable KV, **generate+write secrets**, enable k8s auth + `eso` role |
| 8 | Garage bootstrap | `garage-bootstrap` | yes (`scripts/garage-bootstrap.sh`) | assign layout, create S3 key + buckets, push the S3 key to Vault |

Once 7–8 are done, **External Secrets** syncs Vault → k8s Secrets, and the
workloads (Garage, Mimir, Grafana, Alloy, Envoy, moto, …) come up on their own.

### Secret dependency chain (subtle bit)
- Vault must hold `secret/garage/server` **before** Garage starts (ESO → `garage-secrets` → Garage). `vault-bootstrap` generates it.
- Garage's S3 access key is created **after** Garage is up, then pushed to Vault (`secret/garage/s3`) → ESO → `garage-s3` → Mimir. `garage-bootstrap` does this.

## Golden rules (keep it acyclic — ADR-0001)
- **Never** source ArgoCD's git credentials or Vault's unseal key *from Vault*
  (that creates an ArgoCD↔Vault cycle). The repo secret is Terraform-made; the
  unseal key lives in the `vault-keys` k8s Secret.
- ESO/Vault being down does **not** kill running workloads — their k8s Secrets
  persist; only refresh/new-secret creation pauses.

## What is NOT preserved on a rebuild
Recreate model → fresh everything: new Vault root/unseal keys, new Garage S3 key,
empty metrics history. That's expected for a throwaway lab. If you ever want true
data survival across a *cluster* rebuild, that's a separate exercise (external
backups; not in scope).

## Recovery cookbook (single-component)
- **Vault sealed** (after a pod restart): the in-cluster `vault-unsealer` re-unseals
  automatically within ~10s. Manual: `make vault-unseal`.
- **GitLab down / freeing RAM:** `make gitlab-down` (keeps volumes), `make gitlab-up` to bring back.
- **ArgoCD out of sync after a git push:** `kubectl -n argocd annotate applications.argoproj.io/root argocd.argoproj.io/refresh=hard --overwrite`.
- **Re-run a bootstrap safely:** `vault-bootstrap` and `garage-bootstrap` are idempotent.

See [decisions/](decisions/) for the rationale behind these choices.
