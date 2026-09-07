# Fix stale GitLab/Forgejo references left after their removal

## PR

(backfilled after PR creation)

## What

GitLab (ADR-0033) and its Forgejo successor (ADR-0035) were both removed
entirely 2026-09-07, no replacement — ArgoCD now syncs directly from this
repo's public GitHub remote. This is a JANITOR-fallback cleanup (ROADMAP
rule #9's coverage/hardening sweep, "Now / next" genuinely empty) finding
several places that removal missed.

## Bug found: fabricated live state (ADR-0004)

`gitops/apps/demo/configmap.yaml` — deployed live as part of `lab-demo`, one
of the always-on 6-component core — still said `"Hello from GitOps — this
was synced by ArgoCD, from GitLab, into the cluster."` and
`source: "gitlab:lab/k8s-lab @ gitops/apps/demo"`. `gitops/platform/demo.yaml`'s
own Application has pointed `repoURL` at `https://github.com/tooming/k8s-anywhere.git`
this whole time — this ConfigMap has been asserting the wrong git source
live in the cluster, with zero test coverage protecting against the drift.
Fixed to name GitHub, and added `tests/lab-demo-configmap.bats` as the
mechanical recurrence guard: one test cross-checks the ConfigMap's strings
against the Application's real `repoURL` host, the other hard-fails if
`gitlab`/`forgejo` ever reappears in it.

## Also fixed: dead dropdown option + stale comments

- `.github/workflows/oracle-cluster-apply.yml`'s `unit` workflow_dispatch
  choice still offered `gitlab` after `infra/live/oracle/gitlab/` was
  deleted along with the ADR-0035 removal — selecting it would fail with no
  such Terragrunt unit on disk. Removed the option, and added
  `tests/oracle-cluster.bats` coverage asserting every dropdown option is a
  real `infra/live/oracle/` subdirectory (mechanical recurrence guard).
- `.github/workflows/oracle-cluster-apply-retry.yml`'s comment listing
  excluded actions ("no argocd/gitlab") updated to drop the removed unit.
- `infra/modules/oracle-k3s-cluster/main.tf`'s comment describing
  `infra/live/local/{argocd,gitlab}` updated — only `argocd/` remains.
- `infra/live/README.md` — the backend contract table and every "3
  Terragrunt units" description still documented a `gitlab/` unit
  (`infra/modules/gitlab-config`) that hasn't existed since 2026-09-07,
  including step-by-step new-backend instructions referencing a
  `{cluster,argocd,gitlab}` triple. Rewritten to describe the real 2-unit
  contract (`cluster/`, `argocd/`), with a note on why the third unit was
  dropped.

## Not a new finding

Checked `infra/live/oracle/root.hcl`, `infra/live/local/root.hcl`, and
`tests/oracle-cluster.bats`'s own pre-existing comments — all already
correctly describe the GitLab/Forgejo removal in past tense; no fix needed
there. `scripts/vault-bootstrap.sh`'s comment listing removed KV-seed
consumers (including `secret/gitlab/bootstrap`) is likewise already
accurate historical explanation, not a live-state claim.

The `scripts/gitlab-bootstrap.rb` orphan flagged by
`docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md` turned out
to already be resolved: `ROADMAP.md`'s corresponding item was closed as
moot 2026-09-07 (checked `[x]`) once both GitLab and Forgejo were removed
entirely — no `scripts/gitlab-*.sh`/`forgejo-*.sh` script or Makefile target
remains to rename or retire.

## Verification

- `make ci`: fully green, zero `not ok` lines (including the two new guard
  tests, confirmed to fail against the pre-fix state before the fix landed).
- `grep -rn "gitlab\|forgejo" infra/ .github/workflows/ gitops/` reviewed by
  hand; every remaining hit is either historical-removal prose (already
  correct) or a still-relevant `.forgejo/workflows/` path check that safely
  no-ops when the directory doesn't exist.

## ADR compliance

No ADR contradicted — this only finishes ADR-0033/ADR-0035's own "Removed
2026-09-07" removals, which left stale references behind.

## Behavior preserved

The `oracle-cluster-apply.yml` dropdown change only removes an
already-broken option (selecting it would already fail — the directory it
pointed at doesn't exist); every other change is a comment/doc/ConfigMap
text fix with no functional effect on `make ci` or any live Application
other than correcting the ConfigMap's own displayed content.
