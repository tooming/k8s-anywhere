# [Action needed] Now/next still gated on #631/#633; full fallback-chain sweep clean after the Artifactory decommission

## What's blocked

ROADMAP.md's *Now / next* lane holds the same 3 unchecked `[ ]` items, all
gated on standing maintainer-confirmation issues:

- [#631](https://github.com/tooming/k8s-anywhere/issues/631) — a real GitLab
  CI run must sign and push an image (blocks `auto/cosign-enforce-flip` and
  its dependent `auto/o4-ci-rejection-gate`). Re-checked this cycle: still
  open, last comment 2026-07-29T16:30 says the root cluster blocker was
  fixed but the actual CI-run confirmation was never completed.
- [#633](https://github.com/tooming/k8s-anywhere/issues/633) — an Argo
  Rollouts canary + Kargo promotion must be observed end-to-end (blocks
  `auto/capstone-deployment-removal`). Re-checked: still open, last comment
  confirms no Freight has ever been produced.

## What this run already did

Three real PRs merged earlier this run, closing out the entire Harbor
migration:
- #886 — `chore:` de-duplicated the four frozen-monolith test-check/sync-hook
  script pairs (janitor fallback).
- #887 — `fix:` decommissioned the Artifactory manifests entirely (RFC #297 /
  ADR-0024), closing issue #297 and fixing several stale references PR #885
  missed (dashboard prose, `lab-health-check.sh`'s namespace list, a
  `readme-check.sh` gap for superseded-ADR historical text).
- #888 — `docs:` corrected the cosign-enforce-flip item's now-stale
  Artifactory verification command to point at Harbor instead.

Also closed [#632](https://github.com/tooming/k8s-anywhere/issues/632) (the
Harbor footprint gate) directly — both PRs that satisfied it (#885, #887)
had already merged without a `Closes #632` line, leaving it stranded open
past the point its purpose was served. The gated-issue count is now 2, not 3.

## This cycle's fresh angles (all clean)

- **Planner lens:** no ungroomed open issues (only the two standing
  `[Action required]` issues above remain, both already fully labeled/
  described), no un-RFC'd 🟡 items in ROADMAP.md (zero live `- [ ] 🟡` lines).
- **Architect lens:** directly re-verified two ADR'd components not named in
  today's earlier audits — Vault (chart `0.34.0`, image `2.0.3`, audited
  2026-07-24 with a specific flip condition not yet met) and Garage (image
  `v2.3.0`, audited 2026-07-28, flip condition not yet met) — both still
  fresh, no action needed.
- **Upgrade-drafter lens:** checked the Terraform-bootstrapped chart pin
  (`infra/live/{local,oracle}/argocd/terragrunt.hcl`'s `chart_version =
  "10.2.1"`) that upgrade-drafter's own scope note flags as easy to miss
  since it's invisible to a `gitops/`-only scan — matches the already-current
  pin from the 2026-07-28 bump. Kyverno chart `3.8.2` re-confirmed current
  via its ADR-0019 Re-evaluation log (already verified by architect PR #830
  the same day).
- **Doc-drift lens:** `make readme-check` and `make lab-ui-check` both clean
  after this run's own PRs (the drift they'd have caught was already fixed
  in #887).
- **Triager lens:** both remaining open issues (#631, #633) already carry
  `domain:*`/`readiness:*`/`priority:*` labels — nothing to triage.
- **Janitor lens:** scanned for orphaned `scripts/*.sh` files not wired into
  the Makefile or `.claude/settings.json` — six candidates found, all traced
  to real callers once `.githooks/` (not just Makefile/settings.json) was
  included in the search. No dead code found.

No further bounded, real deliverable qualified for a direct fix this cycle.
`make ci` is unaffected (no code/manifest touched by this audit note itself).
