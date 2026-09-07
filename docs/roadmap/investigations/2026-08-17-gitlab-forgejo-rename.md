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

## Update 2026-09-06 (live-cluster session) — the credential-wiring half of
finding 3 above is now closed

Independently of this item: a fresh `make up` was reproduced live failing
`root-app`'s very first sync (missing `repo-forgejo-gitops` Secret — the exact
gap this investigation flagged). Fixed with `scripts/forgejo-repo-secret.sh` +
`make forgejo-repo-secret`, wired into `up` right after `forgejo-up` and before
`gitlab-up`/`root-app` — full writeup:
[docs/done/2026-09-06-forgejo-repo-secret-bootstrap-gap.md](../../done/2026-09-06-forgejo-repo-secret-bootstrap-gap.md).

This item stays open: the SSH-based `forgejo-push`/`forgejo-force-push`
replacement, the TLS-layer question, and the actual `gitlab-*.sh` →
`forgejo-*.sh` rename are still undone — GitLab's targets still run in `up`,
and no automated push exists yet for a genuinely empty Forgejo repo.

## Update 2026-09-06 (live-cluster session, issue #633) — "legacy, harmless"
was wrong about the resource cost, even though the correctness call was right

`docker stats` showed the `gitlab` container alone holding ~3.1 GiB (27% of
the 12 GB VM) for the entire rest of a session after a `make up`, because
nothing in the `up` sequence ever brought it back down — `gitlab-configure`
only needs GitLab reachable for its own one-shot Terraform-state import +
initial push, and nothing later in `up` (`root-app` now tracks Forgejo, per
the repoURL flip already mentioned above) depends on it staying up. Added
`$(MAKE) gitlab-down` right after `gitlab-configure` in the `up` target —
GitLab still gets configured every fresh bootstrap, it just doesn't sit there
afterward burning a quarter of the VM. This is a narrow, safe addition, not
the full decommission this item is still tracking.

**Status as of 2026-09-06: still blocked, same reason as the original
finding.** The three live-verification-dependent design decisions in the
Recommendation above (SSH push replacement, TLS-layer question, `make up`
bootstrap-sequence rewrite) remain undone. Both 2026-09-06 updates above
closed adjacent gaps this investigation surfaced (the missing-Secret bug, the
GitLab-left-running resource cost) without touching the rename/decommission
itself — genuine progress, not a resolution of this investigation's own
question.
