#!/usr/bin/env bash
# Idempotently ensure ArgoCD can actually pull the gitops repo from Forgejo over SSH
# (ADR-0035): the lab/k8s-lab org+repo exist on Forgejo, an SSH deploy key is
# registered against that repo, and the matching private key is loaded into the
# argocd namespace as the `repo-forgejo-gitops` Secret that `root-app.yaml` (and every
# other Application) resolves its `repoURL` credential from.
#
# Gap this closes: a fresh k3d cluster (`make down && make up`, or a new machine) gets
# a brand-new argocd namespace with no such Secret, but Forgejo itself runs in a
# separate, longer-lived docker-compose stack (`restart: unless-stopped`, persists
# across `colima stop`/`start`) that already has org/repo/deploy-key state from a
# prior run. Without this step `root-app`'s very first sync fails outright:
# `ComparisonError: failed to list refs: error creating SSH agent: "SSH agent
# requested but SSH_AUTH_SOCK not-specified"` — ArgoCD has no repo credential at all
# for this repoURL, so it falls back to (and fails to find) a host SSH agent.
# Confirmed live 2026-09-06.
#
# Re-run-safe by design: if the Secret already exists AND its embedded private key
# still corresponds to a live, non-revoked deploy key on the repo, this is a no-op —
# it only (re)generates a keypair + registers a new deploy key when that isn't true,
# i.e. exactly the fresh-cluster case above, not on every `make up` against the same
# cluster. Superseding the still-open ROADMAP item that would replace this with a
# Terraform-managed equivalent (`infra/modules/forgejo-config`'s own
# `kubernetes_secret.argocd_repo`) is deliberately NOT this script's job — that
# module's remote-state backend has its own outstanding credential issue (see the
# dated investigation doc under docs/roadmap/investigations/ about the still-open
# legacy-git-host script rename), so this script gives `make up` a working,
# dependency-light path in the meantime.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
source "$HERE/lib/kctx.sh"

FORGEJO_URL="${FORGEJO_URL:-http://localhost:3300}"
ORG="lab"
REPO_NAME="k8s-lab"
NS=argocd
SECRET_NAME=repo-forgejo-gitops
REPO_URL_IN_CLUSTER="ssh://git@host.k3d.internal:2223/${ORG}/${REPO_NAME}.git"
# Forgejo enforces unique deploy-key titles per repo, so a fresh run can't register
# its replacement key under the exact same title as the one it's about to retire
# (see step 3's register-before-delete ordering) — every run gets a distinct title
# carrying this fixed, greppable prefix; cleanup matches on the prefix, not equality.
KEY_TITLE_PREFIX="argocd-read (forgejo-repo-secret.sh)"
KEY_TITLE="$KEY_TITLE_PREFIX $(date -u +%Y%m%dT%H%M%SZ)-$$"

ENV_FILE="$ROOT/forgejo/.env"
PW="$(grep -E '^FORGEJO_ADMIN_PASSWORD=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-)"
if [ -z "$PW" ]; then
  echo "forgejo-repo-secret: FORGEJO_ADMIN_PASSWORD missing from forgejo/.env — run 'make forgejo-up' first" >&2
  exit 1
fi

api() { curl -fsS -u "lab-admin:$PW" "$@"; }

# --- 1. org + repo exist (idempotent: only create when actually missing) ----
if ! api "$FORGEJO_URL/api/v1/orgs/$ORG" >/dev/null 2>&1; then
  echo "[forgejo-repo-secret] creating org '$ORG'..."
  api -X POST -H 'Content-Type: application/json' \
    -d "$(jq -n --arg u "$ORG" '{username:$u, visibility:"private"}')" \
    "$FORGEJO_URL/api/v1/orgs" >/dev/null
fi

if ! api "$FORGEJO_URL/api/v1/repos/$ORG/$REPO_NAME" >/dev/null 2>&1; then
  echo "[forgejo-repo-secret] creating repo '$ORG/$REPO_NAME'..."
  api -X POST -H 'Content-Type: application/json' \
    -d "$(jq -n --arg n "$REPO_NAME" '{name:$n, private:true, auto_init:false}')" \
    "$FORGEJO_URL/api/v1/orgs/$ORG/repos" >/dev/null
  echo "[forgejo-repo-secret] NOTE: repo created empty — it has no gitops content yet." \
    "Push the local main branch to it (ssh://git@localhost:2223/$ORG/$REPO_NAME.git)" \
    "before ArgoCD has anything to sync; no automated push step exists yet" \
    "(see the legacy-git-host rename investigation doc under" \
    "docs/roadmap/investigations/)." >&2
fi

