# Close the fresh-cluster `root-app` sync gap: `forgejo-repo-secret` (idempotent SSH deploy-key + Secret bootstrap)

A fresh `make up` (e.g. `make down && make up`, or a new machine) failed at the ArgoCD
`root` Application's very first sync:

```
ComparisonError: failed to list refs: error creating SSH agent: "SSH agent requested
but SSH_AUTH_SOCK not-specified"
```

Root cause: `gitops/bootstrap/root-app.yaml` (and every other `Application`, ADR-0035)
points `repoURL` at `ssh://git@host.k3d.internal:2223/lab/k8s-lab.git`, which needs a
`repo-forgejo-gitops` Secret (SSH deploy key) in the `argocd` namespace. Nothing in
`make up`'s bootstrap chain created that Secret: `gitlab-configure` only wires the
legacy, now-unused `repo-gitlab-gitops` HTTP credential, and the Terraform-based
equivalent (`infra/modules/forgejo-config`'s `kubernetes_secret.argocd_repo`) has an
outstanding remote-state backend credential issue that's kept it from ever actually
being applied (see the 2026-08-17 GitLab→Forgejo rename investigation doc under
`docs/roadmap/investigations/`, and `docs/dependency-tree.md`'s former "Known gap, not
yet reconciled" callout — both flagged this exact drift between what `make up`
literally does and what the live cluster's ArgoCD has pointed at since PR #1205).

Forgejo itself is not the missing piece: it runs in a separate, longer-lived
docker-compose stack (`restart: unless-stopped`, survives `colima stop`/`start`) that
already had the `lab/k8s-lab` org/repo and a registered deploy key from prior runs. The
gap was purely that a **freshly recreated k3d cluster** gets a brand-new `argocd`
namespace with no matching Secret, and nothing in `make up` put one there. Confirmed
live 2026-09-06 — reproduced against this lab's actual running Forgejo + a genuinely
fresh cluster, not just read from the investigation doc.

## What changed

- **`scripts/forgejo-repo-secret.sh`** (new): idempotently ensures the `lab/k8s-lab`
  org+repo exist on Forgejo, and that the `repo-forgejo-gitops` Secret in the `argocd`
  namespace carries a private key matching a live, registered deploy key on that repo.
  - Re-run-safe by construction: it first derives the public key from whatever private
    key is already in the Secret (if any) and checks whether Forgejo still has a
    matching deploy key registered. Only when that check fails (exactly the
    fresh-cluster case, or the key was revoked) does it generate a new ed25519
    keypair, register it, and upsert the Secret.
  - Registers the new key and applies the Secret *before* deleting any previous
    script-managed key, so a failure partway through (e.g. a busy apiserver mid-
    bootstrap) can't leave the cluster with neither a matching Secret nor a valid
    registered key.
  - Retries the `kubectl apply` a few times against a transient apiserver timeout
    (observed live against this same cluster while ~113 Applications were mid-sync)
    rather than failing the whole `make up` on what's usually a passing blip.
  - Deploy-key titles carry a timestamp suffix (Forgejo enforces unique titles per
    repo, so a replacement key can't reuse its predecessor's exact title while both
    briefly coexist under the register-before-delete ordering above) under a fixed,
    greppable prefix that cleanup matches on.
- **`Makefile`**: new `forgejo-repo-secret` target; `up` now calls `forgejo-up` +
  `forgejo-repo-secret` right after `argocd` and before `gitlab-up`/`root-app` — the
  Secret has to exist before `root-app`'s first sync, not after. Refreshed the
  `forgejo-up` target's comment (it said "NOT yet the live git source", stale since PR
  #1205).
- **`tests/forgejo-repo-secret.bats`** (new): clusterless structural coverage — script
  exists/executable/shellcheck-clean, targets the right repo/namespace/Secret, the
  idempotency check and safe (register-then-delete) ordering are present, the
  `kubectl apply` retry exists, and `make up` calls the targets in the right order.
- **`docs/DR.md`**: the "make up order" table still described GitLab as *the* git
  source and didn't mention Forgejo at all, despite the live cutover being seven weeks
  old. Added rows for `forgejo-up`/`forgejo-repo-secret`, renumbered, and flagged the
  remaining GitLab rows as legacy-only (kept for the still-open decommission ROADMAP
  item, not because anything reads from them).
- **`docs/dependency-tree.md`**: updated the day-0 bootstrap diagram and replaced its
  "Known gap, not yet reconciled" callout (which predicted exactly this failure mode)
  with a "Gap closed 2026-09-06" note, including the one piece still genuinely open
  below.

## Deliberately NOT done here

- **No automated `forgejo-push`.** This script does not push repo content into a
  genuinely empty Forgejo — if the org/repo don't exist yet, it creates them empty and
  prints a warning. Harmless on this lab today because Forgejo's docker volume
  persists across `make down`/`make up` cycles on the same machine (only the k3d
  cluster is actually recreated), but a true first-time bootstrap on a brand new
  machine would still need someone to `git push` once by hand. Building the SSH-based
  push flow (auth model differs entirely from GitLab's HTTPS+PAT) is the still-open
  "rename `scripts/gitlab-*.sh`" ROADMAP item under the GitLab→Forgejo migration list —
  not duplicated here.
- **No change to the Terraform-based `infra/modules/forgejo-config` path.** That
  module's `kubernetes_secret.argocd_repo` resource is the "proper" long-term owner of
  this Secret, but its remote-state backend credential issue is unresolved and out of
  this fix's scope (a script this lab has to run against `local-exec`-style
  imperative bootstrap anyway, same tier as `gitlab-pat.sh`/`vault-bootstrap.sh`, is
  a reasonable interim owner regardless of that module's state).
- **GitLab decommission** — still a separate, deliberately-deferred ROADMAP item.
