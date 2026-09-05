#!/usr/bin/env bash
# Keep Forgejo's build-sign-push.yml CI secrets (HARBOR_USER/HARBOR_PASSWORD) in sync
# with Harbor's *actual* live admin credential (the harbor-admin-creds Secret, ESO/Vault
# backed — see gitops/platform/harbor.yaml).
#
# Why this exists (recurrence of a documented bug — docs/incident-log.md 2026-08-04,
# issue #631): Harbor's admin password is whatever was baked in when its database was
# first initialized. Vault's copy of that password (and therefore Forgejo's copy, set
# by hand or by an earlier run of this script) can drift from it — a fresh Harbor
# install picks a new random password, a Vault re-init regenerates one, or someone
# rotates it directly — and nothing keeps the three copies (Harbor's DB, Vault,
# Forgejo's CI secret) in sync. When they drift, `build-sign-push.yml`'s `docker login`
# fails with a fast "Invalid credentials" that looks like a CI/networking problem, not
# a credential-drift problem, and burns real debugging time (confirmed live again
# 2026-09-06 while working issue #633 — the exact same failure mode as #631, a month
# later, because the first fix was applied live with no mechanical guard against
# recurrence).
#
# The fix here treats Harbor's live harbor-admin-creds Secret as the one source of
# truth and pushes it into Forgejo on every `make harbor-up` (see the Makefile target)
# — so the CI secret can never go stale for longer than one bring-up cycle. This does
# not fix Vault's own copy (out of scope: ADR-0001 keeps Terraform/Vault bootstrap
# imperative-once, not continuously reconciled) — only Forgejo's, since that's the copy
# that actually gates CI.
#
# Best-effort: prints a warning and exits 0 rather than failing `make harbor-up` if
# Forgejo isn't running, the credential secret isn't ready yet, or the API call fails
# — the same posture as vault-bootstrap.sh's ESO "kick" (a missing CI secret sync
# should never block getting Harbor itself up).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ENV_FILE="$ROOT/forgejo/.env"
FORGEJO_URL="http://localhost:3300"
REPO="lab/k8s-lab"

warn() { echo "  warn  forgejo-harbor-secret-sync: $1" >&2; }

fp="$(grep -E '^FORGEJO_ADMIN_PASSWORD=' "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-)"
if [ -z "$fp" ]; then
  warn "no FORGEJO_ADMIN_PASSWORD in $ENV_FILE — skipping (Forgejo not bootstrapped yet?)"
  exit 0
fi

if ! curl -sf -m 5 -o /dev/null "$FORGEJO_URL/api/v1/version"; then
  warn "Forgejo unreachable at $FORGEJO_URL — skipping (bring up Forgejo first, or re-run this script later)"
  exit 0
fi

# harbor-admin-creds is ESO-synced from Vault and only appears once the ClusterSecretStore
# has resolved after Harbor's Application syncs — poll rather than assume it's there the
# instant `make harbor-up` triggers the (async) ArgoCD sync.
admin_user="" admin_pw=""
for _ in $(seq 1 30); do
  admin_user="$(kubectl get secret -n harbor harbor-admin-creds -o jsonpath='{.data.HARBOR_ADMIN_USER}' 2>/dev/null | base64 -d 2>/dev/null)"
  admin_pw="$(kubectl get secret -n harbor harbor-admin-creds -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null)"
  [ -n "$admin_user" ] && [ -n "$admin_pw" ] && break
  sleep 10
done

if [ -z "$admin_user" ] || [ -z "$admin_pw" ]; then
  warn "harbor-admin-creds Secret (namespace harbor) never appeared — skipping. Re-run" \
       "'make forgejo-harbor-secret-sync' once Harbor is up."
  exit 0
fi

set_secret() {
  local name="$1" value="$2" code
  code="$(curl -s -o /dev/null -w '%{http_code}' -u "lab-admin:$fp" \
    -X PUT "$FORGEJO_URL/api/v1/repos/$REPO/actions/secrets/$name" \
    -H 'Content-Type: application/json' \
    -d "{\"data\":\"$value\"}")"
  if [ "$code" = "201" ] || [ "$code" = "204" ]; then
    echo "  ok  synced Forgejo CI secret $name from harbor-admin-creds"
  else
    warn "PUT $name returned HTTP $code (expected 201/204) — secret may not have been updated"
  fi
}

set_secret HARBOR_USER "$admin_user"
set_secret HARBOR_PASSWORD "$admin_pw"
