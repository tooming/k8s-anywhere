# ROADMAP.md completed-item trim, batch 4

JANITOR fallback role (`executor.prompt.md` STEP 6b, this run's fifteenth cycle: the
"Now / next" lane remained fully gated on unconfirmed maintainer-confirmation issues
#631/#633/#1229/#1345, and the PLANNER/ARCHITECT/UPGRADE-DRAFTER fallback roles had
already produced 14 real cycles' worth of dependency-currency and architect-digest work
this run — see `docs/industry/2026-W36-digest.md` and this run's PRs #1360-#1373).
ROADMAP.md was 6,625 lines / ~482 KB with 186 checked `[x]` items, most carrying a full
inline writeup that is already permanently mirrored in `docs/done/`. Continuing the
established cleanup started in batch 1 (`docs/done/2026-08-19-roadmap-completed-item-
trim.md`) and extended in batches 2-3 (`docs/done/2026-08-22-roadmap-completed-item-
trim-batch-2.md`, `docs/done/2026-08-25-roadmap-completed-item-trim-batch-3.md`).

## Method (unchanged from batches 1-3)

For each candidate item: confirmed a matching `docs/done/*.md` file exists with a real,
non-placeholder PR link; read the file and confirmed it covers the same substance as
the ROADMAP.md item; only then replaced the item body with a title + link + PR number.

Items with no `docs/done/*.md` mirror are left untouched — trimming those would lose
information ROADMAP.md is the only remaining record of. This batch specifically found
and skipped one such item: "Flip `Application` `repoURL`s (including `root-app.yaml`)
to the Forgejo remote, verify a real sync" (part of the same GitLab→Forgejo migration
numbered list as three of this batch's trimmed items) — it cites `(PR #1205)` inline
but has no matching file under `docs/done/`, so it was left as-is.

## This batch

Picked up exactly where batch 3 left off, within the "GitLab → Forgejo migration
(ADR-0035, superseding ADR-0033) — seven items" numbered list, plus two further
standalone items found later in the file:

- **`infra/modules/forgejo-config` Terraform module** →
  [docs/done/2026-08-11-forgejo-config-terraform-module.md](2026-08-11-forgejo-config-terraform-module.md)
  (PR #1107)
- **Port `.gitlab-ci.yml` → `.forgejo/workflows/build-sign-push.yml`** →
  [docs/done/2026-08-11-forgejo-ci-workflow.md](2026-08-11-forgejo-ci-workflow.md)
  (PR #1108)
- **Wire ArgoCD's repo-credential Secret for the Forgejo remote (prep slice)** →
  [docs/done/2026-08-11-forgejo-argocd-repo-secret.md](2026-08-11-forgejo-argocd-repo-secret.md)
  (PR #1110)
- **Simulate Garage unavailability — third DR fault-injection drill
  (`make dr-garage-failure`)** →
  [docs/done/2026-08-18-dr-garage-failure-drill.md](2026-08-18-dr-garage-failure-drill.md)
  (PR #1240)
- **Dependency exit runbooks for the lab's top concentration risks — closes DORA audit
  Q17's named gap** →
  [docs/done/2026-08-18-dependency-exit-runbooks.md](2026-08-18-dependency-exit-runbooks.md)
  (PR #1242)

Before: 6,625 lines / ~482 KB. After: 6,567 lines / ~471 KB (58 lines / ~11 KB removed).

`make ci` passes (all drift checks green, including `docs-done-pr-link-check` and
`roadmap-check`).

## ADR-0004 caveat

No new technical claims are made in this PR — only already-shipped, already-verified
ROADMAP items are re-pointed at their existing `docs/done/` records. Nothing in this
change affects live-cluster state.

## PR

[#1374](https://github.com/tooming/k8s-anywhere/pull/1374)