# --- 2. is the existing Secret's key still a live, registered deploy key? ---
still_valid=""
if kubectl -n "$NS" get secret "$SECRET_NAME" >/dev/null 2>&1; then
  existing_priv="$(kubectl -n "$NS" get secret "$SECRET_NAME" -o jsonpath='{.data.sshPrivateKey}' 2>/dev/null | base64 -d || true)"
  if [ -n "$existing_priv" ]; then
    keydir="$(mktemp -d)"
    trap 'rm -rf "$keydir"' EXIT
    printf '%s\n' "$existing_priv" >"$keydir/priv"
    chmod 600 "$keydir/priv"
    if pub="$(ssh-keygen -y -f "$keydir/priv" 2>/dev/null)"; then
      pub_material="$(awk '{print $1, $2}' <<<"$pub")"
      # Compare only the algo+base64 fields on both sides — Forgejo's deploy-key
      # listing echoes back whatever comment (3rd field) was submitted at
      # registration time, which varies between keys registered by this script,
      # by Terraform, or by hand, and isn't meaningful for identity.
      if api "$FORGEJO_URL/api/v1/repos/$ORG/$REPO_NAME/keys" \
          | jq -e --arg k "$pub_material" 'any(.[]; (.key | split(" ")[0:2] | join(" ")) == $k)' >/dev/null; then
        still_valid=1
      fi
    fi
    rm -rf "$keydir"
    trap - EXIT
  fi
fi

if [ -n "$still_valid" ]; then
  echo "[forgejo-repo-secret] $SECRET_NAME already carries a live, registered deploy key — nothing to do"
  exit 0
fi

# --- 3. fresh cluster (or drift): generate a new keypair, register, upsert ---
# Register the new key and land the Secret BEFORE touching any previous
# script-managed key — if the kubectl apply below fails partway (e.g. a busy
# apiserver mid-bootstrap), we must not have already deleted the one deploy key
# that still matches what's (still) in the cluster.
echo "[forgejo-repo-secret] generating a new deploy keypair..."
keydir="$(mktemp -d)"
trap 'rm -rf "$keydir"' EXIT
# Note: -C intentionally omitted — the public key registered with Forgejo carries
# no comment, matching the format the idempotency check above compares against.
ssh-keygen -t ed25519 -N '' -f "$keydir/id_ed25519" >/dev/null

echo "[forgejo-repo-secret] registering new deploy key '$KEY_TITLE'..."
new_key_id="$(api -X POST -H 'Content-Type: application/json' \
  -d "$(jq -n --arg t "$KEY_TITLE" --arg k "$(cat "$keydir/id_ed25519.pub")" '{title:$t, key:$k, read_only:true}')" \
  "$FORGEJO_URL/api/v1/repos/$ORG/$REPO_NAME/keys" | jq -r '.id')"

echo "[forgejo-repo-secret] upserting Secret $SECRET_NAME in namespace $NS..."
secret_manifest="$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NS
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: $REPO_URL_IN_CLUSTER
  insecure: "true"
  sshPrivateKey: |
$(sed 's/^/    /' "$keydir/id_ed25519")
EOF
)"
# A busy apiserver (e.g. mid-bootstrap, many Applications syncing at once) can time
# out the client-side openapi schema fetch `kubectl apply` does before it ever
# touches this Secret — retry a few times rather than failing the whole `make up`
# on what's usually a transient blip, not a real problem with the manifest.
ok=""
for _ in 1 2 3 4 5; do
  if printf '%s\n' "$secret_manifest" | kubectl apply -f -; then
    ok=1
    break
  fi
  echo "[forgejo-repo-secret] kubectl apply failed, retrying in 5s..." >&2
  sleep 5
done
[ -n "$ok" ] || { echo "[forgejo-repo-secret] giving up applying $SECRET_NAME after 5 attempts" >&2; exit 1; }

# Only now drop earlier keys this script registered (a different id than the one
# just created), so re-runs don't pile up dead keys on the repo — the original
# Terraform-managed key, a different title, is left alone.
old_ids="$(api "$FORGEJO_URL/api/v1/repos/$ORG/$REPO_NAME/keys" \
  | jq -r --arg p "$KEY_TITLE_PREFIX" --arg new "$new_key_id" \
    '.[] | select((.title | startswith($p)) and (.id|tostring)!=$new) | .id')"
for old_id in $old_ids; do
  echo "[forgejo-repo-secret] removing superseded '$KEY_TITLE' deploy key (id=$old_id)..."
  api -X DELETE "$FORGEJO_URL/api/v1/repos/$ORG/$REPO_NAME/keys/$old_id" >/dev/null || true
done

echo "[forgejo-repo-secret] done"
