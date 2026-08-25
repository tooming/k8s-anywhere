# Investigation: rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh`

Investigated 2026-08-17 (executor STEP 3 pickup, clusterless session) — this is
**NOT** a mechanical rename, and picking it up blind risks a broken `make up`.

Findings, verified directly against the actual repo (ADR-0004):

1. **The auth model changed, not just the hostname.** GitLab's push flow
   (`gitlab-push`/`gitlab-force-push` Makefile targets, `scripts/gitlab-pat.sh`,
   `scripts/gitlab-credential-helper.sh`) is HTTPS + a Terraform-provisioned
   Personal Access Token. `infra/modules/forgejo-config/main.tf`'s own header
   comment states the Forgejo Terraform provider "has no HTTP-token-based deploy
   credential resource" — it uses `forgejo_deploy_key` (SSH) instead, confirmed
   live: PR #1205's cutover pushed via `ssh://git@host.k3d.internal:2223/...`, not
   HTTPS+PAT. A same-named `forgejo-push` target can't be a faithful rename of
   `gitlab-push` — it needs a different auth mechanism, and this clusterless
   session cannot verify a new SSH-based push flow actually authenticates against
   the live Forgejo instance (no live host to test against).
2. **`gitlab-tls-bootstrap` and `scripts/gitlab-bootstrap.rb` likely have no
   Forgejo equivalent to rename to.** `forgejo/docker-compose.yml` runs Forgejo on
   plain HTTP (`GITEA__server__ROOT_URL: http://localhost:3300/`, no TLS/nginx
   sidecar anywhere in that file) — unlike GitLab, which needed `gitlab-tls`'s
   mkcert+nginx proxy specifically because its own web UI required HTTPS for git
   operations over HTTP Basic auth. Forgejo's git operations go over SSH (which
   doesn't need this lab's mkcert layer), so there may be nothing to rename here,
   only to retire. Similarly `gitlab-bootstrap.rb` (a Rails-runner script for
   GitLab's own root-password bootstrap) has no analog need — Forgejo's admin
   bootstrap is already a *different*, existing script
   (`scripts/forgejo-admin-ensure.sh`), not a gap this item fills.
3. **`make up`'s full-lifecycle bootstrap sequence (line ~275) still calls
   `gitlab-up`/`gitlab-configure`/`gitlab-tls-bootstrap`, not any Forgejo
   equivalent** — meaning a fresh `make up` today would still try to bring up and
   configure GitLab as the git source, even though the *live* cluster (per PR
   #1205) already has GitLab stopped and every `repoURL` pointed at Forgejo.
   That's a real, already-existing inconsistency between `make up`'s scripted
   bootstrap path and the cluster's actual live state — bigger in scope and risk
   than a same-shaped rename, and squarely the kind of "rebuild the whole lab
   from scratch" critical path (CHARTER Core Value "Recreate-from-code") that
   needs live verification (a real `make up` run) before trusting a rewritten
   version, not something to guess at from a clusterless session.

**Recommendation:** this item needs a live-cluster or otherwise better-verified
session to (a) design the SSH-based `forgejo-push`/`forgejo-force-push` replacement
against the actual live deploy-key/known_hosts setup, (b) confirm whether a
Forgejo TLS layer is wanted at all before inventing one, and (c) update `make up`'s
bootstrap sequence and verify a real end-to-end rebuild still works — each a
materially different, live-verification-dependent design decision, not a
find-and-replace. Left unchecked and un-picked-up this cycle rather than shipping
a same-shaped-but-wrong rename (ADR-0004 — don't assert a working replacement
this session can't verify).
